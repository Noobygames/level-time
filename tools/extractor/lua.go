package main

import (
	"fmt"

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
func LoadGuide(path string) (map[string]any, error) {
	L := lua.NewState(lua.Options{SkipOpenLibs: true})
	defer L.Close()
	fn, err := L.LoadFile(path)
	if err != nil {
		return nil, err
	}
	ns, client := L.NewTable(), L.NewTable()
	client.RawSetString("Flavor", L.NewFunction(func(L *lua.LState) int {
		L.Push(lua.LString("forever"))
		return 1
	}))
	ns.RawSetString("Client", client)
	L.Push(fn)
	L.Push(lua.LString("LevelTimer"))
	L.Push(ns)
	if err := L.PCall(2, 0, nil); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	guide, ok := toGo(ns.RawGetString("InstanceGuide")).(map[string]any)
	if !ok {
		return nil, fmt.Errorf("%s: ns.InstanceGuide fehlt", path)
	}
	return guide, nil
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
