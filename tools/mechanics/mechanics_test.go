package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadAndRender(t *testing.T) {
	dir := t.TempDir()
	write := func(name, body string) {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	// ASCII-Datei: Umlaute werden ergänzt, "Feuer" bleibt
	write("a.json", `{"instance":"A","bosses":[{"name":"Boss","npcID":2,"mechanics":[
		{"spellID":5,"type":"interrupt","en":"Heals","de":"Feuer; Verbuendete toeten"},
		{"spellID":6,"type":"avoid","en":"","de":""}]}],"trash":[]}`)
	// Datei mit echten Umlauten bleibt unverändert; Einheit ohne Text fällt weg
	write("b.json", `{"instance":"B","bosses":[{"name":"X","npcID":3,"mechanics":[]}],
		"rares":[{"name":"R","npcID":1,"mechanics":[{"spellID":0,"type":"tank","en":"Say \"hi\"","de":"Grüße toeten"}]}]}`)
	entries, files, err := load(dir)
	if err != nil || files != 2 || len(entries) != 2 {
		t.Fatalf("load: %v files=%d entries=%d", err, files, len(entries))
	}
	out := render(entries)
	for _, want := range []string{
		`{ 0, "tank", "Grüße toeten", "Say \"hi\"" }`,
		`{ 5, "interrupt", "Feuer; Verbündete töten", "Heals" }`,
	} {
		if !strings.Contains(out, want) {
			t.Errorf("fehlt %s in\n%s", want, out)
		}
	}
	if strings.Index(out, "[1]") > strings.Index(out, "[2]") {
		t.Error("nicht nach NPC-ID sortiert")
	}
}

// Versions-Kennung (LT-56): classic -> "c", forever -> "f", beide bestätigt -> "v", beide unbestätigt ohne Kennung;
// die Zauberprüfung meldet nur Zeilen, die auch auf Forever gelten.
func TestVersionsAndSpellCheck(t *testing.T) {
	dir := t.TempDir()
	body := `{"instance":"A","bosses":[{"name":"Boss","npcID":2,"mechanics":[
		{"spellID":5,"type":"tank","en":"a","de":"ä","version":"classic"},
		{"spellID":6,"type":"tank","en":"b","de":"ö","version":"forever"},
		{"spellID":7,"type":"tank","en":"c","de":"ü","verified":true},
		{"spellID":8,"type":"tank","en":"d","de":"ß"}]}]}`
	if err := os.WriteFile(filepath.Join(dir, "a.json"), []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	entries, _, err := load(dir)
	if err != nil {
		t.Fatal(err)
	}
	out := render(entries)
	for _, want := range []string{`{ 5, "tank", "ä", "a", "c" }`, `{ 6, "tank", "ö", "b", "f" }`,
		`{ 7, "tank", "ü", "c", "v" }`, `{ 8, "tank", "ß", "d" }`, `local otherTag = flavor == "forever" and "c" or "f"`} {
		if !strings.Contains(out, want) {
			t.Errorf("fehlt %s", want)
		}
	}
	ids, err := readSpellIDs(strings.NewReader("ID,Name_lang\n6,\"x\"\n7,\"y\"\n"))
	if err != nil {
		t.Fatal(err)
	}
	missing := missingSpells(entries, ids)
	if len(missing) != 1 || !strings.Contains(missing[0], ": 8 ") {
		t.Errorf("fehlende Zauber: %v", missing)
	}
	if err := os.WriteFile(filepath.Join(dir, "a.json"), []byte(strings.Replace(body, `"classic"`, `"tbc"`, 1)), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, _, err := load(dir); err == nil {
		t.Error("unbekannte Version nicht abgelehnt")
	}
}
