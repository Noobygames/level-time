package main

import (
	"image"
	"image/color"
	"math"
)

// Funkeln für die Beute-Glitzer (Assist/LootSparkles.lua): weißer Lichtpunkt mit vier langen und vier kurzen
// Strahlen auf transparentem Grund. Weiß, damit das Addon die Farbe per SetVertexColor wählt; die Helligkeit
// steckt im Alphakanal (Blend-Modus ADD im Spiel).
const glintSize = 64 // Zweierpotenz für WoW

const (
	glintCore      = 0.16  // Radius des hellen Kerns (Anteil der halben Kantenlänge)
	glintHalo      = 0.42  // Radius des weichen Scheins
	glintHaloLevel = 0.30  // Helligkeit des Scheins
	glintRayWidth  = 0.035 // Breite der langen Strahlen
	glintShortRay  = 0.55  // Länge der diagonalen Strahlen im Verhältnis zu den langen
	glintShortGain = 0.55  // Helligkeit der diagonalen Strahlen
)

// Strahl entlang der u-Achse: dünn, zur Spitze hin auslaufend
func glintRay(u, v, length float64) float64 {
	along := math.Max(0, 1-math.Abs(u)/length)
	across := math.Exp(-math.Pow(v/glintRayWidth, 2))
	return across * along * along
}

func glintIntensity(u, v float64) float64 {
	r := math.Hypot(u, v)
	core := math.Exp(-math.Pow(r/glintCore, 2))
	halo := glintHaloLevel * math.Exp(-math.Pow(r/glintHalo, 2))
	long := glintRay(u, v, 1) + glintRay(v, u, 1)
	// um 45 Grad gedreht
	du, dv := (u+v)/math.Sqrt2, (u-v)/math.Sqrt2
	short := glintShortGain * (glintRay(du, dv, glintShortRay) + glintRay(dv, du, glintShortRay))
	return math.Min(1, core+halo+long+short)
}

func renderGlint(size int) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	half := float64(size) / 2
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			alpha := glintIntensity(u, v)
			// Ränder sicher transparent, damit beim Skalieren keine Kanten sichtbar werden
			if math.Abs(u) > 0.97 || math.Abs(v) > 0.97 {
				alpha = 0
			}
			img.SetNRGBA(x, y, color.NRGBA{R: 255, G: 255, B: 255, A: uint8(math.Round(alpha * 255))})
		}
	}
	return img
}
