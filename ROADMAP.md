# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## Geplant: Spieldaten von wago.tools (November 2026)

Quelle: DB2-Tabellen der Clients als CSV von wago.tools (`/db2/<Tabelle>/csv?build=<Version>`, neuester Build je Produkt aus `/api/builds`: `wow`, `wow_classic_era`, `wow_anniversary`, `wowf` = Forever), wie die Flugstrecken (458, `tools/flights/wago.go`). Spieldaten von Blizzard, keine fremde Datenbank. Nicht in den Client-Daten (serverseitig): Quest-Level/-Belohnungen, Questgeber, NPC-/Mob-Standorte und -Level, Beutetabellen. Generierte Dateien je Flavor mit frühem `return` in fremden Flavors (nur eine Tabelle im Speicher). Reihenfolge = Priorität.

- [ ] 460. **Instanz-Stammdaten: Level-Bereich, Reset, Gruppengröße** (S–M): `LFGDungeons` (Name, Era/TBC mit `MinLevel`/`MaxLevel`, Typ), `MapDifficulty` (`ResetInterval`, `MaxPlayers`, `LockID`), Zuordnung über Map-ID. Nutzen: passende Dungeons zum eigenen Level (Hinweis/Tooltip), Reset-Intervall und Gruppengröße in Instanz-Statistik und Historie. Retail/Forever ohne Level-Spalten: dort nur Reset/Größe.
- [ ] 461. **Welt-/Kartenkoordinaten umrechnen (`UiMapAssignment`)** (S–M, Infrastruktur): Bereiche `UiMin`/`UiMax` ↔ `Region` je `UiMapID` als generierte Daten plus `Lib`-Helfer `WorldToMap`/`MapToWorld`. Nutzer: Distanz-Schätzung der Flugzeiten in Yards statt Karteneinheiten, Anleger und Transportpositionen (459), Karten-Pins. Nur wo `C_Map.GetWorldPosFromMapPos` fehlt oder offline gerechnet wird.
- [ ] 462. **Flugpunkt-Namen in allen Sprachen (`TaxiNodes`)** (S): `TaxiNodes.Name_lang` je Sprache (wago.tools-Parameter für die Locale prüfen) beim `make flights` mitnehmen; alte Messungen unter Namen (`LevelTimerStatsDB.flightTimes`, `FlightTimesData.names`) direkt auf nodeIDs umschreiben, auch ohne beide Knoten auf einer offenen Karte. Danach `names` im Daten-Export abbauen.
- [ ] 463. **Gegenstands- und Fraktions-Stammdaten für Auswertungen** (S–M): `ItemSparse` (Verkaufspreis, Qualität, Itemlevel) und `Faction` (Name, Eltern-Fraktion) offline für Auswertungen und Exporte (Beute-Journal-Wert ohne `GetItemInfo`-Cache, Fraktionsnamen in Historie/CSV). Nur wenn die In-Game-API nicht reicht; Datenmenge (ItemSparse groß) vorher prüfen, ggf. nur benötigte IDs.

## Geplant: Wettbewerbsanalyse (November 2026)

Quelle: Quellcode von rund 30 Addons gelesen (nur Ansätze übernommen, kein Code; Lizenzen beachten), dazu CurseForge-Seiten und die Regeln auf speedrun.com. Komfort: Leatrix Plus (3.3.5-Port), Questie, RXPGuides, Guidelime, Plumber, Mapster, MoveAny, BlizzMove. Statistik: XPLedger (engster Konkurrent, Retail/Forever/Era/MoP), XToLevel, Experiencer, Rested, DataStore, Accountant Classic, Deathlog, Hardcore, NovaInstanceTracker, SavedInstances, LvlHistory. Speedrun: Sprint (vormals ForeverTimer), OnlySplits, Chromely, Earned: Self Found, SelfFound Tracker, Speed Splits, Forever Journey Log, Hardcore Deathrace. Stream/Ziele: Hardcore (Zarant), UltraHardcore, HC Challenge Wheel, FateLocked, Bingo/TiffBingo, FarmIt, Farming Bar, Cerealize. Alle API-Angaben stammen aus fremdem Code und sind vor dem Bau gegen die Blizzard-Doku je Client zu prüfen (CLAUDE.md); „im Spiel prüfen“ heißt `/dump` nötig.

Reihenfolge = Priorität: Korrektheit, Komfort, Statistik, Speedrun, Level Time Goals, Stream-Funktionen von Level Time, neue Addons.

Bewusst nicht: „Twitch Plays“ (Eingaben von außen verstoßen gegen die Regeln), LiveSplit-Autosplitter per Speicherlesen (Warden/AGB), Questdatenbanken und fremde Flugzeiten-Datenbanken (Pflegeaufwand, Lizenzen; mitgeliefert werden nur eigene Flugmessungen, 364), komplette Leveling-Guides (RXP/Questie decken das ab).

### v2.32: „1 Addon, das viele ablöst“ (Konkurrenzanalyse, Threat & Lueur-Sparkles)

- [ ] 451. **Minimap-Button-Sammler (HidingBar / MBB Light)** (M): Sammelt Minimap-Symbole fremder Addons (`Minimap:GetChildren()`) in einer einklappbaren Leiste am Minimap-Rand (`Assist/MinimapBar.lua`; ersetzt MinimapButtonBag/HidingBar).
- [ ] 452. **Nahkampf- & Fernkampf-Schwungbalken (WeaponSwingTimer Light)** (M): Kompakte Swing-Timer-Leiste für Haupthand, Nebenhand sowie Zauberstab/Automatischen Schuss in Classic Era und Forever (`Assist/SwingTimer.lua` über `UnitAttackSpeed` und Zauber-/Kampf-Events; ersetzt WeaponSwingTimer).
- [ ] 453. **Gruppen-Questabgleich (Party Quest Sync)** (M): Synchronisiert angenommene Quests und Ziel-Fortschritte innerhalb der Gruppe über `C_ChatInfo.SendAddonMessage` (`PARTY`) und zeigt im Questlog/Tooltip den Fortschritt der Gruppenmitglieder an (ersetzt den Gruppen-Sync von Questie).
- [ ] 456. **Multi-Layer-2D-Effekt-Engine für Beute-Glitzer (`UI/LootSparkle.lua`)** (M): Ausbau von `UI/LootSparkle.lua` zu einer mehrschichtigen 2D-Render-Engine mit wählbaren Effekt-Stilen (`lootSparkleStyle`: `aura` [Halo + rotierende Bögen + kreisende Funken], `beam` [vertikale Lichtsäule + Bodenring], `sigil` [gegenläufig rotierendes Siegel], `ripple` [pulsierende Bodenwellen], `sparkle` [aufsteigender Funkenschwarm], `subtle` [dezenter Schein]):
  - Dunkler Kontrast-Bodenschatten (`BLEND`-Schicht mit ~30 % Schwarz-Alpha unter den `ADD`-Lichtschichten), damit helle Effekte auf Schnee oder Sand nie auswaschen.
  - Dynamische Zustands-Übergänge: weiches Einblenden mit Zusammenziehen beim Erscheinen (`arrive`), Aufblitzen (`flash`) und beschleunigte Rotation/Wellen beim Erreichen der Interaktionsreichweite (`READY`), ruhiges Atmen außer Reichweite (`FAR`), entsättigter/eingefrorener Zustand bei gesperrten Objekten (`LOCKED`) sowie kurzes Ausklingen (`ghost`) beim Verschwinden.

### v2.22: Speedrun (Priorität 3)

- [ ] 292. **LiveSplit-Export und Webseite** (S–M): Splits als LiveSplit-`.lss` (XML mit Segmenten, PB, Bestsegmenten) im Kopierfenster, niemand sonst kann das; dazu eine statische Seite (GitHub Pages), die `LT1:`- oder CSV-Text einliest und Graphen zeigt (Sprint `SprintStats.html`). **Teilweise erledigt: LiveSplit-Teil: `Speedrun/LiveSplitExport.lua` baut eine `.lss` im Format von LiveSplits `XMLRunSaver` (Run version 1.7.0, je Level ein Segment mit SplitTime „Personal Best“ kumuliert und BestSegmentTime über alle eigenen Charaktere ohne Teil-Level, .NET-TimeSpan als RealTime und GameTime) aus den zusammenhängend abgeschlossenen Leveln des eingeloggten Charakters; `/lt runs lss` und Button „LiveSplit“ in Speedrun > Läufe öffnen sie im Kopierfenster. Offen: statische Seite (GitHub Pages), die `LT1:`- oder CSV-Text einliest und Graphen zeigt.**

### v2.24: Quest-Unterstützung (Ideen aus RestedXP, eigener Code, keine RXP-Daten; Lizenz CC BY-NC-SA)

- [ ] 352. **Questreste in den Taschen** (S–M): Items, die laut gelernten Daten oder `GetQuestLogSpecialItemInfo` zu einer abgegebenen oder abgebrochenen Quest gehörten (`QUEST_TURNED_IN`, `QUEST_REMOVED`), als Verkaufs-/Löschvorschlag beim Händler (`Merchant.lua`) oder bei vollen Taschen (`GearWarnings`); Löschen nur per Klick (`DeleteCursorItem` braucht eine Spieleraktion). Plus eigene Müll-Markierung je Item (Modifier-Rechtsklick). **Teilweise: Erledigt: `Assist/QuestLeftovers.lua` (questLeftovers, Komfort > Quests): Gegenstände abgegebener/abgebrochener Quests (gelernt über `QuestMobs.ItemsOf` und das gemerkte Quest-Item, `character.questSpecialItems`), die keine offene Quest braucht, als Hinweis beim Händler und als Zusatz im Hinweis „Taschen fast voll“; verkaufte Reste werden vergessen. Offen: eigene Müll-Markierung je Item (Modifier-Rechtsklick) und ein Lösch-Knopf (`DeleteCursorItem` nur per Klick); Folgequests, die denselben Gegenstand brauchen, kennt der Client vorher nicht.**

### Neue Addons und Werkzeuge (Ideen)

- [ ] 318. **Level Time Companion** (L): Go-Programm wie `tools/`; liest SavedVariables nach `/reload`/Logout und liefert lokale HTML-Seiten als OBS-Browserquelle (Historie, Splits, Ziele, Recap). Rückweg: schreibt eine im `.toc` vorhandene Daten-Datei, die das Addon beim `/reload` einliest (Kanalpunkte als Ziele, WeakAuras-Companion-Muster). Später Live-Daten über einen Pixelstreifen (Cerealize; Blizzard-Richtlinie vorher prüfen).
- [ ] 319. **Self-Found-Nachweis** (L): Eigenes Addon auf `LevelTimerAPI`: Verstoßliste (nur abgeschlossene Handel, Auktionen, Post-Entnahmen, Gildenbank), Prüfsummenkette (290), Ruhe- und Instanzgrenzen (287), Zeugen über Gilde/Gruppe („36/42 h von 27 Spielern bezeugt“, Earned). Ziel: Forever und Retail, wo Hardcore/UHC am gesperrten Kampflog scheitern.
- [ ] 320. **Hardcore-Sicherheitspaket** (M): Atem (255), Notfall bei wenig Leben (267), Liste gefährlicher Gegner mit Bildschirmblitz (RXP), Fallschaden- und Elite-Warnung; als Komfort-Gruppe in Level Time oder eigenes Addon.
- [ ] 321. **Twink-Übersicht** (M): Ruhe-Schätzung (271), Gold, `/played`, zuletzt gesehen, „Wer ist dran?“-Liste, Hinweis auf lange nicht gespielte Charaktere (Rested, DataStore). Nutzt `LevelTimerStatsDB`.
- [ ] 322. **Dungeon-Splits** (M–L): Zeit ab erster Bewegung in der Instanz bis zum letzten Boss, Split je Boss (`ENCOUNTER_END`), Bestzeit je Route und Instanz-Kopie (Speed Splits, Murlocs). Baut auf `Instances`/`InstanceCopy`.
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
