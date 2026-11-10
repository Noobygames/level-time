package main

import (
	"image"
	"image/color"
	"math"
)

// Formtexturen für die eigenen Beute-Glitzer-Stile (Roadmap 466, 471, 475): Zielsucher-Klammern, Kristall-Pfeil
// und Kategorie-Symbole. Jede Form gibt es als Körper (Licht und Schatten im Grauwert, SetVertexColor färbt ein),
// dunklen weichen Umriss (BLEND, schwarz), Leuchtrand (ADD) und, bei den Klammern, hellem Kern. Die Kanten sind
// per Supersampling geglättet.
const (
	shapeSamples     = 4   // Teilpixel je Achse
	symbolCellSize   = 128 // Kantenlänge eines Symbols im Atlas
	symbolAtlasCols  = 4
	symbolAtlasRows  = 2
	symbolAtlasW     = symbolCellSize * symbolAtlasCols
	symbolAtlasH     = symbolCellSize * symbolAtlasRows
	bracketExtent    = 0.90 // Außenkante der Klammern (Anteil der halben Textur)
	bracketThickness = 0.16
	bracketArm       = 0.46 // Länge eines Klammerarms
	dashesPerSide    = 7
	outlineGrow      = 3   // Umriss: Pixel über die Form hinaus (bei 128 Pixel Kantenlänge)
	glowRadius       = 12  // Leuchtrand: Weichzeichner-Radius
	bevelRadius      = 4   // Wölbung des Körpers
	bevelVertical    = 0.3 // Verlauf von hell oben nach dunkler unten
)

func nrgba(grey, alpha uint8) color.NRGBA { return color.NRGBA{R: grey, G: grey, B: grey, A: alpha} }

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

// Die vier Bausteine einer Form aus ihrer Maske: Körper, Umriss, Leuchtrand, Kern
func shapeBody(m mask, radius int) *image.NRGBA {
	return m.shadedImage(m.bevelLight(radius, bevelVertical))
}

func shapeOutline(m mask, grow int) *image.NRGBA {
	g := m.morph(grow, true).blur(grow/2 + 1)
	for i := range g.a {
		g.a[i] = math.Min(1, g.a[i]*1.5)
	}
	return g.whiteImage()
}

// glowShapeScale: die Form liegt für den Leuchtrand nur auf diesem Anteil der Textur, damit der Auslauf weit vor dem
// Rand bei 0 ist (sonst schneidet er als Rechteck ab). Die Schicht im Addon ist entsprechend 1 / glowShapeScale mal
// so groß wie der Körper (LootSparkleStyles.GLOW_SCALE).
const glowShapeScale = 0.5

// shapeGlow: weicher Leuchtrand; die äußersten Pixel sind ausdrücklich 0
func shapeGlow(m mask, radius int) *image.NRGBA {
	g := m.blur(radius).normalized()
	const border = 3
	for y := 0; y < g.h; y++ {
		for x := 0; x < g.w; x++ {
			if x < border || y < border || x >= g.w-border || y >= g.h-border {
				g.a[y*g.w+x] = 0
			}
		}
	}
	return g.whiteImage()
}

// scaled: Form verkleinert um die Mitte
func scaled(shape shapeFunc, factor float64) shapeFunc {
	return func(u, v float64) bool { return shape(u/factor, v/factor) }
}

func shapeCore(m mask, shrink int) *image.NRGBA {
	return m.morph(shrink, false).blur(2).normalized().whiteImage()
}

func bracketShape(u, v float64) bool {
	au, av := math.Abs(u), math.Abs(v)
	if au > bracketExtent || av > bracketExtent {
		return false
	}
	inner := bracketExtent - bracketThickness
	arm := bracketExtent - bracketArm
	return (au >= inner && av >= arm) || (av >= inner && au >= arm)
}

func bracketMask(size int) mask {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, bracketShape)
	return maskOf(img)
}

// SparkleBracket: vier dicke Eckklammern wie ein Kamera-Fokus, gewölbt mit Licht von links oben.
func renderSparkleBracket(size int) *image.NRGBA { return shapeBody(bracketMask(size), bevelRadius) }

func renderSparkleBracketOutline(size int) *image.NRGBA {
	return shapeOutline(bracketMask(size), outlineGrow)
}
func renderSparkleBracketGlow(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, scaled(bracketShape, glowShapeScale))
	return shapeGlow(maskOf(img), glowRadius)
}
func renderSparkleBracketCore(size int) *image.NRGBA { return shapeCore(bracketMask(size), 4) }

// SparkleBracketDashed: gestrichelter Rahmen derselben Größe (gesperrt), weiß einfärbbar.
func renderSparkleBracketDashed(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, func(u, v float64) bool {
		au, av := math.Abs(u), math.Abs(v)
		if math.Max(au, av) > bracketExtent || math.Max(au, av) < bracketExtent-bracketThickness*0.8 {
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

// Kristall-Pfeil: lange Raute mit Spitze nach unten (Krone oben, Spitze unten).
const (
	gemTop, gemShoulder, gemTip, gemHalfWidth = -0.85, -0.25, 0.9, 0.55
)

func gemShape(u, v float64) bool {
	if v < gemTop || v > gemTip {
		return false
	}
	if v <= gemShoulder {
		return math.Abs(u) <= gemHalfWidth*(v-gemTop)/(gemShoulder-gemTop)
	}
	return math.Abs(u) <= gemHalfWidth*(gemTip-v)/(gemTip-gemShoulder)
}

// gemFacet: Helligkeit der Facette am Punkt: links heller als rechts, Krone und Spitze verschieden, Kanten leuchten
func gemFacet(u, v float64) float64 {
	crown := v <= gemShoulder
	var b float64
	switch {
	case crown && u < 0:
		b = 0.95
	case crown:
		b = 0.76
	case u < 0:
		b = 0.82
	default:
		b = 0.5
	}
	// Mittelkante und Schulterkante als feine helle Linien
	if math.Abs(u) < 0.025 || math.Abs(v-gemShoulder) < 0.025 {
		b = 1
	}
	return b
}

func gemMask(size int) mask {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, gemShape)
	return maskOf(img)
}

// SparkleArrow: Kristall mit zwei Farbtönen (links hell, rechts dunkel) und leuchtenden Kanten.
func renderSparkleArrow(size int) *image.NRGBA {
	m := gemMask(size)
	light := m.bevelLight(2, bevelVertical)
	bright := make([]float64, len(light))
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			u := (float64(x)+0.5)/float64(m.w)*2 - 1
			v := (float64(y)+0.5)/float64(m.h)*2 - 1
			bright[y*m.w+x] = gemFacet(u, v) * (0.6 + 0.4*math.Min(1.2, light[y*m.w+x]))
		}
	}
	return m.shadedImage(bright)
}

func renderSparkleArrowOutline(size int) *image.NRGBA {
	return shapeOutline(gemMask(size), outlineGrow)
}
func renderSparkleArrowGlow(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, scaled(gemShape, glowShapeScale))
	return shapeGlow(maskOf(img), glowRadius)
}

// SparkleTrail: schmale Lichtspur nach oben (unten hell, nach oben ausblendend) über dem Pfeil
func renderSparkleTrail(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			t := 1 - (float64(y)+0.5)/float64(size) // 1 unten, 0 oben
			setSparklePixel(img, x, y, math.Exp(-math.Pow(u/0.14, 2))*math.Pow(t, 1.4))
		}
	}
	return img
}

// SparkleBadge: runde Scheibe mit weichem Rand hinter den Symbolen (schwarz eingefärbt, BLEND)
func renderSparkleBadge(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			a := math.Max(0, math.Min(1, (0.94-r)/0.1))
			setSparklePixel(img, x, y, a)
		}
	}
	return img
}

// symbolShapes in der Reihenfolge des Atlas (Zelle 1 bis 6, zeilenweise von links oben).
var symbolShapes = []shapeFunc{symbolPickaxe, symbolLeaf, symbolScroll, symbolChest, symbolBobber, symbolSack}

func symbolMask() mask {
	img := image.NewNRGBA(image.Rect(0, 0, symbolAtlasW, symbolAtlasH))
	for i, shape := range symbolShapes {
		x0 := (i % symbolAtlasCols) * symbolCellSize
		y0 := (i / symbolAtlasCols) * symbolCellSize
		drawShape(img, x0, y0, symbolCellSize, shape)
	}
	return maskOf(img)
}

// SparkleSymbols: Atlas der Kategorie-Symbole (4 x 2 Zellen à 128 Pixel), gefüllt, gewölbt, Licht links oben.
func renderSparkleSymbols() *image.NRGBA { return shapeBody(symbolMask(), bevelRadius+1) }

func renderSparkleSymbolsOutline() *image.NRGBA { return shapeOutline(symbolMask(), outlineGrow+1) }

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

// Spitzhacke: dicker Stiel nach links unten, kräftiger gebogener Kopf, der zu den Spitzen hin schmaler wird.
func symbolPickaxe(u, v float64) bool {
	if segmentDistance(u, v, -0.66, 0.66, 0.1, -0.1) <= 0.13 {
		return true
	}
	cu, cv := 0.0, 0.0
	r := math.Hypot(u-cu, v-cv)
	if r > 0.86 || r < 0.5 {
		return false
	}
	// Winkel zur Achse "rechts oben" (1, -1)
	cosA := ((u-cu)*0.7071 - (v-cv)*0.7071) / r
	angle := math.Acos(math.Max(-1, math.Min(1, cosA)))
	limit := 62 * math.Pi / 180
	if angle > limit {
		return false
	}
	taper := 0.5 + 0.14*(angle/limit)*(angle/limit) // Innenradius wächst zu den Enden
	return r >= taper
}

// Blatt: breites spitzes Blatt entlang der Diagonale mit Mittelrippe (ausgespart) und Stiel.
func symbolLeaf(u, v float64) bool {
	a := (u - v) / math.Sqrt2
	b := (u + v) / math.Sqrt2
	if a >= -1.1 && a < -0.88 {
		return math.Abs(b) <= 0.08
	}
	if a < -0.95 || a > 0.95 {
		return false
	}
	if math.Abs(b) < 0.04 && a > -0.75 && a < 0.55 {
		return false
	}
	return math.Abs(b) <= 0.58*(1-(a/0.95)*(a/0.95))
}

// Schriftrolle: Körper mit Textzeilen, oben und unten aufgerollt.
func symbolScroll(u, v float64) bool {
	if inEllipse(u, v, 0, -0.64, 0.74, 0.2) || inEllipse(u, v, 0, 0.64, 0.74, 0.2) {
		return true
	}
	if math.Abs(u) > 0.58 || math.Abs(v) > 0.6 {
		return false
	}
	if math.Abs(u) < 0.36 {
		for _, line := range []float64{-0.3, -0.08, 0.14, 0.36} {
			if math.Abs(v-line) < 0.04 {
				return false
			}
		}
	}
	return true
}

// Truhe: gewölbter Deckel, Körper, Schloss ausgespart.
func symbolChest(u, v float64) bool {
	if math.Abs(u) < 0.12 && v > 0.04 && v < 0.34 {
		return false
	}
	if v <= -0.05 {
		return inEllipse(u, v, 0, -0.05, 0.84, 0.58)
	}
	return math.Abs(u) <= 0.84 && v >= 0.02 && v <= 0.7
}

// Angelpose: dicker Schwimmer mit Spitze oben und Schnur unten.
func symbolBobber(u, v float64) bool {
	if math.Abs(u) < 0.07 && v > -0.9 && v < -0.36 {
		return true
	}
	if math.Abs(u) < 0.06 && v > 0.46 && v < 0.9 {
		return true
	}
	if math.Abs(v-0.05) < 0.04 && math.Abs(u) < 0.46 {
		return false
	}
	return inEllipse(u, v, 0, 0.05, 0.46, 0.46)
}

// Beutel: runder Sack mit gerafftem Hals.
func symbolSack(u, v float64) bool {
	if inEllipse(u, v, 0, -0.64, 0.4, 0.17) {
		return true
	}
	if v >= -0.52 && v <= -0.1 {
		if math.Abs(v+0.36) < 0.035 && math.Abs(u) < 0.5 {
			return false
		}
		return math.Abs(u) <= 0.24+0.16*(v+0.52)/0.42
	}
	return inEllipse(u, v, 0, 0.26, 0.74, 0.64)
}
