# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird gelöscht (Spur steht im Commit und im Changelog). Nummern laufen über alle Versionen weiter; nächste freie Nummer: **505**.

## Funde aus dem Spieltest (November 2026)

Reihenfolge = Priorität: Korrektheit zuerst, dann Funktionen. Bestätigt: Nachrufkarte (314) samt Kopieren funktioniert.

### Korrektheit

- [ ] 482. **Schiffs- und Zeppelinzeiten lernen nicht** (M): Auch nach mehrmaligem Mitfahren zeigen `Assist/TransportTimes.lua`/`TransportPaths.lua` keine Abfahrtszeiten (440, 459; offene Checks 222 und 226). Client notieren, Debug-Log `440.transport.state` auswerten (Strecke erkannt? Phase/Periode gemessen? Anleger-Position passend?) und die Messung bzw. Zuordnung der Fahrt zur Strecke korrigieren. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Transport-Erkennung, `C_Map`-Positionen auf dem Schiff). **Teilweise: Ursache im Code: eine Periode entstand nur aus zwei Fahrten derselben Richtung binnen 30 min (`MAX_PERIOD`), und die Ankunft galt schon beim Ladebild (Zielanleger mitten im Anflug, Fahrzeit zu kurz). Jetzt: Ankunft = Transport hat angelegt (Spieler steht, Position `STAND_MIN_SECONDS` ruhig), `rideTime` Anleger zu Anleger; daraus über die Rundkurse (`TransportPaths.Speed`) eine geschätzte Periode schon nach einer Fahrt, die als Vorgabe auch Fahrten Stunden später zählbar macht (`MAX_ESTIMATE_CYCLES`). Neue Debug-Zeilen `no departure at`, `player moving`, `arrival at`, `estimate`; Check `440.transport.state` mit `moving`, `ride.still`, `rideTime`. Offen: im Spiel bestätigen (Check 222/226), v.a. ob `IsPlayerMoving` auf dem fahrenden Transport false liefert und die Anleger einem Rundkurs zugeordnet werden.**

### Funktionen

- [ ] 502. **Addon „OnForAll“ ansehen** (S): Funktionen des Addons prüfen, Lücken und Ideen als Roadmap-Punkte anlegen (genauer Name klären).


## Geplant: Instanzen, Quests, Klassen (November 2026)

Ideensammlung für Level Time und Level Time Goals. Gegner- und Questdaten werden selbst gepflegt (Grundstock der Instanz-Quests per einmaligem Import, danach eigene Sammlung über den Extractor; keine fremden Datenbanken, siehe „Bewusst nicht“ unten); API-Annahmen vor dem Bau je Client prüfen.

- [ ] 490. **Boss-Mechaniken im Tooltip** (L): Bei Bossen in Dungeons und Raids im Tooltip die 1–2 wichtigsten Kernmechaniken zeigen (Ausweichen/Laufen, z. B. rotierende Strahlen; Unterbrechbares; Überlebensmechaniken). Raid-Bosse mit komplexeren Encountern ebenso. Boss-Daten aus 483.
- [ ] 491. **Trash-Fähigkeiten im Tooltip** (L): Wichtige Fähigkeiten normaler Gegner in Instanzen und Raids hervorheben: Schadensspitzen/AoE (rausgehen, Schildwall), Heiler, Zauber, die unterbrochen werden müssen; gefährlicher Raid-Trash eingeschlossen. Teilt Datenformat und Tooltip-Code mit 490.
- [ ] 494. **Feature-Parität mit Questie und RestedXP** (M): Funktionen beider Addons systematisch gegen Level Time abgleichen (Vorgaben vom Spieler), Lücken als Roadmap-Punkte anlegen und eigene Alleinstellungsmerkmale festhalten.
- [ ] 495. **Klassenquests und Level-Up-Fenster** (M–L): Datenbasis der Klassenquests (Stufe 10, 20, 30 …, auch WoW Forever) mit Belohnungen (Item-IDs für Chat-Links) und Fähigkeiten. Im Level-Up-Fenster Hinweis auf Klassenlehrer/Klassenquests; eigene Einblendung für Spieler, die das Fenster abgeschaltet haben. Fenster schließt sich standardmäßig nicht mehr selbst; Checkbox im Fenster (gleich mit der Einstellung) schaltet das automatische Schließen wieder ein.
- [ ] 498. **Glitzern nur an einer Leiche** (S, Forever): Das Glitzern hängt am Soft-Interact-Ziel, das Spiel liefert davon genau eins (das nächste); weitere Leichen in der Nähe glitzern nicht (Spieltest Schlingendorntal, Raptoren). Prüfen per `lootSparkles.target` (`cvars.SoftTargetInteractRange` = wirklich 60?, `inRange`), ob das Spiel die Reichweite kappt. Mehrere Leichen gleichzeitig gingen nur mit einer anderen Quelle (tote Einheiten haben keine Namensplakette); Quelle suchen oder als Grenze dokumentieren.

## Geplant: Wettbewerbsanalyse (November 2026)

Quelle: Quellcode von rund 30 Addons gelesen (nur Ansätze übernommen, kein Code; Lizenzen beachten), dazu CurseForge-Seiten und die Regeln auf speedrun.com. Komfort: Leatrix Plus (3.3.5-Port), Questie, RXPGuides, Guidelime, Plumber, Mapster, MoveAny, BlizzMove. Statistik: XPLedger (engster Konkurrent, Retail/Forever/Era/MoP), XToLevel, Experiencer, Rested, DataStore, Accountant Classic, Deathlog, Hardcore, NovaInstanceTracker, SavedInstances, LvlHistory. Speedrun: Sprint (vormals ForeverTimer), OnlySplits, Chromely, Earned: Self Found, SelfFound Tracker, Speed Splits, Forever Journey Log, Hardcore Deathrace. Stream/Ziele: Hardcore (Zarant), UltraHardcore, HC Challenge Wheel, FateLocked, Bingo/TiffBingo, FarmIt, Farming Bar, Cerealize. Alle API-Angaben stammen aus fremdem Code und sind vor dem Bau gegen die Blizzard-Doku je Client zu prüfen (CLAUDE.md); „im Spiel prüfen“ heißt `/dump` nötig.

Reihenfolge = Priorität: Korrektheit, Komfort, Statistik, Speedrun, Level Time Goals, Stream-Funktionen von Level Time, neue Addons.

Bewusst nicht: „Twitch Plays“ (Eingaben von außen verstoßen gegen die Regeln), LiveSplit-Autosplitter per Speicherlesen (Warden/AGB), komplette Questdatenbanken und fremde Flugzeiten-Datenbanken (Pflegeaufwand, Lizenzen; mitgeliefert werden nur eigene Flugmessungen, 364), komplette Leveling-Guides (RXP/Questie decken das ab).

### v2.32: „1 Addon, das viele ablöst“ (Konkurrenzanalyse, Threat & Lueur-Sparkles)


### v2.22: Speedrun (Priorität 3)

- [ ] 292. **LiveSplit-Export und Webseite** (S–M): Splits als LiveSplit-`.lss` (XML mit Segmenten, PB, Bestsegmenten) im Kopierfenster, niemand sonst kann das; dazu eine statische Seite (GitHub Pages), die `LT1:`- oder CSV-Text einliest und Graphen zeigt (Sprint `SprintStats.html`). **Teilweise erledigt: LiveSplit-Teil: `Speedrun/LiveSplitExport.lua` baut eine `.lss` im Format von LiveSplits `XMLRunSaver` (Run version 1.7.0, je Level ein Segment mit SplitTime „Personal Best“ kumuliert und BestSegmentTime über alle eigenen Charaktere ohne Teil-Level, .NET-TimeSpan als RealTime und GameTime) aus den zusammenhängend abgeschlossenen Leveln des eingeloggten Charakters; `/lt runs lss` und Button „LiveSplit“ in Speedrun > Läufe öffnen sie im Kopierfenster. Offen: statische Seite (GitHub Pages), die `LT1:`- oder CSV-Text einliest und Graphen zeigt.**

### v2.24: Quest-Unterstützung (Ideen aus RestedXP, eigener Code, keine RXP-Daten; Lizenz CC BY-NC-SA)


### Neue Addons und Werkzeuge (Ideen)

- [ ] 318. **Level Time Companion** (L): Go-Programm wie `tools/`; liest SavedVariables nach `/reload`/Logout und liefert lokale HTML-Seiten als OBS-Browserquelle (Historie, Splits, Ziele, Recap). Rückweg: schreibt eine im `.toc` vorhandene Daten-Datei, die das Addon beim `/reload` einliest (Kanalpunkte als Ziele, WeakAuras-Companion-Muster). Später Live-Daten über einen Pixelstreifen (Cerealize; Blizzard-Richtlinie vorher prüfen).
- [ ] 319. **Self-Found-Nachweis** (L): Eigenes Addon auf `LevelTimerAPI`: Verstoßliste (nur abgeschlossene Handel, Auktionen, Post-Entnahmen, Gildenbank), Prüfsummenkette (290), Ruhe- und Instanzgrenzen (287), Zeugen über Gilde/Gruppe („36/42 h von 27 Spielern bezeugt“, Earned). Ziel: Forever und Retail, wo Hardcore/UHC am gesperrten Kampflog scheitern.
- [ ] 320. **Hardcore-Sicherheitspaket** (M): Atem (255), Notfall bei wenig Leben (267), Liste gefährlicher Gegner mit Bildschirmblitz (RXP), Fallschaden- und Elite-Warnung; als Komfort-Gruppe in Level Time oder eigenes Addon.
- [ ] 321. **Twink-Übersicht** (M): Ruhe-Schätzung (271), Gold, `/played`, zuletzt gesehen, „Wer ist dran?“-Liste, Hinweis auf lange nicht gespielte Charaktere (Rested, DataStore). Nutzt `LevelTimerStatsDB`.
- [ ] 322. **Dungeon-Splits** (M–L): Zeit ab erster Bewegung in der Instanz bis zum letzten Boss, Split je Boss (`ENCOUNTER_END`), Bestzeit je Route und Instanz-Kopie (Speed Splits, Murlocs). Baut auf `Instances`/`InstanceCopy`. Spieltest November 2026: Zeit bis Boss 1/2/3 und Instanz-Speedrun mit Splits auch in der Instanz-Ansicht (484), Boss-Daten aus 483.
- [ ] 323. **Gilden-Bingo und Events** (L): Gemeinsame Bingo-Karten und Ziele über Addon-Nachrichten, Rangliste je Event, Offiziere legen die Karte fest. Baut auf 305 und 311.
- [ ] 324. **Farm-Tracker** (M): Gold/h, Itemwert (Händlerpreis, Auctionator-Preis falls geladen), Ruf/h, Währungen je Farm-Session (LvlHistory, sesh).
- [ ] 325. **Karte aufdecken und Koordinaten** (L): Unerkundete Gebiete sichtbar wie Mapster (`C_MapExplorationInfo.GetExploredMapTextures` plus Kacheldaten je Karte, auch Forever); Aufwand vor allem das Erzeugen der Daten.

### Performance

CPU-Last senken, ohne eine Funktion wegzunehmen (Speicher darf dafür steigen). Grundlage: Performance-Review der Event-Verteilung, Aufgaben, Aura-Scans und Fenster.

Runde 2 nach echten Profiler-Daten (`/lt debug perf`, WoW Forever, 33 min, Stand vor dem Layout-Umbau; zusammen rund 6,5 s CPU in 1978 s):

### UI-Overhaul

Grundlage: UX-Audit aus dem Code (Architektur A1–A4, Reihenfolge in 7 Schritten) und Recherche bei anderen Addons (Details!, ElvUI, WeakAuras, Bartender, Blizzards Edit Mode). Ziel: gutes Aussehen, gute Bedienung, viel Anpassung, mehr Anzeigearten.

## v2.9: Funde aus dem Review

Aus dem Review des Branches `feature/alert-style` (fünf Prüfer: Clean Code, Wiederverwendbarkeit, Bugs im neuen Code, Bugs im Kern, UX/Texte; Funde nur gelesen, nicht im Spiel getestet). „im Spiel prüfen“ = der Prüfer war unsicher, siehe `ManualToCheck.md`. Bereits behoben: Texturpfad in `Alerts.lua` (einfache Backslashes, der Banner wäre unsichtbar gewesen).

### Wiederverwendbarkeit (Vorbereitung weiterer Addons)

Alle Dateien teilen eine `ns`-Tabelle; Einstellungen und Sprache werden über `ns.db`, `ns.L`, `ns.Set` gelesen, nichts ist von `addonName` abhängig. `Lib/` ist fachlich weitgehend sauber. Reihenfolge von klein und risikoarm zu groß.

- [ ] 235. **`Shared/` auslagern und ein zweites Addon anbinden** (L): `Lib/` und die gelösten Teile nach `Shared/` (`Init(addonId, host)`, `host = { addonId, displayName, getSettings, set, L, iconPath }`), Aliase `ns.Widgets = Shared.Widgets` während der Umstellung; `.toc`, Installer (`assetDirs`), `.pkgmeta` und Stub-Lader anpassen (Client-Neustart). Einbindung per Git-Submodul oder `externals` des Packagers, nicht per Kopie (Drift). Vorher: Namenskonvention für gemeinsame Locale-Schlüssel, Locale-Test für die Shared-Texte, `alert*`- und `minimap`-Schlüssel account-kompatibel halten.

## v2.8.1: Stabilität

Aus dem Deep Review aller Funktionen (10 Prüfer je Bereich plus API-Abgleich gegen Blizzards UI-Quellen für Retail 12.1, Classic Era 1.15.9, TBC Anniversary 2.5.6 und WoW Forever 1.60.1; jeder Fund von zwei Gegenprüfern bestätigt). Sortiert nach Schwere.

## v2.8: Dungeons

Schwerpunkt: Leveln in Dungeons auswerten und das Instanzlimit im Blick behalten.

## v2.7: Aufräumen

Schwerpunkt: Struktur und Wartbarkeit nach dem Code- und Architektur-Review, ohne neue Funktionen. Jeder Schritt ändert kein Verhalten; die Tests sichern das ab.

## v2.6: Leveln ohne Umwege

Schwerpunkt: Komfort-Funktionen, die beim Leveln Klicks sparen, und Werte, die zeigen, wo Zeit verloren geht. Jede Komfort-Funktion ist einzeln schaltbar (Standard aus) und liegt im neuen Reiter „Komfort“; gedrückte Umschalttaste setzt die Automatik im Moment aus. Nutzt jemand schon Leatrix Plus o.ä., bleiben unsere Schalter einfach aus. Alle API-Annahmen werden vor der Umsetzung je Client gegen die Doku geprüft.

## v2.5: Streaming

Schwerpunkt: Werte, die Zuschauer im Spielbild sehen und verstehen. Addons haben kein Netzwerk und schreiben keine Dateien, alles muss also im Spiel sichtbar sein.

### Projekt und Verbreitung

- [ ] 20. **Uploads aktivieren** (S): CurseForge aktiv (Projekt 1721235, Secret `CF_API_KEY`). Wago-Projekte angelegt: Level Time `rNkgkwNa` (addons.wago.io/addons/level-time), Level Time Goals `v63QzDGb` (addons.wago.io/addons/level-time-goals), `## X-Wago-ID` in beiden `.toc`. Offen: Secret `WAGO_API_TOKEN` (Wago > Account > API Keys), WoWInterface-ID in die `.toc` und Secret `WOWI_API_TOKEN`.
- [ ] 496. **Vikunja als Taskboard prüfen** (S–M): Große Markdown-Roadmaps zu lesen und zu überschreiben kostet viele Token. Vikunja (self-hosted, Go + Vue.js) bietet MCP, damit Agenten gefiltert abfragen (z. B. nur Top-Priorität) statt ganze Dateien zu laden. Bewerten und ggf. Roadmap dorthin umziehen.
