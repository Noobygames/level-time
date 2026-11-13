# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## Funde aus dem Spieltest (November 2026)

Reihenfolge = Priorität: Korrektheit zuerst, dann Funktionen. Bestätigt: Nachrufkarte (314) samt Kopieren funktioniert.

### Korrektheit

- [ ] 479. **Kürschner: Leichen glitzern nicht** (S–M): Als Kürschner leuchten kürschnerbare Leichen nicht auf. `Assist/LootTarget.lua` erkennt Leichen nur über `isCorpseWithLoot` (`UnitIsDead` + `CanLootUnit`); eine leergeplünderte, aber kürschnerbare Leiche fällt dort heraus. Eigene Art (z.B. `LootTarget.SKIN`) bzw. Erweiterung von `CORPSE`, Erkennung über die Kürschner-Zeile im Einheiten-Tooltip (`C_TooltipInfo.GetUnit`, Era versteckter Tooltip wie `Lib/QuestTooltip.lua`) oder Unit-Flags, Schalter in `Assist/LootSparkles.lua` (`lootSparkleSkinning`). Nur mit erlerntem Kürschnern; gilt sinngemäß für Bergbau/Kräuterkunde an Leichen. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Tooltip-Zeile, `CanLootUnit`-Rückgabe nach dem Plündern); offene Frage als `DebugLog.AddCheck`.
- [ ] 480. **Twink-Knopf im Postfach: Vor- und Nachname in WoW Forever** (S): In Forever haben Charaktere Vor- und Nachnamen, der Twink-Knopf (`Assist/Mail.lua`, `Mail.FillRecipient`) trägt einen falschen Namen ein. Prüfen, woher `data.name` bzw. der Schlüssel `Name-Realm` (Muster `^([^-]+)%-(.+)$`) den Namen nimmt (`UnitName` liefert evtl. nur den Vornamen oder enthält ein Leerzeichen) und was das Empfängerfeld erwartet. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Forever-Zweig, `UnitFullName`/`GetUnitName`); Szenario `forever_*` mit Doppelnamen.
- [ ] 481. **Minimap-Knöpfe sammeln: fremde Knöpfe unbenutzbar** (M): Mit „Minimap-Knöpfe sammeln“ (451) waren die meisten fremden Addon-Knöpfe nicht mehr bedienbar. Commit 651a298 (sammelt nur noch sichtbare Knöpfe, kein Umbau im Kampf) kam nach dem Test: in `Assist/MinimapBar.lua` im Spiel erneut prüfen (Check 227) und untersuchen, warum gesammelte Knöpfe unbrauchbar werden (Klicks, Ziehen, `SetParent`/Strata/`EnableMouse`, LibDBIcon-Positions-Hooks, die den Knopf zurücksetzen). Gegen LibDBIcon-Knöpfe (Details, Questie) testen.
- [ ] 482. **Schiffs- und Zeppelinzeiten lernen nicht** (M): Auch nach mehrmaligem Mitfahren zeigen `Assist/TransportTimes.lua`/`TransportPaths.lua` keine Abfahrtszeiten (440, 459; offene Checks 222 und 226). Client notieren, Debug-Log `440.transport.state` auswerten (Strecke erkannt? Phase/Periode gemessen? Anleger-Position passend?) und die Messung bzw. Zuordnung der Fahrt zur Strecke korrigieren. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Transport-Erkennung, `C_Map`-Positionen auf dem Schiff).

### Funktionen

- [ ] 483. **Boss-Kills und Bosse je Instanz** (M–L): Boss-Kills je Instanz-Durchgang erfassen (`ENCOUNTER_END` mit Erfolg, Classic-Fallback über bekannte Boss-NPC-IDs aus dem Kill-Journal), Bossliste je Instanz kennen (Retail/Forever `EJ_*`/Encounter-Journal, sonst eigene Daten in `Assist/InstanceData`) und „Dungeon abgeschlossen“ melden, wenn der Endboss fällt. Grundlage für 484 und 322; nutzt `Tracking/InstanceInfo.lua`, `History/Instances.lua`, Instanz-Journal. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (`ENCOUNTER_END` in Era/TBC bei Dungeon-Bossen ist offen, Check 182; Encounter-Journal nicht in Era).
- [ ] 484. **Instanz-Ansicht überarbeiten** (M–L): `History/Instances.lua` und `Assist/InstanceReport.lua` je Durchgang mit XP/h, XP gesamt, Zeit und „Bosse x/y“; je Boss ein Symbol lebender Kopf bzw. Totenkopf, Tooltip mit Position im Dungeon und Kernmechanik (eigene, kurze Daten je Boss in `Assist/InstanceData`, alle vier Sprachen; Pflegeaufwand beachten). Zeit bis Boss 1/2/3 und Instanz-Speedrun mit Splits gehören zu 322. Baut auf 483.
- [ ] 485. **Zeit mit und ohne Buff-Food und Schlafsack** (S–M): Zähler für aktive Zeit mit/ohne „Satt“-Buff und mit/ohne Schlafsack-Buff (Forever, „Gut erholt“) je Level, Sitzung und Instanz, als Statzeilen und Historienspalten (Ablauf „Adding a stat“ in `core.md`). Buffs nur über `Lib/Auras.lua` (Satt-Erkennung wie `Assist/FoodTimer.lua`/`BuffReminder.lua`, Schlafsack wie `Assist/SleepTimer.lua`), Zeitaufteilung in `Tracking/TimeBreakdown.lua`. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Buff-Erkennung, geheime Auren im Kampf).
- [ ] 487. **Zauberrang in der Zauber-Historie** (S): `UI/SpellHistory.lua` zeigt zum Zauber den Rang („Rang 3“), z.B. über `C_Spell.GetSpellSubtext` bzw. `GetSpellSubtext`. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Retail hat keine Ränge, dann nichts anzeigen).
- [ ] 488. **Reagenzien-Erinnerung für Buffs und Wiederbelebung** (S–M): Bestand von Ankh, Symbol der Könige, Kerzen, Wiederbelebungsreagenzien usw. je Klasse anzeigen und bei knappem Vorrat warnen (wie die Munitionswarnung 241; Händlerhinweis in `Assist/Merchant.lua`), Klassenliste neben `Assist/ClassBuffs.lua`. Vor dem Bau gegen die Blizzard-Doku je Client prüfen (Item-IDs je Flavor, Retail ohne Reagenzien).
- [ ] 489. **Schwungbalken anpassbar machen** (S–M): WoW Forever baut auf Retail auf und bringt eigene Schwungbalken mit; unsere (452, `Assist/SwingTimer.lua`) müssen sich davon durch Anpassbarkeit abheben. Breite/Höhe, Farben je Hand, Textur (Theme), Text (Restzeit/Dauer/aus), welche Hände gezeigt werden (Haupthand/Nebenhand/Fernkampf einzeln), Ausblenden außerhalb des Kampfes, Anordnung (untereinander/nebeneinander); Optionen in `UI/Options/ComfortWorld.lua` mit Vorschau. Prüfen, ob Forever eigene Balken abschalten lässt (CVar/Edit-Mode), sonst Hinweis.

## Geplant: Wettbewerbsanalyse (November 2026)

Quelle: Quellcode von rund 30 Addons gelesen (nur Ansätze übernommen, kein Code; Lizenzen beachten), dazu CurseForge-Seiten und die Regeln auf speedrun.com. Komfort: Leatrix Plus (3.3.5-Port), Questie, RXPGuides, Guidelime, Plumber, Mapster, MoveAny, BlizzMove. Statistik: XPLedger (engster Konkurrent, Retail/Forever/Era/MoP), XToLevel, Experiencer, Rested, DataStore, Accountant Classic, Deathlog, Hardcore, NovaInstanceTracker, SavedInstances, LvlHistory. Speedrun: Sprint (vormals ForeverTimer), OnlySplits, Chromely, Earned: Self Found, SelfFound Tracker, Speed Splits, Forever Journey Log, Hardcore Deathrace. Stream/Ziele: Hardcore (Zarant), UltraHardcore, HC Challenge Wheel, FateLocked, Bingo/TiffBingo, FarmIt, Farming Bar, Cerealize. Alle API-Angaben stammen aus fremdem Code und sind vor dem Bau gegen die Blizzard-Doku je Client zu prüfen (CLAUDE.md); „im Spiel prüfen“ heißt `/dump` nötig.

Reihenfolge = Priorität: Korrektheit, Komfort, Statistik, Speedrun, Level Time Goals, Stream-Funktionen von Level Time, neue Addons.

Bewusst nicht: „Twitch Plays“ (Eingaben von außen verstoßen gegen die Regeln), LiveSplit-Autosplitter per Speicherlesen (Warden/AGB), Questdatenbanken und fremde Flugzeiten-Datenbanken (Pflegeaufwand, Lizenzen; mitgeliefert werden nur eigene Flugmessungen, 364), komplette Leveling-Guides (RXP/Questie decken das ab).

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
