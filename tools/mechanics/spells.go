package main

// Prüfung der Zauber-IDs gegen den aktuellen WoW-Forever-Build (DB2 SpellName von wago.tools, wie tools/flights):
// eine Zeile, die auch auf Forever gilt, braucht eine Zauber-ID, die es in Forever gibt; sonst gehört sie als
// "version": "classic" markiert. Aufruf über "make mechanics ARGS=-spellcheck".

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"
)

const (
	wagoBase       = "https://wago.tools"
	wagoUserAgent  = "LevelTimer-mechanics-tool"
	foreverProduct = "wowf"
)

// foreverSpellIDs lädt die Zauber-IDs des neuesten Forever-Builds; Ergebnis: IDs und Build
func foreverSpellIDs() (map[int]bool, string, error) {
	client := &http.Client{Timeout: 2 * time.Minute}
	get := func(path string) (io.ReadCloser, error) {
		request, err := http.NewRequest(http.MethodGet, wagoBase+path, nil)
		if err != nil {
			return nil, err
		}
		request.Header.Set("User-Agent", wagoUserAgent)
		response, err := client.Do(request)
		if err != nil {
			return nil, err
		}
		if response.StatusCode != http.StatusOK {
			response.Body.Close()
			return nil, fmt.Errorf("%s: HTTP %d", path, response.StatusCode)
		}
		return response.Body, nil
	}
	body, err := get("/api/builds")
	if err != nil {
		return nil, "", err
	}
	var builds map[string][]struct {
		Version   string `json:"version"`
		CreatedAt string `json:"created_at"`
	}
	err = json.NewDecoder(body).Decode(&builds)
	body.Close()
	if err != nil {
		return nil, "", fmt.Errorf("api/builds: %w", err)
	}
	build, newest := "", ""
	for _, b := range builds[foreverProduct] {
		if b.CreatedAt > newest {
			build, newest = b.Version, b.CreatedAt
		}
	}
	if build == "" {
		return nil, "", fmt.Errorf("wago.tools: kein Build für %s", foreverProduct)
	}
	body, err = get("/db2/SpellName/csv?build=" + build)
	if err != nil {
		return nil, "", err
	}
	defer body.Close()
	ids, err := readSpellIDs(body)
	return ids, build, err
}

// readSpellIDs liest die ID-Spalte einer SpellName-CSV (Kopfzeile "ID,Name_lang")
func readSpellIDs(r io.Reader) (map[int]bool, error) {
	rows, err := csv.NewReader(r).ReadAll()
	if err != nil {
		return nil, err
	}
	ids := map[int]bool{}
	for _, row := range rows {
		if id, err := strconv.Atoi(row[0]); err == nil {
			ids[id] = true
		}
	}
	if len(ids) == 0 {
		return nil, fmt.Errorf("SpellName: keine Zeilen")
	}
	return ids, nil
}

// missingSpells: Zeilen, die auf Forever gelten, deren Zauber-ID der Forever-Build aber nicht kennt
func missingSpells(entries []entry, ids map[int]bool) []string {
	var out []string
	for _, e := range entries {
		for _, m := range e.Mechanics {
			if m.SpellID > 0 && m.Version != "classic" && !ids[m.SpellID] {
				out = append(out, fmt.Sprintf("%s (%s, NPC %d): %d %s", e.Name, e.instance, e.NpcID, m.SpellID, m.Spell))
			}
		}
	}
	return out
}
