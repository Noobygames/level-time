-- Reiter "Bingo" im Fenster /sg (Roadmap 431): Schein selbst füllen. Links das Raster des Entwurfs (Feld anklicken =
-- auswählen, Rechtsklick = leeren), rechts alle Einträge des Pools (mitgelieferte und eigene Ziele, TableView mit
-- Filter); ein Klick auf einen Eintrag setzt ihn ins gewählte Feld und springt zum nächsten leeren. Freier Text landet
-- als eigenes Ziel im gewählten Feld. "Schein anlegen" füllt leere Felder zufällig (wie /sg bingo).
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

local HEADER_HEIGHT = 24
local SIZE_TABS_TOP = -26
local TAB_GAP = 14
local GRID_TOP = -50
local GRID_SIDE = 260
local CELL_GAP = 3
local CELL_TEXT_INSET = 3
local COLUMN_GAP = 16
local TABLE_HEIGHT = 330
local ROW = 26
local BOX_HEIGHT = 20
local BOX_BORDER = 6
local BUTTON_MIN_WIDTH = 90
local BUTTON_GAP = 6
local LABEL_GAP = 8
local ALPHA = { selected = 0.6, picked = 0.45, random = 0.85, free = 0.55 }
local CELL_COLORS = { selected = "accent", picked = "info", random = "surface", free = "success" }

local page = Manager.AddPage("bingo", "SG_TAB_BINGO", function() BingoEditor.Render() end)

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
  sizeTabs[size] = Widgets.CreateTab(page, Theme.Font("body"), function() BingoEditor.SetSize(size) end)
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
-- Einträge rechts
---------------------------------------------------------------------------
-- Eintrag ins gewählte Feld, dann zum nächsten leeren Feld
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
    { header = "SG_COL_SOURCE", width = 90, align = "LEFT",
      value = function(item) return item.premade and L.SG_POOL_PREMADE or L.SG_POOL_OWN end },
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
holder:SetPoint("TOPLEFT", GRID_SIDE + COLUMN_GAP, -HEADER_HEIGHT)
holder:SetSize(tableWidth, TABLE_HEIGHT)
local candidateTable = candidates.Create(holder, tableWidth, TABLE_HEIGHT)
BingoEditor.table = candidateTable

---------------------------------------------------------------------------
-- Unten: freier Text, Knöpfe, Hinweis
---------------------------------------------------------------------------
local controlsTop = -HEADER_HEIGHT - TABLE_HEIGHT - 10

local textLabel = page:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
textLabel:SetJustifyH("LEFT")
textLabel:SetPoint("TOPLEFT", 0, controlsTop - 4)
local textBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
textBox:SetHeight(BOX_HEIGHT)
textBox:SetAutoFocus(false)
textBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
BingoEditor.textBox = textBox

-- Freier Text als eigenes Ziel ins gewählte Feld
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
textBox:SetScript("OnEnterPressed", function() BingoEditor.AddText() end)

local function button(labelKey, onClick)
  local widget = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, onClick)
  widget.labelKey = labelKey
  Widgets.AttachTooltip(widget, function() return L[labelKey] end, function() return L[labelKey .. "_TIP"] end)
  return widget
end

local textButton = button("SG_BINGO_EDIT_TEXT", function() BingoEditor.AddText() end)
textButton:SetPoint("TOPRIGHT", 0, controlsTop)

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

local createButton = button("SG_BINGO_EDIT_CREATE", function() BingoEditor.CreateBoard() end)
createButton:SetPoint("TOPRIGHT", 0, controlsTop - ROW - 4)
local clearAllButton = button("SG_BINGO_EDIT_CLEAR_ALL", function()
  draft().picks = {}
  selected = nextOpen(1)
  BingoEditor.Render()
end)
clearAllButton:SetPoint("RIGHT", createButton, "LEFT", -BUTTON_GAP, 0)
local clearButton = button("SG_BINGO_EDIT_CLEAR", function() BingoEditor.ClearCell() end)
clearButton:SetPoint("RIGHT", clearAllButton, "LEFT", -BUTTON_GAP, 0)
local buttons = { textButton, createButton, clearAllButton, clearButton }

local hint = page:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
hint:SetTextColor(Theme.RGB("muted"))
hint:SetJustifyH("LEFT")
hint:SetWidth(Manager.PAGE_WIDTH)
hint:SetPoint("TOPLEFT", 0, controlsTop - 2 * ROW - 12)

function BingoEditor.Render()
  if not ns.db then return end
  header:SetText(L.SG_BINGO_EDIT_TITLE)
  local left = 0
  for _, size in ipairs(Bingo.SIZES) do
    local tab = sizeTabs[size]
    tab:SetLabel(L[size == 3 and "SG_BINGO_3" or "SG_BINGO_5"])
    tab:SetActive(draft().size == size)
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", left, SIZE_TABS_TOP)
    left = left + tab:GetWidth() + TAB_GAP
  end
  if selected > cellCount() or Bingo.IsFreeCell(draft().size, selected) then selected = nextOpen(1) end
  renderGrid()
  for _, widget in ipairs(buttons) do Widgets.SetButtonText(widget, L[widget.labelKey], BUTTON_MIN_WIDTH) end
  textLabel:SetText(L.SG_OWN_TEXT)
  textBox:ClearAllPoints()
  textBox:SetPoint("LEFT", textLabel, "RIGHT", LABEL_GAP + BOX_BORDER, 0)
  textBox:SetWidth(Manager.PAGE_WIDTH - math.ceil(textLabel:GetStringWidth() or 0) - LABEL_GAP - BOX_BORDER
    - textButton:GetWidth() - BUTTON_GAP)
  hint:SetText(L.SG_BINGO_EDIT_HINT)
  candidateTable:Render(nil, false, true)
end

-- Gewähltes Feld (Tests)
function BingoEditor.Selected()
  return selected
end
