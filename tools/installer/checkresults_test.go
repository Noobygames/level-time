package main

import (
	"bytes"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

const checkResultsSample = `
LevelTimerDebugLog = {
	["enabled"] = true,
	["checkResults"] = {
		["LT-226"] = {
			["status"] = "ok",
			["t"] = "2026-11-16 10:00:00",
		},
		["LT-12"] = {
			["status"] = "fail",
			["t"] = "2026-11-16 11:00:00",
			["note"] = "nur \"eine\" Leiche",
		},
	},
	["lines"] = {
		"x", -- [1]
	},
}
LevelTimerStatsDB = {
}
`

func TestParseCheckResults(t *testing.T) {
	got, err := ParseCheckResults(strings.NewReader(checkResultsSample))
	if err != nil {
		t.Fatal(err)
	}
	want := []CheckResult{
		{ID: "LT-226", Status: "ok", Time: "2026-11-16 10:00:00"},
		{ID: "LT-12", Status: "fail", Time: "2026-11-16 11:00:00", Note: `nur "eine" Leiche`},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("results = %+v, want %+v", got, want)
	}
}

func TestRunCheckResults(t *testing.T) {
	root := t.TempDir()
	dir := filepath.Join(root, "_forever_", "WTF", "Account", "ACC1", "SavedVariables")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, savedVarsFile), []byte(checkResultsSample), 0o644); err != nil {
		t.Fatal(err)
	}
	var out, info bytes.Buffer
	if err := runCheckResults(options{wowDir: root}, &out, &info); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "LT-226\tok\t2026-11-16 10:00:00\t\n") ||
		!strings.Contains(out.String(), "LT-12\tfail\t2026-11-16 11:00:00\tnur \"eine\" Leiche\n") {
		t.Fatalf("unexpected output:\n%s", out.String())
	}
	out.Reset()
	if err := runCheckResults(options{wowDir: root, json: true}, &out, &info); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), `"id":"LT-12","status":"fail"`) {
		t.Fatalf("unexpected json:\n%s", out.String())
	}
}
