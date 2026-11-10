package main

import (
	"math"
	"strings"
	"testing"
)

// Strecke 6 (2>4): 3-4-5-Dreieck 5 + 5 Yards, Halt 10 s, danach Teleport (zählt nicht);
// Strecke 9 ist eine zweite 2>4 mit größerer ID (ignoriert); Strecke 7 (4>2): 20 Yards
const taxiPathCSV = `ID,FromTaxiNode,ToTaxiNode,Cost
9,2,4,1
6,2,4,110
7,4,2,110
`

const taxiPathNodeCSV = `Loc_0,Loc_1,Loc_2,ID,PathID,NodeIndex,ContinentID,Flags,Delay,ArrivalEventID,DepartureEventID
0,0,0,1,6,0,0,0,0,0,0
3,4,0,2,6,1,0,2,10,0,0
6,8,0,3,6,2,0,1,0,0,0
500,500,0,4,6,3,0,0,0,0,0
0,0,0,5,9,0,0,0,0,0,0
99,0,0,6,9,1,0,0,0,0,0
0,0,0,7,7,0,1,0,0,0,0
0,20,0,8,7,1,1,0,0,0,0
`

func testPaths(t *testing.T) *Paths {
	t.Helper()
	paths, err := ParsePaths("1.60.1.1", strings.NewReader(taxiPathCSV), strings.NewReader(taxiPathNodeCSV))
	if err != nil {
		t.Fatal(err)
	}
	return paths
}

func TestParsePaths(t *testing.T) {
	paths := testPaths(t)
	if leg := paths.Legs["2>4"]; leg.Length != 10 || leg.Stops != 10 {
		t.Errorf("2>4 = %+v, erwartet 10 Yards ohne Teleport, 10 s Halt, kleinste ID", leg)
	}
	if leg := paths.Legs["4>2"]; leg.Length != 20 {
		t.Errorf("4>2 = %+v", leg)
	}
}

func TestMeasuredSpeed(t *testing.T) {
	paths := testPaths(t)
	routes := map[string]map[string]*Route{"1411": {
		"4>2": {Samples: []float64{2}},                               // direkt: 20 / 2 = 10
		"2>4": {Samples: []float64{100}, Hops: []float64{2}},         // Zwischenhalt: direkte Strecke passt nicht
		"2>9": {Samples: []float64{25}, PathLengths: []float64{300}}, // gemerkte Flugroute: 300 / 25 = 12
	}}
	speed := MeasuredSpeed(routes, paths)
	if speed == nil || speed.Samples != 2 || math.Abs(speed.YardsPerSecond-11) > 1e-9 {
		t.Fatalf("speed = %+v, erwartet Median 11 aus 2 Strecken", speed)
	}
}

func TestWritePathsLua(t *testing.T) {
	var b strings.Builder
	speed := &Speed{YardsPerSecond: 29.78, Samples: 3, BorrowedFrom: "forever"}
	if err := WritePathsLua(&b, "classic_era", testPaths(t), speed, "2026-11-10"); err != nil {
		t.Fatal(err)
	}
	out := b.String()
	for _, want := range []string{
		`if ns.Client.Flavor() ~= "classic_era" then return end`,
		`speed = { yardsPerSecond = 29.78, samples = 3, borrowedFrom = "forever" },`,
		`["2>4"] = 10,`, `["4>2"] = 20,`,
		"  stops = {\n    [\"2>4\"] = 10,\n  },",
	} {
		if !strings.Contains(out, want) {
			t.Errorf("fehlt %q in\n%s", want, out)
		}
	}
}
