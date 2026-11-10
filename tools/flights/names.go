package main

import (
	"fmt"
	"io"
	"sort"
	"strconv"
	"strings"
)

// Flugpunkt-Namen aus den Spieldaten (DB2-Tabelle TaxiNodes, Spalten ID und Name_lang). wago.tools liefert die
// Texte in der Sprache aus dem Parameter "locale" (csv?build=...&locale=deDE). Alte Messungen im Addon stehen unter
// dem Namen in der Sprache des Clients; dieses Verzeichnis ordnet jeden Namen in allen Sprachen der nodeID zu.

// NameLocales sind die Client-Sprachen, deren Namen mitgeliefert werden (Locales/Core.lua: CLIENT_LANGUAGES plus enUS).
var NameLocales = []string{"enUS", "deDE", "frFR", "esES", "esMX"}

// NameFlavors bekommen die Namen-Datei. Retail nicht: ~4700 Namen (ca. 250 KB) für Altdaten, die es dort kaum gibt; dort
// greift weiter die Übernahme per Name auf der offenen Karte (Assist/FlightTimes.lua, Learn).
var NameFlavors = map[string]bool{"classic_era": true, "anniversary": true, "forever": true}

// NodeNames ordnet Flugpunkt-IDs ihren Namen zu: Locale -> nodeID -> Name.
type NodeNames map[string]map[int]string

// ParseNodeNames liest TaxiNodes einer Sprache: nodeID -> Name (leere Namen fehlen).
func ParseNodeNames(r io.Reader) (map[int]string, error) {
	rows, err := readCSV(r)
	if err != nil {
		return nil, fmt.Errorf("TaxiNodes: %w", err)
	}
	names := map[int]string{}
	for _, row := range rows {
		id, name := integer(row["ID"]), row["Name_lang"]
		if id > 0 && name != "" {
			names[id] = name
		}
	}
	return names, nil
}

// NameIndex ist Name -> nodeID über alle Sprachen. Ein Name, der in einer Sprache zu mehreren Flugpunkten gehört
// (oder in einer Sprache zu einem anderen als in einer zweiten), steht in Ambiguous und nicht in IDs: so wird nie
// eine falsche Strecke zugeordnet; die alte Messung bleibt dann unter ihrem Namen liegen.
type NameIndex struct {
	IDs       map[string]int
	Ambiguous []string
}

// BuildNameIndex bildet den Index. only (falls nicht leer) beschränkt auf diese nodeIDs.
func BuildNameIndex(names NodeNames, only map[int]bool) *NameIndex {
	found := map[string]map[int]bool{}
	for _, byID := range names {
		for id, name := range byID {
			if len(only) > 0 && !only[id] {
				continue
			}
			if found[name] == nil {
				found[name] = map[int]bool{}
			}
			found[name][id] = true
		}
	}
	index := &NameIndex{IDs: map[string]int{}}
	for name, ids := range found {
		if len(ids) > 1 {
			index.Ambiguous = append(index.Ambiguous, name)
			continue
		}
		for id := range ids {
			index.IDs[name] = id
		}
	}
	sort.Strings(index.Ambiguous)
	return index
}

// Resolve übersetzt "Start > Ziel" in die beiden nodeIDs (ok = false, sobald ein Name fehlt oder mehrdeutig ist).
func (n *NameIndex) Resolve(legacyKey string) (from, to int, ok bool) {
	fromName, toName, found := strings.Cut(legacyKey, " > ")
	if !found {
		return 0, 0, false
	}
	from, fromOK := n.IDs[fromName]
	to, toOK := n.IDs[toName]
	return from, to, fromOK && toOK
}

// WriteNamesLua schreibt Assist/FlightNamesData/<flavor>.lua (frühes return in anderen Flavors).
func WriteNamesLua(w io.Writer, flavor, build string, index *NameIndex, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 TaxiNodes von wago.tools,\n")
	fmt.Fprintf(&b, "-- Build %s, Sprachen %s), Stand %s. Nicht von Hand ändern.\n", build, strings.Join(NameLocales, " "), date)
	b.WriteString("-- ns.FlightNamesData = { [\"Name des Flugpunkts\"] = nodeID }   alle Sprachen in einer Tabelle; mehrdeutige\n")
	b.WriteString("-- Namen fehlen. Zweck: alte Messungen unter Namen auf nodeIDs umschreiben (Assist/FlightTimes.lua).\n")
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	b.WriteString("ns.FlightNamesData = {\n")
	for _, name := range sortedKeys(index.IDs) {
		fmt.Fprintf(&b, "  [%s] = %s,\n", strconv.Quote(name), strconv.Itoa(index.IDs[name]))
	}
	b.WriteString("}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
