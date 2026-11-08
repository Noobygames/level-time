-- Level Time Goals, UX-Review Paket 3 (leichter Einstieg, Entdeckbarkeit): Hinweis beim ersten Start, Freitext gleich
-- erreichbar, Level vorbelegt, Fehler im Fenster auf jeder Seite, klickbare Flächen erklären sich im Tooltip, Bingo ohne
-- Wiederholungen, mitgelieferte Pakete ohne "Teilen".
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local Bingo = streamGoal.Bingo
local BingoView = streamGoal.BingoView
local BingoEditor = streamGoal.BingoEditor
local WheelView = streamGoal.WheelView
local CollectionView = streamGoal.CollectionView
local Pool = streamGoal.Pool
local Packs = streamGoal.Packs
local L = streamGoal.L

local function printedText(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- Erster Start: einmal die Chatzeile, danach nie wieder
---------------------------------------------------------------------------
wow.login({ level = 10, zone = "Orgrimmar" })
expect("Einstieg im Chat", printedText(L.SG_INTRO), true)
expect("Merker gesetzt", StreamGoalDB.introShown, true)
local before = #wow.printed
wow.logout()
wow.login({ level = 10, zone = "Orgrimmar" })
local again = false
for index = before + 1, #wow.printed do
  if wow.printed[index]:find(L.SG_INTRO, 1, true) then again = true end
end
expect("nur beim ersten Start", again, false)
-- Wer schon Ziele hat (Update), bekommt den Hinweis nicht
StreamGoalDB.introShown = nil
table.insert(StreamGoalDB.goals, { id = 999, kind = "level", status = Goals.CANCELLED, character = "Andere-Welt",
  target = 5, start = 1, progress = 1, params = {} })
expect("Update ohne Hinweis", streamGoal.TakeFirstStart(), false)
expect("Merker trotzdem gesetzt", StreamGoalDB.introShown, true)
table.remove(StreamGoalDB.goals)

---------------------------------------------------------------------------
-- Fenster ohne je ein Ziel: die drei Schritte; Freitext gleich neben Level, Text vor dem Zähler
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("")
expect("Leerer Zustand erklärt die Schritte", Manager.emptyText and Manager.emptyText._text, L.SG_ACTIVE_EMPTY_FIRST)
expect("Level vorgewählt", Manager.SelectedKind(), "level")
expect("Freitext in der ersten Gruppe", Goals.GroupOf("custom"), Goals.KIND_GROUPS[1].key)
expect("Freitext-Reiter ohne Gruppenwechsel sichtbar", Manager.KindTab("custom"):IsShown(), true)
local customRows = Manager.Form("custom").rows
expect("Text zuerst", customRows[1].field and customRows[1].field.param, "text")
expect("Zähler danach", customRows[2].labelKey, "SG_FORM_COUNTER")

-- Level-Ziel: Feld mit dem nächsten Level vorbelegt, ein Klick reicht
expect("nächstes Level vorbelegt", Manager.FormWidget("amount"):GetText(), "11")
expectTrue("Ziel hinzufügen", wow.click(L.SG_FORM_ADD))
local levelGoal = Goals.Active()[1]
expect("Level-Ziel angelegt", levelGoal and levelGoal.target, 11)
expect("nach dem Anlegen wieder vorbelegt", Manager.FormWidget("amount"):GetText(), "11")
Goals.Cancel(levelGoal.id)
Manager.RenderActive()
expect("mit Historie: normaler Hinweis", Manager.emptyText._text, L.SG_ACTIVE_EMPTY)
-- Unveränderter Vorschlag folgt dem Level; eine eigene Zahl bleibt
wow.levelUp(11)
Manager.Refresh()
expect("Vorschlag nach Level-Up", Manager.FormWidget("amount"):GetText(), "12")
Manager.FormWidget("amount"):SetText("20")
Manager.Refresh()
expect("eigene Zahl bleibt", Manager.FormWidget("amount"):GetText(), "20")

-- Freitext: nur Text eintragen
Manager.SelectKind("custom")
Manager.FormWidget("text"):SetText("Ragnaros legen")
expectTrue("Freitext hinzufügen", wow.click(L.SG_FORM_ADD))
local custom = Goals.Active()[1]
expect("Freitext angelegt", custom and custom.params.text, "Ragnaros legen")
expect("ohne Zähler zum Abhaken", Goals.HasCount(custom), false)
Goals.Cancel(custom.id)

---------------------------------------------------------------------------
-- Fehler stehen auf jeder Seite im Fenster; ein Seitenwechsel leert sie
---------------------------------------------------------------------------
Manager.Toggle("bingo")
BingoEditor.textBox:SetText("   ")
expect("Bingo: Text abgelehnt", BingoEditor.AddText(), nil)
expect("Bingo: Fehlerzeile", BingoEditor.errorLine._text, L.SG_ERR_TEXT)
Manager.ShowPage("wheel")
expect("Seitenwechsel leert Fehler", BingoEditor.errorLine._text, "")
expectTrue("Alle aus", wow.click(L.SG_WHEEL_ALL_OFF))
WheelView.spinButton._scripts.OnClick(WheelView.spinButton, "LeftButton")
expect("Rad: Fehlerzeile", WheelView.errorLine._text, L.SG_WHEEL_EMPTY)
expectTrue("Alle an", wow.click(L.SG_WHEEL_ALL_ON))
Manager.ShowPage("collection")
CollectionView.SelectSection("packs")
CollectionView.nameBox:SetText("Paket")
expect("Sammlung: ohne laufende Ziele kein Paket", CollectionView.SavePack(), false)
expect("Sammlung: Fehlerzeile", CollectionView.errorLine._text, L.SG_ERR_PACK_EMPTY)
-- Schließen und wieder öffnen: alter Fehler weg
StreamGoalWindow:Hide()
Manager.Toggle("collection")
expect("nach dem Schließen leer", CollectionView.errorLine._text, "")

---------------------------------------------------------------------------
-- Pakete: Tooltip mit den Zielen, Teilen nur bei eigenen
---------------------------------------------------------------------------
local lines = CollectionView.PackTipLines("hardcore")
expect("Paket nennt seine Ziele", #lines, #Packs.BUILTIN[1].goals + 1)
expect("Ziel aufgelöst fürs Level", lines[2].text, string.format(L.SG_GOAL_LEVEL, 11 + 5))
expect("Bedienhinweis gedämpft", lines[#lines].muted, true)
local hardcoreRow = CollectionView.packRows[1]
expect("Zeile 1 ist fertig", hardcoreRow.builtin, true)
expect("fertiges Paket ohne Teilen", hardcoreRow.share:IsShown(), false)
expect("fertiges Paket ohne Löschen", hardcoreRow.delete:IsShown(), false)
expectTrue("Name mit Tooltip", hardcoreRow.hover._scripts.OnEnter ~= nil)
Goals.Create("kills", {}, 10)
CollectionView.nameBox:SetText("Meins")
expect("eigenes Paket gespeichert", CollectionView.SavePack(), true)
local ownRow
for _, row in ipairs(CollectionView.packRows) do
  if row.key == "Meins" then ownRow = row end
end
expect("eigenes Paket mit Teilen", ownRow and ownRow.share:IsShown(), true)
for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end

---------------------------------------------------------------------------
-- Tabellen erklären ihren Klick (Bingo: in Feld N, Rad: an/aus)
---------------------------------------------------------------------------
local item = Pool.Get("p:kills10")
local tip = Manager.PoolRowTip(item, { "x" })
expect("voller Titel", tip[1], Pool.Title(item))
expect("Art und Herkunft", tip[2], string.format(L.SG_ROW_TIP_KIND, L.SG_KIND_KILLS, L.SG_POOL_PREMADE))
expect("Klick zuletzt", tip[3], "x")

---------------------------------------------------------------------------
-- Bingo-Schein: Felder ohne Wiederholung, 3x3 ohne zwei Felder desselben Themas; Tooltip je Feld
---------------------------------------------------------------------------
local function cellGoals(board)
  local list = {}
  for _, id in ipairs(board.params.cells) do
    if id ~= Bingo.FREE then table.insert(list, Goals.Get(id)) end
  end
  return list
end
for _ = 1, 5 do
  local small = Bingo.CreateBoard(3)
  local topics = {}
  for _, goal in ipairs(cellGoals(small)) do
    local topic = Bingo.TopicOf(goal)
    expect("3x3: Thema einmal " .. topic, topics[topic], nil)
    topics[topic] = true
  end
  Goals.Cancel(small.id)
end
local big = Bingo.CreateBoard(5)
local titles = {}
for _, goal in ipairs(cellGoals(big)) do
  local title = Goals.Title(goal)
  expect("5x5: kein Feld doppelt " .. title, titles[title], nil)
  titles[title] = true
end
expect("5x5: 24 Felder", #cellGoals(big), 24)

local manualCell, autoCell
for _, goal in ipairs(cellGoals(big)) do
  if goal.kind == "custom" then manualCell = manualCell or goal else autoCell = autoCell or goal end
end
local cellTip = BingoView.CellTip(manualCell)
expect("Feld-Tooltip: voller Text", cellTip.title, Goals.Title(manualCell))
expect("Feld-Tooltip: abhaken", cellTip.lines[1].text, L.SG_CARD_TIP_DONE)
expect("Feld-Tooltip: Einstellungen", cellTip.lines[#cellTip.lines].text, L.SG_CARD_TIP_SETTINGS)
local autoTip = BingoView.CellTip(autoCell)
expectTrue("automatisches Feld sagt es", autoTip.lines[#autoTip.lines - 1].text == L.SG_ACTIVE_TIP_AUTO)
expect("freie Mitte", BingoView.CellTip(nil).title, L.SG_BINGO_FREE)
expectTrue("Feld mit Tooltip am Bildschirm", StreamGoalBingoCell1._scripts.OnEnter ~= nil)
Goals.Cancel(big.id)

-- Zu kleiner Pool für 5x5: der Bingo-Reiter sagt es vorher
local premade = Pool.PREMADE
Pool.PREMADE = { premade[1], premade[2] }
BingoEditor.SetSize(5)
expectTrue("Warnung bei kleinem Pool", BingoEditor.HintText():find(string.format(L.SG_BINGO_POOL_SMALL, #Pool.Items(), 24),
  1, true) ~= nil)
Pool.PREMADE = premade
expect("genug Einträge: keine Warnung", BingoEditor.HintText(), L.SG_BINGO_EDIT_HINT)
