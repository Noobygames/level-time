package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const fixture = "-- Texte\nlocal _, ns = ...\n\nns.locales.LANG = {\n  A = \"eins\",\n  B = \"zwei %s\",\n}\n"

func writeFixture(t *testing.T) string {
	dir := t.TempDir()
	for _, lang := range Languages {
		content := strings.Replace(fixture, "LANG", lang, 1)
		if err := os.WriteFile(filepath.Join(dir, lang+".lua"), []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return dir
}

func read(t *testing.T, dir, lang string) string {
	data, err := os.ReadFile(filepath.Join(dir, lang+".lua"))
	if err != nil {
		t.Fatal(err)
	}
	return string(data)
}

const good = `{"NEW_KEY":{"deDE":"Hallo \"Welt\" %s","enUS":"Hello %s\nline","frFR":"Salut %s","esES":"Hola %s"}}`

func TestApplyAppendsAndReplaces(t *testing.T) {
	dir := writeFixture(t)
	entries, err := ParseEntries([]byte(good))
	if err != nil {
		t.Fatal(err)
	}
	if err := Apply(dir, entries); err != nil {
		t.Fatal(err)
	}
	de := read(t, dir, "deDE")
	if !strings.Contains(de, "  NEW_KEY = \"Hallo \\\"Welt\\\" %s\",\n}") {
		t.Errorf("deDE falsch:\n%s", de)
	}
	if !strings.Contains(read(t, dir, "enUS"), `"Hello %s\nline"`) {
		t.Error("Zeilenumbruch nicht escaped")
	}
	entries, _ = ParseEntries([]byte(strings.ReplaceAll(good, "Salut", "Coucou")))
	if err := Apply(dir, entries); err != nil {
		t.Fatal(err)
	}
	fr := read(t, dir, "frFR")
	if strings.Count(fr, "NEW_KEY") != 1 || !strings.Contains(fr, "Coucou") {
		t.Errorf("frFR nicht ersetzt:\n%s", fr)
	}
}

func TestRemove(t *testing.T) {
	dir := writeFixture(t)
	if err := Remove(dir, []string{"A"}); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(read(t, dir, "esES"), "  A = ") {
		t.Error("A noch da")
	}
	if err := Remove(dir, []string{"NOPE"}); err == nil {
		t.Error("unbekannter Schlüssel sollte fehlschlagen")
	}
}

func TestParseRejects(t *testing.T) {
	cases := map[string]string{
		"fehlende Sprache": `{"K":{"deDE":"a","enUS":"a","frFR":"a"}}`,
		"Platzhalter":      `{"K":{"deDE":"a %d","enUS":"a %s","frFR":"a %s","esES":"a %s"}}`,
		"Reihenfolge":      `{"K":{"deDE":"%s %d","enUS":"%d %s","frFR":"%d %s","esES":"%d %s"}}`,
		"Schlüssel":        `{"bad key":{"deDE":"a","enUS":"a","frFR":"a","esES":"a"}}`,
		"unbekannt":        `{"K":{"deDE":"a","enUS":"a","frFR":"a","esES":"a","ruRU":"a"}}`,
	}
	for name, input := range cases {
		if _, err := ParseEntries([]byte(input)); err == nil {
			t.Errorf("%s: kein Fehler", name)
		}
	}
}

func TestFailureWritesNothing(t *testing.T) {
	dir := writeFixture(t)
	before := read(t, dir, "deDE")
	os.Remove(filepath.Join(dir, "esES.lua"))
	entries, _ := ParseEntries([]byte(good))
	if err := Apply(dir, entries); err == nil {
		t.Fatal("Fehler erwartet")
	}
	if read(t, dir, "deDE") != before {
		t.Error("deDE wurde trotz Fehler geschrieben")
	}
}
