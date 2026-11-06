// Installer kopiert das Addon in die lokale WoW-Installation (alle gewählten Flavors)
// oder schreibt mit -package eine ZIP. Configs (WTF/SavedVariables) werden nie angefasst.
package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
)

type options struct {
	src     string
	wowDir  string
	flavors string
	version string
	yes     bool
	dryRun  bool
	pkgPath string
	addons  string
	// -debuglog: Debug-Log von Level Time ausgeben (nur lesen), tail = nur die letzten Zeilen
	debugLog bool
	tail     int
}

func main() {
	var o options
	flag.StringVar(&o.src, "src", ".", "Quellverzeichnis des Addons (enthält die .toc)")
	flag.StringVar(&o.wowDir, "wow", os.Getenv("WOW_DIR"), "WoW-Installationsverzeichnis (Default: $WOW_DIR oder Auto-Erkennung)")
	flag.StringVar(&o.flavors, "flavors", "", "Kommagetrennte Flavors, z.B. retail,classic_era oder all")
	flag.StringVar(&o.version, "version", "dev", "Versionskennung fürs Manifest")
	flag.BoolVar(&o.yes, "yes", false, "Keine Rückfragen, Defaults übernehmen")
	flag.BoolVar(&o.dryRun, "dry-run", false, "Nur anzeigen, nichts schreiben")
	flag.StringVar(&o.addons, "addons", "", "Kommagetrennte Addons (Ordnername), z.B. StreamGoal; Standard: alle beim Installieren, das Hauptaddon beim Packen")
	flag.StringVar(&o.pkgPath, "package", "", "Statt zu installieren eine ZIP für CurseForge/manuelle Installation schreiben")
	flag.BoolVar(&o.debugLog, "debuglog", false, "Debug-Log von Level Time (/lt debug log) aus den SavedVariables ausgeben, nur lesen; -flavors filtert")
	flag.IntVar(&o.tail, "tail", 0, "Mit -debuglog: nur die letzten N Zeilen je Log")
	flag.Parse()

	var err error
	if o.debugLog {
		err = runDebugLog(o, os.Stdout, os.Stderr)
	} else if o.pkgPath != "" {
		err = runPackage(o)
	} else {
		w := &wizard{in: bufio.NewReader(os.Stdin), out: os.Stdout, opts: o}
		err = w.run()
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
}

func runPackage(o options) error {
	addons, err := LoadAddons(o.src, o.version)
	if err != nil {
		return err
	}
	// Pro ZIP ein Addon: ohne -addons das Hauptaddon
	names := o.addons
	if names == "" {
		names = addons[0].Name
	}
	selected, err := SelectAddons(addons, names)
	if err != nil {
		return err
	}
	if len(selected) != 1 {
		return errors.New("-package packt genau ein Addon, bitte mit -addons wählen")
	}
	if err := WritePackage(selected[0], o.pkgPath); err != nil {
		return err
	}
	fmt.Printf("Paket erstellt: %s\n", o.pkgPath)
	return nil
}

type wizard struct {
	in   *bufio.Reader
	out  io.Writer
	opts options
}

func (w *wizard) printf(format string, args ...any) {
	fmt.Fprintf(w.out, format, args...)
}

// job ist ein Addon in einer Spielversion
type job struct {
	addon *Addon
	plan  *Plan
}

func (w *wizard) run() error {
	all, err := LoadAddons(w.opts.src, w.opts.version)
	if err != nil {
		return err
	}
	addons, err := SelectAddons(all, w.opts.addons)
	if err != nil {
		return err
	}
	// Den Installationsstand der Spielversionen zeigt das erste Addon (das Hauptaddon, falls gewählt)
	lead := addons[0]
	w.printf("%s Installer (Version %s)\n\n", lead.Name, lead.Version)

	root, err := w.chooseRoot()
	if err != nil {
		return err
	}
	flavors, err := FindFlavors(root)
	if err != nil {
		return err
	}
	if len(flavors) == 0 {
		return fmt.Errorf("keine Spielversionen (_retail_, _classic_era_, ...) in %s gefunden", root)
	}

	plans := make([]*Plan, len(flavors))
	for i, f := range flavors {
		if plans[i], err = BuildPlan(lead, f); err != nil {
			return err
		}
	}

	selected, err := w.chooseFlavors(plans)
	if err != nil {
		return err
	}
	if len(selected) == 0 {
		w.printf("Nichts ausgewählt.\n")
		return nil
	}

	var jobs []job
	for _, p := range selected {
		for _, a := range addons {
			plan := p
			if a != lead {
				if plan, err = BuildPlan(a, p.Flavor); err != nil {
					return err
				}
			}
			jobs = append(jobs, job{addon: a, plan: plan})
		}
	}

	anyChanges := false
	for _, j := range jobs {
		w.printPlan(j)
		anyChanges = anyChanges || j.plan.HasChanges()
	}
	if !anyChanges {
		w.printf("Alles aktuell, nichts zu tun.\n")
		return nil
	}
	if w.opts.dryRun {
		w.printf("Dry-Run: nichts geschrieben.\n")
		return nil
	}
	if ok, err := w.confirm("Fortfahren?"); err != nil || !ok {
		if err == nil {
			w.printf("Abgebrochen.\n")
		}
		return err
	}

	for _, j := range jobs {
		if !j.plan.HasChanges() {
			continue
		}
		if err := j.plan.Apply(j.addon); err != nil {
			return fmt.Errorf("%s %s: %w", j.addon.Name, j.plan.Flavor.Name, err)
		}
		hint := "/reload im Spiel genügt"
		if j.plan.NeedsRestart() {
			hint = "WoW-Client neu starten (neue/geänderte .toc)"
		}
		w.printf("✓ %s in %s installiert – %s\n", j.addon.Name, j.plan.Flavor.Name, hint)
	}
	return nil
}

func (w *wizard) chooseRoot() (string, error) {
	if w.opts.wowDir != "" {
		return NormalizeRoot(w.opts.wowDir), nil
	}
	roots := DetectRoots()
	switch {
	case len(roots) == 1:
		w.printf("WoW gefunden: %s\n", roots[0])
		return roots[0], nil
	case len(roots) > 1:
		w.printf("Mehrere WoW-Installationen gefunden:\n")
		for i, r := range roots {
			w.printf("  %d) %s\n", i+1, r)
		}
		if w.opts.yes {
			return roots[0], nil
		}
		answer, err := w.ask("Auswahl [1]: ")
		if err != nil {
			return "", err
		}
		if answer == "" {
			return roots[0], nil
		}
		n, err := strconv.Atoi(answer)
		if err != nil || n < 1 || n > len(roots) {
			return "", fmt.Errorf("ungültige Auswahl: %s", answer)
		}
		return roots[n-1], nil
	}
	if w.opts.yes {
		return "", errors.New("WoW nicht gefunden, bitte -wow oder WOW_DIR setzen")
	}
	answer, err := w.ask("WoW nicht gefunden. Pfad zum WoW-Verzeichnis: ")
	if err != nil {
		return "", err
	}
	if answer == "" {
		return "", errors.New("kein Pfad angegeben")
	}
	return NormalizeRoot(answer), nil
}

func (w *wizard) chooseFlavors(plans []*Plan) ([]*Plan, error) {
	var defaults []int
	w.printf("\nSpielversionen:\n")
	for i, p := range plans {
		w.printf("  %d) %-18s %s\n", i+1, p.Flavor.Name, installState(p))
		if p.Installed() {
			defaults = append(defaults, i)
		}
	}
	if len(defaults) == 0 {
		for i := range plans {
			defaults = append(defaults, i)
		}
	}

	var input string
	switch {
	case w.opts.flavors != "":
		input = w.opts.flavors
	case w.opts.yes:
		input = ""
	default:
		var err error
		input, err = w.ask(fmt.Sprintf("Auswahl (Nummern/Namen, kommagetrennt, \"all\") [%s]: ", describeDefaults(plans, defaults)))
		if err != nil {
			return nil, err
		}
	}

	idx, err := parseSelection(input, plans, defaults)
	if err != nil {
		return nil, err
	}
	selected := make([]*Plan, len(idx))
	for i, n := range idx {
		selected[i] = plans[n]
	}
	return selected, nil
}

func installState(p *Plan) string {
	switch {
	case p.Existing != nil:
		return "installiert (" + p.Existing.Version + ")"
	case p.Legacy:
		return "installiert (alt, ohne Manifest)"
	default:
		return "nicht installiert"
	}
}

func describeDefaults(plans []*Plan, defaults []int) string {
	names := make([]string, len(defaults))
	for i, n := range defaults {
		names[i] = strings.Trim(plans[n].Flavor.Name, "_")
	}
	return strings.Join(names, ",")
}

// parseSelection akzeptiert Nummern, Flavor-Namen mit oder ohne Unterstriche und "all".
func parseSelection(input string, plans []*Plan, defaults []int) ([]int, error) {
	input = strings.TrimSpace(input)
	if input == "" {
		return defaults, nil
	}
	seen := map[int]bool{}
	var out []int
	add := func(n int) {
		if !seen[n] {
			seen[n] = true
			out = append(out, n)
		}
	}
	for _, token := range strings.Split(input, ",") {
		token = strings.ToLower(strings.TrimSpace(token))
		if token == "" {
			continue
		}
		if token == "all" || token == "a" {
			for i := range plans {
				add(i)
			}
			continue
		}
		if n, err := strconv.Atoi(token); err == nil {
			if n < 1 || n > len(plans) {
				return nil, fmt.Errorf("ungültige Nummer: %d", n)
			}
			add(n - 1)
			continue
		}
		found := false
		for i, p := range plans {
			if strings.Trim(strings.ToLower(p.Flavor.Name), "_") == strings.Trim(token, "_") {
				add(i)
				found = true
			}
		}
		if !found {
			return nil, fmt.Errorf("unbekannte Spielversion: %s", token)
		}
	}
	return out, nil
}

func (w *wizard) printPlan(j job) {
	p := j.plan
	w.printf("\n%s %s → %s\n", j.addon.Name, p.Flavor.Name, p.Target)
	for _, m := range p.Migrations {
		w.printf("  Migration %s: %s\n", m.id, m.description)
	}
	unchanged := 0
	for _, f := range p.Files {
		switch f.Status {
		case StatusNew:
			w.printf("  + %s\n", f.Path)
		case StatusUpdated:
			w.printf("  ~ %s\n", f.Path)
		default:
			unchanged++
		}
	}
	for _, r := range p.Remove {
		w.printf("  - %s\n", r)
	}
	if unchanged > 0 {
		w.printf("  (%d Dateien unverändert)\n", unchanged)
	}
}

func (w *wizard) ask(prompt string) (string, error) {
	w.printf("%s", prompt)
	line, err := w.in.ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return "", err
	}
	return strings.TrimSpace(line), nil
}

func (w *wizard) confirm(prompt string) (bool, error) {
	w.printf("\nConfigs (WTF/SavedVariables) werden nicht verändert.\n")
	if w.opts.yes {
		return true, nil
	}
	answer, err := w.ask(prompt + " [J/n]: ")
	if err != nil {
		return false, err
	}
	switch strings.ToLower(answer) {
	case "", "j", "ja", "y", "yes":
		return true, nil
	}
	return false, nil
}
