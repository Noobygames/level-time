package main

import (
	"image"
	"math"
)

// Texturen des Stils Schatzkarte (Roadmap 470): handgezeichnetes Tinten-X, gestrichelter Pfad und ein Kreis, der
// sich um das X schließt. Alles liegt als Strichstücke in einem Atlas (4 x 4 Zellen, im Addon auf eine
// Bodenellipse gestaucht) und wird nacheinander eingeblendet, als würde es gemalt.
// Zellen: 0 bis 3 = X (zwei Striche je zwei Hälften), 4 bis 7 = Pfad, 8 bis 15 = Kreis.
// Tinte = dunkler Grauwert, Rand = heller Grauwert: SetVertexColor färbt den Rand golden, die Tinte bleibt fast
// schwarz, so ist die Zeichnung auf hellem und dunklem Boden zu lesen.
const (
	mapInkRim       = 4 // Texel Rand um die Tinte
	mapRimAlpha     = 1.0
	mapRimLum       = 1.0
	mapInkMin       = 0.04
	mapInkMax       = 0.3
	mapRingMid      = 0.52
	mapRingWidth    = 0.065
	mapRingSegments = 8
	mapRingOvershot = 14.0 // Grad, um die der Kreis über den Start hinausmalt
	mapDashes       = 4
	mapDashWidth    = 0.062
)

// Pfad: leichte Kurve von links unten zum Kreis um das X (Anfang, Ausbuchtung, Ende in Zellkoordinaten)
var (
	mapPathStart = [2]float64{-0.76, 0.62}
	mapPathBend  = [2]float64{-0.90, 0.20}
	mapPathEnd   = [2]float64{-0.56, 0.30}
)

// brushStroke: Pinselstrich von (ax, ay) nach (bx, by): etwa gleich breit (w0), am Ende bis w1 verjüngt, an beiden
// Enden eine kleine Tintenansammlung, Rand leicht ausgefranst wie bei trockenem Pinsel, leicht geschwungen (wobble).
// Nur der Abschnitt t0 bis t1 (0 bis 1 entlang des Strichs) wird gezeichnet; Kappen und Tintenansammlung gibt es nur an
// den echten Enden des Strichs (t0 = 0 bzw. t1 = 1).
func brushStroke(ax, ay, bx, by, w0, w1, wobble, seed, t0, t1 float64) shapeFunc {
	dx, dy := bx-ax, by-ay
	length := math.Hypot(dx, dy)
	nx, ny := -dy/length, dx/length
	return func(u, v float64) bool {
		raw := ((u-ax)*dx + (v-ay)*dy) / (length * length)
		if t0 > 0 && raw < t0 || t1 < 1 && raw > t1 {
			return false
		}
		t := math.Max(0, math.Min(1, raw))
		bend := wobble * math.Sin(2.3*math.Pi*t+seed)
		px, py := ax+t*dx+nx*bend, ay+t*dy+ny*bend
		ragged := 0.1 * w0 * (math.Sin(u*97+v*61+seed) + math.Sin(u*43-v*113+2*seed))
		width := w0 + (w1-w0)*smoothstep(0.55, 1, t) + ragged
		if math.Hypot(u-px, v-py) <= width/2 {
			return true
		}
		const pool = 0.64 // Tintenansammlung: Kreis etwas breiter als der Strich
		if t0 == 0 && math.Hypot(u-ax, v-ay) <= w0*pool {
			return true
		}
		return t1 == 1 && math.Hypot(u-bx, v-by) <= w1*pool*1.1
	}
}

// bezierPoint: Punkt der quadratischen Kurve a, c, b bei t
func bezierPoint(a, c, b [2]float64, t float64) (float64, float64) {
	m := 1 - t
	return m*m*a[0] + 2*m*t*c[0] + t*t*b[0], m*m*a[1] + 2*m*t*c[1] + t*t*b[1]
}

// mapCellShape liefert die Form der Atlaszelle i
func mapCellShape(i int) shapeFunc {
	switch {
	case i < 4:
		stroke, half := i/2, float64(i%2)
		if stroke == 0 {
			return brushStroke(-0.36, -0.32, 0.37, 0.34, 0.15, 0.115, 0.02, 0.4, half*0.5, 0.5+half*0.5)
		}
		return brushStroke(0.34, -0.36, -0.34, 0.33, 0.145, 0.11, 0.024, 2.1, half*0.5, 0.5+half*0.5)
	case i < 4+mapDashes:
		k := float64(i - 4)
		step := 1.0 / mapDashes
		x0, y0 := bezierPoint(mapPathStart, mapPathBend, mapPathEnd, k*step+0.01)
		x1, y1 := bezierPoint(mapPathStart, mapPathBend, mapPathEnd, (k+1)*step-0.015)
		return brushStroke(x0, y0, x1, y1, mapDashWidth, mapDashWidth*0.85, 0, k, 0, 1)
	}
	j := i - 4 - mapDashes
	span := 360.0 / mapRingSegments
	from, to := float64(j)*span, float64(j+1)*span
	last := j == mapRingSegments-1
	if last {
		to += mapRingOvershot
	}
	return func(u, v float64) bool {
		r, deg := polar(u, v)
		if last && deg < mapRingOvershot {
			deg += 360 // Überstand hinter dem Start
		}
		if deg < from || deg > to {
			return false
		}
		progress := math.Min(1.1, deg/360)
		mid := mapRingMid + 0.015*math.Sin(deg*math.Pi/180*2.1) + 0.03*smoothstep(0.93, 1.1, progress)
		width := mapRingWidth * (1 - 0.35*progress)
		return math.Abs(r-mid) <= width/2
	}
}

func mapCellMask(i int) mask {
	img := newSparkleImage(sparkleTexSize)
	drawShape(img, 0, 0, sparkleTexSize, mapCellShape(i))
	return maskOf(img)
}

// inkImage: Tinte dunkel (mit leichtem Glanz), Rand hell; die Deckkraft folgt der aufgeweichten Hülle
func inkImage(m mask) *image.NRGBA {
	grown := m.morph(mapInkRim, true).blur(mapInkRim/2 + 1)
	light := m.bevelLight(2, 0)
	img := image.NewNRGBA(image.Rect(0, 0, m.w, m.h))
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			i := y*m.w + x
			a := math.Max(grown.a[i]*mapRimAlpha, m.a[i])
			if a <= 0 {
				continue
			}
			ink := math.Max(mapInkMin, math.Min(mapInkMax, mapInkMin+0.35*(light[i]-0.86)))
			share := m.a[i] / a
			lum := share*ink + (1-share)*mapRimLum
			img.SetNRGBA(x, y, nrgba(uint8(math.Round(lum*255)), uint8(math.Round(math.Min(1, a)*255))))
		}
	}
	return img
}

func renderSparkleMapInk() *image.NRGBA {
	return atlasOf(func(i int) *image.NRGBA { return inkImage(mapCellMask(i)) })
}

// mapShape: alles zusammen (für das Leuchten)
func mapShape(u, v float64) bool {
	for i := 0; i < atlasCells; i++ {
		if mapCellShape(i)(u, v) {
			return true
		}
	}
	return false
}

func renderSparkleMapGlow(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, scaled(mapShape, glowShapeScale))
	return shapeGlow(maskOf(img), glowRadius)
}
