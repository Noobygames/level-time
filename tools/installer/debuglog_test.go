package main

import (
	"bytes"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

const savedVariablesSample = `
LevelTimerDB = {
	["lines"] = {
		"not mine", -- [1]
	},
}
LevelTimerDebugLog = {
	["enabled"] = true,
	["lines"] = {
		"2026-11-06 12:00:00 [10.00] session: start Name-Realm", -- [1]
		"2026-11-06 12:00:01 [11.50] event: CHAT_MSG_SKILL(\"Kochkunst\" 5)", -- [2]
		"2026-11-06 12:00:02 [12.00] error: boom\nstack line", -- [3]
	},
}
LevelTimerStatsDB = {
}
`

func TestParseDebugLog(t *testing.T) {
	lines, err := ParseDebugLog(strings.NewReader(savedVariablesSample))
	if err != nil {
		t.Fatal(err)
	}
	want := []string{
		"2026-11-06 12:00:00 [10.00] session: start Name-Realm",
		`2026-11-06 12:00:01 [11.50] event: CHAT_MSG_SKILL("Kochkunst" 5)`,
		"2026-11-06 12:00:02 [12.00] error: boom\nstack line",
	}
	if !reflect.DeepEqual(lines, want) {
		t.Fatalf("lines = %q, want %q", lines, want)
	}
}

func TestParseDebugLogMissing(t *testing.T) {
	lines, err := ParseDebugLog(strings.NewReader("LevelTimerDB = {\n}\n"))
	if err != nil || len(lines) != 0 {
		t.Fatalf("lines = %q, err = %v", lines, err)
	}
}

func TestRunDebugLogFindsAccountsAndTails(t *testing.T) {
	root := t.TempDir()
	dir := filepath.Join(root, "_forever_", "WTF", "Account", "ACC1", "SavedVariables")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, savedVarsFile), []byte(savedVariablesSample), 0o644); err != nil {
		t.Fatal(err)
	}
	var out, info bytes.Buffer
	if err := runDebugLog(options{wowDir: root, tail: 1}, &out, &info); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(info.String(), "== _forever_ / ACC1 (3 Zeilen)") {
		t.Fatalf("unexpected header:\n%s", info.String())
	}
	text := out.String()
	if !strings.Contains(text, "error: boom") ||
		strings.Contains(text, "session: start") {
		t.Fatalf("unexpected output:\n%s", text)
	}
}
