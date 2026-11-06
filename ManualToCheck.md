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

---

## Instanzen

**Auswertung:** In Ordnung (Forever).

### 9. Kopie wird an Gegnern erkannt (Roadmap 93)

- [ ] geprüft

Im Dungeon zwei verschiedene Gegner anvisieren. Mit `/lt debug` erscheint im Chat eine Zeile zur Kopie.
Die zoneUID eines Ziels von Hand:

```
/run print(select(5, strsplit("-", UnitGUID("target"))))
```

**Erwartet:** bei allen Gegnern derselben Instanz dieselbe Zahl.

**Antwort:**

```text
Client, Dungeon:
zoneUID von 2 Gegnern:
Debug-Zeile:
```

### 10. Reset ergibt neue Kopie (Roadmap 93)

- [ ] geprüft

Dungeon verlassen, als Gruppenleiter bzw. allein zurücksetzen (Rechtsklick auf das eigene Porträt →
Instanzen zurücksetzen), wieder rein, Gegner anvisieren und den Befehl aus Punkt 9 ausführen.

**Erwartet:** andere zoneUID; in Historie → Journal → Instanzen ein neuer Lauf, der alte beendet.

**Antwort:**

```text
zoneUID vorher / nachher:
Neuer Lauf (ja/nein):
```

### 11. Reset als Gruppenmitglied (Roadmap 93, 121)

- [ ] geprüft

In einer Gruppe setzt der Leiter zurück, (a) während du draußen bist, (b) während du noch drin bist.

**Erwartet:** (a) bei dir erscheint evtl. keine Reset-Meldung; beim nächsten Betreten erkennt das Addon die
neue Kopie an den Gegnern. (b) kein Lua-Fehler, dein Lauf läuft weiter.

**Antwort:**

```text
(a) Reset-Meldung bei dir (ja/nein, Text):
(a) Neuer Lauf nach Wiederbetreten (ja/nein):
(b) Fehler / Lauf weiter:
```

### 12. „Noch Spieler drin“ (Roadmap 93)

- [ ] geprüft

Leiter setzt zurück, während ein Mitglied noch drin ist.

**Erwartet:** Meldung „… kann nicht zurückgesetzt werden …“; für alle, die draußen sind, gilt die Instanz
trotzdem als zurückgesetzt (Annahme aus dem Code von Nova Instance Tracker).

**Antwort:**

```text
Meldung:
Beim Wiederbetreten neue zoneUID (ja/nein):
```

### 13. Tod im Dungeon (Roadmap 91)

- [ ] geprüft

Im Dungeon sterben, als Geist zum Friedhof und zurück laufen, an der Leiche wiederbeleben. Ein anderes Mal
beim Geistheiler draußen wiederbeleben.

**Erwartet:** Geisterlauf: derselbe Lauf, Zeile „Instanz“ zählt weiter (Einstellungen → Statistiken →
Instanz-Lauf an). Geistheiler draußen: Uhr bleibt stehen.

**Antwort:**

```text
Geisterlauf, gleicher Lauf (ja/nein):
Geistheiler, Uhr steht (ja/nein):
```

### 14. Händlergang (Roadmap 91)

- [ ] geprüft

Raus, ein paar Minuten draußen, wieder rein in dieselbe Instanz.

**Erwartet:** derselbe Lauf geht weiter; die Zeit draußen zählt nicht.

**Antwort:**

```text
Gleicher Lauf (ja/nein):
Zeit draußen mitgezählt (ja/nein):
```

### 15. Gruppenwechsel (Roadmap 93)

- [ ] geprüft

Innerhalb von 30 Minuten in die Kopie eines anderen Gruppenleiters wechseln (gleicher Dungeon), Gegner
anvisieren.

**Erwartet:** nach zwei Gegnern wird der Lauf geteilt (alter beendet, neuer läuft).

**Antwort:**

```text
Lauf geteilt (ja/nein):
```

### 16. Normal und Heroisch (Roadmap 123, TBC/Retail/Forever)

- [ ] geprüft

Normal betreten, raus, Schwierigkeit auf Heroisch stellen, wieder rein.

```
/dump GetInstanceInfo()
```

**Erwartet:** dritter Wert (difficultyID) unterscheidet sich; neuer Lauf und ein Eintrag mehr bei
„Instanzen/h“.

**Antwort:**

```text
Ausgabe Normal:
Ausgabe Heroisch:
Neuer Lauf (ja/nein):
```

### 17. Lebend raus, Retail/Forever ohne Fehler (Roadmap 93)

- [ ] geprüft

In Retail oder Forever einen Dungeon laufen und dabei Gegner anvisieren.

```
/dump issecretvalue(UnitGUID("target"))
```

**Erwartet:** kein Lua-Fehler; ist der Wert `true`, bleibt es bei der Schätzung.

**Antwort:**

```text
Client:
Ausgabe (im Kampf / außerhalb):
Fehler:
```

---

## Instanzlimit

### 18. Limit in WoW Forever (Roadmap 92)

- [ ] geprüft

Fünf verschiedene Instanzen innerhalb einer Stunde betreten (z.B. Dungeon betreten und zurücksetzen), dann
eine sechste.

**Erwartet:** die sechste wird abgewiesen; das Addon zeigt dabei „Server: zu viele Instanzen. Laut Addon
5/5 …“.

**Antwort:**

```text
Client:
Abgewiesen bei Nr.:
Text der Server-Meldung:
Zeile des Addons erschienen (ja/nein):
```

### 19. Hinweis bei 4/5 und 5/5 (Roadmap 92)

- [ ] geprüft

Einstellungen → Hinweise → Instanzlimit an, dann die vierte und fünfte Instanz betreten.

**Erwartet:** jeweils Einblendung und Chatzeile mit Wartezeit.

**Antwort:**

```text
Hinweis bei 4/5 (ja/nein):
Hinweis bei 5/5 (ja/nein):
```

### 20. Tageslimit (Roadmap 124)

- [ ] geprüft

Nur falls du je abgewiesen wirst, obwohl „Instanzen/h“ weniger als 5 zeigt.

**Antwort:**

```text
Instanzen/h laut Addon:
Instanzen heute laut Addon:
Text der Server-Meldung:
```

---

## Stabilität (v2.8.1)

### 21. Session-XP über einen Level-Up (Roadmap 100)

- [ ] geprüft

Vor einer großen Quest-Belohnung, die über eine Levelgrenze geht, die Session-XP notieren (Zeile
„Erfahrung“ in der Session-Zusammenfassung), Quest abgeben und erneut nachsehen:

```
/lt recap
```

**Erwartet:** Session-XP steigt um die volle Belohnung.

**Antwort:**

```text
Belohnung laut Quest:
Session-XP vorher / nachher:
```

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

### 23. Gildenreparatur (Roadmap 107, TBC/Retail/Forever)

- [ ] geprüft

Komfort → Automatisch reparieren und „zuerst aus der Gildenbank“ an. **Ohne** vorher die Gildenbank zu
öffnen, beschädigt zum Händler.

**Erwartet:** die Gilde zahlt (Chatzeile „aus der Gildenbank“); reicht ihr Limit nicht, zahlt der Rest der
Charakter.

**Antwort:**

```text
Client:
Chatzeilen:
```

### 24. Wiederholbare Quests (Roadmap 108)

- [ ] geprüft

Mit Auto-Annehmen und Auto-Abgeben eine wiederholbare Abgabe-Quest besuchen (z.B. Runenstoff in einer
Hauptstadt).

**Erwartet:** nichts passiert automatisch, alle Gegenstände bleiben.

**Antwort:**

```text
NPC / Quest:
Automatisch abgegeben (ja/nein):
```

### 25. Levelcap der Erweiterung (Roadmap 118, Retail)

- [ ] geprüft

Charakter am Levelcap des Accounts (z.B. Trial oder ältere Erweiterung):

```
/dump UnitLevel("player"), UnitXPMax("player"), GameRulesUtil.IsPlayerAtEffectiveMaxLevel()
```

**Erwartet:** letzter Wert `true`; im Fenster kein XP-Balken, keine XP/h und Prognose.

**Antwort:**

```text
Ausgabe:
XP-Balken / XP/h sichtbar (ja/nein):
```

### 26. Beinahe-Tod nach Wiederbelebung (Roadmap 120, Classic Era/TBC)

- [ ] geprüft

Mit wenig Gesundheit wiederbeleben (Geistheiler, Seelenstein, niedriger Wiederbelebungszauber) und danach
heilen.

**Erwartet:** kein neuer Beinahe-Tod (Zeile „Beinahe-Tode“ bleibt gleich).

**Antwort:**

```text
Beinahe-Tode vorher / nachher:
```

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

### 29. Gespräch mit einer Option (Roadmap 133)

- [ ] geprüft

Komfort → Gespräche überspringen an, einen NPC mit genau einer Option ansprechen (z.B. Flugmeister,
Gastwirt mit nur „Händler“).

**Erwartet:** die Option wird einmal gewählt, kein Fehler.

**Antwort:**

```text
NPC:
Ergebnis:
```

### 30. Zeit ab 100 Tagen (Roadmap 139)

- [ ] geprüft

Nur falls du einen Charakter mit 100+ Tagen auf dem aktuellen Level hast (meist Max-Level).

**Erwartet:** die Zeitanzeige ist vollständig.

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

### 33. Zeitumstellung (Roadmap 95)

- [ ] geprüft

Am Sonntag, 25.10.2026, zwischen 23 und 24 Uhr ausloggen oder `/reload`, bzw. Historie → Graphen →
Spielzeit pro Tag öffnen.

**Erwartet:** kein Hänger.

**Antwort:**

```text
Hänger (ja/nein):
```

### 34. XP/h ohne AFK überall gleich (Roadmap 90)

- [ ] geprüft

Einstellungen → Statistiken → „XP/h ohne AFK-Zeit“ an; ein paar Minuten AFK, dann leveln.

**Erwartet:** Vergleich der Charaktere, Graph „XP/h je Level“ und die Level-Up-Zeile im Chat zeigen dieselbe
Rate wie Fenster und Level-Tabelle.

**Antwort:**

```text
Abweichung (wo, Werte):
```

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

Einstellungen → Komfort → „Chat kopieren“ an, Button „C“ oben rechts im Chatfenster anklicken; ohne
Button:

```
/lt copy
```

**Erwartet:** Kopierfenster mit den Zeilen des Fensters, älteste oben, ohne Farbcodes; Links als
`[Name]`. Der Button verdeckt nichts Wichtiges und erscheint in jedem Chatfenster (auch Reitern wie
„Kampflog“).

**Antwort:**

```text
Client:
Zeilen vollständig (ja/nein):
Button stört (wo):
Fehler:
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

Größe auf 50 % und 200 %, Dauer auf 1 und 10 s, Ton an; „Position verschieben“, an eine andere Stelle
ziehen, Rechtsklick; danach die Größe ändern.

**Erwartet:** Größe und Dauer wirken sofort; Ton beim Level-Up (`/lt debug alert levelUp`); die Position
bleibt nach `/reload`; „Position zurücksetzen“ bringt sie nach oben in die Mitte. Beim Ändern der
Größe darf die Einblendung nicht auffällig wandern (Roadmap 165).

**Antwort:**

```text
Ton gehört (ja/nein):
Position nach /reload gleich (ja/nein):
Wandert beim Skalieren (ja/nein, wohin):
```

### 39. Einblendungen: Warteschlange und Verschiebemodus (Roadmap 155, 163)

- [ ] geprüft

Mehrere Ereignisse kurz hintereinander auslösen (`/lt debug alert rare`, danach `elite`, `loot` schnell
hintereinander). Dann „Position verschieben“ aktivieren und währenddessen eine Warnung auslösen
(z.B. `/lt debug remind`).

**Erwartet:** die Einblendungen erscheinen nacheinander, die laufende zeigt sich dann kürzer; im
Verschiebemodus geht die Warnung nur in den Chat (bekannte Lücke Roadmap 163).

**Antwort:**

```text
Reihenfolge und Kürze (ja/nein):
Warnung im Verschiebemodus verloren (ja/nein):
```

### 40. Instanz-Reiter im Spiel (Roadmap 149, 152, 156, 161, 162)

- [ ] geprüft

Einen Dungeon betreten und den Reiter „Instanz“ wählen. Kämpfen, XP sammeln, sterben. Dann Rechtsklick auf
den Reiter (oder `/lt resetinstance`) und bestätigen. „Instanz-Reiter automatisch“ (Einstellungen →
Allgemein) einschalten, raus- und wieder hineingehen und **in der Instanz** `/reload` ausführen.

**Erwartet:** Zeit und XP des Laufs zählen nur drinnen; nach dem Zurücksetzen beginnen alle Werte bei
null (Kampfzeit darf nicht sofort springen, Roadmap 162); ohne Lauf steht „Kein Lauf“ und „-“. Nach
`/reload` in der Instanz und dem Verlassen darf das Fenster nicht auf „Instanz“ hängen bleiben
(Roadmap 161).

**Antwort:**

```text
Client, Dungeon:
Werte zählen nur drinnen (ja/nein):
Nach Reset sofort Kampfzeit > 0 (ja/nein):
Reiter nach /reload und Verlassen (Level/Session/Instanz):
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

`/lt history`, Reiter „Sessions“ wählen, Fenster schließen und wieder öffnen; auf den Charakternamen klicken,
einen anderen Charakter wählen. Menü offen lassen und irgendwo anders ins Fenster klicken.

**Erwartet:** der Reiter bleibt (auch nach `/reload`); die Liste zeigt alle Charaktere klassenfarbig, ab 12
scrollt sie mit dem Mausrad; ein Klick daneben schließt sie (bekannte Lücke Roadmap 168: schließt bisher nur
über Name, Eintrag, ESC).

**Antwort:**

```text
Reiter gemerkt (ja/nein):
Liste vollständig (ja/nein):
Schließt bei Klick daneben (ja/nein):
```

### 45. Hilfe und Willkommenshinweis (Roadmap 157)

- [ ] geprüft

Hinweis erneut auslösen und Hilfe ansehen:

```
/run LevelTimerStatsDB.introShown = nil
```

```
/reload
```

```
/lt help
```

**Erwartet:** nach `/reload` einmal die Zeile mit Rechtsklick und `/lt help`; danach nie wieder; die Hilfe
steht in fünf Zeilen nach Themen.

**Antwort:**

```text
Willkommenszeile einmalig (ja/nein):
Hilfe in 5 Zeilen (ja/nein):
```

### 46. Erhaltene XP und XP/h ohne AFK (Roadmap 150, 151)

- [ ] geprüft

Einstellungen → Statistiken → „Erhaltene XP“ an. Auf allen drei Reitern Level, Session, Instanz die Zeile
ansehen. „XP/h ohne AFK-Zeit“ an, einige Minuten AFK, dann leveln; Historie → Levels und Vergleich ansehen.

**Erwartet:** die Zeile zeigt die absolut gewonnenen XP je Reiter; Fenster, Level-Tabelle und Vergleich
zeigen für das laufende Level dieselbe XP/h (Roadmap 151).

**Antwort:**

```text
Werte Level / Session / Instanz:
XP/h Fenster / Historie / Vergleich:
```

### 47. Klassifikation mit geheimen Werten (Roadmap 171, Retail/Forever)

- [ ] geprüft

Im Dungeon oder Bosskampf mit Mouseover und Ziel auf Gegner (und Spieler) fahren; BugSack beobachten.

**Erwartet:** kein Fehler aus `Classification.lua`, `InstanceCopy.lua` oder `Zones.lua` („attempt to
compare/perform boolean test on a secret value“); Rare-/Elite-Kills werden weiter erkannt.

**Antwort:**

```text
Client:
Fehlertext, Datei:Zeile:
```

### 48. `UnitXPMax` beim Level-Up (Roadmap 175)

- [ ] geprüft

Vor einem Level-Up einmalig einschalten (gilt bis `/reload`):

```
/run local f=CreateFrame("Frame"); f:RegisterEvent("PLAYER_LEVEL_UP"); f:SetScript("OnEvent", function() print("XPMax beim Level-Up:", UnitXPMax("player")) end)
```

Dann das Level erreichen und mit dem XP-Bedarf des alten Levels (`UnitXPMax` kurz vorher) und der Spalte
„XP“ des Eintrags in Historie → Levels vergleichen.

**Erwartet:** der ausgegebene Wert ist der Bedarf des **alten** Levels (dann stimmt die Annahme in
`History.lua:204`); ist er der des neuen Levels, ist Roadmap 175 ein echter Fehler.

**Antwort:**

```text
Client, Level:
Ausgabe beim Level-Up:
XP-Bedarf vorher:
Eintrag in der Historie:
```

### 49. Death Recap ohne ID (Roadmap 180, Retail/Forever)

- [ ] geprüft

Nach einem Tod (Geist freigelassen, noch in der Nähe):

```
/dump C_DeathRecap.GetRecapEvents()
```

**Erwartet:** eine Tabelle mit Ereignissen (kein Fehler wegen fehlendem Argument); in Historie → Journal →
Tode steht die Ursache. Bei Fehler oder `nil` ist die Ursache in Retail/Forever immer „unbekannt“.

**Antwort:**

```text
Client:
Ausgabe oder Fehler:
Ursache im Journal:
```

### 50. Gespräch überspringen beim Geistheiler (Roadmap 181)

- [ ] geprüft

Komfort → Gespräche überspringen an, als Geist den Geistheiler ansprechen.

**Erwartet:** nichts wird automatisch gewählt („Wiederbeleben“ kostet Wiederbelebungsschwäche bzw.
Haltbarkeit). Tritt es doch auf, ist Roadmap 181 bestätigt.

**Antwort:**

```text
Client:
Automatisch gewählt (ja/nein):
```

### 51. Gildenreparatur und Abhebelimit (Roadmap 179)

- [ ] geprüft

Komfort → Automatisch reparieren und „zuerst aus der Gildenbank“; einmal mit Gildenbank-Limit **unter** den
Reparaturkosten, einmal darüber zu einem Händler.

**Erwartet:** reicht das Limit nicht, zahlt der Charakter den Rest (kein doppeltes Abbuchen); die Chatzeile
nennt, was aus der Gildenbank kam.

**Antwort:**

```text
Client, Limit, Kosten:
Chatzeilen:
Gold vorher / nachher:
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

Einstellungen → Hinweise → Abschnitt „Lagerfeuer“: Countdown und Hinweis an. Zuerst „Vorschau“ mehrfach
anklicken (Hinweis, Countdown, „Lagervorteile aktiv“), „Verschieben“ ausprobieren, Größe ändern. Dann echt:
zu einem Lagerfeuer gehen **ohne** Lagervorteile (Buff „Lagervorteile“ ablaufen lassen oder abbrechen),
stehen, danach hinsetzen und die 60 Sekunden abwarten.

**Erwartet:** beim Dazustellen erscheint der blaue, leicht pulsierende Hinweis „Setz dich hin“; beim Hinsetzen
wechselt er zum Countdown mit Zauber-Symbol, Zahl und Balken, der von 60 s bis 0 läuft (Zahl und Buff-Zeit
gleich, Prüfung mit der Aura-Liste); danach kurz „Lagervorteile aktiv!“ (grün), mit Ton, wenn „Ton bei
Lagervorteilen“ an ist. Wer vorher aufsteht, bekommt keine Erfolgsmeldung. Mit Lagervorteilen und ohne
Hinsetzen erscheint kein Hinweis. Im Kampf und bei Bosskämpfen nichts und kein Fehler.

```
/run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL"); if not a then break end print(i, a.spellId, a.name, a.duration, a.expirationTime, GetTime()) end
```

**Antwort:**

```text
Hinweis erscheint (ja/nein):
Countdown läuft von 60 bis 0 (ja/nein, Abweichung zur Aura-Liste):
Meldung "aktiv" und Ton (ja/nein):
Symbol sichtbar (ja/nein):
Texte in fr/es passen (ja/nein):
Position nach /reload gleich (ja/nein):
Fehler:
```

### 54. Hinweise als Karten (Roadmap 237)

- [ ] geprüft

Einstellungen → Einblendungen → „Vorschau“ so oft anklicken, bis die Karte „Taschen“ erscheint. Dann die
echten Hinweise auslösen: Food-Hinweis (Satt fehlt, Einstellungen → Hinweise → „Hinweis: Satt fehlt“),
Taschen fast voll, Haltbarkeit unter 20 %, als Jäger Munition knapp, geradzahliger Level-Up (Lehrer),
Instanzlimit.

**Erwartet:** jede Meldung als dunkle Karte mit Farbleiste, passendem Symbol (kein grünes Quadrat, kein
Fragezeichen außer bei unbekanntem Zauber), Titel in Gold/Orange und Text darunter; mehrere gleichzeitig
(Satt + Lagervorteile) erscheinen nacheinander; Größe, Dauer und Position folgen den Einstellungen im Reiter
„Einblendungen“; die Chatzeile erscheint weiterhin.

**Antwort:**

```text
Symbole sichtbar (welche fehlen oder sind grün):
Texte in fr/es passen (ja/nein):
Position und Größe wie eingestellt (ja/nein):
Fehler:
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

Einstellungen → Hinweise → Abschnitt „Essen“: Timer an. Etwas essen, das „Satt“ gibt, und sitzen bleiben. Danach
mitten im Essen aufstehen. Einmal als Satt schon aktiv war und noch einmal essen. Vorschau, Verschieben, Größe.

**Erwartet:** Karte „Sitzen bleiben!“ mit Zahl und leerlaufendem Balken (18 s); „Satt aktiv!“ erscheint, sobald
der Buff „Satt“ da ist (wann genau: vor oder nach Ende des Essens?); beim Aufstehen ohne „Satt“ keine Meldung;
Getränke lösen nichts aus; die Karte sitzt unter der Lagerfeuer-Anzeige und lässt sich verschieben.

**Antwort:**

```text
Satt kommt nach wie vielen Sekunden Essen:
Countdown und „Satt aktiv“ wie erwartet (ja/nein):
Fehler:
```

---

### 56. Kill-Quest-Markierung (Roadmap 240)

- [ ] geprüft

Einstellungen → Komfort → „Questziele markieren“ einschalten. Namensplaketten für Gegner und NPCs an
(Esc → Optionen → Namensplaketten). Eine Quest mit Tötungsziel annehmen und in die Nähe der Ziele laufen.
Ziele töten, bis das Ziel erfüllt ist. Größe-Regler verstellen.

**Erwartet:** gelbes Ausrufezeichen direkt links neben dem Lebensbalken der Questmobs, so hoch wie der Balken (nicht bei anderen); verschwindet,
sobald das Ziel erfüllt ist (auch wenn noch Mobs der Sorte stehen); Größe folgt dem Regler; kein Lua-Fehler,
auch im Kampf und in Instanzen; Symbol sitzt sauber links am Balken (Höhe, kein Überlappen); bei anderen Plakettenaddons (Plater o. ä.) Fallback über der Plakette.

**Antwort:**

```text
Symbol sichtbar und passend (ja/nein):
Verschwindet bei erfülltem Ziel (ja/nein):
Fehler:
```

---

### 55. Fenster verschieben (Roadmap 238)

- [ ] geprüft

Einstellungen → Komfort → „Fenster verschieben“ einschalten. Charakterfenster (C), Zauberbuch, Händler, Questgespräch
und Talente öffnen und jeweils an der Titelleiste oder einer freien Stelle mit der linken Maustaste ziehen. Fenster
schließen und wieder öffnen, dann /reload und noch einmal öffnen. Im Kampf ziehen. „Fensterpositionen zurücksetzen“
klicken, /reload.

**Erwartet:** Fenster folgt der Maus und bleibt nach Schließen, Öffnen und /reload an der neuen Stelle (auch Fenster,
die Blizzard beim Öffnen selbst anordnet); im Kampf bewegt sich nichts und es gibt keinen „Aktion blockiert“-Fehler;
nach dem Zurücksetzen und /reload stehen alle Fenster wieder an der Standardstelle; ausgeschaltet lässt sich nichts ziehen.

**Antwort:**

```text
Welche Fenster verschiebbar (und welche nicht):
Position nach Öffnen/Reload gemerkt (ja/nein):
Fehler oder „Aktion blockiert“ (Text):
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

Reiter Einblendungen: Vorschau mehrfach klicken (Level-Up, Rare, Elite, Beute, Beinahe-Tod), danach Position
verschieben. Stil „Text“ zum Vergleich.

**Erwartet:** im Stil „Banner“ jede Einblendung als Karte mit Symbol und Farbleiste wie die Hinweise (Lagerfeuer,
Taschen); Größe, Dauer, Ton und Position wirken weiter; „Text“ zeigt nur die Schrift. Symbole sind keine grünen
Quadrate.

**Antwort:**

```text
Symbole alle sichtbar (ja/nein):
Fehler:
```

### 60. Lagerfeuer-Hinweis nur kurz (Roadmap 245)

- [ ] geprüft

In WoW Forever zu einem Lagerfeuer gehen, ohne sich zu setzen. Weggehen und wiederkommen. Regler „Hinweis wieder nach“
im Reiter Timer ändern.

**Erwartet:** Hinweis steht ca. 8 s und verschwindet; erscheint erst nach der eingestellten Pause wieder, auch wenn
man zwischendurch weggeht. Countdown und „Lagervorteile aktiv“ sind nicht betroffen.

**Antwort:**

```text
Hinweis verschwindet (ja/nein):
Pause wirkt (ja/nein):
Fehler:
```

### 61. Stream Goal (Roadmap 246)

- [ ] geprüft

Beide Addons installiert (`make install`), Client neu gestartet. `/sg` öffnet das Fenster. Ziele anlegen: Level (Formular),
`/sg add kills 5 pve`, `/sg add item 2589 3` (Leinenstoff), `/sg add bgwin 1`. Auf ein Schlachtfeld gehen und gewinnen,
dann Level-Up bzw. Item looten. Im Formular „Item“ ein Item per Shift-Klick in das Feld einfügen.

**Erwartet:** Karten rechts oben mit Titel, „x / y“ und Balken, Position per „Verschieben“ änderbar. Beim Erreichen
Einblendung „Ziel erreicht!“ wie bei Level Time plus Chatzeile; das Ziel erscheint in der Historie. Sieg im
Schlachtfeld zählt genau einmal (auch in Classic Era, Retail, Forever); Niederlage, Unentschieden und Arena zählen nicht.
Shift-Klick fügt den Link ein. Ohne Level Time lädt Stream Goal nicht (Abhängigkeit).

**Antwort:**

```text
Karten und Einblendung (ja/nein):
BG-Sieg zählt einmal (Client):
Shift-Klick-Link (ja/nein):
Reload im fertigen Schlachtfeld zählt doppelt (ja/nein):
Sieger-Wert: `/dump C_PvP.GetActiveMatchWinner and C_PvP.GetActiveMatchWinner(), GetBattlefieldWinner and GetBattlefieldWinner()` am Ende eines Spiels (Retail/Forever: 0/1 = Horde/Allianz, 255 = Unentschieden?):
Fehler:
```

### 62. Level-Up-Zuwachs (Roadmap 247)

- [ ] geprüft

Level-Up ausgelöst (echtes Level oder `/lt debug levelup` für ein Beispiel). Einstellung „Level-Up: Zuwachs anzeigen“ im Reiter Hinweise, Einblendung „Level-Up“ an.

**Erwartet:** Chatzeile mit Leben, Mana, Stärke, Beweglichkeit, Ausdauer, Intelligenz als „vorher → nachher (+Zuwachs)“ und Talentpunkten; die Level-Up-Karte zeigt dieselben Zeilen. Die Werte stimmen mit dem Charakterfenster überein (Werte ohne Buffs). Mit Ausdauer-Buff (z.B. Essen, Segen) steht beim Leben nur „+Zuwachs“, mit Intelligenz-Buff beim Mana.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Zeilen stimmen mit dem Charakterfenster (ja/nein):
Werte nach 1 s schon neu (ja/nein):
Fehler:
```

### 63. Keine Hinweise im Kampf (Roadmap 248)

- [ ] geprüft

Einblendung „Level-Up“ an. Im Kampf (z.B. gegen einen Gegner) das Level erreichen; außerdem im Kampf die Taschen fast voll machen und in die Nähe eines Lagerfeuers laufen (Forever).

**Erwartet:** Im Kampf erscheint nichts. Nach dem Kampf kommt die Level-Up-Karte (mit Zuwachs), danach die Taschenwarnung bzw. der Lagerfeuer-Hinweis.

**Antwort:**

```text
Level-Up kommt nach dem Kampf (ja/nein):
Taschenwarnung nach dem Kampf (ja/nein):
Lagerfeuer-Hinweis nach dem Kampf (ja/nein):
Fehler:
```

### 64. Level-Up-Fenster (Roadmap 249)

- [ ] geprüft

Klassenlehrer einmal besuchen (Liste wird gemerkt). Reiter Einblendungen > Level-Up-Fenster: „Vorschau“, „Verschieben“, Farbschema und „Kompakte Ansicht“ ausprobieren. Dann ein echtes Level-Up (gerades Level, damit der Lehrer neue Fähigkeiten hat).

**Erwartet:** Eigenes Fenster mit Level, Tabelle der Zuwächse, Talentpunkten und Symbolen der neuen Lehrerfähigkeiten (Tooltip mit Name, Rang, Level). Blizzards großes Banner erscheint nicht, solange „Blizzard-Banner ausblenden“ an ist; mit der Einstellung aus kommt es wieder (dazu ggf. /reload). Linksklick schließt das Fenster, unter der Maus bleibt es stehen. Im Kampf erscheint es erst danach. In WoW Forever ist das Banner ein Toast des EventToastManager; er wird mit Blizzards `CloseActiveToasts()` geschlossen, sobald er kurz nach dem Level-Up mit der neuen Stufe im Titel erscheint (kurzes Aufblitzen möglich). Danach prüfen: Controller-Aktionsleiste und Castbar bleiben an ihrem Platz. Ohne besuchten Lehrer steht im Fenster ein grauer Hinweis statt der Fähigkeiten; mit der Maus über dem Fenster erscheint „Linksklick schließt das Fenster“. Im Kampf steht eine Chatzeile, dass das Fenster nach dem Kampf kommt. Die Level-Up-Einblendung (Karte) kommt nicht zusätzlich, solange das Fenster an ist.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Blizzard-Banner weg (ja/nein):
Fähigkeiten stimmen mit dem Lehrer überein (ja/nein/nicht gemerkt):
Tooltip der Fähigkeiten (ja/nein):
Fehler:
```

### 65. Sozial: geteilte Quests, Freundschaftsanfragen, Einladungen (Roadmap 329, Schritt 3a)

- [ ] geprüft

Komfort > Sozial: „Geteilte Quests ablehnen“, „Freundschaftsanfragen blocken“, „Gruppe von Freunden annehmen“ und „Einladen per Flüstern“ an (Stichwort „inv“). Mit einem Fremden und mit einem Freund bzw. Gildenmitglied: Quest teilen lassen, Gruppe einladen lassen, „inv“ flüstern lassen (auch über Battle.net). Eine Battle.net-Freundschaftsanfrage schicken lassen.

**Erwartet:** Geteilte Quest des Fremden wird abgelehnt (Chatzeile), die des Freundes bleibt bzw. wird mit „Geteilte Quests annehmen“ angenommen. Einladung des Freundes wird angenommen, auch wenn „Gruppeneinladungen ablehnen“ an ist; die des Fremden wird dann abgelehnt. Nach „inv“ kommt eine Einladung, bei Battle.net-Freunden an das WoW-Spielkonto. Die Freundschaftsanfrage verschwindet sofort.

```
/dump C_FriendList.IsFriend(UnitGUID("target")), C_GuildInfo.MemberExistsByName(UnitName("target"))
```

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Quest Fremder abgelehnt / Freund angenommen (ja/nein):
Einladung Freund angenommen, Dialog weg (ja/nein):
Einladung per Flüstern / Battle.net (ja/nein):
Freundschaftsanfrage abgelehnt (ja/nein):
Fehler:
```

### 66. Chat: Fenster, letzter Chat nach /reload, Spam-Filter (Roadmap 329, Schritt 3b)

- [ ] geprüft

Komfort > Chat: jeden Schalter einzeln an und wieder aus: Kampflog-Reiter, Chat-Buttons, Eingabezeile oben, Pfeiltasten, nicht ausblenden. Dann „Chat nach /reload behalten“ an, ein paar Zeilen schreiben, `/reload`. Betrunken werden lassen (Mitspieler) und im Kampf Zauber-Links in der Gruppe posten lassen.

**Erwartet:** Kampflog-Reiter verschwindet, die anderen Reiter rücken auf; aus = wieder da. Menü-, Kanal-, Sprach- und Sozial-Buttons und die Knopfleiste sind weg, Mausrad blättert; aus = wieder da (ohne /reload). Eingabezeile erscheint über den Reitern und überdeckt nichts Wichtiges. Pfeiltasten bewegen den Cursor ohne Alt. Text verblasst nicht. Nach /reload stehen die letzten Zeilen wieder im Chat, nach einem echten Login nicht. Betrunken-Meldungen anderer und Zauber-Links im Kampf erscheinen nicht.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Kampflog-Reiter weg und zurück (ja/nein):
Buttons weg und zurück (ja/nein):
Eingabe oben sitzt gut (ja/nein):
Chat nach /reload wieder da (ja/nein):
Spam-Filter (ja/nein):
Fehler:
```

### 67. Oberfläche: Aktionsleisten und Blizzard-Einblendungen ausblenden (Roadmap 329, Schritt 4)

- [ ] geprüft

Komfort > Oberfläche: jeden Schalter einzeln an und wieder aus (ohne /reload): Tastenbelegung, Makronamen, außer Reichweite rot, Boss-Banner, Ereignis-Einblendungen, Meldungen, Haltungsleiste, Ruhe-Animation, Porträtzahlen. Für Reichweite einen Gegner anvisieren und weglaufen, auch mit wenig Mana. Haltungsleiste einmal im Kampf umschalten. Für Meldungen einen Erfolg oder gewonnene Beute abwarten, für die Porträtzahlen kämpfen (auch mit Begleiter), für die Ruhe-Animation in ein Gasthaus gehen.

**Erwartet:** Tasten und Makronamen verschwinden auf allen Leisten und kommen zurück. Symbol wird rot, sobald das Ziel zu weit weg ist, und wieder normal (blau bei wenig Mana) in Reichweite; aus = nie rot. Kein Boss-Banner, keine Toasts in der Mitte (Forever: auch kein Level-Up-Toast), keine Meldungen unten; aus = wieder da. Haltungsleiste verschwindet (im Kampf erst danach) und kommt zurück, ohne Fehlermeldung. „Zzz“ am Porträt weg. Keine Schadenszahlen auf dem Porträt. Schalter, deren Frame der Client nicht hat (Classic: Boss-Banner, Toasts), fehlen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Tasten/Makrotext weg und zurück (ja/nein):
Reichweite rot, wieder normal (ja/nein):
Boss-Banner/Toasts/Meldungen weg (ja/nein):
Haltungsleiste weg, im Kampf erst danach (ja/nein):
Zzz und Porträtzahlen weg (ja/nein):
Fehler (BugSack, "Aktion blockiert"):
```

### 68. Charakterfenster: Haltbarkeit und Lautstärkeregler (Roadmap 329, Schritt 2d und 4)

- [ ] geprüft

Komfort > Fenster: „Haltbarkeit anzeigen“ und „Lautstärkeregler“ an, Charakterfenster (C) öffnen. Ein paar Mal sterben oder kämpfen, beim Händler reparieren. Regler ziehen, Fenster schließen und wieder öffnen. Beide Schalter wieder aus.

**Erwartet:** Links neben der Waffenhand „Haltbarkeit“ und ein Prozentwert (Summe aller Teile), grün ab 60 %, gelb darunter, rot unter 20 %; nach der Reparatur 100 %. Rechts neben den Waffen ein Regler „Lautstärke“ mit dem aktuellen Wert aus den Spieleinstellungen; Ziehen ändert die Gesamtlautstärke sofort. Nichts überlappt Plätze, Modell oder Reiter (auch auf Französisch). Aus = beides weg.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Haltbarkeit sichtbar, Wert stimmt (ja/nein):
Position gut, nichts überlappt (ja/nein):
Lautstärke ändert sich (ja/nein):
Fehler:
```

### 69. Fenster: Klassenfarben bei Ziel und Fokus, Tooltip, Minimap (Roadmap 329, Schritt 4)

- [ ] geprüft

Komfort > Fenster: „Klassenfarben bei Ziel und Fokus“ an, Spieler verschiedener Klassen und NPCs anvisieren und fokussieren (auch in einer Instanz). Tooltip: „Namen in Klassenfarbe“ und „Ziel der Einheit zeigen“ an, über Spieler und kämpfende Gegner fahren; „Im Kampf ausblenden“ an, im Kampf über Gegner fahren, dann mit Umschalt. Minimap (Classic): Mausrad, Zoom-Knöpfe, Kalender-Knopf. Alles wieder aus.

**Erwartet:** Namenshintergrund bei Spielern in Klassenfarbe, bei NPCs wie gewohnt (rot/gelb/grün); aus = sofort wieder Reaktionsfarbe. Tooltip-Name von Spielern in Klassenfarbe, Zeile „Ziel: Name“ (bei dir „Ziel: Du“), Tooltip passt seine Größe an. Im Kampf keine Einheiten-Tooltips, mit Umschalt doch; Tooltips von Knöpfen und Gegenständen bleiben. Classic: Mausrad zoomt die Minimap, Zoom-Knöpfe und Kalender-Knopf weg und nicht klickbar; aus = zurück. Retail/Forever: Mausrad- und Zoom-Knopf-Schalter fehlen (dort schon Standard). Keine Fehler, kein „Aktion blockiert“, auch in Instanzen (Forever: geheime Werte).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Klassenfarbe Ziel/Fokus, aus = zurück (ja/nein):
Tooltip Klassenfarbe und Zielzeile (ja/nein):
Im Kampf versteckt, Umschalt zeigt (ja/nein):
Minimap Mausrad/Knöpfe (ja/nein/fehlt):
Fehler (auch in Instanzen):
```

### 70. System: Bildschirmeffekte, Wetter, Namensplaketten im Kampf, Töne, Addon-Liste, Gruppenfarbe (Roadmap 329, Schritt 5)

- [ ] geprüft

Vorher die Werte ausgeben und in die Antwort schreiben, dann Komfort > System der Reihe nach einschalten und prüfen, danach alles wieder aus und die Werte erneut ausgeben:

```
/lt debug check
```

```
/run for _,n in ipairs({"ffxGlow","ffxDeath","ffxNether","weatherDensity","RAIDweatherDensity","nameplateShowEnemies","Sound_EnableEmoteSounds"}) do print(n, C_CVar.GetCVar(n)) end print("lowLevelRaid", GetAllowLowLevelRaid())
```

„Kein Rausch-Schleier“ (betrunken werden, z.B. Gasthaus-Bier), „Keine Bildschirmeffekte“ (sterben, als Geist laufen), „Wetterdichte festlegen“ mit Regler 0 und 3 (in einem Regengebiet), „Namensplaketten nur im Kampf“ (Kampf beginnen und beenden, auch den Schalter im Kampf umlegen), „Emotes beim Ausruhen stumm“ (im Gasthaus und draußen /lachen), „Zauber-Fehlschlag stumm“ (Zauber durch Bewegung abbrechen), „Stadtglocken stumm“ (zur vollen Stunde in einer Hauptstadt), „Roboschreiter stumm“ (Gnom-Reittier oder NPC), „Schlachtzug-Beschränkung aufheben“ (Charakter unter Level 10 in einer Gruppe, die zum Schlachtzug wird), „Addon-Liste alphabetisch“ (Addon-Liste im Spielmenü), Komfort > Chat „Eine Gruppenfarbe“ (Schlachtzug- und Instanzchat). Einmal `/reload` mit Einstellungen an, dann aus.

**Erwartet:** Jede Einstellung wirkt sofort, kein „Aktion blockiert“ (auch nicht beim Kampfbeginn mit Namensplaketten). Ausgeschaltet stehen alle CVars wieder auf den notierten Werten, auch mit `/reload` dazwischen; `lowLevelRaid` wieder wie vorher. Plaketten nur im Kampf; im Kampf ausgeschaltet kommt der alte Wert nach dem Kampf. Emotes im Gasthaus ohne Ton, draußen mit. Addon-Liste nach Titel sortiert (Farbcodes egal), Addons und Kategorien lassen sich weiter an- und ausschalten. Schlachtzugchat in der Farbe des Gruppenchats, aus = alte Farben (auch nach einem Neustart). Wenn die Farben direkt nach dem Login nicht umspringen: melden (ChatTypeInfo war dann noch leer).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Werte vorher:
Werte nachher (gleich? ja/nein):
Rausch/Geist/Nether/Wetter wirken (ja/nein je):
Plaketten nur im Kampf, kein „Aktion blockiert“ (ja/nein):
Emotes/Fehlschlag/Glocken/Roboschreiter stumm (ja/nein je):
Schlachtzug mit niedrigem Charakter (ja/nein/nicht getestet):
Addon-Liste alphabetisch, Klicks gehen (ja/nein):
Gruppenfarbe, aus = zurück (ja/nein):
Fehler:
```

### 71. Erfassungsquote und Teil-Level (Roadmap 253)

- [ ] geprüft

Einmal mit einem Twink ohne Level Time spielen (Addon in der Addon-Liste aus, ein paar Minuten), dann mit Addon einloggen. Historie öffnen: Reiter Vergleich und Speedrun > Läufe, Spalte „Erfasst“; Reiter Level.

**Erwartet:** Beim Login mit Addon eine Chatzeile „Seit dem letzten Mal wurden ... ohne Level Time gespielt“. Spalte „Erfasst“ grün ab 95 %, gelb ab 90 %, sonst rot; importierte Läufe zeigen „-“. Das laufende Level hat im Reiter Level ein „*“ und zählt nach dem Level-Up nicht in Speedrun > Rekorde. Nach `/reload` keine Chatzeile.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Chatzeile nach Spielen ohne Addon (ja/nein):
Keine Chatzeile nach /reload (ja/nein):
Quote je Charakter plausibel (Wert):
Stern am Level (ja/nein):
Fehler:
```

### 72. Atem-Warnung (Roadmap 255)

- [ ] geprüft

Hinweise > Warnungen „Atem und Erschöpfung knapp“ an, Regler auf 15 s. Tauchen, bis die Atemleiste fast leer ist (Spiel im Fenster lassen und kurz wegklicken, um das Blinken zu sehen). Einmal unter Wasser `/reload`. Optional: in Richtung offenes Meer schwimmen, bis „Erschöpfung“ startet.

**Erwartet:** Bei 15 s Rest eine Karte „Luft holen!“ mit Sekunden, Warnton, Taskleiste blinkt (wo der Client `FlashClientIcon` hat). Nur einmal je Abtauchen, nach dem Auftauchen wieder. Nach `/reload` unter Wasser kommt die Warnung trotzdem. Erschöpfung: Karte „Erschöpfung!“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Karte bei der Schwelle, Sekunden stimmen (ja/nein):
Ton und Blinken (ja/nein):
Nach /reload unter Wasser (ja/nein):
Erschöpfung (ja/nein/nicht getestet):
In Instanzen (z.B. Unterwasser-Dungeon) geheim? (ja/nein/nicht getestet):
Fehler:
```

### 73. Quest-Automatik: Sperrliste (Roadmap 260, 181, 182)

- [ ] geprüft

Komfort > Automatik: Quests annehmen und abgeben an. Mit 60 Leinen-/Wollstoff zum Stoff-Quartiermeister einer Hauptstadt (z.B. Ralston Farnsley in Unterstadt). Danach im Feld „Nie automatisch“ den Namen eines normalen Questgebers eintragen (Enter) und ihn ansprechen. In Retail/Forever eine wiederholbare Quest von Hand öffnen.

**Erwartet:** Beim Quartiermeister öffnet, nimmt und gibt die Automatik nichts. Der eingetragene Questgeber bleibt ebenfalls manuell. Wiederholbare Quests (Retail/Forever) werden nicht automatisch abgegeben. Flugmeister-Gespräch wird weiter übersprungen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Quartiermeister manuell (ja/nein, Name):
Eigener Eintrag wirkt (ja/nein):
Wiederholbare Quest manuell (ja/nein/nicht getestet):
Flugmeister weiter übersprungen (ja/nein):
Fehler:
```

### 74. Pausen-Erinnerung (Roadmap 263)

- [ ] geprüft

Hinweise > Erinnerungen „Pausen-Erinnerung“ an, „Pause nach“ auf 15 Minuten. 15 Minuten spielen (einmal mit /reload dazwischen), einmal davon im Kampf über die Grenze kommen. Danach 5 Minuten AFK gehen (`/afk`).

**Erwartet:** Nach 15 Minuten (ohne AFK-Zeit) Karte „Kurze Pause?“ mit der Spielzeit, auch nach /reload richtig gezählt. Im Kampf oder in einer Instanz erst danach. Nach 5 Minuten AFK beginnt die Zählung neu.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Karte nach der eingestellten Zeit (ja/nein):
Zählung nach /reload weiter (ja/nein):
Wartet im Kampf/in Instanzen (ja/nein):
AFK setzt zurück (ja/nein):
Fehler:
```

### 75. Questfortschritt an die Gruppe (Roadmap 264)

- [ ] geprüft

Hinweise > Warnungen „Questfortschritt an die Gruppe“ an. In einer Gruppe eine Quest annehmen, ein Ziel fertig machen (Kills und Gegenstände), bis die Quest fertig ist. Einmal `/reload` mit einem halb erfüllten Ziel. In Classic eine Überschrift im Questlog einklappen und weitermachen.

**Erwartet:** Im Gruppenchat „Level Time: Quest angenommen: ...“, je Ziel einmal „Titel: Wolf getötet: 8/8“ (Text des Clients), dann „Quest fertig: ...“. Nach `/reload` keine Wiederholung. Allein nichts.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Angenommen/Ziel/Fertig im Gruppenchat (ja/nein je):
Keine Wiederholung nach /reload (ja/nein):
Eingeklappte Überschrift (Classic): Meldung trotzdem (ja/nein/nicht getestet):
Im Dungeon/Bosskampf (gesperrt?) (ja/nein/nicht getestet):
Fehler:
```

### 76. Einladungen mit Infos (Roadmap 265)

- [ ] geprüft

Komfort > Sozial > Einladungen „Einladungen mit Infos“ an. Von einem Fremden, einem Freund und einem Gildenmitglied einladen lassen, einmal mit dem Einladenden als Ziel.

**Erwartet:** Chatzeile „Gruppeneinladung von <Name in Klassenfarbe>: Orc Krieger“, als Ziel mit „Level N“ davor, bei Freund/Gilde „(Freund oder Gilde)“ dahinter. Das Einladungsfenster funktioniert wie immer (Annehmen/Ablehnen, kein „Aktion blockiert“).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Rasse und Klasse stimmen (ja/nein):
Level als Ziel (ja/nein):
Freund/Gilde markiert (ja/nein):
Popup unverändert, keine Fehler (ja/nein):
Fehler:
```

### 77. Quest-Level in Questlog, Gesprächen und Tracker (Roadmap 259)

- [ ] geprüft

Komfort > Oberfläche > Quests „Quest-Level anzeigen“ an. Questlog öffnen und blättern, einen NPC mit mehreren Quests ansprechen (Gesprächsliste), einen NPC mit der alten Quest-Grußliste (z.B. Anschlagbrett oder NPC ohne Gesprächsoptionen), eine Gruppenquest im Log, in Classic eine Quest beobachten (Tracker). Danach ausschalten und das Questlog neu öffnen.

**Erwartet:** „[12] Titel“ vor jeder Quest, Gruppenquests „[12+]“, Überschriften im Questlog ohne Level. Kein „Aktion blockiert“, keine Lua-Fehler (auch nicht beim Öffnen der Weltkarte in Retail/Forever). Ausgeschaltet verschwindet das Level beim nächsten Öffnen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Questlog (ja/nein):
Gesprächsliste (ja/nein):
Grußliste (ja/nein/nicht getestet):
Tracker (Classic) (ja/nein/nicht getestet):
„+“ bei Gruppenquest (ja/nein):
Lange Titel umbrechen/überlappen (ja/nein):
Fehler:
```

### 78. Verschobene Fenster skalieren (Roadmap 266)

- [ ] geprüft

Komfort > Oberfläche > Fenster „Fenster verschieben“ an. Charakterfenster, Zauberbuch und Händler öffnen, mit gehaltener Strg-Taste das Mausrad über dem Fenster drehen, dann Strg+Rechtsklick. Fenster schließen und neu öffnen, einmal `/reload`. In einem Fenster mit Liste (Questlog, Händler) ohne Strg scrollen. Im Kampf versuchen.

**Erwartet:** Strg+Mausrad macht das Fenster größer/kleiner (50–200 %), Strg+Rechtsklick wieder 100 %. Größe bleibt nach Schließen und /reload. Listen scrollen ohne Strg wie immer. Kein „Aktion blockiert“ im Kampf. „Fensterpositionen zurücksetzen“ setzt die Größe sofort zurück.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Skalieren und Zurücksetzen (ja/nein):
Gemerkt nach /reload (ja/nein):
Listen scrollen weiter (ja/nein):
Im Kampf keine Fehler (ja/nein):
Fehler:
```

### 79. Notfall bei wenig Leben (Roadmap 267)

- [ ] geprüft

Nur Classic Era/TBC. Hinweise > Warnungen „Notfall bei wenig Leben“ an. Einen Heiltrank, einen Gesundheitsstein und einen Notfallzauber der Klasse (z.B. Gottesschild, Entrinnen, Totstellen) auf die Leisten legen, dazu ein Makro mit Heiltrank. Im Kampf unter 10 % Leben fallen (z.B. Fallschaden, starke Gegner), dann heilen. Danach `/lt debug log` an, `/lt debug check`, `make debuglog` und den Eintrag `emergency.actions` ansehen.

**Erwartet:** Unter 10 % grüner Rahmen um Trank, Stein und Notfallzauber (nicht um das Makro), roter Rand am Bildschirm. Ab 15 % ist alles weg. Kein „Aktion blockiert“, auch nicht im Kampf. In `emergency.actions` haben alle Items und Zauber des Clients einen Namen.

**Antwort:**

```text
Client (Era/TBC):
Knöpfe markiert (ja/nein, welche nicht):
Roter Rand (ja/nein, zu stark/zu schwach):
Aus ab 15 % (ja/nein):
Fehler im Kampf (ja/nein):
IDs ohne Namen in emergency.actions:
Fehler:
```

### 80. Quest-Item-Knopf und Zielknopf (Roadmap 268)

- [ ] geprüft

Komfort > Oberfläche > Quests „Quest-Item-Knopf“ und „Questgegner-Zielknopf“ an, Namensplaketten an. Eine Quest mit benutzbarem Item annehmen (z.B. Item auf einen Gegner oder Ort benutzen), zweite solche Quest dazu. Knopf anklicken (mit und ohne Ziel), in den Kampf gehen und eine Quest abschließen, danach den Kampf verlassen. „Knöpfe verschieben“, ziehen, Rechtsklick, `/reload`. Nahe Questgegner auf den Plaketten: Zielknopf klicken.

**Erwartet:** Knopf mit dem Symbol des Quest-Items (Anzahl unten rechts), Klick benutzt das Item. Mit zwei Quests in Retail/Forever das Item der näheren Quest, in Classic das der zuletzt angenommenen. Im Kampf ändert sich nichts, kein „Aktion blockiert“; nach dem Kampf wechselt der Knopf. Zielknopf wählt einen Questgegner als Ziel. Position bleibt nach /reload.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Item erkannt und benutzt (ja/nein):
Nächste/letzte Quest richtig (ja/nein):
Im Kampf keine Fehler (ja/nein):
Zielknopf wählt Questgegner (ja/nein/nicht vorhanden):
Verschieben gemerkt (ja/nein):
Fehler:
```

### 81. Koordinaten auf der Weltkarte (Roadmap 269)

- [ ] geprüft

Komfort > Fenster > Weltkarte „Koordinaten auf der Karte“ an. Weltkarte öffnen, Maus über die Karte und daneben bewegen, auf eine andere Zone und den Kontinent wechseln, in einer Instanz öffnen. In Retail/Forever danach eine Quest über die Karte verfolgen und im Kampf die Karte öffnen.

**Erwartet:** Unten auf der Karte „Spieler: 45.2, 63.1   Maus: 12.3, 40.0“; die Mauswerte ändern sich mit der Maus, neben der Karte „–“. Auf einer fremden Zone Spieler „–“. In Instanzen Spieler „–“. Keine Lua-Fehler, kein „Aktion blockiert“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Spieler-Koordinaten stimmen (ja/nein):
Maus-Koordinaten (ja/nein):
Text gut lesbar/Lage ok (ja/nein):
Fehler/Taint (ja/nein):
Fehler:
```

### 82. Quest-XP im Questlog (Roadmap 270)

- [ ] geprüft

Statistiken > Erfahrung „Quest-XP im Questlog“ an, Allgemein > Fenster „Quest-XP auf dem XP-Balken“ an. Mehrere Quests annehmen, eine davon fertig machen (nicht abgeben), eine Überschrift im Questlog einklappen. Danach `/dump GetQuestLogRewardXP(<questID>)` für eine Quest aus dem Log.

**Erwartet:** „Quest-XP fertig“ = Summe der fertigen Quests, „Quest-XP offen“ = Rest; „Abgabe für Level-Up“ zeigt „Ja (+…)“ grün, sobald die fertigen Quests reichen. Auf dem XP-Balken ein gelbes Stück hinter dem Fortschritt. Nach dem Abgeben sinkt die Summe. In Era/TBC: unter eingeklappten Überschriften fehlen Quests (bekannt).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
/dump GetQuestLogRewardXP(questID) liefert XP (ja/nein, Wert):
Summen fertig/offen stimmen (ja/nein):
Level-Up-Zeile richtig (ja/nein):
Gelbes Stück auf dem Balken (ja/nein):
Fehler:
```

### 83. Ruhe-XP der Twinks (Roadmap 271)

- [ ] geprüft

Einen Twink (levelnd) im Gasthaus ausloggen, `/dump GetXPExhaustion(), UnitXPMax("player")` vorher notieren. Mit einem anderen Charakter einloggen, Historie > Vergleich öffnen. Nach einigen Stunden (oder einem Tag) erneut ansehen und den Twink einloggen, wieder `/dump GetXPExhaustion()`.

**Erwartet:** Spalte „Erholt“ zeigt den geschätzten Pool in Prozent des Balkens (+5 % je 8 h im Gasthaus, draußen ein Viertel), höchstens „150% voll“. Beim Login eines anderen Charakters einmal „X ist voll ausgeruht.“, sobald 150 % erreicht sind. Die Schätzung liegt nahe am echten Wert nach dem Einloggen.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Pool beim Logout / Schätzung / echter Wert nach Login:
Stunden offline, Gasthaus ja/nein:
Meldung "voll ausgeruht" (ja/nein/nicht erreicht):
Fehler:
```

### 84. Kills bis Level-Up mit Erholung (Roadmap 273)

- [ ] geprüft

Statistiken „Kills bis Level-Up“ an, Berechnung „Schnitt über“ auf „letzte 20“. Erholt (blauer Balken) einige Gegner töten, `/lt debug` an und die Chatzeile eines Kills im Erholungsbonus ansehen. Danach Regler ganz nach links („ganzes Level“).

**Erwartet:** Die Zahl passt zu „fehlende XP ÷ XP je Kill ohne Bonus“, im Erholungsbonus etwa halb so viele Kills. Im Journal (Historie > Kills) keine Fehler. Debug-Zeile `stats xpKills +…` mit der vollen XP.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Kill-Meldung im Erholungsbonus (Text kopieren):
Zahl plausibel mit/ohne Erholung (ja/nein):
Fehler:
```

### 85. XP aus Entdecken, Sammeln und nach Ort (Roadmap 275)

- [ ] geprüft

Statistiken „XP-Quellen“ und „XP nach Ort“ an, `/lt debug` an. Ein neues Gebiet entdecken (gelbe Meldung „… entdeckt: N Erfahrung erhalten.“). In Retail/Forever ein Kraut oder Erz sammeln, das XP gibt. Einen Dungeon betreten und dort XP bekommen. Danach Historie > Level > „XP-Quellen“.

**Erwartet:** Debug-Zeilen `xp exploration XP N (Gebiet)` und `xp gathering XP N`; „XP aus Entdecken“/„XP aus Sammeln“ steigen, „XP sonstige“ nicht. „XP in Dungeons“ steigt nur in der Instanz. Die Unteransicht zeigt die Anteile je Level.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Entdecken erkannt (ja/nein; sonst: in welchem Chatfenster/Ereignis kam die Meldung):
Sammeln erkannt (ja/nein/keine Sammel-XP im Client):
XP nach Ort stimmt (ja/nein):
Fehler:
```

### 86. Session-Vergleich beim Login (Roadmap 281)

- [ ] geprüft

Hinweise > Level-Up „Letzte Session beim Login“ an (Standard). Eine Session spielen (einige Minuten mit XP), ausloggen, mehr als 5 Minuten warten, wieder einloggen. Danach `/reload`.

**Erwartet:** Beim Login „Letzte Session: 25m 10s, 3.2k XP (+12% XP/h zur vorherigen)“; der Vergleich fehlt, wenn es keine Session davor mit XP gab. Nach `/reload` keine Zeile.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Zeile beim Login (Text kopieren):
Werte passen zur Historie > Sessions (ja/nein):
Keine Zeile nach /reload (ja/nein):
Fehler:
```

### 87. Leerlauf ohne AFK-Flag (Roadmap 283)

- [ ] geprüft

Statistiken „Zeitaufteilung“ an, Berechnung „Leerlauf ohne XP nach“ auf 2 min. XP holen, dann 5 Minuten stehen bleiben ohne AFK zu werden (Maus bewegen, nicht kämpfen). Danach einen Gegner töten. Zum Vergleich einmal mit Kampf ohne Kill über 2 Minuten.

**Erwartet:** „Leerlauf“ in der Zeitaufteilung steigt erst nach 2 min ohne XP, etwa 3 min für den Test; der Kill beendet ihn. Kampf zählt nicht als Leerlauf. XP/h steigt etwas, die Spielzeit bleibt gleich. Historie > Level > Zeitaufteilung hat die Spalte „Leerlauf“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Leerlauf beginnt nach der Grenze (ja/nein):
Kill/Kampf beendet ihn (ja/nein):
XP/h ohne Leerlauf plausibel (ja/nein):
Fehler:
```

### 88. Persönliche Rekorde (Roadmap 272)

- [ ] geprüft

Hinweise > Persönliche Rekorde „Neue Rekorde melden“ an. Einige Minuten leveln (Kills, eine Quest mit viel XP), danach Historie > Level > „Persönliche Rekorde“ öffnen. Eine zweite, größere Quest abgeben. Einen Dungeon über 5 Minuten laufen und verlassen. Ein Level schneller schaffen als jeder andere Charakter.

**Erwartet:** Beim ersten Wert jeder Art keine Meldung, danach Karte „Persönlicher Rekord!“ mit „Größter XP-Gewinn: 1.2k (vorher 800)“ und Chatzeile. „Meiste XP in 60 Minuten“ und „Beste Session-XP/h“ höchstens einmal je Session. Die Tabelle zeigt Wert, Charakter, Level und Datum.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Meldungen kamen (welche):
Tabelle stimmt (ja/nein):
Zu viele Meldungen (ja/nein):
Fehler:
```

### 89. Kills bis Level im Tooltip (Roadmap 274)

- [ ] geprüft

Komfort > Fenster > Tooltip „Kills bis Level-Up zeigen“ an. Mit der Maus über einen Gegner fahren, den du noch nicht getötet hast, dann einen davon töten und wieder darüberfahren. Auch einen grauen, einen Elite- und einen deutlich höheren Gegner prüfen, einmal mit Erholung.

**Erwartet:** Ungetötete Gegner zeigen „Kills bis Level-Up: ~N“ (Classic-Clients; Retail ohne Zeile), nach dem ersten Kill ohne „~“ und mit dem Wert aus der echten XP. Farbe wie die Stufenfarbe des Gegners. Graue Gegner, Spieler und freundliche NPCs haben keine Zeile. Mit Erholung ist die Zahl kleiner. Im Kampf in Instanzen (geheime Werte) keine Fehler.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Schätzung vor dem ersten Kill (Zahl, echte Kills bis Level-Up):
Gelernter Wert nach dem Kill stimmt (ja/nein):
Farbe passt (ja/nein):
Fehler:
```

### 90. Einnahmen nach Art und Zeitraum (Roadmap 276)

- [ ] geprüft

Statistiken „Einnahmen nach Art“ an. Gold looten (allein und in einer Gruppe, geteilte Beute), eine Quest mit Gold abgeben, etwas beim Händler verkaufen, Gold aus der Post nehmen (auch einen Auktionserlös), einen Handel mit Gold abschließen. Danach Historie > „Geld“ öffnen.

**Erwartet:** Jede Einnahme landet in ihrer Zeile (Auktionserlöse unter Post), nichts doppelt; die Summe stimmt mit „Gold“ überein. Gold/h erscheint nach einer Minute. In „Geld“ stehen Heute, Diese Woche, Dieser Monat und Gesamt mit Ein, Aus, Saldo und Gold/h, unten „Gold aller Charaktere“ (Twinks nach ihrem nächsten Login).

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Falsch eingeordnete Einnahmen (welche, wo gelandet):
Geteilte Beute als Beute (ja/nein):
Tabelle Geld stimmt (ja/nein):
Fehler:
```

### 91. Wann ich spiele (Roadmap 277)

- [ ] geprüft

Eine Weile spielen (auch über einen Stundenwechsel), kurz AFK gehen. Historie > Graphen > „Wann“ öffnen und mit der Maus über die Kacheln fahren.

**Erwartet:** 7 Zeilen (Mo bis So) × 24 Stunden, die heutige Stunde ist hell, Tooltip „Mi 13-14 Uhr“ mit aktiver Zeit (ohne AFK) und XP. Stundenbeschriftung alle 3 Stunden, nichts überlappt. Ein neuer Charakter zeigt „keine Daten“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Heatmap sichtbar und lesbar (ja/nein):
Zeit/XP im Tooltip plausibel (ja/nein):
Fehler:
```

### 92. Ruf pro Stunde (Roadmap 278)

- [ ] geprüft

Statistiken „Ruf“ an. Quests mit Ruf abgeben und Gegner töten, die Ruf geben (auch in einem Dungeon). Historie > „Ruf“, „Zonen“ und „Instanzen“ ansehen.

**Erwartet:** „Ruf“ und „Ruf/h“ steigen im Level, in der Session und im Instanz-Tab. Die Tabelle „Ruf“ zeigt jede Fraktion mit ihrer Summe; Zonen und Instanzen haben die Spalte „Ruf“. Ruf-Verluste zählen nicht.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Ruf wird erkannt (ja/nein, Beispielmeldung aus dem Chat):
Werte stimmen (ja/nein):
Fehler:
```

### 93. Fortschrittskurve (Roadmap 279)

- [ ] geprüft

Mit einem Charakter einloggen, der einige Level mit dem Addon geschafft hat, und mindestens einen Twink mit Leveln haben. Historie > Graphen > „Kurve“ öffnen, über die Punkte fahren, dann oben einen anderen Charakter wählen.

**Erwartet:** Linien je Charakter in Klassenfarbe (gewählter zuerst in der Legende), dazu „Vergleich (Splits)“ schwächer und dünner. Y-Achse Level, X-Achse Spielzeit. Tooltip „Name: 23.4 - 1d 2h“. Der letzte Punkt des eingeloggten Charakters wandert mit der XP. Mit einem anderen gewählten Charakter fehlt der Vergleich.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Linien sichtbar (ja/nein):
Achsen und Legende lesbar (ja/nein):
Werte plausibel (ja/nein):
Fehler:
```

### 94. Todeskarte und letzte Worte (Roadmap 280)

- [ ] geprüft

Komfort > Fenster > Weltkarte „Tode auf der Karte“ an. Etwas in /s oder die Gruppe schreiben, draußen sterben (z.B. Fallschaden), einmal auch in einem Dungeon. Weltkarte öffnen, hinein- und herauszoomen, eine andere Zone anzeigen. Historie > Journal > Tode ansehen.

**Erwartet:** Roter Punkt an der Todesstelle, der beim Zoomen an der Stelle bleibt; Tooltip mit Ursache, Level, Zeit und „Letzte Worte: …“. Auf anderen Karten keine Punkte, Dungeon-Tode ohne Punkt. Die Tabelle zeigt „Ort“ (Koordinaten) und „Letzte Worte“.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Punkt an der richtigen Stelle (ja/nein):
Zoomen/Kartenwechsel richtig (ja/nein):
Letzte Worte stimmen (ja/nein):
Fehler:
```

### 95. Instanz-Bericht an die Gruppe und Tageslimit (Roadmap 282)

- [ ] geprüft

Hinweise > Warnungen „Instanz-Bericht an die Gruppe“ an. In einer Gruppe einen Dungeon einige Minuten laufen (Kills, Gold looten) und hinausgehen, wieder hinein und gleich wieder hinaus. Einmal als Geist hinauslaufen. Statistiken „Instanzen heute“ ansehen (Classic-Clients).

**Erwartet:** Beim Verlassen eine Gruppenchat-Zeile „Level Time: Name: Dauer, XP, Kills (XP/Kill), Gold“, beim sofortigen zweiten Verlassen keine, als Geist keine. Allein nichts. „Instanzen heute“ zeigt in Classic „N (M/30 in 24 h)“. Bitte notieren, ob der Server ein Tageslimit (30) und welches Stundenlimit (5 oder 10) er durchsetzt.

**Antwort:**

```text
Client (Retail/Era/TBC/Forever):
Bericht kam und stimmt (ja/nein):
Kein doppelter Bericht (ja/nein):
Stundenlimit laut Server (5/10):
Tageslimit laut Server (30/keins):
Fehler:
```
