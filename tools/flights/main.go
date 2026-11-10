// Flights sammelt die selbst gemessenen Flugzeiten aus den SavedVariables einer WoW-Installation und schreibt sie
// als Assist/FlightTimesData.lua, damit alle Spieler sie als Startwerte bekommen (wie tools/records die
// Speedrun-Rekorde). Dazu lädt es die Flugstrecken aus den Spieldaten (wago.tools) und schreibt sie mit der aus
// den Messungen gelernten Fluggeschwindigkeit je Flavor nach Assist/FlightPathsData/<flavor>.lua.
// Liest nur, schreibt nie nach WTF. Aufruf über "make flights".
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"time"
)

func main() {
	wowDir := flag.String("wow", os.Getenv("WOW_DIR"), "WoW-Installation (Ordner mit _retail_, _forever_, ...)")
	out := flag.String("out", "Assist/FlightTimesData.lua", "Ziel-Datei (Lua)")
	pathsDir := flag.String("paths", "Assist/FlightPathsData", "Ordner für die Flugstrecken je Flavor (leer = nicht laden)")
	flag.Parse()

	if *wowDir == "" {
		fmt.Fprintln(os.Stderr, "Fehler: bitte -wow oder WOW_DIR setzen")
		os.Exit(1)
	}
	if err := run(*wowDir, *out, *pathsDir); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
}

func run(wowDir, out, pathsDir string) error {
	snapshot, err := Collect(wowDir, os.Stdout)
	if err != nil {
		return err
	}
	date := time.Now().Format("2006-01-02")
	if err := writeFile(out, func(file *os.File) error { return snapshot.WriteLua(file, date) }); err != nil {
		return err
	}
	fmt.Println("Flugzeiten:", out)
	if pathsDir == "" {
		return nil
	}
	return writePaths(snapshot, pathsDir, date)
}

func writeFile(path string, write func(*os.File) error) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()
	return write(file)
}

// writePaths lädt die Strecken je Flavor, lernt die Geschwindigkeit aus den Messungen (sonst geliehen) und
// schreibt eine Datei je Flavor.
func writePaths(snapshot *Snapshot, dir, date string) error {
	client := newWagoClient()
	builds, err := client.LatestBuilds()
	if err != nil {
		return err
	}
	flavors := make([]string, 0, len(Products))
	for flavor := range Products {
		flavors = append(flavors, flavor)
	}
	sort.Strings(flavors)
	paths := map[string]*Paths{}
	speeds := map[string]*Speed{}
	for _, flavor := range flavors {
		build := builds[Products[flavor]]
		if build == "" {
			return fmt.Errorf("wago.tools: kein Build für %s (%s)", flavor, Products[flavor])
		}
		if paths[flavor], err = client.Paths(build); err != nil {
			return fmt.Errorf("%s: %w", flavor, err)
		}
		speeds[flavor] = MeasuredSpeed(snapshot.Maps[flavor], paths[flavor])
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	for _, flavor := range flavors {
		speed := speeds[flavor]
		if lender := BorrowSpeed[flavor]; speed == nil && speeds[lender] != nil {
			borrowed := *speeds[lender]
			borrowed.BorrowedFrom = lender
			speed = &borrowed
		}
		path := filepath.Join(dir, flavor+".lua")
		err := writeFile(path, func(file *os.File) error {
			return WritePathsLua(file, flavor, paths[flavor], speed, date)
		})
		if err != nil {
			return err
		}
		fmt.Printf("Flugstrecken %s: %d Strecken, Build %s, %s\n", flavor, len(paths[flavor].Legs), paths[flavor].Build,
			describeSpeed(speed))
	}
	return nil
}

func describeSpeed(speed *Speed) string {
	if speed == nil {
		return "ohne Geschwindigkeit (erst nach eigenem Flug)"
	}
	text := fmt.Sprintf("%.2f Yards/s aus %d Strecken", speed.YardsPerSecond, speed.Samples)
	if speed.BorrowedFrom != "" {
		text += " (geliehen von " + speed.BorrowedFrom + ")"
	}
	return text
}
