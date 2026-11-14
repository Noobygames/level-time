// Command extractor liest die Spieldaten des lokalen Addons LevelTimer_DataExtractor (SavedVariable
// LevelTimerExtractorDB) aus allen Flavors einer WoW-Installation, schreibt sie je Flavor als JSON nach -out und gibt
// eine kurze Übersicht aus; dazu je Flavor abgeleitete Dateien für die Dungeon-Datenbank (instances.go). Mit -guide vergleicht es die Forever-Daten mit dem Dungeonführer (nur Bericht, ändert
// nichts). Aufruf über make extract / make extract-check.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const (
	dbVariable    = "LevelTimerExtractorDB"
	savedVarsFile = "LevelTimer_DataExtractor.lua"
	guideFlavor   = "_forever_"
)

// Export sind die Daten eines Kontos in einem Flavor.
type Export struct {
	Flavor  string
	Account string
	Path    string
	DB      map[string]any
}

func main() {
	wowDir := flag.String("wow", os.Getenv("WOW_DIR"), "WoW-Installationsordner (Standard: WOW_DIR oder automatisch gesucht)")
	outDir := flag.String("out", "", "Zielordner für <flavor>.json (leer = nichts schreiben)")
	flavors := flag.String("flavors", "", "Nur diese Flavors, z.B. forever,retail")
	guide := flag.String("guide", "", "Pfad zu Assist/InstanceData/forever_guide.lua: Forever-Daten damit vergleichen")
	flag.Parse()
	if err := run(*wowDir, *outDir, *flavors, *guide, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
}

func run(wowDir, outDir, flavors, guidePath string, out io.Writer) error {
	root := normalizeRoot(wowDir)
	if wowDir == "" {
		if root = detectRoot(); root == "" {
			return fmt.Errorf("WoW nicht gefunden, bitte -wow oder WOW_DIR setzen")
		}
	}
	exports, err := FindExports(root)
	if err != nil {
		return err
	}
	if len(exports) == 0 {
		fmt.Fprintf(out, "Keine Extractor-Daten in %s (Addon LevelTimer_DataExtractor aktivieren, spielen, /reload)\n", root)
		return nil
	}
	perFlavor := map[string]int{}
	for _, e := range exports {
		perFlavor[e.Flavor]++
	}
	for _, e := range exports {
		if flavors != "" && !strings.Contains(flavors, strings.Trim(e.Flavor, "_")) {
			continue
		}
		fmt.Fprint(out, Summary(e))
		if outDir != "" {
			name := strings.Trim(e.Flavor, "_")
			if perFlavor[e.Flavor] > 1 {
				name += "-" + e.Account // mehrere Konten im selben Flavor nicht überschreiben
			}
			if err := writeJSON(filepath.Join(outDir, name+".json"), e.DB); err != nil {
				return err
			}
			for file, data := range DerivedExports(e.DB) {
				if err := writeJSON(filepath.Join(outDir, name+"_"+file+".json"), data); err != nil {
					return err
				}
			}
		}
		if guidePath != "" && e.Flavor == guideFlavor {
			guide, err := LoadGuide(guidePath)
			if err != nil {
				return err
			}
			fmt.Fprint(out, CheckGuide(e.DB, guide))
		}
	}
	return nil
}

// FindExports liest LevelTimerExtractorDB aus jedem Flavor und Konto unter root (Dateien ohne die Variable fehlen).
func FindExports(root string) ([]Export, error) {
	paths, _ := filepath.Glob(filepath.Join(root, "_*_", "WTF", "Account", "*", "SavedVariables", savedVarsFile))
	sort.Strings(paths)
	var exports []Export
	for _, path := range paths {
		db, err := LoadGlobal(path, dbVariable)
		if err != nil {
			return nil, err
		}
		if db == nil {
			continue
		}
		// <root>/<Flavor>/WTF/Account/<Konto>/SavedVariables/<Datei>
		rel, _ := filepath.Rel(root, path)
		parts := strings.Split(rel, string(filepath.Separator))
		exports = append(exports, Export{Flavor: parts[0], Account: parts[3], Path: path, DB: db})
	}
	return exports, nil
}

// Summary: Einträge je Bereich und die Client-Versionen, in denen gesammelt wurde.
func Summary(e Export) string {
	var b strings.Builder
	fmt.Fprintf(&b, "== %s / %s (Schema %v): %s\n", e.Flavor, e.Account, e.DB["schema"], e.Path)
	keys := sortedKeys(e.DB)
	var counts []string
	for _, k := range keys {
		if section, ok := e.DB[k].(map[string]any); ok && k != "builds" {
			counts = append(counts, fmt.Sprintf("%s %d", k, len(section)))
		}
	}
	fmt.Fprintf(&b, "   %s\n", strings.Join(counts, ", "))
	builds := table(e.DB, "builds")
	for _, k := range sortedKeys(builds) {
		interfaceVersion, _ := number(table(builds, k), "interface")
		fmt.Fprintf(&b, "   Build %s (Interface %.0f)\n", k, interfaceVersion)
	}
	return b.String()
}

// encoding/json sortiert Map-Schlüssel, das ergibt stabile Dateien
func writeJSON(path string, value any) error {
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, append(data, '\n'), 0o644)
}

func sortedKeys(m map[string]any) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func isFlavorDirName(name string) bool {
	return len(name) > 2 && strings.HasPrefix(name, "_") && strings.HasSuffix(name, "_")
}

// Angabe eines Flavor-Ordners (...\_forever_) erlaubt, wie beim Installer
func normalizeRoot(dir string) string {
	dir = filepath.Clean(dir)
	if isFlavorDirName(filepath.Base(dir)) {
		return filepath.Dir(dir)
	}
	return dir
}

// Wie DetectRoots in tools/installer (eigenes Modul, darum kopiert): erster übliche Installationsort mit Flavor-Ordnern.
func detectRoot() string {
	var candidates []string
	for drive := 'C'; drive <= 'Z'; drive++ {
		for _, sub := range []string{`World of Warcraft`, `Games\World of Warcraft`, `Program Files (x86)\World of Warcraft`,
			`Program Files\World of Warcraft`, `Blizzard\World of Warcraft`} {
			candidates = append(candidates, filepath.Join(string(drive)+`:\`, sub))
		}
	}
	candidates = append(candidates, "/Applications/World of Warcraft")
	for _, c := range candidates {
		if matches, _ := filepath.Glob(filepath.Join(c, "_*_")); len(matches) > 0 {
			return c
		}
	}
	return ""
}
