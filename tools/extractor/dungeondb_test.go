package main

import (
	"path/filepath"
	"strings"
	"testing"
)

// Extractor-Daten gegen eine kleine Dungeon-DB: fehlende NPCs, ungesehene Bosse, Level/Rang, Beute, Geber, Quests
func TestCheckDungeonDB(t *testing.T) {
	names := func(name string) map[string]any { return map[string]any{"deDE": name} }
	db := map[string]any{
		"npcs": map[string]any{
			"100": map[string]any{"names": names("Wache"), "classification": "elite", "levels": map[string]any{"20": 3.0, "21": 1.0},
				"instances": map[string]any{"33": 1.0}},
			"101": map[string]any{"names": names("Ratte"), "classification": "normal", "levels": map[string]any{"18": 1.0},
				"instances": map[string]any{"33": 1.0}},
			"102": map[string]any{"names": names("Boss"), "classification": "elite", "boss": true, "levels": map[string]any{"-1": 1.0},
				"instances": map[string]any{"33": 1.0}, "offers": map[string]any{"500": 1.0, "900": 1.0}},
			"104": map[string]any{"names": names("Rar"), "classification": "rare", "levels": map[string]any{"22": 1.0},
				"instances": map[string]any{"33": 1.0}},
		},
		"items": map[string]any{
			"7001": map[string]any{"quality": 3.0, "names": names("Schwert")},
			"7002": map[string]any{"quality": 2.0, "names": names("Grün")},
			"7003": map[string]any{"quality": 4.0, "names": names("Episch")},
		},
		"instances": map[string]any{"33": map[string]any{"drops": map[string]any{
			"npc:102": map[string]any{"looted": 2.0, "items": map[string]any{"7001": 1.0, "7002": 1.0, "7003": 1.0}},
		}}},
		"quests": map[string]any{
			"500": map[string]any{"progress": map[string]any{"1": map[string]any{"instances": map[string]any{"33": 2.0}}}},
			"501": map[string]any{"progress": map[string]any{"1": map[string]any{"instances": map[string]any{"33": 1.0}}}},
		},
	}
	dungeonDB := map[string]any{
		"npcs": map[string]any{
			"33": map[string]any{
				"100": map[string]any{"1": 20.0, "2": 20.0, "3": 1.0},
				"102": map[string]any{"1": 24.0, "2": 24.0, "3": 3.0},
				"103": map[string]any{"1": 25.0, "2": 25.0, "3": 3.0},
				"104": map[string]any{"1": 22.0, "2": 22.0, "3": 2.0},
			},
			"34": map[string]any{"200": map[string]any{"1": 24.0, "2": 25.0, "3": 3.0}},
		},
		"loot":      map[string]any{"102": map[string]any{"1": map[string]any{"1": 7001.0, "2": 3.0}}},
		"givers":    map[string]any{"npc": map[string]any{"102": map[string]any{"1": 501.0}}},
		"questInfo": map[string]any{"500": map[string]any{}},
		"quests":    map[string]any{"33": map[string]any{"1": 501.0}},
	}
	report := CheckDungeonDB(db, dungeonDB)
	for _, want := range []string{
		"1 NPC fehlt, 1 Boss nie gesehen, 1 Level, 1 Rang, 1 Beute fehlt, 1 Geber fehlt, 1 Quest fehlt, 1 Instanzen ohne Extractor-Daten",
		"NPC fehlt        Karte 33: 101 Ratte",
		"Boss nie gesehen Karte 33: 103",
		"Level            Karte 33: 100 Wache DB 20-20, Daten 20-21",
		"Rang             Karte 33: 104 Rar DB 2, Daten 4",
		"Beute fehlt      Karte 33: npc 102 Item 7003 Episch (1x)",
		"Geber fehlt      npc:102 Boss bietet Quest 500",
		"Quest fehlt      Karte 33: Quest 500 (2x Fortschritt)",
	} {
		if !strings.Contains(report, want) {
			t.Errorf("Bericht ohne %q:\n%s", want, report)
		}
	}
	if strings.Contains(report, "7002") || strings.Contains(report, "Quest 900") {
		t.Errorf("Bericht mit gefilterter Beute oder Weltquest:\n%s", report)
	}
}

// Die echte dungeon_db.lua lädt als Forever und hat alle Bereiche, die der Abgleich liest
func TestLoadDungeonDBRealFile(t *testing.T) {
	dungeonDB, err := LoadDungeonDB(filepath.Join("..", "..", "Assist", "InstanceData", "dungeon_db.lua"))
	if err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"npcs", "loot", "givers", "questInfo", "quests"} {
		if len(table(dungeonDB, key)) == 0 {
			t.Errorf("ns.DungeonDB.%s leer", key)
		}
	}
}
