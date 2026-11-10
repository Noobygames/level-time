package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"math"
	"sort"
	"strconv"
	"strings"
)

// Flugstrecken aus den Spieldaten (DB2-Tabellen TaxiPath und TaxiPathNode, CSV von wago.tools):
//   TaxiPath      ID, FromTaxiNode, ToTaxiNode       eine direkte Strecke zwischen zwei Flugpunkten (nodeID)
//   TaxiPathNode  Loc_0..2, PathID, NodeIndex, ContinentID, Flags, Delay   Wegpunkte der Strecke in Yards
// Länge = Summe der Abstände aufeinanderfolgender Wegpunkte (ohne Sprung über einen Teleport oder Kontinentwechsel),
// Halt = Summe der Delays an Haltepunkten. Dauer im Addon = Halt + Länge / Fluggeschwindigkeit; die Geschwindigkeit
// kommt aus den Messungen (in WoW Forever konstant ~29,9 Yards je Sekunde, ohne Zeit für Start und Landung).

const (
	flagTeleport = 1 // TaxiPathNode.Flags: nach diesem Punkt springt der Flug (keine Strecke bis zum nächsten)
	flagStop     = 2 // TaxiPathNode.Flags: Halt mit Delay Sekunden
)

// Leg ist eine direkte Strecke: Länge in Yards, Halte in Sekunden.
type Leg struct {
	Length float64
	Stops  float64
}

// Paths sind die direkten Strecken eines Builds, Schlüssel "vonID>nachID" wie Assist/FlightMap.lua.
type Paths struct {
	Build string
	Legs  map[string]Leg
}

type pathPoint struct {
	index     int
	x, y, z   float64
	continent string
	flags     int
	delay     float64
}

// readCSV liefert die Zeilen als Maps Spaltenname -> Wert.
func readCSV(r io.Reader) ([]map[string]string, error) {
	reader := csv.NewReader(r)
	header, err := reader.Read()
	if err != nil {
		return nil, err
	}
	var rows []map[string]string
	for {
		record, err := reader.Read()
		if err == io.EOF {
			return rows, nil
		}
		if err != nil {
			return nil, err
		}
		row := make(map[string]string, len(header))
		for i, name := range header {
			if i < len(record) {
				row[name] = record[i]
			}
		}
		rows = append(rows, row)
	}
}

func number(text string) float64 {
	value, _ := strconv.ParseFloat(text, 64)
	return value
}

// ParsePaths rechnet aus TaxiPath und TaxiPathNode die Länge jeder direkten Strecke. Gibt es mehrere Strecken
// zwischen denselben Punkten, gilt die mit der kleinsten ID.
func ParsePaths(build string, taxiPath, taxiPathNode io.Reader) (*Paths, error) {
	pathRows, err := readCSV(taxiPath)
	if err != nil {
		return nil, fmt.Errorf("TaxiPath: %w", err)
	}
	nodeRows, err := readCSV(taxiPathNode)
	if err != nil {
		return nil, fmt.Errorf("TaxiPathNode: %w", err)
	}
	points := map[string][]pathPoint{}
	for _, row := range nodeRows {
		flags, _ := strconv.Atoi(row["Flags"])
		index, _ := strconv.Atoi(row["NodeIndex"])
		points[row["PathID"]] = append(points[row["PathID"]], pathPoint{index: index, x: number(row["Loc_0"]),
			y: number(row["Loc_1"]), z: number(row["Loc_2"]), continent: row["ContinentID"], flags: flags,
			delay: number(row["Delay"])})
	}
	sort.Slice(pathRows, func(i, j int) bool { return number(pathRows[i]["ID"]) < number(pathRows[j]["ID"]) })
	paths := &Paths{Build: build, Legs: map[string]Leg{}}
	for _, row := range pathRows {
		key := row["FromTaxiNode"] + ">" + row["ToTaxiNode"]
		if _, seen := paths.Legs[key]; seen {
			continue
		}
		if leg, ok := legOf(points[row["ID"]]); ok {
			paths.Legs[key] = leg
		}
	}
	return paths, nil
}

func legOf(points []pathPoint) (Leg, bool) {
	if len(points) < 2 {
		return Leg{}, false
	}
	sort.Slice(points, func(i, j int) bool { return points[i].index < points[j].index })
	var leg Leg
	for i, point := range points {
		if point.flags&flagStop != 0 {
			leg.Stops += point.delay
		}
		if i == 0 {
			continue
		}
		previous := points[i-1]
		if previous.flags&flagTeleport != 0 || previous.continent != point.continent {
			continue
		}
		dx, dy, dz := point.x-previous.x, point.y-previous.y, point.z-previous.z
		leg.Length += math.Sqrt(dx*dx + dy*dy + dz*dz)
	}
	return leg, leg.Length > 0
}

// Speed ist die Fluggeschwindigkeit eines Flavors in Yards je Sekunde.
type Speed struct {
	YardsPerSecond float64
	Samples        int
	BorrowedFrom   string // Flavor, dessen Messungen gelten, solange der eigene keine hat
}

// MeasuredSpeed rechnet wie FlightTimes.OwnSpeed im Addon: Median aus Länge / (Sekunden - Halte) je gemessener
// Strecke. Länge aus der beim Flug gemerkten pathLength, sonst aus der direkten Strecke (nur ohne Zwischenhalt).
func MeasuredSpeed(routes map[string]map[string]*Route, paths *Paths) *Speed {
	var ratios []float64
	for _, mapRoutes := range routes {
		for routeKey, route := range mapRoutes {
			length, stops, ok := route.pathLength()
			if !ok {
				leg, direct := paths.Legs[routeKey]
				if !direct || route.multiHop() {
					continue
				}
				length, stops = leg.Length, leg.Stops
			}
			if moving := Median(route.Samples) - stops; moving > 0 && length > 0 {
				ratios = append(ratios, length/moving)
			}
		}
	}
	if len(ratios) == 0 {
		return nil
	}
	return &Speed{YardsPerSecond: Median(ratios), Samples: len(ratios)}
}

// WritePathsLua schreibt Assist/FlightPathsData/<flavor>.lua. Die Datei endet sofort in einem anderen Flavor; ihre
// Tabelle entsteht dann nie und kostet keinen Speicher.
func WritePathsLua(w io.Writer, flavor string, paths *Paths, speed *Speed, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 TaxiPath und TaxiPathNode von\n")
	fmt.Fprintf(&b, "-- wago.tools, Build %s), Stand %s. Nicht von Hand ändern.\n", paths.Build, date)
	b.WriteString("-- ns.FlightPathsData = { build, speed = { yardsPerSecond, samples, borrowedFrom },\n")
	b.WriteString("--   legs = { [\"vonID>nachID\"] = Yards }, stops = { [\"vonID>nachID\"] = Sekunden } }\n")
	b.WriteString("-- Direkte Strecken; Schlüssel = nodeID wie Assist/FlightMap.lua. Rechnung in Assist/FlightPaths.lua.\n")
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	b.WriteString("ns.FlightPathsData = {\n")
	fmt.Fprintf(&b, "  build = %q,\n", paths.Build)
	if speed != nil {
		fmt.Fprintf(&b, "  speed = { yardsPerSecond = %s, samples = %d", luaNumber(speed.YardsPerSecond), speed.Samples)
		if speed.BorrowedFrom != "" {
			fmt.Fprintf(&b, ", borrowedFrom = %q", speed.BorrowedFrom)
		}
		b.WriteString(" },\n")
	}
	b.WriteString("  legs = {\n")
	for _, key := range sortedLegKeys(paths.Legs) {
		fmt.Fprintf(&b, "    [%q] = %d,\n", key, int(math.Round(paths.Legs[key].Length)))
	}
	b.WriteString("  },\n  stops = {\n")
	for _, key := range sortedLegKeys(paths.Legs) {
		if stops := paths.Legs[key].Stops; stops > 0 {
			fmt.Fprintf(&b, "    [%q] = %s,\n", key, luaNumber(stops))
		}
	}
	b.WriteString("  },\n}\n")
	_, err := io.WriteString(w, b.String())
	return err
}

// Schlüssel numerisch sortiert ("2>4" vor "10>3"), damit der Diff nur echte Änderungen zeigt
func sortedLegKeys(legs map[string]Leg) []string {
	keys := sortedKeys(legs)
	parts := func(key string) (float64, float64) {
		from, to, _ := strings.Cut(key, ">")
		return number(from), number(to)
	}
	sort.SliceStable(keys, func(i, j int) bool {
		fromI, toI := parts(keys[i])
		fromJ, toJ := parts(keys[j])
		if fromI != fromJ {
			return fromI < fromJ
		}
		return toI < toJ
	})
	return keys
}
