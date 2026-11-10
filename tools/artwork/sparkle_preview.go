package main

import (
	"fmt"
	"image"
	"image/color"
	"image/png"
	"math"
	"os"
)

// Kontaktbogen der Glitzer-Stile (`-sparkle-preview Datei.png`): setzt die Texturen jedes eigenen Stils in "weit"
// und "bereit" auf vier spielähnliche Hintergründe (dunkles Gras, Schnee, Sand, Höhle bei Nacht), ADD und BLEND
// wie im Spiel. Zum Prüfen von Lesbarkeit, Kontrast und Leuchten; die Schichtwerte spiegeln
// UI/LootSparkleStyles.lua und müssen bei neuen Stilen von Hand nachgezogen werden. Nur ein Hilfsmittel.
const (
	previewCell  = 340
	previewScale = 2.0
)

type previewLayer struct {
	tex       *image.NRGBA
	w, h      float64 // Größe in Spielpixeln
	dx, dy    float64 // Mitte relativ zum Objekt (dy nach oben)
	add       bool    // ADD statt BLEND
	tint      *[3]float64
	whiten, a float64
	cu0, cu1  float64 // Ausschnitt im Atlas (Anteil von 0 bis 1), 0/0 = ganze Textur
	cv0, cv1  float64
	readyOnly bool
}

var previewBackgrounds = []struct {
	name string
	rgb  [3]float64
}{
	{"gras", [3]float64{0.16, 0.28, 0.14}}, {"schnee", [3]float64{0.92, 0.94, 0.97}},
	{"sand", [3]float64{0.80, 0.68, 0.45}}, {"hoehle", [3]float64{0.05, 0.05, 0.08}},
}

var previewOre = [3]float64{1.00, 0.60, 0.18}

type previewStyle struct {
	name  string
	layer func(ready bool) []previewLayer
}

func previewStyles() []previewStyle {
	black := [3]float64{0, 0, 0}
	halo, ring := renderSparkleHalo(sparkleTexSize), renderSparkleRing(sparkleTexSize)
	flare, glint := renderSparkleFlare(sparkleTexSize), renderGlint(glintSize)
	bracket, bracketOutline := renderSparkleBracket(sparkleTexSize), renderSparkleBracketOutline(sparkleTexSize)
	bracketGlow, bracketCore := renderSparkleBracketGlow(sparkleTexSize), renderSparkleBracketCore(sparkleTexSize)
	arrow, arrowOutline := renderSparkleArrow(sparkleTexSize), renderSparkleArrowOutline(sparkleTexSize)
	arrowGlow := renderSparkleArrowGlow(sparkleTexSize)
	trail, badge := renderSparkleTrail(sparkleTexSize), renderSparkleBadge(sparkleTexSize)
	atlas, atlasOutline := renderSparkleSymbols(), renderSparkleSymbolsOutline()
	clockFace, clockOutline, clockGlow := renderSparkleClockFace(sparkleTexSize), renderSparkleClockOutline(sparkleTexSize), renderSparkleClockGlow(sparkleTexSize)
	hands, segments := renderSparkleClockHands(), renderSparkleSegments()
	progressTrack, progressGlow := renderSparkleProgressTrack(sparkleTexSize), renderSparkleProgressGlow(sparkleTexSize)
	column, columnCore, columnShade := renderSparkleColumnBody(), renderSparkleColumnCore(), renderSparkleColumnShade()
	lightRing := renderSparkleLightRing(sparkleTexSize)
	shadow := previewLayer{tex: halo, w: 72, h: 26, dy: -24, tint: &black, a: 0.55}
	groundRing := previewLayer{tex: ring, w: 76, h: 28, dy: -24, add: true, whiten: 0.3, a: 0.45}
	groundGlow := previewLayer{tex: halo, w: 60, h: 22, dy: -20, add: true, whiten: 0.2, a: 0.4}
	styles := []previewStyle{
		{"zielsucher", func(ready bool) []previewLayer {
			size := 84.0
			if ready {
				size = 56
			}
			return []previewLayer{shadow, groundRing,
				{tex: bracketOutline, w: size, h: size, tint: &black, a: 0.9},
				{tex: bracketGlow, w: size / glowShapeScale, h: size / glowShapeScale, add: true, a: 0.35},
				{tex: halo, w: 110, h: 110, add: true, a: 0.18, readyOnly: true},
				{tex: bracket, w: size, h: size, whiten: 0.2, a: 1},
				{tex: bracketCore, w: size, h: size, add: true, whiten: 0.75, a: 0.6}}
		}},
		{"pfeil", func(ready bool) []previewLayer {
			return []previewLayer{shadow, groundGlow,
				{tex: trail, w: 20, h: 56, dy: 85, add: true, whiten: 0.3, a: 0.85},
				{tex: arrowOutline, w: 44, h: 44, dy: 44, tint: &black, a: 0.9},
				{tex: arrowGlow, w: 44 / glowShapeScale, h: 44 / glowShapeScale, dy: 44, add: true, a: 0.8},
				{tex: arrow, w: 44, h: 44, dy: 44, whiten: 0.15, a: 1}}
		}},
		{"symbol", func(ready bool) []previewLayer {
			cell := func(l previewLayer) previewLayer { l.cu0, l.cu1, l.cv0, l.cv1 = 0, 0.25, 0, 0.5; return l }
			return []previewLayer{shadow, groundGlow,
				{tex: badge, w: 60, h: 60, dy: 47, tint: &black, a: 0.5},
				{tex: halo, w: 66, h: 66, dy: 47, add: true, a: 0.45},
				cell(previewLayer{tex: atlasOutline, w: 54, h: 54, dy: 47, tint: &black, a: 0.9}),
				cell(previewLayer{tex: atlas, w: 50, h: 50, dy: 47, whiten: 0.3, a: 1})}
		}},
		{"uhrwerk", func(ready bool) []previewLayer {
			cell := func(l previewLayer, i int) previewLayer {
				l.cu0, l.cu1 = float64(i%atlasCols)/atlasCols, float64(i%atlasCols+1)/atlasCols
				l.cv0, l.cv1 = float64(i/atlasCols)/atlasRows, float64(i/atlasCols+1)/atlasRows
				return l
			}
			out := []previewLayer{shadow,
				{tex: clockOutline, w: 100, h: 40, dy: -24, tint: &black, a: 0.9},
				{tex: clockGlow, w: 200, h: 80, dy: -24, add: true, a: 0.35},
				{tex: clockFace, w: 100, h: 40, dy: -24, whiten: 0.2, a: 1}}
			if ready {
				return append(out, cell(previewLayer{tex: hands, w: 100, h: 40, dy: -24, whiten: 0.5, a: 1}, 0))
			}
			return append(out, cell(previewLayer{tex: hands, w: 100, h: 40, dy: -24, whiten: 0.3, a: 0.55}, 5),
				cell(previewLayer{tex: hands, w: 100, h: 40, dy: -24, whiten: 0.3, a: 0.45}, 6))
		}},
		{"fortschritt", func(ready bool) []previewLayer {
			cell := func(i int) previewLayer {
				return previewLayer{tex: segments, w: 100, h: 40, dy: -24, whiten: 0.15, a: 1,
					cu0: float64(i%atlasCols) / atlasCols, cu1: float64(i%atlasCols+1) / atlasCols,
					cv0: float64(i/atlasCols) / atlasRows, cv1: float64(i/atlasCols+1) / atlasRows}
			}
			out := []previewLayer{shadow, {tex: progressTrack, w: 100, h: 40, dy: -24, tint: &black, a: 0.85}}
			lit := 9
			if ready {
				lit = atlasCells
				out = append(out, previewLayer{tex: progressGlow, w: 200, h: 80, dy: -24, add: true, a: 0.5})
			}
			for i := 0; i < lit; i++ {
				out = append(out, cell(i))
			}
			return out
		}},
		{"lichtsaeule", func(ready bool) []previewLayer {
			out := []previewLayer{shadow,
				{tex: columnShade, w: 66, h: 132, dy: 42, tint: &black, a: 0.4},
				groundRing, {tex: halo, w: 70, h: 26, dy: -24, add: true, whiten: 0.2, a: 0.6},
				{tex: column, w: 64, h: 128, dy: 40, add: true, a: 0.55},
				{tex: columnCore, w: 40, h: 124, dy: 38, add: true, whiten: 0.6, a: 0.8}}
			if ready {
				out = append(out, previewLayer{tex: column, w: 90, h: 140, dy: 46, add: true, a: 0.5},
					previewLayer{tex: halo, w: 100, h: 38, dy: -24, add: true, whiten: 0.5, a: 0.7})
			}
			// drei Ringe in verschiedenen Höhen: unten kräftig, oben ausblendend
			for _, r := range []struct{ h, w, a float64 }{{8, 56, 0.9}, {46, 50, 0.7}, {88, 44, 0.35}} {
				out = append(out, previewLayer{tex: lightRing, w: r.w, h: r.w * 0.4, dy: -24 + r.h, add: true, whiten: 0.3, a: r.a})
			}
			for _, m := range [][3]float64{{-10, 30, 12}, {12, 62, 10}, {-4, 96, 8}, {8, 110, 6}} {
				out = append(out, previewLayer{tex: flare, w: m[2], h: m[2], dx: m[0], dy: -24 + m[1], add: true, whiten: 0.5, a: 0.9})
			}
			return out
		}},
		{"glitzer", func(ready bool) []previewLayer {
			out := []previewLayer{shadow, groundRing}
			for i, p := range [][2]float64{{-26, 14}, {20, 22}, {-8, -2}, {30, 4}, {-32, -6}, {4, 34}} {
				s := 24.0 + float64(i%3)*7
				out = append(out,
					previewLayer{tex: flare, w: s * 1.15, h: s * 1.15, dx: p[0], dy: p[1], tint: &black, a: 0.35},
					previewLayer{tex: flare, w: s, h: s, dx: p[0], dy: p[1], add: true, whiten: 0.1, a: 0.95},
					previewLayer{tex: glint, w: s * 0.5, h: s * 0.5, dx: p[0], dy: p[1], add: true, whiten: 1, a: 0.9})
			}
			return out
		}},
	}
	return append(styles, scenePreviewStyles()...)
}

// sampleTexture liefert Grauwert und Deckkraft der Textur an (u, v), bilinear
func sampleTexture(img *image.NRGBA, u, v float64) (grey, alpha float64) {
	b := img.Bounds()
	x, y := u*float64(b.Dx())-0.5, v*float64(b.Dy())-0.5
	x0, y0 := int(math.Floor(x)), int(math.Floor(y))
	fx, fy := x-float64(x0), y-float64(y0)
	at := func(px, py int, w float64) {
		if px < 0 || py < 0 || px >= b.Dx() || py >= b.Dy() {
			return
		}
		p := img.NRGBAAt(px, py)
		a := float64(p.A) / 255
		alpha += a * w
		grey += float64(p.R) / 255 * a * w
	}
	at(x0, y0, (1-fx)*(1-fy))
	at(x0+1, y0, fx*(1-fy))
	at(x0, y0+1, (1-fx)*fy)
	at(x0+1, y0+1, fx*fy)
	if alpha > 0 {
		grey /= alpha
	}
	return grey, alpha
}

func drawPreviewLayer(buf [][3]float64, l previewLayer, frameAlpha float64) {
	c := previewOre
	if l.tint != nil {
		c = *l.tint
	}
	for i := range c {
		c[i] += (1 - c[i]) * l.whiten
	}
	cx := float64(previewCell) / 2
	cy := float64(previewCell) * 0.62
	w, h := l.w*previewScale, l.h*previewScale
	left, top := cx+l.dx*previewScale-w/2, cy-l.dy*previewScale-h/2
	cu0, cu1, cv0, cv1 := l.cu0, l.cu1, l.cv0, l.cv1
	if cu1 == 0 {
		cu1, cv1 = 1, 1
	}
	for y := int(math.Max(0, top)); y < int(math.Min(previewCell, top+h)); y++ {
		for x := int(math.Max(0, left)); x < int(math.Min(previewCell, left+w)); x++ {
			u := cu0 + (float64(x)+0.5-left)/w*(cu1-cu0)
			v := cv0 + (float64(y)+0.5-top)/h*(cv1-cv0)
			grey, alpha := sampleTexture(l.tex, u, v)
			a := alpha * l.a * frameAlpha
			p := &buf[y*previewCell+x]
			for i := range p {
				col := c[i] * grey
				if l.add {
					p[i] = math.Min(1, p[i]+col*a)
				} else {
					p[i] = p[i]*(1-a) + col*a
				}
			}
		}
	}
}

func runSparklePreview(path string) error {
	styles := filterPreviewStyles(previewStyles(), os.Getenv("SPARKLE_PREVIEW_STYLES"))
	states := []struct {
		name  string
		ready bool
		alpha float64
	}{{"weit", false, 0.5}, {"bereit", true, 1}}
	cols := len(previewBackgrounds)
	rows := len(styles) * len(states)
	sheet := image.NewNRGBA(image.Rect(0, 0, cols*previewCell, rows*previewCell))
	for si, style := range styles {
		for sti, state := range states {
			for bi, bg := range previewBackgrounds {
				buf := make([][3]float64, previewCell*previewCell)
				for y := 0; y < previewCell; y++ {
					for x := 0; x < previewCell; x++ {
						// leichte Maserung, damit der Hintergrund nicht wie eine Fläche wirkt
						n := 0.04 * math.Sin(float64(x)*0.9+float64(y)*0.31) * math.Sin(float64(y)*0.7)
						buf[y*previewCell+x] = [3]float64{bg.rgb[0] + n, bg.rgb[1] + n, bg.rgb[2] + n}
					}
				}
				for _, l := range style.layer(state.ready) {
					if l.readyOnly && !state.ready {
						continue
					}
					drawPreviewLayer(buf, l, state.alpha)
				}
				x0, y0 := bi*previewCell, (si*len(states)+sti)*previewCell
				for y := 0; y < previewCell; y++ {
					for x := 0; x < previewCell; x++ {
						p := buf[y*previewCell+x]
						to8 := func(f float64) uint8 { return uint8(math.Max(0, math.Min(1, f)) * 255) }
						sheet.SetNRGBA(x0+x, y0+y, color.NRGBA{to8(p[0]), to8(p[1]), to8(p[2]), 255})
					}
				}
			}
		}
	}
	return writeFile(path, func(f *os.File) error {
		fmt.Printf("Glitzer-Vorschau: %s (Zeilen: Stile je weit/bereit, Spalten: Gras/Schnee/Sand/Höhle)\n", path)
		return png.Encode(f, sheet)
	})
}
