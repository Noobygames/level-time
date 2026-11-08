# Im Spiel zu prüfen

Was die Tests (WoW-Stub) nicht abdecken: echte API-Werte, Chatmeldungen des Servers und Darstellung.

**So füllst du das aus:** Befehle aus den grauen Blöcken in den Chat kopieren (ein Block = eine Zeile).
Die Ausgabe bzw. was du siehst in den Block **Antwort** darunter schreiben, Kästchen abhaken. Fehlende
Zeilen einfach leer lassen.

**Kopieren aus dem Chat:** `/lt copy` öffnet die Zeilen des aktuellen Chatfensters im Kopierfenster;
dort Strg+A, Strg+C. Mit Einstellungen → Komfort → „Chat kopieren“ gibt es dafür einen Button „C“ oben
rechts an jedem Chatfenster.

```
/lt copy
```

**Vorher einmal:** Fehler sichtbar machen und das Debug-Log einschalten (gilt bis `/reload`).

```
/console scriptErrors 1
```

```
/lt debug
```

---

## Per Debug-Log abgedeckt

Diese Punkte beantwortet das Debug-Log ohne Hinsehen; sie stehen unten nicht mehr. Bei Punkten mit Teil
„Datenteil per Debug-Log“ bleibt unten nur, was man sehen oder hören muss.

**So geht's:**

1. Nach dem Update einmal den Client neu starten (neue Datei `Core\DebugChecks.lua` in der `.toc`).
2. Die Einstellungen der Punkte einschalten, die du prüfen willst (Komfort, Hinweise, Speedrun, Statistiken); das
   Log hält fest, was an war (`settings.all`).
3. Log an (bleibt über `/reload` an):

```
/lt debug log
```

4. Normal spielen. Diese Situationen sollten vorkommen (je mehr, desto mehr Punkte erledigt):
   - Login nach mehr als 5 Minuten Pause, einmal `/reload` (Session-Vergleich, Erfassung, Ruhe-Schätzung, Chat-Verlauf)
   - Kämpfe mit Kills, auch mit Erholungsbonus, ein Rare/Elite; einmal 2+ Minuten stehen ohne XP, einmal über 5 Minuten AFK
   - Level-Up, auch im Kampf und über eine große Quest-Belohnung hinweg; ein gerades Level nach einem Lehrerbesuch
   - Quests annehmen, Ziele erledigen, abgeben (allein und in einer Gruppe); ein Stoff-Quartiermeister oder eine
     wiederholbare Quest; ein NPC mit genau einer Gesprächsoption (Flugmeister, Gastwirt)
   - Tod draußen und im Dungeon, Geisterlauf zurück, einmal als Geist den Geistheiler ansprechen; mit wenig Leben
     wiederbelebt werden (Era/TBC), unter 10 % Leben fallen und heilen
   - Dungeon betreten, Gegner anvisieren, raus und wieder rein (Händlergang), zurücksetzen (allein, als Leiter, als
     Mitglied, mit einem Spieler drin), Normal/Heroisch; mit Gruppe Kills und Gold, dann raus (Instanz-Bericht)
   - Händler: reparieren (mit „zuerst aus der Gildenbank“, Limit unter und über den Kosten), Schrott verkaufen
   - Gold looten (allein und in einer Gruppe), Post mit Gold (auch Auktionserlös), Handel mit Gold, ein Flug
   - Gebiet entdecken, Kraut/Erz sammeln (Retail/Forever), Ruf bekommen (Quest, Kill, Dungeon)
   - Gruppe: Einladung von Fremdem und Freund, geteilte Quest, „inv“ flüstern, Battle.net-Anfrage; ein zweiter
     Spieler mit Level Time (Rennen gegen Freunde), Briefkasten/Handel (SSF)
   - Forever: Lagerfeuer (stehen, sitzen 60 s, aufstehen), Essen bis „Satt“; ein Schlachtfeld (Level Time Goals)
   - Pausen-Erinnerung (Einstellung an, Grenze erreichen, einmal im Kampf), Screenshot-Meilensteine, eigener Split
     per Taste
5. Zwischendurch an diesen Stellen einmal (läuft alle Prüfungen, auch mit Log aus):

```
/lt debug check
```

   nach dem Login; in einem Dungeon; mit einem Spieler (Freund/Fremder) als Ziel; mit einem Gegner als Ziel; bei
   offener Weltkarte; mit Namensplaketten an Questgegnern; vor Erz, Kraut, Quest-Objekt und Leiche (Beute-Glitzer);
   vor und nach dem Umschalten der System-Schalter (CVars); einmal je Sprache (Einheiten).
6. `/reload` oder ausloggen (schreibt das Log auf die Platte), dann Bescheid sagen; ich lese es mit `make debuglog`.
7. Danach Log wieder aus (oder leeren mit `/lt debug log clear`):

```
/lt debug log
```

**Legende:** check `Name` = Eintrag einer Prüfung aus `/lt debug check`; event `NAME` = Ereignis-Probe; debug `bereich`
= Entscheidungszeile eines Moduls (`ns.Debug`); `print` = Chatzeile des Addons; `error` = abgefangener Lua-Fehler mit
Aufrufstapel. „Aktion blockiert“ (Taint) steht als event `ADDON_ACTION_BLOCKED`/`ADDON_ACTION_FORBIDDEN` im Log.

- **9. Kopie wird an Gegnern erkannt (Roadmap 93)**: debug `instances` (enter/sighted/confirmed, zoneUID je Gegner), event `PLAYER_TARGET_CHANGED` (guid des Ziels)
- **10. Reset ergibt neue Kopie (Roadmap 93)**: event `CHAT_MSG_SYSTEM` (Reset-Text), debug `instances` (reset, run finished, new run), check `282.instances`
- **11. Reset als Gruppenmitglied (Roadmap 93, 121)**: wie 10, dazu `error`-Zeilen (Lua-Fehler) und debug `instances` beim Wiederbetreten
- **12. „Noch Spieler drin“ (Roadmap 93)**: event `CHAT_MSG_SYSTEM` (Text „… kann nicht zurückgesetzt werden …“), debug `instances` (zoneUID beim Wiederbetreten)
- **13. Tod im Dungeon (Roadmap 91)**: debug `instances` (left as ghost / alive outside, clock paused / run continues), events `PLAYER_DEAD`, `PLAYER_ALIVE`, `PLAYER_UNGHOST`, `ZONE_CHANGED_NEW_AREA`
- **14. Händlergang (Roadmap 91)**: debug `instances` (clock paused, run continues), check `282.instances` (Sekunden des Laufs)
- **15. Gruppenwechsel (Roadmap 93)**: debug `instances` (confirmed … new copy, corrected … snapshot), check `282.instances`
- **16. Normal und Heroisch (Roadmap 123, TBC/Retail/Forever)**: events `ZONE_CHANGED_NEW_AREA`/`PLAYER_ENTERING_WORLD` (extra = `GetInstanceInfo`, 3. Wert difficultyID), debug `instances` (new run, new instance … in the last hour)
- **17. Lebend raus, Retail/Forever ohne Fehler (Roadmap 93)**: `error`-Zeilen, event `PLAYER_TARGET_CHANGED` (guid `<secret>` oder lesbar), debug `instances` (instance info secret)
- **18. Limit in WoW Forever (Roadmap 92)**: events `UI_ERROR_MESSAGE`/`CHAT_MSG_SYSTEM` (Server-Text), `print` (Zeile des Addons), check `282.instances` (limit)
- **19. Hinweis bei 4/5 und 5/5 (Roadmap 92)**: `print` und debug `alert` (Hinweis bei 4/5 und 5/5), check `282.instances`; Einstellung `warnInstanceLimit`
- **20. Tageslimit (Roadmap 124)**: check `282.instances` (hour, today, day, dailyLimit) und der Server-Text aus `UI_ERROR_MESSAGE`/`CHAT_MSG_SYSTEM`
- **21. Session-XP über einen Level-Up (Roadmap 100)**: debug `stats` (xpGained +…), event `QUEST_TURNED_IN` (XP der Belohnung), `PLAYER_LEVEL_UP`, check `window.rows.session`
- **23. Gildenreparatur (Roadmap 107, TBC/Retail/Forever)**: debug `merchant` (repair cost, guild repair … left), debug `money` (spent … as …), event `PLAYER_MONEY` (Gold vorher/nachher), `print`; check `guild.repair`
- **24. Wiederholbare Quests (Roadmap 108)**: debug `quests` (quest … is repeatable, left to the player / blocked), events `QUEST_DETAIL`, `QUEST_PROGRESS`, `GOSSIP_SHOW`
- **25. Levelcap der Erweiterung (Roadmap 118, Retail)**: check `118.maxLevel` (UnitLevel, UnitXPMax, IsPlayerAtEffectiveMaxLevel, leveling, xpBar)
- **26. Beinahe-Tod nach Wiederbelebung (Roadmap 120, Classic Era/TBC)**: debug `neardeath` (resurrected at … health, low health … ignored, counted)
- **29. Gespräch mit einer Option (Roadmap 133)**: event `GOSSIP_SHOW` (extra = Optionen mit Flags), debug `quests` (gossip: skipping to option), `error`-Zeilen
- **33. Zeitumstellung (Roadmap 95)**: check `95.daily.dst` (mit der echten Zeitzone: dayLength 90000/82800, stuckHours 0) – kein Spielen am Stichtag nötig
- **34. XP/h ohne AFK überall gleich (Roadmap 90)**: check `90.xp.rates` (Fenster, Level-Tabelle, Graph, Vergleich nebeneinander), `print` (Level-Up-Zeile); Einstellung `xpRateWithoutAfk`
- **39. Einblendungen: Warteschlange und Verschiebemodus (Roadmap 155, 163)**: debug `alert` (queued … waiting, moving true; shown … mit Zeitstempel `gt` = Reihenfolge und Dauer)
- **40. Instanz-Reiter im Spiel (Roadmap 149, 152, 156, 161, 162)**: check `window.state` (Reiter, Lauf, offen), `window.rows.instance`, debug `instances`, debug `stats` (combatSeconds direkt nach dem Reset)
- **45. Hilfe und Willkommenshinweis (Roadmap 157)**: `print` (Willkommenszeile einmal, Hilfe-Zeilen), check `157.help` (Zeilenzahl, introShown)
- **46. Erhaltene XP und XP/h ohne AFK (Roadmap 150, 151)**: checks `window.rows.level/session/instance` (Zeile „Erhaltene XP“), `90.xp.rates`
- **47. Klassifikation mit geheimen Werten (Roadmap 171, Retail/Forever)**: `error`-Zeilen (secret value in Classification/InstanceCopy/Zones), debug `stats` (eliteKills/rareKills +1)
- **48. `UnitXPMax` beim Level-Up (Roadmap 175)**: event `PLAYER_LEVEL_UP` (state.xpMax im Moment des Ereignisses), `PLAYER_XP_UPDATE` davor, check `175.level.records` (xp gegen Tabelle)
- **49. Death Recap ohne ID (Roadmap 180, Retail/Forever)**: debug `death` (recap: ok … events …, cause from death recap), check `deathRecap.withoutId`, `280.deaths.recent`
- **50. Gespräch überspringen beim Geistheiler (Roadmap 181)**: debug `quests` (gossip: ghost, no option skipped), event `GOSSIP_SHOW`; Einstellung `skipGossip`
- **51. Gildenreparatur und Abhebelimit (Roadmap 179)**: wie 23: debug `merchant` (guild repair: … of … left), event `PLAYER_MONEY` (Gold vorher/nachher), `print`
- **60. Lagerfeuer-Hinweis nur kurz (Roadmap 245)**: debug `camp` (hint visible for 8 s, hint paused for … min), debug `timer` (LevelTimerCamp shows/hides hint)
- **63. Keine Hinweise im Kampf (Roadmap 248)**: debug `alert` (in combat: hold, combat over, showing … held), `print` (Level-Up-Fenster nach dem Kampf), debug `camp` (state … combat true), events `PLAYER_REGEN_*`
- **65. Sozial: geteilte Quests, Freundschaftsanfragen, Einladungen (Roadmap 329, Schritt 3a)**: debug `social` (declining/accepting/inviting …), events `PARTY_INVITE_REQUEST`, `BN_FRIEND_INVITE_ADDED`, `QUEST_DETAIL`, `print`, check `329.social.target` (Freund/Gilde des Ziels)
- **71. Erfassungsquote und Teil-Level (Roadmap 253)**: debug `coverage` (played, last known, gap; level … only partly tracked), `print` (Chatzeile), check `253.coverage`
- **73. Quest-Automatik: Sperrliste (Roadmap 260, 181, 182)**: debug `quests` (blocked: quest …, gossip/greeting: blocked npc, repeatable), events `QUEST_*`/`GOSSIP_SHOW`, check `settings.all` (`questExclude`)
- **74. Pausen-Erinnerung (Roadmap 263)**: debug `reminders` (break counted (afk/reminder), break due … waits), event `PLAYER_FLAGS_CHANGED` (AFK), `print`/debug `alert`
- **75. Questfortschritt an die Gruppe (Roadmap 264)**: debug `announce` (quest progress …, skipped (chat lockdown)), debug `groupchat`, event `CHAT_MSG_PARTY`/`_INSTANCE_CHAT` (eigene Zeile vom Server)
- **83. Ruhe-XP der Twinks (Roadmap 271)**: debug `rested` (login: estimated … actual …, fully rested), check `271.rested.estimate`, `print`
- **84. Kills bis Level-Up mit Erholung (Roadmap 273)**: check `window.rows.level` (Kills bis Level-Up), debug `stats` (xpKills, xpRested), event `CHAT_MSG_COMBAT_XP_GAIN`
- **85. XP aus Entdecken, Sammeln und nach Ort (Roadmap 275)**: debug `xp` (exploration XP …, gathering XP …), events `CHAT_MSG_SYSTEM`/`UI_INFO_MESSAGE`/`CHAT_MSG_OPENING`, check `window.rows.level` (XP-Quellen, XP nach Ort)
- **86. Session-Vergleich beim Login (Roadmap 281)**: `print` (Zeile „Letzte Session …“ nur beim echten Login), debug `session`
- **87. Leerlauf ohne AFK-Flag (Roadmap 283)**: debug `stats` (idleSeconds +…), checks `window.rows.level` (Zeitaufteilung), `90.xp.rates`; Einstellung `idleMinutes`
- **88. Persönliche Rekorde (Roadmap 272)**: debug `records` (… before …), `print`, debug `alert` (Karte), check `272.personalRecords`
- **90. Einnahmen nach Art und Zeitraum (Roadmap 276)**: debug `money` (income … from window/as loot/as other, spent … as …), events Fenster auf/zu und `PLAYER_MONEY`, checks `window.rows.session`, `276.money.periods`
- **92. Ruf pro Stunde (Roadmap 278)**: debug `reputation` (Fraktion +…), event `CHAT_MSG_COMBAT_FACTION_CHANGE`, checks `278.reputation`, `window.rows.*`
- **95. Instanz-Bericht an die Gruppe und Tageslimit (Roadmap 282)**: debug `announce` (instance report …), debug `groupchat`, eigene Zeile aus `CHAT_MSG_PARTY`/`_INSTANCE_CHAT`, check `282.instances` (Limits), Server-Texte
- **97. Toleranzband und PB derselben Klasse (Roadmap 285)**: check `284.splitList.lines` (Abweichungen mit Farbcode: gelb im Band), `settings.all` (`splitTolerancePercent`, `splitComparison`)
- **98. Prognose des nächsten Abschnitts (Roadmap 286)**: check `284.splitList.lines` (Fußzeilen Prognose/gegen PB/Bestzeiten/Rekord), `286.bracketForecast`
- **99. SSF-Regelhelfer (Roadmap 287)**: debug `ssf` (logout counted, forbidden window), check `287.ssf` (Ruhe-XP-Balken, Logouts, Zeilen), `print`/debug `alert` bei Post/Handel
- **100. Eigene Splits und Tastenbelegung (Roadmap 288)**: check `288.customSplits` (Splits, Vorlage, Tastenbelegung `GetBindingKey`), debug `splits` (custom split …), `print`
- **101. Quest-Splits (Roadmap 289)**: debug `quests` (accepted … at …, quest split … delta), `print`
- **102. Prüfcode für Läufe (Roadmap 290)**: debug `runcheck`, check `290.runs` (Prüfstatus je Lauf), `print` von `/lt runs verify`
- **105. Rennen gegen Freunde (Roadmap 293)**: debug `friendrace` (send/received), check `293.friendRace`, `284.splitList.lines` (Spalte Freund), `print`, event `ADDON_ACTION_BLOCKED`
- **106. Meilenstein-Screenshots (Roadmap 294)**: debug `screenshot` (milestone …), events `SCREENSHOT_SUCCEEDED`/`SCREENSHOT_FAILED`, `ADDON_ACTION_BLOCKED`
- **126. Themes und Schriften, Datenteil (Roadmap 357)**: check `357.theme` (Preset, Schrift je Rolle mit Größe und Flags nach dem Anwenden, LibSharedMedia geladen, Zahl der Schriften)
- **127. Positionen nach Update und Profilwechsel (Roadmap 358)**: check `358.frames.positions` (gespeicherter Eintrag je Anzeige gegen Anker und Größe des Rahmens), vor und nach `/reload`, nach `/lt reset`
- **128. Edit-Modus und Blizzards Bearbeitungsmodus, Datenteil (Roadmap 359)**: check `359.editMode` (Blizzard-Modus vorhanden und eingehängt), debug `edit` (enter/leave, dropped … snap), event `ADDON_ACTION_BLOCKED`
- **130. Beute-Würfe: Daten je Client (Roadmap 364)**: check `364.lootRoll.api` (Quelle legacy/drops/chat, vorhandene `LOOT_ROLL_*`-Formate roh, `GroupLootFrame1..4` mit rollID, verfolgte Würfe mit Zählung), events `START_LOOT_ROLL` (extra: Link, Item-Info, aktive IDs), `CANCEL_LOOT_ROLL`, `LOOT_HISTORY_ROLL_CHANGED` (extra: `C_LootHistory.GetItem`/`GetPlayerInfo`, gleiche rollID wie beim Start?), `LOOT_HISTORY_UPDATE_DROP` (extra: Drop mit Zuständen, auch bei Trash?), `CHAT_MSG_LOOT` (Würfelzeilen lesbar oder `<secret>`), debug `lootroll` (start, chat … zugeordnet, secret loot chat line skipped, complete … winner), `print` (Ergebnis-Zeile); Einstellungen `lootRoll*`
- **149. Lesbarkeit und Balken, Datenteil (Roadmap 361)**: check `361.readability` (Untergrenze, kleinste Größe, effektive kleinste Schrift je Anzeige, Balkenpfad und geladene Textur, LibSharedMedia-Balken)
- **144. Blizzard-Einstellungsmenü, Datenteil (Roadmap 403)**: check `403.blizzardSettings` (Settings/InterfaceOptions vorhanden, Kategorie-ID, Strata von SettingsPanel und unserem Fenster), event `ADDON_ACTION_BLOCKED`
- **132. Flugzeiten-Schätzung, Datenteil (Roadmap 370)**: check `258.flight.estimates` bei offener Flugkarte (taxiMapID, ob `C_TaxiMap` nodeIDs liefert, Strecken, Faktoren), debug `flight` (takeoff … source/seconds/distance/hops, recorded … factor, landed … expected)
- **133. Layouts des Hauptfensters, Datenteil (Roadmap 360)**: check `360.window.layout` (aktives Layout, Zeilen, Breite jedes sichtbaren Texts gegen die Fensterbreite, `IsTruncated`, Schrift mit Kontur) je Layout und Sprache
- **134. XP-Tooltip, Datenteil (Roadmap 360)**: check `360.xpTooltip` (Zeilen wie beim Überfahren, Rohwerte `UnitXP`, `UnitXPMax`, `GetXPExhaustion`, fertige Quest-XP)
- **135. Sichtbarkeitsregeln, Datenteil (Roadmap 362)**: check `362.visibility` (Regel, Kampf, Instanz, Leveln, `IsMouseOver`, Alpha und Sichtbarkeit beider Rahmen) im Kampf, in einer Instanz und mit der Maus über dem Fenster
- **173. Berufs-Ziel, Datenteil (Roadmap 297)**: check `297.goals.skills` (Format `SKILL_RANK_UP`, Classic-Fertigkeitsliste, Berufe mit Wert aus `GetProfessions`)
- **175./176. Erkundung und Ehre, Datenteil (Roadmap 307, 309)**: check `307.goals.formats` (Formate `ERR_ZONE_EXPLORED`/`_XP`, `COMBATLOG_HONORGAIN`/`_NO_RANK`/`COMBATLOG_HONORAWARD`, Erfolgs-API vorhanden), debug `goal:tracking` (discovered …, honor …)
- **178. Regel-Ziele, Datenteil (Roadmap 300)**: check `300.goals.potionSpells` (Name je Heiltrank-Spell-ID; `false` = Client kennt sie nicht), debug `goal:rule`
- **182. Boss-Ziele, Datenteil (Roadmap 302)**: debug `goal:tracking` (encounter end … success …) und event `ENCOUNTER_END`
- **183. Ruf-Ziele, Datenteil (Roadmap 303)**: check `303.goals.reputation` (welche Rufliste, erste Fraktion mit Stufe und Wert)
- **190. Glücksrad, Datenteil (Roadmap 432)**: check `432.goals.wheel` (`SetRotation`/`GetRotation` an den Stücken, Tick-Ton `SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON`, `PlaySound`)
- **189. Schlafsack-Timer, Datenteil (Roadmap 430, WoW Forever)**: check `430.sleep.state` (Schlafsack in der Tasche, Zauber des Items aus `C_Item.GetItemSpell`, „Gut erholt“ mit `applications`/Dauer/Ablauf, `rolledOut`, Zustand des Timers samt `duration`) vor und während des Liegens, debug `sleep` (sleeping bag rolled out, emote SLEEP/STAND (andere Emotes nur beim Liegen oder 15 s nach dem Ausrollen), started by emote … countdown 180/60 s, well rested stacks … -> …, well rested refreshed after … s, ended: done/moving/combat/stand/jump), Proben `430.sleep.cast` und `430.sleep.auras` (springt `expirationTime` bei 3 Stapeln nach etwa 60 s auf volle 2 Stunden?)

---

## Schnellcheck: Werte des Clients

Diese Punkte gehen in wenigen Minuten an einem beliebigen Ort. Wenn möglich in **WoW Forever** und in
**Classic Era/Anniversary** prüfen.

### 1. Reset- und Limit-Texte vorhanden (Roadmap 93)

- [x] geprüft

```
/dump INSTANCE_RESET_SUCCESS, INSTANCE_RESET_FAILED, TRANSFER_ABORT_TOO_MANY_INSTANCES
```

**Erwartet:** drei Texte, z.B. „%s wurde zurückgesetzt.“; keiner `nil`.

**Antwort:**

```text
Client:
Ausgabe:
```

Client: Alle
Ausgabe:
[1]="'%s' wurde zurückgesetzt.",
[2]="'%s' kann nicht zurückgesetzt werden. Es halten sich noch Spieler in der Instanz auf.",
[3]="Ihr habt in letzter Zeit zu viele Instanzen betreten."

**Auswertung:** In Ordnung (alle Clients). Die deutschen Texte setzen den Namen in Anführungszeichen; das Muster liest den Namen trotzdem richtig, Test-Stub und Szenarien nutzen jetzt genau diese Texte.

### 2. Beute-Format (Roadmap 97)

- [x] geprüft

```
/dump LOOT_ITEM_SELF, LOOT_ITEM_PUSHED_SELF, LOOT_ITEM_SELF_MULTIPLE
```

**Erwartet:** Texte mit `%s`; ob am Ende ein Punkt steht, ist egal. Danach einen seltenen (blauen)
Gegenstand looten und in Historie → Journal → Beute nachsehen.

**Antwort:**

```text
Client:
Ausgabe:
Seltene Beute im Journal (ja/nein):
```

Client: Forever
Ausgabe:
[1]="Ihr erhaltet Beute: %s",
[2]="Ihr erhaltet einen Gegenstand: %s",
[3]="Ihr erhaltet Beute: %sx%d"

Selte Beute: Nicht geprüft

**Auswertung:** Forever: Beute-Texte ohne Punkt am Ende, genau der Fall aus Roadmap 97 (seit v2.8.1 behoben). Seltene Beute im Journal steht noch aus.

### 3. Gesundheit geheim? (Roadmap 103)

- [x] geprüft

Einmal außerhalb und einmal im Kampf ausführen (im Kampf z.B. per Makro auf einer Taste):

```
/dump issecretvalue(UnitHealth("player"))
```

**Erwartet:** in Forever/Retail laut Doku `true`; in Classic Era/TBC `false`. Ist es in Forever außerhalb
des Kampfs `false`, können Beinahe-Tode dort wieder eingeschaltet werden.

**Antwort:**

```text
Client: Forever
Außerhalb des Kampfs:
Dump: value=issecretvalue(UnitHealth("player"))
[1]=true
Im Kampf:
Dump: value=issecretvalue(UnitHealth("player"))
[1]=true
```

**Auswertung:** Forever: Gesundheit auch außerhalb des Kampfs geheim. Die Doku stimmt; Beinahe-Tode bleiben in Forever ausgeblendet (Roadmap 103).

### 4. XP-Tabelle passt (Roadmap 94)

- [x] geprüft

```
/dump UnitLevel("player"), UnitXPMax("player")
```

**Erwartet:** Wert aus der Tabelle in `History/XpTable.lua`. Classic Era, Anniversary (Classic) und Forever:
Level 10 = 7600, 20 = 23200, 30 = 47400, 40 = 90700, 50 = 147500. TBC Anniversary: 30 = 38800,
60 = 494000.

**Antwort:**

```text
Client: Forever
Level, XP-Bedarf: Dump: value=UnitLevel("player"), UnitXPMax("player")
[1]=21,
[2]=25200
```

**Auswertung:** Forever Level 21 = 25200, wie in der Classic-Tabelle. Die Prognose nutzt die XP-Tabelle.

### 5. Kein /played im Chat (Roadmap 101)

- [x] geprüft

```
/reload
```

**Erwartet:** nach dem Laden **keine** Zeile „Gesamtspielzeit …“ in keinem Chatfenster. Dann selbst:

```
/played
```

**Erwartet:** jetzt erscheinen die zwei Zeilen wie gewohnt; keine Fehlermeldung (BugSack).

**Antwort:**

```text
Client: Forever
Nach /reload Zeile im Chat (ja/nein): nein
Eigenes /played sichtbar (ja/nein): ja
Fehler: keiner
```

**Auswertung:** In Ordnung (Forever).

### 6. Kampflog-Funktion für die Todesursache (Roadmap 119, Classic Era/TBC)

- [x] geprüft

```
/dump C_CombatLog and C_CombatLog.GetCurrentEventInfo, CombatLogGetCurrentEventInfo
```

**Erwartet:** der erste Wert ist eine Funktion. Danach sterben (z.B. an einem Gegner) und in
Historie → Journal → Tode prüfen, ob der Gegner als Ursache steht.

**Antwort:**

```text
Client: Forever
Ausgabe:
Dump: value=C_CombatLog and C_CombatLog.GetCurrentEventInfo, CombatLogGetCurrentEventInfo
empty result
Todesursache im Journal:
When,Cause,Level,Zone
10/03 11:53:54,Hezrul Blutmal Estpolie (Blutegel),21,Brachland
```

**Auswertung:** Forever: keine Kampflog-Funktion für Addons (beide nil), wie erwartet; die Todesursache kommt dort aus dem Death Recap und steht im Journal. Classic Era/TBC noch offen.

### 7. Munition in Forever (Roadmap 144, als Jäger)

- [x] geprüft

```
/dump UnitUsesAmmo and UnitUsesAmmo("player"), C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded and C_PaperDollInfo.AmmoNeeded()
```

**Erwartet:** mit Bogen/Gewehr `true`. Bei wenig Munition kommt der Hinweis nur, wenn hier `true` steht.

**Antwort:**

```text
Klasse, Waffe: Hunter, Bogen
Ausgabe:Dump: value=UnitUsesAmmo and UnitUsesAmmo("player"), C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded and C_PaperDollInfo.AmmoNeeded()
[1]=true,
[2]=true
```

**Auswertung:** In Ordnung (Forever, Jäger mit Bogen): beide true.

### 8. Goldsymbole (Roadmap 138)

- [x] geprüft

Zeile „Einnahmen“ im Fenster ansehen (Einstellungen → Statistiken → Einnahmen an).

**Erwartet:** Münzsymbole statt „1g 2s 3c“, auch in Forever.

**Antwort:**

```text
Client: Forever
Symbole (ja/nein): ja
```

**Auswertung:** In Ordnung (Forever).

---

## Stabilität (v2.8.1)

### 22. Erholt-XP (Roadmap 102)

- [x] geprüft

Mit Erholt-Bonus vor und nach einem Kill:

```
/dump GetXPExhaustion(), UnitXP("player")
```

**Erwartet:** der erste Wert sinkt um Grund- plus Bonus-XP (doppelt so viel wie der Bonus im Chat).

**Antwort:**

```text
Vorher:
Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=1216,
[2]=19782
Nachher:
Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=1108,
[2]=19890
XP-Zeile im Chat:
Level Time: [debug] stats: combatSeconds +10.045000416227
Level Time: [debug] stats: pveKills +1
Level Time: [debug] stats: xpKills +108
Level Time: [debug] journal: killLog: Oasenschnappkiefer
Level Time: XP message counted as kill: Oasenschnappkiefer stirbt, Ihr bekommt 108 Erfahrung.
Level Time: [debug] stats: xpGained +108
Level Time: [debug] stats: xpRested +54
Level Time: [debug] stats: combatSeconds +2.0160001059994
Eure Fertigkeit 'Kürschnerei' hat sich auf 148 erhöht.
Ihr erhaltet Beute: [Verdorbene Lederfetzen]
```

```text
Vorher:
Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=1108,
[2]=19890

Nachher:

Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=972,
[2]=20026

XP-Zeile im Chat:

Level Time: [debug] stats: combatSeconds +10.060000490397
Level Time: [debug] stats: pveKills +1
Level Time: [debug] stats: xpKills +136
Level Time: [debug] journal: killLog: Oasenschnappkiefer
Level Time: XP message counted as kill: Oasenschnappkiefer stirbt, Ihr bekommt 136 Erfahrung.
Level Time: [debug] stats: xpGained +136
Level Time: [debug] stats: xpRested +68
Level Time: [debug] stats: combatSeconds +4.0260001625866

```

**Auswertung:** In Ordnung: der Pool sank um 108 bzw. 136 (Grund- plus Bonus-XP), gebucht wurde jeweils die Hälfte als Erholt-Bonus (54 bzw. 68). Genau das Verhalten aus Roadmap 102.

### 27. Split-Liste skalieren (Roadmap 128)

- [x] geprüft

```
/lt splits
```

Dann Speedrun → Größe der Split-Liste ändern, und die Größe des Hauptfensters ändern.

**Erwartet:** die Split-Liste bleibt mit ihrer linken oberen Ecke stehen.

**Antwort:**

```text
Springt (ja/nein): bleibt in ihrer ecke stehen. Aber es fehlt der "drag to scale" button wie im hauptfenster des addons.
```

**Auswertung:** Bleibt stehen. Der fehlende Ziehgriff ist nachgerüstet (Roadmap 146): unten rechts an der Split-Liste wie am Hauptfenster; bitte einmal ausprobieren.

### 28. Importierte Laufnamen (Roadmap 132)

- [ ] geprüft

```
/lt runs import
```

Diesen Text einfügen und importieren (ein Lauf namens Test mit Farbcode im Namen, Level 10 in 100 s):

```
LT1:run:{sname=s%7Ccffff0000Test%7Cr,stimes={n10=n100}}
```

**Erwartet:** der Name erscheint ohne Farbe, als `cffff0000Testr`.

**Antwort:** Ich kann keinen Text in "Import runs" fenster kopieren - es passiert nichts auch kein LUA fehler

```text
Import-Meldung:
Name in Historie → Speedrun → Läufe:
```

**Auswertung:** Fehler bestätigt, Ursache vermutet: ein leeres mehrzeiliges Eingabefeld ist nur eine Zeile hoch; ein Klick in den freien Bereich trifft es nicht, Strg+V geht dann ins Leere. Jetzt fokussiert jeder Klick in den Textbereich das Feld (Roadmap 147). Bitte erneut prüfen; klappt es weiterhin nicht, bitte sagen, ob ein Textcursor im Feld blinkt.

### 30. Zeit ab 100 Tagen (Roadmap 139)

- [ ] geprüft

Datenteil per Debug-Log: check `194.format.units` (Text über 100 Tage). Hier nur noch das Auge:

**Erwartet:** im Zeitfenster wird die lange Zeit nicht abgeschnitten (nur prüfbar mit einem Charakter mit 100+ Tagen).

**Antwort:**

```text
Anzeige vollständig (ja/nein):
```

### 31. Summenzeile Speedrun (Roadmap 141)

- [ ] geprüft

```
/lt history
```

Reiter Speedrun → Läufe und Rekorde.

**Erwartet:** „Gesamt: N“ unten lesbar.

**Antwort:**

```text
Lesbar (ja/nein):
```

### 32. Texte in Historie und Einstellungen (Roadmap 142, Darstellung)

- [x] geprüft

Sprache in Einstellungen → Allgemein nacheinander auf Français, Español, Deutsch stellen; Historie und
Einstellungen öffnen:

```
/lt history
```

```
/lt config
```

**Erwartet:** Buttons „Daten löschen“ und „Als Profil speichern“ ganz lesbar; das Sortierzeichen (v/^) steht vor
dem Spaltennamen. Neue Zeilen „Instanz“, „Instanzen/h“, „Instanzen heute“ und ihre Schalter mit Tooltip
passen in allen Sprachen, auch in der horizontalen Leiste (`/lt bar`).

**Antwort:**

```text
Abgeschnitten (Sprache, Stelle): alles top
```

**Auswertung:** In Ordnung (alle Sprachen).

### 35. Prognose plausibel (Roadmap 94)

- [ ] geprüft

Nach ein paar Leveln die Zeile „Max-Level in“ mit deinem Gefühl vergleichen.

**Erwartet:** eher etwas zu lang.

**Antwort:**

```text
Level, Prognose:
Einschätzung:
```

### 36. Chat kopieren (Roadmap 145)

- [ ] geprüft

Datenteil per Debug-Log: check `145.chatCopy.lines` (Zeilen, älteste zuerst, ohne Farbcodes). Hier nur das Aussehen:

Einstellungen → Komfort → „Chat kopieren“ an, Button „C“ oben rechts im Chatfenster ansehen und anklicken.

**Erwartet:** der Button verdeckt nichts Wichtiges und erscheint in jedem Chatfenster (auch Reitern wie „Kampflog“).

**Antwort:**

```text
Button stört (wo):
```

---

## Neu in v2.9: Instanz-Reiter, Einblendungen, Einstellungen (Branch `feature/alert-style`)

Das Gebaute ist nur im Stub getestet; Darstellung und Verhalten der echten Frames sind hier offen.

### 37. Einblendungen: Banner sichtbar (Roadmap 153, Texturpfad)

- [ ] geprüft

Einstellungen → Einblendungen → Vorschau.

**Erwartet:** dunkler Banner mit Farbleisten links, rechts und unten in Gold; der Text steht auf dem
Banner. Wirkt der Stil „Text“, nur Schrift ohne Hintergrund. (Früher wäre der Hintergrund wegen des
Texturpfads unsichtbar gewesen.)

**Antwort:**

```text
Client:
Banner mit Leisten sichtbar (ja/nein):
Stil Text (ja/nein, aussehen):
```

### 38. Einblendungen: Größe, Dauer, Ton, Position (Roadmap 153, 165)

- [ ] geprüft

Datenteil per Debug-Log: debug `alert` (shown … duration, scale, sound), check `frames.addon` (Position von
`LevelTimerAlert`/`LevelTimerNotice` vor und nach `/reload` und nach dem Skalieren). Hier nur Ton und Eindruck:

Ton an, `/lt debug alert levelUp`; Größe auf 50 % und 200 % stellen.

**Erwartet:** Ton ist zu hören; beim Skalieren springt die Einblendung nicht sichtbar weg.

**Antwort:**

```text
Ton gehört (ja/nein):
Wandert sichtbar beim Skalieren (ja/nein):
```

### 41. Einstellungen scrollen (Roadmap 159)

- [ ] geprüft

Einstellungen öffnen, Reiter „Statistiken“ (die längste Seite). Bei kleiner Fensterauflösung oder großer
UI-Skalierung (Video → UI-Skalierung) wiederholen.

**Erwartet:** das Fenster wird höchstens 90 % der Bildschirmhöhe; jede Seite beginnt oben direkt unter den
Reitern; das Mausrad scrollt den Inhalt, nicht über die Reiter oder die Fußzeile; kein Inhalt läuft aus dem
Fenster; jeder Reiter hat beim ersten Öffnen die richtige Scroll-Stellung.

**Antwort:**

```text
Client, Auflösung, UI-Skalierung:
Seite beginnt oben bündig (ja/nein, welcher Reiter anders):
Mausrad (ja/nein):
```

### 42. Voreinstellungen und Gruppen (Roadmap 158)

- [ ] geprüft

Einstellungen → Statistiken → „Minimal“, „Leveln“, „Dungeon“. Sprache nacheinander auf Français und
Español stellen und die Seite zuerst öffnen, bevor eine andere Seite offen war.

**Erwartet:** die Zeilen im Fenster passen zur Voreinstellung; die drei Buttons stehen nebeneinander, gleich
breit, Texte vollständig (auch fr/es); die Buttons haben ihre Breite auch auf der Seite, die nicht zuerst
geöffnet wurde (Prüfer fragte, ob `OnSizeChanged` bei versteckten Seiten feuert).

**Antwort:**

```text
Buttons nebeneinander und breit genug (Sprache):
Zeilen wie erwartet (ja/nein):
```

### 43. Buttons und Fußzeile (Roadmap 154)

- [ ] geprüft

Mit der Maus über Buttons fahren, klicken und gedrückt halten (Einstellungen, Historie, „C“-Button im
Chat). Fußzeile in Deutsch, Französisch und Spanisch ansehen.

**Erwartet:** Mouseover heller Rand und weiße Schrift, gedrückt dunkler; Schrift jederzeit lesbar; vier
Fußzeilen-Buttons in zwei Spalten gleich breit, Texte vollständig.

**Antwort:**

```text
Lesbar (ja/nein):
Abgeschnitten (Sprache, Button):
```

### 44. Charakterliste und gemerkter Reiter in der Historie (Roadmap 160, 168)

- [ ] geprüft

Datenteil per Debug-Log: check `settings.all` (`historyTab` nach `/reload`). Hier nur die Liste:

`/lt history`, auf den Charakternamen klicken, Menü offen lassen und irgendwo anders ins Fenster klicken.

**Erwartet:** die Liste zeigt alle Charaktere klassenfarbig, ab 12 scrollt sie mit dem Mausrad; ein Klick daneben
schließt sie (bekannte Lücke Roadmap 168).

**Antwort:**

```text
Liste vollständig (ja/nein):
Schließt bei Klick daneben (ja/nein):
```

### 52. Chroma-Grün und schnelle Splits (Roadmap 198)

- [ ] geprüft

Einstellungen → Stream → Hintergrund „Grün“, `/lt splits`, Vergleich mit einem langsameren Lauf, damit
ein Split grün („schneller“) erscheint.

**Erwartet:** Schrift in Gold und die schnellen Splits sind auf grünem Grund lesbar (bisher in reinem Grün
unsichtbar bzw. von OBS ausgestanzt).

**Antwort:**

```text
Schnelle Splits sichtbar (ja/nein):
```

---

## Neu in v2.10: Lagerfeuer (nur WoW Forever)

### 53. Lagerfeuer-Hinweis und Countdown (Roadmap 236)

- [ ] geprüft

Datenteil per Debug-Log: debug `camp` (state, countdown started/ended, benefits granted), debug `timer`
(LevelTimerCamp shows/hides/done, sound), `error`-Zeilen. Der Ablauf (Hinweis, Countdown 60 → 0, „aktiv“, nichts im
Kampf) steht damit im Log. Hier nur das Aussehen:

Einstellungen → Hinweise → „Lagerfeuer“: Vorschau mehrfach, „Verschieben“, Größe; dann echt an ein Lagerfeuer.

**Erwartet:** blauer, leicht pulsierender Hinweis; Countdown mit Zauber-Symbol, Zahl und Balken; „Lagervorteile
aktiv!“ grün; Ton, wenn eingeschaltet; Texte passen in fr/es.

**Antwort:**

```text
Pulsieren, Symbol, Balken sichtbar (ja/nein):
Ton gehört (ja/nein):
Texte in fr/es passen (ja/nein):
```

### 54. Hinweise als Karten (Roadmap 237)

- [ ] geprüft

Datenteil per Debug-Log: check `237.alerts.icons` (Datei-ID je Symbol; leer = grünes Quadrat), debug `card`
(icon … -> …), debug `alert` (shown …, Reihenfolge). Hier nur das Aussehen:

Einstellungen → Einblendungen → „Vorschau“ bis zur Karte „Taschen“; einige echte Hinweise auslösen.

**Erwartet:** dunkle Karte mit Farbleiste, Titel in Gold/Orange und Text darunter.

**Antwort:**

```text
Karten sehen richtig aus (ja/nein):
Texte in fr/es passen (ja/nein):
```

---

### 58. Reiter Timer und Munition nur für Jäger (Roadmap 243)

- [ ] geprüft

Einstellungen öffnen: Reiter Hinweise und Reiter Timer ansehen, mit einem Jäger und mit einer anderen Klasse. In
fr/es die Breite der Reiterzeile prüfen (neun Reiter).

**Erwartet:** Hinweise = Level-Up, Erinnerungen, Warnungen; Timer = Lagerfeuer (nur Forever) und Essen mit
Vorschau/Verschieben/Zurücksetzen; „Munition knapp“ mit seinen drei Reglern nur beim Jäger; die Reiterzeile passt
in jeder Sprache ins Fenster.

**Antwort:**

```text
Reiterzeile passt (de/en/fr/es):
Munition nur beim Jäger (ja/nein):
Fehler:
```

---

### 57. Essen-Timer (Roadmap 242)

- [ ] geprüft

Datenteil per Debug-Log: debug `food` (eating started/ended after … s, well fed granted … s after eating started),
debug `timer` (LevelTimerFood). Damit steht im Log, wann „Satt“ kommt. Hier nur die Karte:

Einstellungen → Hinweise → „Essen“: Timer an, etwas essen.

**Erwartet:** Karte „Sitzen bleiben!“ mit Zahl und leerlaufendem Balken, sitzt unter der Lagerfeuer-Anzeige und lässt
sich verschieben.

**Antwort:**

```text
Karte sieht richtig aus (ja/nein):
```

---

### 56. Kill-Quest-Markierung (Roadmap 240)

- [ ] geprüft

Datenteil per Debug-Log: debug `questmarks` (mark/unmark Name, health bar), check `240.questMarks.plates` (Plaketten,
Questbezug), `error`-Zeilen. Hier nur die Lage des Symbols:

„Questziele markieren“ an, Namensplaketten an, zu Questgegnern laufen, Größe-Regler verstellen.

**Erwartet:** gelbes Ausrufezeichen direkt links neben dem Lebensbalken, so hoch wie der Balken, kein Überlappen; Größe
folgt dem Regler; bei Plater o. ä. Fallback über der Plakette.

**Antwort:**

```text
Symbol sitzt sauber (ja/nein):
```

---

### 55. Fenster verschieben (Roadmap 238)

- [ ] geprüft

Datenteil per Debug-Log: debug `moveframes` (attached/skipped), check `238.moveFrames.frames` (Positionen nach Öffnen
und `/reload`, gemerkte Werte), event `ADDON_ACTION_BLOCKED` (auch im Kampf). Hier nur das Ziehen selbst:

Einstellungen → Komfort → „Fenster verschieben“ an; Charakterfenster, Zauberbuch, Händler, Questgespräch und Talente
ziehen.

**Erwartet:** das Fenster folgt der Maus; ausgeschaltet lässt sich nichts ziehen.

**Antwort:**

```text
Welche Fenster verschiebbar (und welche nicht):
```

---

## Errors

### When starting boss fight

**Auswertung:** Ursache gefunden: der Food-/Camp-Hinweis (Roadmap 39/40) fragt alle 30 s die Buffs ab.
Bei einem Bosskampf sperrt WoW Forever die Auren für Addons schon, bevor man als im Kampf gilt, und
`C_UnitAuras.GetAuraDataByIndex` bricht dann mit diesem Fehler ab (Doku: `RequiresUnitAuraAccess`,
FailureMode Error). Behoben in Roadmap 148: Abfrage nur, wenn `C_Secrets.ShouldAurasBeSecret()` false ist,
und geschützt aufgerufen. Ein Abgleich aller Addon-Aufrufe gegen die Forever-Doku fand keine weitere
Funktion, die so abbricht. Bitte beim nächsten Bosskampf prüfen, ob der Fehler weg ist.

Message: GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'LevelTimer'
Lua Taint: LevelTimer
Time: Sat Oct 3 12:27:23 2026
Count: 1
Stack:
[C]: in function 'xpcall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:42: in function 'SafeCall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:116: in function <Interface/AddOns/LevelTimer/Core/LevelTimer.lua:109>

Locals:

Message: GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'LevelTimer'
Lua Taint: LevelTimer
Time: Sat Oct 3 12:27:23 2026
Count: 2
Stack:
[C]: in function 'xpcall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:42: in function 'SafeCall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:116: in function <Interface/AddOns/LevelTimer/Core/LevelTimer.lua:109>

Locals:

### 59. Einblendungen als Karten (Roadmap 244)

- [ ] geprüft

Datenteil per Debug-Log: check `237.alerts.icons` (Datei-IDs), debug `card`, debug `alert`. Hier nur das Aussehen:

Reiter Einblendungen: Vorschau mehrfach (Level-Up, Rare, Elite, Beute, Beinahe-Tod), Stil „Text“ zum Vergleich.

**Erwartet:** im Stil „Banner“ jede Einblendung als Karte mit Symbol und Farbleiste; „Text“ zeigt nur die Schrift.

**Antwort:**

```text
Karten und Text-Stil sehen richtig aus (ja/nein):
```

### 61. Level Time Goals (Roadmap 246)

- [ ] geprüft

Datenteil per Debug-Log: debug `goal:goals` und `goal:tracking` (battleground over: winner, faction, won), event
`PVP_MATCH_COMPLETE`/`UPDATE_BATTLEFIELD_SCORE` (Siegerwerte), check `246.battleground`, `error`-Zeilen. Hier nur
das Sichtbare:

`/sg`, Ziele anlegen (siehe `/sg add …`), im Formular „Item“ ein Item per Shift-Klick einfügen.

**Erwartet:** Karten rechts oben mit Titel, „x / y“ und Balken, verschiebbar; Einblendung „Ziel erreicht!“;
Shift-Klick fügt den Link ein; ohne Level Time lädt Level Time Goals nicht.

**Antwort:**

```text
Karten und Einblendung (ja/nein):
Shift-Klick-Link (ja/nein):
```

### 62. Level-Up-Zuwachs (Roadmap 247)

- [ ] geprüft

Datenteil per Debug-Log: debug `gains` (Werte beim Level-Up), `print` (Zuwachs-Zeile), check `unit.stats` (Werte
danach). Hier nur die Karte:

Level-Up (echt oder `/lt debug levelup`) mit „Level-Up: Zuwachs anzeigen“ und Einblendung „Level-Up“.

**Erwartet:** die Level-Up-Karte zeigt dieselben Zeilen wie die Chatzeile.

**Antwort:**

```text
Karte zeigt die Zuwächse (ja/nein):
```

### 64. Level-Up-Fenster (Roadmap 249)

- [ ] geprüft

Datenteil per Debug-Log: debug `levelup` (window for level … abilities, Blizzard banner off/on, Blizzard toast
closed), check `249.trainer.cache`, `print` (nach dem Kampf). Hier nur das Sichtbare:

Reiter Einblendungen > Level-Up-Fenster: Vorschau, Verschieben, Farbschema, kompakte Ansicht; dann ein echtes
Level-Up (gerades Level).

**Erwartet:** eigenes Fenster mit Tabelle, Talentpunkten und Symbolen (Tooltip mit Name, Rang, Level); Blizzards
Banner/Toast erscheint nicht (kurzes Aufblitzen in Forever möglich); Controller-Aktionsleiste und Castbar bleiben an
ihrem Platz; Linksklick schließt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Blizzard-Banner weg (ja/nein):
Tooltip der Fähigkeiten (ja/nein):
Aktionsleiste/Castbar am Platz (ja/nein):
```

### 66. Chat: Fenster, letzter Chat nach /reload, Spam-Filter (Roadmap 329, Schritt 3b)

- [ ] geprüft

Datenteil per Debug-Log: debug `overrides` (… overridden/restored), debug `chat` (restored … lines, filtered …),
check `329.chat.windows` (Reiter, Knöpfe, Eingabezeile, Ausblenden). Hier nur das Sichtbare:

Komfort > Chat: „Eingabezeile oben“ und „Pfeiltasten“ an.

**Erwartet:** die Eingabezeile sitzt über den Reitern und überdeckt nichts Wichtiges; Pfeiltasten bewegen den Cursor
ohne Alt.

**Antwort:**

```text
Eingabe oben sitzt gut (ja/nein):
Pfeiltasten (ja/nein):
```

### 67. Oberfläche: Aktionsleisten und Blizzard-Einblendungen ausblenden (Roadmap 329, Schritt 4)

- [ ] geprüft

Datenteil per Debug-Log: debug `overrides` (je Frame overridden/restored), debug `comfort` (stance bar: waiting for
combat end), events `ADDON_ACTION_BLOCKED`/`ADDON_ACTION_FORBIDDEN`. Hier nur das Sichtbare:

Komfort > Oberfläche: jeden Schalter einzeln an und aus (Tastenbelegung, Makronamen, Reichweite rot, Boss-Banner,
Ereignis-Einblendungen, Meldungen, Haltungsleiste, Ruhe-Animation, Porträtzahlen).

**Erwartet:** Texte, Banner, Toasts, „Zzz“ und Porträtzahlen verschwinden und kommen zurück; Symbol rot außer
Reichweite, blau bei wenig Mana.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Alles weg und zurück (ja/nein, was nicht):
Reichweite rot, wieder normal (ja/nein):
```

### 68. Charakterfenster: Haltbarkeit und Lautstärkeregler (Roadmap 329, Schritt 2d und 4)

- [ ] geprüft

Datenteil per Debug-Log: check `329.characterFrame` (eigene Haltbarkeitssumme gegen angezeigten Text, Regler gegen
CVar `Sound_MasterVolume`), event `UPDATE_INVENTORY_DURABILITY`. Hier nur Lage und Ton:

Komfort > Fenster: „Haltbarkeit anzeigen“ und „Lautstärkeregler“ an, Charakterfenster (C) öffnen, Regler ziehen.

**Erwartet:** nichts überlappt Plätze, Modell oder Reiter (auch auf Französisch); die Lautstärke ändert sich hörbar.

**Antwort:**

```text
Position gut, nichts überlappt (ja/nein):
Lautstärke ändert sich hörbar (ja/nein):
```

### 69. Fenster: Klassenfarben bei Ziel und Fokus, Tooltip, Minimap (Roadmap 329, Schritt 4)

- [ ] geprüft

Datenteil per Debug-Log: check `329.classColors` (Farbe des Namenshintergrunds gegen Klasse), check `329.minimap`
(Knöpfe, Mausrad), events `ADDON_ACTION_BLOCKED`, `error`-Zeilen (auch in Instanzen). Hier nur der Tooltip:

Tooltip: „Namen in Klassenfarbe“, „Ziel der Einheit zeigen“, „Im Kampf ausblenden“ an; über Spieler und kämpfende
Gegner fahren, im Kampf mit und ohne Umschalt.

**Erwartet:** Name in Klassenfarbe, Zeile „Ziel: Name“ (bei dir „Ziel: Du“), Tooltip passt seine Größe an; im Kampf
keine Einheiten-Tooltips, mit Umschalt doch.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tooltip Klassenfarbe und Zielzeile (ja/nein):
Im Kampf versteckt, Umschalt zeigt (ja/nein):
```

### 70. System: Bildschirmeffekte, Wetter, Namensplaketten im Kampf, Töne, Addon-Liste, Gruppenfarbe (Roadmap 329, Schritt 5)

- [ ] geprüft

Datenteil per Debug-Log: check `329.cvars` vorher/nachher (Werte, Standard, gemerkte Originale, `lowLevelRaid`),
event `CVAR_UPDATE`, debug `comfort` (cvar … = …, restored, sound group … muted, low level raid …), check
`329.chat.colors`, events `ADDON_ACTION_BLOCKED`. Dafür einmal vor dem Einschalten, einmal eingeschaltet und einmal nach
dem Ausschalten (auch nach `/reload`) `/lt debug check`. Hier nur, was man sieht und hört:

**Erwartet:** kein Rausch-Schleier, keine Geist-/Nether-Effekte, Wetter bei 0 und 3 sichtbar anders; Emotes im
Gasthaus stumm, draußen mit Ton; Zauber-Fehlschlag, Stadtglocken, Roboschreiter stumm; Addon-Liste alphabetisch und
weiter klickbar.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Rausch/Geist/Nether/Wetter wirken (ja/nein je):
Emotes/Fehlschlag/Glocken/Roboschreiter stumm (ja/nein je):
Addon-Liste alphabetisch, Klicks gehen (ja/nein):
```

### 72. Atem-Warnung (Roadmap 255)

- [ ] geprüft

Datenteil per Debug-Log: debug `warnings` (mirror timer …, … low), events `MIRROR_TIMER_START`/`STOP`, debug `alert`
(Karte), auch nach `/reload` unter Wasser. Hier nur Ton und Blinken:

„Atem und Erschöpfung knapp“ an, tauchen bis kurz vor leer, Spiel im Fenster lassen und kurz wegklicken.

**Erwartet:** Warnton und blinkende Taskleiste (wo der Client `FlashClientIcon` hat).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Ton und Blinken (ja/nein):
```

### 76. Einladungen mit Infos (Roadmap 265)

- [ ] geprüft

Datenteil per Debug-Log: `print` (Zeile „Gruppeneinladung von …“), check `329.social.target` (Info zum Ziel), event
`PARTY_INVITE_REQUEST`, `ADDON_ACTION_BLOCKED`. Hier nur das Einladungsfenster:

„Einladungen mit Infos“ an, einladen lassen.

**Erwartet:** das Einladungsfenster funktioniert wie immer (Annehmen/Ablehnen); der Name in der Chatzeile ist
klassenfarbig.

**Antwort:**

```text
Popup unverändert (ja/nein):
Name klassenfarbig (ja/nein):
```

### 77. Quest-Level in Questlog, Gesprächen und Tracker (Roadmap 259)

- [ ] geprüft

Datenteil per Debug-Log: debug `questlevels` (hooked …), check `259.questLevels.log` (Präfix je Quest), events
`ADDON_ACTION_BLOCKED`, `error`-Zeilen (auch beim Öffnen der Weltkarte). Hier nur das Sichtbare:

„Quest-Level anzeigen“ an: Questlog, Gesprächsliste, Grußliste, Tracker (Classic).

**Erwartet:** „[12] Titel“ bzw. „[12+]“ überall, Überschriften ohne Level, lange Titel umbrechen ohne Überlappen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Questlog/Gespräch/Gruß/Tracker (ja/nein je):
Lange Titel umbrechen/überlappen (ja/nein):
```

### 78. Verschobene Fenster skalieren (Roadmap 266)

- [ ] geprüft

Datenteil per Debug-Log: debug `moveframes` (… scale …), check `238.moveFrames.frames` (Größe nach Schließen und
`/reload`), `ADDON_ACTION_BLOCKED`. Hier nur das Bedienen:

Strg+Mausrad über Charakterfenster, Zauberbuch, Händler; in Questlog und Händler ohne Strg scrollen.

**Erwartet:** das Fenster wird sichtbar größer/kleiner; Listen scrollen ohne Strg wie immer.

**Antwort:**

```text
Skalieren sichtbar (ja/nein):
Listen scrollen weiter (ja/nein):
```

### 79. Notfall bei wenig Leben (Roadmap 267)

- [ ] geprüft

Datenteil per Debug-Log: debug `emergency` (active, marked Knopf=Aktion), check `emergency.actions`,
`ADDON_ACTION_BLOCKED`. Nur Classic Era/TBC. Hier nur das Aussehen:

„Notfall bei wenig Leben“ an, Trank, Stein und Notfallzauber auf die Leisten, im Kampf unter 10 % fallen.

**Erwartet:** grüner Rahmen um die markierten Knöpfe, roter Rand am Bildschirm.

**Antwort:**

```text
Client (Era/TBC):
Rahmen und Rand sichtbar (ja/nein, zu stark/zu schwach):
```

### 80. Quest-Item-Knopf und Zielknopf (Roadmap 268)

- [ ] geprüft

Datenteil per Debug-Log: debug `questitem` (item …, target …, in combat, update waits), check `268.questItem.pick`
(Kandidaten, Wahl, Ziel), `ADDON_ACTION_BLOCKED`. Hier nur Klicks und Aussehen:

„Quest-Item-Knopf“ und „Questgegner-Zielknopf“ an, Knopf anklicken, Zielknopf klicken, verschieben.

**Erwartet:** Symbol mit Anzahl, Klick benutzt das Item; Zielknopf wählt einen Questgegner.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Klick benutzt das Item (ja/nein):
Zielknopf wählt Questgegner (ja/nein/nicht vorhanden):
```

### 81. Koordinaten auf der Weltkarte (Roadmap 269)

- [ ] geprüft

Datenteil per Debug-Log: check `269.mapCoordinates` bei offener Weltkarte (Spieler- und Maustext), `error`- und
Taint-Zeilen. Hier nur Lesbarkeit:

„Koordinaten auf der Karte“ an, Weltkarte öffnen.

**Erwartet:** Text unten auf der Karte gut lesbar, Lage passt.

**Antwort:**

```text
Text gut lesbar/Lage ok (ja/nein):
```

### 82. Quest-XP im Questlog (Roadmap 270)

- [ ] geprüft

Datenteil per Debug-Log: check `quest.log` (XP je Quest), `270.questLogXp`, `window.rows.level` (Quest-XP fertig/offen,
Abgabe für Level-Up), debug `quests` (quest log XP). Hier nur der Balken:

„Quest-XP auf dem XP-Balken“ an, eine Quest fertig machen.

**Erwartet:** gelbes Stück hinter dem Fortschritt auf dem XP-Balken.

**Antwort:**

```text
Gelbes Stück auf dem Balken (ja/nein):
```

### 89. Kills bis Level im Tooltip (Roadmap 274)

- [ ] geprüft

Datenteil per Debug-Log: debug `tooltip` (kills line for … : Text), check `274.tooltip.killsToLevel`. Hier nur die Farbe:

„Kills bis Level-Up zeigen“ an, über Gegner verschiedener Stufen fahren.

**Erwartet:** Farbe wie die Stufenfarbe des Gegners.

**Antwort:**

```text
Farbe passt (ja/nein):
```

### 91. Wann ich spiele (Roadmap 277)

- [ ] geprüft

Datenteil per Debug-Log: check `277.playHours` (Kacheln mit Zeit und XP, aktuelle Stunde). Hier nur das Bild:

Historie > Graphen > „Wann“, mit der Maus über die Kacheln.

**Erwartet:** 7 × 24 Kacheln, heutige Stunde hell, Tooltip „Mi 13-14 Uhr“, Beschriftung alle 3 Stunden, nichts
überlappt.

**Antwort:**

```text
Heatmap sichtbar und lesbar (ja/nein):
```

### 93. Fortschrittskurve (Roadmap 279)

- [ ] geprüft

Datenteil per Debug-Log: check `279.progressCurve` (Linien, Punkte, letzter Punkt). Hier nur das Bild:

Historie > Graphen > „Kurve“, über die Punkte fahren.

**Erwartet:** Linien in Klassenfarbe, Vergleich schwächer und dünner, Achsen und Legende lesbar.

**Antwort:**

```text
Linien, Achsen und Legende (ja/nein):
```

### 94. Todeskarte und letzte Worte (Roadmap 280)

- [ ] geprüft

Datenteil per Debug-Log: debug `deaths` (place mapID x, y), check `280.deaths.recent` (Ort, letzte Worte). Hier nur
die Karte:

„Tode auf der Karte“ an, nach einem Tod die Weltkarte öffnen, zoomen, andere Zone anzeigen.

**Erwartet:** roter Punkt an der Todesstelle, bleibt beim Zoomen dort; Tooltip mit Ursache und letzten Worten.

**Antwort:**

```text
Punkt an der richtigen Stelle, Zoom richtig (ja/nein):
```

### 96. Gold-Splits (Roadmap 284)

- [ ] geprüft

Datenteil per Debug-Log: debug `splits` (gold split level …), `print` (Gold-Split-Zeile), check
`284.splitList.lines` (`gold`). Hier nur Farbe und Ton:

„Gold-Splits melden“ an, ein Level schneller als jeder andere eigene Charakter.

**Erwartet:** Raid-Warnungs-Ton; die Abweichung in der Split-Liste lila.

**Antwort:**

```text
Ton gehört (ja/nein):
Lila in der Split-Liste (ja/nein):
```

### 103. Run-Kategorie automatisch (Roadmap 291)

- [ ] geprüft

Datenteil per Debug-Log: debug `runcategory` (… -> …), event `GROUP_ROSTER_UPDATE` (Level der Mitglieder), check
`290.runs` (Kategorie je Lauf). Hier nur das Suchfeld:

Historie > Speedrun > Läufe, Suchfeld „SSF“ eingeben.

**Erwartet:** das Suchfeld filtert die Läufe nach Kategorie.

**Antwort:**

```text
Filter (ja/nein):
```

### 104. LiveSplit-Export (Roadmap 292)

- [ ] geprüft

Mit einem Charakter, der einige Level erfasst hat: `/lt runs lss` (oder Historie > Speedrun > Läufe > „LiveSplit“). Text mit Strg+A, Strg+C kopieren, in eine Datei `run.lss` speichern und in LiveSplit öffnen (Rechtsklick > Open Splits).

**Erwartet:** LiveSplit öffnet die Datei ohne Fehler, zeigt Segmente „Level N“ mit Personal Best und Bestsegmenten (Sum of Best).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
LiveSplit öffnet die Datei (ja/nein):
Zeiten stimmen (ja/nein):
Fehler:
```

### 107. Beute-Glitzer (Roadmap 330)

- [ ] geprüft

Datenteil per Debug-Log: debug `sparkle` (… target, state …), check `lootSparkles.target` (vor Erz, Kraut,
Quest-Objekt, Leiche je einmal `/lt debug check`), check `329.cvars` (SoftTarget-CVars vorher/nachher), event
`CVAR_UPDATE`, `ADDON_ACTION_BLOCKED`. Vorher ForeverLootSparkles und Lueur ausschalten. Hier nur das Glitzern:

**Erwartet:** Quest-Gegenstände glitzern (Forever, auch nach Wechsel der Grafik-Voreinstellung); Erz/Kräuter zuerst
gedämpft, in Reichweite hell, mit zu niedriger Fertigkeit grau; Quest-Objekte und Leichen mit Beute glitzern bis zum
Plündern bzw. erfüllten Ziel; „Größe der Funken“ 200 % deutlich größer; NPCs und Briefkästen ohne Plakette.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Quest-Gegenstände nach Voreinstellung wieder an (ja/nein/nicht vorhanden):
Erz/Kräuter: gedämpft/hell/grau (ja/nein):
Quest-Objekte, Leichen (ja/nein):
Funkengröße (ja/nein):
```

### 108. Einheiten je Sprache (Roadmap 194)

- [ ] geprüft

Datenteil per Debug-Log: check `194.format.units` (Zeit- und Geldtext in der eingestellten Sprache; je Sprache einmal
`/lt debug check`). Hier nur, ob nichts abgeschnitten ist:

Sprache nacheinander auf Deutsch, Français, Español; Zeitfenster und Historie → Levels/Sessions ansehen.

**Erwartet:** Spalten schneiden die längeren französischen Geldeinheiten nicht ab.

**Antwort:**

```text
Abgeschnitten (wo):
```

### 109. Zusammenfassungskarte im Stream (Roadmap 209)

- [ ] geprüft

Einstellungen → Stream → Hintergrund „Grün“, dann `/lt recap` offen lassen und ein paar Gegner töten.
Danach im Reiter Stream „Minimap-Button ausblenden“ anhaken.

**Erwartet:** Die Karte hat denselben grünen Hintergrund ohne Rand wie das Zeitfenster und zählt Zeit, XP und
Kills jede Sekunde mit, ohne neu geöffnet zu werden. Mit „Standard“ ist sie wieder dunkel mit Rand. Der
Minimap-Button verschwindet, im Reiter Allgemein ist „Minimap-Button anzeigen“ nicht mehr angehakt.

**Antwort:**

```text
Client:
Chroma-Hintergrund der Karte (ja/nein):
Karte zählt mit (ja/nein):
Minimap-Button ausgeblendet (ja/nein):
Fehler:
```

### 110. Spiel-Tooltip in Beute und Quests (Roadmap 212)

- [ ] geprüft

`/lt history` → Journal → Beute: Maus über eine Zeile mit einem Gegenstand. Dann Journal → Quests: Maus über
eine abgegebene Quest.

**Erwartet:** Bei Beute erscheint der normale Gegenstands-Tooltip am Mauszeiger, bei Quests der Quest-Tooltip
(Titel, ggf. Ziele). Kein Lua-Fehler; in Classic Era/TBC darf der Quest-Tooltip fehlen oder nur den Titel zeigen,
dann bitte notieren.

**Antwort:**

```text
Client:
Gegenstands-Tooltip (ja/nein):
Quest-Tooltip (ja/nein/nur Titel):
Fehler:
```

### 111. CPU-Last vorher/nachher (Roadmap 331–336)

- [ ] geprüft

Einmal mit dem Stand **vor** dem Performance-Branch und einmal **danach** messen, jeweils gleiche Situation (z.B. 5 min Questen draußen, dazu wenn möglich 5 min Dungeon/Raid oder Schlachtfeld). Nach `/reload`:

```
/lt debug perf on
```

Spielen, dann:

```
/lt debug perf report 20
```

Danach `/lt copy`, die perf-Zeilen kopieren. Vor dem Wechsel `/lt debug perf off`. (Der alte Stand kennt den Befehl noch nicht; dort als Gegencheck `/console scriptProfile 1`, `/reload`, nach dem Spielen `/dump GetAddOnCPUUsage("LevelTimer")` nach `/run UpdateAddOnCPUUsage()`, danach `scriptProfile 0`.)

**Erwartet:** Der Bericht listet Schlüssel wie `event UNIT_AURA ...`, `task ...`, `onupdate TimerWindow`; nach dem Branch kleinere Summen bei UNIT_*-Events, COMBAT_LOG_EVENT_UNFILTERED (Classic) und den Aura-Aufgaben, weniger Speicherzuwachs. Keine Fehler, keine fehlenden Funktionen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Situation:
Vorher (Top-Zeilen oder GetAddOnCPUUsage):
Nachher (Top-Zeilen):
Fehler:
```

### 112. Historie offen beim Kämpfen vorher/nachher (Roadmap 337–339, 353–355)

- [ ] geprüft

Einmal mit dem Stand **vor** dem Branch `perf/bigo` und einmal **danach**, gleiche Situation: Charakter mit großem Kill-Journal (möglichst einige tausend Kills, Archiv geladen), Historie offen auf **Journal > Kills**, nach Name sortiert und mit Suchtext (z.B. `wolf`), dann 5 min Mobs töten. Danach dasselbe auf **Graphen > Top-Gegner** und **Speedrun > Läufe**. Nach `/reload`:

```
/lt debug perf on
```

Spielen, dann:

```
/lt debug perf report 20
```

Danach `/lt copy`, die perf-Zeilen kopieren, `/lt debug perf off`. Zusätzlich im Optionsfenster einen Regler (z.B. Hintergrund) hin und her ziehen und den Bericht danach ansehen.

**Erwartet:** Nach dem Branch deutlich kleinere Summen und Maxima bei den OnUpdate-Zeilen der Historie und bei den Journal-Listenern; neue Kills erscheinen weiter spätestens nach 5 s an der richtigen Stelle der sortierten Tabelle, Suche und Summenzeile stimmen, Top-Gegner zählt mit. Reglerziehen ohne Ruckeln. Keine Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Journal-Größe (Kills):
Vorher (Top-Zeilen):
Nachher (Top-Zeilen):
Tabellen korrekt (Sortierung, Suche, Summe):
Fehler:
```

### 113. Zielstand am Quest-Symbol (Roadmap 340)

- [ ] geprüft

Komfort > Quests > Kill-Quest-Markierung: „Kill-Quest-Mobs markieren“ und „Zielstand am Symbol“ an, Namensplaketten an. Eine Quest „töte 8 X“ annehmen und zu den Gegnern gehen.

1. Links vom Quest-Symbol steht der Stand, z.B. „0/8“; nach jedem Kill steigt er, nach dem letzten verschwindet das Symbol.
2. Einen Questgegner anvisieren, `/lt debug log`, `/lt debug check`, danach `make debuglog` (Eintrag `quests.unitTooltip`: Zeilentypen, Texte, `completed`, gedeuteter Stand).
3. Classic Era/TBC: steht im Tooltip eines Questgegners überhaupt eine Questzeile? Wenn nicht, bleibt der Zähler leer (dann kommt er später aus gelernten Daten).

**Erwartet:** Zähler stimmt mit dem Questlog überein, kein Flackern, keine Lua-Fehler; im Kampf in Instanzen (geheime Zeilen) kein Zähler, aber auch kein Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Zähler sichtbar und richtig (ja/nein):
Tooltip-Zeilen laut Debug-Log (Typen/Text):
Fehler:
```

### 114. Questgegner und Quest-Gegenstände lernen (Roadmap 341)

- [ ] geprüft

Komfort > Quests > Lernen: „Questgegner und -gegenstände lernen“ an, `/lt debug log` an. Eine Tötungsquest („töte 8 X“) und eine Sammelquest („bringe 4 Y“, Y droppt von Gegnern) annehmen und je drei Ziele erledigen, dazu einen grauen Gegner für eine Quest töten, falls möglich.

1. `/lt debug check`, danach `make debuglog`: Eintrag `quests.learned` nennt die gelernten Namen (`openMobs`), die `quests`-Zeilen „objective .../... rose (...): learned true“.
2. Classic Era/TBC: Komfort > Quests > Kill-Quest-Markierung an. Gelernte Gegner bekommen nach dem zweiten Kill das Quest-Symbol (mit „Zielstand am Symbol“ auch den Zähler aus dem Questlog); Mouseover zeigt „Quest: Name (3/8)“.
3. Mit einem Twink dieselbe Quest annehmen: die Gegner sind sofort markiert (Classic) bzw. der Zielknopf kennt sie.
4. Ziel erfüllt: Markierung und Tooltipzeile verschwinden.

**Erwartet:** keine falschen Zuordnungen (z.B. ein zufällig gleichzeitig getöteter anderer Gegner bleibt unter 2 Treffern), keine Lua-Fehler. Retail/Forever: Tooltipzeile erscheint nicht (der Client zeigt eigene Questzeilen).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Gelernt laut Debug-Log (Namen):
Markierung/Tooltip in Classic (ja/nein):
Twink sofort markiert (ja/nein):
Falsche Zuordnungen:
Fehler:
```

### 115. Zielknopf mit gelernten Namen und Totenkopf (Roadmap 342)

- [ ] geprüft

Komfort > Quests: „Questgegner-Zielknopf“, „Ziel mit Totenkopf markieren“ und „Questgegner und -gegenstände lernen“ an. Eine Tötungsquest mit schon gelernten Gegnern (siehe 341) offen haben.

1. Der Zielknopf erscheint auch ohne sichtbare Plakette; Mouseover nennt die Namen. Klick wählt den nächsten passenden Gegner und setzt den Totenkopf, ein zweiter Klick nimmt ihn nicht wieder ab.
2. Im Kampf ein Ziel erfüllen: der Knopf ändert sich erst nach dem Kampf, ohne „Aktion blockiert“.
3. Ziel erfüllt: der Name verschwindet aus dem Mouseover des Knopfs.
4. Solo in Classic Era: setzt `/tm` überhaupt einen Marker? (Falls nicht, bitte notieren.)

**Erwartet:** keine Lua-Fehler, kein Taint-Hinweis; Makro wird nie länger als 255 Zeichen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Zielwahl mit gelernten Namen (ja/nein):
Totenkopf gesetzt, bleibt beim 2. Klick (ja/nein):
Fehler:
```

### 116. „Quest fertig“ als Einblendung (Roadmap 343)

- [ ] geprüft

Einblendungen: „Quest fertig“ und „Questziel erfüllt“ an, Stil Banner, Ton an. Allein (ohne Gruppe) eine Quest mit zwei Zielen erledigen.

1. Erstes Ziel erfüllt: Karte „Ziel erfüllt: …“ mit Questname darunter.
2. Letztes Ziel erfüllt: nur „Quest fertig: Name“ mit „+N XP bei Abgabe“ und Ton, keine zusätzliche Ziel-Karte.
3. Ziel im Kampf erfüllen: Karte kommt erst nach dem Kampf.
4. `/reload` mit einer schon fertigen Quest: keine Karte.
5. `/lt debug alert questcomplete` zeigt ein Beispiel.

**Erwartet:** XP stimmt mit dem Questlog überein (Retail: Wert nach Level), keine doppelten Karten, keine Lua-Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Ziel-/Quest-Karte (ja/nein):
XP richtig (ja/nein):
Im Kampf zurückgehalten (ja/nein):
Fehler:
```

### 117. Graue Quests aufräumen, Questlog fast voll (Roadmap 344)

- [ ] geprüft

Komfort > Quests > Questlog: Knopf „Graue Quests“ an; Hinweise > Warnungen: „Questlog fast voll“ an. Ein Charakter mit mindestens zwei grauen Quests.

1. Questlog öffnen (Classic: L, Retail/Forever: Karte mit Questliste): unter dem Fenster steht „Graue Quests (N)“; Lage und Größe ok? Überdeckt er etwas?
2. Klick: Rückfrage mit den Namen. „Nein“: nichts passiert. „Ja“: die grauen Quests verschwinden nacheinander aus dem Log, sonst keine. Danach `/lt debug log` mit `make debuglog`: Zeilen „abandoned gray quest …“.
3. Gibt es nach dem Abbruch einen Fehler „Aktion blockiert“/„Interface-Aktion fehlgeschlagen“? (Abbrechen ist laut Doku nicht geschützt, aber ungeprüft.)
4. So viele Quests annehmen, bis nur noch 2 Plätze frei sind: einmal Hinweis „N von M Quests im Log“.

**Erwartet:** nie ohne Bestätigung abgebrochen, keine Lua-Fehler; Classic: graue Quests stimmen mit der grauen Farbe im Log überein.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Knopf sichtbar und gut platziert (ja/nein):
Nur graue abgebrochen (ja/nein):
Blockiert-Fehler (ja/nein):
Hinweis „fast voll“ (ja/nein):
Fehler:
```

### 118. Abgabe-Übersicht (Roadmap 345)

- [ ] geprüft

Mit mehreren abgabebereiten Quests in verschiedenen Zonen `/lt history` > Quests > Abgabe öffnen.

1. Jede fertige Quest steht mit Zone (Überschrift im Questlog), Level, XP und „% Level“; Fußzeile mit Anzahl, XP-Summe und Summe in Prozent.
2. Maus über eine Zeile zeigt den Quest-Tooltip des Spiels.
3. Eine Quest abgeben: sie verschwindet nach spätestens 5 s aus der Liste.
4. Classic: Quests unter eingeklappten Überschriften fehlen (bekannt); bitte notieren, ob das stört.

**Erwartet:** XP stimmen mit dem Questlog überein, keine Lua-Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Liste und Summen richtig (ja/nein):
Quest-Tooltip (ja/nein):
Fehler:
```

### 119. Belohnungsempfehlung (Roadmap 346)

- [ ] geprüft

Komfort > Quests: „Belohnung empfehlen“ an. Eine Quest mit mehreren Belohnungen zur Auswahl abgeben (Questfenster) und vorher im Questlog die Details derselben Quest ansehen.

1. Die Wahl mit dem höchsten Händlerpreis hat oben links eine Goldmünze; die benutzbare Wahl mit dem größten Itemlevel-Gewinn unten links „+N“ in Grün.
2. Beim ersten Öffnen (Items noch nicht im Cache) erscheinen die Symbole kurz verzögert.
3. Sitzen die Symbole sauber auf den Knöpfen (auch im Questlog-Detail)? Überdecken sie Anzahl oder Name?
4. `/lt debug log`, danach `make debuglog`: Zeile „reward hint: value …, upgrade …, log …“.

**Erwartet:** keine automatische Wahl, keine Lua-Fehler; Ringe/Schmuck vergleichen mit dem schwächeren angelegten.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Münze richtig (ja/nein):
+N richtig (ja/nein):
Im Questlog-Detail (ja/nein):
Fehler:
```

### 120. Quest-Effizienz (Roadmap 347)

- [ ] geprüft

Nach einigen abgegebenen Quests (mit Quest-Splits, also nach der Installation angenommen) `/lt history` > Quests > Effizienz.

1. Je Quest: Abgaben, Ø Dauer, Ø XP, XP/min; Klick auf die Spaltenköpfe sortiert.
2. Komfort > Quests: „Quest-Effizienz im Tooltip“ an. Einen Quest-Link im Chat anklicken bzw. in der Tabelle mit der Maus darüber: Zeile „Bisher: Ø 3:40, 1.250 XP/min, 2x“.
3. Retail/Forever: zeigt die Questliste neben der Karte beim Überfahren einen Link-Tooltip mit dieser Zeile? (Wenn nicht, bitte notieren; Classic zeigt im Questlog keinen Tooltip.)

**Erwartet:** Werte plausibel, Twink sieht die Werte des Main, keine Lua-Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tabelle richtig (ja/nein):
Tooltipzeile an Links (ja/nein):
In der Questliste (ja/nein/kein Tooltip):
Fehler:
```

### 121. Seltene Gegner melden (Roadmap 348)

- [ ] geprüft

Einblendungen: „Rare gesichtet“ und „Dabei Taskleiste blinken“ an, Ton an. Zu einem bekannten seltenen Gegner gehen (silberner Drache am Porträt).

1. Sobald seine Plakette erscheint (oder beim Anvisieren/Mouseover): „Rare gesichtet: Name“ mit Ton; läuft WoW im Hintergrund, blinkt das Symbol in der Taskleiste.
2. Erneut hinsehen: keine zweite Meldung in dieser Session; nach Logout/Login wieder.
3. Toter Rare: keine Meldung. In Instanzen (geheime Werte in Forever): keine Fehler.
4. `/lt debug alert rarespotted` zeigt ein Beispiel.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Meldung bei Plakette/Ziel/Mouseover (ja/nein):
Taskleiste blinkt (ja/nein):
Fehler:
```

### 122. Quest-Gegenstand im Tooltip (Roadmap 349)

- [ ] geprüft

Komfort > Quests: „Quest-Gegenstände im Tooltip“ an (dazu am besten „Questgegner und -gegenstände lernen“). Eine Sammelquest offen haben und einige Gegenstände dafür in der Tasche.

1. Tooltip eines solchen Gegenstands in der Tasche: „Für Quest: Name (3/8)“ in Gelb.
2. Ein Gegenstand, dessen Name nicht im Zieltext steht (z.B. „Schuppe“ für „Schuppen gesammelt“): erscheint die Zeile erst nach dem Lernen (zweite Beute)?
3. Quest abgeben, übrig gebliebener Gegenstand: „Quest erledigt – verkaufbar“ in Grau.
4. Retail/Forever: Zeile auch im Tooltip von Händler, Beute-Fenster und Chat-Links?

**Erwartet:** Zeile nur einmal pro Tooltip, keine Lua-Fehler; keine Zeile bei normalen Gegenständen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Offene Quest mit Stand (ja/nein):
„verkaufbar“ nach Abgabe (ja/nein):
Fehler:
```

### 123. Quest-NPCs und Orte lernen, Questkarte (Roadmap 350)

- [ ] geprüft

Komfort > Quests > Lernen: „Questgegner und -gegenstände lernen“ und „Gelernte Questorte auf der Karte“ an, `/lt debug log` an. Eine Quest bei einem NPC annehmen, ein paar Ziele an verschiedenen Stellen erledigen, abgeben; eine zweite Quest annehmen und fertig machen, aber noch nicht abgeben.

1. Weltkarte: gelbe Punkte, wo die Ziele der offenen Quest vorankamen; Maus darüber nennt die Quest.
2. Fertige Quest, deren Abgabe-NPC schon bekannt ist (z.B. Twink mit derselben Quest): Fragezeichen am NPC, Tooltip „Abgabe bei Name“.
3. Historie > Quests > Abgabe: Spalte NPC mit dem gelernten Namen.
4. `make debuglog`: Zeilen „quest … giver/turnIn: Name (NPC-ID) map …“. In einer Forever-Instanz: Name ohne NPC-ID, keine Fehler.
5. Die Todeskarte (Komfort > Rahmen > Weltkarte) zeigt weiterhin die Tode (gemeinsamer Baustein).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Zielpunkte (ja/nein):
Abgabe-Fragezeichen (ja/nein):
NPC-Spalte (ja/nein):
Todeskarte noch ok (ja/nein):
Fehler:
```

### 124. Leichenpfeil (Roadmap 351)

- [ ] geprüft

Komfort > Rahmen > Weltkarte: „Leichenpfeil als Geist“ an. Draußen sterben und freilassen.

1. Als Geist erscheint oben mittig ein Pfeil mit „N Meter“ darunter. Zeigt er zur Leiche, wenn du dich drehst? Nimmt die Entfernung beim Laufen ab und stimmt sie ungefähr (z.B. mit der Minikarte)?
2. In einer anderen Zone als die Leiche (Friedhof jenseits der Zonengrenze): Pfeil weg oder richtig?
3. Wiederbelebt: Pfeil weg.
4. Als Geist `/lt debug log`, `/lt debug check`, danach `make debuglog`: Eintrag `deaths.corpseArrow` (Karte, Leiche, Breite/Höhe, Blickrichtung, Drehung, Entfernung).
5. In einer Instanz sterben (Forever: geheime Positionen): kein Pfeil, keine Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Richtung stimmt (ja/nein, um wie viel daneben):
Entfernung plausibel (ja/nein):
Andere Zone (ja/nein/weg):
Fehler:
```

### 125. Questreste in den Taschen (Roadmap 352)

- [ ] geprüft

Komfort > Quests > Questlog: „Questreste melden“ an, dazu „Questgegner und -gegenstände lernen“. Eine Sammelquest mit überzähligen Gegenständen abgeben oder eine Quest mit Quest-Item abbrechen.

1. Beim nächsten Händler: Hinweis „Questreste – Kann weg: Name (Anzahl)“. Gegenstände, die eine andere offene Quest braucht, stehen nicht dabei.
2. Verkaufen: beim nächsten Händler kein Hinweis mehr.
3. Taschen fast voll (Hinweis an): der Hinweis nennt die Questreste mit.
4. `/reload` zwischen Annahme und Abbruch: das Quest-Item wird trotzdem erkannt.

**Erwartet:** keine falschen Vorschläge (z.B. Gegenstände für Folgequests: bitte notieren), keine Lua-Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Hinweis beim Händler (ja/nein):
Falsche Vorschläge:
Fehler:
```

### 126. Themes, Akzent, Schrift und Kontur (Roadmap 357)

- [ ] geprüft

Allgemein > Aussehen. Hauptfenster, Split-Liste (Speedrun) und eine Einblendung (Einblendungen > Vorschau) sichtbar machen.

1. Stil „Klassisch“: sieht aus wie vor dem Update (goldener Tooltip-Rand, dunkler Grund, Karten ohne Rand).
2. „Flach“: dunkler Grund mit feinem grauem 1-px-Rand an Fenster, Split-Liste, Einstellungen und Karten; keine Lücken an den Ecken.
3. „Minimal“: kein Rand, Grund deutlich durchscheinender.
4. „Farbsehschwäche“: Split-Abweichungen und „Level-Up mit Quests“ blau statt grün, Tode und „langsamer“ orange statt rot.
5. Akzent Blau/Grün/Lila/Klasse: Zeit, XP-Balken und aktiver Reiter färben sich um, Gold-Elemente (Level-Up) bleiben.
6. Schriftart durchklicken (Links-/Rechtsklick), Schriftgröße +4 und −2, Kontur dünn/dick: Fenster wächst mit, nichts wird abgeschnitten; mit ElvUI/SharedMedia erscheinen deren Schriften.
7. Deckkraft 0 (Allgemein > Fenster): kein schwebender Goldrahmen mehr.
8. Chroma Grün (Stream): weiterhin deckend grün ohne Rand, auch im Stil „Flach“.

**Erwartet:** live ohne /reload, keine Lua-Fehler; ruRU/zh-Clients: „Spiel-Standard“ zeigt alle Zeichen.
### 127. Positionen nach dem Update (Roadmap 358)

- [ ] geprüft

Vor dem Update: Hauptfenster, Split-Liste, Einblendungen, Level-Up-Fenster und (falls genutzt) Lagerfeuer, Essen, Flug, Quest-Knöpfe und Stream-Goal-Tracker an eigene Stellen mit eigener Größe setzen. Update einspielen, Client neu starten (neue Dateien in der `.toc`).

1. Alle Anzeigen stehen an derselben Stelle in derselben Größe wie vorher.
2. Ein zweites Profil mit anderen Positionen: Wechsel setzt alle Anzeigen um, zurück ebenso.
3. `/lt lock`: Hauptfenster und Split-Liste lassen sich nicht mehr ziehen, kein Größengriff; `/lt unlock` wieder.
4. `/lt reset`: alle Anzeigen springen auf ihre Standardplätze (Hauptfenster oben Mitte, Einblendungen darunter).

**Erwartet:** nichts springt beim Login oder `/reload`, keine Lua-Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Positionen übernommen (ja/nein, welche nicht):
Profilwechsel ok (ja/nein):
Fehler:
```

### 128. Edit-Modus (Roadmap 359)

- [ ] geprüft

`/lt edit` (oder „Layout bearbeiten“ unten in den Einstellungen, oder Shift-Rechtsklick auf den Minimap-Knopf).

1. Alle Anzeigen erscheinen mit Beispielinhalt und einer farbigen, beschrifteten Fläche (Name und Größe in %), oben eine Leiste mit Hinweis und Knöpfen; das Raster liegt hinter allem.
2. Ziehen: die Anzeige folgt der Maus; beim Loslassen rastet sie sichtbar am Raster, an der Bildschirmmitte oder an der Kante einer anderen Anzeige ein; mit gehaltenem Shift nicht.
3. Mausrad über einer Anzeige ändert ihre Größe in 5-%-Schritten; die Fläche wächst mit.
4. Anzeige anklicken, dann Pfeiltasten: 1 px je Druck, mit Shift 10 px. Andere Tasten (WASD) bewegen weiter den Charakter.
5. Rechtsklick: kleines Menü mit Größen-Regler, Zurücksetzen, Ausblenden, Einstellungen (öffnet den passenden Reiter), Schließen.
6. Esc oder „Fertig“: alles verschwindet, Anzeigen zeigen wieder ihren echten Zustand.
7. Im Edit-Modus einen Gegner angreifen: der Modus endet mit Chatzeile, kein „Aktion blockiert“.
8. Retail/Forever: Esc > Bearbeitungsmodus öffnet die Flächen mit, Verlassen schließt sie (Einstellung „Mit Blizzards Bearbeitungsmodus“).

**Erwartet:** keine Lua-Fehler, kein Taint-Hinweis, Text der Leiste passt in allen vier Sprachen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Ziehen/Einrasten ok (ja/nein):
Mausrad/Pfeiltasten ok (ja/nein):
Menü ok (ja/nein):
Kampf beendet sauber (ja/nein):
Blizzard-Modus (nur Retail/Forever):
Zeile unter dem Würfelfenster (ja/nein, überdeckt etwas?):
Zahlen stimmen (ja/nein):
Tooltip mit Namen (ja/nein):
Chatzeile (ja/nein):
Ersatzkarte (ja/nein/nicht getestet):
Fehler:
```

### 129. Beute-Würfe: Zähler, Tooltip, Ersatzkarte (Roadmap 364)

- [ ] geprüft

Komfort > System > Würfeln um Beute: alle vier Schalter an. In einer Gruppe (Dungeon) um grüne oder bessere Beute würfeln.

1. Unter jedem Blizzard-Würfelfenster eine Zeile: Würfel, Münze, Passen-Symbol und Sanduhr mit Zahlen; Entzaubern/Transmog nur, wenn jemand sie wählt. Die Zahlen steigen, während die anderen wählen; die Zeile überdeckt nichts (auch nicht das nächste Würfelfenster).
2. Maus über einen Zähler: Namen in Klassenfarbe, nach dem Würfeln mit Zahl.
3. Nach dem Würfeln eine Chatzeile „Gegenstand: Name gewinnt mit 87 (Bedarf). Bedarf 2, Gier 1, Passen 2“; bei „alle gepasst“ eine kurze Zeile.
4. Eigener Gewinn (selten oder besser): Historie > Beute zeigt in der Spalte „Wurf“ Symbol und Zahl.
5. Mit einem Addon, das die Würfelfenster ersetzt (z.B. ElvUI-Beutewürfe), oder mehr als vier Würfen gleichzeitig (Retail): die Karte „Würfe“ listet die Gegenstände mit Zählern; im Edit-Modus (`/lt edit`) erscheint sie mit Beispielwürfen und lässt sich verschieben und skalieren.

**Erwartet:** keine Lua-Fehler, kein „Aktion blockiert“, Zähler stimmen mit Blizzards Beute-Historie überein.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Klassisch wie vorher (ja/nein):
Flach/Minimal sauber (ja/nein, was fällt auf):
Schriften/Kontur ok (ja/nein):
Fehler:
```

### 131. Blizzard-XP- und Rufleiste ausblenden (Roadmap 365)

- [ ] geprüft

Komfort > Oberfläche > „Blizzard-XP-Leiste ausblenden“ und „Blizzard-Rufleiste ausblenden“ (eine Fraktion beobachten), dazu der Schalter in der Leiste von `/lt edit`. Vorher und nachher `/lt debug check` (Prüfung `365.blizzardXpBar`).

1. XP-Leiste aus: Blizzards Erfahrungsleiste samt Rahmen und Ruhe-Marke ist weg, Mausover zeigt keinen Tooltip; die Aktionsleisten bleiben, wo sie waren (Lücke darüber).
2. Rufleiste aus: die Leiste der beobachteten Fraktion ist weg, die XP-Leiste bleibt (wenn sie an ist).
3. Im Kampf umschalten: ändert sich erst nach dem Kampf, kein „Aktion blockiert“.
4. Wieder an: beide Leisten sehen aus wie vorher (Rahmen, Text bei Mausover, Ruhe-Marke).
5. Retail/Forever: Esc > Bearbeitungsmodus, die Leisten verschieben: kein Taint-Hinweis, nach dem Verlassen bleiben ausgeblendete Leisten unsichtbar.
6. Level-Up auf Max-Level oder andere Fraktion beobachten: Blizzard wechselt die Leiste im Behälter, der Rahmen folgt (bleibt nicht leer stehen).

**Erwartet:** keine Lua-Fehler, kein Taint-Hinweis; Classic: ob die Lücke über der Hauptleiste stört (Blizzard zeigt die Max-Level-Leiste nicht, weil der Behälter weiter da ist).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
XP-Leiste weg (ja/nein):
Rufleiste weg (ja/nein):
Kampf wartet (ja/nein):
Zurück wie vorher (ja/nein):
Lücke stört (ja/nein):
Fehler:
```

### 132. Flugzeiten im Tooltip und geschätzte Restzeit (Roadmap 370)

- [ ] geprüft

Einstellungen > Timer > Flüge: „Flugzeiten“ und „Flugzeit im Tooltip“ an. Einen Flugmeister ansprechen.

1. Maus auf ein Ziel der Flugkarte: unter Name und Preis steht „Flugzeit 2:21 (dein Flug)“ (blau) bei schon geflogenen Strecken, „~2:20 (geschätzt)“ (grau) bei anderen, sobald auf dieser Karte einmal geflogen wurde; nichts am eigenen Standort. Die Zeile passt in den Tooltip, kein doppelter Tooltip, kein Flackern.
2. Retail/Forever mit der großen Flugkarte (Weltkarten-Stil): dasselbe auf den Flugpunkt-Symbolen.
3. Eine nie geflogene Strecke abfliegen: die Flug-Anzeige zeigt die Restzeit grau mit „~“ (z.B. „~2:20“) und läuft herunter; nach der Landung dieselbe Strecke noch einmal: normale Farbe, ohne „~“.

**Erwartet:** keine Lua-Fehler, kein „Aktion blockiert“ beim Abflug über die Flugkarte, Text passt in allen vier Sprachen.

### 136. Quest-Knöpfe nur in der Zone der Quest (Roadmap 366)

- [ ] geprüft

Komfort > Quests: „Quest-Item-Knopf“, „Questgegner-Zielknopf“ und „Quest-Knöpfe nur in der Zone der Quest“ an. Zwei Quests mit benutzbarem Gegenstand aus verschiedenen Zonen im Log. Datenteil per Debug-Log: debug `questitem` (quest … zone …), check `268.questItem.pick` (`here`, `inZone` und `zoneSignals` je Kandidat).

1. In der Zone der ersten Quest: der Knopf zeigt deren Gegenstand, nicht den der anderen Zone.
2. In die andere Zone reisen (oder fliegen): der Knopf wechselt beim Zonenwechsel ohne Verzögerung zum anderen Gegenstand; im Kampf erst danach.
3. In einer Zone ohne passende Quest: Knopf weg (Klassen- oder Saisonquests mit Gegenstand bleiben sichtbar).
4. In einer Höhle oder einem Gebäude mit eigener Karte (z.B. Mine): der Knopf bleibt wie in der Zone darüber.
5. Schalter aus: der Knopf zeigt wieder die nächste bzw. zuletzt angenommene Quest wie vorher.

**Erwartet:** keine Lua-Fehler, kein „Aktion blockiert“; nichts verschwindet, was in der Zone gebraucht wird.
### 137. Blizzard-Oberfläche ausblenden (Roadmap 371)

- [ ] geprüft

`/lt edit`: über jedem Blizzard-Element liegt eine graue Fläche mit Namen und Haken „Ausgeblendet“; dazu Komfort >
Oberfläche > „Blizzard-Oberfläche“. Vorher und nachher `/lt debug check` (Prüfung `371.blizzardFrames`).

1. Edit-Modus: Flächen über Spieler-, Ziel-, Gruppenrahmen, Minimap, Uhr, Buffs, Tracker, Chat, Aktionsleisten,
   Mikromenü, Taschen; kleine Flächen (Uhr, Gebietsname) liegen über der Minimap und sind anklickbar.
2. Haken setzen: das Element verschwindet, die Fläche wird dunkel und heißt „… (ausgeblendet)“; Haken weg: es sieht
   aus wie vorher (Deckkraft, Maus, Tooltip).
3. Ausgeblendete Aktionsleiste: Tasten wirken weiter, unsichtbare Knöpfe lassen sich nicht anklicken.
4. Minimap ganz aus: ist die Karte selbst weg oder bleibt sie sichtbar (Rahmen weg, Karte da)?
5. Zauberleiste aus: beim Zaubern nichts zu sehen, auch kein kurzes Aufblitzen am Ende?
6. Buffs/Gruppenrahmen aus, dann neue Buffs bekommen bzw. Gruppe wechseln: lassen sich unsichtbare Buff-Symbole
   rechtsklicken (Buff weg)?
7. Im Kampf in den Optionen umschalten: ändert sich erst nach dem Kampf, kein „Aktion blockiert“.
8. Retail/Forever: Esc > Bearbeitungsmodus mit ausgeblendeten Elementen öffnen und schließen: kein Taint-Hinweis,
   ausgeblendete bleiben unsichtbar; Deckkraft im Blizzard-Edit-Mode ändern und danach wieder einblenden: Blizzards
   Deckkraft gilt.
9. Schalter „Blizzard-Elemente zeigen“ in der Leiste aus: die grauen Flächen verschwinden, unsere Anzeigen bleiben.

**Erwartet:** keine Lua-Fehler, kein Taint-Hinweis (`ADDON_ACTION_BLOCKED` im Debug-Log).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tooltip-Zeile gemessen/geschätzt ok (ja/nein):
Große Flugkarte (nur Retail/Forever):
Anzeige grau mit ~, danach normal (ja/nein):
Fehler:
```

### 142. Kills und Beute je Stunde (Roadmap 382)

- [ ] geprüft

Statistiken > Voreinstellung „Farmen“ (oder einzeln: Kämpfe > Kills/h und Kills der letzten 15 min, Beute >
Gegenstände erbeutet und Gegenstände der letzten 15 min). 15 Minuten farmen, dabei einmal beim Händler etwas kaufen.

1. Reiter Level/Session/Instanz: Kills/h und Gegenstände/h ändern sich je Reiter; mit „XP/h ohne AFK“ und kurzem AFK
   steigen sie wie XP/h.
2. Kills (15 min) zählt jeden Kill sofort, nach einer Pause fallen alte Kills heraus (Zahl sinkt ohne Kill).
3. Ein Stapel (z.B. 5 Leinenstoff) zählt 5; graue Beute zählt; Beute anderer Gruppenmitglieder zählt nicht.
4. Kauf beim Händler: Gegenstände bleiben gleich; Questbelohnung zählt.
5. Layout Leiste und Kacheln, Sprache Französisch/Spanisch: Kurzlabels lesbar, nichts abgeschnitten.
6. Historie > Sessions und Level: Spalten Kills/h und Items/h passen in die Breite.

**Erwartet:** keine Lua-Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Raten je Reiter ok (ja/nein):
15 min gleitet (ja/nein):
Stapel/Kauf richtig (ja/nein):
Beute in Instanzen gezählt (ja/nein):
Layouts/Spalten passen (ja/nein):
Fehler:
```

### 133. Layouts des Hauptfensters (Roadmap 360)

- [ ] geprüft

Einstellungen > Allgemein > Anzeige: jedes Layout einmal wählen (am besten im Edit-Modus, `/lt edit`), in Deutsch und Französisch.

1. Tabelle: sieht aus wie vor dem Update (Reiter, Zeit, XP-Balken, Zeilen).
2. Leiste (`/lt bar`): eine Zeile mit Kurzbezeichnungen („Niveau“ statt „Prochain niveau dans“), XP-Balken darunter.
3. Kompakt (`/lt compact`): Zeit, Balken und die drei gewählten Werte („Wert 1–3“); ohne Wahl nur Zeit und Balken.
4. Text: kein Grund, kein Rand, Schrift mit Kontur, gut lesbar über hellem und dunklem Gelände; mit Hintergrund „Grün“ deckend grün (OBS).
5. Uhr: große Zeit, darunter die gewählten Werte in einer Zeile.
6. XP-Balken: schmaler Balken mit Level/Prozent links, Zeit in der Mitte, Werten rechts; „Texte auf dem Balken: Maus“ zeigt sie nur beim Überfahren; Breite per Regler.
7. Kacheln: Raster mit Zeit-Kachel zuerst, Spaltenzahl per Regler; Kacheln gleich breit, nichts ragt über den Rand.
8. Nicht passende Einstellungen (z.B. Spalten bei Tabelle) sind ausgegraut.
9. Statistiken > Reihenfolge der Zeilen: Zeile wählen, „Nach oben/unten“ verschiebt sie sofort im Fenster.

**Erwartet:** keine Lua-Fehler, kein abgeschnittener Text, kein Springen der Breite im Sekundentakt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Layouts ok (je Layout ja/nein):
Text-Layout lesbar (ja/nein):
Reihenfolge ok (ja/nein):
Fehler:
```

### 134. XP-Tooltip (Roadmap 360)

- [ ] geprüft

Maus auf den XP-Balken (Tabelle, Leiste, Kompakt, Uhr, Kacheln und Layout XP-Balken), einmal mit und einmal ohne Erholung.

1. Tooltip unter dem Balken: „XP: 12.345 / 31.700 (38,9 %)“, „Bis zum Level-Up“, Erholungs-XP mit Anteil am Level und wie viel vom Rest sie deckt, fertige Quests (wenn welche abgabebereit sind).
2. Während der Tooltip offen ist, einen Gegner töten: die Zahlen ändern sich sofort.
3. Fenster lässt sich auch über dem Balken ziehen, Rechtsklick auf den Balken öffnet die Einstellungen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tooltip ok (ja/nein):
Aktualisiert beim Kill (ja/nein):
Ziehen über dem Balken (ja/nein):
Fehler:
```

### 135. Sichtbarkeitsregeln (Roadmap 362)

- [ ] geprüft

Allgemein > Anzeige > „Fenster sichtbar“ und Speedrun > „Split-Liste sichtbar“, „Abgeblendet“ auf 30 % und auf 0 %.

1. „Nicht im Kampf“: im Kampf blendet das Fenster ab (bzw. verschwindet bei 0 %), danach wieder voll.
2. „Nur in Instanzen“: draußen ab, im Dungeon voll.
3. „Bei Mauskontakt“: nur beim Überfahren voll sichtbar, auch über den Reitern; bei 0 % unsichtbar, aber per Maus auffindbar.
4. Im Edit-Modus sind beide Anzeigen immer voll da.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Regeln ok (ja/nein):
Maus über Reitern bleibt sichtbar (ja/nein):
Richtiger Gegenstand je Zone (ja/nein):
Wechsel beim Zonenwechsel (ja/nein):
Fremde Zone: Knopf weg (ja/nein):
Höhle/Gebäude ok (ja/nein):
Fehlt etwas zu Unrecht (welche Quest, Überschrift im Log):
Flächen richtig (ja/nein, welche fehlen):
Ausblenden und zurück (ja/nein):
Minimap-Karte weg (ja/nein):
Zauberleiste blitzt (ja/nein):
Unsichtbare Buffs klickbar (ja/nein):
Kampf wartet (ja/nein):
Fehler:
```

### 139. Schlafsack-Hinweis (Roadmap 394, WoW Forever)

- [ ] geprüft

Einstellungen > Hinweise: „Hinweis: Gut erholt fehlt (Schlafsack)“ an, „Gemütlicher Schlafsack“ in der Tasche, unter Maximallevel, draußen und ohne „Gut erholt“. Datenteil: `/lt debug remind` (Zeile „well rested missing …“).

1. Nach spätestens 2 s erscheint die Hinweis-Karte „Im Schlafsack ausruhen für 3 % XP-Bonus.“ mit dem Symbol des Schlafsacks (nicht dem allgemeinen Taschen-Symbol).

**Antwort:**

```text
Karte mit Schlafsack-Symbol (ja/nein):
Zeile von /lt debug remind:
Fehler:
```

### 138. Profiler-Vergleich nach Performance-Runde 2 (Roadmap 390-401)

- [ ] geprüft

Gleiche Art Sitzung wie beim letzten Lauf (WoW Forever, leveln mit Quest-Knöpfen, Lagerfeuer, Buff-Hinweisen, Beute-Glitzer, Debug-Log an), etwa 30 Minuten:

```
/lt debug perf reset
```

```
/lt debug perf on
```

Nach der Sitzung:

```
/lt debug perf report 25
```

**Erwartet (vorher → Ziel):** `task QuestItemButton.lua` 43,7 MB Müll → unter 1 MB; `task CampFire.lua` 6,8 MB → deutlich weniger; `task QuestWatch.lua` 5,8 MB → weniger; `task BuffReminder.lua` max 7 ms → unter 2 ms; `call Options.lua` und `call ActionBars.lua` je Apply → fast nichts bei geschlossenem bzw. fremdem Apply; `event CVAR_UPDATE` 737 → deutlich weniger; `onupdate TimerWindow` deutlich unter 3,2 s; `onupdate DeathMap`/`QuestMap` ohne 31-ms-Spitzen; kein „kills line for <Spieler>“ und keine Serien „icon … INV_Misc_Note_01“ im Debug-Log.

**Antwort:**

```text
Bericht (/lt debug perf report 25):
Sitzungsdauer:
Fehler:
```

### 140. Einstellungen in Kategorien (Roadmap 380)

- [ ] geprüft

`/lt` öffnen, in Deutsch, Französisch und Spanisch (Allgemein > Sprache & Minimap).

1. Reiter: Allgemein, Statistiken, Hinweise, Einblendungen, Komfort, Speedrun, Profile; alle außer Profile mit
   Seitenleiste links, Inhalt rechts daneben, nichts überlappt (auch die rechte Schalter-Spalte nicht).
2. Jede Kategorie einmal anklicken: das Fenster springt nicht in der Höhe, keine Seite braucht Scrollen (außer bei
   kleinem Bildschirm/hoher UI-Skalierung), beim Kategoriewechsel steht die Seite oben.
3. Komfort > Quests: Quest-Automatik, Questfortschritt, „Questlog fast voll“ und die Quest-Einblendungen stehen dort;
   Allgemein > Stream und Einblendungen > Timer/Flüge funktionieren wie vorher.
4. Edit-Modus (`/lt edit`): Rechtsklick auf Split-Liste, Einblendung, Level-Up-Fenster, Flug-Anzeige > „Einstellungen“
   öffnet die passende Kategorie.
5. Fenster schließen und wieder öffnen: dieselbe Kategorie ist noch gewählt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Sprache(n):
Überlappungen (wo):
Höhe/Scrollen ok (ja/nein):
Sprünge aus dem Edit-Modus ok (ja/nein):
Fehler:
```

### 141. Suche in den Einstellungen (Roadmap 381)

- [ ] geprüft

`/lt`, Suchfeld oben links („Suchen …“).

1. „Repar“ tippen: Liste unter dem Feld mit „Automatisch reparieren — Komfort > Automatik“ usw., über Reitern und
   Inhalt, nicht abgeschnitten; Mausrad/Klicks gehen nicht durch die Liste auf die Schalter darunter.
2. Treffer anklicken: Reiter und Kategorie wechseln, der Schalter ist kurz hell hinterlegt (Fläche über Kästchen und
   Text, nicht verrutscht), nach 2 s weg.
3. Tiefe Einstellung (z.B. „Atem“, „Munition“ als Jäger) mit Enter: Seite scrollt so, dass sie oben steht.
4. Ein Wort nur aus einem Tooltip (z.B. „Gruppenchat“): Treffer erscheinen hinter den Beschriftungs-Treffern.
5. Esc im Feld leert es und schließt die Liste; Esc danach schließt das Fenster. Tippen in das Feld löst keine
   Tastenbelegungen aus (Bewegen, Zauber).
6. Französisch/Spanisch: Feld und Titel überlappen nicht.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Liste lesbar und oben (ja/nein):
Hervorhebung sitzt richtig (ja/nein):
Scrollen zum Treffer (ja/nein):
Tastatur ok (ja/nein):
Fehler:
```

### 150. Chat bis an den Rand und eigene Schriftgröße (Roadmap 329, Schritt 3c)

- [ ] geprüft

Komfort > Chat: „Chat bis an den Rand“, „Eigene Chat-Schriftgröße“ mit Regler.

1. Rand an: Chatfenster lässt sich ganz an den linken und unteren Bildschirmrand ziehen; aus: der alte Abstand gilt
   wieder (Fenster springt beim nächsten Ziehen zurück).
2. Schriftgröße an, Regler auf 10 und 26: alle Chatfenster (auch Kampflog) ändern sich sofort; Rechtsklick auf einen
   Reiter > Schriftgröße zeigt Blizzards Menü weiter normal.
3. /reload: Größe bleibt; ausschalten: jedes Fenster bekommt seine vorherige Größe zurück.
### 143. Rechtsklick auf Anzeigen öffnet ihre Einstellungen (Roadmap 404)

- [ ] geprüft

Außerhalb des Edit-Modus nacheinander rechtsklicken: Hauptfenster (und Level-/Session-Reiter), Split-Liste
(`/lt splits`), Flug-Anzeige während eines Flugs, Essen-/Lagerfeuer-Anzeige (Vorschau in den Einstellungen),
Level-Up-Fenster (Vorschau), Beute-Wurf-Karte (falls sichtbar).

1. Jede Anzeige öffnet die Einstellungen auf ihrer eigenen Unterseite; ein zweiter Rechtsklick schließt sie.
2. Linksklick auf das Level-Up-Fenster schließt es weiter; Ziehen von Hauptfenster/Split-Liste geht weiter.
3. Die Einblendung (Level-Up-Banner, Warnungen) bleibt klickdurchlässig: Klick durch sie auf einen Gegner wählt ihn.
4. Flug-/Essen-Anzeige: schluckt sie Klicks, die stören (z.B. auf Gegner hinter ihr)?

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Rand ok (ja/nein):
Schriftgröße ok, auch nach /reload (ja/nein):
Fehler:
```

### 151. Tooltip am Mauszeiger, Größe, Gildenrang (Roadmap 329, Schritt 4c)

- [ ] geprüft

Komfort > Fenster > Tooltip: „Tooltip in der Welt“, „Tooltip-Größe“, „Gildenrang im Tooltip“.

1. „Mauszeiger“: Tooltip von Gegnern, NPCs und Objekten (Briefkasten, Erz) folgt dem Zeiger; Tooltips an
   Aktionsknöpfen und Taschen bleiben, wo sie waren. „Links/Rechts vom Zeiger“ ebenso.
2. Größe 150 %: Gegenstands-Tooltip und Vergleichs-Tooltip größer, Link im Chat anklicken (ItemRefTooltip) auch;
   zurück auf 100 %: wie vorher.
3. Gildenrang: Spieler einer Gilde überfahren, hinter dem Gildennamen steht „(Rang)“; eigene Gilde ebenso.
richtige Unterseite je Anzeige (ja/nein, welche nicht):
Einblendung klickdurchlässig (ja/nein):
Timer-Anzeigen stören (ja/nein):
Fehler:
```

### 144. Eintrag im Blizzard-Einstellungsmenü (Roadmap 403)

- [ ] geprüft

Esc > Optionen > Reiter „AddOns“ > „Level Time“.

1. Seite zeigt Titel, Kurztext (umbricht, nicht abgeschnitten) und den Button „Level-Time-Einstellungen öffnen“.
2. Button: unser Fenster öffnet über dem Blizzard-Menü (nicht dahinter); Esc schließt erst unser Fenster, dann das Menü.
3. Danach im Blizzard-Menü eine Einstellung ändern und „Schließen“: keine Meldung „Aktion blockiert“/kein Taint
   (BugSack leer), Tastenbelegungen bleiben gespeichert.
4. Französisch/Spanisch: Button-Text passt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Anker richtig, nur Welt-Tooltips (ja/nein):
Größe ok (ja/nein):
Gildenrang sichtbar (ja/nein):
Fehler:
```

### 152. Eckige Minimap (Roadmap 329, Schritt 4c)

- [ ] geprüft

Komfort > Fenster > Minimap: „Eckige Minimap“.

1. An: Minimap eckig, runder Rahmen weg, Kartenrand sauber; Addon-Knöpfe (LibDBIcon) sitzen am eckigen Rand.
2. Forever: Minimap drehen (Interface-Einstellung) bleibt eckig.
3. Aus: wieder rund mit Rahmen (Retail: Maske `Interface\Masks\CircleMaskScalable`, Classic `Textures\MinimapMask`
   ungeprüft; Forever nutzt Blizzards UpdateMinimapConfig).
Eintrag vorhanden (ja/nein):
Fenster liegt oben (ja/nein):
Taint/Fehler beim Schließen (ja/nein):
Fehler:
```

### 145. Standard je Kategorie (Roadmap 405)

- [ ] geprüft

`/lt`, z.B. Einblendungen > Stil & Position: Stil, Dauer, Ton, Größe ändern.

1. Unter der Seitenleiste steht „Standard“ (nicht über einem Eintrag, nicht abgeschnitten, auch in fr/es).
2. Klick: Rückfrage nennt „Stil & Position“; Ja setzt nur diese Werte zurück (Ereignisse-Schalter bleiben), Chatzeile.
3. „Rückgängig“ erscheint darunter und stellt die Werte wieder her; danach verschwindet es.
4. Allgemein > Sprache & Minimap: „Standard“ zeigt den Minimap-Button wieder, seine Position am Rand bleibt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
eckig ok (ja/nein):
wieder rund nach Aus (ja/nein):
Fehler:
```

### 153. Questtext-Größe (Roadmap 329, Schritt 4c)

- [ ] geprüft

Komfort > Quest-Anzeige: „Questtext-Größe ändern“, Regler.

1. Questgeber ansprechen: Text, Ziele und Überschrift in der Reglergröße, nichts abgeschnitten.
2. Questlog (Classic: Questlog-Fenster, Retail/Forever: Kartenquests) ebenso.
3. Aus: Blizzards Größen sofort zurück.
Buttons gut platziert (ja/nein):
nur die Kategorie zurückgesetzt (ja/nein):
Rückgängig ok (ja/nein):
Fehler:
```

### 146. Einklappbare Abschnitte (Roadmap 406)

- [ ] geprüft

`/lt` > Komfort > Ausblenden und Komfort > Quests.

1. Ausblenden zeigt die Blizzard-Elemente in Gruppen (Einheitenrahmen, Minimap/Buffs/Tracker, Aktionsleisten, Weitere).
2. Klick auf eine Überschrift („-“ davor) klappt sie ein („+“), die Gruppen darunter rücken ohne Lücke hoch.
3. Suche nach einem Element einer eingeklappten Gruppe (z.B. „Zielrahmen“): Gruppe klappt auf, Treffer hervorgehoben.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Größe wirkt (ja/nein):
Fehler:
```

### 154. Bildschirmränder (Roadmap 329, Schritt 4c)

- [ ] geprüft

Komfort > Oberfläche > Bildschirmränder.

1. An, oben 60, unten 80, seitlich 40: schwarze Balken, Aktionsleisten und Chat liegen darüber.
2. Klicks auf die Spielwelt im Balkenbereich gehen weiter (Maus aus).
3. Alt+Z (Oberfläche aus): Balken verschwinden mit.
Gruppen sinnvoll (ja/nein):
Einklappen ohne Lücken/Überlappung (ja/nein):
Fehler:
```

### 147. Einfach/Erweitert (Roadmap 402)

- [ ] geprüft

`/lt`, Haken „Erweitert“ oben rechts neben dem X.

1. Haken und Beschriftung überlappen weder Titel noch X (auch fr/es).
2. Haken aus: z.B. Hinweise > Erinnerungen ohne Intervall-Regler, die Bausteine darunter rücken ohne Lücke nach;
   Statistiken: „Reihenfolge“ und „Berechnung“ fehlen in der Seitenleiste, die übrigen rücken hoch.
3. Suche „Leerlauf“: Treffer schaltet den Haken wieder an und zeigt die Seite.
4. Haken bleibt nach /reload, wie er war.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Balken unter der Oberfläche (ja/nein):
Klicks gehen durch (ja/nein):
Fehler:
```

### 155. Bereit-Timer (Roadmap 329, Schritt 4c)

- [ ] geprüft

Komfort > System > „Bereit-Timer“.

1. In einer Gruppe einen Bereitschaftscheck starten lassen: unter Blizzards Fenster „Bereitschaftscheck: 30 s“, zählt
   herunter, verschwindet nach Antwort/Ende.
2. Schlachtfeld-Warteschlange bis zur Einladung: „Schlachtfeld betreten: 1:25“ oben in der Mitte.
Platz oben rechts ok (ja/nein):
Seiten ohne Lücken (ja/nein):
Fehler:
```

### 148. Willkommenskarte (Roadmap 363)

- [ ] geprüft

Neuer Account-Stand (oder `/lt welcome`).

1. Beim ersten Start mittig eine Karte mit drei Schritten; Texte nicht abgeschnitten (auch fr/es), Buttons in einer Zeile.
2. Voreinstellung und Layout ändern das Hauptfenster sofort, das gewählte Layout ist hervorgehoben.
3. „Position anpassen“ schließt die Karte und startet den Edit-Modus; Esc schließt die Karte.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Bereitschaftscheck (ja/nein):
Schlachtfeld (ja/nein):
Fehler:
```

### 156. Spielerrahmen in Classic: Klassenfarbe, Drache, Druiden-Mana (Roadmap 329, Schritt 4c)

- [ ] geprüft

Classic Era/Anniversary. Komfort > Fenster > Einheitenrahmen.

1. „Klassenfarbe am Spielerrahmen“: farbiger Balken hinter dem Namen, gleiche Lage wie beim Ziel (gespiegelt).
2. „Rahmen am Spieler“ Elite/Rar/Rar-Elite: Drache sitzt passend um den Rahmen (keine doppelten Kanten, Porträt
   frei); Aus: Blizzards Rahmen.
3. Druide: „Druiden-Manaleiste“, in Bär/Katze schmale Manaleiste unter der Wut-/Energieleiste mit Zahl; in
   Normalgestalt weg.

**Antwort:**

```text
Client (Era/TBC):
Namenshintergrund sitzt (ja/nein):
Drache sitzt (ja/nein, Versatz?):
Manaleiste ok (ja/nein):
Fehler:
```

### 157. Anprobe-Knöpfe und Flugkarte verschieben (Roadmap 329, Schritt 4c)

- [ ] geprüft

Komfort > Fenster > Charakterfenster: „Anprobe-Knöpfe“; Komfort > Oberfläche: „Fenster verschieben“.

1. Strg+Klick auf ein Ausrüstungsteil: Anprobe offen, links neben „Zurücksetzen“ „Ausziehen“ und „Wappenrock“.
   Beide wirken auf das Modell; „Zurücksetzen“ zieht wieder an.
2. Retail/Forever: Flugmeister, Flugkarte am Rand ziehen und mit Strg+Mausrad skalieren; Flugpunkte bleiben klickbar.
Karte lesbar (ja/nein):
Schritte wirken (ja/nein):
Fehler:
```

### 149. Mindestschrift, Balkentexturen, Farbe nach Wert (Roadmap 361)

- [ ] geprüft

`/lt` > Allgemein > Aussehen.

1. Mindestschriftgröße 10 pt, Schriftgröße -4: alle Anzeigen bleiben lesbar; Hauptfenster per Mausrad im Edit-Modus
   lässt sich nicht kleiner ziehen, als die Schrift erlaubt.
2. Balkentextur: Verlauf, Glanz, Blizzard nacheinander; XP-Balken und der Zeitbalken einer Karte (Essen/Flug-Vorschau)
   ändern sich, Farben bleiben (Akzent, Erholung blau). Mit einem Addon, das LibSharedMedia lädt: dessen Balken in der Liste.
3. Farbe nach Wert an: XP/h grün/rot je nach Schnitt der letzten Level; Theme „Farbsehschwäche“: blau/orange.
4. Split-Liste mit Vergleich: „Gesamt“ hellgrün, wenn man vorn liegt, das laufende Level aber langsamer läuft.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Anprobe-Knöpfe ok (ja/nein):
Flugkarte verschiebbar, Punkte klickbar (ja/nein):
Fehler:
```

### 158. Infokarte und Communities als Freunde (Roadmap 329, Schritt 3c/4c)

- [ ] geprüft

Komfort > Fenster > Tooltip „Infokarten“, Taste unter Tastaturbelegung > AddOns > Level Time „Infokarte“;
Komfort > Sozial „Communities als Freunde“.

1. Gegenstand in der Tasche, Zauber im Zauberbuch, NPC in der Welt überfahren und Taste drücken: Kopierfenster mit
   Name, Art, ID und Wowhead-Link (Forever: Classic-Link, prüfen, ob der Link passt).
2. Mitglied einer Charakter-Community lädt in eine Gruppe ein (mit „Gruppe von Freunden annehmen“): wird angenommen.
Schrift lesbar, Grenze greift (ja/nein):
Texturen sehen gut aus (ja/nein, welche nicht):
Farben verständlich (ja/nein):
Fehler:
```

### 159. Tabellenköpfe, Split-Kopfzeile, Unterstrich und Legende (Roadmap 203, 215, 216)

- [ ] geprüft

1. `/lt history` auf Französisch und Spanisch: Kills, Tode, Quests, Level: kein Spaltenkopf abgeschnitten
   („Rare-Elite“, „Muertes“, „Misiones“, „Victimes“, „Abatidos“); Tabelle nicht breiter als vorher.
2. Split-Liste: oben „Level / Zeit / ±“ in leiser Farbe, Spalten darunter bündig; Maus über der Liste zeigt den Tooltip.
3. Aktive Reiter (Optionen, Seitenleiste, Historie, Hauptfenster) haben einen feinen Strich unter dem Text.
4. Historie > Diagramme (Zeit je Level, Kills je Tag): rechts oben „laufend / heute“ mit blauem Feld.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Infokarte ok, Link passt (ja/nein):
Community-Einladung angenommen (ja/nein):
Köpfe vollständig (ja/nein, welche nicht):
Kopfzeile ok (ja/nein):
Unterstrich und Legende sichtbar (ja/nein):
Fehler:
```

## Level Time Goals (Roadmap 295-312)

### 170. Einstellungen, Tracker und Fenster im Look von Level Time (Roadmap 312)

- [ ] geprüft

1. `/sg options`: Fenster mit Seitenleiste Tracker / Meldungen / Daten, Suche oben links findet „Karten höchstens“;
   jedes Steuerelement hat einen Tooltip; Texte auf Französisch und Spanisch nicht abgeschnitten.
2. „Karten höchstens“ 2 bei vier Zielen: zwei Karten, darunter „+2 weitere Ziele“; Kartenfarbe „Akzentfarbe“ färbt
   alle Karten in der Akzentfarbe des Level-Time-Themes, Theme-Wechsel in Level Time färbt live mit.
3. Rechtsklick auf eine Karte öffnet die Unterseite Tracker, zweiter Rechtsklick schließt; Linksklick auf ein eigenes
   Ziel +1, Shift+Linksklick -1.
4. `/lt edit` ohne Ziele: Beispielkarte; Rechtsklick > „Einstellungen“ öffnet die Goals-Einstellungen (nicht die von
   Level Time).
5. `/sg`: Reiter der Zielarten brechen bei Platzmangel in eine zweite Zeile um, Beschriftungen und Felder stehen bündig;
   „Abbrechen“ fragt nach; Fußzeile „Einstellungen“ und „Verschieben“.
6. Daten: Charakter in `/lt history` löschen, dann „Ziele gelöschter Charaktere entfernen“ (Rückfrage, Zähler sinkt).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Einstellungen und Suche ok (ja/nein):
Kartenzahl und Farben ok (ja/nein):
Rechtsklick/Shift-Klick ok (ja/nein):
Edit-Modus Einstellungen ok (ja/nein):
Fenster-Layout fr/es ok (ja/nein):
Fehler:
```

### 171. Gold-Ziel (Roadmap 295)

- [ ] geprüft

1. `/sg add gold 1`: Gegner looten, Quest abgeben, beim Händler verkaufen: Karte zählt „0g / 1g“ hoch, Ausgaben senken
   nichts.
2. `/sg add gold <Bestand+1> own`: Karte zeigt den Bestand, Kauf beim Händler senkt ihn, Verkauf hebt ihn.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Verdienen zählt (ja/nein):
Besitzen folgt dem Bestand (ja/nein):
Fehler:
```

### 172. Quest-Ziele (Roadmap 296)

- [ ] geprüft

1. Quest im Questlog per Shift-Klick in das Feld „Quest-IDs oder Links“ (`/sg`, Reiter Quests, „Bestimmte Quests“):
   Link landet im Feld, Karte zeigt den Questnamen; Abgabe hakt ab.
2. Kette aus drei Quest-IDs, die erste schon erledigt: Karte startet bei 1 / 3 und nennt die nächste Quest.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Link per Shift-Klick (ja/nein):
Schon erledigte Quest erkannt (ja/nein):
Fehler:
```

### 173. Berufs-Ziel (Roadmap 297)

- [ ] geprüft

1. `/sg add skill <aktuell+2> <Beruf>`: Karte startet beim aktuellen Wert (Retail/Forever: Hauptberufe, Kochen, Angeln),
   Fertigkeit steigern zählt mit.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Startwert stimmt (ja/nein):
Steigen zählt (ja/nein):
Fehler:
```

### 174. Items besitzen (Roadmap 298)

- [ ] geprüft

1. `/sg add owned <Link> 20`: Karte zeigt den Bestand mit Item-Symbol; looten, kaufen, verkaufen, Bank-Fach räumen
   ändern den Stand; mit „Bank mitzählen“ nach einmal Bank öffnen auch die Bank.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Bestand folgt (ja/nein):
Bank mitgezählt (ja/nein):
Fehler:
```

### 175. Erkundung und Zonen (Roadmap 307)

- [ ] geprüft

1. `/sg add explore 2`, zwei neue Gebiete entdecken (auch auf Max-Level ohne XP): Karte zählt je Gebiet genau eins.
2. `/sg add explore <Nachbarzone>`: beim Betreten abgehakt; in der Zone selbst angelegt: Meldung „schon erreicht“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Entdecken zählt einmal je Gebiet (ja/nein, doppelt/gar nicht):
Zone erreicht (ja/nein):
Fehler:
```

### 176. Erfolge und Ehre (Roadmap 309)

- [ ] geprüft

1. Retail/Forever: Erfolg per Shift-Klick im Erfolgsfenster in das Feld (`/sg`, Reiter Erfolg): Karte mit Erfolgssymbol,
   Stand aus den Kriterien, Abschluss beim Erreichen. Classic Era/TBC: kein Reiter „Erfolg“.
2. `/sg add honor 100` auf dem Schlachtfeld: Siege und Bonusehre zählen; Retail: zählt die Karte überhaupt
   (sonst Chatzeilen von CHAT_MSG_COMBAT_HONOR_GAIN notieren)?

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Erfolg-Fortschritt stimmt (ja/nein):
Ehre zählt (ja/nein, Chatzeile):
Fehler:
```

### 177. Fristen (Roadmap 299)

- [ ] geprüft

1. `/sg`, Kills 5 mit Frist „2m“: Karte zeigt „0 / 5  noch 00h 02m 00s“ und zählt jede Sekunde herunter; nach Ablauf
   rote Einblendung „Ziel gescheitert“, Historie „Gescheitert“ in Rot.
2. `/sg deadline <Nr> 10m played`, ausloggen und 5 Minuten warten: nach dem Login stimmt die Restzeit (Spielzeit läuft
   ausgeloggt nicht).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Countdown flüssig und lesbar (ja/nein):
Scheitern mit Einblendung (ja/nein):
Spielzeit-Frist stimmt nach Login (ja/nein):
Fehler:
```

### 178. Regel-Ziele (Roadmap 300)

- [ ] geprüft

1. `/sg add rule nopotion`, einen Heiltrank trinken: Ziel scheitert mit „Heiltrank benutzt“ (Classic/TBC; Retail und
   Forever: `/lt debug check` zeigt unter `300.goals.potionSpells`, welche IDs der Client kennt).
2. `/sg add rule naked` ohne Rüstung, ein Rüstungsteil anlegen und sofort wieder ablegen: hält; anbehalten: scheitert
   nach etwa 10 s.
3. `/sg add rule notaxi`, Flugmeister: spätestens 10 s nach dem Abflug „Flugpunkt benutzt“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Heiltrank erkannt (ja/nein, Trank):
Nackt mit Schonfrist (ja/nein):
Flug erkannt (ja/nein):
Fehler:
```

### 179. Checkliste mit Teilzielen (Roadmap 304)

- [ ] geprüft

1. `/sg add list Holz; Boss; Ruf`, dann `/sg add kills 3` und `/sg sub <Liste> <Kills>`: eine Karte mit vier Zeilen und
   Häkchen-Symbolen (keine grünen Quadrate), die Kills-Karte verschwindet; Zeilen umbrechen sauber.
2. Klick hakt ab, Shift+Klick nimmt zurück; drei Kills: Zeile grün, Liste erreicht.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Symbole sichtbar (ja/nein):
Teilziel zählt (ja/nein):
Fehler:
```

### 180. Vorlagen und Pakete (Roadmap 301)

- [ ] geprüft

1. `/sg`, Reiter „Vorlagen“: drei fertige Pakete, Buttons in einer Zeile (auch fr/es); „Übernehmen“ legt die Ziele an.
2. Laufende Ziele unter einem Namen speichern, „Teilen“: Text kopieren, auf einem anderen Charakter „Importieren“ und
   einfügen: Paket erscheint, „Übernehmen“ legt dieselben Ziele an.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Reiter-Layout ok (ja/nein):
Teilen/Importieren ok (ja/nein):
Fehler:
```

### 181. Wiederkehrende Ziele (Roadmap 310)

- [ ] geprüft

1. Tägliches Ziel anlegen und erreichen; nach Mitternacht (oder am nächsten Tag beim Login) ist es neu da, die Karte
   zeigt „Täglich · Serie 1“.
2. Einen Tag auslassen: das alte steht in der Historie als „Gescheitert (Zeitraum vorbei)“, Serie wieder 0.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Erneuert nach Mitternacht/Login (ja/nein):
Serie stimmt (ja/nein):
Fehler:
```

### 182. Boss-Ziele (Roadmap 302)

- [ ] geprüft

1. `/sg add boss 1 <Name des ersten Bosses>` in einem Dungeon: Sieg hakt ab, ein Wipe nicht; mit Instanz-Feld zählt
   nur diese Instanz. Classic Era/TBC: kommt ENCOUNTER_END bei Dungeon-Bossen (sonst `/lt debug log` Zeilen notieren)?

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Boss gezählt (ja/nein):
Fehler:
```

### 183. Ruf-Ziele (Roadmap 303)

- [ ] geprüft

1. `/sg add rep <nächste Stufe> <Fraktion>`: Karte zeigt „Stufe jetzt > Ziel“, der Balken wächst mit jedem Rufgewinn;
   Forever: findet `C_Reputation` die Fraktion?
2. `/sg add rep 500 <Fraktion>`: Quest der Fraktion abgeben zählt die Rufmenge.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Stufe und Balken stimmen (ja/nein):
Ruf gewinnen zählt (ja/nein):
Fehler:
```

### 184. Belohnung und Punkte (Roadmap 308)

- [ ] geprüft

1. Ziel mit Belohnung „Zuschauer wählen die Zone“ und 25 Punkten: Karte zeigt die Zeile unter dem Titel, die
   Einblendung beim Erreichen nennt sie; Historie unten „… · 25 Punkte“.
2. `/sg`: Formular mit allen Zusätzen (Frist, Wiederholen, Belohnung, Punkte) passt ins Fenster, auch auf Französisch.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Belohnung auf Karte und Einblendung (ja/nein):
Formular passt (ja/nein):
Fehler:
```

### 185. Bingo (Roadmap 305)

- [ ] geprüft

1. `/sg bingo 3`: Raster mit neun Feldern neben dem Tracker, Texte lesbar (zwei, drei Zeilen je Feld, auch fr/es);
   Kills/Quests haken sich selbst ab und färben das Feld grün, eigene Felder per Klick.
2. Volle Reihe: „BINGO!“-Einblendung, Raster verschwindet; mit „BINGO in den Gruppenchat“ in einer Gruppe eine Zeile.
3. `/sg bingo 5`: 5×5 mit „FREI“ in der Mitte passt auf den Bildschirm; `/lt edit` zeigt den Beispielschein.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Raster lesbar (ja/nein):
BINGO und Ansage (ja/nein):
Fehler:
```

### 186. Glücksrad (Roadmap 306)

- [ ] geprüft

1. `/sg wheel`: Karte links neben dem Tracker wechselt etwa zwei Sekunden lang die Titel und bleibt grün beim Ergebnis
   stehen; das Ziel erscheint im Tracker. `/sg wheel reroll` ersetzt es, bis keine Neuwürfe mehr übrig sind.
2. „Bei jedem Level-Up drehen“ an: Level-Up dreht automatisch.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Animation flüssig (ja/nein):
Neuwürfe und Level-Up ok (ja/nein):
Fehler:
```

### 187. Fenster von Level Time Goals (/sg) aufgeräumt

- [ ] geprüft

1. `/sg`: das Schließen-Kreuz sitzt oben rechts vollständig im Fenster (auch nach Verschieben an den oberen Rand).
2. Zielarten: oben eine Zeile mit Gruppen (Fortschritt, Kampf, Beute & Gold, Quests, Regeln & Spaß), darunter nur die
   Arten der gewählten Gruppe; jede Art ist erreichbar, beim Zurückwechseln ist die zuletzt gewählte Art wieder da.
   Auch auf Französisch/Spanisch kein Text über den rechten Rand.
3. Formular: alle Felder beginnen in einer Spalte; Zahlen (Ziel, Frist, Punkte) gleich schmal, Textfelder (Belohnung,
   Item, Eigenes) bis zum rechten Rand, Auswahl-Buttons gleich breit.
4. Fußzeile: „Layout bearbeiten“ (Tooltip wie bei Level Time) schließt das Fenster und startet den Edit-Modus.
5. Ohne aktive Ziele: Hinweis „Keine aktiven Ziele …“ und Button „Vorlagen öffnen“, der den Reiter Vorlagen zeigt.
### 189. Schlafsack-Timer (Roadmap 430, WoW Forever)

- [ ] geprüft

1. Den „Gemütlichen Schlafsack“ benutzen: er wird nur ausgerollt, kurz erscheint „Schlafsack ausgerollt – /schlafen zum Ausruhen“ (kein Countdown). Zum Sack laufen bricht nichts ab.
2. Mit unter 3 Stapeln „Gut erholt“ `/schlafen`: die Karte „Im Schlafsack ausruhen“ erscheint unter dem Essen-Timer und zählt von 180 s herunter. Bei jedem neuen Stapel kurz „Gut erholt ×N/3“ (Karte und Chatzeile), der Titel zeigt „×N/3“; bei Stapel 3 sofort „Fertig ausgeruht!“, sonst nach 180 s.
3. Mit schon 3 Stapeln `/schlafen`: der Countdown zählt nur 60 s. Sobald der Buff wieder auf 2 Stunden aufgefrischt ist, kommt „Gut erholt aufgefrischt (2 Std.)“ und gleich „Fertig ausgeruht!“.
4. Noch einmal hinlegen und nach ein paar Sekunden laufen, springen oder aufstehen: „Ausruhen abgebrochen“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Kreuz im Fenster (ja/nein):
Gruppen und Arten übersichtlich (ja/nein):
Felder bündig (ja/nein):
Layout bearbeiten / Vorlagen öffnen ok (ja/nein):
Fehler:
```

### 188. Historie > Speedrun > Läufe: Kopfzeile, Namen, Werkzeugzeile

- [ ] geprüft

1. `/lt history`, Speedrun > Läufe: „Filter“ steht vollständig rechts neben „LiveSplit“ (kein „lter“), das Suchfeld
   überlappt nichts; auf Französisch/Spanisch ggf. schmaler oder in einer eigenen Zeile darunter.
2. Spaltenköpfe „Splits“ und „Quote“ statt zweimal „Erfasst“; Maus auf jeden Kopf zeigt eine Erklärung (auch
   „Bis akt. Level“ und „Prüfcode“). Keine leere Status-Spalte mehr, die Tabelle endet vor der Bildlaufleiste.
3. Namen ohne Realm („Nerzal“); Maus auf die Zeile zeigt „Name - Realm“ und Klasse. Zwei Charaktere gleichen Namens
   auf verschiedenen Realms zeigen den unterscheidenden Teil des Realms in Klammern.
4. Gewählter Vergleich (Klick auf einen Lauf) trägt „>“ in der ersten Spalte, Favoriten „*“.
5. Auf Level 1 zeigt „Bis akt. Level“ ein gedämpftes „–“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Filter frei lesbar (ja/nein):
Köpfe eindeutig, Tooltips ok (ja/nein):
Namen und Tooltip ok (ja/nein):
Client (Forever):
Startet bei /schlafen bzw. Benutzen (ja/nein):
Stapel-Hinweise kommen (ja/nein, wie viele in 180 s):
Abbruch beim Aufstehen (ja/nein):
Fehler:
```

### 190. Level Time Goals: Glücksrad dreht sich, Bingo selbst füllen, eigene Ziele

- [ ] geprüft

Nach dem Update den Client neu starten (neue Dateien und Texturen in `StreamGoal/`).

1. `/sg`, Reiter „Glücksrad“: Tabelle mit allen mitgelieferten und eigenen Zielen; Klick schaltet „an/aus“ um.
   Eigene Texte hinzufügen und eigene Ziele löschen geht seit Roadmap 433 im Reiter „Sammlung“ (siehe 191).
2. „Glücksrad drehen“: in der Bildschirmmitte erscheint ein rundes Rad mit 12 farbigen Stücken, Zeiger oben, Nabe in
   der Mitte. Es läuft schnell an, wird über etwa 4 s langsamer, dreht sich dabei mehrmals; die Zeile darunter zeigt
   das Stück unter dem Zeiger. Am Ende steht der Zeiger auf dem Stück, dessen Ziel angelegt wird (Karte unter dem
   Rad, Chatzeile). Klicken je Stück hörbar und nicht zu laut. Auf jedem Client: Stücke drehen sich sauber um die
   Mitte (keine abgeschnittenen Ecken, keine Lücken zwischen den Stücken).
3. Einstellungen > Glücksrad (seit Roadmap 433 eigene Unterseite): „Rad drehen lassen“ aus = Ergebnis sofort;
   „Klicken beim Drehen“ aus = still.
4. `/lt edit`: das Rad lässt sich verschieben und skalieren.
5. Reiter „Ziele“: Art wählen, Werte eingeben, „Als eigenes Ziel speichern“: nichts wird angelegt, das Ziel steht im
   Glücksrad- und Bingo-Reiter.
6. Reiter „Bingo“: Feld anklicken, rechts ein Ziel anklicken (springt zum nächsten Feld), einen Text „Ins Feld“;
   Rechtsklick leert ein Feld. „Schein anlegen“: gewählte Felder stehen an ihrer Stelle, leere sind zufällig. Lange
   Texte in den kleinen 5×5-Feldern bleiben lesbar (Tooltip zeigt den ganzen Text). Französisch/Spanisch: Knöpfe
   überlappen nicht.
7. Wer vorher eigene Bingo-Texte hatte (`/sg bingo texts`): sie stehen jetzt als eigene Ziele im Glücksrad-Reiter,
   die mitgelieferten Texte sind dort aus.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Rad sichtbar, dreht und landet richtig (ja/nein):
Stücke sauber, Farben ok (ja/nein):
Tick-Ton ok (ja/nein):
Eigene Ziele und Bingo-Editor ok (ja/nein):
Fehler:
```

### 191. Level Time Goals aufgeräumt (Roadmap 433)

- [ ] geprüft

Nach dem Update den Client neu starten (neue Dateien unter `StreamGoal/Window/` und `StreamGoal/Locales/`).

1. `/sg`: Reiter in der Reihenfolge Ziele | Bingo | Glücksrad | Sammlung | Historie, jeder mit Tooltip. Gespeicherte
   Ziele, Pakete, eigene Ziele, Bingo-Entwurf und Rad-Einstellungen von vorher sind alle noch da.
2. Reiter „Ziele“: Frist, Wiederholung, Belohnung und Punkte sind zugeklappt; „+ Weitere Optionen“ klappt sie auf,
   „- Weniger Optionen“ wieder zu. „Ziel hinzufügen“ steht ganz rechts, daneben „Als eigenes Ziel speichern“. Ein
   Fehler (z.B. Level unter dem aktuellen) steht in einer eigenen roten Zeile und überdeckt nichts. Überschrift
   „Aktive Ziele (n/6)“. Kein Bingo-Reiter mehr unter „Regeln & Spaß“; die Art „Eigenes“ heißt jetzt „Freitext“.
   Tooltips auf Gruppen- und Artenreitern (Arten bzw. Chatbefehl), auf +, - und Abbrechen.
3. Ohne aktive Ziele: „Pakete ansehen“ öffnet Sammlung > Pakete.
4. Reiter „Glücksrad“: Klick schaltet einen Eintrag an/aus, „Alle an“/„Alle aus“ (mit Filter nur die gefundenen),
   Haken „Bei jedem Level-Up drehen“ und „Rad drehen lassen“ stimmen mit Einstellungen > Glücksrad überein.
5. Reiter „Sammlung“: Unterreiter „Pakete“ (Übernehmen ganz rechts, Teilen, bei eigenen Löschen; unten „Laufende
   Ziele als Paket speichern“) und „Eigene Ziele“ (Linksklick legt an, Rechtsklick löscht mit Rückfrage, freier Text
   hinzufügen). Oben rechts „Importieren“: ein Paket-Text landet unter Pakete, ein Text von „Eigene Ziele teilen“
   unter Eigene Ziele (auch ein Text aus der Version vor diesem Update).
6. „Einstellungen“ unten rechts öffnet je Reiter die passende Unterseite (Ziele: Tracker, Bingo: Bingo, Glücksrad:
   Glücksrad, Historie: Daten). Rechtsklick auf Bingo-Schein bzw. Rad am Bildschirm ebenso.
7. In Englisch, Französisch und Spanisch (`/lt` > Sprache): nichts überlappt oder ragt über den Rand, vor allem die
   Knopfzeilen im Reiter Ziele, Glücksrad und Sammlung.
8. `/sg own`, `/sg own add Test`, `/sg import`, `/sg collection`, `/sg bingo edit`, `/sg wheel edit` funktionieren;
   alte Befehle (`/sg pack import`, `/sg bingo text …`) ebenso.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Daten von vorher da (ja/nein):
Reiter, Zusätze, Knopfzeilen ok (ja/nein):
Sammlung und Import ok (ja/nein):
Andere Sprachen ohne Überlappung (ja/nein):
Fehler:
```

### 192. Minimap-Button von Level Time Goals (Roadmap 434)

- [ ] geprüft

Nach dem Update den Client neu starten (neue Datei `StreamGoal/MinimapButton.lua`).

1. Am Rand der Minimap steht neben dem Button von Level Time ein zweiter mit dem Goals-Icon; das Icon sitzt sauber im
   runden Rahmen (nicht verschoben, nicht abgeschnitten).
2. Tooltip: „Level Time Goals“, Zahl der laufenden Ziele, bis zu fünf Ziele mit Stand, darunter die Klicks.
3. Linksklick öffnet/schließt `/sg`, Shift+Linksklick die Historie, Rechtsklick die Einstellungen von Goals,
   Shift+Rechtsklick den Edit-Modus.
4. Ziehen schiebt den Button um die Minimap; nach `/reload` steht er an derselben Stelle.
5. `/sg minimap` blendet ihn aus (Chat-Hinweis) und wieder ein; Einstellungen > Tracker > „Minimap-Button anzeigen“
   ebenso, auch nach `/reload`.
6. Mit einem Addon, das Minimap-Buttons sammelt (z.B. MinimapButtonButton, Leatrix Plus), wird er wie der von Level
   Time behandelt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Button sichtbar, Icon sitzt (ja/nein):
Tooltip und Klicks ok (ja/nein):
Position nach /reload (ja/nein):
Ausblenden per Befehl und Einstellung (ja/nein):
Fehler:
```

### 193. UX-Review: Hinweise, Reiter, Rückfragen und Instanz-Reiter

- [ ] geprüft

1. `/lt history` auf Französisch und Spanisch: die Hauptreiter laufen nicht über den rechten Rand, passen sie nicht in
   eine Zeile, brechen sie in eine zweite um; Unterreiter und Inhalt rücken darunter, nichts überlappt.
2. Historie > Quests > Abgabe, Speedrun > Quest-Splits, Quests > Effizienz, Geld: der graue Hinweis unten bricht in der
   Fensterbreite um (zwei Zeilen), läuft nicht links aus dem Fenster und überdeckt die Summenzeile nicht.
3. Quests > Abgabe für einen anderen Charakter: „Nur für den eingeloggten Charakter …“; eigener Charakter ohne fertige
   Quest: „Keine Quest ist abgabebereit.“. In einer Tabelle etwas in den Filter tippen, das nicht vorkommt: „Keine
   Treffer für …“.
4. `/lt edit` > „Alle zurücksetzen“: Tooltip, dann Rückfrage; „Nein“ ändert nichts, „Ja“ setzt alle Anzeigen zurück.
   `/lt reset` fragt ebenso.
5. Hauptfenster auf Reiter „Instanz“ ohne Lauf: Instanzlimit, Instanzen heute, Ohne Tod, XP/h (15 min) zeigen Werte,
   Zähler wie Kills „-“.
6. Rechtsklick auf den Reiter „Instanz“ öffnet die Einstellungen (wie Level/Session), Shift+Rechtsklick fragt nach dem
   Zurücksetzen des Durchgangs.
7. Retail/Forever: `/lt recap` hat keine Zeile „Beinahe-Tode“; Classic Era/TBC: die Zeile ist da.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Hauptreiter passen (ja/nein, Sprache):
Hinweise umbrochen, nichts überdeckt (ja/nein, welcher nicht):
Leer- und Kein-Treffer-Text (ja/nein):
Rückfrage Alle zurücksetzen und /lt reset (ja/nein):
Instanz-Reiter ohne Lauf und Rechtsklick ok (ja/nein):
Recap Beinahe-Tode passend (ja/nein):
Fehler:
```

### 194. UX-Review Paket 2: Tooltips an den Werten im Hauptfenster

- [ ] geprüft

1. Hauptfenster im Layout Tabelle, Leiste, Nur Text und Kacheln: Maus über eine Zeile (bzw. Kachel) zeigt einen Tooltip
   mit der Bezeichnung als Titel und der Erklärung der Stat; steht „...“ oder „-“ da, erklärt eine zweite Zeile den
   Platzhalter. Die Zeit-Kachel hat keinen Tooltip.
2. Über einer Zeile: Ziehen verschiebt das Fenster (wenn nicht fixiert), Rechtsklick öffnet die Einstellungen.
3. Sichtbarkeit „Bei Mauskontakt“: Maus von einer Zeile aus dem Fenster heraus ziehen blendet das Fenster wieder ab.
4. Tode mit Totzeit stehen als „2 (6m 38s tot)“ da (enUS „dead“).
5. Flug-, Essen-, Lagerfeuer- und Schlafsack-Karte zeigen die Restzeit als „4m 10s“ bzw. „37s“ (nicht mehr „4:10“ oder
   „37 s“); die Titel von Essen und Lagerfeuer unterscheiden sich („Essen: …“, „Lagerfeuer: …“).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tooltips an Zeilen/Kacheln (ja/nein, welches Layout nicht):
Ziehen und Rechtsklick über Zeilen (ja/nein):
Bei Mauskontakt blendet wieder ab (ja/nein):
Totzeit-Format und Karten-Zeiten (ja/nein):
Fehler:
```

### 195. UX-Review Paket 2: Historie erklärt Spalten und Graphen

- [ ] geprüft

1. `/lt history`: Maus über einen Spaltenkopf (z.B. Übersicht „Kills“, „PvP-Siege“, Zeitaufteilung „Sonstiges“,
   „Leerlauf“, Vergleich „Erholt“, Geld „Einnahmen“) zeigt eine Erklärung statt nur „Klick sortiert“.
2. Speedrun > Läufe: Spalten „Gemessen“, „Bis dein Level“, „Erfasst %“, „Kategorie“ (Tooltip mit SSF-Erklärung),
   „Zeiten“ mit „original“/„bearbeitet“. Die Knöpfe „Export“, „Alle sichern“, „Importieren“ und „LiveSplit“ haben einen
   Tooltip.
3. Graphen: Unterreiter heißen „Zeit je Level“, „Todesursachen“, „Spielzeiten (Tag × Stunde)“ (das „×“ wird
   dargestellt), „Levelkurve“ usw.; unter jedem Diagramm steht eine graue Hinweiszeile, die nicht über das Diagramm
   ragt. Die Unterreiter brechen sauber um (auch frFR/esES).
4. Level-Tabellen ohne Teil-Level zeigen unten „Klick auf einen Spaltenkopf sortiert.“ statt des Hinweises zu „*“.
5. `/lt recap` ohne Level-Up: „Level 25“; mit Level-Up: „10 bis 12“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Spaltenköpfe erklärt (ja/nein, welche nicht):
Läufe-Spalten und Knopf-Tooltips (ja/nein):
Graphen-Namen und Hinweiszeile (ja/nein, Sprache):
Recap-Level (ja/nein):
Fehler:
```

### 196. UX-Review Paket 2: einheitliche Begriffe und ausgegraute Schalter

- [ ] geprüft

1. `/lt`: Reiter „Chat & Erinnerungen“ und „Einblendungen“, Allgemein > „Hauptfenster“, Komfort > „Rahmen, Tooltip &
   Karte“, Unterseite Speedrun > „Weltrekorde“; der Knopf unter der Seitenleiste heißt „Seite zurücksetzen“. Alles
   passt in allen vier Sprachen (Seitenleiste, Reiter, Knopf).
2. Abhängige Schalter sind grau, solange ihr Hauptschalter aus ist, und werden sofort bedienbar, wenn er an geht:
   Flugzeit-Tooltip/-Ton (Flugzeiten), Gildenreparatur (Automatisch reparieren), Rare-Aufblinken (Rare gesichtet),
   Level-Up-Fenster-Optionen, Namen beim Würfeln (Zähler), Totenkopf und „nur in der Zone“ (Quest-Knöpfe), Fortschritt
   und Größe der Kill-Quest-Markierung, Split-Liste-Optionen, Regler zu Pause, Atem, Mana, Munition, Wetter.
3. Einblendungen > Ereignisse und Komfort > Automatik zeigen den Hinweis, dass Quest-Einblendungen bzw. die
   Quest-Automatik unter Komfort > Quests stehen.
4. XP-Balken-Tooltip: „Erholt übrig: …“, „Erholt reicht für … des Wegs zum Level-Up“, „XP abgabebereiter Quests: …“;
   Stat „XP durch Erholt“ im Fenster.
5. Historie: Hauptreiter „Quest-Auswertung“ mit „Abgabebereit“, Speedrun > „Bestzeiten je Level“ und „Weltrekorde“,
   Level > „Verlauf“; Zählzeile der Journale „12 Einträge“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Neue Namen passen in allen Sprachen (ja/nein, wo nicht):
Ausgegraut und wieder bedienbar (ja/nein, welcher nicht):
Verweis-Hinweise (ja/nein):
Begriffe im XP-Tooltip und in der Historie (ja/nein):
Fehler:
```

### 197. UX-Review Paket 3: Modus „Einfach“ und Profile

- [ ] geprüft

1. Neue Installation (Level Time-SavedVariables `LevelTimerDB` vorher umbenennen, nach dem Test zurück): `/lt` öffnet
   im Modus „Einfach“; der Schalter oben rechts heißt „Alle Optionen zeigen“ (enUS „Show all options“) und passt neben
   die Suche, auch in frFR/esES.
2. Bestehende Installation (eigenes `LevelTimerDB`): der Schalter steht wie vorher (an, wenn du nie umgeschaltet hast).
3. Im Modus „Einfach“: Komfort > Oberfläche zeigt nur die Hauptschalter (Ränder ohne die drei Regler, Beute-Glitzer
   ohne Größe), Komfort > Chat ohne Schriftgröße, Allgemein > Aussehen mit „Kontur“, aber ohne Mindestschriftgröße,
   Balkentextur und „Farbe nach Wert“. Keine Seite der Seitenleiste ist leer, die Bausteine rücken ohne Lücken nach.
4. Reiter Profile: oben „Aktiv: Standard (genutzt von N Charakteren)“, Tooltip listet die Charaktere; vor dem Feld
   steht „Neues Profil:“, „Als Profil speichern“ ist grau, bis ein Name im Feld steht.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Neu: einfach, Beschriftung passt (ja/nein, Sprache):
Bestehend: Schalter unverändert (ja/nein):
Einfach-Modus ohne leere Seiten und Lücken (ja/nein, wo):
Profile: Aktiv-Zeile, Beschriftung, grauer Knopf (ja/nein):
Fehler:
```

### 198. UX-Review Paket 3: Willkommenskarte, Hilfe und erster Start

- [ ] geprüft

1. Erster Start (oder `/lt welcome`): Voreinstellungen und Layouts sind Reiter; Maus darüber erklärt sie, die aktive
   Voreinstellung und das aktive Layout sind unterstrichen. Zeile „3. Streamst du?“ mit Schalter Stream-Modus, Fußtext
   zu Historie, `/lt welcome` und `/lt help` über den Knöpfen; nichts überlappt (auch frFR/esES).
2. Beim ersten Start steht im Chat nur „Level Time ist bereit. /lt öffnet die Einstellungen, /lt help zeigt die
   Befehle.“
3. `/lt help` zeigt drei kurze Zeilen, `/lt help all` alle Befehle; `/lt quatsch` und `/lt runs x` melden eine Zeile
   mit dem Verweis auf die Hilfe.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Karte: Tooltips, Hervorhebung, Stream, Fuß, kein Überlappen (ja/nein, Sprache):
Chatzeile beim ersten Start (ja/nein):
Hilfe kurz/lang, unbekannter Befehl (ja/nein):
Fehler:
```

### 199. UX-Review Paket 3: Bedienhinweise an Anzeigen und Historie

- [ ] geprüft

1. Maus über den Hintergrund oder die Zeit des Hauptfensters: Tooltip „Hauptfenster“ mit Rechtsklick, Ziehen (fehlt bei
   „Fixieren“), Griff und `/lt edit`; über einer Zeile weiter nur die Erklärung der Zeile. Flug-, Essen-, Lagerfeuer-
   und Schlafsack-Karte sowie die Split-Liste zeigen den Hinweis ebenso, im Edit-Modus nicht.
2. Edit-Modus: der Hinweis steht in zwei Zeilen, die Leiste ist schmaler als vorher und nichts überlappt.
3. `/lt history`: Maus über einen Hauptreiter oder Unterreiter (z.B. „Verlauf“, „Zeitaufteilung“, „Effizienz“,
   „Abgabebereit“) zeigt, was die Ansicht enthält.
4. Layout „XP-Balken“ mit Breite 200 und drei gewählten Werten: der Balken wird breiter, links, Mitte und rechts
   überlappen nicht; mit Texten „Nie“ bleibt er bei 200.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Bedienhinweis an Fenster, Karten, Split-Liste (ja/nein, welche nicht):
Edit-Modus-Hinweis zweizeilig (ja/nein):
Historien-Reiter erklärt (ja/nein, welche nicht):
XP-Balken ohne Überlappen (ja/nein):
Fehler:
```

### 200. Level Time Goals: Glücksrad über dem Fenster, Ergebnis bleibt, Neu drehen per Knopf

- [ ] geprüft

Nach dem Update den Client neu starten (neue Datei `StreamGoal/ClickStep.lua`).

1. `/sg`, Reiter „Glücksrad“, „Glücksrad drehen“: das Rad dreht sich sichtbar **vor** dem Fenster (nicht dahinter),
   die Ergebnis-Karte darunter ebenso. Gleiches über Einstellungen > Glücksrad > „Glücksrad drehen“.
2. Nach dem Halt erscheint links neben „Glücksrad drehen“ der Knopf „Neu drehen (noch 2)“; Klick verwirft das
   Ergebnis (Ziel abgebrochen) und dreht neu, die Zahl sinkt; bei 0 verschwindet der Knopf. Die Chatzeile nennt
   `/sg wheel reroll` nur, solange Neuwürfe übrig sind.
3. Rechtsklick auf die Ergebnis-Karte dreht ebenfalls neu, Linksklick blendet Rad und Karte aus; der Tooltip der
   Karte nennt beides.
4. Rad und Karte bleiben 15 s stehen (Einstellungen > Glücksrad > „Ergebnis zeigen“); auf 0 („bis Klick“) bleiben
   sie bis zum Linksklick auf die Karte oder bis zur nächsten Drehung.
5. `/lt edit`: das Rad lässt sich weiterhin greifen und verschieben (die Rahmen des Edit-Modus liegen darüber).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Rad vor dem Fenster /sg und vor den Einstellungen (ja/nein):
Knopf Neu drehen und Zähler (ja/nein):
Karte: Linksklick/Rechtsklick (ja/nein):
Anzeigedauer 15 s / bis Klick (ja/nein):
Edit-Modus greift das Rad (ja/nein):
Fehler:
```

### 201. Level Time Goals: Abhaken mit zweitem Klick, Formular je Modus, Zusätze zurückgesetzt

- [ ] geprüft

1. Freitext-Ziel ohne Zähler (`/sg add custom Test`): ein Linksklick auf die Karte hakt **nicht** ab, die Karte zeigt
   „Nochmal klicken zum Abhaken“; ein zweiter Klick innerhalb von 3 s hakt ab (Einblendung erst jetzt). Nach 3 s
   ohne zweiten Klick zeigt die Karte wieder ihren normalen Text.
2. Zähler-Ziel (`/sg add custom 2 Test`): erster Klick zählt 1, beim letzten Schritt gilt dasselbe wie in 1.
   Shift+Linksklick zählt zurück. Im Bingo-Schein: Feld zeigt unter dem Text „Nochmal klicken zum Abhaken“.
3. `/sg`, Fortschritt > Quests: zuerst „Art“, darunter nur „Anzahl“ (Art: Anzahl abgeben) bzw. nur „Quest-IDs oder
   Links“ (Art: Bestimmte Quests); beim Umschalten springt die Knopfzeile mit, nichts überlappt. Gleiches bei
   Erkundung (Anzahl / Zone) und Ruf (Rufpunkte / Stufe, Fraktion immer).
4. „+ Weitere Optionen“, „Wiederholen: Täglich“, Ziel hinzufügen: das Ziel ist täglich, danach steht „Wiederholen“
   wieder auf „Nie“ und die Zusätze lassen sich zuklappen; solange etwas gesetzt ist, bleiben sie offen.
5. Karten und Bingo-Felder mit Anzahl 1 lesen sich richtig: „1 Gebiet entdecken“, „1 Quest abgeben“, in Englisch
   „Discover 1 area“, Französisch „Découvrir 1 zone“, Spanisch „Descubrir 1 zona“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Zweiter Klick nötig, Hinweis auf Karte und Feld (ja/nein):
Formular zeigt nur Felder des Modus (ja/nein):
Zusätze nach Hinzufügen zurückgesetzt (ja/nein):
Einzahl in allen Sprachen (ja/nein):
Fehler:
```

### 202. Level Time Goals: Vorlagen, Ziel-Karten und erklärende Tooltips

- [ ] geprüft

1. `/sg`, Reiter Ziele: Maus über jeden Artenreiter. Der Tooltip erklärt in einem Satz, was die Art zählt (z.B.
   „Item looten“ vs. „Item besitzen“), darunter grau der Chatbefehl. Texte passen in die Tooltip-Breite (umbrechen).
2. Maus über jedes Feld (Zahl, Text, Auswahl, Haken) mehrerer Arten und der „Weiteren Optionen“: jedes hat einen
   Tooltip; Auswahlknöpfe zusätzlich grau „Linksklick: nächster Wert …“. Beim Haken („Bank mitzählen“, „Nur auf
   Schlachtfeldern“) reicht die Maus über der Beschriftung, ein Klick auf die Beschriftung setzt den Haken.
3. Item-Feld fokussieren, Shift-Klick auf ein Item in den Taschen: Link steht im Feld. Dasselbe bei Quests
   (Bestimmte Quests) mit Shift-Klick auf eine Quest im **Questlog** und bei Erfolgen mit Shift-Klick im
   **Erfolgsfenster**: Kommt der Link im Feld an? (Die Tooltips versprechen nur „Shift-Klick auf einen Link“; falls
   das Questlog/Erfolgsfenster ohne offenen Chat nichts einfügt, bitte notieren.)
4. Knopf „Als Vorlage speichern“: legt **kein** Ziel an, Chat „Vorlage gespeichert: …“; Sammlung > Vorlagen zeigt den
   Eintrag mit Herkunft „Eigene Vorlage“ (Bingo und Glücksrad: „Mitgeliefert“/„Eigene Vorlage“). `/sg template` und
   `/sg own` listen dieselben Vorlagen. Ein älterer geteilter Text „Eigene Ziele“/„Own goals“ importiert weiter als
   Vorlagen.
5. Überall „Ziel-Karten“: Fußzeile des Fensters „Ziel-Karten anzeigen“, Einstellungen > Ziel-Karten, Edit-Modus
   „Ziel-Karten“, `/sg tracker` → „Ziel-Karten an./aus.“; „Laufende Ziele (n/6)“ im Fenster und im Minimap-Tooltip.
6. Maus über eine Zeile der laufenden Ziele (langer Freitext mit Frist und Belohnung): Tooltip zeigt den vollen Titel,
   Stand, Frist/Belohnung und bei selbst gezählten Zielen den Bedienhinweis.
7. `/sg add rule nodeath` (ohne Level): Karte „Läuft bis zum Abbruch; ein Verstoß lässt das Ziel scheitern“.
   `/sg scale` ohne Zahl: Chat nennt die aktuelle Größe und den Bereich 0.5 bis 2.
8. Sprache Französisch und Spanisch (Level Time Einstellungen): Formular-Beschriftungen und Tooltips abgeschnitten?

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tooltips Arten/Felder vollständig (ja/nein):
Shift-Klick Item / Questlog / Erfolgsfenster fügt Link ein (ja/nein je):
Vorlage speichern legt kein Ziel an (ja/nein):
Begriffe einheitlich (ja/nein, Stellen):
Tooltip laufende Ziele (ja/nein):
Fehler:
```

### 203. Level Time Goals: Einstieg, Fehler im Fenster, Klicks erklärt, Bingo ohne Wiederholung

- [ ] geprüft

1. Frischer Account (oder `StreamGoalDB` gelöscht): beim ersten Login steht im Chat einmal „Willkommen! /sg öffnet das
   Fenster …“. Steht die Zeile nach den Login-Zeilen von Level Time noch sichtbar da? Nach `/reload` und beim nächsten
   Charakter kommt sie nicht wieder.
2. `/sg` ohne je ein Ziel: unter „Laufende Ziele“ stehen die drei Schritte und darunter „Pakete ansehen“. Level ist
   gewählt und das Feld zeigt das nächste Level; „Ziel hinzufügen“ legt es mit einem Klick an. Freitext steht in der
   ersten Reiterzeile neben Level, das Textfeld steht über dem Zähler.
3. Fehler im Fenster: Bingo „Ins Feld“ mit leerem Text, Glücksrad mit allen Einträgen aus „Glücksrad drehen“,
   Sammlung „Paket speichern“ ohne laufende Ziele: der Fehler steht rot auf der Seite (nicht abgeschnitten, nichts
   überdeckt), nach einem Reiterwechsel oder Schließen ist er weg.
4. Sammlung > Vorlagen: Klick auf eine Zeile wählt sie nur aus (gold, Zeile „Gewählt: …“), „Als Ziel anlegen“ und
   „Löschen“ darunter wirken auf sie. Sammlung > Pakete: Maus über einem Paketnamen listet seine Ziele; fertige Pakete
   haben nur „Übernehmen“, eigene zusätzlich „Teilen“ und „Löschen“.
5. Maus über Zeilen der Tabellen in Bingo (Klick: in Feld N setzen), Glücksrad (im Rad / nicht im Rad) und Vorlagen:
   Tooltip mit vollem Titel, Art · Herkunft und dem Klick. Maus über ein Feld des Bingo-Scheins am Bildschirm: voller
   Text, Stand, „Linksklick, dann nochmal …“ bzw. „Zählt automatisch“ und „Rechtsklick: Einstellungen“.
6. `/sg bingo 5` mehrmals ohne eigene Vorlagen: kein Feld doppelt; bei 3 × 3 nie zwei Felder derselben Art (z.B.
   10 und 25 Kreaturen). Passen die neuen Texte (Vor einem NPC tanzen, …) in die 72-px-Felder?
7. `/sg help`: sieben Zeilen; `/sg help all`: alle Zielarten; `/sg lsit`: eine Zeile „Unbekannter Befehl …“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Einstiegszeile sichtbar / nur einmal (ja/nein):
Fehlerzeilen lesbar, ohne Überdeckung (ja/nein, Seite):
Tooltips Tabellen / Bingo-Schein (ja/nein):
Bingo ohne Dubletten (ja/nein):
Fehler:
```

### 204. Level Time Goals: Kacheln der Zielarten, Ziele bearbeiten, Ziel fürs Bingo-Feld

- [ ] geprüft

1. `/sg`, Reiter „Ziele“: statt zweier Reiterzeilen steht oben ein Raster aus Kacheln, je Art Symbol, Name und ein
   Farbstreifen in der Farbe der Art. Sind alle Symbole sichtbar (keine grünen/leeren Kästchen), ist kein Name
   abgeschnitten, und passt das Raster in allen vier Sprachen in höchstens vier Zeilen? Gewählte Kachel heller, Maus
   darüber zeigt Erklärung und gedämpft den Chatbefehl.
2. Sechs Ziele anlegen, „+ Weitere Optionen“ aufklappen, Art Ruf wählen: steht die letzte Zeile der laufenden Ziele
   noch ganz im Fenster (nichts überdeckt die Fußzeile)?
3. Laufender Freitext > „Bearbeiten“: Kacheln weichen einem Hinweis, Text und Zähler sind vorbelegt, Zusätze offen.
   Tippfehler korrigieren, Frist „30m“, „Speichern“: Karte zeigt den neuen Text und die Restzeit. Nochmal „Bearbeiten“:
   die Frist steht als Restzeit (z.B. „29m“) da; nur Punkte ändern lässt die Frist unverändert.
4. Checkliste und ein weiteres laufendes Ziel: „Bearbeiten“ an der Checkliste, unter „Teilziel anhängen“ das Ziel
   wählen (Links-/Rechtsklick), „Anhängen“: es verschwindet als eigene Karte und steht als Zeile in der Checkliste;
   „Lösen“ holt es zurück. Lange Titel im Auswahlknopf werden abgeschnitten statt über den Rand zu laufen.
5. Reiter „Bingo“, ein Feld wählen, „Neues Ziel fürs Feld“: Reiter „Ziele“ mit Überschrift „Neues Ziel für das gewählte
   Bingo-Feld“, ohne Zusätze. Art Item wählen, Item per Shift-Klick einfügen, „Ins Bingo-Feld setzen“: zurück im Bingo,
   das Feld zeigt das Item, das nächste leere Feld ist gewählt. „Zurück“ statt Speichern ändert nichts.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Kacheln: Symbole sichtbar / Namen ganz / Zeilen (je Sprache):
Letzte Zeile im Fenster (ja/nein):
Bearbeiten: Text / Frist / Punkte (ja/nein):
Teilziele anhängen / lösen (ja/nein):
Bingo-Feld über das Formular (ja/nein):
Fehler:
```

### 210. UX-Review Paket 4: Historie in sieben Reitern

- [ ] geprüft

1. `/lt history` in Deutsch und Französisch: Hauptreiter Level, Sessions, Journal, Auswertung, Graphen, Speedrun &
   Rekorde, Vergleich, alle in einer oder zwei Zeilen innerhalb des Fensters, nichts überlappt.
2. Level > Übersicht hat nur noch Level, Zeit, XP/h, Kills, Tode, Quests und Gold; Level > „Kills & Items“ und Sessions >
   „Kills & Items“ zeigen Kills/h, Items, Items/h und PvP-Siege. Die Spalten passen ohne Abschneiden.
3. Auswertung enthält Zonen, Ruf, Geld, Abgabebereit und Quest-Effizienz; Speedrun & Rekorde enthält Läufe, Bestzeiten
   je Level, Persönliche Rekorde, Quest-Splits und Weltrekorde.
4. Vergleich, Läufe, Bestzeiten, Persönliche Rekorde, Weltrekorde, Quest-Effizienz: statt des Namens steht „Alle
   Charaktere“, die Pfeile und „Daten löschen“ sind grau und reagieren nicht; zurück auf Level ist der zuletzt gewählte
   Charakter wieder da.
5. Fenster mit einem vorher gemerkten Reiter (z.B. vor dem Update Zonen offen gelassen) öffnet direkt Auswertung > Zonen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Hauptreiter passen (ja/nein, Sprache):
Übersicht / Kills & Items Spalten passen (ja/nein):
Alle Charaktere: Pfeile und Löschen grau (ja/nein):
Gemerkter Reiter (ja/nein):
Fehler:
```

### 211. UX-Review Paket 4: Bereich in Kompakt, Text und Uhr; Titel der Split-Liste

- [ ] geprüft

1. Layout „Kompakt“: über der Zeit steht klein „Level 25“, nach Wechsel auf Session (Einstellung oder Rechtsklick)
   „Session“; die Zeit springt nicht.
2. Layout „Text“ mit Bezeichnungen: „Level 25“ links über der Zeit, mit Kontur; Bezeichnungen aus: nur die Zahlen.
3. Layout „Uhr“ mit gewählten Werten: Zeile „Level 25 - XP/h 8k …“ unter der großen Zeit.
4. Split-Liste: Titel „Splits vs. Bestzeit“, mit Vergleich PB „Splits vs. PB“, mit gewähltem Lauf dessen Name; die Liste
   wird für lange Namen breiter statt abzuschneiden.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Kompakt / Text / Uhr zeigen den Bereich (ja/nein):
Split-Titel je Vergleich (ja/nein):
Fehler:
```

### 212. UX-Review Paket 4: neue Orte in den Einstellungen, Goals ohne Reiterzeile

- [ ] geprüft

1. Einblendungen > Level-Up: Level-Up-Fenster, Einblendung (grau, solange das Fenster an ist) und Chat und Ansage auf
   einer Seite; Chat & Erinnerungen beginnt mit „Login & Rekorde“ und verweist auf die Level-Up-Seite.
2. Komfort > Timer & Flüge (Forever: Lagerfeuer, Essen, Schlafsack; alle: Flugzeiten). Rechtsklick auf die Flugkarte
   und das Level-Up-Fenster öffnet die neue Seite.
3. Komfort > Ausblenden: Erfahrungs-, Ruf- und Haltungsleiste, Kalender und Chat-Knöpfe stehen in der Liste und
   schalten dieselbe Einstellung wie vorher (Haken an der Chat-Seite folgt); „Blizzard-Meldungen und -Effekte“ ist ein
   einklappbarer Abschnitt dort. Komfort > Oberfläche hat keine Leisten- und Glitzer-Schalter mehr.
4. Komfort > Beute: Plündern, Würfeln um Beute, Beute-Glitzer; Rechtsklick auf die Würfel-Karte öffnet sie.
   Komfort > Rahmen, Tooltip & Karte: „Blizzard-Fenster“ (Fenster verschieben) unten.
5. Allgemein > Hauptfenster: „Minimap-Knopf anzeigen“; die Seite „Sprache“ hat nur die Sprachwahl. Allgemein > Stream:
   Hinweis zum Stream-Modus, Abschnitt „Für OBS“ mit Layout, Hintergrund und Kontur; Layout „Text“ dort gewählt wirkt
   sofort.
6. `/sg options`: keine Reiterzeile mit „Ziele“, die Seitenleiste beginnt direkt unter Suche und Titel, nichts überlappt
   das Suchfeld; „Seite zurücksetzen“ wirkt weiter.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Level-Up-Seite vollständig (ja/nein):
Timer & Flüge / Beute / Ausblenden vollständig (ja/nein, was fehlt):
Minimap-Knopf und Stream-Seite (ja/nein):
Goals-Einstellungen ohne Reiterzeile (ja/nein):
Fehler:
```
