package main

// Abgleich der Extractor-Daten mit der von Hand gepflegten Dungeon-DB (ns.DungeonDB, Assist/InstanceData/
// dungeon_db.lua): je Instanz gesehene NPCs, die in der DB fehlen, DB-Bosse, die nie gesehen wurden, abweichende
// Level und Ränge, Beute (selten+) ohne DB-Eintrag, Questgeber-Angebote und Quest->Instanz-Zuordnungen, die der DB
// fehlen. Nur Bericht, die DB bleibt unberührt.

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
)

const (
	dbNpcMissing     = "NPC fehlt"
	dbBossUnseen     = "Boss nie gesehen"
	dbLevel          = "Level"
	dbRank           = "Rang"
	dbLootMissing    = "Beute fehlt"
	dbGiverMissing   = "Geber fehlt"
	dbQuestMissing   = "Quest fehlt"
	dbMaxListed      = 10 // Zeilen je Gruppe im Bericht, der Rest nur als Anzahl
	dbRankBoss       = 3  // Rang in ns.DungeonDB.npcs: 0 normal, 1 Elite, 2 Rar-Elite, 3 Boss, 4 Rar
	dbMinLootQuality = 3  // selten, wie die DB-Beute und der Beute-Sammler
)

// UnitClassification -> Rang der DB (Weltboss zählt über das Boss-Kennzeichen von instanceNpcs)
var classificationRank = map[string]float64{"normal": 0, "trivial": 0, "minus": 0, "elite": 1, "rareelite": 2, "rare": 4}

// LoadDungeonDB führt dungeon_db.lua als WoW Forever aus und gibt ns.DungeonDB zurück.
func LoadDungeonDB(path string) (map[string]any, error) {
	return loadForeverTable(path, "DungeonDB", false)
}

// CheckDungeonDB gibt den Bericht als Text zurück; DB-Instanzen ohne Extractor-Daten nur als Anzahl.
func CheckDungeonDB(db, dungeonDB map[string]any) string {
	findings := map[string][]string{}
	note := func(kind, format string, args ...any) {
		findings[kind] = append(findings[kind], fmt.Sprintf(format, args...))
	}
	seenMaps := checkDBNpcs(db, dungeonDB, note)
	checkDBLoot(db, dungeonDB, note)
	checkDBGivers(db, dungeonDB, note)
	checkDBQuestInstances(db, dungeonDB, note)
	unseen := 0
	for mapID := range table(dungeonDB, "npcs") {
		if !seenMaps[mapID] {
			unseen++
		}
	}

	kinds := []string{dbNpcMissing, dbBossUnseen, dbLevel, dbRank, dbLootMissing, dbGiverMissing, dbQuestMissing}
	var counts []string
	for _, kind := range kinds {
		counts = append(counts, fmt.Sprintf("%d %s", len(findings[kind]), kind))
	}
	var b strings.Builder
	fmt.Fprintf(&b, "-- Abgleich mit der Dungeon-DB: %s, %d Instanzen ohne Extractor-Daten\n", strings.Join(counts, ", "), unseen)
	for _, kind := range kinds {
		lines := findings[kind]
		sort.Strings(lines)
		for i, line := range lines {
			if i == dbMaxListed {
				fmt.Fprintf(&b, "   %-16s ... %d weitere\n", kind, len(lines)-dbMaxListed)
				break
			}
			fmt.Fprintf(&b, "   %-16s %s\n", kind, line)
		}
	}
	return b.String()
}

// NPCs je Instanz gegen npcs[mapID][npcID] = { MinLevel, MaxLevel, Rang }; gibt die Karten mit NPC-Daten zurück
func checkDBNpcs(db, dungeonDB map[string]any, note func(string, string, ...any)) map[string]bool {
	seenMaps := map[string]bool{}
	dbNpcs := table(dungeonDB, "npcs")
	seen := instanceNpcs(db)
	for _, mapID := range sortedKeys(seen) {
		seenMaps[mapID] = true
		known, npcs := table(dbNpcs, mapID), table(seen, mapID)
		for _, npcID := range sortedKeys(npcs) {
			npc, entry := table(npcs, npcID), table(known, npcID)
			name := anyName(table(npc, "names"))
			if entry == nil {
				note(dbNpcMissing, "Karte %s: %s %s", mapID, npcID, name)
				continue
			}
			lo, hasLevel := number(npc, "minLevel")
			hi, _ := number(npc, "maxLevel")
			dbLo, _ := number(entry, "1")
			dbHi, _ := number(entry, "2")
			// Totenkopf-Level (-1) sagt nichts über das echte Level
			if hasLevel && lo > 0 && (lo != dbLo || hi != dbHi) {
				note(dbLevel, "Karte %s: %s %s DB %.0f-%.0f, Daten %.0f-%.0f", mapID, npcID, name, dbLo, dbHi, lo, hi)
			}
			if rank, ok := seenRank(npc); ok {
				if knownRank, _ := number(entry, "3"); knownRank != rank {
					note(dbRank, "Karte %s: %s %s DB %.0f, Daten %.0f", mapID, npcID, name, knownRank, rank)
				}
			}
		}
		for _, npcID := range sortedKeys(known) {
			if rank, _ := number(table(known, npcID), "3"); rank == dbRankBoss && npcs[npcID] == nil {
				note(dbBossUnseen, "Karte %s: %s", mapID, npcID)
			}
		}
	}
	return seenMaps
}

func seenRank(npc map[string]any) (float64, bool) {
	if npc["boss"] == true {
		return dbRankBoss, true
	}
	class, _ := npc["classification"].(string)
	rank, ok := classificationRank[class]
	return rank, ok
}

// instance_loot "npc:<id>" gegen loot[npcID] = { { itemID, Qualität, ... }, ... } (Objekte kennt die DB-Beute nicht)
func checkDBLoot(db, dungeonDB map[string]any, note func(string, string, ...any)) {
	dbLoot, loot := table(dungeonDB, "loot"), instanceLoot(db)
	for _, mapID := range sortedKeys(loot) {
		sources := table(loot, mapID)
		for _, source := range sortedKeys(sources) {
			npcID, isNpc := strings.CutPrefix(source, "npc:")
			if !isNpc {
				continue
			}
			known := map[string]bool{}
			for _, raw := range table(dbLoot, npcID) {
				if id, ok := number(raw.(map[string]any), "1"); ok {
					known[strconv.Itoa(int(id))] = true
				}
			}
			items := table(table(sources, source), "items")
			for _, itemID := range sortedKeys(items) {
				item := table(items, itemID)
				if quality, ok := number(item, "quality"); (ok && quality < dbMinLootQuality) || known[itemID] {
					continue
				}
				count, _ := number(item, "count")
				note(dbLootMissing, "Karte %s: npc %s Item %s %s (%.0fx)", mapID, npcID, itemID, anyName(table(item, "names")), count)
			}
		}
	}
}

// quest_givers gegen givers.npc/object[id] = { questID, ... }; nur Quests, die die DB kennt oder die in einer
// Instanz Fortschritt hatten (die DB führt keine reinen Weltquests)
func checkDBGivers(db, dungeonDB map[string]any, note func(string, string, ...any)) {
	questInfo, progress, dbGivers := table(dungeonDB, "questInfo"), questInstances(db), table(dungeonDB, "givers")
	givers := questGivers(db)
	for _, key := range sortedKeys(givers) {
		kind, id, _ := strings.Cut(key, ":")
		known := map[string]bool{}
		for _, raw := range table(table(dbGivers, kind), id) {
			if questID, ok := raw.(float64); ok {
				known[strconv.Itoa(int(questID))] = true
			}
		}
		giver := table(givers, key)
		for _, questID := range sortedKeys(table(giver, "offers")) {
			if known[questID] || (questInfo[questID] == nil && progress[questID] == nil) {
				continue
			}
			note(dbGiverMissing, "%s %s bietet Quest %s", key, anyName(table(giver, "names")), questID)
		}
	}
}

// quest_instances gegen quests[mapID] = { questID, ... }
func checkDBQuestInstances(db, dungeonDB map[string]any, note func(string, string, ...any)) {
	dbQuests, progress := table(dungeonDB, "quests"), questInstances(db)
	for _, questID := range sortedKeys(progress) {
		maps := table(progress, questID)
		for _, mapID := range sortedKeys(maps) {
			found := false
			for _, raw := range table(dbQuests, mapID) {
				if id, ok := raw.(float64); ok && strconv.Itoa(int(id)) == questID {
					found = true
					break
				}
			}
			if !found {
				note(dbQuestMissing, "Karte %s: Quest %s (%.0fx Fortschritt)", mapID, questID, maps[mapID])
			}
		}
	}
}
