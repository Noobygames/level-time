package main

import (
	"image"
	"math"
)

// Texturen der Bodenstile Uhrwerk, Fortschrittsring und Lichtsäule (Roadmap 467, 468, 476). Die Kreise liegen in
// quadratischen Texturen; im Addon werden sie auf etwa 0.4 Höhe gestaucht und wirken so als Ellipse auf dem Boden
// (auch Zeiger und Segmente stimmen dann in der Perspektive). Animierte Teile (Zeigerstellungen, Segmente) liegen als
// Zellen in einem Atlas, weil Rotation und Stauchung zusammen nicht ohne OnUpdate gehen.
const (
	atlasCols, atlasRows = 4, 4
	atlasCells           = atlasCols * atlasRows // 16 Zeigerstellungen bzw. Segmente
	atlasSize            = atlasCols * sparkleTexSize

	clockRingOuter = 0.86
	clockRingWidth = 0.05
	clockTickOuter = 0.77
	clockHandReach = 0.64

	segmentInner = 0.66
	segmentOuter = 0.88
	segmentGap   = 3.4 // Grad Lücke zwischen zwei Segmenten

	columnWidth, columnHeight = 64, 256 // Lichtsäule: Seitenverhältnis 1 : 4
)

// polar liefert Radius und Winkel in Grad (0 = oben, im Uhrzeigersinn, 0 bis 360) eines Punktes (u rechts, v unten)
func polar(u, v float64) (r, deg float64) {
	r = math.Hypot(u, v)
	deg = math.Atan2(u, -v) * 180 / math.Pi
	if deg < 0 {
		deg += 360
	}
	return
}

// Zifferblatt: dünner Außenring und zwölf Striche (die vier Viertelstriche länger und kräftiger).
func clockFaceShape(u, v float64) bool {
	r, deg := polar(u, v)
	if r <= clockRingOuter && r >= clockRingOuter-clockRingWidth {
		return true
	}
	if r > clockTickOuter || r < 0.5 {
		return false
	}
	const step = 30.0
	offset := math.Abs(math.Remainder(deg, step)) // Gradabstand zum nächsten Strich
	halfWidth, inner := 0.022, 0.64
	if math.Abs(math.Remainder(deg, 90)) < 8 {
		halfWidth, inner = 0.034, 0.56
	}
	return r >= inner && r*offset*math.Pi/180 <= halfWidth
}

func clockFaceMask(size int) mask {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, clockFaceShape)
	return maskOf(img)
}

func renderSparkleClockFace(size int) *image.NRGBA { return shapeBody(clockFaceMask(size), 2) }
func renderSparkleClockOutline(size int) *image.NRGBA {
	return shapeOutline(clockFaceMask(size), outlineGrow)
}
func renderSparkleClockGlow(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, scaled(clockFaceShape, glowShapeScale))
	return shapeGlow(maskOf(img), glowRadius)
}

// handShape: schlanker, zur Spitze verjüngter Zeiger in Richtung deg (0 = oben, im Uhrzeigersinn) mit kurzem
// Gegengewicht und Nabe
func handShape(deg float64) shapeFunc {
	dx, dy := math.Sin(deg*math.Pi/180), -math.Cos(deg*math.Pi/180)
	return func(u, v float64) bool {
		if math.Hypot(u, v) <= 0.11 {
			return true
		}
		along := u*dx + v*dy
		across := math.Abs(-u*dy + v*dx)
		if along < -0.16 || along > clockHandReach {
			return false
		}
		if along < 0 {
			return across <= 0.04
		}
		return across <= 0.068-0.046*along/clockHandReach
	}
}

// atlasOf setzt 16 Zellen (sparkleTexSize Pixel) zeilenweise von links oben zu einer Textur zusammen
func atlasOf(cell func(i int) *image.NRGBA) *image.NRGBA {
	atlas := image.NewNRGBA(image.Rect(0, 0, atlasSize, atlasSize))
	for i := 0; i < atlasCells; i++ {
		x0, y0 := (i%atlasCols)*sparkleTexSize, (i/atlasCols)*sparkleTexSize
		part := cell(i)
		for y := 0; y < sparkleTexSize; y++ {
			for x := 0; x < sparkleTexSize; x++ {
				atlas.SetNRGBA(x0+x, y0+y, part.NRGBAAt(x, y))
			}
		}
	}
	return atlas
}

func handMask(i, size int) mask {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, handShape(float64(i)*360/atlasCells))
	return maskOf(img)
}

// SparkleClockHands: 16 Zeigerstellungen (22.5 Grad Abstand, Zelle 1 = 12 Uhr), gewölbt mit Licht links oben.
func renderSparkleClockHands() *image.NRGBA {
	return atlasOf(func(i int) *image.NRGBA { return shapeBody(handMask(i, sparkleTexSize), 2) })
}

// segmentShape: Ringsegment i (Zelle i, Segment 1 beginnt bei 12 Uhr, im Uhrzeigersinn) mit Lücke zu den Nachbarn
func segmentShape(i int) shapeFunc {
	span := 360.0 / atlasCells
	from, to := float64(i)*span+segmentGap/2, float64(i+1)*span-segmentGap/2
	return func(u, v float64) bool {
		r, deg := polar(u, v)
		return r >= segmentInner && r <= segmentOuter && deg >= from && deg <= to
	}
}

func segmentMask(i, size int) mask {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, segmentShape(i))
	return maskOf(img)
}

// ringShape: alle Segmente zusammen (für Umriss, Spur und Leuchten)
func ringShape(u, v float64) bool {
	r, _ := polar(u, v)
	return r >= segmentInner && r <= segmentOuter
}

// SparkleSegments: 16 Ringsegmente wie die XP-Leiste, gewölbt mit Licht links oben (Zelle i = Segment i + 1).
func renderSparkleSegments() *image.NRGBA {
	return atlasOf(func(i int) *image.NRGBA { return shapeBody(segmentMask(i, sparkleTexSize), 3) })
}

func ringMask(size int) mask {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, ringShape)
	return maskOf(img)
}

// SparkleProgressTrack: dunkler weicher Umriss des ganzen Rings; ungefüllt bleibt er als leere Leiste stehen.
func renderSparkleProgressTrack(size int) *image.NRGBA {
	return shapeOutline(ringMask(size), outlineGrow)
}

func renderSparkleProgressGlow(size int) *image.NRGBA {
	img := newSparkleImage(size)
	drawShape(img, 0, 0, size, scaled(ringShape, glowShapeScale))
	return shapeGlow(maskOf(img), glowRadius)
}

func smoothstep(edge0, edge1, x float64) float64 {
	t := math.Max(0, math.Min(1, (x-edge0)/(edge1-edge0)))
	return t * t * (3 - 2*t)
}

// SparkleColumn: Lichtsäule (hochkant), unten hell und breit, nach oben schmaler und ausblendend, zu den Seiten
// weich auslaufend; sigma bestimmt die Breite des hellen Kerns, rise den Verlauf nach oben (Potenz).
func renderSparkleColumn(sigma, rise float64) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, columnWidth, columnHeight))
	for y := 0; y < columnHeight; y++ {
		s := (float64(y) + 0.5) / columnHeight // 0 oben, 1 unten
		vert := math.Pow(s, rise) * smoothstep(0.0, 0.12, s) * (1 - 0.6*smoothstep(0.93, 1.0, s))
		width := sigma * (0.55 + 0.45*s) // oben schmaler
		for x := 0; x < columnWidth; x++ {
			nx := (float64(x) + 0.5 - columnWidth/2.0) / (columnWidth / 2.0)
			side := math.Exp(-math.Pow(nx/width, 2)) * (1 - smoothstep(0.7, 0.97, math.Abs(nx)))
			setSparklePixel(img, x, y, side*vert)
		}
	}
	return img
}

func renderSparkleColumnBody() *image.NRGBA { return renderSparkleColumn(0.5, 1.5) }
func renderSparkleColumnCore() *image.NRGBA { return renderSparkleColumn(0.2, 1.1) }

// SparkleColumnShade: dunkler weicher Schatten um die Säule (BLEND), damit sie auch auf Schnee und Sand zu sehen ist
func renderSparkleColumnShade() *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, columnWidth, columnHeight))
	for y := 0; y < columnHeight; y++ {
		s := (float64(y) + 0.5) / columnHeight
		vert := math.Pow(s, 0.9) * smoothstep(0.0, 0.1, s)
		for x := 0; x < columnWidth; x++ {
			nx := (float64(x) + 0.5 - columnWidth/2.0) / (columnWidth / 2.0)
			side := math.Exp(-math.Pow(nx/0.78, 2)) * (1 - smoothstep(0.75, 0.97, math.Abs(nx)))
			setSparklePixel(img, x, y, side*vert)
		}
	}
	return img
}

// SparkleLightRing: flacher Lichtring der Säule: dünner heller Kern mit weichem Hof, die vordere (untere) Hälfte
// heller als die hintere, damit er räumlich wirkt.
func renderSparkleLightRing(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			if r >= 0.97 {
				continue
			}
			line := math.Exp(-math.Pow((r-0.7)/0.05, 2)) + 0.35*math.Exp(-math.Pow((r-0.7)/0.16, 2))
			front := 0.55 + 0.45*smoothstep(-0.5, 0.5, v/math.Max(r, 0.001))
			setSparklePixel(img, x, y, math.Min(1, line*front)*(1-smoothstep(0.85, 0.97, r)))
		}
	}
	return img
}
