-- Level Time Goals, Roadmap 431 und 433: eigene Ziele (aus dem Formular jeder Art oder als Text in der Sammlung),
-- Einträge des Glücksrads an/aus, Bingo-Schein selbst füllen (leere Felder zufällig), Teilen und ein Import für
-- Pakete und eigene Ziele.
local Goals = streamGoal.Goals
local Library = streamGoal.Library
local Pool = streamGoal.Pool
local Wheel = streamGoal.Wheel
local Bingo = streamGoal.Bingo
local Manager = streamGoal.Manager
local WheelView = streamGoal.WheelView
local BingoEditor = streamGoal.BingoEditor
local CollectionView = streamGoal.CollectionView
local Sharing = streamGoal.Sharing
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
expect("Bingo nicht im Formular wählbar", Manager.SelectedKind(), "kills")

-- Pool: mitgelieferte zuerst, dann eigene; im Rad an/aus per Klick
local items = Pool.Items()
expect("mitgelieferte zuerst", items[1].premade, true)
expect("eigenes zuletzt", items[#items].key, Pool.OwnKey(own.id))
expect("Titel des Texts", Pool.Title(Pool.Get("p:text1")), L.SG_BINGO_TEXT_1)
expect("unbekannter Schlüssel", Pool.Get("o:999"), nil)
expect("Herkunft mitgeliefert", Pool.SourceText(items[1]), L.SG_POOL_PREMADE)
expect("Herkunft eigenes Ziel", Pool.SourceText(items[#items]), L.SG_POOL_OWN)
expectTrue("eigenes Ziel heißt anders als die Zielart Freitext", L.SG_POOL_OWN ~= L.SG_KIND_CUSTOM)

Manager.Toggle("wheel")
expect("Seite offen", Manager.ShownPage(), "wheel")
local records = WheelView.table:GetVisibleRecords()
expect("Tabelle zeigt den Pool", #records, #items)
WheelView.OnRowClick(Pool.Get("p:kills10"))
expect("abgeschaltet", Wheel.IsEnabled("p:kills10"), false)
expect("nicht im Rad", #Wheel.Pool(), #items - 1)
WheelView.OnRowClick(Pool.Get("p:kills10"))
expect("wieder an", Wheel.IsEnabled("p:kills10"), true)
expectTrue("Alle aus", wow.click(L.SG_WHEEL_ALL_OFF))
expect("alle aus", #Wheel.Pool(), 0)
expectTrue("Alle an", wow.click(L.SG_WHEEL_ALL_ON))
expect("alle an", #Wheel.Pool(), #items)

-- Einstellungen des Rads direkt auf der Seite (dieselben wie im Einstellungsfenster)
local levelUpCheck = WheelView.checks[1]
levelUpCheck:SetChecked(true)
levelUpCheck._scripts.OnClick(levelUpCheck)
expect("Level-Up-Drehen an", StreamGoalDB.settings.wheelOnLevelUp, true)
levelUpCheck:SetChecked(false)
levelUpCheck._scripts.OnClick(levelUpCheck)
expect("Level-Up-Drehen aus", StreamGoalDB.settings.wheelOnLevelUp, false)

-- Freier Text in der Sammlung
Manager.Toggle("collection")
CollectionView.SelectSection("own")
expect("Teilen bei eigenen Zielen", CollectionView.shareOwnButton:IsShown(), true)
CollectionView.textBox:SetText("Einen Murloc umarmen")
expectTrue("Text hinzufügen", wow.click(L.SG_OWN_ADD_TEXT))
local hug = Library.Entries()[2]
expect("Text gespeichert", hug.params.text, "Einen Murloc umarmen")
expect("neue eigene Ziele sind im Rad", Wheel.IsEnabled(Pool.OwnKey(hug.id)), true)
expect("Tabelle der Sammlung", #CollectionView.ownTable:GetVisibleRecords(), 2)

-- Teilen und ein Import für beides: eigene Ziele tragen eine Kennung, Pakete nicht
local text = Library.Export()
expect("Paket-Format", text:sub(1, 9), "LT1:goals")
expect("Kennung eigene Ziele", select(3, streamGoal.Packs.Decode(text, Library.MAX_ENTRIES)), true)
expect("Unsinn abgelehnt", select(2, Library.Import("quatsch")), L.SG_ERR_IMPORT)
expect("Unsinn im gemeinsamen Import", select(2, Sharing.Import("quatsch")), false)
expect("schon vorhanden: nichts neu", Sharing.Import(text), string.format(L.SG_CHAT_OWN_IMPORTED, 0))
local packText = streamGoal.Packs.Export("hardcore")
expect("Paket-Text bleibt ein Paket", Sharing.Import(packText),
  string.format(L.SG_CHAT_PACK_IMPORTED, L.SG_PACK_HARDCORE))
expectTrue("als Paket gespeichert", StreamGoalDB.packs[L.SG_PACK_HARDCORE] ~= nil)
expect("Paket-Text als eigene Ziele (Bibliothek direkt)", Library.Import(packText), 3)
expect("fünf eigene Ziele", #Library.Entries(), 5)
-- Älterer Text von Vorlagen ohne Kennung: am früheren Namen erkannt (Vorlagen hießen bis v2.26 "Own goals")
local legacy = streamGoal.Packs.Encode("Own goals", { { kind = "custom", params = { text = "Alter Text" } } })
expect("alter Text eigener Ziele", Sharing.Import(legacy), string.format(L.SG_CHAT_OWN_IMPORTED, 1))
expect("sechs Vorlagen", #Library.Entries(), 6)
-- Ein Paket, das wie die Vorlagen heißt, bleibt ein Paket (neue Vorlagen-Texte tragen immer die Kennung)
local namedPack = streamGoal.Packs.Encode(L.SG_OWN_GOALS, { { kind = "custom", params = { text = "Paket-Text" } } })
expect("Paket namens Vorlagen", Sharing.Import(namedPack), string.format(L.SG_CHAT_PACK_IMPORTED, L.SG_OWN_GOALS))
expect("weiter sechs Vorlagen", #Library.Entries(), 6)
StreamGoalDB.packs[L.SG_OWN_GOALS] = nil
-- Befehlswort "template" wie "own"
SlashCmdList.STREAMGOAL("template add Per Vorlagen-Befehl")
expect("template add", Library.Entries()[#Library.Entries()].params.text, "Per Vorlagen-Befehl")
Library.Remove(Library.Entries()[#Library.Entries()].id)

-- Linksklick legt ein eigenes Ziel sofort an
CollectionView.OnOwnRowClick(Pool.Get(Pool.OwnKey(hug.id)), "LeftButton")
local started = Goals.Active()[1]
expect("angelegt", started and started.params.text, "Einen Murloc umarmen")
Goals.Cancel(started.id)

-- Löschen per Rechtsklick mit Rückfrage
CollectionView.OnOwnRowClick(Pool.Get(Pool.OwnKey(hug.id)), "RightButton")
expect("Rückfrage", wow.popup.name, "STREAMGOAL_REMOVE_OWN")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("gelöscht", Library.Get(hug.id), nil)

-- Befehle für eigene Ziele
SlashCmdList.STREAMGOAL("own add Per Befehl")
local byCommand = Library.Entries()[#Library.Entries()]
expect("own add", byCommand.params.text, "Per Befehl")
SlashCmdList.STREAMGOAL("own remove " .. byCommand.id)
expect("own remove", Library.Get(byCommand.id), nil)
SlashCmdList.STREAMGOAL("own remove 999")
expect("own remove unbekannt",
  wow.printed[#wow.printed]:find(string.format(L.SG_ERR_OWN_UNKNOWN, "999"), 1, true) ~= nil, true)

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

-- Befehle zum Öffnen der Reiter
SlashCmdList.STREAMGOAL("wheel edit")
expect("wheel edit", Manager.ShownPage(), "wheel")
SlashCmdList.STREAMGOAL("bingo edit")
expect("bingo edit", Manager.ShownPage(), "bingo")
SlashCmdList.STREAMGOAL("collection")
expect("collection", Manager.ShownPage(), "collection")
