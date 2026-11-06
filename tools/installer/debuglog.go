package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// Debug-Log von Level Time (/lt debug log) lesen: Der Client schreibt die SavedVariable LevelTimerDebugLog bei
// /reload und Logout nach <Flavor>/WTF/Account/<Konto>/SavedVariables/LevelTimer.lua. Nur lesen, nie schreiben.

const (
	debugLogVariable = "LevelTimerDebugLog"
	savedVarsFile    = "LevelTimer.lua"
)

// Zeilen der Tabelle "lines" im SavedVariables-Format des Clients: "\t\t\"text\", -- [n]"
var debugLogLinePattern = regexp.MustCompile(`^\s*("(?:[^"\\]|\\.)*"),?\s*(?:--\s*\[\d+\])?\s*$`)

// DebugLogFile ist das Log eines Kontos in einem Flavor.
type DebugLogFile struct {
	Flavor  string
	Account string
	Path    string
	Lines   []string
}

// ParseDebugLog holt die Log-Zeilen aus dem Inhalt einer SavedVariables-Datei (leer, wenn die Variable fehlt).
func ParseDebugLog(r io.Reader) ([]string, error) {
	scanner := bufio.NewScanner(r)
	scanner.Buffer(make([]byte, 1024*1024), 16*1024*1024)
	var lines []string
	inVariable, inLines := false, false
	for scanner.Scan() {
		text := scanner.Text()
		switch {
		case strings.HasPrefix(text, debugLogVariable+" = "):
			inVariable = true
		case inVariable && text != "" && !strings.HasPrefix(text, "\t") && !strings.HasPrefix(text, "}"):
			inVariable = false // nächste globale Variable
		case inVariable && strings.HasPrefix(strings.TrimSpace(text), `["lines"] = {`):
			inLines = true
		case inLines && strings.HasPrefix(strings.TrimSpace(text), "}"):
			inLines = false
		case inLines:
			if m := debugLogLinePattern.FindStringSubmatch(text); m != nil {
				lines = append(lines, unquoteLua(m[1]))
			}
		}
	}
	return lines, scanner.Err()
}

// Lua-Escapes der SavedVariables (\" \\ \n) entsprechen denen von Go; sonst den Text roh lassen
func unquoteLua(quoted string) string {
	if s, err := strconv.Unquote(quoted); err == nil {
		return s
	}
	return strings.Trim(quoted, `"`)
}

// FindDebugLogs sucht in allen Flavors und Konten der WoW-Installation nach Debug-Logs mit Zeilen.
func FindDebugLogs(root string) ([]DebugLogFile, error) {
	flavors, err := FindFlavors(root)
	if err != nil {
		return nil, err
	}
	var logs []DebugLogFile
	for _, f := range flavors {
		paths, _ := filepath.Glob(filepath.Join(f.Dir, "WTF", "Account", "*", "SavedVariables", savedVarsFile))
		for _, path := range paths {
			lines, err := readDebugLog(path)
			if err != nil {
				return nil, err
			}
			if len(lines) == 0 {
				continue
			}
			account := filepath.Base(filepath.Dir(filepath.Dir(path)))
			logs = append(logs, DebugLogFile{Flavor: f.Name, Account: account, Path: path, Lines: lines})
		}
	}
	return logs, nil
}

func readDebugLog(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	return ParseDebugLog(file)
}

// runDebugLog gibt die Logs als JSON Lines nach out aus (je Eintrag eine Zeile), Überschriften und Hinweise nach
// info, damit out direkt in jq & Co. passt. Optional nur bestimmte Flavors und die letzten tail Zeilen (0 = alle).
func runDebugLog(o options, out, info io.Writer) error {
	root := NormalizeRoot(o.wowDir)
	if o.wowDir == "" {
		roots := DetectRoots()
		if len(roots) == 0 {
			return fmt.Errorf("WoW nicht gefunden, bitte -wow oder WOW_DIR setzen")
		}
		root = roots[0]
	}
	logs, err := FindDebugLogs(root)
	if err != nil {
		return err
	}
	if len(logs) == 0 {
		fmt.Fprintf(info, "Kein Debug-Log in %s (im Spiel /lt debug log oder /lt debug check, dann /reload)\n", root)
		return nil
	}
	for _, log := range logs {
		if o.flavors != "" && !strings.Contains(o.flavors, strings.Trim(log.Flavor, "_")) {
			continue
		}
		lines := log.Lines
		if o.tail > 0 && len(lines) > o.tail {
			lines = lines[len(lines)-o.tail:]
		}
		fmt.Fprintf(info, "== %s / %s (%d Zeilen): %s\n", log.Flavor, log.Account, len(log.Lines), log.Path)
		for _, line := range lines {
			fmt.Fprintln(out, line)
		}
	}
	return nil
}
