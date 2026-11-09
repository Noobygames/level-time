# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## Geplant: Wettbewerbsanalyse (November 2026)

Quelle: Quellcode von rund 30 Addons gelesen (nur Ansätze übernommen, kein Code; Lizenzen beachten), dazu CurseForge-Seiten und die Regeln auf speedrun.com. Komfort: Leatrix Plus (3.3.5-Port), Questie, RXPGuides, Guidelime, Plumber, Mapster, MoveAny, BlizzMove. Statistik: XPLedger (engster Konkurrent, Retail/Forever/Era/MoP), XToLevel, Experiencer, Rested, DataStore, Accountant Classic, Deathlog, Hardcore, NovaInstanceTracker, SavedInstances, LvlHistory. Speedrun: Sprint (vormals ForeverTimer), OnlySplits, Chromely, Earned: Self Found, SelfFound Tracker, Speed Splits, Forever Journey Log, Hardcore Deathrace. Stream/Ziele: Hardcore (Zarant), UltraHardcore, HC Challenge Wheel, FateLocked, Bingo/TiffBingo, FarmIt, Farming Bar, Cerealize. Alle API-Angaben stammen aus fremdem Code und sind vor dem Bau gegen die Blizzard-Doku je Client zu prüfen (CLAUDE.md); „im Spiel prüfen“ heißt `/dump` nötig.

Reihenfolge = Priorität: Korrektheit, Komfort, Statistik, Speedrun, Level Time Goals, Stream-Funktionen von Level Time, neue Addons.

Bewusst nicht: „Twitch Plays“ (Eingaben von außen verstoßen gegen die Regeln), LiveSplit-Autosplitter per Speicherlesen (Warden/AGB), Questdatenbanken und fremde Flugzeiten-Datenbanken (Pflegeaufwand, Lizenzen; mitgeliefert werden nur eigene Flugmessungen, 364), komplette Leveling-Guides (RXP/Questie decken das ab).

### v2.32: „1 Addon, das viele ablöst“ (Konkurrenzanalyse, Threat & Lueur-Sparkles)

- [ ] 444. **Objekt- und Ressourcen-Erkennung auf Lueur-Niveau (ohne Minimap-Icons)** (M): Ausbau von `Assist/LootTarget.lua` und `Assist/LootSparkles.lua` um alle Erkennungs-Mechanismen aus `Lueur`, ausdrücklich ohne Minimap-Tracking (`NodeScan`/`Nodes`):
  - Erweiterte Zeiger-Abfrage `SetUnitCursorTexture(probe, unit, nil, true)` mit vollständiger Datei-ID-, Pfad- und Atlas-Zuordnung für Erze (`Mine`), Kräuter (`GatherHerbs`), alle Quest-Zeiger (`Quest`, `QuestInteract`, `CampaignQuest`, `LegendaryQuest`, `Important`, `Recurring`, `Wrapper` inkl. `TurnIn`), Truhen (`PickLock`, `LootAll`, `Pickup`), Angel-Schwimmer (`Fishing`, `FishingCursor`) sowie explizitem Ausschluss von NPC-Diensten (`Mail`, `Speak`, `Buy`, `Trainer`, `Taxi`, `Innkeeper`, `Repair`, `Stablemaster`).
  - Truhen & Container ohne eigenen Zeiger (Standard-Zahnrad `Interact`) erkennen: (a) beim Plündern über `GetLootSourceInfo(slot)` die GameObject-ID aus der GUID (`GameObject-0-...-<id>-...`) accountweit in `LevelTimerStatsDB.containers` lernen, (b) über sprachspezifische Truhen-Schlüsselwörter im Objektnamen (Truhe, Kiste, Fass, Kassette / Chest, Crate, Barrel, Footlocker, Box).
  - Dreistufige Questobjekt-Erkennung: 1. `C_QuestLog.UnitIsRelatedToActiveQuest("softinteract")` (Forever/Retail), 2. aus dem Welt-Tooltip gelernte Zuordnung Objektname → aktiver Questtitel (`C_TooltipInfo.GetWorldCursor`), 3. Zieltext- und Wortstamm-Abgleich nur für Sammel-/Objekt-Ziele (`item`/`object`, nie für Kill-Ziele wie „Murloc getötet“ bei „Murlochütte“) mit Filter für häufige Adjektive.
  - Berufs-Filter (`lootSparkleHideUntrained`): Erze und Kräuter optional ausblenden, wenn Bergbau bzw. Kräuterkunde nicht gelernt ist.
  - Angel-Schwimmer (`lootSparkleBobber`): Während des Angel-Kanalisierens (`UnitChannelInfo("player")`, Icon `136245` / `Trade_Fishing` bzw. Objekt-ID `35591`) `SoftTargetInteractRange` und `nameplateGameObjectMaxDistance` auf 60 m sowie `SoftTargetInteractRangeIsHard = 0` setzen, damit auch weit ausgeworfene Schwimmer eine Plakette erhalten.
- [ ] 450. **Level Time Post (Postal Light)** (M): „Alles öffnen“-Button im Briefkasten (leert Post im 0,25-s-Takt, überspringt Nachnahme/COD, stoppt bei vollen Taschen), Alt-Klick zum sofortigen Anhängen von Taschen-Items an offene Briefe sowie ein Empfänger-Dropdown mit allen eigenen Twinks aus `LevelTimerStatsDB`, Gildenmitgliedern und Freunden (`Assist/Mail.lua`; ersetzt Postal).
- [ ] 451. **Minimap-Button-Sammler (HidingBar / MBB Light)** (M): Sammelt Minimap-Symbole fremder Addons (`Minimap:GetChildren()`) in einer einklappbaren Leiste am Minimap-Rand (`Assist/MinimapBar.lua`; ersetzt MinimapButtonBag/HidingBar).
- [ ] 452. **Nahkampf- & Fernkampf-Schwungbalken (WeaponSwingTimer Light)** (M): Kompakte Swing-Timer-Leiste für Haupthand, Nebenhand sowie Zauberstab/Automatischen Schuss in Classic Era und Forever (`Assist/SwingTimer.lua` über `UnitAttackSpeed` und Zauber-/Kampf-Events; ersetzt WeaponSwingTimer).
- [ ] 453. **Gruppen-Questabgleich (Party Quest Sync)** (M): Synchronisiert angenommene Quests und Ziel-Fortschritte innerhalb der Gruppe über `C_ChatInfo.SendAddonMessage` (`PARTY`) und zeigt im Questlog/Tooltip den Fortschritt der Gruppenmitglieder an (ersetzt den Gruppen-Sync von Questie).
- [ ] 454. **Zonen-Abgaberouten-Bündler (Smart Turn-In Hub)** (S–M): Gruppiert abgabefertige Quests in `UI/QuestViews.lua` nach gelernten Abgabe-NPCs und Teilzonen (`QuestNpcs.lua`), damit auf einen Blick sichtbar ist, in welchem Hub sich mehrere Abgaben gleichzeitig lohnen.
- [ ] 455. **Prozedurale 2D-Lichttexturen für Beute-Glitzer (`tools/artwork`)** (S–M): In `tools/artwork/draw.go` (`make artwork`) eigene 32-Bit-TGA-Texturen (Zweierpotenzen, komplett eigenständig generiert) für mehrschichtige Lichteffekte unter `Media/` erzeugen:
  - `SparkleHalo.tga` (weicher radialer Lichthof für Grundschein und dunklen Kontrast-Bodenschatten),
  - `SparkleRing.tga` (scharfer Lichtring für Fokus-Kreise und auslaufende Bodenwellen),
  - `SparkleArcs.tga` (geschwungene Kometen-/Lichtbögen auf einer Kreisbahn für Rotation),
  - `SparkleFlare.tga` (mehrstrahliger Stern-/Linsenblitz für das helle Zentrum),
  - `SparkleBeam.tga` (vertikaler Lichtstrahl mit weichem Verlauf nach oben und zur Seite),
  - `SparkleSigil.tga` (geometrischer Runen-/Ornamentring für gegenläufige Siegel-Effekte).
- [ ] 456. **Multi-Layer-2D-Effekt-Engine für Beute-Glitzer (`UI/LootSparkle.lua`)** (M): Ausbau von `UI/LootSparkle.lua` zu einer mehrschichtigen 2D-Render-Engine mit wählbaren Effekt-Stilen (`lootSparkleStyle`: `aura` [Halo + rotierende Bögen + kreisende Funken], `beam` [vertikale Lichtsäule + Bodenring], `sigil` [gegenläufig rotierendes Siegel], `ripple` [pulsierende Bodenwellen], `sparkle` [aufsteigender Funkenschwarm], `subtle` [dezenter Schein]):
  - Dunkler Kontrast-Bodenschatten (`BLEND`-Schicht mit ~30 % Schwarz-Alpha unter den `ADD`-Lichtschichten), damit helle Effekte auf Schnee oder Sand nie auswaschen.
  - Dynamische Zustands-Übergänge: weiches Einblenden mit Zusammenziehen beim Erscheinen (`arrive`), Aufblitzen (`flash`) und beschleunigte Rotation/Wellen beim Erreichen der Interaktionsreichweite (`READY`), ruhiges Atmen außer Reichweite (`FAR`), entsättigter/eingefrorener Zustand bei gesperrten Objekten (`LOCKED`) sowie kurzes Ausklingen (`ghost`) beim Verschwinden.
- [ ] 457. **Kategoriefarben, Silhouettenmaske & Effekt-Vorschau für Beute-Glitzer** (S–M):
  - Eigene Farben je Objektkategorie statt Einheitsgelb (Erz = Orange, Kraut = Grün, Questobjekt = Gold, Truhe = Hellblau/Cyan, Angel-Schwimmer = Korallenrot, Leiche = Hellgold; mit aufgehelltem Kern im Zentrum).
  - Optionale Spieler-Silhouettenmaske (`lootSparkleSilhouette` über `CreateMaskTexture`), die den Lichtschein hinter der eigenen Spielfigur ausblendet, wenn man direkt vor dem Objekt steht.
  - Auswahl von Effekt-Stil, Intensität und Kategoriefarben samt Live-Vorschau in Komfort > Oberfläche > Beute-Glitzer.

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

## v2.18: Qualitätssicherung

- [] 250. \*_Hinweise-Bleiben-Stehen_ (S): Hinweise wie z.B. sitzenbleiben können bestehen bleiben, obwohl man nicht mehr steht, isst und ggf. sogar im Kampf ist. Sicherstellen, dass diese Hinweise sauber abgeräumt werden.

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

- [ ] 20. **Uploads aktivieren** (S): CurseForge aktiv (Projekt 1721235, Secret `CF_API_KEY`). Offen: Wago- und WoWInterface-ID in die `.toc`, Secrets `WAGO_API_TOKEN` und `WOWI_API_TOKEN`.
