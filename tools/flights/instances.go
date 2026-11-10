package main

import (
	"fmt"
	"io"
	"sort"
	"strconv"
	"strings"
)

// Instanz-Stammdaten aus den Spieldaten (DB2-Tabellen von wago.tools):
//   Map            ID, MapName_lang, InstanceType     1 = Dungeon, 2 = Raid (nur diese Karten kommen in die Datei)
//   MapDifficulty  MapID, DifficultyID, ResetInterval, MaxPlayers   Reset und Gruppengröße je Schwierigkeit
//   LFGDungeons    Name_lang, MinLevel, MaxLevel, TypeID, MapID     Level-Bereich (nur Era und Anniversary;
//                  Retail und Forever haben keine Level-Spalten)
// Die Era-Tabelle trägt MapID 0; die Karte kommt dann über den Namen (Map.MapName_lang), Lücken füllt lfgMapAliases.

const (
	instanceTypeDungeon = 1
	instanceTypeRaid    = 2
	lfgTypeDungeon      = "1"
	lfgTypeRaid         = "2"
	maxInstancePlayers  = 40 // darüber sind es Testkarten ("Test Dungeon": 100)
	partyDungeonPlayers = 5
	blackrockSpire      = 229 // 10 Spieler laut Daten, bleibt
)

// resetIntervalDays rechnet ResetInterval in Tage um (0 = kein Reset). 5 (SoD-Schlachtzüge) als wöchentlich angenommen.
var resetIntervalDays = map[int]int{0: 0, 1: 1, 2: 7, 3: 3, 4: 5, 5: 7}

// lfgMapAliases: LFG-Namen (oder deren Anfang), die ohne MapID nicht zum Kartennamen passen
var lfgMapAliases = map[string]int{
	"Stormwind Stockades":   34,
	"Zul'Farak":             209,
	"Lower Blackrock Spire": blackrockSpire,
	"Upper Blackrock Spire": blackrockSpire,
	"Dire Maul":             429,
	"Onyxia":                249,
	"Ahn'Qiraj Ruins":       509,
	"Serpentshrine Cavern":  548,
	"Hyjal Past":            534,
}

// Mode ist Reset (Tage, 0 = keiner) und Gruppengröße einer Schwierigkeit.
type Mode struct {
	ResetDays int
	Players   int
}

// Instances sind die Stammdaten eines Builds: Modi je Karte und Schwierigkeit, Level-Bereich je Karte.
type Instances struct {
	Build  string
	Modes  map[int]map[int]Mode
	Levels map[int][2]int
}

func integer(text string) int {
	value, _ := strconv.Atoi(text)
	return value
}

// instanceMaps liefert Karten-ID -> Name der Dungeons und Raids.
func instanceMaps(rows []map[string]string) map[int]string {
	maps := map[int]string{}
	for _, row := range rows {
		kind := integer(row["InstanceType"])
		name := row["MapName_lang"]
		if (kind == instanceTypeDungeon || kind == instanceTypeRaid) && !strings.HasPrefix(name, "<unused>") {
			maps[integer(row["ID"])] = name
		}
	}
	return maps
}

func parseModes(rows []map[string]string, maps map[int]string) map[int]map[int]Mode {
	modes := map[int]map[int]Mode{}
	for _, row := range rows {
		mapID := integer(row["MapID"])
		players := integer(row["MaxPlayers"])
		if _, ok := maps[mapID]; !ok || players <= 0 || players > maxInstancePlayers {
			continue
		}
		if modes[mapID] == nil {
			modes[mapID] = map[int]Mode{}
		}
		modes[mapID][integer(row["DifficultyID"])] = Mode{
			ResetDays: resetIntervalDays[integer(row["ResetInterval"])],
			Players:   players,
		}
	}
	return modes
}

// lfgMapID: Karte eines LFG-Eintrags (MapID, sonst Kartenname, sonst Alias); 0 = nicht gefunden
func lfgMapID(row map[string]string, maps map[int]string) int {
	if id := integer(row["MapID"]); id != 0 {
		return id
	}
	name := row["Name_lang"]
	for id, mapName := range maps {
		if mapName == name {
			return id
		}
	}
	for prefix, id := range lfgMapAliases {
		if strings.HasPrefix(name, prefix) {
			return id
		}
	}
	return 0
}

// parseLevels vereint die Level-Bereiche aller LFG-Einträge einer Karte (Flügel, z.B. Dire Maul). Gibt zusätzlich
// die Karten der Dungeons (TypeID 1) zurück und die Namen, die keiner Karte zugeordnet werden konnten.
func parseLevels(rows []map[string]string, maps map[int]string) (levels map[int][2]int, dungeons map[int]bool, missing []string) {
	levels, dungeons = map[int][2]int{}, map[int]bool{}
	for _, row := range rows {
		kind := row["TypeID"]
		if kind != lfgTypeDungeon && kind != lfgTypeRaid {
			continue
		}
		low, high := integer(row["MinLevel"]), integer(row["MaxLevel"])
		id := lfgMapID(row, maps)
		if _, ok := maps[id]; !ok {
			missing = append(missing, row["Name_lang"])
			continue
		}
		if kind == lfgTypeDungeon {
			dungeons[id] = true
		}
		if known, ok := levels[id]; ok {
			low, high = min(low, known[0]), max(high, known[1])
		}
		levels[id] = [2]int{low, high}
	}
	return levels, dungeons, missing
}

// ParseInstances liest die drei Tabellen. flavor "classic_era": Dungeons mit mehr als 5 Spielern in den Daten sind
// 5er-Dungeons (der Client führt dort die 10er-Werte der SoD-Schwierigkeit), ausgenommen die Blackrock Spire.
// Zweiter Rückgabewert: LFG-Namen ohne zugeordnete Karte.
func ParseInstances(build, flavor string, lfg, mapDifficulty, mapTable io.Reader) (*Instances, []string, error) {
	mapRows, err := readCSV(mapTable)
	if err != nil {
		return nil, nil, fmt.Errorf("Map: %w", err)
	}
	difficultyRows, err := readCSV(mapDifficulty)
	if err != nil {
		return nil, nil, fmt.Errorf("MapDifficulty: %w", err)
	}
	lfgRows, err := readCSV(lfg)
	if err != nil {
		return nil, nil, fmt.Errorf("LFGDungeons: %w", err)
	}
	maps := instanceMaps(mapRows)
	instances := &Instances{Build: build, Modes: parseModes(difficultyRows, maps), Levels: map[int][2]int{}}
	var missing []string
	if len(lfgRows) > 0 {
		if _, hasLevels := lfgRows[0]["MinLevel"]; hasLevels {
			var dungeons map[int]bool
			instances.Levels, dungeons, missing = parseLevels(lfgRows, maps)
			if flavor == "classic_era" {
				fixEraDungeonSize(instances.Modes, dungeons)
			}
		}
	}
	for id := range instances.Levels {
		if instances.Modes[id] == nil {
			delete(instances.Levels, id)
		}
	}
	return instances, missing, nil
}

func fixEraDungeonSize(modes map[int]map[int]Mode, dungeons map[int]bool) {
	for id := range dungeons {
		if id == blackrockSpire {
			continue
		}
		for difficulty, mode := range modes[id] {
			if mode.Players > partyDungeonPlayers {
				mode.Players = partyDungeonPlayers
				modes[id][difficulty] = mode
			}
		}
	}
}

func sortedMapIDs[V any](values map[int]V) []int {
	ids := make([]int, 0, len(values))
	for id := range values {
		ids = append(ids, id)
	}
	sort.Ints(ids)
	return ids
}

// WriteInstancesLua schreibt Assist/InstanceData/<flavor>.lua (frühes return in anderen Flavors).
func WriteInstancesLua(w io.Writer, flavor string, instances *Instances, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 Map, MapDifficulty, LFGDungeons von\n")
	fmt.Fprintf(&b, "-- wago.tools, Build %s), Stand %s. Nicht von Hand ändern.\n", instances.Build, date)
	b.WriteString("-- ns.InstanceData = { build, modes = { [Karten-ID] = { [DifficultyID] = { Reset in Tagen (0 = keiner), Spieler } } },\n")
	b.WriteString("-- levels = { [Karten-ID] = { MinLevel, MaxLevel } } } (levels nur in Clients mit Level-Spalten).\n")
	b.WriteString("-- Lesen: Tracking/InstanceInfo.lua.\n")
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	fmt.Fprintf(&b, "ns.InstanceData = {\n  build = %q,\n  modes = {\n", instances.Build)
	for _, id := range sortedMapIDs(instances.Modes) {
		fmt.Fprintf(&b, "    [%d] = {", id)
		for _, difficulty := range sortedMapIDs(instances.Modes[id]) {
			mode := instances.Modes[id][difficulty]
			fmt.Fprintf(&b, " [%d] = { %d, %d },", difficulty, mode.ResetDays, mode.Players)
		}
		b.WriteString(" },\n")
	}
	b.WriteString("  },\n")
	if len(instances.Levels) > 0 {
		b.WriteString("  levels = {\n")
		for _, id := range sortedMapIDs(instances.Levels) {
			fmt.Fprintf(&b, "    [%d] = { %d, %d },\n", id, instances.Levels[id][0], instances.Levels[id][1])
		}
		b.WriteString("  },\n")
	}
	b.WriteString("}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
