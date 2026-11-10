package main

import (
	"bytes"
	"io"
	"math"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// SavedVariables wie WoW Forever sie schreibt (ohne Einrückung), mit neuen Strecken und alten Namen-Messungen
const foreverFixture = `LevelTimerDB = {
["flightTimer"] = true,
}
LevelTimerStatsDB = {
["flightTimes"] = {
["Crossroads, Brachland > Camp Taurajo, Brachland"] = 91,
["Tarrens Mühle, Hillsbrad > Undercity, Tirisfal"] = 140,
},
["flights"] = {
["forever"] = {
["1411"] = {
["nodes"] = {
["25"] = {
["y"] = 0.53047657012939,
["x"] = 0.55735743045807,
["name"] = "Crossroads, Brachland",
},
},
["routes"] = {
["25>77"] = {
["seconds"] = 91,
["distance"] = 0.0849,
["samples"] = {
91, -- [1]
93, -- [2]
},
["from"] = "Crossroads, \"Brachland\"",
},
["80>25"] = {
["seconds"] = 70,
["distance"] = 0.0518,
["samples"] = {
70, -- [1]
},
},
["80>22"] = {
["seconds"] = 251,
["distance"] = 0.1641,
["samples"] = {
251, -- [1]
},
},
},
},
},
},
}
LevelTimerDebugLog = {
}
`

func TestParseVariable(t *testing.T) {
	value, err := ParseVariable(foreverFixture, statsVariable)
	if err != nil {
		t.Fatal(err)
	}
	stats := asTable(value)
	routes := asTable(asTable(asTable(asTable(stats["flights"])["forever"])["1411"])["routes"])
	if got := numbers(asTable(routes["25>77"])["samples"]); len(got) != 2 || got[1] != 93 {
		t.Errorf("samples = %v", got)
	}
	if got := asTable(routes["25>77"])["from"]; got != `Crossroads, "Brachland"` {
		t.Errorf("String mit Escape = %v", got)
	}
	if missing, _ := ParseVariable(foreverFixture, "Fehlt"); missing != nil {
		t.Errorf("fehlende Variable = %v", missing)
	}
}

func TestFitLikeAddon(t *testing.T) {
	// Ein Punkt: Standard-Start/Landung und Median der Einzelwerte
	one := Fit([]Point{{Distance: 0.0849, Seconds: 91}})
	if one.Offset != defaultOffset || math.Abs(one.PerUnit-(91-10)/0.0849) > 1e-9 {
		t.Errorf("ein Punkt: %+v", one)
	}
	// Drei Punkte: Gerade, Schätzung der zurückgehaltenen Strecke Ratchet > Sonnenfels (218,8 s) in 25 %
	three := Fit([]Point{{0.0849, 91}, {0.0518, 70}, {0.1641, 251}})
	estimate := three.Offset + three.PerUnit*0.212
	if math.Abs(estimate-218.8)/218.8 > 0.25 {
		t.Errorf("Schätzung %.1f s zu weit weg (%+v)", estimate, three)
	}
	if Fit(nil) != nil {
		t.Error("ohne Punkte kein Faktor")
	}
}

func TestCollectAndWriteLua(t *testing.T) {
	root := t.TempDir()
	dir := filepath.Join(root, "_forever_", "WTF", "Account", "123#1", "SavedVariables")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, savedVarsFile), []byte(foreverFixture), 0o644); err != nil {
		t.Fatal(err)
	}
	snapshot, err := Collect(root, io.Discard)
	if err != nil {
		t.Fatal(err)
	}
	var out bytes.Buffer
	if err := snapshot.WriteLua(&out, "2026-11-07"); err != nil {
		t.Fatal(err)
	}
	lua := out.String()
	for _, want := range []string{
		`["forever"] = {`,
		`["25>77"] = 92,`, // Median aus 91 und 93
		`["80>22"] = 251,`,
		`factor = { offset = `,
		`samples = 3 }`,
		"Nicht von Hand ändern",
	} {
		if !strings.Contains(lua, want) {
			t.Errorf("fehlt %q in\n%s", want, lua)
		}
	}
	if strings.Contains(lua, "\r") {
		t.Error("Datei muss LF haben")
	}
}
