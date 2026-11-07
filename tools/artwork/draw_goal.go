package main

import (
	"image"
	"math"
)

// Zeichnung für Level Time Goals: goldener Ring wie bei Level Time, darin eine Zielflagge auf einem Hügel.
var (
	flagColor     = rgb{0.92, 0.27, 0.22}
	flagColorDark = rgb{0.68, 0.14, 0.14}
)

const (
	goalCenter     = 256.0
	goalRingOuter  = 196.0
	goalRingInner  = 164.0
	poleLeft       = 224.0
	poleRight      = 240.0
	poleTop        = 118.0
	poleBottom     = 372.0
	flagTipX       = 372.0
	flagTopY       = 124.0
	flagBottomY    = 238.0
	moundBase      = 430.0
	moundHeight    = 80.0
	moundHalfWidth = 110.0
)

// inFlag: Wimpel als Dreieck von der Stange nach rechts, Spitze auf halber Höhe
func inFlag(x, y float64) bool {
	if x < poleRight || x > flagTipX {
		return false
	}
	t := (x - poleRight) / (flagTipX - poleRight)
	mid := (flagTopY + flagBottomY) / 2
	halfHeight := (flagBottomY - flagTopY) / 2 * (1 - t)
	return math.Abs(y-mid) <= halfHeight
}

// inMound: Hügel als obere Hälfte einer Ellipse; der Ring verdeckt den unteren Rand
func inMound(x, y float64) bool {
	dx := (x - 232) / moundHalfWidth
	dy := (y - moundBase) / moundHeight
	return y <= moundBase && dx*dx+dy*dy <= 1
}

func sampleGoal(x, y float64, s style) (rgb, float64) {
	c, alpha := rgb{}, 0.0
	if s.background {
		c, alpha = mix(bgInner, bgOuter, math.Hypot(x-256, y-256)/360), 1
	}
	dist := math.Hypot(x-goalCenter, y-goalCenter)
	switch {
	case dist <= goalRingOuter && dist >= goalRingInner:
		return gold(y, goalCenter-goalRingOuter, goalCenter+goalRingOuter), 1
	case dist < goalRingInner:
		switch {
		case inRoundRect(x, y, poleLeft, poleTop, poleRight, poleBottom, 5):
			return gold(y, poleTop, poleBottom), 1
		case inFlag(x, y):
			return mix(flagColor, flagColorDark, (y-flagTopY)/(flagBottomY-flagTopY)), 1
		case inMound(x, y):
			return gold(y, moundBase-moundHeight, moundBase), 1
		}
		return mix(faceColor, bgInner, dist/goalRingInner*0.6), 1
	}
	return c, alpha
}

func renderGoal(size int, s style) *image.NRGBA {
	return renderWith(size, func(x, y float64) (rgb, float64) { return sampleGoal(x, y, s) })
}
