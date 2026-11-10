package main

import (
	"strings"
	"testing"
)

const uiMapCSV = `Name_lang,ID,ParentUiMapID,Type
Elwynn Forest,37,13,3
Kalimdor,12,946,2
Burning Blade Coven,2,1,5
Teilkarte,99,13,3
Leer,98,13,3
`

// Elwynn zweimal (höherer OrderIndex verliert), Teilkarte nur mit Ausschnitt, Leer ohne Fläche, Coven falscher Typ
const uiAssignmentCSV = `UiMin_0,UiMin_1,UiMax_0,UiMax_1,Region_0,Region_1,Region_2,Region_3,Region_4,Region_5,ID,UiMapID,OrderIndex,MapID
0,0,1,1,-1,-2,0,3,4,0,1,37,5,9
0,0,1,1,-10254.200195312,-1935.4200439453,-1000000,-7939.580078125,1535.4200439453,1000000,39462,37,0,0
0,0,1,1,-5000,-9000,0,5000,1000,0,3,12,0,1
0,0,0.5,1,0,0,0,10,10,0,4,99,0,0
0,0,1,1,5,5,0,5,5,0,5,98,0,0
0,0,1,1,0,0,0,10,10,0,6,2,0,1
`

func TestParseMapCoords(t *testing.T) {
	coords, err := ParseMapCoords("12.0.1", strings.NewReader(uiMapCSV), strings.NewReader(uiAssignmentCSV))
	if err != nil {
		t.Fatal(err)
	}
	if len(coords.Areas) != 2 {
		t.Fatalf("Karten: %d, erwartet 2 (%v)", len(coords.Areas), coords.Areas)
	}
	elwynn := coords.Areas[37]
	if elwynn.InstanceID != 0 || elwynn.MaxNorth > -7939.57 || elwynn.MaxNorth < -7939.59 || elwynn.MaxWest < 1535 {
		t.Errorf("Elwynn: %+v", elwynn)
	}
	if coords.Areas[12].InstanceID != 1 {
		t.Errorf("Kalimdor: %+v", coords.Areas[12])
	}
}

func TestWriteMapCoordsLua(t *testing.T) {
	coords, _ := ParseMapCoords("12.0.1", strings.NewReader(uiMapCSV), strings.NewReader(uiAssignmentCSV))
	var out strings.Builder
	if err := WriteMapCoordsLua(&out, "retail", coords, "2026-11-10"); err != nil {
		t.Fatal(err)
	}
	text := out.String()
	for _, want := range []string{`if ns.Client.Flavor() ~= "retail" then return end`,
		`[37] = { 0, -10254.2, -1935.42, -7939.58, 1535.42 },`, `[12] = { 1, -5000, -9000, 5000, 1000 },`,
		`build = "12.0.1"`} {
		if !strings.Contains(text, want) {
			t.Errorf("fehlt: %s\n%s", want, text)
		}
	}
}
