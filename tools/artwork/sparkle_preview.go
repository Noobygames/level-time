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
// und "bereit" auf drei spielähnliche Hintergründe (dunkles Gras, Schnee, Sand), ADD und BLEND wie im Spiel.
// Zum Prüfen von Lesbarkeit und Kontrast; die Schichtwerte spiegeln UI/LootSparkleStyles.lua und müssen bei
// neuen Stilen von Hand nachgezogen werden. Nur ein Hilfsmittel, nichts davon liegt im Addon.
const (
	previewCell  = 220
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
}

var previewBackgrounds = []struct {
	name string
	rgb  [3]float64
}{{"gras", [3]float64{0.16, 0.28, 0.14}}, {"schnee", [3]float64{0.92, 0.94, 0.97}}, {"sand", [3]float64{0.80, 0.68, 0.45}}}

var previewOre = [3]float64{1.00, 0.60, 0.18}

type previewStyle struct {
	name  string
	layer func(ready bool) []previewLayer
}

func previewStyles() []previewStyle {
	bracket, bracketGlow := renderSparkleBracket(sparkleTexSize), renderSparkleBracketGlow(sparkleTexSize)
	arrow, arrowGlow := renderSparkleArrow(sparkleTexSize), renderSparkleArrowGlow(sparkleTexSize)
	halo, flare := renderSparkleHalo(sparkleTexSize), renderSparkleFlare(sparkleTexSize)
	atlas := renderSparkleSymbols()
	black := [3]float64{0, 0, 0}
	shadow := previewLayer{tex: halo, w: 64, h: 24, dy: -10, tint: &black, a: 0.4}
	return []previewStyle{
		{"zielsucher", func(ready bool) []previewLayer {
			size := 84.0
			if ready {
				size = 56
			}
			return []previewLayer{shadow,
				{tex: bracketGlow, w: size, h: size, tint: &black, a: 0.4},
				{tex: bracketGlow, w: size, h: size, add: true, a: 0.6},
				{tex: bracket, w: size, h: size, whiten: 0.25, a: 1}}
		}},
		{"pfeil", func(ready bool) []previewLayer {
			return []previewLayer{shadow,
				{tex: arrowGlow, w: 28, h: 28, dy: 40, tint: &black, a: 0.4},
				{tex: arrowGlow, w: 28, h: 28, dy: 40, add: true, a: 0.6},
				{tex: arrow, w: 28, h: 28, dy: 40, whiten: 0.2, a: 1}}
		}},
		{"symbol", func(ready bool) []previewLayer {
			return []previewLayer{shadow,
				{tex: halo, w: 46, h: 46, dy: 43, tint: &black, a: 0.35},
				{tex: halo, w: 50, h: 50, dy: 43, add: true, a: 0.45},
				{tex: atlas, w: 34, h: 34, dy: 43, whiten: 0.2, a: 1, cu0: 0, cu1: 0.25, cv0: 0, cv1: 0.5}}
		}},
		{"glitzer", func(ready bool) []previewLayer {
			var out []previewLayer
			for i, p := range [][2]float64{{-22, 8}, {18, 14}, {-6, -10}, {26, -4}, {-28, -14}, {4, 24}} {
				s := 22.0 + float64(i%3)*6
				out = append(out, previewLayer{tex: flare, w: s, h: s, dx: p[0], dy: p[1], add: true, whiten: 0.35, a: 0.9})
			}
			return out
		}},
	}
}

func sampleAlpha(img *image.NRGBA, u, v float64) float64 {
	b := img.Bounds()
	x, y := u*float64(b.Dx())-0.5, v*float64(b.Dy())-0.5
	x0, y0 := int(math.Floor(x)), int(math.Floor(y))
	fx, fy := x-float64(x0), y-float64(y0)
	at := func(px, py int) float64 {
		if px < 0 || py < 0 || px >= b.Dx() || py >= b.Dy() {
			return 0
		}
		return float64(img.NRGBAAt(px, py).A) / 255
	}
	return at(x0, y0)*(1-fx)*(1-fy) + at(x0+1, y0)*fx*(1-fy) + at(x0, y0+1)*(1-fx)*fy + at(x0+1, y0+1)*fx*fy
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
			a := sampleAlpha(l.tex, u, v) * l.a * frameAlpha
			p := &buf[y*previewCell+x]
			for i := range p {
				if l.add {
					p[i] = math.Min(1, p[i]+c[i]*a)
				} else {
					p[i] = p[i]*(1-a) + c[i]*a
				}
			}
		}
	}
}

func runSparklePreview(path string) error {
	styles := previewStyles()
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
		fmt.Printf("Glitzer-Vorschau: %s (Zeilen: Stile je weit/bereit, Spalten: Gras/Schnee/Sand)\n", path)
		return png.Encode(f, sheet)
	})
}
