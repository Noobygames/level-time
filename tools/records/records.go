package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
)

// Leaderboard auf speedrun.com: WoW Classic Leveling (Classic Era), Kategorie SSF, Modus Softcore.
// IDs aus https://www.speedrun.com/api/v1/games/j1lljpz1/variables.
const (
	gameID       = "j1lljpz1"
	categoryID   = "xk964r6k" // SSF
	bracketVarID = "0nwgjqd8" // Leveling Brackets
	modeVarID    = "wle4e6xn" // Mode
	softcoreID   = "14opw2jq"
	classVarID   = "yn219508" // Class (für SSF)
	sourceLabel  = "speedrun.com: World of Warcraft Classic: Leveling, SSF, Softcore"
)

// Bracket ist ein Abschnitt des Leaderboards, z.B. 1-10 = bis Level 10.
type Bracket struct {
	Label   string
	Level   int
	ValueID string
}

var brackets = []Bracket{
	{Label: "1-10", Level: 10, ValueID: "le23gxkl"},
	{Label: "1-20", Level: 20, ValueID: "1gnjkr6l"},
	{Label: "1-60", Level: 60, ValueID: "q5vxe32l"},
}

// Klassen-Werte des Leaderboards -> Klassen-Token des Spiels (UnitClass)
var classValues = map[string]string{
	"gq7r8ndl": "WARRIOR",
	"jqzxj621": "PALADIN",
	"21g2mj8l": "HUNTER",
	"klrygzmq": "ROGUE",
	"jqzxj681": "PRIEST",
	"klrygzoq": "SHAMAN",
	"gq7r8npl": "MAGE",
	"21g2mj6l": "WARLOCK",
	"21d304pq": "DRUID",
}

// Record ist der schnellste Lauf eines Brackets (gesamt oder einer Klasse).
type Record struct {
	Seconds int
	Runner  string
	Class   string
	Date    string
	Link    string
}

// BracketRecords enthält den Gesamtrekord und den besten Lauf je Klasse.
type BracketRecords struct {
	Bracket Bracket
	Best    *Record
	Classes map[string]*Record
}

type leaderboardResponse struct {
	Data struct {
		Runs []struct {
			Run struct {
				Weblink string `json:"weblink"`
				Date    string `json:"date"`
				Times   struct {
					PrimaryT float64 `json:"primary_t"`
				} `json:"times"`
				Players []struct {
					ID   string `json:"id"`
					Name string `json:"name"`
				} `json:"players"`
				Values map[string]string `json:"values"`
			} `json:"run"`
		} `json:"runs"`
		Players struct {
			Data []struct {
				ID    string `json:"id"`
				Names struct {
					International string `json:"international"`
				} `json:"names"`
				Name string `json:"name"`
			} `json:"data"`
		} `json:"players"`
	} `json:"data"`
}

// Fetcher holt Leaderboards von BaseURL (https://www.speedrun.com/api/v1, im Test ein httptest-Server).
type Fetcher struct {
	Client  *http.Client
	BaseURL string
}

// best liefert den ersten Lauf des Leaderboards, nil wenn es keinen gibt.
func (f Fetcher) best(bracket Bracket, classValue string) (*Record, error) {
	query := url.Values{}
	query.Set("var-"+bracketVarID, bracket.ValueID)
	query.Set("var-"+modeVarID, softcoreID)
	if classValue != "" {
		query.Set("var-"+classVarID, classValue)
	}
	query.Set("top", "1")
	query.Set("embed", "players")
	address := fmt.Sprintf("%s/leaderboards/%s/category/%s?%s", f.BaseURL, gameID, categoryID, query.Encode())

	response, err := f.Client.Get(address)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(response.Body)
		return nil, fmt.Errorf("%s: %s %s", address, response.Status, strings.TrimSpace(string(body)))
	}
	var board leaderboardResponse
	if err := json.NewDecoder(response.Body).Decode(&board); err != nil {
		return nil, err
	}
	if len(board.Data.Runs) == 0 {
		return nil, nil
	}

	names := map[string]string{}
	for _, player := range board.Data.Players.Data {
		name := player.Names.International
		if name == "" {
			name = player.Name
		}
		names[player.ID] = name
	}
	run := board.Data.Runs[0].Run
	var runners []string
	for _, player := range run.Players {
		if name := names[player.ID]; name != "" {
			runners = append(runners, name)
		} else {
			runners = append(runners, player.Name) // Gastspieler ohne Konto
		}
	}
	return &Record{
		Seconds: int(run.Times.PrimaryT),
		Runner:  strings.Join(runners, ", "),
		Class:   classValues[run.Values[classVarID]],
		Date:    run.Date,
		Link:    run.Weblink,
	}, nil
}

// FetchAll holt für jedes Bracket den Gesamtrekord und den besten Lauf jeder Klasse.
func (f Fetcher) FetchAll() ([]BracketRecords, error) {
	var result []BracketRecords
	for _, bracket := range brackets {
		records := BracketRecords{Bracket: bracket, Classes: map[string]*Record{}}
		best, err := f.best(bracket, "")
		if err != nil {
			return nil, err
		}
		records.Best = best
		for value, class := range classValues {
			record, err := f.best(bracket, value)
			if err != nil {
				return nil, err
			}
			if record != nil {
				records.Classes[class] = record
			}
		}
		result = append(result, records)
	}
	return result, nil
}

// luaString setzt einen Text sicher in Anführungszeichen. Lua 5.1 kennt keine \x- oder \u-Escapes,
// daher Steuerzeichen als \ddd; UTF-8-Zeichen bleiben unverändert.
func luaString(text string) string {
	var b strings.Builder
	b.WriteByte('"')
	for i := 0; i < len(text); i++ {
		c := text[i]
		switch {
		case c == '"' || c == '\\':
			b.WriteByte('\\')
			b.WriteByte(c)
		case c < 0x20 || c == 0x7f:
			fmt.Fprintf(&b, "\\%03d", c)
		default:
			b.WriteByte(c)
		}
	}
	b.WriteByte('"')
	return b.String()
}

// luaRecord: der Link steht in einer eigenen Zeile (indent = Einrückung der Zeile mit dem Eintrag), damit keine Zeile
// länger als 140 Zeichen wird (luacheck)
func luaRecord(record *Record, indent string) string {
	return fmt.Sprintf("{ seconds = %d, runner = %s, class = %s, date = %s,\n%s  link = %s }",
		record.Seconds, luaString(record.Runner), luaString(record.Class), luaString(record.Date), indent, luaString(record.Link))
}

// WriteLua schreibt die Daten als Lua-Datei für das Addon (ns.SpeedrunRecordsData).
func WriteLua(w io.Writer, all []BracketRecords, fetched string) error {
	var b strings.Builder
	b.WriteString("-- Automatisch erzeugt von tools/records (make records). Nicht von Hand ändern.\n")
	b.WriteString("-- Schnellste Läufe je Abschnitt (gesamt und je Klasse), Zeiten in Echtzeit-Sekunden.\n")
	b.WriteString("local _, ns = ...\n\n")
	b.WriteString("ns.SpeedrunRecordsData = {\n")
	fmt.Fprintf(&b, "  source = %s,\n", luaString(sourceLabel))
	fmt.Fprintf(&b, "  fetched = %s,\n", luaString(fetched))
	b.WriteString("  brackets = {\n")
	for _, records := range all {
		if records.Best == nil {
			continue
		}
		fmt.Fprintf(&b, "    {\n      label = %s,\n      level = %d,\n", luaString(records.Bracket.Label), records.Bracket.Level)
		fmt.Fprintf(&b, "      best = %s,\n", luaRecord(records.Best, "      "))
		b.WriteString("      classes = {\n")
		classes := make([]string, 0, len(records.Classes))
		for class := range records.Classes {
			classes = append(classes, class)
		}
		sort.Strings(classes)
		for _, class := range classes {
			fmt.Fprintf(&b, "        %s = %s,\n", class, luaRecord(records.Classes[class], "        "))
		}
		b.WriteString("      },\n    },\n")
	}
	b.WriteString("  },\n}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
