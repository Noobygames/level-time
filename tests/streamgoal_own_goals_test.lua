-- Level Time Goals, Roadmap 431: eigene Ziele (aus dem Formular jeder Art oder als Text), Pool des Glücksrads mit
-- an/aus, Bingo-Schein selbst füllen (leere Felder zufällig), Teilen und Importieren der eigenen Ziele.
local Goals = streamGoal.Goals
local Library = streamGoal.Library
local Pool = streamGoal.Pool
local Wheel = streamGoal.Wheel
local Bingo = streamGoal.Bingo
local Manager = streamGoal.Manager
local WheelView = streamGoal.WheelView
local BingoEditor = streamGoal.BingoEditor
local L = streamGoal.L

wow.login({ level = 10 })

-- Eigenes Ziel aus dem Formular: jede Art, ohne es anzulegen
SlashCmdList.STREAMGOAL("")
Manager.SelectKind("kills")
Manager.FormWidget("amount"):SetText("7")
expectTrue("Knopf Als eigenes Ziel", wow.click(L.SG_FORM_SAVE_OWN))
expect("nichts angelegt", #Goals.Active(), 0)
local own = Library.Entries()[1]
expect("Art gespeichert", own.kind, "kills")
expect("Ziel gespeichert", own.target, 7)
expect("Meldung", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_OWN_SAVED, Pool.Title(own)), 1, true) ~= nil,
  true)
expect("Formular geleert", Manager.FormWidget("amount"):GetText(), "")
expect("gleiches Ziel nur einmal", Library.Add("kills", { source = "any" }, 7), own)
expect("ungültige Eingabe abgelehnt", select(2, Library.Add("level", {}, 5)), string.format(L.SG_ERR_LEVEL, 10))
expect("Bingo kann kein eigenes Ziel sein", select(2, Library.Add("bingo", { size = 3 })), L.SG_ERR_OWN_KIND)
Manager.SelectKind("bingo")
expect("Knopf bei Bingo verborgen", Manager.saveOwnButton:IsShown(), false)

-- Pool: mitgelieferte zuerst, dann eigene; im Rad an/aus per Klick
local items = Pool.Items()
expect("mitgelieferte zuerst", items[1].premade, true)
expect("eigenes zuletzt", items[#items].key, Pool.OwnKey(own.id))
expect("Titel des Texts", Pool.Title(Pool.Get("p:text1")), L.SG_BINGO_TEXT_1)
expect("unbekannter Schlüssel", Pool.Get("o:999"), nil)

Manager.Toggle("wheel")
expect("Seite offen", Manager.ShownPage(), "wheel")
local records = WheelView.table:GetVisibleRecords()
expect("Tabelle zeigt den Pool", #records, #items)
WheelView.OnRowClick(Pool.Get("p:kills10"), "LeftButton")
expect("abgeschaltet", Wheel.IsEnabled("p:kills10"), false)
expect("nicht im Rad", #Wheel.Pool(), #items - 1)
WheelView.OnRowClick(Pool.Get("p:kills10"), "LeftButton")
expect("wieder an", Wheel.IsEnabled("p:kills10"), true)
WheelView.OnRowClick(Pool.Get("p:kills10"), "RightButton")
expect("mitgelieferte lassen sich nicht löschen", wow.popup, nil)

-- Freier Text im Glücksrad-Reiter
WheelView.textBox:SetText("Einen Murloc umarmen")
expectTrue("Text hinzufügen", wow.click(L.SG_OWN_ADD_TEXT))
local hug = Library.Entries()[2]
expect("Text gespeichert", hug.params.text, "Einen Murloc umarmen")
expect("neue eigene Ziele sind im Rad", Wheel.IsEnabled(Pool.OwnKey(hug.id)), true)

-- Teilen und Importieren (Paket-Format)
local text = Library.Export()
expect("Paket-Format", text:sub(1, 9), "LT1:goals")
expect("Unsinn abgelehnt", select(2, Library.Import("quatsch")), L.SG_ERR_IMPORT)
expect("schon vorhanden: nichts neu", Library.Import(text), 0)
local packText = streamGoal.Packs.Export("hardcore")
expect("Paket-Text als eigene Ziele", Library.Import(packText), 3)
expect("fünf eigene Ziele", #Library.Entries(), 5)

-- Löschen per Rechtsklick mit Rückfrage
WheelView.OnRowClick(Pool.Get(Pool.OwnKey(hug.id)), "RightButton")
expect("Rückfrage", wow.popup.name, "STREAMGOAL_REMOVE_OWN")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("gelöscht", Library.Get(hug.id), nil)

-- Bingo selbst füllen: Feld 1 eigenes Ziel, Feld 2 mitgelieferter Text, Feld 3 freier Text, Rest zufällig
Manager.Toggle("bingo")
expect("Entwurf 3x3", BingoEditor.Draft().size, 3)
BingoEditor.Select(1)
BingoEditor.Assign(Pool.OwnKey(own.id))
expect("springt zum nächsten Feld", BingoEditor.Selected(), 2)
BingoEditor.Assign("p:text2")
BingoEditor.textBox:SetText("Tanzen in Ogrimmar")
expectTrue("Text ins Feld", wow.click(L.SG_BINGO_EDIT_TEXT))
local dance = Library.Entries()[#Library.Entries()]
expect("Text als eigenes Ziel", dance.params.text, "Tanzen in Ogrimmar")
expect("im Feld 3", BingoEditor.Draft().picks[3], Pool.OwnKey(dance.id))
expect("Feld zeigt den Text", StreamGoalBingoEditorCell3.text._text, "Tanzen in Ogrimmar")
expect("leeres Feld zufällig", StreamGoalBingoEditorCell5.text._text, L.SG_BINGO_RANDOM)
StreamGoalBingoEditorCell2._scripts.OnMouseUp(StreamGoalBingoEditorCell2, "RightButton")
expect("Rechtsklick leert", BingoEditor.Draft().picks[2], nil)
BingoEditor.Select(2)
BingoEditor.Assign("p:text2")

expectTrue("Schein anlegen", wow.click(L.SG_BINGO_EDIT_CREATE))
local board = Goals.Active()[1]
expect("Schein", board.kind, "bingo")
expect("neun Felder", #board.params.cells, 9)
local cell1 = Goals.Get(board.params.cells[1])
expect("Feld 1 eigenes Ziel", cell1.kind, "kills")
expect("Feld 1 Ziel 7", cell1.target, 7)
expect("Feld 2 Text", Goals.Title(Goals.Get(board.params.cells[2])), L.SG_BINGO_TEXT_2)
expect("Feld 3 freier Text", Goals.Title(Goals.Get(board.params.cells[3])), "Tanzen in Ogrimmar")
expect("gewählte Felder gemerkt", board.params.chosen[1], Pool.OwnKey(own.id))
expect("zufällige Felder nicht", board.params.chosen[4], nil)
expectTrue("übrige Felder belegt", Goals.Get(board.params.cells[9]) ~= nil)
expect("Entwurf geleert", next(BingoEditor.Draft().picks), nil)
Goals.Cancel(board.id)

-- 5x5: Mitte frei, nicht wählbar; gelöschtes eigenes Ziel wird zufällig
BingoEditor.SetSize(5)
BingoEditor.Select(13)
expect("Mitte nicht wählbar", BingoEditor.Selected() ~= 13, true)
BingoEditor.Select(1)
BingoEditor.Assign(Pool.OwnKey(dance.id))
Library.Remove(dance.id)
local big = BingoEditor.CreateBoard()
expect("25 Felder", #big.params.cells, 25)
expect("Mitte frei", big.params.cells[13], Bingo.FREE)
expectTrue("Feld 1 trotzdem belegt", Goals.Get(big.params.cells[1]) ~= nil)
expect("nicht als gewählt gemerkt", big.params.chosen, nil)

-- Ältere Scheine ohne chosen laufen weiter
expect("Fortschritt zählt", Bingo.DoneCount(big), 1)
