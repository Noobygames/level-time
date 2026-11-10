package main

import (
	"image"
	"image/color"
	"math"
)

// Prozedurale 2D-Lichttexturen für Beute-Glitzer (Roadmap 455).
// Alle Texturen sind 32-Bit-NRGBA mit reinweißer RGB-Farbe (255, 255, 255),
// damit WoW SetVertexColor sie im Blend-Modus ADD beliebig einfärben kann.
// Die Helligkeit und Weichheit liegt im vorberechneten Alphakanal.
const sparkleTexSize = 128 // Zweierpotenz für WoW

func newSparkleImage(size int) *image.NRGBA {
	return image.NewNRGBA(image.Rect(0, 0, size, size))
}

func setSparklePixel(img *image.NRGBA, x, y int, alpha float64) {
	if alpha < 0 {
		alpha = 0
	} else if alpha > 1 {
		alpha = 1
	}
	a := uint8(math.Round(alpha * 255))
	img.SetNRGBA(x, y, color.NRGBA{R: 255, G: 255, B: 255, A: a})
}

// SparkleHalo: Weicher radialer Lichthof als Glühscheibe (r von 0 im Zentrum bis 1 am Rand; alpha = (1 - r)^2.2).
func renderSparkleHalo(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			alpha := 0.0
			if r < 1.0 {
				alpha = math.Pow(1.0-r, 2.2)
			}
			setSparklePixel(img, x, y, alpha)
		}
	}
	return img
}

// SparkleRing: Scharfer Lichtring mit Radius r0 = 0.72 und Gauß-Profil exp(-((r-0.72)/0.07)^2), weich auslaufend ab r >= 0.98.
func renderSparkleRing(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	const r0 = 0.72
	const sigma = 0.07
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			var alpha float64
			if r >= 1.0 {
				alpha = 0
			} else {
				alpha = math.Exp(-math.Pow((r-r0)/sigma, 2))
				if r >= 0.98 {
					alpha *= (1.0 - r) / (1.0 - 0.98)
				}
			}
			setSparklePixel(img, x, y, alpha)
		}
	}
	return img
}

// SparkleArcs: Zwei symmetrisch rotierende Kometenbögen auf Radius r0 = 0.74, ca. 110 Grad Bogenlänge,
// heller Kopf mit weichem Auslauf entlang des Winkels, radiale Dicke ~0.06.
func renderSparkleArcs(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	const (
		r0        = 0.74
		sigmaR    = 0.06
		arcSpan   = 110.0 * math.Pi / 180.0
		headFade  = 14.0 * math.Pi / 180.0
		arcOffset = 10.0 * math.Pi / 180.0
	)
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			if r >= 0.98 || r <= 0.40 {
				setSparklePixel(img, x, y, 0)
				continue
			}
			theta := math.Atan2(v, u)
			// Modulo Pi für 2-fache Rotationssymmetrie (zwei gegenüberliegende Bögen)
			phi := math.Mod(theta+2*math.Pi, math.Pi)
			dPhi := phi - arcOffset
			if dPhi < 0 || dPhi > arcSpan {
				setSparklePixel(img, x, y, 0)
				continue
			}

			// Radiales Gauß-Profil
			radial := math.Exp(-math.Pow((r-r0)/sigmaR, 2))

			// Winkel-Verlauf: Kopf hell, weich nach hinten auf 0 abfallend
			t := dPhi / arcSpan
			angular := math.Pow(1.0-t, 1.8)
			if dPhi < headFade {
				angular *= math.Sin((dPhi / headFade) * (math.Pi / 2))
			}

			alpha := radial * angular
			setSparklePixel(img, x, y, alpha)
		}
	}
	return img
}

// SparkleFlare: 4-strahliger Linsenblitz mit hellem Kern exp(-(r/0.18)^2),
// horizontalen und vertikalen Strahlen exp(-(pos/0.06)^2) * (1-|dist|)^2.5 sowie dezenten Diagonalstrahlen.
func renderSparkleFlare(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			if math.Abs(u) > 0.97 || math.Abs(v) > 0.97 {
				setSparklePixel(img, x, y, 0)
				continue
			}
			r := math.Hypot(u, v)

			// Heller Kern
			core := math.Exp(-math.Pow(r/0.18, 2))

			// Horizontale und vertikale Strahlen
			rayH := math.Exp(-math.Pow(v/0.06, 2)) * math.Pow(math.Max(0, 1.0-math.Abs(u)), 2.5)
			rayV := math.Exp(-math.Pow(u/0.06, 2)) * math.Pow(math.Max(0, 1.0-math.Abs(v)), 2.5)

			// Dezente diagonale Strahlen (um 45 Grad rotiert)
			du := (u + v) / math.Sqrt2
			dv := (v - u) / math.Sqrt2
			diag1 := math.Exp(-math.Pow(dv/0.065, 2)) * math.Pow(math.Max(0, 1.0-math.Abs(du)), 3.0)
			diag2 := math.Exp(-math.Pow(du/0.065, 2)) * math.Pow(math.Max(0, 1.0-math.Abs(dv)), 3.0)
			diag := 0.35 * (diag1 + diag2)

			alpha := math.Min(1.0, core+rayH+rayV+diag)
			setSparklePixel(img, x, y, alpha)
		}
	}
	return img
}

// SparkleBeam: Vertikaler Lichtstrahl, horizontal zentriert exp(-(nx/0.22)^2),
// am hellsten im unteren Bereich (ny um 0.7..0.85), sanft nach oben (ny = -1) und zur Unterkante (ny = 1) auslaufend.
func renderSparkleBeam(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	const nyPeak = 0.78
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			nx := (float64(x) + 0.5 - half) / half
			ny := (float64(y) + 0.5 - half) / half
			if math.Abs(nx) > 0.97 || ny < -0.97 || ny > 0.97 {
				setSparklePixel(img, x, y, 0)
				continue
			}

			// Horizontales Gauß-Profil
			pillarH := math.Exp(-math.Pow(nx/0.22, 2))

			// Vertikales Profil: Peak bei nyPeak, stetiger Verlauf zu den Rändern
			var vert float64
			if ny <= nyPeak {
				// Von ny = -1 bis nyPeak
				t := (ny - (-1.0)) / (nyPeak - (-1.0))
				if t > 0 {
					vert = math.Sin(math.Max(0, math.Min(1, t)) * (math.Pi / 2))
				}
			} else {
				// Von nyPeak bis ny = 1
				b := (ny - nyPeak) / (1.0 - nyPeak)
				vert = math.Cos(math.Max(0, math.Min(1, b)) * (math.Pi / 2))
			}

			alpha := pillarH * vert
			setSparklePixel(img, x, y, alpha)
		}
	}
	return img
}

// SparkleSigil: Geometrischer Runenkreis mit Außenring (r = 0.78), Innenring (r = 0.52),
// eingeschriebenem 8-Zack-Stern und 8 Runenspeichen zwischen 0.52 und 0.78 sowie 8 leuchtenden Knoten auf dem Ring.
func renderSparkleSigil(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			if r >= 0.96 {
				setSparklePixel(img, x, y, 0)
				continue
			}

			theta := math.Atan2(v, u)

			// 1. Außenring (r = 0.78)
			outerRing := math.Exp(-math.Pow((r-0.78)/0.03, 2))

			// 2. Innenring (r = 0.52)
			innerRing := math.Exp(-math.Pow((r-0.52)/0.025, 2))

			// 3. 8 Speichen zwischen Innen- und Außenring
			dAngle := math.Remainder(theta, math.Pi/4)
			arcDist := r * math.Abs(dAngle)
			spokeLine := math.Exp(-math.Pow(arcDist/0.022, 2))
			spokeWindow := 0.0
			if r >= 0.50 && r <= 0.80 {
				spokeWindow = math.Exp(-math.Pow((r-0.65)/0.11, 4))
			}
			spokes := spokeLine * spokeWindow

			// 4. Eingeschriebener 8-Zack-Stern
			dist1 := math.Abs(math.Abs(u)+math.Abs(v)-0.78) / math.Sqrt2
			star1 := math.Exp(-math.Pow(dist1/0.022, 2))

			ru := (u + v) / math.Sqrt2
			rv := (v - u) / math.Sqrt2
			dist2 := math.Abs(math.Abs(ru)+math.Abs(rv)-0.78) / math.Sqrt2
			star2 := math.Exp(-math.Pow(dist2/0.022, 2))
			star := 0.7 * math.Max(star1, star2)

			// 5. 8 leuchtende Knoten auf dem Außenring bei k * pi/4
			dr := r - 0.78
			nodeArcDist := 0.78 * dAngle
			distNode := math.Hypot(dr, nodeArcDist)
			nodes := math.Exp(-math.Pow(distNode/0.045, 2))

			total := 0.85*outerRing + 0.75*innerRing + 0.7*spokes + star + nodes
			alpha := math.Min(1.0, total)
			setSparklePixel(img, x, y, alpha)
		}
	}
	return img
}
