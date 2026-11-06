package main

import (
	"archive/zip"
	"io"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

func TestWritePackage(t *testing.T) {
	a, _ := setup(t)
	writeFile(t, filepath.Join(a.Dir, "LevelTimer.toc"), "## Version: "+VersionToken+"\nLocales.lua\nLevelTimer.lua\n")
	writeFile(t, filepath.Join(a.Dir, "LICENSE"), "license")
	writeFile(t, filepath.Join(a.Dir, "Makefile"), "nicht ins Paket")

	zipPath := filepath.Join(t.TempDir(), "dist", "LevelTimer-v2.zip")
	if err := WritePackage([]*Addon{a}, zipPath); err != nil {
		t.Fatal(err)
	}

	archive, err := zip.OpenReader(zipPath)
	if err != nil {
		t.Fatal(err)
	}
	defer archive.Close()

	contents := map[string]string{}
	var names []string
	for _, file := range archive.File {
		r, err := file.Open()
		if err != nil {
			t.Fatal(err)
		}
		data, _ := io.ReadAll(r)
		r.Close()
		contents[file.Name] = string(data)
		names = append(names, file.Name)
	}
	sort.Strings(names)

	want := []string{"LevelTimer/LICENSE", "LevelTimer/LevelTimer.lua", "LevelTimer/LevelTimer.toc", "LevelTimer/Locales.lua"}
	if strings.Join(names, ",") != strings.Join(want, ",") {
		t.Errorf("Dateien = %v, want %v", names, want)
	}
	if !strings.Contains(contents["LevelTimer/LevelTimer.toc"], "## Version: v2") {
		t.Errorf("Version nicht eingesetzt: %q", contents["LevelTimer/LevelTimer.toc"])
	}
}
