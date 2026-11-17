package main

import (
	"fmt"
	"io"
	"sort"
	"strings"
)

// Kacheldaten der Karten-Überlagerungen (unerkundete Gebiete) aus den Spieldaten (DB2 von wago.tools):
//   WorldMapOverlay      ID, UiMapArtID, TextureWidth/Height, OffsetX/Y (Pixel auf der Karte)
//   WorldMapOverlayTile  WorldMapOverlayID, RowIndex, ColIndex, FileDataID
// Wie Blizzards MapExplorationDataProvider: Kacheln der Größe overlayTileSize, zeilenweise (Zeile * Breite + Spalte).

const overlayTileSize = 256

// OverlayFlavors sind die Flavors mit Karten-Überlagerung (Fokus WoW Forever und Classic Era).
var OverlayFlavors = map[string]bool{"classic_era": true, "forever": true}

// Overlay ist ein unerkundetes Gebiet einer Kartengrafik; Tiles zeilenweise (0 = Kachel fehlt in den Daten).
type Overlay struct {
	Width, Height, OffsetX, OffsetY int
	Tiles                           []int
}

// MapOverlays sind alle Überlagerungen eines Builds je UiMapArtID.
type MapOverlays struct {
	Build string
	Art   map[int][]Overlay
}

func ParseMapOverlays(build string, overlays, tiles io.Reader) (*MapOverlays, error) {
	overlayRows, err := readCSV(overlays)
	if err != nil {
		return nil, fmt.Errorf("WorldMapOverlay: %w", err)
	}
	tileRows, err := readCSV(tiles)
	if err != nil {
		return nil, fmt.Errorf("WorldMapOverlayTile: %w", err)
	}
	type key struct{ overlay, row, col int }
	files := map[key]int{}
	for _, row := range tileRows {
		files[key{integer(row["WorldMapOverlayID"]), integer(row["RowIndex"]), integer(row["ColIndex"])}] = integer(row["FileDataID"])
	}
	result := &MapOverlays{Build: build, Art: map[int][]Overlay{}}
	for _, row := range overlayRows {
		id, width, height := integer(row["ID"]), integer(row["TextureWidth"]), integer(row["TextureHeight"])
		if width <= 0 || height <= 0 {
			continue
		}
		wide, tall := (width+overlayTileSize-1)/overlayTileSize, (height+overlayTileSize-1)/overlayTileSize
		overlay := Overlay{Width: width, Height: height, OffsetX: integer(row["OffsetX"]), OffsetY: integer(row["OffsetY"]),
			Tiles: make([]int, wide*tall)}
		found := false
		for r := 0; r < tall; r++ {
			for c := 0; c < wide; c++ {
				if file := files[key{id, r, c}]; file != 0 {
					overlay.Tiles[r*wide+c] = file
					found = true
				}
			}
		}
		if found {
			art := integer(row["UiMapArtID"])
			result.Art[art] = append(result.Art[art], overlay)
		}
	}
	return result, nil
}

// Count liefert die Zahl der Überlagerungen.
func (m *MapOverlays) Count() int {
	n := 0
	for _, list := range m.Art {
		n += len(list)
	}
	return n
}

// WriteMapOverlaysLua schreibt Assist/MapOverlayData/<flavor>.lua (frühes return in anderen Flavors).
func WriteMapOverlaysLua(w io.Writer, flavor string, data *MapOverlays, date string) error {
	var b strings.Builder
	b.WriteString("-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 WorldMapOverlay, WorldMapOverlayTile von\n")
	fmt.Fprintf(&b, "-- wago.tools, Build %s), Stand %s. Nicht von Hand ändern.\n", data.Build, date)
	b.WriteString("-- ns.MapOverlayData = { build, art = { [UiMapArtID] = { { Breite, Höhe, OffsetX, OffsetY, FileDataID... } } } }\n")
	fmt.Fprintf(&b, "-- (Pixel der Kartengrafik; Kacheln %dx%d zeilenweise, 0 = fehlt). Lesen: Assist/MapReveal.lua.\n", overlayTileSize, overlayTileSize)
	b.WriteString("local _, ns = ...\n")
	fmt.Fprintf(&b, "if ns.Client.Flavor() ~= %q then return end\n\n", flavor)
	fmt.Fprintf(&b, "ns.MapOverlayData = {\n  build = %q,\n  art = {\n", data.Build)
	ids := make([]int, 0, len(data.Art))
	for id := range data.Art {
		ids = append(ids, id)
	}
	sort.Ints(ids)
	for _, id := range ids {
		fmt.Fprintf(&b, "    [%d] = {\n", id)
		for _, o := range data.Art[id] {
			fmt.Fprintf(&b, "      { %d, %d, %d, %d", o.Width, o.Height, o.OffsetX, o.OffsetY)
			for _, tile := range o.Tiles {
				fmt.Fprintf(&b, ", %d", tile)
			}
			b.WriteString(" },\n")
		}
		b.WriteString("    },\n")
	}
	b.WriteString("  },\n}\n")
	_, err := io.WriteString(w, b.String())
	return err
}
