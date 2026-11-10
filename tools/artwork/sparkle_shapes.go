package main

import (
	"image"
	"math"
)

// Scharfe Formtexturen für die eigenen Beute-Glitzer-Stile (Roadmap 466, 471, 475): Zielsucher-Klammern,
// Pfeil und Kategorie-Symbole. Wie die Lichttexturen reinweiß mit Form im Alphakanal, damit SetVertexColor
// sie einfärben kann; die Kanten sind per Supersampling geglättet.
const (
	shapeSamples     = 4  // Teilpixel je Achse
	symbolCellSize   = 64 // Kantenlänge eines Symbols im Atlas
	symbolAtlasCols  = 4
	symbolAtlasRows  = 2
	symbolAtlasW     = symbolCellSize * symbolAtlasCols
	symbolAtlasH     = symbolCellSize * symbolAtlasRows
	bracketExtent    = 0.92 // Außenkante der Klammern (Anteil der halben Textur)
	bracketThickness = 0.13
	bracketArm       = 0.45 // Länge eines Klammerarms
	dashesPerSide    = 7
)

// shapeFunc: liegt der Punkt (u rechts, v unten, beide von -1 bis 1 in der Zelle) in der Form?
type shapeFunc func(u, v float64) bool

// drawShape zeichnet die Form in die Zelle (x0, y0, Kantenlänge cell) und glättet die Kanten.
func drawShape(img *image.NRGBA, x0, y0, cell int, inside shapeFunc) {
	half := float64(cell) / 2.0
	for y := 0; y < cell; y++ {
		for x := 0; x < cell; x++ {
			hits := 0
			for sy := 0; sy < shapeSamples; sy++ {
				for sx := 0; sx < shapeSamples; sx++ {
					u := (float64(x) + (float64(sx)+0.5)/shapeSamples - half) / half
					v := (float64(y) + (float64(sy)+0.5)/shapeSamples - half) / half
					if inside(u, v) {
						hits++
					}
				}
			}
			setSparklePixel(img, x0+x, y0+y, float64(hits)/float64(shapeSamples*shapeSamples))
		}
	}
}

// SparkleBracket: vier Eckklammern wie ein Kamera-Fokus.
func renderSparkleBracket(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, func(u, v float64) bool {
		au, av := math.Abs(u), math.Abs(v)
		if au > bracketExtent || av > bracketExtent {
			return false
		}
		inner := bracketExtent - bracketThickness
		arm := bracketExtent - bracketArm
		return (au >= inner && av >= arm) || (av >= inner && au >= arm)
	})
	return img
}

// SparkleBracketDashed: gestrichelter Rahmen derselben Größe (gesperrt).
func renderSparkleBracketDashed(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, func(u, v float64) bool {
		au, av := math.Abs(u), math.Abs(v)
		if math.Max(au, av) > bracketExtent || math.Max(au, av) < bracketExtent-bracketThickness {
			return false
		}
		along := u // Strich entlang der oberen/unteren Kante
		if au > av {
			along = v // entlang der linken/rechten Kante
		}
		phase := (along + 1) / 2 * dashesPerSide
		return phase-math.Floor(phase) < 0.6
	})
	return img
}

// SparkleArrow: Pfeil nach unten (Schaft und Spitze).
func renderSparkleArrow(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, func(u, v float64) bool {
		if v < -0.9 || v > 0.9 {
			return false
		}
		if v <= 0.05 {
			return math.Abs(u) <= 0.2
		}
		return math.Abs(u) <= 0.7*(0.9-v)/0.85
	})
	return img
}

// symbolShapes in der Reihenfolge des Atlas (Zelle 1 bis 6, zeilenweise von links oben).
var symbolShapes = []shapeFunc{symbolPickaxe, symbolLeaf, symbolScroll, symbolChest, symbolBobber, symbolSack}

// SparkleSymbols: Atlas der Kategorie-Symbole (4 x 2 Zellen à 64 Pixel).
func renderSparkleSymbols() *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, symbolAtlasW, symbolAtlasH))
	for i, shape := range symbolShapes {
		x0 := (i % symbolAtlasCols) * symbolCellSize
		y0 := (i / symbolAtlasCols) * symbolCellSize
		drawShape(img, x0, y0, symbolCellSize, shape)
	}
	return img
}

func inEllipse(u, v, cu, cv, ru, rv float64) bool {
	du, dv := (u-cu)/ru, (v-cv)/rv
	return du*du+dv*dv <= 1
}

// Abstand eines Punktes zur Strecke (ax, ay)-(bx, by)
func segmentDistance(u, v, ax, ay, bx, by float64) float64 {
	dx, dy := bx-ax, by-ay
	t := math.Max(0, math.Min(1, ((u-ax)*dx+(v-ay)*dy)/(dx*dx+dy*dy)))
	return math.Hypot(u-(ax+t*dx), v-(ay+t*dy))
}

// Spitzhacke: Stiel nach links unten, gebogener Kopf am oberen Ende.
func symbolPickaxe(u, v float64) bool {
	if segmentDistance(u, v, -0.62, 0.62, 0.1, -0.1) <= 0.09 {
		return true
	}
	cu, cv := 0.03, -0.03
	r := math.Hypot(u-cu, v-cv)
	if r > 0.78 || r < 0.58 {
		return false
	}
	// Winkel zur Achse "rechts oben" (1, -1)
	cosA := ((u-cu)*0.7071 - (v-cv)*0.7071) / r
	return cosA >= math.Cos(55*math.Pi/180)
}

// Blatt: spitzes Blatt entlang der Diagonale mit Mittelrippe (ausgespart) und Stiel.
func symbolLeaf(u, v float64) bool {
	a := (u - v) / math.Sqrt2
	b := (u + v) / math.Sqrt2
	if a >= -1.12 && a < -0.9 {
		return math.Abs(b) <= 0.05
	}
	if a < -0.95 || a > 0.95 {
		return false
	}
	if math.Abs(b) < 0.035 && a > -0.8 && a < 0.6 {
		return false
	}
	return math.Abs(b) <= 0.46*(1-(a/0.95)*(a/0.95))
}

// Schriftrolle: Körper mit Textzeilen, oben und unten aufgerollt.
func symbolScroll(u, v float64) bool {
	if inEllipse(u, v, 0, -0.62, 0.66, 0.17) || inEllipse(u, v, 0, 0.62, 0.66, 0.17) {
		return true
	}
	if math.Abs(u) > 0.5 || math.Abs(v) > 0.55 {
		return false
	}
	if math.Abs(u) < 0.3 {
		for _, line := range []float64{-0.25, -0.05, 0.15, 0.35} {
			if math.Abs(v-line) < 0.03 {
				return false
			}
		}
	}
	return true
}

// Truhe: gewölbter Deckel, Körper, Schloss ausgespart.
func symbolChest(u, v float64) bool {
	if math.Abs(u) < 0.1 && v > 0.05 && v < 0.3 {
		return false
	}
	if v <= -0.05 {
		return inEllipse(u, v, 0, -0.05, 0.75, 0.5)
	}
	return math.Abs(u) <= 0.75 && v >= 0 && v <= 0.6
}

// Angelpose: Schwimmer mit Spitze oben und Schnur unten.
func symbolBobber(u, v float64) bool {
	if math.Abs(u) < 0.05 && v > -0.85 && v < -0.33 {
		return true
	}
	if math.Abs(u) < 0.04 && v > 0.43 && v < 0.85 {
		return true
	}
	if math.Abs(v-0.05) < 0.03 && math.Abs(u) < 0.4 {
		return false
	}
	return inEllipse(u, v, 0, 0.05, 0.38, 0.38)
}

// Beutel: runder Sack mit gerafftem Hals.
func symbolSack(u, v float64) bool {
	if inEllipse(u, v, 0, -0.62, 0.34, 0.14) {
		return true
	}
	if v >= -0.5 && v <= -0.1 {
		if math.Abs(v+0.35) < 0.025 && math.Abs(u) < 0.45 {
			return false
		}
		return math.Abs(u) <= 0.2+0.15*(v+0.5)/0.4
	}
	return inEllipse(u, v, 0, 0.25, 0.65, 0.6)
}

// glowRadius: Weichzeichner-Radius (Pixel bei 128) für den Leuchtrand dünner Formen
const glowRadius = 6

// blurAlpha: Gauß-Weichzeichner auf dem Alphakanal (getrennt in x und y), danach auf Höchstwert 1 normalisiert,
// damit auch dünne Striche als helle weiche Hülle erscheinen. RGB bleibt weiß.
func blurAlpha(src *image.NRGBA, radius int) *image.NRGBA {
	b := src.Bounds()
	w, h := b.Dx(), b.Dy()
	kernel := make([]float64, 2*radius+1)
	sigma := float64(radius) / 2.0
	for i := range kernel {
		d := float64(i - radius)
		kernel[i] = math.Exp(-d * d / (2 * sigma * sigma))
	}
	pass := func(in []float64, horizontal bool) []float64 {
		out := make([]float64, len(in))
		for y := 0; y < h; y++ {
			for x := 0; x < w; x++ {
				sum, weight := 0.0, 0.0
				for i, k := range kernel {
					xx, yy := x, y
					if horizontal {
						xx += i - radius
					} else {
						yy += i - radius
					}
					weight += k
					if xx >= 0 && xx < w && yy >= 0 && yy < h {
						sum += k * in[yy*w+xx]
					}
				}
				out[y*w+x] = sum / weight
			}
		}
		return out
	}
	alpha := make([]float64, w*h)
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			alpha[y*w+x] = float64(src.NRGBAAt(x, y).A) / 255
		}
	}
	alpha = pass(pass(alpha, true), false)
	peak := 0.0
	for _, a := range alpha {
		peak = math.Max(peak, a)
	}
	out := newSparkleImage(w)
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			setSparklePixel(out, x, y, alpha[y*w+x]/peak)
		}
	}
	return out
}

// SparkleBracketGlow, SparkleArrowGlow: weiche Leuchthülle der Formen (Bloom unter dem scharfen Körper)
func renderSparkleBracketGlow(size int) *image.NRGBA {
	return blurAlpha(renderSparkleBracket(size), glowRadius)
}

func renderSparkleArrowGlow(size int) *image.NRGBA {
	return blurAlpha(renderSparkleArrow(size), glowRadius)
}
