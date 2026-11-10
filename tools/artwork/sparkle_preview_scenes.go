package main

import (
	"math"
	"strings"
)

// Kontaktbogen-Spiegel der Szenen-Stile (Roadmap 469, 470, 472, 473); die Werte folgen UI/LootSparkleStyles.lua und
// zeigen einen typischen Moment der Animation (Tiere mitten im Flug, halb gemalte Karte, Pixel im Sprung ...).

func atlasCell(l previewLayer, i int) previewLayer {
	l.cu0, l.cu1 = float64(i%atlasCols)/atlasCols, float64(i%atlasCols+1)/atlasCols
	l.cv0, l.cv1 = float64(i/atlasCols)/atlasRows, float64(i/atlasCols+1)/atlasRows
	return l
}

func scenePreviewStyles() []previewStyle {
	black := [3]float64{0, 0, 0}
	halo, flare := renderSparkleHalo(sparkleTexSize), renderSparkleFlare(sparkleTexSize)
	firefly := renderSparkleFirefly(sparkleTexSize)
	mapInk, mapGlow := renderSparkleMapInk(), renderSparkleMapGlow(sparkleTexSize)
	block, ringA, ringB := renderSparkleBlock(), renderSparkleBlockRing(sparkleTexSize, 0), renderSparkleBlockRing(sparkleTexSize, 1)
	star, sky := renderSparkleStar(), renderSparkleConstellation()
	shadow := previewLayer{tex: halo, w: 72, h: 26, dy: -24, tint: &black, a: 0.55}
	return []previewStyle{
		{"gluehwuermchen", func(ready bool) []previewLayer {
			out := []previewLayer{shadow}
			far := [][3]float64{{-30, 22, 1}, {22, 36, 0.7}, {-14, 58, 0.9}, {26, 6, 0.5}}
			home := [][3]float64{{-22, 34, 1}, {20, 46, 1}, {-6, 14, 1}, {24, 20, 1}}
			if ready {
				out = append(out, previewLayer{tex: halo, w: 96, h: 96, dy: 28, add: true, whiten: 0.2, a: 0.1})
			}
			for i, f := range far {
				if ready {
					f = home[i]
					out = append(out, previewLayer{tex: halo, w: 54, h: 54, dx: f[0], dy: f[1], tint: &black, a: 0.6},
						previewLayer{tex: firefly, w: 42, h: 42, dx: f[0], dy: f[1], add: true, whiten: 0.25, a: 0.5},
						previewLayer{tex: firefly, w: 20, h: 20, dx: f[0], dy: f[1], add: true, whiten: 0.9, a: 1})
					continue
				}
				out = append(out, previewLayer{tex: halo, w: 30, h: 30, dx: f[0], dy: f[1], tint: &black, a: 0.45 * f[2]},
					previewLayer{tex: firefly, w: 40, h: 40, dx: f[0], dy: f[1], add: true, whiten: 0.1, a: 0.9 * f[2]},
					previewLayer{tex: firefly, w: 18, h: 18, dx: f[0], dy: f[1], add: true, whiten: 0.85, a: f[2]})
			}
			return out
		}},
		{"schatzkarte", func(ready bool) []previewLayer {
			out := []previewLayer{{tex: halo, w: 110, h: 42, dy: -24, tint: &black, a: 0.3}}
			cells := 8 // weit: X und Pfad gemalt
			if ready {
				cells = atlasCells
				out = append(out, previewLayer{tex: mapGlow, w: 300, h: 120, dy: -24, add: true, a: 0.45})
			}
			for i := 0; i < cells; i++ {
				out = append(out, atlasCell(previewLayer{tex: mapInk, w: 150, h: 60, dy: -24, whiten: 0.1, a: 1}, i))
			}
			return out
		}},
		{"pixel-pop", func(ready bool) []previewLayer {
			out := []previewLayer{shadow}
			ringAlpha := 0.9
			out = append(out, previewLayer{tex: ringA, w: 100, h: 40, dy: -24, whiten: 0.2, a: ringAlpha})
			if ready {
				out = append(out, previewLayer{tex: ringB, w: 100, h: 40, dy: -24, whiten: 0.2, a: 1},
					previewLayer{tex: halo, w: 84, h: 84, dy: 46, add: true, whiten: 0.2, a: 0.3},
					previewLayer{tex: star, w: 60, h: 60, dy: 46, whiten: 0.25, a: 1})
				for i := 1; i <= 10; i++ {
					angle, dist := (36*float64(i)+10)*math.Pi/180, 32+float64(i%3)*8
					s := 14 + float64(i%2)*4
					out = append(out, previewLayer{tex: block, w: s, h: s, dx: math.Sin(angle) * dist * 0.8, dy: 24 + math.Cos(angle)*dist*0.8,
						whiten: float64(i%4) * 0.2, a: 1})
				}
			}
			pixels := [][5]float64{{-34, -6, 16, 28, 0}, {28, -8, 13, 36, 0.35}, {-14, 6, 18, 32, 0.6}, {38, 14, 14, 26, 0.15},
				{-40, 20, 12, 34, 0.45}, {8, -2, 16, 38, 0}, {20, 24, 13, 24, 0.6}, {-24, -10, 15, 30, 0.3}}
			for i, p := range pixels {
				lift := p[3] * (0.9 - 0.25*float64(i%3))
				out = append(out, previewLayer{tex: block, w: p[2], h: p[2], dx: p[0], dy: p[1] + lift, whiten: p[4], a: 1})
			}
			return out
		}},
		{"sternbild", func(ready bool) []previewLayer {
			out := []previewLayer{shadow}
			stars := [][2]float64{{-38, 8}, {-26, 44}, {-2, 28}, {22, 58}, {40, 22}}
			sizes := []float64{26, 22, 30, 24, 28}
			lines, shown := 4, 5
			if !ready {
				lines, shown = 2, 3
			}
			for i := 0; i < lines; i++ {
				out = append(out, atlasCell(previewLayer{tex: sky, w: 110, h: 110, dy: 27, tint: &black, a: 1}, 8+i))
			}
			for i := 0; i < shown; i++ {
				out = append(out, previewLayer{tex: flare, w: sizes[i] * 1.5, h: sizes[i] * 1.5, dx: stars[i][0], dy: stars[i][1], tint: &black, a: 0.8})
			}
			for i := 0; i < lines; i++ {
				out = append(out, atlasCell(previewLayer{tex: sky, w: 110, h: 110, dy: 27, add: true, whiten: 0.45, a: 0.95}, i))
			}
			for i := 0; i < shown; i++ {
				if ready {
					out = append(out, previewLayer{tex: halo, w: sizes[i] * 2, h: sizes[i] * 2, dx: stars[i][0], dy: stars[i][1], add: true, whiten: 0.3, a: 0.2})
				}
				out = append(out, previewLayer{tex: flare, w: sizes[i], h: sizes[i], dx: stars[i][0], dy: stars[i][1], add: true, whiten: 0.2, a: 1},
					previewLayer{tex: halo, w: 10, h: 10, dx: stars[i][0], dy: stars[i][1], add: true, whiten: 1, a: 1})
			}
			return out
		}},
	}
}

// filterPreviewStyles: nur die Stile mit diesen Namen (kommagetrennt, Umgebungsvariable SPARKLE_PREVIEW_STYLES), leer = alle
func filterPreviewStyles(styles []previewStyle, names string) []previewStyle {
	if names == "" {
		return styles
	}
	var out []previewStyle
	for _, style := range styles {
		for _, name := range strings.Split(names, ",") {
			if style.name == strings.TrimSpace(name) {
				out = append(out, style)
			}
		}
	}
	return out
}
