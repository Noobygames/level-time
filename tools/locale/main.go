// Locale schreibt Texte in die vier Sprachdateien (Locales/deDE.lua, enUS.lua, frFR.lua, esES.lua), ohne dass sie
// gelesen werden müssen (jede ist ~125 KB). Aufruf über "make locale ARGS=...":
//
//	-file texts.json   Einträge anhängen oder ersetzen
//	-remove KEY        Schlüssel aus allen vier Dateien löschen (mehrere mit Komma: A,B)
//	-dir Locales       Ordner mit den Sprachdateien (Standard: Locales)
//
// Eingabeformat (JSON, Klartext ohne Lua-Escapes, "\n" für Zeilenumbruch):
//
//	{ "MY_KEY": { "deDE": "...", "enUS": "...", "frFR": "...", "esES": "..." } }
package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

func main() {
	file := flag.String("file", "", "JSON-Datei mit neuen Texten")
	remove := flag.String("remove", "", "Schlüssel entfernen (Komma-getrennt)")
	dir := flag.String("dir", "Locales", "Ordner der Sprachdateien")
	flag.Parse()

	var err error
	switch {
	case *file != "":
		var data []byte
		if data, err = os.ReadFile(*file); err == nil {
			var entries []Entry
			if entries, err = ParseEntries(data); err == nil {
				err = Apply(*dir, entries)
			}
		}
	case *remove != "":
		err = Remove(*dir, strings.Split(*remove, ","))
	default:
		err = fmt.Errorf("-file oder -remove angeben")
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
}
