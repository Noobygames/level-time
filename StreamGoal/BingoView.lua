-- Bingo-Schein am Bildschirm (Roadmap 305): Raster aus Feldern (Text des Feld-Ziels, Stand), erledigte Felder in der
-- Erfolgsfarbe des Themes, freie Mitte bei 5x5. Verschiebbar über den Edit-Modus von Level Time (Beispielschein in
-- der Vorschau). Linksklick auf ein selbst gezähltes Feld hakt es ab (mit Bestätigung, ClickStep.lua),
-- Shift+Linksklick zurück, Rechtsklick öffnet die Einstellungen; der Tooltip eines Felds zeigt den vollen Text (Felder
-- schneiden lange Texte ab), den Stand und diese Klicks wie bei den Ziel-Karten. Neu aufgebaut nur bei Änderungen der Ziele
-- (Goals.OnChange) und Einstellungen.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Bingo = ns.Bingo
local L = ns.L
local Theme = LT.Theme

local BingoView = {}
ns.BingoView = BingoView

BingoView.FRAME_ID = "streamGoalBingo"
local CELL_SIZE = 72
local CELL_GAP = 3
local PADDING = 8
local TITLE_HEIGHT = 18
local CELL_TEXT_INSET = 4
local DONE_ALPHA, OPEN_ALPHA = 0.55, 0.85
local SAMPLE_SIZE = 3
local SAMPLE_DONE = { [1] = true, [5] = true }
local DEFAULT_POSITION = { "TOPRIGHT", "TOPRIGHT", -280, -220 }
local TOOLTIP_ANCHOR = "ANCHOR_LEFT"  -- der Schein steht meist am rechten Rand

local frame = CreateFrame("Frame", "StreamGoalBingo", UIParent)
frame:SetSize(1, 1)
frame:Hide()
Theme.RegisterCard(frame)
BingoView.frame = frame

local title = frame:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
title:SetPoint("TOPLEFT", PADDING, -PADDING)

local cells = {}
local editing = false

local function onCellClick(cell, mouseButton)
  if editing then return end
  if mouseButton == "RightButton" then
    ns.Tracker.ToggleSettings()
    return
  end
  ns.ClickStep.Click(cell.goal, IsShiftKeyDown())
end

-- Tooltip eines Felds: { title, lines = { { text, muted } } } (Tests); goal = nil ist die freie Mitte
function BingoView.CellTip(goal)
  local lines = {}
  if not goal then
    table.insert(lines, { text = L.SG_CARD_TIP_SETTINGS, muted = true })
    return { title = L.SG_BINGO_FREE, lines = lines }
  end
  if Goals.HasCount(goal) then table.insert(lines, { text = Goals.CountText(goal) }) end
  if goal.status == Goals.ACTIVE then
    if Goals.IsManual(goal) then
      table.insert(lines, { text = Goals.HasCount(goal) and L.SG_CARD_TIP_COUNT or L.SG_CARD_TIP_DONE, muted = true })
    else
      table.insert(lines, { text = L.SG_ACTIVE_TIP_AUTO, muted = true })
    end
  end
  table.insert(lines, { text = L.SG_CARD_TIP_SETTINGS, muted = true })
  return { title = Goals.Title(goal), lines = lines }
end

local function showCellTooltip(cell)
  if editing then return end
  local tip = BingoView.CellTip(cell.goal)
  GameTooltip:SetOwner(cell, TOOLTIP_ANCHOR)
  GameTooltip:SetText(tip.title, Theme.RGB("accent"))
  for _, line in ipairs(tip.lines) do
    if line.muted then
      local r, g, b = Theme.RGB("muted")
      GameTooltip:AddLine(line.text, r, g, b, true)
    else
      GameTooltip:AddLine(line.text, 1, 1, 1, true)
    end
  end
  GameTooltip:Show()
end

local function cellAt(index)
  if cells[index] then return cells[index] end
  local cell = CreateFrame("Frame", "StreamGoalBingoCell" .. index, frame)
  cell:SetSize(CELL_SIZE, CELL_SIZE)
  cell.back = cell:CreateTexture(nil, "BACKGROUND")
  cell.back:SetAllPoints()
  cell.text = cell:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
  cell.text:SetPoint("TOPLEFT", CELL_TEXT_INSET, -CELL_TEXT_INSET)
  cell.text:SetPoint("BOTTOMRIGHT", -CELL_TEXT_INSET, CELL_TEXT_INSET)
  cell.text:SetJustifyH("CENTER")
  cell.text:SetJustifyV("MIDDLE")
  cell:SetScript("OnMouseUp", function(self, mouseButton) onCellClick(self, mouseButton) end)
  cell:SetScript("OnEnter", showCellTooltip)
  cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
  cells[index] = cell
  return cell
end

-- Feld füllen: Text, Farbe nach Status
local function paint(cell, text, done)
  local color = done and Theme.COLORS.success or Theme.COLORS.surface
  cell.back:SetColorTexture(color[1], color[2], color[3], done and DONE_ALPHA or OPEN_ALPHA)
  cell.text:SetText(text)
  cell.text:SetTextColor(Theme.RGB(done and "text" or "muted"))
end

local function cellText(goal)
  local text = Goals.Title(goal)
  if ns.ClickStep.IsArmed(goal) then return text .. "\n" .. L.SG_CARD_CONFIRM end
  if Goals.HasCount(goal) and goal.status == Goals.ACTIVE then text = text .. "\n" .. Goals.CountText(goal) end
  return text
end

local function layout(size, count)
  for index = 1, math.max(count, #cells) do
    local cell = cells[index]
    if index <= count then
      cell = cellAt(index)
      local row, column = math.floor((index - 1) / size), (index - 1) % size
      cell:ClearAllPoints()
      cell:SetPoint("TOPLEFT", PADDING + column * (CELL_SIZE + CELL_GAP),
        -PADDING - TITLE_HEIGHT - row * (CELL_SIZE + CELL_GAP))
      cell:Show()
    elseif cell then
      cell.goal = nil
      cell:Hide()
    end
  end
  local side = size * CELL_SIZE + (size - 1) * CELL_GAP + 2 * PADDING
  frame:SetSize(side, side + TITLE_HEIGHT)
end

-- Laufender Schein des Charakters (der älteste), nil = keiner
function BingoView.ActiveBoard()
  for _, goal in ipairs(Goals.Active()) do
    if goal.kind == "bingo" and goal.params.cells then return goal end
  end
end

local function showSample()
  title:SetText(string.format(L.SG_GOAL_BINGO, SAMPLE_SIZE, SAMPLE_SIZE))
  layout(SAMPLE_SIZE, SAMPLE_SIZE * SAMPLE_SIZE)
  for index = 1, SAMPLE_SIZE * SAMPLE_SIZE do
    cells[index].goal = nil
    paint(cells[index], L.SG_BINGO_SAMPLE, SAMPLE_DONE[index] == true)
  end
  frame:Show()
end

function BingoView.Refresh()
  if not ns.db then return end
  local board = BingoView.ActiveBoard()
  if not board then
    if editing then showSample() else frame:Hide() end
    return
  end
  if not ns.db.settings.showBingo and not editing then
    frame:Hide()
    return
  end
  local size = board.params.size
  title:SetText(Goals.Title(board))
  layout(size, #board.params.cells)
  for index, id in ipairs(board.params.cells) do
    local cell = cells[index]
    if id == Bingo.FREE then
      cell.goal = nil
      paint(cell, L.SG_BINGO_FREE, true)
    else
      local goal = Goals.Get(id)
      cell.goal = goal
      paint(cell, goal and cellText(goal) or "?", Bingo.IsCellDone(board, index))
    end
    cell:EnableMouse(not editing)
  end
  frame:Show()
end

LT.Frames.Register({
  id = BingoView.FRAME_ID, frame = frame, label = "SG_EDIT_BINGO", default = DEFAULT_POSITION,
  settingsPage = ns.SETTINGS_PAGES.BINGO,
  store = {
    get = function() return ns.db and ns.db.settings.bingoFrame end,
    set = function(entry) ns.db.settings.bingoFrame = entry end,
  },
  preview = function(on)
    editing = on
    BingoView.Refresh()
  end,
  hide = function() ns.SetSetting("showBingo", false) end,
})

Goals.OnChange(function() BingoView.Refresh() end)
ns.RegisterApply(BingoView.Refresh)
LT.OnLogin(function() LT.Frames.Restore(BingoView.FRAME_ID) end)
