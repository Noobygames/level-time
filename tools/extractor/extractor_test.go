package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// testdata/wow: Forever mit Daten und Debug-Log in derselben Datei, Retail ohne LevelTimerExtractorDB
func TestRunExportsAndChecks(t *testing.T) {
	outDir := t.TempDir()
	var out bytes.Buffer
	if err := run(filepath.Join("testdata", "wow"), outDir, "", filepath.Join("testdata", "guide.lua"), &out); err != nil {
		t.Fatal(err)
	}
	report := out.String()
	for _, want := range []string{
		"== _forever_ / TEST (Schema 1)",
		"instances 3, levels 0, npcs 2, quests 2",
		"Build 1.15.7.16001 (Interface 11507)",
		"4 bestätigt, 2 widersprechen, 1 ergänzen",
		"bestätigt    Eingang Karte 33: 1421 0.445,0.675 (3x)",
		"widerspricht Eingang Karte 34: Führer 1453 0.524,0.700, Daten 1453 0.205,0.205 (2x)",
		"ergänzt      Eingang Karte 999: 1411 0.505,0.505 (1x)",
		"bestätigt    Boss-Level Begegnung 222: 26",
		"bestätigt    Queststart 1806: 1426 0.525,0.365 npc:6171 (2x)",
		"widerspricht Questlevel 1098: Führer 25, Daten 26",
	} {
		if !strings.Contains(report, want) {
			t.Errorf("Bericht ohne %q:\n%s", want, report)
		}
	}
	if strings.Contains(report, "9001") || strings.Contains(report, "_retail_") {
		t.Errorf("Totenkopf-Boss oder Retail ohne Daten im Bericht:\n%s", report)
	}

	data, err := os.ReadFile(filepath.Join(outDir, "forever.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), `"4467": 3`) || strings.Contains(string(data), "LevelTimerDebugLog") {
		t.Errorf("forever.json unerwartet:\n%s", data)
	}
	if _, err := os.Stat(filepath.Join(outDir, "retail.json")); !os.IsNotExist(err) {
		t.Errorf("retail.json sollte fehlen: %v", err)
	}
}

// Der echte Dungeonführer muss sich laden lassen (Formänderungen dort fallen hier auf)
func TestLoadRealGuide(t *testing.T) {
	guide, err := LoadGuide(filepath.Join("..", "..", "Assist", "InstanceData", "forever_guide.lua"))
	if err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"levels", "entrances", "bossLevels", "quests"} {
		if len(table(guide, key)) == 0 {
			t.Errorf("ns.InstanceGuide.%s leer", key)
		}
	}
}
