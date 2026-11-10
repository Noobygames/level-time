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
	// Körper tragen Licht und Schatten als Grauwert (R = G = B, nicht nur weiß); Umrisse, Gestrichelt weiß
	for _, img := range []*image.NRGBA{bracket, arrow, atlas} {
		var darkest, brightest uint8 = 255, 0
		for y := 0; y < img.Bounds().Dy(); y++ {
			for x := 0; x < img.Bounds().Dx(); x++ {
				p := img.NRGBAAt(x, y)
				if p.A == 0 {
					continue
				}
				if p.R != p.G || p.G != p.B {
					t.Fatalf("Pixel (%d,%d) nicht grau: %v", x, y, p)
				}
				if p.A == 255 && p.R < darkest {
					darkest = p.R
				}
				if p.A == 255 && p.R > brightest {
					brightest = p.R
				}
			}
		}
		if brightest-darkest < 40 {
			t.Errorf("Körper ohne Licht und Schatten (Grauwerte %d bis %d)", darkest, brightest)
		}
	}
	for _, img := range []*image.NRGBA{dashed, renderSparkleBracketOutline(size), renderSparkleArrowOutline(size),
		renderSparkleSymbolsOutline(), renderSparkleTrail(size), renderSparkleBadge(size), renderSparkleBracketCore(size)} {
		for y := 0; y < img.Bounds().Dy(); y++ {
			for x := 0; x < img.Bounds().Dx(); x++ {
				if p := img.NRGBAAt(x, y); p.A > 0 && (p.R != 255 || p.G != 255 || p.B != 255) {
					t.Fatalf("Pixel (%d,%d) nicht weiß: %v", x, y, p)
				}
			}
		}
	}
	// Umriss umschließt die Form (mindestens so viele Pixel, an der Formkante voll deckend)
	body, outline := bracket, renderSparkleBracketOutline(size)
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			if body.NRGBAAt(x, y).A == 255 && outline.NRGBAAt(x, y).A < 250 {
				t.Fatalf("SparkleBracketOutline: Pixel (%d,%d) unter der Form nicht deckend", x, y)
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
		shapeN = int(float64(shapeN) * glowShapeScale * glowShapeScale) // Glow-Form liegt verkleinert auf der Textur
		for i := 0; i < size; i++ {
			for _, p := range [][2]int{{i, 0}, {i, size - 1}, {0, i}, {size - 1, i}} {
				if a := glow.NRGBAAt(p[0], p[1]).A; a != 0 {
					t.Fatalf("%s: Leuchtrand schneidet am Texturrand ab (Alpha %d bei %v)", name, a, p)
				}
			}
		}
		glowN, glowPeak := count(glow)
		if glowN <= shapeN {
			t.Errorf("%s: Leuchthülle (%d Pixel) sollte breiter sein als die Form (%d)", name, glowN, shapeN)
		}
		if glowPeak < 250 {
			t.Errorf("%s: Leuchthülle nicht normalisiert (Höchstwert %d)", name, glowPeak)
		}
	}
}

// Bodenstile (Roadmap 467, 468, 476): Atlanten mit 16 gefüllten Zellen, Leuchtränder enden vor dem Rand bei 0,
// Körper tragen Licht und Schatten, Lichtsäule ist unten hell und oben leer
func TestSparkleGroundTextures(t *testing.T) {
	cellFilled := func(img *image.NRGBA, i int) int {
		n := 0
		x0, y0 := (i%atlasCols)*sparkleTexSize, (i/atlasCols)*sparkleTexSize
		for y := 0; y < sparkleTexSize; y++ {
			for x := 0; x < sparkleTexSize; x++ {
				if img.NRGBAAt(x0+x, y0+y).A > 0 {
					n++
				}
			}
		}
		return n
	}
	for name, atlas := range map[string]*image.NRGBA{"hands": renderSparkleClockHands(), "segments": renderSparkleSegments()} {
		if atlas.Bounds().Dx() != atlasSize || atlas.Bounds().Dy() != atlasSize {
			t.Fatalf("%s: Maße %v", name, atlas.Bounds())
		}
		for i := 0; i < atlasCells; i++ {
			if n := cellFilled(atlas, i); n < 150 {
				t.Errorf("%s: Zelle %d fast leer (%d Pixel)", name, i, n)
			}
		}
	}
	// Segment 1 liegt rechts oben von 12 Uhr, Segment 9 links unten
	seg := renderSparkleSegments()
	if seg.NRGBAAt(sparkleTexSize/2+12, 20).A == 0 {
		t.Errorf("Segment 1 sollte rechts von 12 Uhr liegen")
	}
	if seg.NRGBAAt(sparkleTexSize/2-12, 20).A != 0 {
		t.Errorf("Segment 1 sollte links von 12 Uhr leer sein")
	}
	// Zeiger Zelle 1 zeigt nach oben, Zelle 5 (90 Grad) nach rechts
	hands := renderSparkleClockHands()
	if hands.NRGBAAt(sparkleTexSize/2, 30).A == 0 {
		t.Errorf("Zeiger 1 sollte nach oben zeigen")
	}
	if hands.NRGBAAt(sparkleTexSize/2, sparkleTexSize-8).A != 0 {
		t.Errorf("Zeiger 1: unterer Rand sollte leer sein")
	}
	// Zelle 5 (Zeile 2, Spalte 1, 90 Grad) zeigt nach rechts
	if hands.NRGBAAt(sparkleTexSize/2+40, sparkleTexSize+sparkleTexSize/2).A == 0 {
		t.Errorf("Zeiger 5 sollte nach rechts zeigen")
	}
	for name, glow := range map[string]*image.NRGBA{"clock": renderSparkleClockGlow(sparkleTexSize), "progress": renderSparkleProgressGlow(sparkleTexSize)} {
		for i := 0; i < sparkleTexSize; i++ {
			for _, p := range [][2]int{{i, 0}, {i, sparkleTexSize - 1}, {0, i}, {sparkleTexSize - 1, i}} {
				if a := glow.NRGBAAt(p[0], p[1]).A; a != 0 {
					t.Fatalf("%s: Leuchtrand schneidet am Rand ab (Alpha %d bei %v)", name, a, p)
				}
			}
		}
	}
	face := renderSparkleClockFace(sparkleTexSize)
	var darkest, brightest uint8 = 255, 0
	for y := 0; y < sparkleTexSize; y++ {
		for x := 0; x < sparkleTexSize; x++ {
			if p := face.NRGBAAt(x, y); p.A == 255 {
				darkest, brightest = min(darkest, p.R), max(brightest, p.R)
			}
		}
	}
	if brightest-darkest < 25 {
		t.Errorf("Zifferblatt ohne Licht und Schatten (%d bis %d)", darkest, brightest)
	}
	// Lichtsäule: hochkant 1:4, unten hell, oberste Zeile leer, seitlich leer; Kern schmaler als Körper
	for name, col := range map[string]*image.NRGBA{"body": renderSparkleColumnBody(), "core": renderSparkleColumnCore(), "shade": renderSparkleColumnShade()} {
		if col.Bounds().Dx() != columnWidth || col.Bounds().Dy() != columnHeight {
			t.Fatalf("Säule %s: Maße %v", name, col.Bounds())
		}
		if col.NRGBAAt(columnWidth/2, 0).A != 0 || col.NRGBAAt(0, columnHeight*3/4).A != 0 || col.NRGBAAt(columnWidth-1, columnHeight*3/4).A != 0 {
			t.Errorf("Säule %s: Oberkante und Seiten sollten leer sein", name)
		}
		if col.NRGBAAt(columnWidth/2, columnHeight*7/8).A < 150 {
			t.Errorf("Säule %s: Fuß sollte hell sein", name)
		}
		if col.NRGBAAt(columnWidth/2, columnHeight/8).A >= col.NRGBAAt(columnWidth/2, columnHeight*7/8).A {
			t.Errorf("Säule %s: oben sollte dunkler sein als unten", name)
		}
	}
	body, core := renderSparkleColumnBody(), renderSparkleColumnCore()
	if core.NRGBAAt(columnWidth/2+14, columnHeight*7/8).A >= body.NRGBAAt(columnWidth/2+14, columnHeight*7/8).A {
		t.Errorf("Säulenkern sollte schmaler sein als der Körper")
	}
	// Lichtring: Mitte leer, vordere (untere) Hälfte heller als die hintere
	ring := renderSparkleLightRing(sparkleTexSize)
	if ring.NRGBAAt(sparkleTexSize/2, sparkleTexSize/2).A != 0 {
		t.Errorf("Lichtring: Mitte sollte leer sein")
	}
	if ring.NRGBAAt(sparkleTexSize/2, sparkleTexSize/2+45).A <= ring.NRGBAAt(sparkleTexSize/2, sparkleTexSize/2-45).A {
		t.Errorf("Lichtring: vorn sollte heller sein als hinten")
	}
}
