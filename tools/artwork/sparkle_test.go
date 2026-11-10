package main

import (
	"bytes"
	"encoding/binary"
	"image"
	"testing"
)

func TestSparkleTextures(t *testing.T) {
	textures := []struct {
		name         string
		render       func(int) *image.NRGBA
		activePoints [][2]int
	}{
		{
			name:   "SparkleHalo",
			render: renderSparkleHalo,
			activePoints: [][2]int{
				{64, 64}, // Center
				{64, 40}, // Inner glow
			},
		},
		{
			name:   "SparkleRing",
			render: renderSparkleRing,
			activePoints: [][2]int{
				// r0 = 0.72 -> x = 64 + 0.72*64 = 110, y = 64
				{110, 64},
				{18, 64},
				{64, 110},
				{64, 18},
			},
		},
		{
			name:   "SparkleArcs",
			render: renderSparkleArcs,
			activePoints: [][2]int{
				// Radius r0 = 0.74, arc from ~10° to 120°:
				// At angle ~35°: u = 0.74 * cos(35°) = 0.606, v = 0.74 * sin(35°) = 0.424
				// x = 64 + 0.606*64 = 103, y = 64 + 0.424*64 = 91
				{103, 91},
			},
		},
		{
			name:   "SparkleFlare",
			render: renderSparkleFlare,
			activePoints: [][2]int{
				{64, 64}, // Center core
				{90, 64}, // Horizontal ray
				{64, 90}, // Vertical ray
			},
		},
		{
			name:   "SparkleBeam",
			render: renderSparkleBeam,
			activePoints: [][2]int{
				{64, 114}, // Centered horizontally, bright near bottom (ny = 0.78)
				{64, 80},  // Pillar body
			},
		},
		{
			name:   "SparkleSigil",
			render: renderSparkleSigil,
			activePoints: [][2]int{
				{114, 64}, // Outer ring (0.78)
				{97, 64},  // Inner ring (0.52)
			},
		},
	}

	corners := [][2]int{
		{0, 0},
		{sparkleTexSize - 1, 0},
		{0, sparkleTexSize - 1},
		{sparkleTexSize - 1, sparkleTexSize - 1},
	}

	for _, tc := range textures {
		t.Run(tc.name, func(t *testing.T) {
			img := tc.render(sparkleTexSize)

			// 1. Dimensions and power-of-two check
			w := img.Bounds().Dx()
			h := img.Bounds().Dy()
			if w != sparkleTexSize || h != sparkleTexSize {
				t.Fatalf("%s: falsche Dimensionen %dx%d (erwartet %dx%d)", tc.name, w, h, sparkleTexSize, sparkleTexSize)
			}
			if (w&(w-1)) != 0 || (h&(h-1)) != 0 {
				t.Fatalf("%s: keine Zweierpotenz (%dx%d)", tc.name, w, h)
			}

			// 2. Transparent corners
			for _, c := range corners {
				if a := img.NRGBAAt(c[0], c[1]).A; a != 0 {
					t.Errorf("%s: Ecke (%d,%d) nicht transparent (Alpha = %d)", tc.name, c[0], c[1], a)
				}
			}

			// 3. White RGB and active pixel statistics
			var maxAlpha uint8
			var activeCount int
			for y := 0; y < h; y++ {
				for x := 0; x < w; x++ {
					p := img.NRGBAAt(x, y)
					if p.A > 0 {
						activeCount++
						if p.R != 255 || p.G != 255 || p.B != 255 {
							t.Errorf("%s: Pixel (%d,%d) nicht weiß: RGB=(%d,%d,%d)", tc.name, x, y, p.R, p.G, p.B)
						}
					}
					if p.A > maxAlpha {
						maxAlpha = p.A
					}
				}
			}

			if activeCount == 0 {
				t.Errorf("%s: Keine aktiven Pixel gefunden!", tc.name)
			}
			if maxAlpha < 200 {
				t.Errorf("%s: Maximale Deckkraft zu gering (%d < 200)", tc.name, maxAlpha)
			}

			// 4. Sample active points
			for _, pt := range tc.activePoints {
				if a := img.NRGBAAt(pt[0], pt[1]).A; a == 0 {
					t.Errorf("%s: Aktiver Punkt (%d,%d) ist transparent (Alpha = 0)", tc.name, pt[0], pt[1])
				}
			}

			// 5. Clean TGA encoding
			var buf bytes.Buffer
			if err := writeTGA(&buf, img); err != nil {
				t.Fatalf("%s: writeTGA Fehler: %v", tc.name, err)
			}
			data := buf.Bytes()
			wantLen := 18 + sparkleTexSize*sparkleTexSize*4
			if len(data) != wantLen {
				t.Fatalf("%s: TGA Dateigröße %d != %d", tc.name, len(data), wantLen)
			}
			if data[2] != 2 || data[16] != 32 || data[17] != 0x08 {
				t.Errorf("%s: Unerwarteter TGA Header: %v", tc.name, data[:18])
			}
			headerW := binary.LittleEndian.Uint16(data[12:14])
			headerH := binary.LittleEndian.Uint16(data[14:16])
			if headerW != sparkleTexSize || headerH != sparkleTexSize {
				t.Errorf("%s: TGA Header-Maße %dx%d != %dx%d", tc.name, headerW, headerH, sparkleTexSize, sparkleTexSize)
			}
		})
	}
}

func TestSparkleSpecifics(t *testing.T) {
	// Ring center should be transparent
	ring := renderSparkleRing(sparkleTexSize)
	if a := ring.NRGBAAt(sparkleTexSize/2, sparkleTexSize/2).A; a != 0 {
		t.Errorf("SparkleRing: Mitte sollte transparent sein, Alpha = %d", a)
	}

	// Halo center should be fully bright
	halo := renderSparkleHalo(sparkleTexSize)
	if a := halo.NRGBAAt(sparkleTexSize/2, sparkleTexSize/2).A; a < 240 {
		t.Errorf("SparkleHalo: Mitte sollte hell sein, Alpha = %d", a)
	}

	// Beam: bright near bottom (y around 114), dark at top (y = 0)
	beam := renderSparkleBeam(sparkleTexSize)
	topA := beam.NRGBAAt(sparkleTexSize/2, 0).A
	botA := beam.NRGBAAt(sparkleTexSize/2, 114).A
	if topA != 0 {
		t.Errorf("SparkleBeam: Oberkante sollte transparent sein, Alpha = %d", topA)
	}
	if botA < 200 {
		t.Errorf("SparkleBeam: Fußpunkt sollte hell sein, Alpha = %d", botA)
	}

	// Arcs: two opposite arcs, center transparent
	arcs := renderSparkleArcs(sparkleTexSize)
	if a := arcs.NRGBAAt(sparkleTexSize/2, sparkleTexSize/2).A; a != 0 {
		t.Errorf("SparkleArcs: Mitte sollte transparent sein, Alpha = %d", a)
	}
}

// Formtexturen der eigenen Stile (Roadmap 466, 471, 475): weiße RGB-Farbe, Form im Alphakanal, Maße als Zweierpotenz
func TestSparkleShapes(t *testing.T) {
	size := sparkleTexSize
	bracket := renderSparkleBracket(size)
	if a := bracket.NRGBAAt(size/2, size/2).A; a != 0 {
		t.Errorf("SparkleBracket: Mitte sollte leer sein, Alpha = %d", a)
	}
	// Ecke (links oben) liegt auf der Klammer, Kantenmitte nicht
	if a := bracket.NRGBAAt(8, 8).A; a == 0 {
		t.Errorf("SparkleBracket: Ecke sollte gefüllt sein")
	}
	if a := bracket.NRGBAAt(size/2, 8).A; a != 0 {
		t.Errorf("SparkleBracket: Kantenmitte sollte offen sein, Alpha = %d", a)
	}
	dashed := renderSparkleBracketDashed(size)
	if a := dashed.NRGBAAt(size/2, size/2).A; a != 0 {
		t.Errorf("SparkleBracketDashed: Mitte sollte leer sein, Alpha = %d", a)
	}
	var onEdge, offEdge int
	for x := 0; x < size; x++ {
		if dashed.NRGBAAt(x, 8).A > 0 {
			onEdge++
		} else {
			offEdge++
		}
	}
	if onEdge == 0 || offEdge == 0 {
		t.Errorf("SparkleBracketDashed: Kante sollte Striche und Lücken haben (%d/%d)", onEdge, offEdge)
	}
	arrow := renderSparkleArrow(size)
	if arrow.NRGBAAt(size/2, size/4).A == 0 || arrow.NRGBAAt(size/2, size*3/4).A == 0 {
		t.Errorf("SparkleArrow: Schaft und Spitze sollten gefüllt sein")
	}
	if arrow.NRGBAAt(4, size-4).A != 0 {
		t.Errorf("SparkleArrow: untere Ecke sollte leer sein")
	}

	atlas := renderSparkleSymbols()
	if atlas.Bounds().Dx() != symbolAtlasW || atlas.Bounds().Dy() != symbolAtlasH {
		t.Fatalf("SparkleSymbols: Maße %v", atlas.Bounds())
	}
	for i := range symbolShapes {
		x0 := (i % symbolAtlasCols) * symbolCellSize
		y0 := (i / symbolAtlasCols) * symbolCellSize
		filled := 0
		for y := 0; y < symbolCellSize; y++ {
			for x := 0; x < symbolCellSize; x++ {
				if atlas.NRGBAAt(x0+x, y0+y).A > 0 {
					filled++
				}
			}
		}
		if filled < symbolCellSize*symbolCellSize/20 {
			t.Errorf("SparkleSymbols: Symbol %d fast leer (%d Pixel)", i+1, filled)
		}
	}
	for _, img := range []*image.NRGBA{bracket, dashed, arrow, atlas} {
		for y := 0; y < img.Bounds().Dy(); y++ {
			for x := 0; x < img.Bounds().Dx(); x++ {
				if p := img.NRGBAAt(x, y); p.A > 0 && (p.R != 255 || p.G != 255 || p.B != 255) {
					t.Fatalf("Pixel (%d,%d) nicht weiß: %v", x, y, p)
				}
			}
		}
	}
}

// Leuchthüllen: weich (Kantenpixel der Form nicht hart), breiter als die Form, Höchstwert 1
func TestSparkleGlows(t *testing.T) {
	size := sparkleTexSize
	for name, pair := range map[string][2]*image.NRGBA{
		"bracket": {renderSparkleBracket(size), renderSparkleBracketGlow(size)},
		"arrow":   {renderSparkleArrow(size), renderSparkleArrowGlow(size)},
	} {
		shape, glow := pair[0], pair[1]
		count := func(img *image.NRGBA) (n int, peak uint8) {
			for y := 0; y < size; y++ {
				for x := 0; x < size; x++ {
					a := img.NRGBAAt(x, y).A
					if a > 0 {
						n++
					}
					if a > peak {
						peak = a
					}
				}
			}
			return
		}
		shapeN, _ := count(shape)
		glowN, glowPeak := count(glow)
		if glowN <= shapeN {
			t.Errorf("%s: Leuchthülle (%d Pixel) sollte breiter sein als die Form (%d)", name, glowN, shapeN)
		}
		if glowPeak < 250 {
			t.Errorf("%s: Leuchthülle nicht normalisiert (Höchstwert %d)", name, glowPeak)
		}
	}
}
