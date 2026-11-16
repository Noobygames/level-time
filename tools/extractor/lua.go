package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	lua "github.com/yuin/gopher-lua"
)

// Lua-Dateien ohne Standardbibliotheken ausführen (SavedVariables und der Dungeonführer bestehen nur aus Tabellen)
// und die Ergebnisse als Go-Werte liefern: Tabellen werden immer zu map[string]any (Schlüssel als Text, auch
// Zahlen), damit Nummern-Schlüssel wie npcIDs oder Level nie stillschweigend zu Listen werden.

// LoadGlobal führt eine SavedVariables-Datei aus und gibt die globale Variable name zurück (nil, wenn sie fehlt).
func LoadGlobal(path, name string) (map[string]any, error) {
	L := lua.NewState(lua.Options{SkipOpenLibs: true})
	defer L.Close()
	if err := L.DoFile(path); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	table, _ := toGo(L.GetGlobal(name)).(map[string]any)
	return table, nil
}

// LoadGuide führt Assist/InstanceData/forever_guide.lua mit einem Namespace-Ersatz aus und gibt ns.InstanceGuide zurück.
// Die Dungeonquests kommen aus der dungeon_db.lua daneben (ns.DungeonDB, falls vorhanden) und stehen in
// guide["quests"] in der früheren Führer-Form: quests[mapID][index] = { questID, Questlevel, nil, ..., uiMapID, x, y }.
func LoadGuide(path string) (map[string]any, error) {
	L := lua.NewState(lua.Options{SkipOpenLibs: true})
	defer L.Close()
	ns := foreverNamespace(L)
	if err := runAddonFile(L, ns, path); err != nil {
		return nil, err
	}
	guide, ok := toGo(ns.RawGetString("InstanceGuide")).(map[string]any)
	if !ok {
		return nil, fmt.Errorf("%s: ns.InstanceGuide fehlt", path)
	}
	dbPath := filepath.Join(filepath.Dir(path), "dungeon_db.lua")
	if _, err := os.Stat(dbPath); err != nil {
		return guide, nil
	}
	if err := runAddonFile(L, ns, dbPath); err != nil {
		return nil, err
	}
	if db, ok := toGo(ns.RawGetString("DungeonDB")).(map[string]any); ok {
		guide["quests"] = guideQuests(db)
	}
	return guide, nil
}

// loadForeverTable führt eine Addon-Datei als WoW Forever aus und gibt ns[key] zurück; openLibs für Dateien, die
// selbst Standardfunktionen wie pairs aufrufen (nur Repo-Dateien, kein fremder Inhalt).
func loadForeverTable(path, key string, openLibs bool) (map[string]any, error) {
	L := lua.NewState(lua.Options{SkipOpenLibs: !openLibs})
	defer L.Close()
	ns := foreverNamespace(L)
	if err := runAddonFile(L, ns, path); err != nil {
		return nil, err
	}
	value, ok := toGo(ns.RawGetString(key)).(map[string]any)
	if !ok {
		return nil, fmt.Errorf("%s: ns.%s fehlt", path, key)
	}
	return value, nil
}

// foreverNamespace: Namespace-Ersatz mit ns.Client.Flavor() = "forever"
func foreverNamespace(L *lua.LState) *lua.LTable {
	ns, client := L.NewTable(), L.NewTable()
	client.RawSetString("Flavor", L.NewFunction(func(L *lua.LState) int {
		L.Push(lua.LString("forever"))
		return 1
	}))
	ns.RawSetString("Client", client)
	return ns
}

// runAddonFile führt eine Addon-Datei mit den Vararg-Werten ("LevelTimer", ns) aus.
func runAddonFile(L *lua.LState, ns *lua.LTable, path string) error {
	fn, err := L.LoadFile(path)
	if err != nil {
		return err
	}
	L.Push(fn)
	L.Push(lua.LString("LevelTimer"))
	L.Push(ns)
	if err := L.PCall(2, 0, nil); err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	return nil
}

// guideQuests: ns.DungeonDB.quests/questInfo (Spalten 1 Level, 7-9 Geber-Ort) in der Führer-Form.
func guideQuests(db map[string]any) map[string]any {
	out := map[string]any{}
	info := table(db, "questInfo")
	for mapID, raw := range table(db, "quests") {
		list := map[string]any{}
		ids, _ := raw.(map[string]any)
		for index, id := range ids {
			questID := strconv.Itoa(int(id.(float64)))
			quest := table(info, questID)
			entry := map[string]any{"1": id, "2": quest["1"]}
			for _, col := range []string{"7", "8", "9"} {
				if v, ok := quest[col]; ok {
					entry[col] = v
				}
			}
			list[index] = entry
		}
		out[mapID] = list
	}
	return out
}

func toGo(value lua.LValue) any {
	switch v := value.(type) {
	case lua.LBool:
		return bool(v)
	case lua.LNumber:
		return float64(v)
	case lua.LString:
		return string(v)
	case *lua.LTable:
		out := map[string]any{}
		v.ForEach(func(key, val lua.LValue) { out[key.String()] = toGo(val) })
		return out
	}
	return nil
}

// Zugriffshilfen auf die verschachtelten Werte
func table(m map[string]any, key string) map[string]any {
	t, _ := m[key].(map[string]any)
	return t
}

func number(m map[string]any, key string) (float64, bool) {
	n, ok := m[key].(float64)
	return n, ok
}
