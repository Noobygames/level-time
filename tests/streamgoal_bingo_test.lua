-- Level Time Goals, Roadmap 305: Bingo-Schein aus Zielen anderer Arten, Felder kreuzen sich selbst an, BINGO bei
-- voller Reihe, Spalte oder Diagonale, freie Mitte bei 5x5.
local Goals = streamGoal.Goals
local Bingo = streamGoal.Bingo
local L = streamGoal.L

wow.login({ level = 10 })
StreamGoalDB.settings.bingoTexts = { "Feld A", "Feld B", "Feld C", "Feld D", "Feld E", "Feld F", "Feld G", "Feld H",
  "Feld I" }
Bingo.POOL = {}  -- nur eigene Texte: Felder zum Abhaken, Reihenfolge egal

SlashCmdList.STREAMGOAL("bingo 3")
local board = Goals.Active()[1]
expect("Schein", board.kind, "bingo")
expect("neun Felder", #board.params.cells, 9)
expect("Felder belegen keine Plätze", Goals.UsedSlots(), 1)
expect("Schein am Bildschirm", StreamGoalBingo:IsShown(), true)
expect("keine eigene Karte für Felder", StreamGoalCard2 == nil or not StreamGoalCard2:IsShown(), true)
expect("eine Karte für den Schein", StreamGoalCard1.title._text, Goals.Title(board))
expect("Feld zeigt seinen Text", StreamGoalBingoCell1.text._text, Goals.Title(Goals.Get(board.params.cells[1])))

-- Felder per Klick: erste Reihe voll = BINGO
local function clickCell(index)
  local cell = _G["StreamGoalBingoCell" .. index]
  cell._scripts.OnMouseUp(cell, "LeftButton")
end
clickCell(1)
clickCell(5)
expect("noch kein Bingo", board.status, Goals.ACTIVE)
expect("Feld erledigt gefärbt", StreamGoalBingoCell1.back._colorTexture[1], addon.Theme.COLORS.success[1])
addon.Alerts.Clear()
clickCell(9)
expect("Diagonale = BINGO", board.status, Goals.DONE)
expect("übrige Felder abgebrochen", Goals.Get(board.params.cells[2]).status, Goals.CANCELLED)
expect("Schein weg", StreamGoalBingo:IsShown(), false)

-- 5x5 mit freier Mitte, Pool wiederholt sich, wenn er nicht reicht
SlashCmdList.STREAMGOAL("bingo 5")
local big = Goals.Active()[1]
expect("25 Felder", #big.params.cells, 25)
expect("Mitte frei", big.params.cells[13], Bingo.FREE)
expect("Mitte zählt als erledigt", Bingo.IsCellDone(big, 13), true)
expect("falsche Größe", select(2, Goals.Create("bingo", { size = 4 })), L.SG_ERR_BINGO_SIZE)

-- Abbrechen des Scheins bricht die Felder ab
Goals.Cancel(big.id)
expect("Feld mit abgebrochen", Goals.Get(big.params.cells[1]).status, Goals.CANCELLED)
expect("keine laufenden Ziele", #Goals.Active(), 0)

-- Eigene Texte per Befehl
SlashCmdList.STREAMGOAL("bingo clear")
expect("mitgelieferte Texte", Bingo.Texts()[1], L.SG_BINGO_TEXT_1)
SlashCmdList.STREAMGOAL("bingo text Einen Fisch fangen")
expect("eigener Text", Bingo.Texts()[1], "Einen Fisch fangen")

-- Gruppenansage
StreamGoalDB.settings.bingoAnnounce = true
StreamGoalDB.settings.bingoTexts = { "X" }
wow.state.groupMembers = 2
SlashCmdList.STREAMGOAL("bingo 3")
local third = Goals.Active()[1]
for index = 1, 3 do clickCell(index) end
expect("drittes Bingo", third.status, Goals.DONE)
