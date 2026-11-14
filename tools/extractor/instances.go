package main

// Abgeleitete Dateien für eine Dungeon-/Schlachtzug-Datenbank aus LevelTimerExtractorDB (je Flavor neben
// <flavor>.json als <flavor>_<name>.json):
//   instance_npcs:   Karten-ID -> npcID -> { names, minLevel, maxLevel, classification, boss, kills, looted }
//   instance_loot:   Karten-ID -> "npc:<id>"|"object:<id>" -> { looted, kills, items: itemID -> { count, chance,
//                    quality, names } } (nur Qualität >= selten, chance = count / looted)
//   quest_givers:    "npc:<id>"|"object:<id>" -> { names, offers: questID -> Anzahl, spots, maps }
//   quest_instances: questID -> Karten-ID -> Anzahl Fortschritte in dieser Instanz

import (
	"math"
	"strconv"
)

// worldbossClass: UnitClassification für Weltbosse (Schädel-Level), zählt wie ein Bossrahmen
const worldbossClass = "worldboss"

// DerivedExports liefert die abgeleiteten Tabellen nach Dateinamen.
func DerivedExports(db map[string]any) map[string]any {
	return map[string]any{
		"instance_npcs":   instanceNpcs(db),
		"instance_loot":   instanceLoot(db),
		"quest_givers":    questGivers(db),
		"quest_instances": questInstances(db),
	}
}

func instanceNpcs(db map[string]any) map[string]any {
	out := map[string]any{}
	for npcID, raw := range table(db, "npcs") {
		npc, _ := raw.(map[string]any)
		instances := table(npc, "instances")
		if len(instances) == 0 {
			continue
		}
		entry := map[string]any{"names": npc["names"], "classification": npc["classification"]}
		if lo, hi, ok := levelRange(table(npc, "levels")); ok {
			entry["minLevel"], entry["maxLevel"] = lo, hi
		}
		entry["boss"] = npc["boss"] == true || npc["classification"] == worldbossClass
		for _, key := range []string{"kills", "looted"} {
			if n, ok := number(npc, key); ok {
				entry[key] = n
			}
		}
		for mapID := range instances {
			subTable(out, mapID)[npcID] = entry
		}
	}
	return out
}

func levelRange(levels map[string]any) (float64, float64, bool) {
	lo, hi := math.Inf(1), math.Inf(-1)
	for key := range levels {
		if level, err := strconv.ParseFloat(key, 64); err == nil {
			lo, hi = math.Min(lo, level), math.Max(hi, level)
		}
	}
	return lo, hi, len(levels) > 0 && !math.IsInf(lo, 1)
}

func instanceLoot(db map[string]any) map[string]any {
	out := map[string]any{}
	items, npcs := table(db, "items"), table(db, "npcs")
	for mapID, raw := range table(db, "instances") {
		instance, _ := raw.(map[string]any)
		for source, rawDrop := range table(instance, "drops") {
			drop, _ := rawDrop.(map[string]any)
			looted, _ := number(drop, "looted")
			entry := map[string]any{"looted": looted}
			if len(source) > 4 && source[:4] == "npc:" {
				if kills, ok := number(table(npcs, source[4:]), "kills"); ok {
					entry["kills"] = kills
				}
			}
			list := map[string]any{}
			for itemID, rawCount := range table(drop, "items") {
				count, _ := rawCount.(float64)
				item := map[string]any{"count": count}
				if looted > 0 {
					item["chance"] = math.Round(count/looted*1000) / 1000
				}
				if info := table(items, itemID); info != nil {
					item["quality"], item["names"] = info["quality"], info["names"]
				}
				list[itemID] = item
			}
			entry["items"] = list
			subTable(out, mapID)[source] = entry
		}
	}
	return out
}

func questGivers(db map[string]any) map[string]any {
	out := map[string]any{}
	for section, prefix := range map[string]string{"npcs": "npc:", "objects": "object:"} {
		for id, raw := range table(db, section) {
			giver, _ := raw.(map[string]any)
			if len(table(giver, "offers")) == 0 {
				continue
			}
			entry := map[string]any{}
			for _, key := range []string{"names", "offers", "spots", "maps"} {
				if value, ok := giver[key]; ok {
					entry[key] = value
				}
			}
			out[prefix+id] = entry
		}
	}
	return out
}

func questInstances(db map[string]any) map[string]any {
	out := map[string]any{}
	for questID, raw := range table(db, "quests") {
		quest, _ := raw.(map[string]any)
		for _, rawProgress := range table(quest, "progress") {
			progress, _ := rawProgress.(map[string]any)
			for mapID, rawCount := range table(progress, "instances") {
				count, _ := rawCount.(float64)
				maps := subTable(out, questID)
				previous, _ := maps[mapID].(float64)
				maps[mapID] = previous + count
			}
		}
	}
	return out
}

// Untertabelle m[key], bei Bedarf angelegt
func subTable(m map[string]any, key string) map[string]any {
	t, ok := m[key].(map[string]any)
	if !ok {
		t = map[string]any{}
		m[key] = t
	}
	return t
}
