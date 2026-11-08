-- Reiter "Bingo" im Fenster /sg (Roadmap 431): Schein selbst füllen. Links Größe und Raster des Entwurfs (Feld anklicken
-- = auswählen, Rechtsklick = leeren), rechts alle Ziele zur Wahl (mitgelieferte und eigene, TableView mit Filter); ein
-- Klick auf ein Ziel setzt es ins gewählte Feld und springt zum nächsten leeren. Darunter: freier Text als Vorlage
-- direkt ins Feld, dann die Knopfzeile mit der Hauptaktion "Schein anlegen" rechts (leere Felder werden zufällig).
-- Entwurf in StreamGoalDB.bingoDraft = { size = 3|5, picks = { [Feld] = Pool-Schlüssel } } (bleibt über /reload).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Bingo = ns.Bingo
local Pool = ns.Pool
local Library = ns.Library
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local BingoEditor = {}
ns.BingoEditor = BingoEditor

local SIZE_TABS_TOP = -26
local TAB_GAP = 14
local GRID_TOP = -50
local GRID_SIDE = 260
local CELL_GAP = 3
local CELL_TEXT_INSET = 3
local COLUMN_GAP = 16
local TABLE_HEIGHT = 330
local CONTROLS_GAP = 10
local HINT_GAP = 12
local ALPHA = { selected = 0.6, picked = 0.45, random = 0.85, free = 0.55 }
local CELL_COLORS = { selected = "accent", picked = "info", random = "surface", free = "success" }
local SIZE_LABELS = { [3] = "SG_BINGO_3", [5] = "SG_BINGO_5" }

local page = Manager.AddPage({
  key = "bingo", label = "SG_TAB_BINGO", settingsPage = ns.SETTINGS_PAGES.BINGO,
  render = function() BingoEditor.Render() end,
})

local header = Widgets.CreateSectionHeader(page)
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")

local selected = 1

local function draft()
  local db = ns.db
  db.bingoDraft = type(db.bingoDraft) == "table" and db.bingoDraft or {}
  local value = db.bingoDraft
  if value.size ~= 3 and value.size ~= 5 then value.size = Bingo.SIZES[1] end
  value.picks = type(value.picks) == "table" and value.picks or {}
  return value
end
BingoEditor.Draft = draft

local function cellCount()
  return draft().size * draft().size
end

-- Nächstes Feld ohne Wahl ab from (ohne freie Mitte), sonst from
local function nextOpen(from)
  local size, picks = draft().size, draft().picks
  for step = 0, cellCount() - 1 do
    local index = (from - 1 + step) % cellCount() + 1
    if not picks[index] and not Bingo.IsFreeCell(size, index) then return index end
  end
  return from
end

---------------------------------------------------------------------------
-- Raster
---------------------------------------------------------------------------
local cells = {}

-- Feld wählen bzw. leeren (auch für Tests)
function BingoEditor.Select(index)
  if Bingo.IsFreeCell(draft().size, index) then return end
  selected = index
  BingoEditor.Render()
end

function BingoEditor.ClearCell(index)
  draft().picks[index or selected] = nil
  BingoEditor.Render()
end

local function cellAt(index)
  if cells[index] then return cells[index] end
  local cell = CreateFrame("Frame", "StreamGoalBingoEditorCell" .. index, page)
  cell.back = cell:CreateTexture(nil, "BACKGROUND")
  cell.back:SetAllPoints()
  cell.text = cell:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
  cell.text:SetPoint("TOPLEFT", CELL_TEXT_INSET, -CELL_TEXT_INSET)
  cell.text:SetPoint("BOTTOMRIGHT", -CELL_TEXT_INSET, CELL_TEXT_INSET)
  cell.text:SetJustifyH("CENTER")
  cell.text:SetJustifyV("MIDDLE")
  cell:EnableMouse(true)
  cell:SetScript("OnMouseUp", function(_, mouseButton)
    if mouseButton == "RightButton" then BingoEditor.ClearCell(index) else BingoEditor.Select(index) end
  end)
  Widgets.AttachTooltip(cell, function() return cell.fullText or "" end, function() return L.SG_BINGO_EDIT_CELL_TIP end)
  cells[index] = cell
  return cell
end

local function paint(cell, kind, text)
  local color = Theme.COLORS[CELL_COLORS[kind]]
  cell.back:SetColorTexture(color[1], color[2], color[3], ALPHA[kind])
  cell.text:SetText(text)
  cell.text:SetTextColor(Theme.RGB(kind == "random" and "muted" or "text"))
  cell.fullText = text
end

local function renderGrid()
  local size, picks = draft().size, draft().picks
  local side = (GRID_SIDE - (size - 1) * CELL_GAP) / size
  for index = 1, math.max(cellCount(), #cells) do
    if index <= cellCount() then
      local cell = cellAt(index)
      local row, column = math.floor((index - 1) / size), (index - 1) % size
      cell:SetSize(side, side)
      cell:ClearAllPoints()
      cell:SetPoint("TOPLEFT", column * (side + CELL_GAP), GRID_TOP - row * (side + CELL_GAP))
      cell:Show()
      local item = picks[index] and Pool.Get(picks[index])
      if Bingo.IsFreeCell(size, index) then
        paint(cell, "free", L.SG_BINGO_FREE)
      elseif index == selected then
        paint(cell, "selected", item and Pool.Title(item) or L.SG_BINGO_RANDOM)
      elseif item then
        paint(cell, "picked", Pool.Title(item))
      else
        paint(cell, "random", L.SG_BINGO_RANDOM)
      end
    elseif cells[index] then
      cells[index]:Hide()
    end
  end
end

-- Größe: Reiter "3 × 3" und "5 × 5"
local sizeTabs = {}
for _, size in ipairs(Bingo.SIZES) do
  local tab = Widgets.CreateTab(page, Theme.Font("body"), function() BingoEditor.SetSize(size) end)
  Widgets.AttachTooltip(tab, function() return L[SIZE_LABELS[size]] end, function() return L.SG_BINGO_SIZE_TIP end)
  sizeTabs[size] = tab
end

function BingoEditor.SetSize(size)
  local value = draft()
  if value.size == size then return end
  value.size = size
  for index in pairs(value.picks) do
    if index > size * size or Bingo.IsFreeCell(size, index) then value.picks[index] = nil end
  end
  selected = nextOpen(1)
  BingoEditor.Render()
end

---------------------------------------------------------------------------
-- Ziele zur Wahl (rechts)
---------------------------------------------------------------------------
-- Ziel ins gewählte Feld, dann zum nächsten leeren Feld
function BingoEditor.Assign(key)
  local value = draft()
  if Bingo.IsFreeCell(value.size, selected) then selected = nextOpen(1) end
  value.picks[selected] = key
  selected = nextOpen(selected)
  BingoEditor.Render()
end

local candidates = LT.TableView.Create({
  tab = "SG_TAB_BINGO",
  columns = {
    { header = "SG_COL_GOAL", width = 214, align = "LEFT", value = function(item) return Pool.Title(item) end },
    { header = "SG_COL_SOURCE", width = 90, align = "LEFT", value = Pool.SourceText },
  },
  records = function() return Pool.Items() end,
  footer = function(_, records) return { string.format(L.SG_BINGO_EDIT_FOOTER, #records) } end,
  rowColor = function(item) return item.premade and Theme.COLORS.text or Theme.COLORS.accent end,
  onRowClick = function(item, mouseButton)
    if mouseButton ~= "RightButton" then BingoEditor.Assign(item.key) end
  end,
  hint = "SG_BINGO_EDIT_TABLE_HINT",
})

local tableWidth = Manager.PAGE_WIDTH - GRID_SIDE - COLUMN_GAP
local holder = CreateFrame("Frame", nil, page)
holder:SetPoint("TOPLEFT", GRID_SIDE + COLUMN_GAP, -Manager.HEADER_HEIGHT)
holder:SetSize(tableWidth, TABLE_HEIGHT)
local candidateTable = candidates.Create(holder, tableWidth, TABLE_HEIGHT)
BingoEditor.table = candidateTable

---------------------------------------------------------------------------
-- Unten: freier Text ins Feld, Knopfzeile, Hinweis
---------------------------------------------------------------------------
local controlsTop = -Manager.HEADER_HEIGHT - TABLE_HEIGHT - CONTROLS_GAP

local textLabel = Manager.CreateLabel(page)
textLabel:SetPoint("TOPLEFT", 0, controlsTop - 4)
local textBox = Manager.CreateTextBox(page, function() BingoEditor.AddText() end)
BingoEditor.textBox = textBox

-- Freier Text als Vorlage ins gewählte Feld
function BingoEditor.AddText()
  local entry, err = Library.AddText(textBox:GetText())
  if not entry then
    ns.Print(err)
    return nil
  end
  textBox:SetText("")
  textBox:ClearFocus()
  BingoEditor.Assign(Pool.OwnKey(entry.id))
  return entry
end

local textButton = Manager.CreateButton(page, "SG_BINGO_EDIT_TEXT", function() BingoEditor.AddText() end)

-- Schein aus dem Entwurf anlegen; der Entwurf wird danach geleert
function BingoEditor.CreateBoard()
  local value = draft()
  local board, err = Bingo.CreateBoard(value.size, value.picks)
  if not board then
    ns.Print(err)
    return nil
  end
  value.picks = {}
  selected = nextOpen(1)
  ns.Print(string.format(L.SG_CHAT_ADDED, Goals.Title(board)))
  BingoEditor.Render()
  return board
end

local createButton = Manager.CreateButton(page, "SG_BINGO_EDIT_CREATE", function() BingoEditor.CreateBoard() end)
local clearAllButton = Manager.CreateButton(page, "SG_BINGO_EDIT_CLEAR_ALL", function()
  draft().picks = {}
  selected = nextOpen(1)
  BingoEditor.Render()
end)
local clearButton = Manager.CreateButton(page, "SG_BINGO_EDIT_CLEAR", function() BingoEditor.ClearCell() end)
local actionButtons = { createButton, clearAllButton, clearButton }  -- Hauptaktion rechts

local hint = Manager.CreateHint(page)
hint:SetPoint("TOPLEFT", 0, controlsTop - 2 * Manager.ROW - HINT_GAP)

function BingoEditor.Render()
  if not ns.db then return end
  header:SetText(L.SG_BINGO_EDIT_TITLE)
  local left = 0
  for _, size in ipairs(Bingo.SIZES) do
    local tab = sizeTabs[size]
    tab:SetLabel(L[SIZE_LABELS[size]])
    tab:SetActive(draft().size == size)
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", left, SIZE_TABS_TOP)
    left = left + tab:GetWidth() + TAB_GAP
  end
  if selected > cellCount() or Bingo.IsFreeCell(draft().size, selected) then selected = nextOpen(1) end
  renderGrid()
  Manager.SetLabels({ textButton, createButton, clearAllButton, clearButton })
  textLabel:SetText(L.SG_OWN_TEXT)
  Manager.FitBox(textLabel, textBox, Manager.AlignRight({ textButton }, page, "TOPRIGHT", controlsTop))
  Manager.AlignRight(actionButtons, page, "TOPRIGHT", controlsTop - Manager.ROW - 4)
  hint:SetText(L.SG_BINGO_EDIT_HINT)
  candidateTable:Render(nil, false, true)
end

-- Gewähltes Feld (Tests)
function BingoEditor.Selected()
  return selected
end

-- Knöpfe der Seite (Tests: Überlappung)
function BingoEditor.Buttons()
  return actionButtons
end
