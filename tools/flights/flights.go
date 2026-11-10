package main

import (
	"fmt"
	"io"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// Flugzeiten aus den SavedVariables (LevelTimerStatsDB) der Entwickler sammeln und als Assist/FlightTimesData.lua
// mitliefern. Gleiches Speicherformat und gleiche Schätzung wie Assist/FlightTimes.lua im Addon:
//   LevelTimerStatsDB.flights[flavor][map].routes["vonKey>nachKey"] = { seconds, samples = { ... }, distance, ... }
//   LevelTimerStatsDB.flightTimes["Start > Ziel"] = Sekunden (alte Messungen nach Namen, Flavor = Ordner)

const (
	statsVariable = "LevelTimerStatsDB"
	savedVarsFile = "LevelTimer.lua"

	// wie in Assist/FlightTimes.lua
	minFitSamples = 3
	defaultOffset = 10.0
	maxOffset     = 60.0
	minDistance   = 0.001
)

// Route sammelt alle Messungen einer Richtung auf einer Karte; PathLengths/PathStops sind Länge (Yards) und Halte
// der Flugroute aus Assist/FlightPaths.lua, soweit das Addon sie beim Flug kannte.
type Route struct {
	Samples     []float64
	Distances   []float64
	Hops        []float64
	PathLengths []float64
	PathStops   []float64
}

// pathLength liefert die gemerkte Länge und Halte der Flugroute (Median), ok = false ohne Angabe.
func (r *Route) pathLength() (length, stops float64, ok bool) {
	if len(r.PathLengths) == 0 {
		return 0, 0, false
	}
	if len(r.PathStops) > 0 {
		stops = Median(r.PathStops)
	}
	return Median(r.PathLengths), stops, true
}

// multiHop: mindestens eine Messung lief über einen Zwischenhalt (dann passt die direkte Strecke nicht)
func (r *Route) multiHop() bool {
	for _, hops := range r.Hops {
		if hops > 1 {
			return true
		}
	}
	return false
}

// Factor ist die gelernte Gerade: Sekunden = Offset + PerUnit × Strecke.
type Factor struct {
	Offset  float64
	PerUnit float64
	Samples int
}

// Snapshot ist alles, was mitgeliefert wird: flavor -> map -> route, dazu Namen-Messungen je flavor.
type Snapshot struct {
	Maps     map[string]map[string]map[string]*Route // flavor, map, routeKey
	Names    map[string]map[string][]float64         // flavor, "Start > Ziel" (noch nicht auf nodeIDs umgeschrieben)
	NodeMaps map[string]map[string]string            // flavor, nodeID -> Flugkarte, in der der Knoten gesehen wurde
}

func NewSnapshot() *Snapshot {
	return &Snapshot{Maps: map[string]map[string]map[string]*Route{}, Names: map[string]map[string][]float64{},
		NodeMaps: map[string]map[string]string{}}
}

func asTable(value any) map[string]any {
	table, _ := value.(map[string]any)
	return table
}

func asNumber(value any) (float64, bool) {
	number, ok := value.(float64)
	return number, ok && !math.IsNaN(number) && !math.IsInf(number, 0)
}

func appendNumber(list *[]float64, raw any) {
	if number, ok := asNumber(raw); ok {
		*list = append(*list, number)
	}
}

// numbers liest eine Lua-Liste { 1, 2, ... } in Reihenfolge
func numbers(value any) []float64 {
	table := asTable(value)
	var list []float64
	for i := 1; ; i++ {
		raw, ok := table[strconv.Itoa(i)]
		if !ok {
			return list
		}
		if number, ok := asNumber(raw); ok {
			list = append(list, number)
		}
	}
}

// Add nimmt den Inhalt von LevelTimerStatsDB einer Installation auf; dirFlavor gilt für die alten Namen-Messungen.
func (s *Snapshot) Add(stats map[string]any, dirFlavor string) {
	for flavor, maps := range asTable(stats["flights"]) {
		for mapKey, store := range asTable(maps) {
			s.rememberNodes(flavor, mapKey, asTable(asTable(store)["nodes"]))
			for routeKey, raw := range asTable(asTable(store)["routes"]) {
				s.rememberRouteNodes(flavor, mapKey, routeKey)
				route := asTable(raw)
				samples := numbers(route["samples"])
				if len(samples) == 0 {
					if seconds, ok := asNumber(route["seconds"]); ok {
						samples = []float64{seconds}
					}
				}
				if len(samples) == 0 {
					continue
				}
				target := s.route(flavor, mapKey, routeKey)
				target.Samples = append(target.Samples, samples...)
				appendNumber(&target.Distances, route["distance"])
				appendNumber(&target.Hops, route["hops"])
				appendNumber(&target.PathLengths, route["pathLength"])
				appendNumber(&target.PathStops, route["pathStops"])
			}
		}
	}
	for name, raw := range asTable(stats["flightTimes"]) {
		if seconds, ok := asNumber(raw); ok {
			if s.Names[dirFlavor] == nil {
				s.Names[dirFlavor] = map[string][]float64{}
			}
			s.Names[dirFlavor][name] = append(s.Names[dirFlavor][name], seconds)
		}
	}
}

func (s *Snapshot) route(flavor, mapKey, routeKey string) *Route {
	if s.Maps[flavor] == nil {
		s.Maps[flavor] = map[string]map[string]*Route{}
	}
	if s.Maps[flavor][mapKey] == nil {
		s.Maps[flavor][mapKey] = map[string]*Route{}
	}
	route := s.Maps[flavor][mapKey][routeKey]
	if route == nil {
		route = &Route{}
		s.Maps[flavor][mapKey][routeKey] = route
	}
	return route
}

func Median(values []float64) float64 {
	sorted := append([]float64(nil), values...)
	sort.Float64s(sorted)
	middle := len(sorted) / 2
	if len(sorted)%2 == 1 {
		return sorted[middle]
	}
	return (sorted[middle-1] + sorted[middle]) / 2
}

// Point ist eine Strecke für die Gerade.
type Point struct{ Distance, Seconds float64 }

// Fit rechnet wie FlightTimes.Fit im Addon (nil = kein Faktor).
func Fit(points []Point) *Factor {
	var usable []Point
	for _, p := range points {
		if p.Distance >= minDistance {
			usable = append(usable, p)
		}
	}
	if len(usable) == 0 {
		return nil
	}
	n := float64(len(usable))
	if len(usable) >= minFitSamples {
		var meanX, meanY float64
		for _, p := range usable {
			meanX += p.Distance
			meanY += p.Seconds
		}
		meanX, meanY = meanX/n, meanY/n
		var sxx, sxy float64
		for _, p := range usable {
			dx := p.Distance - meanX
			sxx += dx * dx
			sxy += dx * (p.Seconds - meanY)
		}
		if sxx > 0 {
			perUnit := sxy / sxx
			offset := meanY - perUnit*meanX
			if perUnit > 0 && offset >= 0 && offset <= maxOffset {
				return &Factor{Offset: offset, PerUnit: perUnit, Samples: len(usable)}
			}
		}
	}
	var ratios []float64
	for _, p := range usable {
		if p.Seconds > defaultOffset {
			ratios = append(ratios, (p.Seconds-defaultOffset)/p.Distance)
		}
	}
	if len(ratios) == 0 {
		return nil
	}
	return &Factor{Offset: defaultOffset, PerUnit: Median(ratios), Samples: len(usable)}
}

// MapFactor lernt den Faktor einer Karte aus dem Median je Strecke.
func MapFactor(routes map[string]*Route) *Factor {
	var points []Point
	for _, route := range routes {
		if len(route.Distances) > 0 {
			points = append(points, Point{Distance: Median(route.Distances), Seconds: Median(route.Samples)})
		}
	}
	return Fit(points)
}

func sortedKeys[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func luaNumber(value float64) string {
	return strconv.FormatFloat(math.Round(value*1000)/1000, 'f', -1, 64)
}

// WriteLua schreibt Assist/FlightTimesData.lua (sortiert, damit der Diff nur echte Änderungen zeigt).
func (s *Snapshot) WriteLua(w io.Writer, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus Flugzeiten, die die Entwickler selbst gemessen haben\n")
	b.WriteString("-- (SavedVariables LevelTimerStatsDB), Stand " + date + ". Nicht von Hand ändern.\n")
	b.WriteString("-- ns.FlightTimesData[flavor][map] = { routes = { [\"vonKey>nachKey\"] = Sekunden (Median) },\n")
	b.WriteString("--   factor = { offset, perUnit, samples } }   (Schlüssel wie Assist/FlightMap.lua: nodeID oder \"x,y\")\n")
	b.WriteString("local _, ns = ...\n\nns.FlightTimesData = {\n")
	flavors := map[string]bool{}
	for flavor := range s.Maps {
		flavors[flavor] = true
	}
	for _, flavor := range sortedKeys(flavors) {
		fmt.Fprintf(&b, "  [%q] = {\n", flavor)
		maps := s.Maps[flavor]
		for _, mapKey := range sortedKeys(maps) {
			routes := maps[mapKey]
			fmt.Fprintf(&b, "    [%q] = {\n      routes = {\n", mapKey)
			for _, routeKey := range sortedKeys(routes) {
				fmt.Fprintf(&b, "        [%q] = %s,\n", routeKey, luaNumber(Median(routes[routeKey].Samples)))
			}
			b.WriteString("      },\n")
			if factor := MapFactor(routes); factor != nil {
				fmt.Fprintf(&b, "      factor = { offset = %s, perUnit = %s, samples = %d },\n",
					luaNumber(factor.Offset), luaNumber(factor.PerUnit), factor.Samples)
			}
			b.WriteString("    },\n")
		}
		b.WriteString("  },\n")
	}
	b.WriteString("}\n")
	_, err := io.WriteString(w, b.String())
	return err
}

// Collect liest LevelTimerStatsDB aus allen Flavors und Konten der Installation (nur lesen).
func Collect(root string, info io.Writer) (*Snapshot, error) {
	snapshot := NewSnapshot()
	paths, err := filepath.Glob(filepath.Join(root, "_*_", "WTF", "Account", "*", "SavedVariables", savedVarsFile))
	if err != nil {
		return nil, err
	}
	for _, path := range paths {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		value, err := ParseVariable(string(content), statsVariable)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}
		stats := asTable(value)
		if stats == nil {
			continue
		}
		dirFlavor := flavorOfPath(root, path)
		snapshot.Add(stats, dirFlavor)
		fmt.Fprintf(info, "%s: %s\n", dirFlavor, path)
	}
	return snapshot, nil
}

// "<root>/_forever_/WTF/..." -> "forever" (wie Client.Flavor im Addon)
func flavorOfPath(root, path string) string {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return ""
	}
	first := strings.Split(filepath.ToSlash(rel), "/")[0]
	return strings.Trim(first, "_")
}

// rememberNodes merkt, auf welcher Flugkarte ein Knoten (nodeID) zu sehen war; nur echte nodeIDs, keine Positionen.
func (s *Snapshot) rememberNodes(flavor, mapKey string, nodes map[string]any) {
	for id := range nodes {
		s.rememberNode(flavor, mapKey, id)
	}
}

func (s *Snapshot) rememberRouteNodes(flavor, mapKey, routeKey string) {
	from, to, _ := strings.Cut(routeKey, ">")
	s.rememberNode(flavor, mapKey, from)
	s.rememberNode(flavor, mapKey, to)
}

func (s *Snapshot) rememberNode(flavor, mapKey, id string) {
	if _, err := strconv.Atoi(id); err != nil {
		return
	}
	if s.NodeMaps[flavor] == nil {
		s.NodeMaps[flavor] = map[string]string{}
	}
	if _, known := s.NodeMaps[flavor][id]; !known {
		s.NodeMaps[flavor][id] = mapKey
	}
}

// ResolveNames schreibt die alten Messungen unter Namen auf nodeIDs um und legt sie als Strecken der Flugkarte ab
// (die Karte kennt man von den Knoten aus den eigenen Messungen). Eine vorhandene Strecke bleibt unberührt.
// Zurück: die Schlüssel, die sich nicht zuordnen ließen (Name unbekannt oder mehrdeutig, Karte unbekannt); sie
// kommen nicht in die Datei (die Messung im Addon bleibt unter dem Namen lesbar).
func (s *Snapshot) ResolveNames(flavor string, index *NameIndex) (resolved int, unresolved []string) {
	for _, legacyKey := range sortedKeys(s.Names[flavor]) {
		from, to, ok := index.Resolve(legacyKey)
		mapKey := ""
		if ok {
			mapKey = s.nodeMap(flavor, from, to)
		}
		if mapKey == "" {
			unresolved = append(unresolved, legacyKey)
			continue
		}
		routeKey := fmt.Sprintf("%d>%d", from, to)
		if existing := s.Maps[flavor][mapKey][routeKey]; existing == nil {
			s.route(flavor, mapKey, routeKey).Samples = []float64{Median(s.Names[flavor][legacyKey])}
		}
		resolved++
	}
	delete(s.Names, flavor)
	return resolved, unresolved
}

// nodeMap: Flugkarte der beiden Knoten (die eine bekannte, wenn nur ein Knoten bekannt ist; "" bei Widerspruch).
func (s *Snapshot) nodeMap(flavor string, from, to int) string {
	fromMap, toMap := s.NodeMaps[flavor][strconv.Itoa(from)], s.NodeMaps[flavor][strconv.Itoa(to)]
	if fromMap != "" && toMap != "" && fromMap != toMap {
		return ""
	}
	if fromMap != "" {
		return fromMap
	}
	return toMap
}
