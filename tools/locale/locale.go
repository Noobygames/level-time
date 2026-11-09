package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// Languages sind die Sprachdateien; enUS ist die Referenz für Platzhalter.
var Languages = []string{"deDE", "enUS", "frFR", "esES"}

var (
	keyPattern         = regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)
	placeholderPattern = regexp.MustCompile(`%([sd])`)
)

// Entry ist ein Schlüssel mit seinem Text je Sprache.
type Entry struct {
	Key   string
	Texts map[string]string
}

// ParseEntries liest das JSON-Format und prüft Vollständigkeit und Platzhalter (wie tests/locales_test.lua).
func ParseEntries(data []byte) ([]Entry, error) {
	raw := map[string]map[string]string{}
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("JSON: %w", err)
	}
	keys := make([]string, 0, len(raw))
	for key := range raw {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	var entries []Entry
	for _, key := range keys {
		if !keyPattern.MatchString(key) {
			return nil, fmt.Errorf("ungültiger Schlüssel %q", key)
		}
		texts := raw[key]
		for lang := range texts {
			if !contains(Languages, lang) {
				return nil, fmt.Errorf("%s: unbekannte Sprache %s", key, lang)
			}
		}
		for _, lang := range Languages {
			if strings.TrimSpace(texts[lang]) == "" {
				return nil, fmt.Errorf("%s: Sprache %s fehlt", key, lang)
			}
		}
		reference := Placeholders(texts["enUS"])
		for _, lang := range Languages {
			if got := Placeholders(texts[lang]); got != reference {
				return nil, fmt.Errorf("%s: Platzhalter %q in %s, erwartet %q wie enUS", key, got, lang, reference)
			}
		}
		entries = append(entries, Entry{Key: key, Texts: texts})
	}
	return entries, nil
}

// Placeholders liefert %s und %d in Reihenfolge, z.B. "sdd".
func Placeholders(text string) string {
	var out strings.Builder
	for _, match := range placeholderPattern.FindAllStringSubmatch(text, -1) {
		out.WriteString(match[1])
	}
	return out.String()
}

// LuaString schreibt Klartext als Lua-Stringliteral (UTF-8 bleibt wie in den Dateien unverändert).
func LuaString(text string) string {
	replacer := strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`, "\r", "")
	return `"` + replacer.Replace(text) + `"`
}

func contains(list []string, value string) bool {
	for _, item := range list {
		if item == value {
			return true
		}
	}
	return false
}

// SetKey ersetzt die Zeile des Schlüssels oder hängt sie vor der schließenden Klammer an.
func SetKey(content, key, text string) (string, error) {
	line := "  " + key + " = " + LuaString(text) + ","
	lines := strings.Split(content, "\n")
	prefix := "  " + key + " = "
	for i, existing := range lines {
		if strings.HasPrefix(existing, prefix) {
			lines[i] = line
			return strings.Join(lines, "\n"), nil
		}
	}
	for i := len(lines) - 1; i >= 0; i-- {
		if strings.TrimSpace(lines[i]) == "}" {
			lines = append(lines[:i], append([]string{line}, lines[i:]...)...)
			return strings.Join(lines, "\n"), nil
		}
	}
	return "", fmt.Errorf("keine schließende Klammer gefunden")
}

// RemoveKey löscht die Zeile des Schlüssels; false, wenn es sie nicht gab.
func RemoveKey(content, key string) (string, bool) {
	lines := strings.Split(content, "\n")
	prefix := "  " + key + " = "
	for i, existing := range lines {
		if strings.HasPrefix(existing, prefix) {
			return strings.Join(append(lines[:i], lines[i+1:]...), "\n"), true
		}
	}
	return content, false
}

// edit wendet fn auf alle vier Dateien an und schreibt erst, wenn alle gelungen sind.
func edit(dir string, fn func(lang, content string) (string, error)) error {
	results := map[string]string{}
	for _, lang := range Languages {
		path := filepath.Join(dir, lang+".lua")
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		out, err := fn(lang, string(data))
		if err != nil {
			return fmt.Errorf("%s: %w", lang, err)
		}
		results[path] = out
	}
	for path, out := range results {
		if err := os.WriteFile(path, []byte(out), 0o644); err != nil {
			return err
		}
	}
	return nil
}

// Apply schreibt alle Einträge in alle Sprachdateien.
func Apply(dir string, entries []Entry) error {
	return edit(dir, func(lang, content string) (string, error) {
		var err error
		for _, entry := range entries {
			if content, err = SetKey(content, entry.Key, entry.Texts[lang]); err != nil {
				return "", err
			}
		}
		return content, nil
	})
}

// Remove löscht die Schlüssel aus allen Sprachdateien; unbekannte Schlüssel sind ein Fehler.
func Remove(dir string, keys []string) error {
	return edit(dir, func(lang, content string) (string, error) {
		for _, key := range keys {
			var found bool
			if content, found = RemoveKey(content, strings.TrimSpace(key)); !found {
				return "", fmt.Errorf("Schlüssel %s nicht gefunden", key)
			}
		}
		return content, nil
	})
}
