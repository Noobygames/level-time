// Flights sammelt die selbst gemessenen Flugzeiten aus den SavedVariables einer WoW-Installation und schreibt sie
// als Assist/FlightTimesData.lua, damit alle Spieler sie als Startwerte bekommen (wie tools/records die
// Speedrun-Rekorde). Liest nur, schreibt nie nach WTF. Aufruf über "make flights".
package main

import (
	"flag"
	"fmt"
	"os"
	"time"
)

func main() {
	wowDir := flag.String("wow", os.Getenv("WOW_DIR"), "WoW-Installation (Ordner mit _retail_, _forever_, ...)")
	out := flag.String("out", "Assist/FlightTimesData.lua", "Ziel-Datei (Lua)")
	flag.Parse()

	if *wowDir == "" {
		fmt.Fprintln(os.Stderr, "Fehler: bitte -wow oder WOW_DIR setzen")
		os.Exit(1)
	}
	if err := run(*wowDir, *out); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	fmt.Println("Flugzeiten:", *out)
}

func run(wowDir, out string) error {
	snapshot, err := Collect(wowDir, os.Stdout)
	if err != nil {
		return err
	}
	file, err := os.Create(out)
	if err != nil {
		return err
	}
	defer file.Close()
	return snapshot.WriteLua(file, time.Now().Format("2006-01-02"))
}
