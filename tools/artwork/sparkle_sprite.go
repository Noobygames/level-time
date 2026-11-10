package main

import (
	"image"
	"math"
)

// Pixel-Art-Sprites (Roadmap 472): Blöcke mit harten Kanten wie in einem 8-Bit-Spiel. Jeder gefüllte Texel bekommt
// seinen Grauwert aus der Lage im Block (dunkler Rand, helle Kante links oben, dunklere rechts unten, Fläche), dazu
// einen weichen dunklen Schatten um die Form, damit die Pixel auch auf Schnee und Sand stehen.
const (
	spriteLumBorder  = 0.18
	spriteLumLight   = 1.0
	spriteLumBody    = 0.88
	spriteLumDark    = 0.6
	spriteShadowPeak = 0.5
)

// edgeDistance: Abstand in Texeln (bis limit) zum nächsten leeren Texel in dieser Richtung, limit + 1 wenn keins
func (m mask) edgeDistance(x, y, dx, dy, limit int) int {
	for d := 1; d <= limit; d++ {
		if m.at(x+dx*d, y+dy*d) < 0.5 {
			return d
		}
	}
	return limit + 1
}

// spriteImage färbt die harte Maske m (Kantenbreite edge Texel) ein und legt den weichen Schatten dahinter
func spriteImage(m mask, edge, shadowRadius int) *image.NRGBA {
	shadow := m.morph(shadowRadius/2, true).blur(shadowRadius)
	img := image.NewNRGBA(image.Rect(0, 0, m.w, m.h))
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			if m.at(x, y) < 0.5 {
				img.SetNRGBA(x, y, nrgba(0, uint8(math.Round(math.Min(1, shadow.at(x, y)*spriteShadowPeak)*255))))
				continue
			}
			left, up := m.edgeDistance(x, y, -1, 0, 2*edge), m.edgeDistance(x, y, 0, -1, 2*edge)
			right, down := m.edgeDistance(x, y, 1, 0, 2*edge), m.edgeDistance(x, y, 0, 1, 2*edge)
			lum := spriteLumBody
			switch {
			case min(min(left, up), min(right, down)) <= edge:
				lum = spriteLumBorder
			case left <= 2*edge || up <= 2*edge:
				lum = spriteLumLight
			case right <= 2*edge || down <= 2*edge:
				lum = spriteLumDark
			}
			img.SetNRGBA(x, y, nrgba(uint8(math.Round(lum*255)), 255))
		}
	}
	return img
}

// squaresMask: Quadrate (Mittelpunkte in -1 bis 1, Halbkante half), ohne Glättung
func squaresMask(size int, centers [][2]float64, half float64) mask {
	m := newMask(size, size)
	h := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u, v := (float64(x)+0.5-h)/h, (float64(y)+0.5-h)/h
			for _, c := range centers {
				if math.Abs(u-c[0]) <= half && math.Abs(v-c[1]) <= half {
					m.a[y*size+x] = 1
				}
			}
		}
	}
	return m
}

// SparkleBlock: ein einzelner Pixelblock (32 Texel, Block 20 Texel groß in der Mitte, 6 Texel Platz für den Schatten)
const (
	blockTexSize = 32
	blockHalf    = 0.625
)

func renderSparkleBlock() *image.NRGBA {
	return spriteImage(squaresMask(blockTexSize, [][2]float64{{0, 0}}, blockHalf), 2, 4)
}

// Bodenring aus Pixelblöcken: ringSquares Quadrate auf einem Kreis; Phase 0 = gerade, 1 = ungerade Nummern
const (
	ringSquares    = 12
	ringRadius     = 0.78
	ringSquareHalf = 0.11
)

func renderSparkleBlockRing(size, phase int) *image.NRGBA {
	var centers [][2]float64
	for i := phase; i < ringSquares; i += 2 {
		angle := float64(i) / ringSquares * 2 * math.Pi
		centers = append(centers, [2]float64{ringRadius * math.Sin(angle), -ringRadius * math.Cos(angle)})
	}
	return spriteImage(squaresMask(size, centers, ringSquareHalf), 2, 5)
}

// SparkleStar8: pixeliges Funkel-Plus (8 x 8 Zellen, Mitte dick, vier Arme), Zelle 6 Texel, 8 Texel Rand
const (
	starTexSize = 64
	starCell    = 6
	starMargin  = 8
)

var starPattern = [8]string{
	"...XX...",
	"...XX...",
	"..XXXX..",
	"XXXXXXXX",
	"XXXXXXXX",
	"..XXXX..",
	"...XX...",
	"...XX...",
}

func renderSparkleStar() *image.NRGBA {
	m := newMask(starTexSize, starTexSize)
	for row, line := range starPattern {
		for col, ch := range line {
			if ch != 'X' {
				continue
			}
			for y := 0; y < starCell; y++ {
				for x := 0; x < starCell; x++ {
					m.a[(starMargin+row*starCell+y)*starTexSize+starMargin+col*starCell+x] = 1
				}
			}
		}
	}
	return spriteImage(m, 2, 4)
}
