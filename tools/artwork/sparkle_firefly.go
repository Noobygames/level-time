package main

import (
	"image"
	"math"
)

// Textur des Stils Glühwürmchen (Roadmap 469): ein Punkt mit weißglühendem Kern und weichem Hof in einer Textur.
// Das Addon nutzt sie zweimal je Tier: groß als warmer Hof, klein und aufgehellt als heißer Kern.
const (
	fireflyCoreSigma = 0.11
	fireflyHaloSigma = 0.34
	fireflyHaloShare = 0.55
)

func renderSparkleFirefly(size int) *image.NRGBA {
	img := newSparkleImage(size)
	half := float64(size) / 2.0
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			u := (float64(x) + 0.5 - half) / half
			v := (float64(y) + 0.5 - half) / half
			r := math.Hypot(u, v)
			core := math.Exp(-math.Pow(r/fireflyCoreSigma, 2))
			halo := fireflyHaloShare * math.Exp(-math.Pow(r/fireflyHaloSigma, 2))
			setSparklePixel(img, x, y, math.Min(1, core+halo)*(1-smoothstep(0.6, 0.95, r)))
		}
	}
	return img
}
