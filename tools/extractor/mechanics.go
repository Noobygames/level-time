package main

// Abgleich der Gegner-Zauber aus dem Kampflog (instances[mapID].spells, LevelTimer_DataExtractor/Collect/
// CombatSpells.lua) mit ns.Mechanics (Assist/InstanceData/mechanics.lua): je NPC mit Mechaniken und Kampflog-Daten,
// welche Zauber-IDs bestätigt sind, welche nie im Log auftauchen, was für Zeilen mit spellID 0 in Frage kommt und
// welche gesehenen Zauber keine Mechanik haben. Nur Bericht, die Mechaniken bleiben unberührt.

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
)

const (
	spellConfirmed = "bestätigt"
	spellMissing   = "fehlt im Log"
	spellNoID      = "ohne ID"
	spellExtra     = "ungenutzt"
	countKey       = "count" // Zähler der Zauber je NPC in spells[npcID], kein Zauber
)

// LoadMechanics führt mechanics.lua als WoW Forever aus und gibt ns.Mechanics zurück (npcID -> Liste von Zeilen
// { spellID, Typ, Text deDE, Text enUS, Kennung }). Die Datei filtert am Ende mit pairs/table.remove, darum mit
// Standardbibliotheken (Repo-Datei, kein fremder Inhalt).
func LoadMechanics(path string) (map[string]any, error) {
	return loadForeverTable(path, "Mechanics", true)
}

// instanceSpells: Karten-ID -> npcID -> Zauber-Schlüssel -> { names, count, events } (ohne den Zähler je NPC)
func instanceSpells(db map[string]any) map[string]any {
	out := map[string]any{}
	for mapID, raw := range table(db, "instances") {
		instance, _ := raw.(map[string]any)
		for npcID, rawSpells := range table(instance, "spells") {
			spells, _ := rawSpells.(map[string]any)
			list := map[string]any{}
			for key, spell := range spells {
				if key != countKey {
					list[key] = spell
				}
			}
			subTable(out, mapID)[npcID] = list
		}
	}
	return out
}

// seenSpells: npcID -> Zauber-Schlüssel -> Anzahl über alle Instanzen, dazu je Schlüssel ein Name
func seenSpells(db map[string]any) (map[string]map[string]float64, map[string]string) {
	seen, names := map[string]map[string]float64{}, map[string]string{}
	for _, npcs := range instanceSpells(db) {
		for npcID, rawSpells := range npcs.(map[string]any) {
			if seen[npcID] == nil {
				seen[npcID] = map[string]float64{}
			}
			for key, rawSpell := range rawSpells.(map[string]any) {
				spell, _ := rawSpell.(map[string]any)
				count, _ := number(spell, "count")
				seen[npcID][key] += count
				names[key] = anyName(table(spell, "names"))
			}
		}
	}
	return seen, names
}

// Erster Name in fester Sprachreihenfolge
func anyName(names map[string]any) string {
	for _, locale := range append([]string{"deDE", "enUS"}, sortedKeys(names)...) {
		if name, ok := names[locale].(string); ok {
			return name
		}
	}
	return ""
}

// CheckMechanics gibt den Bericht als Text zurück; NPCs mit Mechaniken, aber ohne Kampflog-Daten nur als Anzahl.
func CheckMechanics(db, mechanics map[string]any) string {
	seen, names := seenSpells(db)
	findings := map[string][]string{}
	note := func(kind, format string, args ...any) {
		findings[kind] = append(findings[kind], fmt.Sprintf(format, args...))
	}
	unseen := 0
	for _, npcID := range sortedKeys(mechanics) {
		spells := seen[npcID]
		if len(spells) == 0 {
			unseen++
			continue
		}
		used, hasNoID := map[string]bool{}, false
		for _, rawLine := range mechanics[npcID].(map[string]any) {
			line, _ := rawLine.(map[string]any)
			id, _ := number(line, "1")
			if id == 0 {
				hasNoID = true
				continue
			}
			key := strconv.Itoa(int(id))
			used[key] = true
			if count, ok := spells[key]; ok {
				note(spellConfirmed, "npc %s: %s %s (%.0fx)", npcID, key, names[key], count)
			} else {
				note(spellMissing, "npc %s: %s (%v)", npcID, key, line["2"])
			}
		}
		var extra []string
		for _, key := range sortedKeys(toAny(spells)) {
			if !used[key] {
				extra = append(extra, fmt.Sprintf("%s %s (%.0fx)", key, names[key], spells[key]))
			}
		}
		if len(extra) == 0 {
			continue
		}
		if hasNoID {
			note(spellNoID, "npc %s: Kandidaten %s", npcID, strings.Join(extra, ", "))
		} else {
			note(spellExtra, "npc %s: %s", npcID, strings.Join(extra, ", "))
		}
	}

	var b strings.Builder
	fmt.Fprintf(&b, "-- Abgleich mit den Mechaniken: %d bestätigt, %d fehlen im Log, %d NPCs mit spellID 0 und Kandidaten, "+
		"%d NPCs mit ungenutzten Zaubern, %d NPCs ohne Kampflog-Daten\n", len(findings[spellConfirmed]),
		len(findings[spellMissing]), len(findings[spellNoID]), len(findings[spellExtra]), unseen)
	for _, kind := range []string{spellMissing, spellNoID, spellExtra, spellConfirmed} {
		lines := findings[kind]
		sort.Strings(lines)
		for _, line := range lines {
			fmt.Fprintf(&b, "   %-12s %s\n", kind, line)
		}
	}
	return b.String()
}

func toAny(m map[string]float64) map[string]any {
	out := make(map[string]any, len(m))
	for k, v := range m {
		out[k] = v
	}
	return out
}
