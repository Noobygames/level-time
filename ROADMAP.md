# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## Geplant: Wettbewerbsanalyse (November 2026)

Quelle: Quellcode von rund 30 Addons gelesen (nur Ansätze übernommen, kein Code; Lizenzen beachten), dazu CurseForge-Seiten und die Regeln auf speedrun.com. Komfort: Leatrix Plus (3.3.5-Port), Questie, RXPGuides, Guidelime, Plumber, Mapster, MoveAny, BlizzMove. Statistik: XPLedger (engster Konkurrent, Retail/Forever/Era/MoP), XToLevel, Experiencer, Rested, DataStore, Accountant Classic, Deathlog, Hardcore, NovaInstanceTracker, SavedInstances, LvlHistory. Speedrun: Sprint (vormals ForeverTimer), OnlySplits, Chromely, Earned: Self Found, SelfFound Tracker, Speed Splits, Forever Journey Log, Hardcore Deathrace. Stream/Ziele: Hardcore (Zarant), UltraHardcore, HC Challenge Wheel, FateLocked, Bingo/TiffBingo, FarmIt, Farming Bar, Cerealize. Alle API-Angaben stammen aus fremdem Code und sind vor dem Bau gegen die Blizzard-Doku je Client zu prüfen (CLAUDE.md); „im Spiel prüfen“ heißt `/dump` nötig.

Reihenfolge = Priorität: Korrektheit, Komfort, Statistik, Speedrun, Level Time Goals, Stream-Funktionen von Level Time, neue Addons.

Bewusst nicht: „Twitch Plays“ (Eingaben von außen verstoßen gegen die Regeln), LiveSplit-Autosplitter per Speicherlesen (Warden/AGB), Questdatenbanken und fremde Flugzeiten-Datenbanken (Pflegeaufwand, Lizenzen; mitgeliefert werden nur eigene Flugmessungen, 364), komplette Leveling-Guides (RXP/Questie decken das ab).

### v2.22: Speedrun (Priorität 3)

- [ ] 292. **LiveSplit-Export und Webseite** (S–M): Splits als LiveSplit-`.lss` (XML mit Segmenten, PB, Bestsegmenten) im Kopierfenster, niemand sonst kann das; dazu eine statische Seite (GitHub Pages), die `LT1:`- oder CSV-Text einliest und Graphen zeigt (Sprint `SprintStats.html`). **Teilweise erledigt: LiveSplit-Teil: `Speedrun/LiveSplitExport.lua` baut eine `.lss` im Format von LiveSplits `XMLRunSaver` (Run version 1.7.0, je Level ein Segment mit SplitTime „Personal Best“ kumuliert und BestSegmentTime über alle eigenen Charaktere ohne Teil-Level, .NET-TimeSpan als RealTime und GameTime) aus den zusammenhängend abgeschlossenen Leveln des eingeloggten Charakters; `/lt runs lss` und Button „LiveSplit“ in Speedrun > Läufe öffnen sie im Kopierfenster. Offen: statische Seite (GitHub Pages), die `LT1:`- oder CSV-Text einliest und Graphen zeigt.**

### v2.24: Quest-Unterstützung (Ideen aus RestedXP, eigener Code, keine RXP-Daten; Lizenz CC BY-NC-SA)

- [ ] 352. **Questreste in den Taschen** (S–M): Items, die laut gelernten Daten oder `GetQuestLogSpecialItemInfo` zu einer abgegebenen oder abgebrochenen Quest gehörten (`QUEST_TURNED_IN`, `QUEST_REMOVED`), als Verkaufs-/Löschvorschlag beim Händler (`Merchant.lua`) oder bei vollen Taschen (`GearWarnings`); Löschen nur per Klick (`DeleteCursorItem` braucht eine Spieleraktion). Plus eigene Müll-Markierung je Item (Modifier-Rechtsklick). **Teilweise: Erledigt: `Assist/QuestLeftovers.lua` (questLeftovers, Komfort > Quests): Gegenstände abgegebener/abgebrochener Quests (gelernt über `QuestMobs.ItemsOf` und das gemerkte Quest-Item, `character.questSpecialItems`), die keine offene Quest braucht, als Hinweis beim Händler und als Zusatz im Hinweis „Taschen fast voll“; verkaufte Reste werden vergessen. Offen: eigene Müll-Markierung je Item (Modifier-Rechtsklick) und ein Lösch-Knopf (`DeleteCursorItem` nur per Klick); Folgequests, die denselben Gegenstand brauchen, kennt der Client vorher nicht.**

### Level Time Goals (nächste Versionen, ehemals Stream Goal)

- [ ] 302. **Dungeon-Ziel** (M): Dungeon X N-mal abschließen oder alle bis Level Y; `ENCOUNTER_END`/`BOSS_KILL` (je Client prüfen), sonst letzter Boss per NPC-ID (6. GUID-Feld) aus `Instances`. **Teilweise erledigt: Art `dungeon` (`StreamGoal/Kinds/Dungeon.lua`): N Bosse besiegen, optional bestimmter Boss und/oder Instanz (Teilstrings), aus `ENCOUNTER_END` mit `success = 1` (in Forever lesbar), Instanzname aus `GetInstanceInfo`; fertiges Paket „Dungeon-Tour“. `/sg add boss 5 [Name]`. Szenario `streamgoal_dungeon`. Offen: „Dungeon N-mal abschließen“ (Endboss je Instanz unbekannt) und „alle Dungeons bis Level Y“.**
- [ ] 306. **Glücksrad** (M): Zufallsziel aus einem Pool bei Level-Up oder per Knopf, begrenzte Neuwürfe, eigene Einträge, Dreh-Animation auf der Karte (HC Challenge Wheel). Zuschauer können per Chat abstimmen, der Streamer dreht. **Teilweise erledigt: `StreamGoal/Wheel.lua`: Zufallsziel per Knopf, `/sg wheel` oder bei jedem Level-Up, Neuwürfe je Drehung einstellbar (0-5, `/sg wheel reroll` bricht das letzte Ergebnis ab); eigener Pool mit eigenen Einträgen (431) und echtes drehendes Rad (432), v2.24. Szenario `streamgoal_wheel`. Offen: Abstimmung der Zuschauer (Twitch-Chat ist für Addons nicht lesbar; Ingame-Chat-Abstimmung wäre möglich).**
- [ ] 307. **Erkundung und Zonen** (S–M): N Gebiete entdecken (`ERR_ZONE_EXPLORED` im Systemchat), Zone X erreichen, optional % einer Zone (`C_MapExplorationInfo`, Era prüfen). **Teilweise erledigt: Art `explore` (`StreamGoal/Kinds/Explore.lua`): N Gebiete entdecken (`ERR_ZONE_EXPLORED`/`_XP` aus `CHAT_MSG_SYSTEM` oder `UI_INFO_MESSAGE`, dieselbe Entdeckung aus beiden Quellen zählt einmal) und Zone erreichen (`GetRealZoneText`/`GetSubZoneText`, Teilstring, bei `ZONE_CHANGED*`). `/sg add explore 10 | <Zone>`. Szenario `streamgoal_explore`. Offen: Anteil einer Zone (`C_MapExplorationInfo`), welche Quelle je Client die Meldung schickt (ManualToCheck 175).**
- [ ] 311. **Gruppenziele** (L): Ziel an die Gruppe schicken, gemeinsame Ziele, bei denen Kills/Beute aller zählen, Abgleich über Addon-Nachrichten mit eigener Drossel (Hardcore-Protokoll als Vorbild).

### Stream-Funktionen von Level Time

- [ ] 313. **OBS-Signalfeld** (S): Kleines einfarbiges Feld blinkt bei Tod, Level-Up und erreichtem Ziel; OBS-Plugins (Advanced Scene Switcher, Streamer.bot) erkennen die Farbe und schalten Szenen oder spielen Töne. Ohne Zusatzprogramm (Plugin-Funktion prüfen).
- [ ] 314. **Nachruf- und Abschlusskarte** (S–M): Beim Tod (Hardcore) oder Max-Level: Level, `/played`, Mörder, Tode, beste Splits als Karte zum Zeigen und Kopieren (FateLocked, Recap).
- [ ] 315. **Stream-Link** (S): Twitch/Discord-Link im Kopierfeld, optional zeitgesteuert in Gruppe/Gilde mit den Sperren der Level-Up-Ansage (UltraHardcore). Sparsam, kein Spam.
- [ ] 316. **Zauberleiste für Zuschauer** (M): Die letzten N gewirkten Zauber als Symbole (`UNIT_SPELLCAST_SUCCEEDED` auf `player`, kein Kampflog), Chroma-Hintergrund.
- [ ] 317. **Statistik beim Gruppenbeitritt** (S): Optional Tode, Dungeons und Level-Zeit in den Gruppenchat (UltraHardcore).

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

### Struktur

- [ ] 86. **Standardwerte je Modul** (M): Module melden ihre Einstellungen und Zähler selbst an (`ns.RegisterDefaults`), statt alles zentral in `Database.lua`. **Teilweise: Erledigt: `Database.RegisterDefaults({ settings, ranges, counters })` (beim Laden, vor `Database.Load`; doppelte Schlüssel brechen das Laden ab); als Muster melden `Assist/LootSparkles.lua` (`lootSparkle*` samt Bereich von `lootSparkleScale`) und `Tracking/LootRolls.lua` (`lootRoll*`) ihre Standardwerte selbst an. Offen: die übrigen rund 300 Einstellungen und die Zähler Modul für Modul umziehen; dabei beachten, dass ein Schlüssel vor dem ersten Lesen angemeldet ist (Datei lädt vor allen Lesern oder Lesen erst nach dem Login) und Einstellungen, die mehrere Module teilen, beim zuerst geladenen stehen.**

## v2.6: Leveln ohne Umwege

Schwerpunkt: Komfort-Funktionen, die beim Leveln Klicks sparen, und Werte, die zeigen, wo Zeit verloren geht. Jede Komfort-Funktion ist einzeln schaltbar (Standard aus) und liegt im neuen Reiter „Komfort“; gedrückte Umschalttaste setzt die Automatik im Moment aus. Nutzt jemand schon Leatrix Plus o.ä., bleiben unsere Schalter einfach aus. Alle API-Annahmen werden vor der Umsetzung je Client gegen die Doku geprüft.

## v2.5: Streaming

Schwerpunkt: Werte, die Zuschauer im Spielbild sehen und verstehen. Addons haben kein Netzwerk und schreiben keine Dateien, alles muss also im Spiel sichtbar sein.

### Projekt und Verbreitung

- [ ] 20. **Uploads aktivieren** (S): CurseForge aktiv (Projekt 1721235, Secret `CF_API_KEY`). Offen: Wago- und WoWInterface-ID in die `.toc`, Secrets `WAGO_API_TOKEN` und `WOWI_API_TOKEN`.
