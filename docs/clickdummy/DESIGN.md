# Design-Regeln Clickdummy und Addon-UI

Gilt für jeden neuen oder geänderten Screen im Clickdummy (`docs/clickdummy/project/`) und in der Addon-UI.

## Tokens

- Gold `#ffd100`: Titel, Reiter, Spaltenköpfe, Primär. Gold-Hover `#fff1a8`.
- Panel `rgba(8,8,10,0.95)`, auch für Tooltips. Rahmen `#555`, Trenner `#333`.
- Input-Hintergrund `#111`, Button-Hintergrund `#1d1d1d`, Auswahl-Hintergrund `#3a2e0c`.
- Text `#f2f2f2`, sekundär `#c8c8c8`, Notiz `#8a8a8a`, Label `#9fb3a8`.
- Keine neuen Grautöne und Rottöne. Nur die Tokens verwenden.
- Fenster, die ein Blizzard-Fenster ersetzen (z. B. die Gruppensuche), übernehmen Blizzards Look und Vorlagen (Porträtrahmen, rote Knöpfe, Blizzard-Auswahllisten, dessen Atlanten) statt der Addon-Tokens.

## Abstände & Größen

- Abstände nur 4 / 8 / 12 / 16 / 24.
- Fenster-Padding 12 x 16, Kopfhöhe 40.
- Karten-Padding 12 (rundum), Abstand Symbol zu Text 12, Zeilenabstand 4, Balken 8 unter dem Text. Gap in einer Gruppe 8, zwischen Gruppen 16.
- Radius 6 für Fenster und Panels, 4 für Controls.
- Controls 28 (kompakt) oder 32 (Standard). Listenzeile 32. Close-Button 24 x 24.

## Schrift

- Minimum 12, Standard 13.
- Fenstertitel 16 / 700. Hero-Zahl 20 / 700. Größe 26 nur im Level-up-Popup.
- Gewicht 600 nur für Labels und Spaltenköpfe, 700 für Titel.
- Zahlen tabellarisch (tabular), in Tabellen rechtsbündig.
- Mockups nutzen Inter, das Spiel FRIZQT / ARIALN. Textbreiten im Spiel prüfen.

## Fenster

- Klein 340 breit (Anzeigen, Karten). Tooltips maximal 420 breit.
- Mittel 640 x 520. Groß 1000 x 680.
- Maximal ca. 60 % der Bildschirmbreite bei 1080p. Lesbar bei UI-Scale 0.64.
- Maximal 2 Spalten. Eine dritte Spalte wird zum Einblend-Detail.
- Fensterkopf: Titel links in Gold, Aktionen rechts, Close ganz rechts, Trenner `#333`.
- Jedes Fenster ist verschiebbar und mit Esc schließbar.

## Layout

- Liste links (oder oben), Detail rechts (oder unten).
- Filter oben als Chips oder Dropdowns. Seltene Filter in "Weitere Filter (n aktiv)" einklappen.
- Maximal 2 Reiter-Ebenen, bevorzugt eine.
- Ein Primärbutton pro Fenster (goldener Rand), rechts unten.

## Tooltip vs. Detail

- Tooltip: 1 bis 3 Zeilen Zusatz, Begriffserklärung, Randfälle.
- Detailpanel: Vergleichbares, Anklickbares, mehr als 4 Zeilen, Aktionen.
- Erklärtexte nie dauerhaft im Fenster. Stattdessen ein "?"-Tooltip.

## Notizen

- Graue Notizen: `#8a8a8a`, 12 px, maximal eine Zeile, keine Handlungsanweisungen.
- Wichtige Hinweise nie grau.

## Farbe & Status

- Farbe nie allein: Ampel und Rot immer mit Symbol oder Text.
- Farbe nur für Abweichung oder Status. Normwerte neutral.
- Klassenfarbe nur für Spielernamen.
- Status: grün `#40ff40`, rot `#ff5050`, orange `#ff9a3c`, blau `#5fa8ff`.

## Lokalisierung

- Keine festen Textbreiten: `min-width` plus flex, bei Überlauf Ellipsis mit Tooltip.
- Für fr/es +30 % Textlänge einplanen. Buttons wachsen mit dem Text.
- Kein Text in Bildern.
- Labels maximal 2 Wörter.
- Jede Steuerung hat einen Tooltip in allen 4 Sprachen.

## Dichte

- Maximal 6 bis 7 Kernwerte je Ansicht sichtbar. Der Rest ist einklappbar oder im Tooltip.
- Listen: 5 bis 6 Standardspalten, weitere Spalten wählbar.
- Zeilenhöhe 32. Hover und Auswahl sind sichtbar.
- Kommentare einzeilig, ellipsiert.

## Ablauf

- Neue Screens zuerst im Clickdummy mit diesen Tokens, dann im Code.
- Abweichungen im Clickdummy gelten als Fehler.

## Wiederverwendbare Elemente

Vorhanden, nutzen statt neu bauen:

- Fensterrahmen: `Widgets.CreatePanel` / `Theme.ApplyPanel`
- Close: `Widgets.CreateCloseButton`
- Reiter: `Widgets.CreateTab`, `Lib/TabStrip.lua`
- Button: `Widgets.CreateButton`
- Abschnittskopf: `Widgets.CreateSectionHeader`
- Checkbox / Slider: `Widgets.CreateCheckbox` / `Widgets.CreateSlider`, `OptionsBuilder`
- Dropdown: `Lib/Dropdown.lua`
- Tabelle: `Lib/TableView.lua`
- Scroll: `Widgets.CreateScrollArea`
- Karten: `Lib/Card.lua`
- Tooltip: `Widgets.AttachTooltip`, `Lib/QuestTooltip.lua`
- Klassenfarbe: `Theme.ClassColor`
- Balken: `Theme.SetBarTexture`
- Formate: `Format.*`
- Diagramme: `Lib/Charts.lua`
- Rollen: `Lib/GroupRole.lua`

Neu zu extrahieren (noch nicht vorhanden):

- WindowHeader (Titel, Aktionen, Close)
- Primärbutton-Variante
- Chip (an / aus)
- Listenzeile mit Hover und Auswahl
- Label-Wert-Zeile
- Badge / Statuspunkt
- Notiz-Schriftrolle "note"
- Tooltip-Abschnittskopf "Level Time"
- Fortschrittsbalken in 3 Höhen (6 / 12 / 24)

## Icons

- Größen 16 (Zeile, Reiter), 20 (Fensterkopf), 24 (Schrittkopf im Assistenten). Keine Zwischengrößen.
- Client-Symbole zuerst: `Interface\Icons\*` oder Atlas, die in Forever, Era und Retail existieren (Nachweis: Nutzung im Blizzard-UI-Code unter `.cache/wow-ui-source`). Eigene Grafiken nur, wenn der Client nichts Passendes hat.
- Setzen nur über `Widgets.SetIcon(texture, quelle, größe)` / `header:SetIcon(quelle)`. Fehlt ein Atlas im Client, bleibt das Icon weg und das Layout rutscht nach (Fallback ohne Icon).
- Ein Icon steht nie allein: immer neben Text oder mit Tooltip. Keine Farbe als Bedeutungsträger über das Icon.
- Im Clickdummy stehen Emojis als Platzhalter für das Client-Icon (gleiche Größe, Rahmen `#555`).
- Verwendet: Einrichtungsassistent (je Schritt und Kopf), Routen-Checkliste, Dungeonquest-Hinweis, Dungeon Guide, Verlauf, Lauf-Fenster, Rückblick und Hinweisfenster (Fensterkopf). Die Pfade stehen alle schon in `UI/Options/Icons.lua`; neue Symbole dort zuerst im Blizzard-Code nachweisen.
