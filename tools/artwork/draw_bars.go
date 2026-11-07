package main

import (
	"image"
	"image/color"
	"math"
)

// Balkentexturen (Roadmap 361): weiß in Graustufen, das Addon färbt sie per SetVertexColor ein.
// Zweierpotenzen für WoW; die Breite wird gestreckt, daher reicht ein schmales Bild.
const (
	barTextureWidth  = 128
	barTextureHeight = 16

	smoothTop    = 1.0  // Helligkeit oben (Verlauf "Glatt")
	smoothBottom = 0.62 // Helligkeit unten

	glossBase      = 0.72 // Grundhelligkeit "Glanz"
	glossHighlight = 0.28 // Zusatz im Glanzstreifen
	glossCenter    = 0.3  // Lage des Glanzstreifens (Anteil der Höhe von oben)
	glossWidth     = 0.18 // Breite des Glanzstreifens
	glossShadow    = 0.2  // Abdunklung zur Unterkante
)

// Arten: Dateiname ohne Endung -> Helligkeit in relativer Höhe v (0 = oben, 1 = unten)
var barKinds = map[string]func(v float64) float64{
	"BarSmooth": func(v float64) float64 { return smoothTop + (smoothBottom-smoothTop)*v },
	"BarGloss": func(v float64) float64 {
		band := math.Exp(-math.Pow((v-glossCenter)/glossWidth, 2))
		return glossBase + glossHighlight*band - glossShadow*v*v
	},
}

func renderBar(brightness func(v float64) float64) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, barTextureWidth, barTextureHeight))
	for y := 0; y < barTextureHeight; y++ {
		v := (float64(y) + 0.5) / barTextureHeight
		level := uint8(math.Round(math.Max(0, math.Min(1, brightness(v))) * 255))
		for x := 0; x < barTextureWidth; x++ {
			img.SetNRGBA(x, y, color.NRGBA{R: level, G: level, B: level, A: 255})
		}
	}
	return img
}
