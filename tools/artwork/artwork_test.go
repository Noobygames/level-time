package main

import (
	"bytes"
	"encoding/binary"
	"testing"
)

func TestIconIsTransparentAroundTheWatch(t *testing.T) {
	icon := render(iconSize, iconStyle)
	if a := icon.NRGBAAt(0, 0).A; a != 0 {
		t.Errorf("Ecke sollte transparent sein, Alpha = %d", a)
	}
	if a := icon.NRGBAAt(iconSize/2, iconSize*9/16).A; a != 255 {
		t.Errorf("Mitte sollte deckend sein, Alpha = %d", a)
	}
}

func TestLogoHasNoTransparency(t *testing.T) {
	logo := render(32, logoStyle)
	if a := logo.NRGBAAt(0, 0).A; a != 255 {
		t.Errorf("Logo-Hintergrund sollte deckend sein, Alpha = %d", a)
	}
}

func TestWriteTGA(t *testing.T) {
	icon := render(8, iconStyle)
	var buf bytes.Buffer
	if err := writeTGA(&buf, icon); err != nil {
		t.Fatal(err)
	}
	data := buf.Bytes()
	if len(data) != 18+8*8*4 {
		t.Fatalf("Größe = %d", len(data))
	}
	if data[2] != 2 || data[16] != 32 || data[17] != 0x08 {
		t.Errorf("Header = %v", data[:18])
	}
	if w, h := binary.LittleEndian.Uint16(data[12:]), binary.LittleEndian.Uint16(data[14:]); w != 8 || h != 8 {
		t.Errorf("Maße = %dx%d", w, h)
	}
}

func TestGoalArtwork(t *testing.T) {
	if a := renderGoal(32, logoStyle).NRGBAAt(0, 0).A; a != 255 {
		t.Errorf("Logo-Hintergrund sollte deckend sein, Alpha = %d", a)
	}
	if a := renderGoal(iconSize, iconStyle).NRGBAAt(0, 0).A; a != 0 {
		t.Errorf("Icon-Ecke sollte transparent sein, Alpha = %d", a)
	}
}

func TestGlintIsBrightInTheMiddleAndTransparentAtTheEdges(t *testing.T) {
	glint := renderGlint(glintSize)
	if a := glint.NRGBAAt(glintSize/2, glintSize/2).A; a != 255 {
		t.Errorf("Mitte sollte voll hell sein, Alpha = %d", a)
	}
	for _, p := range [][2]int{{0, 0}, {glintSize - 1, 0}, {0, glintSize / 2}, {glintSize / 2, glintSize - 1}} {
		if a := glint.NRGBAAt(p[0], p[1]).A; a != 0 {
			t.Errorf("Rand %v sollte transparent sein, Alpha = %d", p, a)
		}
	}
	// Strahl: auf der Achse heller als daneben
	if on, off := glint.NRGBAAt(glintSize*3/4, glintSize/2).A, glint.NRGBAAt(glintSize*3/4, glintSize/2+8).A; on <= off {
		t.Errorf("Strahl fehlt: auf der Achse %d, daneben %d", on, off)
	}
}

func TestBarTextures(t *testing.T) {
	for name, brightness := range barKinds {
		bar := renderBar(brightness)
		if bar.Bounds().Dx() != barTextureWidth || bar.Bounds().Dy() != barTextureHeight {
			t.Errorf("%s: falsche Größe %v", name, bar.Bounds())
		}
		if a := bar.NRGBAAt(0, barTextureHeight/2).A; a != 255 {
			t.Errorf("%s: nicht deckend (%d)", name, a)
		}
	}
	smooth := renderBar(barKinds["BarSmooth"])
	if top, bottom := smooth.NRGBAAt(0, 0).R, smooth.NRGBAAt(0, barTextureHeight-1).R; top <= bottom {
		t.Errorf("BarSmooth: oben %d nicht heller als unten %d", top, bottom)
	}
}
