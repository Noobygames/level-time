// Flights sammelt die selbst gemessenen Flugzeiten aus den SavedVariables einer WoW-Installation und schreibt sie
// als Assist/FlightTimesData.lua, damit alle Spieler sie als Startwerte bekommen (wie tools/records die
// Speedrun-Rekorde). Dazu lädt es die Flugstrecken aus den Spieldaten (wago.tools) und schreibt sie mit der aus
// den Messungen gelernten Fluggeschwindigkeit je Flavor nach Assist/FlightPathsData/<flavor>.lua, dazu die
// Schiffs- und Zeppelin-Rundkurse der Classic-Clients nach Assist/TransportData/<flavor>.lua.
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
	transportsDir := flag.String("transports", "Assist/TransportData", "Ordner für die Schiffs- und Zeppelin-Rundkurse")
	instancesDir := flag.String("instances", "Assist/InstanceData", "Ordner für die Instanz-Stammdaten je Flavor")
	mapCoordsDir := flag.String("mapcoords", "Assist/MapCoordsData", "Ordner für die Kartenbereiche (Weltkoordinaten) je Flavor")
	flag.Parse()

	if *wowDir == "" {
		fmt.Fprintln(os.Stderr, "Fehler: bitte -wow oder WOW_DIR setzen")
		os.Exit(1)
	}
	if err := run(*wowDir, *out, *pathsDir, *transportsDir, *instancesDir, *mapCoordsDir); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
}

func run(wowDir, out, pathsDir, transportsDir, instancesDir, mapCoordsDir string) error {
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
	return writePaths(snapshot, pathsDir, transportsDir, instancesDir, mapCoordsDir, date)
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
// schreibt eine Datei je Flavor; dazu die Transport-Rundkurse der Classic-Flavors.
func writePaths(snapshot *Snapshot, dir, transportsDir, instancesDir, mapCoordsDir, date string) error {
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
		var transports *TransportPaths
		if paths[flavor], transports, err = client.Taxi(build); err != nil {
			return fmt.Errorf("%s: %w", flavor, err)
		}
		if TransportFlavors[flavor] {
			if err := writeTransports(transportsDir, flavor, transports, date); err != nil {
				return err
			}
		}
		if err := writeInstances(client, instancesDir, flavor, build, date); err != nil {
			return err
		}
		if err := writeMapCoords(client, mapCoordsDir, flavor, build, date); err != nil {
			return err
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

func writeTransports(dir, flavor string, transports *TransportPaths, date string) error {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	path := filepath.Join(dir, flavor+".lua")
	err := writeFile(path, func(file *os.File) error { return WriteTransportsLua(file, flavor, transports, date) })
	if err == nil {
		fmt.Printf("Transporte %s: %d Rundkurse, Build %s\n", flavor, len(transports.ByID), transports.Build)
	}
	return err
}

// writeInstances lädt Level, Reset und Gruppengröße der Instanzen eines Flavors und schreibt Assist/InstanceData/<flavor>.lua.
func writeInstances(client *wagoClient, dir, flavor, build, date string) error {
	if dir == "" {
		return nil
	}
	instances, missing, err := client.Instances(build, flavor)
	if err != nil {
		return fmt.Errorf("%s: %w", flavor, err)
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	path := filepath.Join(dir, flavor+".lua")
	err = writeFile(path, func(file *os.File) error { return WriteInstancesLua(file, flavor, instances, date) })
	if err == nil {
		fmt.Printf("Instanzen %s: %d Karten, %d mit Level-Bereich, Build %s\n", flavor, len(instances.Modes),
			len(instances.Levels), instances.Build)
		if len(missing) > 0 {
			fmt.Printf("  ohne Karte (kein Level-Bereich): %v\n", missing)
		}
	}
	return err
}

// writeMapCoords lädt die Weltbereiche der Karten eines Flavors und schreibt Assist/MapCoordsData/<flavor>.lua.
func writeMapCoords(client *wagoClient, dir, flavor, build, date string) error {
	if dir == "" {
		return nil
	}
	coords, err := client.MapCoords(build)
	if err != nil {
		return fmt.Errorf("%s: %w", flavor, err)
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	path := filepath.Join(dir, flavor+".lua")
	err = writeFile(path, func(file *os.File) error { return WriteMapCoordsLua(file, flavor, coords, date) })
	if err == nil {
		fmt.Printf("Kartenbereiche %s: %d Karten, Build %s\n", flavor, len(coords.Areas), coords.Build)
	}
	return err
}
