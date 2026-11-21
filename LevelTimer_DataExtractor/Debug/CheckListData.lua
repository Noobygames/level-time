-- Daten der Spiel-Checkliste (Debug/CheckList.lua): offene Vikunja-Tickets mit Label "Im Spiel prüfen" (Projekt 5, LT).
-- Eintrag: { id, title, client = "all"|"forever"|"classic_era", triggers = { ... }, steps = { ... } }.
-- Trigger (feste Menge, siehe CheckList.lua): login, instance, raid, levelup, questAccept, questTurnIn, lfg, worldmap,
-- combat (nach dem Kampf), death, loot, flight, merchant, trainer, options, history, stream, anywhere.
-- Client: Label "Client: Forever" allein -> forever, nur "Client: Classic Era" -> classic_era, beides oder keins -> all.
-- Umfang: Tickets und Änderungen, die in Release v3.4.0 stecken (Commits von main..v3.4.0), dazu ältere offene Einträge;
-- alle übrigen offenen Tickets bleiben in Vikunja (Label 8). Automatisch prüfbares steht als Debug-Check (/lt debug check).
-- Stand 2026-11-21 (Einträge bis LT-388: 2026-11-17): Schritte und Trigger je Eintrag von Hand aus den Vikunja-Ticketbeschreibungen abgeleitet (konkrete
-- Handlung und Erwartung). Tickets ohne Spieltest (reine Daten-, Code- oder Planungsaufgaben) haben den einen Schritt
-- "Kein Spieltest nötig: im Ticket abschließen" und den Trigger anywhere.
-- Aktualisieren: Tickets mit `project = 5 && done = false && labels in 8` in kleinen Seiten neu lesen (sonst kommen die
-- Beschreibungen komprimiert) und Titel, Client, Trigger, Schritte nachziehen; erledigte Tickets bleiben in
-- LevelTimerDebugLog.checkResults.

local _, X = ...

X.CheckListData = {
  { id = "LT-104", client = "all", triggers = { "combat" },
    title = "Kill-Quest-Markierung",
    steps = {
      "Questziele markieren und Namensplaketten an, zu Questgegnern laufen, Größe-Regler verstellen.",
      "Erwartung: gelbes Ausrufezeichen links neben dem Lebensbalken, so hoch wie der Balken, kein Überlappen; mit Plater Fallback über der Plakette.",
    } },
  { id = "LT-125", client = "forever", triggers = { "anywhere" },
    title = "Schlafsack-Timer",
    steps = {
      "Forever: 'Gemütlichen Schlafsack' benutzen, dann /schlafen (unter 3 und mit 3 Stapeln Gut erholt); zwischendurch aufstehen.",
      "Erwartung: Karte zählt 180 s bzw. 60 s, Hinweise 'Gut erholt xN/3' und 'Fertig ausgeruht!', Aufstehen: 'Ausruhen abgebrochen'.",
    } },
  { id = "LT-303", client = "all", triggers = { "history" },
    title = "Mehr Icons in unseren Fenstern (bevorzugt Client-Icons/Atlas)",
    steps = {
      "Verlauf, Dungeon-Runs, Rückblick, Hinweisfenster und /lt setup öffnen.",
      "Erwartung: jedes Fenster hat ein Symbol vor dem Titel.",
    } },
  { id = "LT-338", client = "all", triggers = { "anywhere" },
    title = "Aufräumen: Quest-Sync, Profil-Import und Release-Workflow absichern",
    steps = {
      "In einer Gruppe mit einem anderen Level-Time-Spieler (Gruppen-Questabgleich an, auch anderer Realm) Quest-Tooltip ansehen; ein Mitspieler verlässt die Gruppe (Gruppe bleibt); /lte check LT338.sync.groupApi.",
      "Erwartung: Fortschritt des Gegangenen verschwindet aus dem Tooltip, ein Mitspieler vom anderen Realm bleibt drin, solange er in der Gruppe ist.",
    } },
  { id = "LT-349", client = "all", triggers = { "options" },
    title = "Wasserschild-Ladungen auch bei ausgeklappter Buffleiste",
    steps = {
      "Maus auf den Schalter für eingeklappte Buffs; Wasser-/Blitzschlagschild wirken, Buffleiste ein- und ausklappen.",
      "Erwartung: Tooltip sagt, dass die Buffleiste eingeklappt sein muss; eingeklappt zeigt die Anzeige die Ladungen.",
    } },
  { id = "LT-388", client = "forever", triggers = { "options" },
    title = "Beyond Ultra Grafik: Wetter, Wasserwellen, Sonnenstrahlen, HDR, Pause in Instanzen",
    steps = {
      "Beyond Ultra an, Wetter/Wellen/Sonnenstrahlen-Regler ändern (FPS beobachten), Seite aus; mit HDR-Monitor HDR an/aus; 'Pause in Instanzen' an, Dungeon betreten/verlassen; /lte check LT388.graphics.cvars.",
      "Erwartung: Änderung sichtbar, aus = Originalwerte zurück; im Dungeon Standardwerte, draußen wieder die eigenen; Check: missing leer.",
    } },
  { id = "LT-405", client = "all", triggers = { "instance", "options" },
    title = "Dungeon-Recap während des Laufs und Setup-Assistent-Schalter",
    steps = {
      "In einem Dungeon mit laufendem Tracker links auf den Tracker klicken (ohne Ziehen), dann /lt recap run, dann im Run-Fenster den Knopf Recap; /lte check LT405.recap.run.",
      "Erwartung: jedes Mal öffnet sich der Recap mit dem Zwischenstand des laufenden Laufs; Ziehen des Trackers öffnet ihn nicht; im Setup-Assistent gibt es die Schalter für Dungeon-Guide und Recap.",
    } },
  { id = "LT-411", client = "forever", triggers = { "worldmap" },
    title = "Dungeonquests: Alle markieren über mehrere Zonen, Karte öffnet einmal",
    steps = {
      "Hinweisfenster für Dungeonquests öffnen (Quests aus mehreren Zonen), 'Alle markieren' klicken; /lte check LT411.dungeonQuests.markAll.",
      "Erwartung: Kartenpunkte für alle Einträge in allen Zonen, die Weltkarte öffnet genau einmal (Elternkarte bei mehreren Zonen).",
    } },
  { id = "LT-412", client = "forever", triggers = { "anywhere" },
    title = "Dungeon-Vorquests: gelbes Ausrufezeichen bei Kettengebern, graue Quests in der Nähe",
    steps = {
      "In die Nähe eines Gebers einer Dungeon-Vorquest (auch graue Quest) laufen, Optionen 'Graue Quests in der Nähe' und 'kurz einblenden' einmal an/aus; /lte check LT412.trivialChain.state.",
      "Erwartung: gelbes Ausrufezeichen über dem Geber, Hinweis zur grauen Quest, Quest lässt sich annehmen; der Minimap-Filter geht danach wieder zurück.",
    } },
  { id = "LT-416", client = "all", triggers = { "combat", "options" },
    title = "Elite-Einblendung, Hinweisfenster unter der Maus, Abklingzeit-Zahlen",
    steps = {
      "Allein einen Elite-Gegner töten, danach dieselbe Art erneut innerhalb von 5 Minuten; in einer Gruppe und in einem Dungeon Elites töten; /lte check LT416.alerts.eliteGate. Außerdem Maus über ein Hinweisfenster halten und Namensplaketten mit Abklingzeit-Zahlen ansehen (Forever).",
      "Erwartung: Elite-Banner nur allein und je Gegnerart höchstens alle 5 Minuten; das Hinweisfenster bleibt unter der Maus stehen; keine Lua-Fehler durch Abklingzeit-Zahlen an Plaketten; Questreste enthalten keine Handwerkswaren (/lte check LT416.cleanup.leftoversTitles).",
    } },
  { id = "LT-401", client = "all", triggers = { "instance", "raid" },
    title = "Dungeon-Tracker: Porträtrahmen, Zeilenabstand, Bosse ausgeklappt",
    steps = {
      "Dungeon mit 7-8 Bossen betreten, Tracker ansehen; danach einen Schlachtzug mit mehr als 8 Bossen (z. B. Geschmolzener Kern).",
      "Erwartung: goldener Rahmen ums Boss-Porträt, sichtbar mehr Zeilenabstand, im Dungeon alle Bosse gelistet; im Schlachtzug nur besiegte und der nächste plus '+N weitere'.",
    } },
  { id = "LT-321", client = "forever", triggers = { "instance" },
    title = "Forever-Dungeon: Boss-Kills werden gezählt",
    steps = {
      "Einen Forever-5er (z. B. Scharlachrotes Kloster) spielen, Bosse anvisieren, nach jedem Boss die Fortschrittsanzeige prüfen; am Ende /lte check.",
      "Erwartung: Fortschritt zählt jeden Boss genau einmal, Splits sind gefüllt; LT321.bossKills.sources zeigt die zählende Quelle und ob encounterStart/encounterEnd/bossKill > 0 sind.",
    } },
  { id = "LT-390", client = "forever", triggers = { "lfg", "options" },
    title = "Gruppensuche: Flüstervorlage",
    steps = {
      "Einstellungen > Dungeons > Gruppensuche: Flüstertext ansehen/ändern (Platzhalter {role} {class} {level} {dungeon}); im Gruppensuche-Fenster eine Gruppe wählen und Flüstern klicken.",
      "Erwartung: genau eine Nachricht mit ersetzten Platzhaltern geht an den Leiter (im Chat sichtbar), nie ohne Klick; leerer Text = Standardtext; ohne gesetzte Rolle bleibt {role} leer.",
    } },
  { id = "LT-349", client = "all", triggers = { "combat" },
    title = "Wasserschild-Ladungen bei ein- und ausgeklappter Buffleiste",
    steps = {
      "Schamane mit Wasserschild: Buffleiste ausgeklappt ansehen und Tooltip der Option lesen; Leiste einklappen; dann einen Übungsdummy angreifen.",
      "Erwartung: ausgeklappt keine eigene Anzeige (Tooltip sagt warum), eingeklappt Wasserschild mit Ladungen und Restzeit hinter dem letzten Buff, auch im Kampf.",
    } },
  { id = "LT-389", client = "forever", triggers = { "lfg" },
    title = "Gruppensuche: Flüster-Verlauf",
    steps = {
      "Gruppensuche öffnen, Gruppe wählen, Flüstern klicken, Antwort des Leiters abwarten (auch realmübergreifend); Reiter Flüstern öffnen, eine Zeile anklicken.",
      "Erwartung: Reiter zeigt 'An <Leiter>' und 'Von <Leiter>', neueste zuerst; Klick öffnet den Chat an den Leiter; fremde Flüster erscheinen nicht.",
    } },
  { id = "LT-392", client = "forever", triggers = { "lfg", "instance" },
    title = "Gruppensuche: Mitspieler merken, bewerten, Abbrecher",
    steps = {
      "Mit 1-2 Spielern gruppieren, /lt lfg, Reiter Mitspieler: Klick wechselt + / - / leer. In einer Instanz verlässt ein Mitglied die Gruppe; zwischendurch einen Ladebildschirm durchlaufen. Reiter Suchen: Gruppe dieses Leiters ansehen.",
      "Erwartung: Namen erscheinen, nach dem Verlassen steht '!' und 'ging früh: 1 x', Ladebildschirme markieren niemanden, eigenes Verlassen auch nicht; das Zeichen steht in der Suche vor dem Leiternamen und bleibt nach /reload.",
    } },
  { id = "LT-403", client = "forever", triggers = { "instance" },
    title = "Krol'dok: Bossmann Toof als Boss",
    steps = {
      "Mit Debug-Log (/lt debug log) Feste Krol'dok bis nach Bossmann Toof spielen, danach /lte check.",
      "Erwartung: im Debug-Log steht bei Toof ein ENCOUNTER_START/ENCOUNTER_END mit Encounter-ID (Antwort ins Ticket), sonst keine Encounter-Zeile.",
    } },
  { id = "LT-106", client = "forever", triggers = { "combat" },
    title = "Kein Auren-Fehler beim Bosskampf",
    steps = {
      "Einen Dungeon-Boss angreifen (Essen-/Lager-Hinweis an), Kampf zu Ende spielen.",
      "Erwartung: kein Lua-Fehler 'GetAuraDataByIndex(): Auras cannot be accessed when secret'.",
    } },
  { id = "LT-393", client = "forever", triggers = { "anywhere" },
    title = "Dungeonbilder im Dungeon Guide",
    steps = {
      "Nach dem Login /lte check LT393.dungeonArt.coverage; dann das Dungeonkompendium einmal öffnen und schließen, /reload, Check erneut.",
      "Erwartung: found > 0 und der Guide zeigt Banner-Bilder; sonst steht unter raw, ob Erweiterungen (tiers) und eine erste Instanz geliefert werden (Antwort ins Ticket).",
    } },
}
