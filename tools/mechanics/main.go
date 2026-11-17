// Mechanics erzeugt aus der Guide-Recherche (docs/research/mechanics/*.json, je Instanz eine Datei) die Tooltip-Daten
// Assist/InstanceData/mechanics.lua: Boss- und Trash-Fähigkeiten je NPC-ID. Liest jede vorhandene Datei, neue Instanzen
// kommen also einfach durch eine weitere JSON-Datei dazu. Aufruf über "make mechanics".
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Gruppen einer Instanzdatei, deren Einheiten Tooltipzeilen bekommen
var groups = []string{"bosses", "rares", "trash"}

// Erlaubte Typen (Farbe und Symbol im Addon: Assist/Mechanics.lua)
var types = map[string]bool{"avoid": true, "interrupt": true, "dispel": true, "tank": true, "survive": true,
	"adds": true, "positioning": true}

type mechanic struct {
	SpellID int    `json:"spellID"`
	Spell   string `json:"spell"`
	Type    string `json:"type"`
	En      string `json:"en"`
	De      string `json:"de"`
	// Version: leer = beide Flavors, "classic" = nur Classic Era, "forever" = nur WoW Forever
	Version string `json:"version"`
	// Verified: eine Forever-Quelle bestätigt die Fähigkeit (Forever zeigt sonst den Hinweis "aus Classic übernommen")
	Verified bool `json:"verified"`
}

type unit struct {
	Name      string     `json:"name"`
	NpcID     int        `json:"npcID"`
	Mechanics []mechanic `json:"mechanics"`
}

type entry struct {
	unit
	instance string
	mapID    int    // instanceMapID der Datei (0 = unbekannt, dann nicht im Dungeon Guide)
	group    string // "bosses" oder "trash" (Rare zählen zum Trash)
	seq      int    // Reihenfolge in den Dateien (Dungeon Guide)
}

func main() {
	dir := flag.String("dir", "docs/research/mechanics", "Ordner der Recherche-Dateien (*.json)")
	luaOut := flag.String("lua", "Assist/InstanceData/mechanics.lua", "Ziel-Datei (Lua)")
	spellCheck := flag.Bool("spellcheck", false, "Zauber-IDs gegen den neuesten Forever-Build (wago.tools) prüfen")
	flag.Parse()
	entries, files, err := load(*dir)
	if err == nil && *spellCheck {
		err = checkSpells(entries)
	}
	if err == nil {
		err = os.WriteFile(*luaOut, []byte(render(entries)), 0o644)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	lines := 0
	for _, e := range entries {
		lines += len(e.Mechanics)
	}
	fmt.Printf("%s: %d Instanzdateien, %d NPCs, %d Mechaniken\n", *luaOut, files, len(entries), lines)
}

func checkSpells(entries []entry) error {
	ids, build, err := foreverSpellIDs()
	if err != nil {
		return err
	}
	missing := missingSpells(entries, ids)
	for _, line := range missing {
		fmt.Println("  fehlt in Forever:", line)
	}
	if len(missing) > 0 {
		return fmt.Errorf("%d Zauber-IDs fehlen im Forever-Build %s: als \"version\": \"classic\" markieren", len(missing), build)
	}
	fmt.Printf("Zauber-IDs: alle Forever-Zeilen im Build %s vorhanden\n", build)
	return nil
}

// load liest alle Instanzdateien; Ergebnis nach NPC-ID sortiert, nur Einheiten mit mindestens einer Mechanik mit Text
func load(dir string) ([]entry, int, error) {
	paths, err := filepath.Glob(filepath.Join(dir, "*.json"))
	if err != nil || len(paths) == 0 {
		return nil, 0, fmt.Errorf("keine Recherche-Dateien in %s (%v)", dir, err)
	}
	byID := map[int]entry{}
	for _, path := range paths {
		raw, err := os.ReadFile(path)
		if err != nil {
			return nil, 0, err
		}
		var file map[string]json.RawMessage
		if err := json.Unmarshal(raw, &file); err != nil {
			return nil, 0, fmt.Errorf("%s: %w", path, err)
		}
		var instance string
		var mapID int
		_ = json.Unmarshal(file["instance"], &instance)
		_ = json.Unmarshal(file["instanceMapID"], &mapID)
		var units []unit
		groupOf := map[int]string{}
		for _, group := range groups {
			var list []unit
			if file[group] != nil {
				if err := json.Unmarshal(file[group], &list); err != nil {
					return nil, 0, fmt.Errorf("%s (%s): %w", path, group, err)
				}
			}
			kind := "trash"
			if group == "bosses" {
				kind = "bosses"
			}
			for _, u := range list {
				groupOf[u.NpcID] = kind
			}
			units = append(units, list...)
		}
		fix := asciiUmlauts(units)
		for _, u := range units {
			kept := u.Mechanics[:0:0]
			for _, m := range u.Mechanics {
				if m.En == "" || m.De == "" {
					continue
				}
				if !types[m.Type] {
					return nil, 0, fmt.Errorf("%s: %s hat unbekannten Typ %q", path, u.Name, m.Type)
				}
				if _, ok := versionTags[m.Version]; !ok {
					return nil, 0, fmt.Errorf("%s: %s hat unbekannte Version %q", path, u.Name, m.Version)
				}
				if fix {
					m.De = umlautFixer.Replace(m.De)
				}
				kept = append(kept, m)
			}
			if u.NpcID <= 0 || len(kept) == 0 {
				continue
			}
			if old, dup := byID[u.NpcID]; dup {
				return nil, 0, fmt.Errorf("NPC %d doppelt (%s, %s)", u.NpcID, old.instance, instance)
			}
			u.Mechanics = kept
			byID[u.NpcID] = entry{u, instance, mapID, groupOf[u.NpcID], len(byID)}
		}
	}
	entries := make([]entry, 0, len(byID))
	for _, e := range byID {
		entries = append(entries, e)
	}
	sort.Slice(entries, func(i, j int) bool { return entries[i].NpcID < entries[j].NpcID })
	return entries, len(paths), nil
}

// asciiUmlauts: Dateien, deren deutsche Texte nirgends ä/ö/ü/ß enthalten, schreiben Umlaute als ae/oe/ue/ss
func asciiUmlauts(units []unit) bool {
	for _, u := range units {
		for _, m := range u.Mechanics {
			if strings.ContainsAny(m.De, "äöüÄÖÜß") {
				return false
			}
		}
	}
	return true
}

// Ausdrückliche Wortstämme statt einer Regel: "Feuer", "zuerst" oder "lassen" dürfen nicht umgeschrieben werden
var umlautFixer = strings.NewReplacer(
	"Beschwoer", "Beschwör", "Betaeub", "Betäub", "betaeub", "betäub", "Flaech", "Fläch", "schlaege", "schläge",
	"Naehe", "Nähe", "kaempf", "kämpf", "Schlaef", "Schläf", "schlaef", "schläf", "Verbuend", "Verbünd",
	"Weisskraehe", "Weißkrähe", "ausser", "außer", "erhoeh", "erhöh", "moeglich", "möglich", "schwaech", "schwäch",
	"toet", "töt", "Uebern", "Übern", "uebern", "übern", "wuetend", "wütend", "zurueck", "zurück", "Feuerstoss", "Feuerstoß",
)

// Kennung je Version im Lua (5. Feld); beide Flavors ohne Forever-Bestätigung bleiben ohne Kennung (kompakt)
var versionTags = map[string]string{"": "", "classic": "c", "forever": "f"}

func tag(m mechanic) string {
	if m.Version == "" && m.Verified {
		return "v"
	}
	return versionTags[m.Version]
}

// tagRank: für Forever bestätigt (v, f) vor unbestätigt vor Classic-only
func tagRank(m mechanic) int {
	switch tag(m) {
	case "v", "f":
		return 0
	case "c":
		return 2
	}
	return 1
}

func luaString(s string) string {
	return `"` + strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`).Replace(s) + `"`
}

func render(entries []entry) string {
	var b strings.Builder
	b.WriteString(`-- GENERIERT von tools/mechanics ("make mechanics"), nicht von Hand bearbeiten.
-- Quelle: Guide-Recherche docs/research/mechanics/*.json (je Instanz eine Datei), siehe sources.md.
-- ns.Mechanics = { [npcID] = { { spellID, Typ, Text deDE, Text enUS, Kennung }, ... } }
--   Kennung: "c" nur Classic Era, "f" nur Forever, "v" beide und für Forever bestätigt, ohne = beide, für Forever
--   nur aus Classic übernommen. Der Schluss der Datei entfernt die Zeilen des anderen Flavors.
--   spellID 0 = keine passende Zauber-ID (Zeile ohne Zaubersymbol), Typ: avoid, interrupt, dispel, tank, survive, adds,
--   positioning. Deutsche Clients lesen den deutschen Text, alle anderen (auch frFR/esES) den englischen; die Texte
--   laufen bewusst nicht über Locales (Spieldaten, kein UI-Text). Leser: Assist/Mechanics.lua.
local _, ns = ...
-- Nur Classic Era und Forever: klassische Instanzen, Retail hat andere Fähigkeiten an denselben NPCs.
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

ns.Mechanics = {
`)
	for _, e := range entries {
		// Bestätigte Zeilen zuerst: der Tooltip zeigt nur die ersten drei
		sort.SliceStable(e.Mechanics, func(i, j int) bool { return tagRank(e.Mechanics[i]) < tagRank(e.Mechanics[j]) })
		fmt.Fprintf(&b, "  [%d] = { -- %s (%s)\n", e.NpcID, e.Name, e.instance)
		for _, m := range e.Mechanics {
			fmt.Fprintf(&b, "    { %d, %q, %s, %s", m.SpellID, m.Type, luaString(m.De), luaString(m.En))
			if t := tag(m); t != "" {
				fmt.Fprintf(&b, ", %q", t)
			}
			b.WriteString(" },\n")
		}
		b.WriteString("  },\n")
	}
	b.WriteString(`}

-- Zeilen des anderen Flavors entfernen, NPCs ohne Zeile ganz
local otherTag = flavor == "forever" and "c" or "f"
for npcID, list in pairs(ns.Mechanics) do
  for index = #list, 1, -1 do
    if list[index][5] == otherTag then table.remove(list, index) end
  end
  if #list == 0 then ns.Mechanics[npcID] = nil end
end
`)
	renderGuide(&b, entries)
	return b.String()
}

// renderGuide: NPCs je Instanz für den Dungeon Guide (UI/DungeonGuide.lua), in der Reihenfolge der Recherche-Dateien;
// nur Dateien mit instanceMapID. Name englisch (nur Rückfall, wenn die Bossliste keinen übersetzten Namen hat).
func renderGuide(b *strings.Builder, entries []entry) {
	byMap := map[int][]entry{}
	var maps []int
	for _, e := range entries {
		if e.mapID == 0 {
			continue
		}
		if byMap[e.mapID] == nil {
			maps = append(maps, e.mapID)
		}
		byMap[e.mapID] = append(byMap[e.mapID], e)
	}
	sort.Ints(maps)
	b.WriteString(`
-- Dungeon Guide: ns.MechanicGuide = { [Karten-ID] = { bosses = { { NPC-ID, Name }, ... }, trash = { ... } } }
ns.MechanicGuide = {
`)
	for _, mapID := range maps {
		list := byMap[mapID]
		sort.Slice(list, func(i, j int) bool { return list[i].seq < list[j].seq })
		fmt.Fprintf(b, "  [%d] = {\n", mapID)
		for _, group := range []string{"bosses", "trash"} {
			fmt.Fprintf(b, "    %s = {", group)
			for _, e := range list {
				if e.group == group {
					fmt.Fprintf(b, " { %d, %s },", e.NpcID, luaString(e.Name))
				}
			}
			b.WriteString(" },\n")
		}
		b.WriteString("  },\n")
	}
	b.WriteString("}\n")
}
