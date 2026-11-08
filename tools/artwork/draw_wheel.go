package main

import (
	"image"
	"image/color"
	"math"
)

// Glücksrad von Level Time Goals (StreamGoal/WheelDisplay.lua): alle Teile weiß bzw. grau auf transparentem Grund,
// das Addon färbt sie per SetVertexColor mit Theme-Farben.
//
//	WheelSlice: ein Tortenstück (wheelSlices Stück ergeben den vollen Kreis), Spitze in der Mitte, nach oben
//	            zeigend; das Addon dreht jede Kopie per Texture:SetRotation um die Mitte. Grauer Rand = Trennlinie.
//	WheelRim:   Ring um das Rad (dreht sich nicht).
//	WheelHub:   Nabe in der Mitte (gefüllter Kreis mit grauem Rand).
//	WheelPointer: Zeiger oben, Spitze nach unten.
const (
	wheelSliceSize   = 256 // Zweierpotenz für WoW
	wheelHubSize     = 64
	wheelPointerSize = 64
	wheelSlices      = 12   // muss zu WheelDisplay.SLICES passen
	wheelRadius      = 0.96 // Außenradius des Stücks (Anteil der halben Kantenlänge)
	wheelBorder      = 0.03 // Breite der Trennlinien
	wheelBorderLevel = 140  // Grauwert der Trennlinien (färbt dunkler als die Fläche)
	wheelRimInner    = 0.90
	wheelRimOuter    = 0.99
	hubBorder        = 0.18
)

// Abdeckung 0..1 aus einem Abstand zur Kante (positiv = innen), über etwa ein Pixel weich
func coverage(distance, pixel float64) float64 {
	return math.Max(0, math.Min(1, distance/pixel+0.5))
}

func wheelPixel(img *image.NRGBA, x, y int, gray uint8, alpha float64) {
	img.SetNRGBA(x, y, color.NRGBA{R: gray, G: gray, B: gray, A: uint8(math.Round(alpha * 255))})
}

// polar: u nach rechts, v nach oben, beide -1..1
func eachPixel(size int, fn func(x, y int, u, v, pixel float64)) {
	half := float64(size) / 2
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (half - float64(y) - 0.5) / half
			fn(x, y, u, v, 1/half)
		}
	}
}

func renderWheelSlice(size int) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	halfAngle := math.Pi / wheelSlices
	eachPixel(size, func(x, y int, u, v, pixel float64) {
		r := math.Hypot(u, v)
		angle := math.Abs(math.Atan2(u, v)) // 0 = oben
		side := r * math.Sin(halfAngle-angle)
		if angle > math.Pi/2 {
			side = -1
		}
		edge := math.Min(side, wheelRadius-r)
		alpha := coverage(edge, pixel)
		gray := uint8(255)
		if edge < wheelBorder {
			gray = wheelBorderLevel
		}
		wheelPixel(img, x, y, gray, alpha)
	})
	return img
}

func renderWheelRim(size int) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	eachPixel(size, func(x, y int, u, v, pixel float64) {
		r := math.Hypot(u, v)
		wheelPixel(img, x, y, 255, coverage(math.Min(r-wheelRimInner, wheelRimOuter-r), pixel))
	})
	return img
}

func renderWheelHub(size int) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	eachPixel(size, func(x, y int, u, v, pixel float64) {
		r := math.Hypot(u, v)
		gray := uint8(255)
		if r > 1-hubBorder {
			gray = wheelBorderLevel
		}
		wheelPixel(img, x, y, gray, coverage(0.95-r, pixel))
	})
	return img
}

// Dreieck mit Spitze nach unten (v = -0.9), Grundlinie oben (v = 0.9), grauer Rand
func renderWheelPointer(size int) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	const top, tip, halfWidth = 0.9, -0.9, 0.7
	slope := math.Hypot(halfWidth, top-tip)
	eachPixel(size, func(x, y int, u, v, pixel float64) {
		// Abstand zu den drei Kanten (positiv = innen)
		toTop := top - v
		toSide := ((v-tip)*halfWidth - math.Abs(u)*(top-tip)) / slope
		edge := math.Min(toTop, toSide)
		gray := uint8(255)
		if edge < 0.15 {
			gray = wheelBorderLevel
		}
		wheelPixel(img, x, y, gray, coverage(edge, pixel))
	})
	return img
}
