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
  { id = "LT-318", client = "forever", triggers = { "instance" },
    title = "Dungeon-Flügel vor dem ersten Boss erkennen (Kloster, Stratholme, Düsterbruch, Schwarzfels)",
    steps = {
      "Scharlachrotes Kloster per Gruppensuche-Eintrag betreten (Kathedrale), vor dem ersten Boss Tracker und Tooltip ansehen.",
      "Erwartung: Fortschritt zeigt die Bosse des Flügels (z. B. 0/2 statt 0/7); der Flügel wird auch durch den ersten Trash-Kill erkannt.",
    } },
  { id = "LT-319", client = "all", triggers = { "instance" },
    title = "Instanz-Bericht wird nach /reload in der Instanz nicht erneut gepostet",
    steps = {
      "In einer Instanz mit Gruppe /reload ausführen.",
      "Erwartung: der Instanz-Bericht wird nach /reload nicht in den Gruppenchat gepostet.",
    } },
  { id = "LT-320", client = "all", triggers = { "options" },
    title = "Einstellungen mit Symbolen: Reiter, Seitenleiste, Abschnitte",
    steps = {
      "Einstellungen öffnen: Reiter, Seitenleisten-Einträge und Abschnitts-Überschriften ansehen (auch fr/es).",
      "Erwartung: Spiel-Symbole an Reitern und Unterseiten, auf allen Clients sichtbar, Text nicht abgeschnitten.",
    } },
  { id = "LT-322", client = "forever", triggers = { "lfg" },
    title = "Gruppensuche-Tooltip: Blizzards Tooltip ergänzen statt doppelter Block",
    steps = {
      "Forever: Gruppensuche öffnen, Maus über einen Sucheintrag.",
      "Erwartung: im Blizzard-Tooltip ergänzt Level Time Zone je Mitglied, Level-Spanne und Passung, '13 Level'-Warnung, offene Rollen, Freunde/Gilde, offene Dungeonquests; kein zweiter Tooltip darunter.",
    } },
  { id = "LT-324", client = "all", triggers = { "combat" },
    title = "Reichweiten-Anzeige löst im Kampf keine blockierte Aktion mehr aus",
    steps = {
      "Im Kampf (Kampfsperre) mit eingeschalteter Reichweitenanzeige ein Ziel anvisieren.",
      "Erwartung: kein ADDON_ACTION_BLOCKED, die Reichweitenanzeige ist im Kampf ausgeblendet.",
    } },
  { id = "LT-325", client = "all", triggers = { "options" },
    title = "Hinweisfenster schließt nach einstellbarer Zeit von selbst (Standard 10 s)",
    steps = {
      "Einstellungen: Hinweisfenster-Einstellung prüfen; Hinweis auslösen und Zeit abwarten (Maus daneben und darüber).",
      "Erwartung: automatisches Schließen standardmäßig an, Dauer per Regler (Standard 10 s), unter der Maus bleibt das Fenster stehen.",
    } },
  { id = "LT-326", client = "forever", triggers = { "lfg" },
    title = "Gruppensuche-Fenster: Gruppen und Einzelspieler getrennt, Reihenfolge, Blizzard-Kartenstil",
    steps = {
      "Eigenes Gruppensuche-Fenster öffnen, suchen, mit und ohne eigene Gruppe vergleichen.",
      "Erwartung: Treffer in zwei einklappbaren Abschnitten 'Gruppen' und 'Einzelspieler' (ohne Gruppe oben Gruppen, in Gruppe oben Einzelspieler), Einträge als Karten mit Leiter, Aktivität, Rollen-Slots.",
    } },
  { id = "LT-328", client = "forever", triggers = { "questAccept" },
    title = "Dungeonquests: Classic-Mindeststufe in Forever zu niedrig (z.B. Negolash ab 51)",
    steps = {
      "Forever: Quest 'Negolash anlocken' (619) mit Level 41 beim Geber prüfen.",
      "Erwartung: die Quest gilt nicht als annehmbar (Mindeststufe 51); echte Forever-Stufe bestätigen.",
    } },
  { id = "LT-330", client = "all", triggers = { "worldmap" },
    title = "Dungeonquests über dem Levelbereich der Instanz nicht mehr anzeigen",
    steps = {
      "Mit Level 41 im Brachland Geber für Höhlen des Wehklagens (15-25) suchen; Weltkarte, Minimap, Zonen-Hinweis.",
      "Erwartung: keine Geber-Symbole, kein Hinweis für Instanzen unter dem eigenen Level; Liste in der Instanz bleibt mit 'nicht annehmbar'.",
    } },
  { id = "LT-331", client = "forever", triggers = { "instance" },
    title = "Dungeon Guide: Fenster mit Trash- und Bossseiten beim Betreten",
    steps = {
      "Client neu starten; eine neue Instanzkopie (z. B. Todesminen) betreten; blättern; Haken 'Nicht mehr automatisch anzeigen'; /lt guide; Scharlachrotes Kloster.",
      "Erwartung: Guide öffnet mit Trash-Seite und Bossseiten (Porträt, Mechaniken, Zaubersymbole), mit Haken kein Autoöffnen, Kloster zeigt nur Bosse des Flügels.",
    } },
  { id = "LT-286", client = "forever", triggers = { "instance" },
    title = "Extractor: Gegner-Zauber und Todesursache aus C_DamageMeter sammeln (Forever)",
    steps = {
      "Nach einem Dungeon-Kampf außerhalb des Kampfes /lte check LT285.damageMeter.api eingeben.",
      "Erwartung: available=true und collector.reads mindestens 1.",
    } },
  { id = "LT-297", client = "all", triggers = { "worldmap" },
    title = "Karte aufdecken: Kacheldaten unerkundeter Gebiete importieren und Overlay zeigen",
    steps = {
      "Komfort > Weltkarte > Karte aufdecken einschalten, Weltkarte einer halb erkundeten Zone öffnen.",
      "Erwartung: unerkundete Gebiete abgedunkelt und lückenlos; Zonenwechsel zeichnet neu; aus = weg.",
    } },
  { id = "LT-300", client = "all", triggers = { "options" },
    title = "Rest aus LT-295: Options-Fensterkopf, Mindestschrift 12, feste Textbreiten",
    steps = {
      "/lt öffnen, auch auf Französisch und Spanisch.",
      "Erwartung: Titel links, Suche und Erweitert daneben, Schließen rechts; Erklärtexte größer; nichts abgeschnitten.",
    } },
  { id = "LT-303", client = "all", triggers = { "history" },
    title = "Mehr Icons in unseren Fenstern (bevorzugt Client-Icons/Atlas)",
    steps = {
      "Verlauf, Dungeon-Runs, Rückblick, Hinweisfenster und /lt setup öffnen.",
      "Erwartung: jedes Fenster hat ein Symbol vor dem Titel.",
    } },
  { id = "LT-308", client = "all", triggers = { "options" },
    title = "Addon-Sprache folgt standardmäßig dem Client; Profile übernehmen die Sprache nicht",
    steps = {
      "/lt setup: im ersten Schritt Automatisch oder eine Sprache wählen; danach das Profil wechseln.",
      "Erwartung: Texte wechseln sofort, Automatisch = Client-Sprache, der Profilwechsel ändert die Sprache nicht.",
    } },
  { id = "LT-334", client = "all", triggers = { "instance" },
    title = "Dungeon-Run-Recap nach Endboss",
    steps = {
      "Era/Forever: Dungeon mit Gruppe bis zum Endboss spielen; nach dem Kampf /lte check LT334.recap.state; Reiter Übersicht, Beute, Gruppe, Gegner und 'Runs-Fenster' klicken; später /lt recap run.",
      "Erwartung: Rückblick öffnet nach Kampfende von selbst (Laufzeit mit Bestzeit/Ø, Kacheln, Highlights), Gruppe/Gegner mit Schadensmesser-Werten (sonst Hinweis), Esc schließt; Einstellung aus = kein Fenster.",
    } },
  { id = "LT-338", client = "all", triggers = { "anywhere" },
    title = "Aufräumen: Quest-Sync, Profil-Import und Release-Workflow absichern",
    steps = {
      "In einer Gruppe mit einem anderen Level-Time-Spieler (Gruppen-Questabgleich an, auch anderer Realm) Quest-Tooltip ansehen; ein Mitspieler verlässt die Gruppe (Gruppe bleibt); /lte check LT338.sync.groupApi.",
      "Erwartung: Fortschritt des Gegangenen verschwindet aus dem Tooltip, ein Mitspieler vom anderen Realm bleibt drin, solange er in der Gruppe ist.",
    } },
  { id = "LT-340", client = "forever", triggers = { "anywhere" },
    title = "Schlafsack-Timer startet nicht ständig neu (auch nicht in Gasthaus/Stadt)",
    steps = {
      "Forever: auf den Schlafsack legen (Chatzeile 'Ihr fühlt Euch erholt'), Timer bis 'Fertig' laufen lassen; danach im Gasthaus/in der Stadt aufstehen und 1 Minute warten.",
      "Erwartung: Karte startet mit der Chatzeile; nach 'Fertig' oder Aufstehen beginnt kein neuer 60-s-Countdown.",
    } },
  { id = "LT-342", client = "all", triggers = { "options" },
    title = "Hinweise wechseln komplett die Sprache (kein Deutsch/Englisch-Mix)",
    steps = {
      "Hinweise auslösen (z. B. fehlender Buff 'Satt', Dungeonquest-Hinweis 'Weitere Quests für ...'), dann die Addon-Sprache wechseln.",
      "Erwartung: Überschrift, Knöpfe und alle Zeilen in der neuen Sprache, kein Mix wie 'Hinweise' über 'Missing buff: Not well fed!'.",
    } },
  { id = "LT-343", client = "all", triggers = { "anywhere" },
    title = "Hinweisliste: Zeilen wachsen mit dem Text, kein doppelter Titel, normaler Schließen-Knopf",
    steps = {
      "Mehrere Hinweise sammeln (Addon-Sprache Französisch oder Spanisch), Hinweisliste ansehen.",
      "Erwartung: dreizeilige Texte laufen nicht in die nächste Zeile, Buff-Erinnerung ohne doppeltes 'Fehlender Buff:' vor '... fehlt!', Schließen-Knopf in Standardgröße.",
    } },
  { id = "LT-344", client = "all", triggers = { "login" },
    title = "Anzeigen starten nicht übereinander (eigene Standardposition je Fenster)",
    steps = {
      "Positionen im Edit-Modus zurücksetzen; Hinweisliste, Dungeonquest-Hinweis, Lagerfeuer, Level-Up, Flugzeit, Quest-Item-Knopf, Schwungbalken und Run-Tracker zeigen.",
      "Erwartung: keine zwei Anzeigen liegen übereinander; schon verschobene Anzeigen bleiben, wo sie waren.",
    } },
  { id = "LT-345", client = "all", triggers = { "instance" },
    title = "Run-Karte kompakter: nur nächste Bosse, keine Null-Werte, Stern erklärt",
    steps = {
      "Dungeon betreten, Run-Karte beobachten, Bosse töten; Forever: Maus auf ein Beute-Symbol mit '*'.",
      "Erwartung: nur nächster Boss ('>') plus '+N weitere'; Fußzeile Kills · Tode · XP/h erst nach dem ersten Kill; Tooltip-Zeile '* aus Classic übernommen, für Forever unbestätigt'.",
    } },
  { id = "LT-346", client = "all", triggers = { "loot" },
    title = "Würfelkarte verständlich: Tooltip, keine Nullen, kein doppeltes Icon",
    steps = {
      "Würfelzähler und Namen an, in der Gruppe würfeln (oder Edit-Modus), Maus auf die Würfelkarte.",
      "Erwartung: nur Wahlen mit Stimmen (keine '0'), Würfel als Kartensymbol, Gegenstand einmal; Tooltip mit Namen je Wahl in Klassenfarbe ('Bedarf: 2 (A, B)').",
    } },
  { id = "LT-347", client = "forever", triggers = { "lfg" },
    title = "Gruppensuche: Kategorie lesbar, Blizzard-Texte, klare Filter",
    steps = {
      "Eigenes Gruppensuche-Fenster öffnen (Addon-Sprache ungleich Client-Sprache), 'Weitere Filter' öffnen, Maus auf Abschnittsköpfe und Filter-Überschriften.",
      "Erwartung: Kategorie nicht vom Porträt verdeckt; Titel/Suchen/Abschnitte in Client-Sprache; Sprachen mit Haken, Pflichtsprache grau, Art per Auswahlliste; 'n Gruppen · m Einzelspieler'; Tooltips.",
    } },
  { id = "LT-348", client = "all", triggers = { "instance" },
    title = "Lesbarkeit: Mindestschrift 12 und kurze fr/es-Bezeichnungen",
    steps = {
      "Lauf-Übersicht (/lt runs), eingeklappte Buffs und Edit-Modus ansehen; Einstellungen der Erinnerungen auf Französisch und Spanisch.",
      "Erwartung: keine Schrift kleiner als 12; Erinnerungs-Schalter mit kurzen Bezeichnungen (Details im Tooltip), nichts abgeschnitten.",
    } },
  { id = "LT-349", client = "all", triggers = { "options" },
    title = "Wasserschild-Ladungen auch bei ausgeklappter Buffleiste",
    steps = {
      "Maus auf den Schalter für eingeklappte Buffs; Wasser-/Blitzschlagschild wirken, Buffleiste ein- und ausklappen.",
      "Erwartung: Tooltip sagt, dass die Buffleiste eingeklappt sein muss; eingeklappt zeigt die Anzeige die Ladungen.",
    } },
  { id = "LT-350", client = "all", triggers = { "options" },
    title = "Einstellungen nach Themen ordnen (acht Reiter)",
    steps = {
      "/lt: alle Reiter und Unterseiten klicken (auch fr/es); Rechtsklick auf Hauptfenster, Level-Up, Flugzeit, Würfelkarte, Dungeon-Tracker, Dungeonquest-Hinweis; Suche 'Reparieren'; /reload; /lt setup.",
      "Erwartung: acht Reiter passen ins Fenster, keine leere Seite, Rechtsklick öffnet die passende Unterseite, Suchtreffer nennt Reiter > Seite und springt hin, Schalter nach /reload gleich, Assistent in neuer Reihenfolge.",
    } },
  { id = "LT-351", client = "forever", triggers = { "lfg" },
    title = "Gruppensuche: eigener Seitenreiter an Blizzards Gruppensuche",
    steps = {
      "Blizzards Gruppensuche (I) öffnen, unseren Seitenreiter klicken, /lte check LT351.lfg.sidetab; danach im Kampf Blizzards Gruppensuche öffnen; in unserem Fenster Blizzards Reiter klicken.",
      "Erwartung: Klang und Tooltip am Reiter; Check template/whoTab/tab true, taintedBy leer; kein 'action blocked'; Blizzards Reiter öffnen Blizzards Fenster (im Kampf nur Meldung).",
    } },
  { id = "LT-352", client = "forever", triggers = { "lfg" },
    title = "Gruppensuche: Funktionsparität mit LFG Forever (Filter, Rollenabfrage, Taste)",
    steps = {
      "'Weitere Filter': Rolle, Level, Klassen, Spielstil setzen, /reload, Zurücksetzen; als Leiter Rollenabfrage; Taste unter AddOns belegen; /lte check LT352.lfg.filters.",
      "Erwartung: jeder Filter wirkt und bleibt nach /reload, Freunde/Gilde oben, Rollenabfrage nur als Leiter/Assistent ohne 'action blocked', hängende Suche nach 15 s 'gescheitert'.",
    } },
  { id = "LT-387", client = "forever", triggers = { "anywhere" },
    title = "Dungeon-Guide jederzeit öffnen und Dungeon per Dropdown wählen",
    steps = {
      "Draußen /lt guide, Dungeon-Knopf klicken und anderen wählen; /lt guide Todesminen; Strg+Klick auf den Minimap-Knopf; Knopf 'Guide' im Lauf-Fenster; in einer Instanz /lt guide.",
      "Erwartung: Vorauswahl passt zum Level, Liste nach Level sortiert, Flügel-Dungeons je ein Eintrag, alle Wege öffnen den Guide, zweites /lt guide schließt, in der Instanz diese Instanz.",
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
  { id = "LT-409", client = "all", triggers = { "anywhere" },
    title = "Alte Zauberränge: Upgrade-Knopf, Überfahren markiert den Platz, Klick tauscht einen Platz",
    steps = {
      "Zauber niedrigen Ranges auf mehrere Aktionsleisten-Plätze legen, höheren Rang lernen, Hinweisfenster abwarten; Maus über den Upgrade-Knopf, dann klicken (auch in Forever); /lte check LT409.oldRanks.upgrade.",
      "Erwartung: Überfahren markiert den nächsten Platz auf der Leiste, jeder Klick ersetzt genau einen Platz durch den höchsten Rang, die Zeile verschwindet nach dem letzten; im Kampf passiert nichts.",
    } },
  { id = "LT-410", client = "all", triggers = { "anywhere" },
    title = "Ruhestein-Hinweis beim Betreten eines Gasthauses oder einer Hauptstadt",
    steps = {
      "Ein Gasthaus oder eine Hauptstadt betreten (nicht per /reload darin); /lte check LT410.hearth.bind.",
      "Erwartung: ein Hinweis nennt den Bindeort des Ruhesteins, einmal je Betreten, nicht nach /reload im Gasthaus.",
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
}
