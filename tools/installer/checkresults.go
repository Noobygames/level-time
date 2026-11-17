package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Ergebnisse der Spiel-Checkliste (/lte todo) lesen: LevelTimerDebugLog.checkResults in derselben SavedVariables-Datei wie
// das Debug-Log. Nur lesen, nie schreiben (nach Vikunja überträgt der Entwickler von Hand).

var (
	checkEntryPattern = regexp.MustCompile(`^\s*\["(LT-\d+)"\] = \{`)
	checkFieldPattern = regexp.MustCompile(`^\s*\["(status|t|note)"\] = ("(?:[^"\\]|\\.)*")`)
)

// CheckResult ist ein abgehaktes Ticket.
type CheckResult struct {
	Flavor  string `json:"flavor,omitempty"`
	Account string `json:"account,omitempty"`
	ID      string `json:"id"`
	Status  string `json:"status"`
	Time    string `json:"t,omitempty"`
	Note    string `json:"note,omitempty"`
}

// ParseCheckResults holt die Einträge von checkResults aus dem Inhalt einer SavedVariables-Datei.
func ParseCheckResults(r io.Reader) ([]CheckResult, error) {
	scanner := bufio.NewScanner(r)
	scanner.Buffer(make([]byte, 1024*1024), 16*1024*1024)
	var results []CheckResult
	inVariable, inResults, inEntry := false, false, false
	var current CheckResult
	for scanner.Scan() {
		text := scanner.Text()
		trimmed := strings.TrimSpace(text)
		switch {
		case strings.HasPrefix(text, debugLogVariable+" = "):
			inVariable = true
		case inVariable && globalAssignmentPattern.MatchString(text):
			inVariable, inResults, inEntry = false, false, false
		case inVariable && strings.HasPrefix(trimmed, `["checkResults"] = {`):
			inResults = true
		case inResults && !inEntry && checkEntryPattern.MatchString(text):
			inEntry = true
			current = CheckResult{ID: checkEntryPattern.FindStringSubmatch(text)[1]}
		case inEntry && strings.HasPrefix(trimmed, "}"):
			results, inEntry = append(results, current), false
		case inEntry:
			if m := checkFieldPattern.FindStringSubmatch(text); m != nil {
				value := unquoteLua(m[2])
				switch m[1] {
				case "status":
					current.Status = value
				case "t":
					current.Time = value
				case "note":
					current.Note = value
				}
			}
		case inResults && strings.HasPrefix(trimmed, "}"):
			inResults = false
		}
	}
	return results, scanner.Err()
}

// runCheckResults gibt je Ergebnis eine Zeile aus: "id status datum notiz" (Text) oder mit -json ein JSON-Objekt.
func runCheckResults(o options, out, info io.Writer) error {
	root := NormalizeRoot(o.wowDir)
	if o.wowDir == "" {
		roots := DetectRoots()
		if len(roots) == 0 {
			return fmt.Errorf("WoW nicht gefunden, bitte -wow oder WOW_DIR setzen")
		}
		root = roots[0]
	}
	flavors, err := FindFlavors(root)
	if err != nil {
		return err
	}
	found := 0
	for _, f := range flavors {
		if o.flavors != "" && !strings.Contains(o.flavors, strings.Trim(f.Name, "_")) {
			continue
		}
		paths, _ := filepath.Glob(filepath.Join(f.Dir, "WTF", "Account", "*", "SavedVariables", savedVarsFile))
		for _, path := range paths {
			file, err := os.Open(path)
			if err != nil {
				return err
			}
			results, err := ParseCheckResults(file)
			file.Close()
			if err != nil {
				return err
			}
			account := filepath.Base(filepath.Dir(filepath.Dir(path)))
			for _, r := range results {
				r.Flavor, r.Account = f.Name, account
				found++
				if o.json {
					line, _ := json.Marshal(r)
					fmt.Fprintln(out, string(line))
				} else {
					fmt.Fprintf(out, "%s\t%s\t%s\t%s\n", r.ID, r.Status, r.Time, r.Note)
				}
			}
		}
	}
	if found == 0 {
		fmt.Fprintf(info, "Keine Prüfergebnisse in %s (im Spiel /lte todo, dann /reload)\n", root)
	}
	return nil
}
