package main

import (
	"strings"
	"testing"
)

// Pfad 302: Rundkurs mit zwei Halten (60 s), Kontinentwechsel dazwischen; Pfad 6 ist eine Flugroute ohne Halt;
// Pfad 436 hat nur einen Halt (kein Transport)
const transportNodeCSV = `Loc_0,Loc_1,Loc_2,ID,PathID,NodeIndex,ContinentID,Flags,Delay,ArrivalEventID,DepartureEventID
0,0,0,1,302,0,1,0,0,0,0
30,40,0,2,302,1,1,2,60,0,0
60,80,0,3,302,2,1,1,0,0,0
0,0,0,4,302,3,0,0,0,0,0
0,100,0,5,302,4,0,2,60,0,0
0,110,0,6,302,5,0,1,0,0,0
0,0,0,7,6,0,0,0,0,0,0
0,9,0,8,6,1,0,0,0,0,0
0,0,0,9,436,0,0,2,60,0,0
0,5,0,10,436,1,0,0,0,0,0
`

func TestParseTransports(t *testing.T) {
	transports, err := ParseTransports("1.60.1.1", strings.NewReader(transportNodeCSV))
	if err != nil {
		t.Fatal(err)
	}
	if len(transports.ByID) != 1 {
		t.Fatalf("Rundkurse = %d, erwartet nur 302", len(transports.ByID))
	}
	stops := transports.ByID["302"]
	// Halt 1 -> Halt 2: 50 bis zum Teleport, danach 0 -> (0,100) = 100; Halt 2 -> Halt 1: 10 bis zum Teleport,
	// Schluss über Kontinentwechsel 0, Anfang (0,0) -> (30,40) = 50
	if len(stops) != 2 || stops[0].Next != 150 || stops[1].Next != 60 || stops[0].Wait != 60 || stops[1].Continent != "0" {
		t.Errorf("Halte = %+v", stops)
	}
	var b strings.Builder
	if err := WriteTransportsLua(&b, "forever", transports, "2026-11-10"); err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{`if ns.Client.Flavor() ~= "forever" then return end`,
		"{ continent = 1, x = 30, y = 40, wait = 60, next = 150 },"} {
		if !strings.Contains(b.String(), want) {
			t.Errorf("fehlt %q in\n%s", want, b.String())
		}
	}
}
