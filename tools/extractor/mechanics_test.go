package main

import (
	"path/filepath"
	"strings"
	"testing"
)

// Kampflog-Zauber gegen Mechaniken: bestätigt, fehlt, spellID-0-Kandidaten, ungenutzte Zauber, NPC ohne Daten
func TestCheckMechanics(t *testing.T) {
	spell := func(name string, count float64) map[string]any {
		return map[string]any{"names": map[string]any{"deDE": name}, "count": count}
	}
	db := map[string]any{"instances": map[string]any{
		"36": map[string]any{"spells": map[string]any{
			"645": map[string]any{"count": 2.0, "5174": spell("Kochen", 3), "6306": spell("Säure", 1)},
			"644": map[string]any{"count": 1.0, "name:Hieb": spell("Hieb", 2)},
			"639": map[string]any{"count": 1.0, "3391": spell("Raserei", 4)},
		}},
		"34": map[string]any{"spells": map[string]any{
			"645": map[string]any{"count": 1.0, "5174": spell("Kochen", 1)},
		}},
	}}
	line := func(id float64, kind string) map[string]any { return map[string]any{"1": id, "2": kind} }
	mechanics := map[string]any{
		"645": map[string]any{"1": line(5174, "interrupt"), "2": line(9999, "avoid")},
		"644": map[string]any{"1": line(0, "tank")},
		"639": map[string]any{"1": line(3391, "tank")},
		"622": map[string]any{"1": line(3605, "adds")},
	}
	report := CheckMechanics(db, mechanics)
	for _, want := range []string{
		"2 bestätigt, 1 fehlen im Log, 1 NPCs mit spellID 0 und Kandidaten, 1 NPCs mit ungenutzten Zaubern, 1 NPCs ohne Kampflog-Daten",
		"bestätigt    npc 645: 5174 Kochen (4x)",
		"bestätigt    npc 639: 3391 Raserei (4x)",
		"fehlt im Log npc 645: 9999 (avoid)",
		"ohne ID      npc 644: Kandidaten name:Hieb Hieb (2x)",
		"ungenutzt    npc 645: 6306 Säure (1x)",
	} {
		if !strings.Contains(report, want) {
			t.Errorf("Bericht ohne %q:\n%s", want, report)
		}
	}
	if spells := table(table(instanceSpells(db), "36"), "645"); spells["count"] != nil || spells["5174"] == nil {
		t.Errorf("instance_spells ohne Zähler je NPC erwartet: %v", spells)
	}
}

// Die echten Mechaniken müssen sich laden lassen (nur Forever-Zeilen, NPCs mit Zeilen)
func TestLoadRealMechanics(t *testing.T) {
	mechanics, err := LoadMechanics(filepath.Join("..", "..", "Assist", "InstanceData", "mechanics.lua"))
	if err != nil {
		t.Fatal(err)
	}
	if len(mechanics) < 50 || len(table(mechanics, "645")) == 0 {
		t.Errorf("ns.Mechanics unerwartet klein: %d NPCs", len(mechanics))
	}
}
