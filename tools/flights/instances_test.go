package main

import (
	"strings"
	"testing"
)

const instanceMapCSV = `ID,MapName_lang,InstanceType
43,Wailing Caverns,1
229,Blackrock Spire,1
409,Molten Core,2
13,Test Dungeon,1
35,<unused>StormwindPrison,1
1,Eastern Kingdoms,0
`

const instanceDifficultyCSV = `Message_lang,ID,DifficultyID,LockID,ResetInterval,MaxPlayers,MapID
,1,1,0,0,10,43
,2,201,0,1,10,43
,3,1,0,0,10,229
,4,9,0,2,40,409
,5,1,0,0,100,13
,6,1,0,0,5,35
,7,1,0,0,0,1
`

// Dire-Maul-artiger Eintrag ohne MapID: Kartenname, Alias und zwei Flügel einer Karte
const instanceLFGEraCSV = `ID,Name_lang,MinLevel,MaxLevel,TypeID,MapID
1,Wailing Caverns,15,28,1,0
2,Lower Blackrock Spire,52,60,1,0
3,Upper Blackrock Spire,56,60,2,0
4,Molten Core,60,60,2,0
5,Unbekannt,1,2,1,0
`

func TestParseInstancesEra(t *testing.T) {
	instances, missing, err := ParseInstances("1.15.9.1", "classic_era", strings.NewReader(instanceLFGEraCSV),
		strings.NewReader(instanceDifficultyCSV), strings.NewReader(instanceMapCSV))
	if err != nil {
		t.Fatal(err)
	}
	if len(instances.Modes) != 3 {
		t.Fatalf("Karten = %d, erwartet 3 (Testkarten, unused und Außenwelt entfallen)", len(instances.Modes))
	}
	if mode := instances.Modes[43][1]; mode.Players != 5 {
		t.Errorf("Wehklagen Normal = %d Spieler, erwartet 5 (Era-Dungeon)", mode.Players)
	}
	if mode := instances.Modes[229][1]; mode.Players != 10 {
		t.Errorf("Blackrock Spire = %d Spieler, erwartet 10", mode.Players)
	}
	if mode := instances.Modes[409][9]; mode.Players != 40 || mode.ResetDays != 7 {
		t.Errorf("Molten Core = %+v, erwartet 40 Spieler wöchentlich", mode)
	}
	if instances.Levels[43] != [2]int{15, 28} {
		t.Errorf("Wehklagen Level = %v", instances.Levels[43])
	}
	if instances.Levels[229] != [2]int{52, 60} {
		t.Errorf("Blackrock Spire Level = %v, erwartet die vereinten Bereiche", instances.Levels[229])
	}
	if len(missing) != 1 || missing[0] != "Unbekannt" {
		t.Errorf("ohne Karte = %v", missing)
	}
}

func TestParseInstancesWithoutLevels(t *testing.T) {
	lfg := "ID,Name_lang,TypeID,MapID\n1,Wailing Caverns,1,43\n"
	instances, _, err := ParseInstances("12.0.0.1", "retail", strings.NewReader(lfg),
		strings.NewReader(instanceDifficultyCSV), strings.NewReader(instanceMapCSV))
	if err != nil {
		t.Fatal(err)
	}
	if len(instances.Levels) != 0 {
		t.Errorf("Levels = %v, erwartet keine ohne Level-Spalten", instances.Levels)
	}
	if instances.Modes[43][1].Players != 10 {
		t.Errorf("Spieler = %d, erwartet 10 (nur Era korrigiert)", instances.Modes[43][1].Players)
	}
	var out strings.Builder
	if err := WriteInstancesLua(&out, "retail", instances, "2026-11-10"); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "[43] = { [1] = { 0, 10 }, [201] = { 1, 10 }, },") || strings.Contains(out.String(), "  levels = {") {
		t.Errorf("Lua unerwartet:\n%s", out.String())
	}
}
