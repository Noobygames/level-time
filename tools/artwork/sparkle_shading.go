package main

import (
	"image"
	"math"
)

// Maskenwerkzeuge für die Formtexturen der Glitzer-Stile: aus einer Deckkraftmaske (0 bis 1) entstehen
// Körper mit Licht und Schatten (Bevel, Verlauf), ein dunkler weicher Umriss, ein Leuchtrand und ein heller Kern.

type mask struct {
	w, h int
	a    []float64
}

func newMask(w, h int) mask { return mask{w: w, h: h, a: make([]float64, w*h)} }

func maskOf(img *image.NRGBA) mask {
	b := img.Bounds()
	m := newMask(b.Dx(), b.Dy())
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			m.a[y*m.w+x] = float64(img.NRGBAAt(x, y).A) / 255
		}
	}
	return m
}

func (m mask) at(x, y int) float64 {
	if x < 0 || y < 0 || x >= m.w || y >= m.h {
		return 0
	}
	return m.a[y*m.w+x]
}

// blur: Gauß-Weichzeichner (sigma = radius / 2), getrennt in x und y
func (m mask) blur(radius int) mask {
	kernel := make([]float64, 2*radius+1)
	sigma := math.Max(float64(radius)/2.0, 0.5)
	for i := range kernel {
		d := float64(i - radius)
		kernel[i] = math.Exp(-d * d / (2 * sigma * sigma))
	}
	pass := func(in mask, horizontal bool) mask {
		out := newMask(in.w, in.h)
		for y := 0; y < in.h; y++ {
			for x := 0; x < in.w; x++ {
				sum, weight := 0.0, 0.0
				for i, k := range kernel {
					xx, yy := x, y
					if horizontal {
						xx += i - radius
					} else {
						yy += i - radius
					}
					weight += k
					sum += k * in.at(xx, yy)
				}
				out.a[y*in.w+x] = sum / weight
			}
		}
		return out
	}
	return pass(pass(m, true), false)
}

// morph: Maximum (grow) oder Minimum über eine Kreisscheibe
func (m mask) morph(radius int, grow bool) mask {
	out := newMask(m.w, m.h)
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			best := m.at(x, y)
			for dy := -radius; dy <= radius; dy++ {
				for dx := -radius; dx <= radius; dx++ {
					if dx*dx+dy*dy > radius*radius {
						continue
					}
					v := m.at(x+dx, y+dy)
					if grow && v > best || !grow && v < best {
						best = v
					}
				}
			}
			out.a[y*m.w+x] = best
		}
	}
	return out
}

// normalized: auf Höchstwert 1 skaliert
func (m mask) normalized() mask {
	peak := 0.0
	for _, a := range m.a {
		peak = math.Max(peak, a)
	}
	out := newMask(m.w, m.h)
	if peak == 0 {
		return out
	}
	for i, a := range m.a {
		out.a[i] = a / peak
	}
	return out
}

// whiteImage: weiße RGB-Farbe, Deckkraft aus der Maske (einfärbbar per SetVertexColor)
func (m mask) whiteImage() *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, m.w, m.h))
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			setSparklePixel(img, x, y, m.a[y*m.w+x])
		}
	}
	return img
}

// shadedImage: Deckkraft aus der Maske, Helligkeit (Grau) aus bright; SetVertexColor färbt den Körper ein,
// die Helligkeit bleibt als Licht und Schatten erhalten.
func (m mask) shadedImage(bright []float64) *image.NRGBA {
	img := image.NewNRGBA(image.Rect(0, 0, m.w, m.h))
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			i := y*m.w + x
			g := uint8(math.Round(math.Max(0, math.Min(1, bright[i])) * 255))
			a := uint8(math.Round(math.Max(0, math.Min(1, m.a[i])) * 255))
			img.SetNRGBA(x, y, nrgba(g, a))
		}
	}
	return img
}

// bevelLight: Licht von links oben auf die gewölbte Maske (Höhe = weichgezeichnete Maske) plus Verlauf von
// hell oben nach dunkler unten. Die Helligkeit liegt zwischen etwa 0.5 und 1.
func (m mask) bevelLight(radius int, vertical float64) []float64 {
	height := m.blur(radius)
	out := make([]float64, m.w*m.h)
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			gx := (height.at(x+1, y) - height.at(x-1, y)) / 2
			gy := (height.at(x, y+1) - height.at(x, y-1)) / 2
			lit := 0.6*gx + 0.8*gy // Normale zeigt gegen den Anstieg: Kanten links oben sind hell
			v := 1 - vertical*float64(y)/float64(m.h)
			out[y*m.w+x] = (0.86 + 2.4*float64(radius)*lit) * v
		}
	}
	return out
}
