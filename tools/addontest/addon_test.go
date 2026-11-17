// Package addontest führt die Lua-Szenarien aus tests/ gegen das Addon aus.
// Jede *_test.lua bekommt einen frischen Lua-5.1-Zustand (wie der WoW-Client),
// in den tests/wow_stub.lua die WoW-API nachbaut und das Addon lädt.
// Tempo: die Szenarien laufen parallel (jedes hat seinen eigenen Zustand, sie teilen nichts), und jede Lua-Datei
// wird nur einmal geparst und kompiliert (protoCache); loadfile und dofile liefern danach eine neue Funktion aus dem
// fertigen Bytecode. Vorher las jedes der ~400 Szenarien alle ~370 Addon-Dateien neu aus dem Quelltext.
package addontest

import (
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	lua "github.com/yuin/gopher-lua"
)

const repoRoot = "../.."

func TestScenarios(t *testing.T) {
	root, err := filepath.Abs(repoRoot)
	if err != nil {
		t.Fatal(err)
	}
	scenarios, err := filepath.Glob(filepath.Join(root, "tests", "*_test.lua"))
	if err != nil {
		t.Fatal(err)
	}
	if len(scenarios) == 0 {
		t.Fatal("keine Szenarien in tests/ gefunden")
	}

	// Begrenzung: t.Parallel() allein liefe mit GOMAXPROCS Szenarien gleichzeitig (siehe scenarioLimit)
	limit := scenarioLimit()
	runtime.GOMAXPROCS(limit)
	limitMemory()
	lowerPriority()
	slots := make(chan struct{}, limit)

	for _, scenario := range scenarios {
		name := strings.TrimSuffix(filepath.Base(scenario), "_test.lua")
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			defer acquire(slots, scenarioWeight(name))()
			runScenario(t, root, scenario)
		})
	}
}

func runScenario(t *testing.T, root, scenario string) {
	L := lua.NewState()
	defer L.Close()
	useProtoCache(L)

	L.SetGlobal("ADDON_DIR", lua.LString(filepath.ToSlash(root)))
	L.SetGlobal("SCENARIO", lua.LString(strings.TrimSuffix(filepath.Base(scenario), "_test.lua")))
	if err := doFile(L, filepath.Join(root, "tests", "wow_stub.lua")); err != nil {
		t.Fatalf("Addon laden: %v", err)
	}
	if err := doFile(L, scenario); err != nil {
		t.Fatalf("Szenario abgebrochen: %v", err)
	}

	failures, ok := L.GetGlobal("TEST_FAILURES").(*lua.LTable)
	if !ok {
		t.Fatal("TEST_FAILURES fehlt")
	}
	failures.ForEach(func(_, failure lua.LValue) {
		t.Error(failure.String())
	})

	// Fehler, die das Addon geschützt abgefangen hat (ns.SafeCall -> geterrorhandler), zählen als
	// Fehlschlag; Szenarien, die absichtlich Fehler auslösen, leeren wow.errors danach.
	if wow, ok := L.GetGlobal("wow").(*lua.LTable); ok {
		if caught, ok := wow.RawGetString("errors").(*lua.LTable); ok {
			caught.ForEach(func(_, message lua.LValue) {
				t.Errorf("abgefangener Lua-Fehler: %s", message.String())
			})
		}
	}
}
