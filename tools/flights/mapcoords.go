package main

import (
	"fmt"
	"io"
	"math"
	"sort"
	"strings"
)

// Karten-Koordinaten aus den Spieldaten (DB2-Tabellen von wago.tools):
//   UiMap            ID, Type     2 = Kontinent, 3 = Zone (nur diese Karten kommen in die Datei)
//   UiMapAssignment  UiMapID, MapID, OrderIndex, UiMin_0/1, UiMax_0/1, Region_0..5
// Region_0..2 ist die kleinste, Region_3..5 die größte Weltposition (Yards) der Karte; Region_0 / Region_3 ist die
// Nord-Achse (das x von C_Map.GetWorldPosFromMapPos), Region_1 / Region_4 die West-Achse (y). Karte (0,0) liegt oben
// links, also bei Nord-Maximum und West-Maximum (geprüft am Wald von Elwynn: Karte (0,0) = Region_3, Region_4).
// Je Karte kommt die Zuordnung mit dem kleinsten OrderIndex, die die ganze Karte (UiMin 0,0 bis UiMax 1,1) abdeckt.

const (
	uiMapTypeContinent = 2
	uiMapTypeZone      = 3
	coordDecimals      = 100 // Weltposition auf 0,01 Yards genau
)

// MapArea ist der Weltbereich einer Karte: Instanz-/Kontinent-ID und die Grenzen in Yards.
type MapArea struct {
	InstanceID int
	MinNorth   float64
	MinWest    float64
	MaxNorth   float64
	MaxWest    float64
	order      int
}

// MapCoords sind die Bereiche aller Kontinent- und Zonenkarten eines Builds.
type MapCoords struct {
	Build string
	Areas map[int]MapArea
}

func isFullMap(row map[string]string) bool {
	return number(row["UiMin_0"]) == 0 && number(row["UiMin_1"]) == 0 &&
		number(row["UiMax_0"]) == 1 && number(row["UiMax_1"]) == 1
}

// ParseMapCoords liest UiMap und UiMapAssignment. Karten ohne ganze Karten-Zuordnung oder mit leerem Bereich fehlen.
func ParseMapCoords(build string, uiMap, assignment io.Reader) (*MapCoords, error) {
	mapRows, err := readCSV(uiMap)
	if err != nil {
		return nil, fmt.Errorf("UiMap: %w", err)
	}
	rows, err := readCSV(assignment)
	if err != nil {
		return nil, fmt.Errorf("UiMapAssignment: %w", err)
	}
	wanted := map[int]bool{}
	for _, row := range mapRows {
		if kind := integer(row["Type"]); kind == uiMapTypeContinent || kind == uiMapTypeZone {
			wanted[integer(row["ID"])] = true
		}
	}
	coords := &MapCoords{Build: build, Areas: map[int]MapArea{}}
	for _, row := range rows {
		id := integer(row["UiMapID"])
		area := MapArea{InstanceID: integer(row["MapID"]), order: integer(row["OrderIndex"]),
			MinNorth: number(row["Region_0"]), MinWest: number(row["Region_1"]),
			MaxNorth: number(row["Region_3"]), MaxWest: number(row["Region_4"])}
		if !wanted[id] || !isFullMap(row) || area.MaxNorth <= area.MinNorth || area.MaxWest <= area.MinWest {
			continue
		}
		if known, ok := coords.Areas[id]; ok && known.order <= area.order {
			continue
		}
		coords.Areas[id] = area
	}
	return coords, nil
}

func roundYards(value float64) float64 {
	return math.Round(value*coordDecimals) / coordDecimals
}

// WriteMapCoordsLua schreibt Assist/MapCoordsData/<flavor>.lua (frühes return in anderen Flavors).
func WriteMapCoordsLua(w io.Writer, flavor string, coords *MapCoords, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 UiMap, UiMapAssignment von wago.tools,\n")
	fmt.Fprintf(&b, "-- Build %s), Stand %s. Nicht von Hand ändern.\n", coords.Build, date)
	b.WriteString("-- ns.MapCoordsData = { build, areas = { [UiMapID] = { Instanz-ID, Nord min, West min, Nord max, West max } } }\n")
	b.WriteString("-- (Yards; Nord = x von C_Map.GetWorldPosFromMapPos, West = y). Lesen: Lib/MapCoords.lua.\n")
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	fmt.Fprintf(&b, "ns.MapCoordsData = {\n  build = %q,\n  areas = {\n", coords.Build)
	ids := make([]int, 0, len(coords.Areas))
	for id := range coords.Areas {
		ids = append(ids, id)
	}
	sort.Ints(ids)
	for _, id := range ids {
		a := coords.Areas[id]
		fmt.Fprintf(&b, "    [%d] = { %d, %g, %g, %g, %g },\n", id, a.InstanceID, roundYards(a.MinNorth),
			roundYards(a.MinWest), roundYards(a.MaxNorth), roundYards(a.MaxWest))
	}
	b.WriteString("  },\n}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
