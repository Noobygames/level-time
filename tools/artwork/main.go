// Artwork erzeugt das CurseForge-Logo (PNG) und das Addon-Icon (TGA) aus derselben Zeichnung.
// Aufruf über "make artwork".
package main

import (
	"flag"
	"fmt"
	"image"
	"image/png"
	"os"
	"path/filepath"
)

const (
	logoSize = 512
	iconSize = 64 // Zweierpotenz für WoW; angezeigt werden ca. 16-20 px
)

func main() {
	logoPath := flag.String("logo", "curseforge/logo.png", "Ziel für das CurseForge-Logo (PNG)")
	iconPath := flag.String("icon", "Media/Icon.tga", "Ziel für das Addon-Icon (TGA)")
	previewPath := flag.String("preview", "", "Optional: Icon zusätzlich als PNG zum Ansehen")
	goalLogoPath := flag.String("goal-logo", "curseforge/streamgoal/logo.png", "Ziel für das Level-Time-Goals-Logo (PNG)")
	goalIconPath := flag.String("goal-icon", "StreamGoal/Media/Icon.tga", "Ziel für das Level-Time-Goals-Icon (TGA)")
	glintPath := flag.String("glint", "Media/Glint.tga", "Ziel für das Funkeln der Beute-Glitzer (TGA)")
	barsDir := flag.String("bars", "Media", "Ordner für die Balkentexturen (TGA)")
	wheelDir := flag.String("wheel", "StreamGoal/Media", "Ordner für die Teile des Glücksrads von Level Time Goals (TGA)")
	sparklesDir := flag.String("sparkles", "Media", "Ordner für die Beute-Glitzer-Effekttexturen (TGA)")
	flag.Parse()

	if err := run(*logoPath, *iconPath, *previewPath); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	if err := runGoal(*goalLogoPath, *goalIconPath); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	if err := runGlint(*glintPath); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	if err := runBars(*barsDir); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	if err := runWheel(*wheelDir); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	if err := runSparkles(*sparklesDir); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
}

func runSparkles(dir string) error {
	sparkles := []struct {
		name string
		img  *image.NRGBA
	}{
		{"SparkleHalo", renderSparkleHalo(sparkleTexSize)},
		{"SparkleRing", renderSparkleRing(sparkleTexSize)},
		{"SparkleArcs", renderSparkleArcs(sparkleTexSize)},
		{"SparkleFlare", renderSparkleFlare(sparkleTexSize)},
		{"SparkleBeam", renderSparkleBeam(sparkleTexSize)},
		{"SparkleSigil", renderSparkleSigil(sparkleTexSize)},
	}
	for _, s := range sparkles {
		path := filepath.Join(dir, s.name+".tga")
		img := s.img
		if err := writeFile(path, func(f *os.File) error { return writeTGA(f, img) }); err != nil {
			return err
		}
		fmt.Printf("Glitzer: %s\n", path)
	}
	return nil
}

func runWheel(dir string) error {
	parts := []struct {
		name string
		img  *image.NRGBA
	}{
		{"WheelSlice", renderWheelSlice(wheelSliceSize)},
		{"WheelRim", renderWheelRim(wheelSliceSize)},
		{"WheelHub", renderWheelHub(wheelHubSize)},
		{"WheelPointer", renderWheelPointer(wheelPointerSize)},
	}
	for _, part := range parts {
		path := filepath.Join(dir, part.name+".tga")
		img := part.img
		if err := writeFile(path, func(f *os.File) error { return writeTGA(f, img) }); err != nil {
			return err
		}
		fmt.Printf("Glücksrad: %s\n", path)
	}
	return nil
}

func runBars(dir string) error {
	for name, brightness := range barKinds {
		path := filepath.Join(dir, name+".tga")
		bar := renderBar(brightness)
		if err := writeFile(path, func(f *os.File) error { return writeTGA(f, bar) }); err != nil {
			return err
		}
		fmt.Printf("Balken: %s\n", path)
	}
	return nil
}

func runGlint(path string) error {
	glint := renderGlint(glintSize)
	if err := writeFile(path, func(f *os.File) error { return writeTGA(f, glint) }); err != nil {
		return err
	}
	fmt.Printf("Funkeln: %s\n", path)
	return nil
}

func run(logoPath, iconPath, previewPath string) error {
	logo := render(logoSize, logoStyle)
	if err := writeFile(logoPath, func(f *os.File) error { return png.Encode(f, logo) }); err != nil {
		return err
	}

	icon := render(iconSize, iconStyle)
	if err := writeFile(iconPath, func(f *os.File) error { return writeTGA(f, icon) }); err != nil {
		return err
	}

	if previewPath != "" {
		if err := writeFile(previewPath, func(f *os.File) error { return png.Encode(f, icon) }); err != nil {
			return err
		}
	}
	fmt.Printf("Logo: %s\nIcon: %s\n", logoPath, iconPath)
	return nil
}

func runGoal(logoPath, iconPath string) error {
	logo := renderGoal(logoSize, logoStyle)
	if err := writeFile(logoPath, func(f *os.File) error { return png.Encode(f, logo) }); err != nil {
		return err
	}
	icon := renderGoal(iconSize, iconStyle)
	if err := writeFile(iconPath, func(f *os.File) error { return writeTGA(f, icon) }); err != nil {
		return err
	}
	fmt.Printf("Level-Time-Goals-Logo: %s\nLevel-Time-Goals-Icon: %s\n", logoPath, iconPath)
	return nil
}

func writeFile(path string, encode func(*os.File) error) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	if err := encode(f); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}
