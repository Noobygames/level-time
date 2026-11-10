package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

const taxiNodesDE = `Name_lang,Pos_0,ID,ContinentID
"Orgrimmar, Durotar",1,23,1
"Gadgetzan, Tanaris",2,39,1
"Gadgetzan, Tanaris",3,40,1
"Crossroads, Brachland",4,25,1
Leer,5,26,1
`

const taxiNodesEN = `Name_lang,Pos_0,ID,ContinentID
"Orgrimmar, Durotar",1,23,1
"Gadgetzan, Tanaris",2,39,1
"Gadgetzan, Tanaris",3,40,1
"Crossroads, The Barrens",4,25,1
`

func parseNames(t *testing.T, csv string) map[int]string {
	t.Helper()
	names, err := ParseNodeNames(strings.NewReader(csv))
	if err != nil {
		t.Fatal(err)
	}
	return names
}

func TestNameIndexAcrossLocales(t *testing.T) {
	index := BuildNameIndex(NodeNames{"deDE": parseNames(t, taxiNodesDE), "enUS": parseNames(t, taxiNodesEN)}, nil)
	if index.IDs["Crossroads, Brachland"] != 25 || index.IDs["Crossroads, The Barrens"] != 25 {
		t.Errorf("beide Sprachen müssen auf 25 zeigen: %v", index.IDs)
	}
	if _, ok := index.IDs["Gadgetzan, Tanaris"]; ok || len(index.Ambiguous) != 1 {
		t.Errorf("Gadgetzan (39 und 40) muss mehrdeutig sein: ids %v, mehrdeutig %v", index.IDs, index.Ambiguous)
	}
	from, to, ok := index.Resolve("Orgrimmar, Durotar > Crossroads, The Barrens")
	if !ok || from != 23 || to != 25 {
		t.Errorf("Resolve = %d %d %v", from, to, ok)
	}
	if _, _, ok := index.Resolve("Orgrimmar, Durotar > Gadgetzan, Tanaris"); ok {
		t.Error("mehrdeutiger Name darf nicht zugeordnet werden")
	}
	if _, _, ok := index.Resolve("ohne Trenner"); ok {
		t.Error("Schlüssel ohne Trenner")
	}
}

func TestNameCollisionBetweenLocales(t *testing.T) {
	// Derselbe Text bedeutet in zwei Sprachen verschiedene Knoten: mehrdeutig
	index := BuildNameIndex(NodeNames{"deDE": {1: "Lager"}, "enUS": {2: "Lager"}}, nil)
	if len(index.IDs) != 0 || len(index.Ambiguous) != 1 {
		t.Errorf("Sprachen-Kollision: %v %v", index.IDs, index.Ambiguous)
	}
	only := BuildNameIndex(NodeNames{"deDE": {1: "Lager"}, "enUS": {2: "Lager"}}, map[int]bool{1: true})
	if only.IDs["Lager"] != 1 {
		t.Errorf("Einschränkung auf IDs: %v", only.IDs)
	}
}

func TestResolveNamesRewritesToRoutes(t *testing.T) {
	snapshot := NewSnapshot()
	snapshot.Add(map[string]any{
		"flights": map[string]any{"forever": map[string]any{"1411": map[string]any{
			"nodes":  map[string]any{"23": map[string]any{}},
			"routes": map[string]any{"25>23": map[string]any{"seconds": 50.0, "samples": map[string]any{"1": 50.0}}},
		}}},
		"flightTimes": map[string]any{
			"Orgrimmar, Durotar > Crossroads, Brachland": 111.0,
			"Crossroads, Brachland > Orgrimmar, Durotar": 99.0, // Strecke gibt es schon (eigene gewinnt nicht: 25>23)
			"Orgrimmar, Durotar > Gadgetzan, Tanaris":    300.0,
		},
	}, "forever")
	index := BuildNameIndex(NodeNames{"deDE": parseNames(t, taxiNodesDE)}, nil)
	resolved, unresolved := snapshot.ResolveNames("forever", index)
	if resolved != 2 || len(unresolved) != 1 || unresolved[0] != "Orgrimmar, Durotar > Gadgetzan, Tanaris" {
		t.Fatalf("resolved %d, unresolved %v", resolved, unresolved)
	}
	routes := snapshot.Maps["forever"]["1411"]
	if got := Median(routes["23>25"].Samples); got != 111 {
		t.Errorf("23>25 = %v", got)
	}
	if got := Median(routes["25>23"].Samples); got != 50 {
		t.Errorf("vorhandene Strecke bleibt: %v", got)
	}
	if len(snapshot.Names) != 0 {
		t.Error("Namen müssen nach dem Umschreiben weg sein")
	}
	var out bytes.Buffer
	if err := snapshot.WriteLua(&out, "2026-11-10"); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out.String(), "names") || !strings.Contains(out.String(), `["23>25"] = 111,`) {
		t.Errorf("Ausgabe:\n%s", out.String())
	}
}

func TestResolveNamesWithoutKnownMap(t *testing.T) {
	snapshot := NewSnapshot()
	snapshot.Add(map[string]any{"flightTimes": map[string]any{"Orgrimmar, Durotar > Crossroads, Brachland": 111.0}}, "forever")
	index := BuildNameIndex(NodeNames{"deDE": parseNames(t, taxiNodesDE)}, nil)
	if resolved, unresolved := snapshot.ResolveNames("forever", index); resolved != 0 || len(unresolved) != 1 {
		t.Errorf("ohne bekannte Karte: %d %v", resolved, unresolved)
	}
}

func TestWriteNamesLua(t *testing.T) {
	index := BuildNameIndex(NodeNames{"deDE": parseNames(t, taxiNodesDE)}, nil)
	var out bytes.Buffer
	if err := WriteNamesLua(&out, "forever", "1.60.1", index, "2026-11-10"); err != nil {
		t.Fatal(err)
	}
	lua := out.String()
	for _, want := range []string{`if ns.Client.Flavor() ~= "forever" then return end`, `["Crossroads, Brachland"] = 25,`,
		`["Orgrimmar, Durotar"] = 23,`, "Nicht von Hand ändern"} {
		if !strings.Contains(lua, want) {
			t.Errorf("fehlt %q in\n%s", want, lua)
		}
	}
	if strings.Contains(lua, "Gadgetzan") || strings.Contains(lua, "\r") {
		t.Error("mehrdeutige Namen fehlen, LF")
	}
}

// wago.tools wählt die Sprache über den Parameter locale
func TestTableLocaleQuery(t *testing.T) {
	var queries []string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		queries = append(queries, r.URL.Path+"?"+r.URL.RawQuery)
		w.Write([]byte(taxiNodesDE))
	}))
	defer server.Close()
	client := &wagoClient{http: server.Client(), base: server.URL}
	names, err := client.TaxiNames("1.60.1", []string{"deDE", "frFR"})
	if err != nil {
		t.Fatal(err)
	}
	if len(names) != 2 || names["frFR"][25] != "Crossroads, Brachland" {
		t.Errorf("names = %v", names)
	}
	if len(queries) != 2 || queries[0] != "/db2/TaxiNodes/csv?build=1.60.1&locale=deDE" {
		t.Errorf("queries = %v", queries)
	}
}
