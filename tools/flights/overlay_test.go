package main

import (
	"strings"
	"testing"
)

const overlayCSV = `ID,UiMapArtID,TextureWidth,TextureHeight,OffsetX,OffsetY
84,1244,300,200,382,281
85,1244,100,100,1,2
86,7,100,100,0,0
`

// Overlay 84: 2x1 Kacheln, nur die zweite vorhanden; 85 ohne Kacheln; 86 eine Kachel
const overlayTileCSV = `ID,RowIndex,ColIndex,LayerIndex,FileDataID,WorldMapOverlayID
1,0,1,0,555,84
2,0,0,0,777,86
`

func TestParseMapOverlays(t *testing.T) {
	data, err := ParseMapOverlays("1.0", strings.NewReader(overlayCSV), strings.NewReader(overlayTileCSV))
	if err != nil {
		t.Fatal(err)
	}
	if data.Count() != 2 || len(data.Art[1244]) != 1 {
		t.Fatalf("Überlagerungen: %+v", data.Art)
	}
	o := data.Art[1244][0]
	if len(o.Tiles) != 2 || o.Tiles[0] != 0 || o.Tiles[1] != 555 || o.OffsetX != 382 {
		t.Errorf("Overlay 84: %+v", o)
	}
	var out strings.Builder
	if err := WriteMapOverlaysLua(&out, "forever", data, "2026-11-16"); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "{ 300, 200, 382, 281, 0, 555 },") || !strings.Contains(out.String(), "[7] = {") {
		t.Errorf("Lua: %s", out.String())
	}
}
