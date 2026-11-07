package main

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func readFile(t *testing.T, path string) string {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(data)
}

// setup legt eine Addon-Quelle und eine WoW-Installation mit _retail_ samt Config an.
func setup(t *testing.T) (*Addon, Flavor) {
	t.Helper()
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	writeFile(t, filepath.Join(src, "LevelTimer.toc"), "## Title: LevelTimer\n## SavedVariables: LevelTimerDB\n\nLocales.lua\r\nLevelTimer.lua\n")
	writeFile(t, filepath.Join(src, "Locales.lua"), "locales")
	writeFile(t, filepath.Join(src, "LevelTimer.lua"), "core v2")

	flavorDir := filepath.Join(dir, "wow", "_retail_")
	writeFile(t, filepath.Join(flavorDir, "WTF", "Account", "X", "SavedVariables", "LevelTimer.lua"), "LevelTimerDB = {}")
	if err := os.MkdirAll(filepath.Join(flavorDir, "Interface", "AddOns"), 0o755); err != nil {
		t.Fatal(err)
	}

	a, err := LoadAddon(src, "v2")
	if err != nil {
		t.Fatal(err)
	}
	return a, Flavor{Name: "_retail_", Dir: flavorDir}
}

func TestLoadAddonReadsTocFileList(t *testing.T) {
	a, _ := setup(t)
	if a.Name != "LevelTimer" {
		t.Errorf("Name = %q", a.Name)
	}
	want := []string{"LevelTimer.toc", "Locales.lua", "LevelTimer.lua"}
	if !reflect.DeepEqual(a.Files, want) {
		t.Errorf("Files = %v, want %v", a.Files, want)
	}
}

func TestLoadAddonFailsOnMissingFile(t *testing.T) {
	src := t.TempDir()
	writeFile(t, filepath.Join(src, "A.toc"), "Missing.lua\n")
	if _, err := LoadAddon(src, "x"); err == nil || !strings.Contains(err.Error(), "Missing.lua") {
		t.Fatalf("err = %v", err)
	}
}

func TestFreshInstall(t *testing.T) {
	a, f := setup(t)
	p, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if p.Installed() || len(p.Migrations) != 0 || !p.NeedsRestart() {
		t.Fatalf("unexpected plan: installed=%v migrations=%d restart=%v", p.Installed(), len(p.Migrations), p.NeedsRestart())
	}
	if err := p.Apply(a); err != nil {
		t.Fatal(err)
	}
	if got := readFile(t, filepath.Join(p.Target, "LevelTimer.lua")); got != "core v2" {
		t.Errorf("LevelTimer.lua = %q", got)
	}
	m, err := readManifest(p.Target)
	if err != nil || m == nil || m.Version != "v2" {
		t.Fatalf("manifest = %+v, err = %v", m, err)
	}

	again, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if again.HasChanges() {
		t.Error("zweiter Lauf sollte nichts ändern")
	}
}

func TestLegacyInstallIsMigratedAndConfigUntouched(t *testing.T) {
	a, f := setup(t)
	target := filepath.Join(f.AddOnsDir(), "LevelTimer")
	writeFile(t, filepath.Join(target, "LevelTimer.toc"), "LevelTimer.lua\n")
	writeFile(t, filepath.Join(target, "LevelTimer.lua"), "core v1")
	writeFile(t, filepath.Join(target, "Old.lua"), "stale")
	writeFile(t, filepath.Join(target, "notes.txt"), "user file")
	configPath := filepath.Join(f.Dir, "WTF", "Account", "X", "SavedVariables", "LevelTimer.lua")

	p, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if !p.Legacy || len(p.Migrations) != 1 || p.Migrations[0].id != "001-adopt-legacy-install" {
		t.Fatalf("legacy=%v migrations=%v", p.Legacy, p.Migrations)
	}
	if !reflect.DeepEqual(p.Remove, []string{"Old.lua"}) {
		t.Errorf("Remove = %v", p.Remove)
	}
	if err := p.Apply(a); err != nil {
		t.Fatal(err)
	}

	if _, err := os.Stat(filepath.Join(target, "Old.lua")); !os.IsNotExist(err) {
		t.Error("Old.lua sollte entfernt sein")
	}
	if got := readFile(t, filepath.Join(target, "notes.txt")); got != "user file" {
		t.Error("fremde Datei verändert")
	}
	if got := readFile(t, configPath); got != "LevelTimerDB = {}" {
		t.Errorf("Config verändert: %q", got)
	}

	again, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if len(again.Migrations) != 0 || again.HasChanges() {
		t.Error("Migration darf nur einmal laufen")
	}
}

func TestFilesDroppedFromTocAreRemoved(t *testing.T) {
	a, f := setup(t)
	p, _ := BuildPlan(a, f)
	if err := p.Apply(a); err != nil {
		t.Fatal(err)
	}

	writeFile(t, filepath.Join(a.Dir, "LevelTimer.toc"), "LevelTimer.lua\n")
	a2, err := LoadAddon(a.Dir, "v3")
	if err != nil {
		t.Fatal(err)
	}
	p2, err := BuildPlan(a2, f)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(p2.Remove, []string{"Locales.lua"}) {
		t.Fatalf("Remove = %v", p2.Remove)
	}
	if err := p2.Apply(a2); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(p2.Target, "Locales.lua")); !os.IsNotExist(err) {
		t.Error("Locales.lua sollte entfernt sein")
	}
}

func TestConfigPathsAreRefused(t *testing.T) {
	if err := ensureNotConfigPath(filepath.Join("x", "WTF", "Account")); err == nil {
		t.Error("WTF-Pfad muss verweigert werden")
	}
	if _, err := safeJoin(t.TempDir(), "../escape.lua"); err == nil {
		t.Error("Pfad außerhalb des Ziels muss verweigert werden")
	}
}

func TestParseSelection(t *testing.T) {
	plans := []*Plan{
		{Flavor: Flavor{Name: "_classic_era_"}},
		{Flavor: Flavor{Name: "_retail_"}},
		{Flavor: Flavor{Name: "_anniversary_"}},
	}
	tests := []struct {
		input   string
		want    []int
		wantErr bool
	}{
		{"", []int{1}, false},
		{"all", []int{0, 1, 2}, false},
		{"3, 1", []int{2, 0}, false},
		{"retail,_classic_era_", []int{1, 0}, false},
		{"1,1", []int{0}, false},
		{"4", nil, true},
		{"ptr", nil, true},
	}
	for _, tt := range tests {
		got, err := parseSelection(tt.input, plans, []int{1})
		if (err != nil) != tt.wantErr {
			t.Errorf("%q: err = %v", tt.input, err)
			continue
		}
		if !tt.wantErr && !reflect.DeepEqual(got, tt.want) {
			t.Errorf("%q: got %v, want %v", tt.input, got, tt.want)
		}
	}
}

func TestNormalizeRoot(t *testing.T) {
	root := filepath.Join("D:", "Games", "World of Warcraft")
	if got := NormalizeRoot(filepath.Join(root, "_retail_")); got != root {
		t.Errorf("got %q", got)
	}
	if got := NormalizeRoot(root); got != root {
		t.Errorf("got %q", got)
	}
}

func TestVersionTokenIsReplacedOnInstall(t *testing.T) {
	a, f := setup(t)
	writeFile(t, filepath.Join(a.Dir, "LevelTimer.toc"), "## Version: "+VersionToken+"\nLocales.lua\nLevelTimer.lua\n")
	p, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if err := p.Apply(a); err != nil {
		t.Fatal(err)
	}
	if got := readFile(t, filepath.Join(p.Target, "LevelTimer.toc")); !strings.Contains(got, "## Version: v2\n") {
		t.Errorf("toc = %q", got)
	}

	again, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if again.HasChanges() {
		t.Error("eingesetzte Version darf nicht als Änderung gelten")
	}
}

func TestBindingsAreInstalledWithoutTocEntry(t *testing.T) {
	a, _ := setup(t)
	writeFile(t, filepath.Join(a.Dir, "Bindings.xml"), "<Bindings/>")
	a, err := LoadAddon(a.Dir, "v2")
	if err != nil {
		t.Fatal(err)
	}
	if a.Files[len(a.Files)-1] != "Bindings.xml" {
		t.Fatalf("Files = %v", a.Files)
	}
}

func TestMediaFilesAreInstalledWithoutTocEntry(t *testing.T) {
	a, f := setup(t)
	writeFile(t, filepath.Join(a.Dir, "Media", "Icon.tga"), "icon")
	a, err := LoadAddon(a.Dir, "v2")
	if err != nil {
		t.Fatal(err)
	}
	if a.Files[len(a.Files)-1] != "Media/Icon.tga" {
		t.Fatalf("Files = %v", a.Files)
	}

	p, err := BuildPlan(a, f)
	if err != nil {
		t.Fatal(err)
	}
	if err := p.Apply(a); err != nil {
		t.Fatal(err)
	}
	if got := readFile(t, filepath.Join(p.Target, "Media", "Icon.tga")); got != "icon" {
		t.Errorf("Icon.tga = %q", got)
	}
}
