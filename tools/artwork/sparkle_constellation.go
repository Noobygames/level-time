package main

import (
	"image"
	"math"
)

// Texturen des Stils Sternbild (Roadmap 473): vier dünne leuchtende Linien zwischen fünf Sternen, je Linie eine Zelle
// im Atlas. Zellen 0 bis 3 = Leuchtlinie (ADD), Zellen 8 bis 11 = dunkler weicher Schatten dazu (BLEND, schwarz).
// Eine Zelle bildet ein Quadrat von constellationSpan Spielpixeln um (0, constellationCenterY) ab; die Sternpositionen
// (Pixel relativ zur Mitte des Glitzerrahmens) müssen mit LootSparkleStyles.lua übereinstimmen.
const (
	constellationSpan       = 110.0
	constellationCenterY    = 27.0
	constellationInset      = 6.0 // Linien enden vor dem Stern (Pixel)
	constellationCore       = 1.0 // Pixel, Kernbreite
	constellationHalo       = 3.2
	constellationShadeAt    = 3.6
	constellationShadeAlpha = 0.8
	constellationShadeFirst = 8
)

var constellationStars = [5][2]float64{{-38, 8}, {-26, 44}, {-2, 28}, {22, 58}, {40, 22}}

// distanceToLine: Abstand (Pixel) des Zellpunktes (u, v) zur Linie i und Lage t entlang der Linie (0 bis 1)
func distanceToLine(u, v float64, i int) (dist, t float64) {
	half := constellationSpan / 2
	px, py := u*half, constellationCenterY-v*half
	a, b := constellationStars[i], constellationStars[i+1]
	dx, dy := b[0]-a[0], b[1]-a[1]
	length := math.Hypot(dx, dy)
	ux, uy := dx/length, dy/length
	ax, ay := a[0]+ux*constellationInset, a[1]+uy*constellationInset
	inner := length - 2*constellationInset
	along := math.Max(0, math.Min(inner, (px-ax)*ux+(py-ay)*uy))
	return math.Hypot(px-(ax+ux*along), py-(ay+uy*along)), along / inner
}

func renderSparkleConstellation() *image.NRGBA {
	atlas := image.NewNRGBA(image.Rect(0, 0, atlasSize, atlasSize))
	for i := 0; i < len(constellationStars)-1; i++ {
		drawConstellationCell(atlas, i, func(d, t float64) float64 {
			ends := 0.8 + 0.2*math.Sin(math.Pi*t) // an den Sternen etwas blasser
			core := math.Exp(-math.Pow(d/constellationCore, 2))
			halo := 0.35 * math.Exp(-math.Pow(d/constellationHalo, 2))
			return math.Min(1, core+halo) * ends
		})
		drawConstellationCell(atlas, constellationShadeFirst+i, func(d, t float64) float64 {
			return constellationShadeAlpha * math.Exp(-math.Pow(d/constellationShadeAt, 2))
		})
	}
	return atlas
}

// drawConstellationCell füllt Zelle cell des Atlas; die Linie ergibt sich aus der Zelle modulo 8 (Schatten = Linie + 8)
func drawConstellationCell(atlas *image.NRGBA, cell int, alpha func(dist, t float64) float64) {
	line := cell % constellationShadeFirst
	x0, y0 := (cell%atlasCols)*sparkleTexSize, (cell/atlasCols)*sparkleTexSize
	half := float64(sparkleTexSize) / 2
	for y := 0; y < sparkleTexSize; y++ {
		for x := 0; x < sparkleTexSize; x++ {
			d, t := distanceToLine((float64(x)+0.5-half)/half, (float64(y)+0.5-half)/half, line)
			setSparklePixel(atlas, x0+x, y0+y, alpha(d, t))
		}
	}
}
