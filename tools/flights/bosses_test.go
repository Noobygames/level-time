package main

import (
	"io"
	"strings"
	"testing"
)

func TestParseBossesOrdersAndLocalizes(t *testing.T) {
	header := "Name_lang,ID,MapID,DifficultyID,OrderIndex\n"
	tables := make([]io.Reader, len(NameLocales))
	for i := range NameLocales {
		final := "\"Edwin VanCleef\""
		if NameLocales[i] == "deDE" {
			final = "\"Edwin van Cleef\""
		}
		tables[i] = strings.NewReader(header + final + ",2747,36,0,6000\nRhahk'Zor,2741,36,0,0\n")
	}
	bosses, err := ParseBosses("1.0", tables)
	if err != nil {
		t.Fatal(err)
	}
	if got := bosses.Maps[36][0]; len(got) != 2 || got[0] != 2741 || got[1] != 2747 {
		t.Fatalf("Reihenfolge nach OrderIndex: %v", got)
	}
	var b strings.Builder
	if err := WriteBossesLua(&b, "classic_era", bosses, "2026-11-13"); err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"[36] = { [0] = { 2741, 2747 }, },", "[2741] = \"Rhahk'Zor\",", "\"Edwin van Cleef\""} {
		if !strings.Contains(b.String(), want) {
			t.Errorf("fehlt %q in\n%s", want, b.String())
		}
	}
}
