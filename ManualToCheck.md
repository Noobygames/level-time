# Im Spiel zu prüfen

**Offene Prüfpunkte stehen im Vikunja-Board** (Projekt Leveltime, Spalte „Im Spiel prüfen“, Label „Im Spiel prüfen“):
je Punkt ein Task mit Schritten, Erwartung und Antwortfeld. Diese Datei erklärt nur noch das Vorgehen und listet, was
das Debug-Log beantwortet. Erledigte Punkte bis 523: `ManualToCheck-done.md`.

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

1. Debug-Log, Prüfungen und `/lt debug` liegen im lokalen Addon **Level Time Data Extractor**
   (`LevelTimer_DataExtractor/`, nie veröffentlicht). `make install` bzw. `make update` installiert es mit; nach dem
   ersten Installieren einmal den Client neu starten (neues Addon, neue SavedVariables).
2. Die Einstellungen der Punkte einschalten, die du prüfen willst (Komfort, Hinweise, Speedrun, Statistiken); das
   Log hält fest, was an war (`settings.all`).
3. Das Log ist mit dem Data Extractor von selbst an (bleibt über `/reload` an); falls es ausgeschaltet wurde:

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
7. Danach bei Bedarf leeren mit `/lt debug log clear` (aus: `/lt debug log off`).

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
- **222. Schiffs- und Zeppelin-Zeiten, Datenteil (Roadmap 440)**: check `440.transport.state` (Strecken mit Phase, Periode, Fahrzeit, Anleger mit Position und Meister-IDs, Spielerposition, nächster Anleger, laufende Fahrt, API-Typen), Debug-Bereich `transport`, Probe `PLAYER_LEAVING_WORLD` mit Position in `state.map`; die Erkennung der Abfahrt am Anleger bleibt offen unter 222.
- **224. Grafikdetails, Datenteil (Roadmap 442, WoW Forever)**: check `LT388.graphics.cvars` (je CVar Wert, Client-Standard, gemerktes Original); sehen muss man nur die Wirkung, siehe 224.
- **190. Glücksrad, Datenteil (Roadmap 432)**: check `432.goals.wheel` (`SetRotation`/`GetRotation` an den Stücken, Tick-Ton `SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON`, `PlaySound`)
- **189. Schlafsack-Timer, Datenteil (Roadmap 430, WoW Forever)**: check `430.sleep.state` (Schlafsack in der Tasche, Zauber des Items aus `C_Item.GetItemSpell`, „Gut erholt“ mit `applications`/Dauer/Ablauf, `rolledOut`, Zustand des Timers samt `duration`) vor und während des Liegens, debug `sleep` (sleeping bag rolled out, emote SLEEP/STAND (andere Emotes nur beim Liegen oder 15 s nach dem Ausrollen), started by emote … countdown 180/60 s, well rested stacks … -> …, well rested refreshed after … s, ended: done/moving/combat/stand/jump), Proben `430.sleep.cast` und `430.sleep.auras` (springt `expirationTime` bei 3 Stapeln nach etwa 60 s auf volle 2 Stunden?)
- **213. Weglaufen, Datenteil (Roadmap 439)**: check `439.goals.escape` (Namen der Zauber, die den Kampf ohne Weglaufen beenden: Verschwinden 1856/1857/26889, Totstellen 5384, Schattenhaftigkeit 20580/58984, Unsichtbarkeit 66; `false` = Client kennt die ID nicht; Zustand von Ziel/Fokus/Maus als attacking/other/idle/unsure/dead, `UnitIsFeignDeath`/`UnitPlayerControlled` vorhanden), debug `goal:escape` (combat end: Name, Angriffsdauer, dead, seen alive, killed, nameless kill; escaped (combat end/aggro taken); combat end not counted: instance/death/combat drop; combat drop spell …) bei einem Kampf, aus dem man wegläuft, einem getöteten Gegner und einer abgenommenen Aggro
- **214. Momente, Datenteil (Roadmap 439)**: check `439.goals.moments` (verfügbare Modi, `IsSwimming`/`IsFalling` lesbar, `C_PlayerInfo.GetGlidingInfo`, `C_ChatInfo.PerformEmote`/`DoEmote`, `C_Spell.IsSpellHelpful`, `C_MerchantFrame.GetBuybackItemID`/`GetBuybackItemLink`/`BuybackItem`, Zahl gemerkter Quest-Belohnungen), debug `goal:moment` (rare seen …, fell … s, emote … at … (unit …), helpful spell … on … : heal/res, quest reward …, sold … (quest reward true/false), bought back slot …, <Modus> +1)
- **236. Minimap-Knopfleiste, Knöpfe nicht klickbar/ausgegraut (Roadmap 451)**: check `451.minimapBar.buttons` (je Knopf Deckkraft, Maus, Ebenen, Unterframes, Fade-Animation)
- **Charakter-GUID nach Fraktionswechsel/Umzug**: check `character.guid` (aktuelle gegen gespeicherte GUID; `same` muss nach dem Wechsel `true` sein, sonst beginnen die Daten des Charakters neu)
- **Schwungbalken, Kampflog in Forever (Roadmap 452)**: check `452.swing.combatlog` nach ein paar Nahkampfschlägen mit eingeschaltetem Schwungbalken (`combatLogSeen` = true heißt: eigene SWING_*-Events kommen an; false in Forever = Ersatztakt ab Kampfbeginn), debug `swing`
- **238. Zauberrang in der Zauberleiste, Datenteil (Roadmap 487)**: check `487.spellHistory.rank` nach ein paar Zaubern (roher Untertext je Zauber und gelesene Rangzahl; Era „Rang n“, Retail/Forever ohne Zahl = leer)
- **239. Häutbare Leichen glitzern, Datenteil (Roadmap 479)**: check `479.lootSparkles.skinning` als Kürschner vor einer leergeplünderten, häutbaren Leiche (Tooltipzeilen mit „Häutbar“, `hasLoot`/`canLoot` nach dem Plündern, `skinningTrained`, `kind` = corpse); ob das Soft-Targeting solche Leichen überhaupt wählt, zeigt `name`/`dead`
- **240. Boss-Kills, „Dungeon abgeschlossen“ und Instanz-Ansicht (Roadmap 483/484)**: check `483.bosses` (Bossliste der Instanz mit Namen, besiegte encounterIDs des Laufs, letzte Meldung: `encounter` = ENCOUNTER_END bzw. `died` = Fallback über UNIT_DIED, success, gezählt) und debug `instances` (boss killed ...); je Client einen Dungeon bis zum Endboss spielen, dann `/lt debug check`; debug `instances` „dungeon completed“ genau einmal je Lauf, `tooltip` im Check = Zeilen der Historien-Zeile (Totenkopf-/Kopf-Pfad je Boss)
- **242. XP und Gold im Quest-Tooltip, Datenteil (Roadmap 486)**: check `486.questRewards` (je Quest XP und Geld; in Era gleiche Beträge bei allen Quests = `GetQuestLogRewardMoney(questID)` ignoriert die ID, Vergleich `selectedMoney`; welche Hooks es gibt). Sichtprüfung: Questlog-Zeile überfahren (Einstellung an), Questkarte-Punkt überfahren; debug `quests` „reward line for …“ beim Überfahren statt Sichtprüfung
- **243. Reagenzien-Erinnerung, Datenteil (Roadmap 488, Classic Era/WoW Forever)**: check `488.reagents` (je Item der Klasse Name, Bestand, bekannte Zauber; in Forever: liefern die Classic-IDs Namen und `IsPlayerSpell` true?), debug `warnings` (WARN_REAGENTS, reagents sold here …). Sichtprüfung: Warnung mit Bestand, Chathinweis beim Reagenzienhändler
- **245. Minimap-Knopfleiste, Ebenen und Anker (Roadmap 481)**: check `481.minimapBar.layers` (je Knopf Ebene, feste Ebene/Schicht, alle Anker, über der Leiste); debug `minimapbar` „mouse down on …“ je Klick auf einen gesammelten Knopf (kommt der Klick an?), Punkte nach dem Ziehen zeigen, ob er in der Leiste bleibt
- **244. Twink-Knopf mit Vor- und Nachname (Roadmap 480, WoW Forever)**: check `450.mail` (`unitName` = Rückgaben von `UnitName("player")`, gespeicherter `surname`); `altRecipients` = Namen, die der Knopf einträgt, debug `mail` „filled recipient“
- **246. Dungeon-Eingänge auf der Karte, Datenteil (Roadmap 497, WoW Forever)**: check `497.dungeonEntrances` (`atlas` = Client kennt den Atlas „Dungeon“, sonst Runen-Symbol; Eingänge der offenen Karte mit Instanz und Zahl offener Dungeonquests). Sichtprüfung: Einstellung an, Weltkarte einer Zone mit Dungeon öffnen (z.B. Brachland, Tirisfal); Symbol am Eingang, Tooltip mit Name, Level-Bereich und Quests; Boss-Level im Instanz-Tooltip der Historie
- **247. Gewählte Buffs bei eingeklappter Buffleiste (Roadmap 500)**: check `500.collapsedBuffs` mit eingeklappter Buffleiste und aktivem Wasser-/Blitzschlagschild, je Client (`collapsed` = true, `hasIsExpanded`, `buttonEnabled`, `matches` mit Ladungen und Restzeit, `shown` > 0; im Kampf `aurasReadable`; `cooldownViewer` = Verfügbarkeit des Cooldown-Managers). Sichtprüfung: Symbol mit Ladungszahl und Restzeit erscheint beim Einklappen, verschwindet beim Ausklappen, verschiebbar im Edit-Modus; Texte der Einstellung passen in allen vier Sprachen
- **249. Dungeon-Flügel beim Betreten erkennen (Roadmap 493, WoW Forever/Classic Era)**: check `493.instances.wing` direkt nach dem Betreten jedes Flügels des Scharlachroten Klosters (und Düsterbruch): `uiMapID`, `zone`, `subZone`, `minimapZone` je Flügel; mit Gegnern in Sicht und einem Ziel: `plates`/`target` = Namen oder `secret` (Rückfall Trash-Namen je Flügel). Unterscheidet ein Wert die Flügel verlässlich, kann ein anderer Flügel als neue Kopie zählen
- **516. Boss- und Gegnerfähigkeiten im Tooltip, Datenteil (LT-10/LT-11)**: check `LT10.mechanics.mouseover` mit der Maus über einem Dungeon-Boss, in WoW Forever und Classic Era, je einmal in und außerhalb einer Instanz (`guidSecret` muss `false` sein, sonst fehlen die Zeilen in Instanzen; `npcID`, `mechanics` > 0)
- **525. Gegner-Zauber aus dem Kampflog, Datenteil (LT-52, WoW Forever/Classic Era)**: check `LT52.combatlog.guid` nach ein paar Kämpfen in einem Dungeon (`instance` = Karten-ID, `events` > 0, `npcSources` > 0 = Quell-GUIDs lesbar; `secretGuids` > 0 = GUIDs geheim, dann keine Zauberdaten; `nameKeys` > 0 = Kampflog ohne Zauber-IDs; `lastGuid` = Beispiel). Danach `/reload` und `make extract-check`: Abschnitt "Abgleich mit den Mechaniken"
- **Kampflog-Ersatz in WoW Forever (LT-267)**: check `LT267.combatlog.api` in WoW Forever und Classic Era nach einem Dungeon-Kampf mit Nahkampf-Angriff (`cCombatLogGetCurrentEventInfo`/`globalCombatLogGetCurrentEventInfo` = Abruf vorhanden, Forever laut Doku `false`; `restricted` = `IsCombatLogRestricted()`; `cleuEvents` > 0 = Event feuert trotzdem; `deathCause` = combatlog/deathrecap, `bossDeaths` = combatlog/unit_died, `swing` = combatlog/player_swing/fallback, `extractorSpells` = Zaubersammlung an). Fragen: kommt in Forever `PLAYER_SWING` (sonst `player_swing pending`), zählt ein Boss nach einem Kill über `UNIT_DIED` (check `483.bosses`: `last.source` = `died`, wenn ENCOUNTER_END fehlte)?
- **Schadensmesser-API als Zauber-/Todesquelle (LT-285, WoW Forever)**: check `LT285.damageMeter.api` einmal außer Kampf direkt nach einem Kampf (am besten Dungeon-Boss mit Tod). `api = absent` = kein C_DamageMeter; `available`/`failureReason`/`cvar` (damageMeterEnabled) = ob der Schadensmesser nutzbar ist; `sessions` = Kampfsitzungen (ID/Name/Dauer; je Boss/Trash?); `damageTaken.sample` = Quellen mit `sourceGUID`/`sourceCreatureID` (`secret` = auch außer Kampf nicht lesbar), `spells` = Zauberanzahl, `spell1.spellID`/`isDeadly`; `deaths.sample[].deathRecapID` = Todesursache lesbar? Blockiert LT-286.
- **526. Quest-Fokus und Questpfeil, Datenteil (LT-259/LT-260, WoW Forever/Classic Era)**: Questkarte und Questpfeil an, eine Quest fokussieren, check `LT259.questArrow.state` draußen (`focus` = Quest-ID, `hasModifyMenu` in Forever bzw. `hasEraLogClick` in Era true, `facing` eine Zahl, `rotation`/`distance` gesetzt) und in einer Instanz (`rotation` nil = kein Pfeil)
- **LT-254. Schlüssel- und Einstimmungsreihen, Datenteil (WoW Forever/Classic Era)**: check `LT254.attunements` (je Instanz `steps`/`done` = erkannter Stand passt zum Charakter; `unknown` leer = der Client kennt alle Quests der Reihe, sonst gibt es sie in Forever so nicht).
- **Zonenstufen auf der Weltkarte, Datenteil (LT-252, WoW Forever)**: check `LT252.map.zoneLevels` (`withLevels` > 0 und `zones` stimmen mit dem Forever-Guide = Blizzards eigene Anzeige beim Überfahren reicht, Ticket schließen; `withLevels` 0 oder abweichende Werte = eigene Tabelle nötig). Zusätzlich auf der Weltkarte eine Zone überfahren: Name mit (min-max) farbig.
- **LT-279. Kills ohne Kampflog (WoW Forever)**: nach ein paar Kills check `LT279.kills.events` (`active` true, `partyKills` > 0 = PARTY_KILL feuert, `secretGuids` 0 = GUID lesbar, `unnamed` = Kills ohne bekannten NPC-Namen, `unitDied` > 0).
- **LT-278. Gegner-Zauber ohne Kampflog (WoW Forever)**: in einem Dungeon ein paar Kämpfe, check `LT52.combatlog.guid` (`unitCasts` true, `npcSources` > 0 = Zauber-IDs von Gegnern kommen lesbar an, `secretGuids` 0, danach `instances[Karten-ID].spells` in LevelTimerExtractorDB gefüllt).
- **LT-271. Gruppensuche-Tooltip und Sprachfilter, Datenteil (WoW Forever)**: in der Gruppensuche (I) einmal suchen, dann checks `LT271.lfg.finder` (`loaded`/`ui` = welche Gruppensuche lädt, woran die Hooks hängen; `tooltipEnabled` true), `LT271.lfg.encounters` (je Gruppe `raw` = Namen oder IDs der besiegten Bosse, `mapID` = Instanz der Aktivität, `matchedNpcs` nicht leer, wenn Bosse besiegt sind = Namen passen zur Bossliste; sonst fällt die Quest-Machbarkeit auf machbar zurück) und `LT271.lfg.languages` (mit Schalter "alle Sprachen" an: `enabled` enthält alle `available`, `backup` = vorheriger Filter; `canChange` false in der US-Region = Filter dort nicht änderbar). Sehen muss man nur: Tooltip einer Gruppe zeigt unter Blizzards Zeilen den Block "Level Time" (Mitglieder mit Rolle/Level/Zone, Spanne, offene Rollen, Quests mit machbar/Boss bereits tot), auch im Classic-Stil unter dem Tooltip-Rahmen.

- **LT-272. Eigenes Gruppensuche-Fenster (WoW Forever)**: Einstellungen, Reiter Gruppensuche, "Eigenes Gruppensuche-Fenster statt Blizzards" an; Check `LT272.lfg.window` (`functions` = welche Öffner existieren (`LFGVanilla_ShowFrame` muss true sein), `api` alle true, `categories` nicht leer, `roles`). Sehen muss man: (1) I, Minikarten-Auge und Warteschlangenknopf öffnen das eigene Fenster (Blizzards Fenster bleibt zu, zweiter Tastendruck schließt; Reiter Wer bleibt Blizzards); (2) Esc schließt, Fenster verschiebbar, Position bleibt nach /reload; (3) Suchen nur auf Klick, Ergebnisse mit Level/Rollen/Alter, "Passend für mich", Weitere Filter (Sprachen, Art), Detail rechts mit Mitgliedern, Quests, Warnung bei 13 Level Abstand; (4) Flüstern öffnet das Chatfeld, Einladen bei Einzelspielern funktioniert ohne "action blocked"-Meldung (Taint, `/lt debug` Taint-Zeilen); (5) Eigene Gruppe: Eintragen/Aktualisieren/Austragen, Rollen als Einzelspieler, als Mitglied nur Hinweis "Nur der Gruppenleiter"; (6) die Rollen- und Haken-Symbole in der Liste erscheinen (sonst Atlas fehlt: `|A:...|a` oder `ReadyCheck-*`).
- **LT-273. Ziele annehmbarer und Gruppen-Dungeonquests an Namensplaketten (WoW Forever)**: Quest-Markierungen an, in einer Instanz mit Gegnern einer annehmbaren Dungeonquest bzw. Gruppenquest (Mitglied mit Gruppen-Questabgleich): check `LT273.questmarks.instance` (`related` = Plaketten mit aktiver Quest, `take`/`party` = Treffer der Umkehrkarte, `secretGuid` = Plaketten ohne lesbare NPC-ID; in Forever-Instanzen können GUIDs geheim sein, dann gibt es keine Markierung). Sichtbar prüfen: anderes Symbol je Art.
- **LT-287. Bücher sammeln, Datenteil (WoW Forever)**: Debug-Log an, in Bibliotheken (z. B. Sturmwind, Unterstadt, Darnassus) mehrere Bücher auf Regalen und als Gegenstand öffnen, danach check `LT287.books.collected` (`extractorBooks` = Anzahl, `rows[].objects` = Objekt-ID des Buchs, falls eine der Einheiten npc/softinteract/mouseover/target es liefert) und Ereignis-Probe `ITEM_TEXT_BEGIN` (`extra.units` zeigt, welche Einheit eine GameObject-GUID hat; kein Eintrag bei einem Buch = feuert nicht). Danach `LevelTimerExtractorDB.books` für den Import auswerten.
- **LT-305. Gruppensuche-Fenster in Blizzard-Optik (WoW Forever)**: Check `LT272.lfg.window` (`look`: `panelTitle`, `closeButton`, `dropdownMenu`, `playstyles`, `voiceModes`, `playstyleText` alle true). Sehen muss man: (1) Fenster wie Blizzards (Porträtrahmen, rote Knöpfe, Blizzard-Auswahllisten), Reiter unter dem Rahmen; (2) Eigene Gruppe: runde Rollenknöpfe mit Haken, Anführer-Symbol = einsteigerfreundlich, Spielstil Pflicht fürs Eintragen, Aktivitäten mit Haken und Level-Spanne absteigend, "Alle Stufen anzeigen", Voicechat, Zurück/Austragen/Eintragen; Eintragen mit Mehrfachauswahl, Spielstil und Voicechat übernimmt Blizzards Fenster/Minikarten-Tooltip (kein "action blocked"); (3) Suchen: Aktivitätsliste nach Level mit Spannen, "Passend für mich" blendet unpassende Aktivitäten aus, Rollen-Symbole gut lesbar, "Suche läuft" verschwindet mit den Ergebnissen; (4) Gruppe wählen: Detail als Seitenfenster rechts, X schließt es; (5) Texte deutsch, wenn die Addon-Sprache (Einstellung) Deutsch ist. Offen: Kommentarfeld fehlt (nur Blizzards gesichertes Feld wird gelesen).
- **LT-351. Seitenreiter an Blizzards Gruppensuche (WoW Forever)**: Blizzards Gruppensuche (I) öffnen, unseren Reiter (Level-Time-Symbol) unter "Wer" klicken, dann Check `LT351.lfg.sidetab` (`template`, `whoTab`, `tab` true; `anchor` = `WhoListingTab` bzw. `LFGForever`, wenn LFG Forever installiert ist; `taintedBy` leer). Sehen muss man: (1) Klick-Klang und Tooltip am Reiter; (2) Blizzards Fenster schließt, unseres öffnet; im Kampf öffnet nur unseres; (3) danach Blizzards Gruppensuche im Kampf öffnen, kein "action blocked"; (4) an unserem Fenster rechts dieselbe Leiste (Eintragen, Suchen, Wer, ggf. LFG Forever, unserer markiert), bei offenem Detail rechts am Detail; Blizzards Reiter öffnen Blizzards Fenster auf diesem Reiter, im Kampf nur eine Chatmeldung.
- **LT-352. Gruppensuche-Filter wie LFG Forever (WoW Forever)**: Sehen muss man: (1) Weitere Filter ersetzt die Liste und passt ohne Überlappung ins Fenster (auch fr/es), Suchen zeigt wieder die Liste; (2) Gruppen nach Rolle, Einzelspieler nach Rolle und Level (Enter übernimmt), Klassen (4 Spalten, Blizzards Namen), Spielstil filtern die Liste; nach /reload sind die Filter noch gesetzt, Zurücksetzen stellt den Standard her; (3) Freunde/Gilde stehen oben; (4) Rollenabfrage nur als Leiter/Assistent aktiv und startet Blizzards Abfrage ohne "action blocked"; (5) Tastenbelegung "Level-Time-Gruppensuche" unter AddOns; (6) eine hängende Suche zeigt nach 15 s "gescheitert". Datenteil: check `LT352.lfg.filters` bei offener Gruppensuche (`saved` = gespeicherte Filter, nach /reload gleich; `rolePoll`, `leader`/`assistant`; `binding` = Taste; `classes` = Klassennamen des Clients, keiner `false`; `playstyles` true), dazu `LT352.lfg.api` und die Proben `lfg.results`/`lfg.hover` (Rohfelder je Gruppe und Mitglied).
- **LT-388. Beyond Ultra Grafik (WoW Forever)**: check `LT388.graphics.cvars` nach dem Login und einmal in einer Instanz (`missing` leer = der Client kennt alle CVars, sonst stehen dort z. B. `weatherDensity`/`rippleDetail`/`sunshafts`/`HDR*`; je CVar `value`/`default`/`overridden`; `paused` true nur mit "Pause in Instanzen" in einer Instanz).
- **LT-387. Dungeon-Guide jederzeit (WoW Forever)**: draußen `/lt guide`, dann check `LT387.guide.anytime` (`count` > 0, `unnamed` 0 = alle Dungeons mit Namen in Client-Sprache, `sample` nach Level sortiert, `noRange` = Dungeons ohne Levelbereich am Ende; `suggested`/`suggestedName` = Vorauswahl zum eigenen Level; `shown`, `pages` > 0).
- **LT-335..338. Gruppen-Sync abgesichert**: in einer Gruppe mit einem zweiten Level-Time-Spieler check `LT338.sync.groupApi` (`functions` alle true; je Peer `inParty` true = UnitInParty erkennt Absender "Name-Realm"; nach dem Verlassen der Gruppe ist `peerCount` 0).
- **LT-350. Einstellungen nach Themen**: Einstellungen öffnen, check `LT350.options.pages` (acht Reiter in der neuen Reihenfolge, `hits` = Seite je Suchbegriff) und `LT350.options.textFit` je Sprache (de/en/fr/es; `tooLong`/`overflow` leer = nichts abgeschnitten).
- **LT-393. Dungeonbilder im Dungeon Guide (WoW Forever)**: nach dem Login check `LT393.dungeonArt.coverage` (`journal` true = Dungeonkompendium-API da, `total` = gefundene Instanzbilder, `found` = Guide-Dungeons mit Bild, `missing` = Beispiele ohne Bild). Sehen muss man: `/lt guide`, Bild unter der Dungeonwahl scharf und sinnvoll beschnitten.
- **LT-395. Symbole mit WoW-Bedeutung**: check `LT395.icons.spells` (`missing` leer = jeder Zauber der Einstellungs-Symbole hat im Client ein Symbol). Sehen muss man: Einstellungen durchklicken, Symbole passen zur Bedeutung; Reiter oben und Seitenleiste links als Reiter erkennbar (Fläche, Hover, goldene Marke, aktive Seite hervorgehoben).
- **LT-404. Zauber-Links im Dungeon Guide**: check `LT404.guide.spellLinks` (`linked` = verlinkte Zeilen, `unknown` = Zauber-IDs ohne Namen im Client, `mismatch` = Beispiele, wo Clientname und Text abweichen). Sehen muss man: `/lt guide`, über einen goldenen Zaubernamen fahren (Tooltip), Shift-Klick in den Chat und die Nachricht wirklich senden.
- **LT-408. Sprachflaggen in der Gruppensuche (WoW Forever)**: `/lt debug log` an, Gruppensuche öffnen und einmal normal suchen (Dungeons, mehrere Sprachen), dann `/lt debug check` (check `LT408.lfg.realms`: `withRealm`/`leaders` = Leader mit Realm im Namen, `realms` = Realm -> Anzahl, `own` = eigener Realm). Danach `/lt debug lfgsearch`, 5 Sekunden warten, `/reload` (Zeilen `lfg.searchProbe` mit `click1`, `click2`, `timer` und die Proben `LFG_LIST_SEARCH_RESULTS_RECEIVED`/`LFG_LIST_SEARCH_FAILED`/`ADDON_ACTION_BLOCKED`: wie viele Suchen ein Tastendruck erlaubt und ob eine Suche ohne Klick geht). Eine Meldung „Aktion blockiert“ ist dabei erwartet.
- **LT-410. Ruhestein-Hinweis**: Debug-Log an, ein Gasthaus und eine Hauptstadt betreten (zu Fuß und einmal per Flug/Portal); Probe `PLAYER_UPDATE_RESTING` (`resting` true beim Betreten, `bind` = Ruhestein-Ort im Text der Client-Sprache). Sehen muss man: Hinweis „Ruhestein gebunden an: …“ mit Ruhestein-Symbol, einmal je Betreten.
- **LT-412. Graue Vorquests in der Nähe (WoW Forever)**: check `LT412.trivialTracking.api` (`index` = Filter-Index "Triviale Quests", `setOk` true = SetTracking aus Addon-Code erlaubt, `filteredBefore`/`filteredAfter`/`filteredRestored` = Zustand vor, nach Umschalten und nach Zurückschalten; der Check schaltet kurz um und zurück). Sehen muss man: Stufe 40+ Horde in Mulgore bei Häuptling Hawkwind: Hinweis „Graue Vorquest in der Nähe“, das „!“ über dem Geber; mit Option „Graue Quests dort kurz einblenden“ zeigt Blizzard den Geber auf der Minimap und der Filter geht beim Entfernen wieder aus.
- **LT-413. Leerer Realmname (WoW Forever ab Build 71037)**: check `LT413.realm.sources` (`realmName`/`normalized` = Client-Realm, `fullRealm` = UnitFullName, `realmID`, `used` = Realm, den Level Time nutzt, `key` = Charakterschlüssel). Sehen muss man: `key` ist `Name-Realm` (nicht `Name-`), die History zeigt weiter den bisherigen Charakter mit wachsender Spielzeit.
- **LT-401. Dungeon-Tracker-Optik**: check `LT401.tracker.layout` (`bosses`, `expanded` true bis 8 Bosse, `rowSpacing` 4, `portraitBorder` true). Sehen muss man nur Rahmen und Abstand.
- **LT-321. Boss-Kills in Forever-Dungeons**: nach einem Lauf check `LT321.bossKills.sources` (`counted` = "Encounter-ID:Quelle" je gezähltem Boss, Quelle `encounter`/`bosskill`/`unit`; `encounterStart`/`encounterEnd`/`bossKill` = wie oft die Events kamen). Beantwortet, ob ENCOUNTER_END/BOSS_KILL in Forever-5ern kommen.
- **LT-390. Flüstervorlage der Gruppensuche (WoW Forever)**: check `LT390.lfg.templates` (`template`, `custom`, `sample` = ersetzter Text für den eigenen Charakter, `length` <= 255, `sendApi`, `role`). Sehen muss man nur, dass der Klick auf Flüstern die Nachricht sendet.
- **LT-414. Doppel-Einträge mit leerem Realm**: check `LT414.realm.orphans` (`count` = aufgehobene Einträge, je Eintrag `characterKey`, `guidMatch`, `seconds`). Nur bei `count` > 0 muss man das Zusammenführen in der Historie ansehen.
- **LT-349. Wasserschild-Ladungen**: im Kampf mit eingeklappter Buffleiste check `LT349.waterShield.display` (`barCollapsed`, `aura.applications` lesbar oder nur `countText`, `shown`, `anchor`).
- **LT-389. Flüster-Verlauf der Gruppensuche (WoW Forever)**: nach einer Flüster-Runde check `LT389.lfg.whisperLog` (`eventsSeen` == `eventsReadable` = Namen lesbar, `contacted`, `entries`, `last`). Sehen muss man nur den Reiter.
- **LT-278. Gegner-Zauber ohne Kampflog (Extractor, WoW Forever)**: nach einem Dungeon check `LT278.spells.casts` (`spellIDReadable` vs `spellIDSecret`, `secretGuids`, `npcsWithSpells`, `sample`). Alles geheim = `instance_spells` bleibt leer, dann andere Quelle nötig.
- **LT-392. Mitspieler der Gruppensuche (WoW Forever)**: check `LT392.lfg.players` (`recent`, `rated`, `leavers`, `rosterNamesRead`/`rosterNamesSecret` = Gruppennamen lesbar). Sehen muss man Reiter und Zeichen in der Suche.
- **LT-353. Von Hand ergänzte Dungeon-Quests (Abgleich 2026-11-21)**: check `LT353.quests.added` (je Quest "ID Clienttitel | DB-Name"; `unknown` = Client kennt die ID nicht oder Titel nicht geladen, dann Check wiederholen). Geber, Mindestlevel und Koordinaten der neuen Quests stehen in den Prüf-Tasks.
