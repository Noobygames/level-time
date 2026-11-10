package main

import (
	"fmt"
	"io"
	"math"
	"sort"
	"strconv"
	"strings"
)

// Schiffe und Zeppeline fahren in den Classic-Clients auf Taxi-Pfaden (TaxiPath/TaxiPathNode), die als Rundkurs
// angelegt sind: Haltepunkte (Flag 2) mit Delay Sekunden Liegezeit, dazwischen die Fahrt. Ein Pfad mit mindestens
// zwei Halten ist ein Transport (Flugrouten halten nicht, Naxxramas-Pfad hat nur einen Halt). Positionen sind
// Weltkoordinaten (Yards je Kontinent), damit ordnet das Addon die gelernten Anleger zu (Assist/TransportPaths.lua).

const minTransportStops = 2

// TransportStop ist ein Halt: Kontinent, Weltposition, Liegezeit und Yards bis zum nächsten Halt des Rundkurses.
type TransportStop struct {
	Continent string
	X, Y      float64
	Wait      float64
	Next      float64
}

// TransportPaths sind die Transport-Rundkurse eines Builds je TaxiPath-ID.
type TransportPaths struct {
	Build string
	ByID  map[string][]TransportStop
}

// ParseTransports sucht die Pfade mit mindestens zwei Halten und rechnet die Abstände zwischen den Halten.
func ParseTransports(build string, taxiPathNode io.Reader) (*TransportPaths, error) {
	rows, err := readCSV(taxiPathNode)
	if err != nil {
		return nil, fmt.Errorf("TaxiPathNode: %w", err)
	}
	points := map[string][]pathPoint{}
	for _, row := range rows {
		flags, _ := strconv.Atoi(row["Flags"])
		index, _ := strconv.Atoi(row["NodeIndex"])
		points[row["PathID"]] = append(points[row["PathID"]], pathPoint{index: index, x: number(row["Loc_0"]),
			y: number(row["Loc_1"]), z: number(row["Loc_2"]), continent: row["ContinentID"], flags: flags,
			delay: number(row["Delay"])})
	}
	transports := &TransportPaths{Build: build, ByID: map[string][]TransportStop{}}
	for id, list := range points {
		if stops := transportStops(list); len(stops) >= minTransportStops {
			transports.ByID[id] = stops
		}
	}
	return transports, nil
}

// Strecke von a nach b: 0 über einen Teleport (Flag 1) oder Kontinentwechsel
func segment(a, b pathPoint) float64 {
	if a.flags&flagTeleport != 0 || a.continent != b.continent {
		return 0
	}
	dx, dy, dz := b.x-a.x, b.y-a.y, b.z-a.z
	return math.Sqrt(dx*dx + dy*dy + dz*dz)
}

// transportStops liefert die Halte in Reihenfolge; Next läuft im Kreis (letzter Halt zurück zum ersten über das
// Pfadende, den Schluss zum ersten Punkt und den Pfadanfang).
func transportStops(points []pathPoint) []TransportStop {
	sort.Slice(points, func(i, j int) bool { return points[i].index < points[j].index })
	var stops []TransportStop
	var sinceStop, beforeFirst float64
	for i, point := range points {
		if i > 0 {
			sinceStop += segment(points[i-1], point)
		}
		if point.flags&flagStop == 0 || point.delay <= 0 {
			continue
		}
		if len(stops) == 0 {
			beforeFirst = sinceStop
		} else {
			stops[len(stops)-1].Next = sinceStop
		}
		stops = append(stops, TransportStop{Continent: point.continent, X: point.x, Y: point.y, Wait: point.delay})
		sinceStop = 0
	}
	if len(stops) > 0 {
		closing := segment(points[len(points)-1], points[0])
		stops[len(stops)-1].Next = sinceStop + closing + beforeFirst
	}
	return stops
}

// WriteTransportsLua schreibt Assist/TransportData/<flavor>.lua (frühes return in anderen Flavors).
func WriteTransportsLua(w io.Writer, flavor string, transports *TransportPaths, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 TaxiPathNode von wago.tools, Build\n")
	fmt.Fprintf(&b, "-- %s), Stand %s. Nicht von Hand ändern.\n", transports.Build, date)
	b.WriteString("-- ns.TransportData = { build, paths = { [TaxiPath-ID] = { { continent, x, y, wait, next }, ... } } }:\n")
	b.WriteString("-- Halte eines Schiffs- oder Zeppelin-Rundkurses mit Weltposition (Yards), Liegezeit (Sekunden) und Yards bis zum\n")
	b.WriteString("-- nächsten Halt. Rechnung in Assist/TransportPaths.lua.\n")
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	fmt.Fprintf(&b, "ns.TransportData = {\n  build = %q,\n  paths = {\n", transports.Build)
	ids := sortedKeys(transports.ByID)
	sort.SliceStable(ids, func(i, j int) bool { return number(ids[i]) < number(ids[j]) })
	for _, id := range ids {
		fmt.Fprintf(&b, "    [%s] = {\n", id)
		for _, stop := range transports.ByID[id] {
			fmt.Fprintf(&b, "      { continent = %s, x = %s, y = %s, wait = %s, next = %d },\n", stop.Continent,
				luaNumber(math.Round(stop.X)), luaNumber(math.Round(stop.Y)), luaNumber(stop.Wait),
				int(math.Round(stop.Next)))
		}
		b.WriteString("    },\n")
	}
	b.WriteString("  },\n}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
