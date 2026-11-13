package main

import (
	"fmt"
	"io"
	"sort"
	"strconv"
	"strings"
)

// Boss-Listen je Instanz aus den Spieldaten (DB2-Tabelle DungeonEncounter: Name_lang, ID, MapID, DifficultyID,
// OrderIndex), Namen in allen Sprachen aus NameLocales (wago.tools, Parameter locale). ID = encounterID von
// ENCOUNTER_END; DifficultyID 0 = alle Schwierigkeiten. Reihenfolge je Karte nach OrderIndex, der letzte gilt als Endboss.

// BossFlavors bekommen die Boss-Datei. shortcut: Retail fehlt (tausende Encounter aller Erweiterungen, dort zählt
// Instances nur die Kills ohne Liste); bei Bedarf über das Encounter-Journal (EJ_*) des Clients nachrüsten.
var BossFlavors = map[string]bool{"classic_era": true, "anniversary": true, "forever": true}

// Bosses sind die Boss-Listen eines Builds: Karte -> Schwierigkeit -> encounterIDs, Namen je encounterID in der
// Reihenfolge von NameLocales.
type Bosses struct {
	Build string
	Maps  map[int]map[int][]int
	Names map[int][]string
}

type bossRow struct{ id, order int }

// ParseBosses liest DungeonEncounter je Sprache (tables[i] gehört zu NameLocales[i], die erste bestimmt die Listen).
func ParseBosses(build string, tables []io.Reader) (*Bosses, error) {
	bosses := &Bosses{Build: build, Maps: map[int]map[int][]int{}, Names: map[int][]string{}}
	rows := map[int]map[int][]bossRow{}
	for index, table := range tables {
		records, err := readCSV(table)
		if err != nil {
			return nil, fmt.Errorf("DungeonEncounter %s: %w", NameLocales[index], err)
		}
		for _, record := range records {
			id := integer(record["ID"])
			if id <= 0 {
				continue
			}
			if index == 0 {
				mapID, difficulty := integer(record["MapID"]), integer(record["DifficultyID"])
				if rows[mapID] == nil {
					rows[mapID] = map[int][]bossRow{}
				}
				rows[mapID][difficulty] = append(rows[mapID][difficulty], bossRow{id, integer(record["OrderIndex"])})
				bosses.Names[id] = make([]string, len(tables))
			}
			if names, ok := bosses.Names[id]; ok {
				names[index] = record["Name_lang"]
			}
		}
	}
	for mapID, byDifficulty := range rows {
		bosses.Maps[mapID] = map[int][]int{}
		for difficulty, list := range byDifficulty {
			sort.Slice(list, func(i, j int) bool {
				if list[i].order != list[j].order {
					return list[i].order < list[j].order
				}
				return list[i].id < list[j].id
			})
			ids := make([]int, len(list))
			for i, row := range list {
				ids[i] = row.id
			}
			bosses.Maps[mapID][difficulty] = ids
		}
	}
	return bosses, nil
}

// bossNameLua: ein String, wenn alle Sprachen gleich heißen, sonst eine Liste je Sprache (leer = Englisch)
func bossNameLua(names []string) string {
	same := true
	for _, name := range names {
		same = same && (name == names[0] || name == "")
	}
	if same {
		return strconv.Quote(names[0])
	}
	quoted := make([]string, len(names))
	for i, name := range names {
		quoted[i] = strconv.Quote(name)
	}
	return "{ " + strings.Join(quoted, ", ") + " }"
}

// WriteBossesLua schreibt Assist/BossData/<flavor>.lua (frühes return in anderen Flavors).
func WriteBossesLua(w io.Writer, flavor string, bosses *Bosses, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 DungeonEncounter von wago.tools,\n")
	fmt.Fprintf(&b, "-- Build %s), Stand %s. Nicht von Hand ändern.\n", bosses.Build, date)
	b.WriteString("-- ns.BossData = { build, locales, maps = { [Karten-ID] = { [DifficultyID, 0 = alle] = { encounterID, ... } } },\n")
	b.WriteString("-- names = { [encounterID] = Name oder { Name je Sprache aus locales } } }; Reihenfolge = OrderIndex, letzter = Endboss.\n")
	b.WriteString("-- Lesen: History/InstanceBosses.lua.\n")
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	fmt.Fprintf(&b, "ns.BossData = {\n  build = %q,\n  locales = { ", bosses.Build)
	for _, locale := range NameLocales {
		fmt.Fprintf(&b, "%q, ", locale)
	}
	b.WriteString("},\n  maps = {\n")
	for _, mapID := range sortedMapIDs(bosses.Maps) {
		fmt.Fprintf(&b, "    [%d] = {", mapID)
		for _, difficulty := range sortedMapIDs(bosses.Maps[mapID]) {
			ids := make([]string, len(bosses.Maps[mapID][difficulty]))
			for i, id := range bosses.Maps[mapID][difficulty] {
				ids[i] = strconv.Itoa(id)
			}
			fmt.Fprintf(&b, " [%d] = { %s },", difficulty, strings.Join(ids, ", "))
		}
		b.WriteString(" },\n")
	}
	b.WriteString("  },\n  names = {\n")
	for _, id := range sortedMapIDs(bosses.Names) {
		fmt.Fprintf(&b, "    [%d] = %s,\n", id, bossNameLua(bosses.Names[id]))
	}
	b.WriteString("  },\n}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
