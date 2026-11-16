package main

import (
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
)

// Vergleich der Forever-Extractor-Daten mit dem von Hand gepflegten Dungeonführer (ns.InstanceGuide): je Eingang,
// Boss-Level und Quest (Level, Startort) bestätigt, widerspricht oder ergänzt. Nur Bericht, der Führer bleibt unberührt.

const (
	grid          = 100  // Kartenzellen je Achse wie GRID in LevelTimer_DataExtractor/Core.lua
	spotTolerance = 0.03 // Abstand in Kartenanteilen, ab dem ein Ort als anderer Ort gilt
)

const (
	confirms    = "bestätigt"
	contradicts = "widerspricht"
	adds        = "ergänzt"
)

// CheckGuide gibt den Bericht als Text zurück, gruppiert nach Ergebnis.
func CheckGuide(db, guide map[string]any) string {
	findings := map[string][]string{}
	note := func(kind, format string, args ...any) {
		findings[kind] = append(findings[kind], fmt.Sprintf(format, args...))
	}
	checkEntrances(db, guide, note)
	checkBossLevels(db, guide, note)
	checkQuests(db, guide, note)

	var b strings.Builder
	fmt.Fprintf(&b, "-- Abgleich mit dem Dungeonführer: %d bestätigt, %d widersprechen, %d ergänzen\n",
		len(findings[confirms]), len(findings[contradicts]), len(findings[adds]))
	for _, kind := range []string{contradicts, adds, confirms} {
		lines := findings[kind]
		sort.Strings(lines)
		for _, line := range lines {
			fmt.Fprintf(&b, "   %-12s %s\n", kind, line)
		}
	}
	return b.String()
}

// instances[mapID].entrances[uiMapID][Zelle] gegen entrances[mapID] = { { uiMapID, x, y }, ... }
func checkEntrances(db, guide map[string]any, note func(string, string, ...any)) {
	instances := table(db, "instances")
	for _, mapID := range sortedKeys(instances) {
		entrances := table(table(instances, mapID), "entrances")
		for _, uiMapID := range sortedKeys(entrances) {
			cell, count := topCell(table(entrances, uiMapID))
			if count == 0 {
				continue
			}
			x, y := cellToXY(cell)
			data := fmt.Sprintf("%s %.3f,%.3f (%.0fx)", uiMapID, x, y, count)
			guideSpot, distance := nearestGuideSpot(table(table(guide, "entrances"), mapID), uiMapID, x, y)
			switch {
			case guideSpot == "":
				note(adds, "Eingang Karte %s: %s", mapID, data)
			case distance <= spotTolerance:
				note(confirms, "Eingang Karte %s: %s", mapID, data)
			default:
				note(contradicts, "Eingang Karte %s: Führer %s, Daten %s", mapID, guideSpot, data)
			}
		}
	}
}

// Boss-Level = höchstes (häufigstes) Level der Ziele während des Kampfes; Totenkopf-Level (-1) zählt nicht
func checkBossLevels(db, guide map[string]any, note func(string, string, ...any)) {
	instances, npcs, bossLevels := table(db, "instances"), table(db, "npcs"), table(guide, "bossLevels")
	for _, mapID := range sortedKeys(instances) {
		encounters := table(table(instances, mapID), "encounters")
		for _, encounterID := range sortedKeys(encounters) {
			level := 0
			for npcID := range table(table(encounters, encounterID), "npcs") {
				if l := topKey(table(table(npcs, npcID), "levels")); l > level {
					level = l
				}
			}
			if level <= 0 {
				continue
			}
			guideLevel, known := number(bossLevels, encounterID)
			switch {
			case !known:
				note(adds, "Boss-Level Begegnung %s (Karte %s): %d", encounterID, mapID, level)
			case int(guideLevel) == level:
				note(confirms, "Boss-Level Begegnung %s: %d", encounterID, level)
			default:
				note(contradicts, "Boss-Level Begegnung %s: Führer %.0f, Daten %d", encounterID, guideLevel, level)
			}
		}
	}
}

// quests[mapID] = { { questID, Level, Mindestlevel, Fraktion, Klasse, Name, Start-uiMapID, x, y }, ... }
func checkQuests(db, guide map[string]any, note func(string, string, ...any)) {
	quests, guideQuests := table(db, "quests"), table(guide, "quests")
	for _, mapID := range sortedKeys(guideQuests) {
		list := table(guideQuests, mapID)
		for _, index := range sortedKeys(list) {
			entry := table(list, index)
			id, _ := number(entry, "1")
			questID := strconv.Itoa(int(id))
			quest := table(quests, questID)
			if quest == nil {
				continue
			}
			if level, ok := number(quest, "level"); ok {
				guideLevel, _ := number(entry, "2")
				if guideLevel == level {
					note(confirms, "Questlevel %s: %.0f", questID, level)
				} else {
					note(contradicts, "Questlevel %s: Führer %.0f, Daten %.0f", questID, guideLevel, level)
				}
			}
			checkQuestStart(questID, entry, quest, note)
		}
	}
}

func checkQuestStart(questID string, entry, quest map[string]any, note func(string, string, ...any)) {
	spots := table(table(quest, "startSpots"), "spots")
	bestMap, bestCell, bestCount := "", 0, 0.0
	for _, uiMapID := range sortedKeys(spots) {
		if cell, count := topCell(table(spots, uiMapID)); count > bestCount {
			bestMap, bestCell, bestCount = uiMapID, cell, count
		}
	}
	if bestCount == 0 {
		return
	}
	x, y := cellToXY(bestCell)
	giver := sortedKeys(table(quest, "starts"))
	data := fmt.Sprintf("%s %.3f,%.3f %s (%.0fx)", bestMap, x, y, strings.Join(giver, "/"), bestCount)
	guideMap, hasMap := number(entry, "7")
	gx, hasX := number(entry, "8")
	gy, _ := number(entry, "9")
	switch {
	case !hasMap || !hasX:
		note(adds, "Queststart %s: %s", questID, data)
	case strconv.Itoa(int(guideMap)) == bestMap && math.Hypot(gx-x, gy-y) <= spotTolerance:
		note(confirms, "Queststart %s: %s", questID, data)
	default:
		note(contradicts, "Queststart %s: Führer %.0f %.3f,%.3f, Daten %s", questID, guideMap, gx, gy, data)
	}
}

// Nächster Führer-Ort auf derselben Karte als Text und sein Abstand ("" ohne Ort auf dieser Karte)
func nearestGuideSpot(list map[string]any, uiMapID string, x, y float64) (string, float64) {
	best, bestDistance := "", math.Inf(1)
	for _, index := range sortedKeys(list) {
		spot := table(list, index)
		m, _ := number(spot, "1")
		gx, _ := number(spot, "2")
		gy, _ := number(spot, "3")
		if strconv.Itoa(int(m)) != uiMapID {
			continue
		}
		if d := math.Hypot(gx-x, gy-y); d < bestDistance {
			best, bestDistance = fmt.Sprintf("%s %.3f,%.3f", uiMapID, gx, gy), d
		}
	}
	return best, bestDistance
}

// Häufigste Zelle einer Zellen-Tabelle (Feld "count" = Zahl der Zellen, kein Ort); bei Gleichstand die kleinste
func topCell(cells map[string]any) (int, float64) {
	best, bestCount := 0, 0.0
	for _, key := range sortedKeys(cells) {
		cell, err := strconv.Atoi(key)
		count, _ := cells[key].(float64)
		if err == nil && (count > bestCount || count == bestCount && cell < best) {
			best, bestCount = cell, count
		}
	}
	return best, bestCount
}

// Häufigster Schlüssel einer Zähl-Tabelle wie levels[Level] = Anzahl (0, wenn leer)
func topKey(counts map[string]any) int {
	cell, _ := topCell(counts)
	return cell
}

func cellToXY(cell int) (float64, float64) {
	return (float64(cell/grid) + 0.5) / grid, (float64(cell%grid) + 0.5) / grid
}
