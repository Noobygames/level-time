-- Zielart Bingo (Roadmap 305): ein Schein mit 3x3 oder 5x5 Feldern (5x5 mit freier Mitte). Jedes Feld ist ein Ziel
-- einer anderen Art (goal.cell, goal.parentId = Schein; belegt keinen der MAX_ACTIVE-Plätze), gezogen aus Bingo.POOL
-- (Ziele relativ zum Level, zählen sich selbst wie jedes Ziel) und den eigenen Texten (settings.bingoTexts, abhaken per
-- Klick). Eine volle Reihe, Spalte oder Diagonale = BINGO: der Schein ist erreicht, die übrigen Felder werden
-- abgebrochen, große Einblendung, optional eine Ansage in den Gruppenchat (settings.bingoAnnounce).
-- params: { size = 3|5, cells = { [Feld] = Ziel-ID oder FREE } } (Felder zeilenweise)
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L

local Bingo = {}
ns.Bingo = Bingo

Bingo.SIZES = { 3, 5 }
Bingo.FREE = 0           -- freies Feld (Mitte bei 5x5)
Bingo.MAX_TEXTS = 30
local ICON = "Interface\\Icons\\INV_Misc_Note_02"
local FREE_CENTER_SIZE = 5
local DEFAULT_TEXTS = 6  -- SG_BINGO_TEXT_1..6

-- Felder, die sich selbst zählen; target(level)
Bingo.POOL = {
  { kind = "kills", params = { source = "pve" }, target = function() return 10 end },
  { kind = "kills", params = { source = "pve" }, target = function() return 25 end },
  { kind = "kills", params = { source = "any" }, target = function() return 50 end },
  { kind = "quest", params = { mode = "count" }, target = function() return 2 end },
  { kind = "quest", params = { mode = "count" }, target = function() return 5 end },
  { kind = "quest", params = { mode = "count" }, target = function() return 10 end },
  { kind = "gold", params = { mode = "earn" }, target = function() return 1 end },
  { kind = "gold", params = { mode = "earn" }, target = function() return 5 end },
  { kind = "explore", params = { mode = "count" }, target = function() return 1 end },
  { kind = "explore", params = { mode = "count" }, target = function() return 3 end },
  { kind = "dungeon", params = {}, target = function() return 1 end },
  { kind = "dungeon", params = {}, target = function() return 3 end },
  { kind = "level", params = {}, target = function(level) return level + 1 end },
  { kind = "honor", params = {}, target = function() return 100 end },
}

-- Eigene Texte oder, solange keine da sind, die mitgelieferten
function Bingo.Texts()
  local own = ns.db.settings.bingoTexts
  if type(own) == "table" and #own > 0 then return own end
  local texts = {}
  for index = 1, DEFAULT_TEXTS do table.insert(texts, L["SG_BINGO_TEXT_" .. index]) end
  return texts
end

-- Pool gemischt (auch für das Glücksrad): Einträge { kind, params, target }
function Bingo.ShuffledPool()
  local entries = {}
  for _, entry in ipairs(Bingo.POOL) do
    if Goals.IsAvailable(entry.kind) then
      table.insert(entries, { kind = entry.kind, params = Goals.CopyFlat(entry.params), target = entry.target(LT.level) })
    end
  end
  for _, text in ipairs(Bingo.Texts()) do
    table.insert(entries, { kind = "custom", params = { text = text } })
  end
  for index = #entries, 2, -1 do
    local other = math.random(index)
    entries[index], entries[other] = entries[other], entries[index]
  end
  return entries
end

local function cellCount(size)
  return size * size
end

local function isFree(board, index)
  return board.params.size == FREE_CENTER_SIZE and index == math.ceil(cellCount(board.params.size) / 2)
end

-- Felder anlegen; reicht der Pool nicht (oder lehnt eine Art ab, z.B. schon erreicht), wird weiter gezogen und
-- notfalls wiederholt
local function fill(board)
  local size = board.params.size
  local pool = Bingo.ShuffledPool()
  local cells, next, attempts = {}, 1, 0
  for index = 1, cellCount(size) do
    if isFree(board, index) then
      cells[index] = Bingo.FREE
    else
      local cell
      while not cell and attempts < cellCount(size) * 4 do
        local entry = pool[(next - 1) % #pool + 1]
        next, attempts = next + 1, attempts + 1
        cell = Goals.Create(entry.kind, Goals.CopyFlat(entry.params), entry.target, {}, board)
      end
      cells[index] = cell and cell.id or Bingo.FREE
    end
  end
  board.params.cells = cells
end

-- Ist das Feld erledigt? (freies Feld immer)
function Bingo.IsCellDone(board, index)
  local id = board.params.cells[index]
  if id == Bingo.FREE then return true end
  local cell = Goals.Get(id)
  return cell ~= nil and cell.status == Goals.DONE
end

-- Volle Reihe, Spalte oder Diagonale?
function Bingo.HasLine(board)
  local size = board.params.size
  local function done(row, column) return Bingo.IsCellDone(board, (row - 1) * size + column) end
  local diagonal, anti = true, true
  for i = 1, size do
    local row, column = true, true
    for j = 1, size do
      row = row and done(i, j)
      column = column and done(j, i)
    end
    if row or column then return true end
    diagonal = diagonal and done(i, i)
    anti = anti and done(i, size - i + 1)
  end
  return diagonal or anti
end

function Bingo.DoneCount(board)
  local count = 0
  for index = 1, #board.params.cells do
    if Bingo.IsCellDone(board, index) then count = count + 1 end
  end
  return count
end

Goals.RegisterKind("bingo", {
  label = "SG_KIND_BINGO",
  usage = "SG_USAGE_BINGO",
  color = LT.Theme.COLORS.gold,
  icon = ICON,
  form = { fields = {
    { type = "choice", param = "size", label = "SG_FORM_BINGO_SIZE", values = Bingo.SIZES,
      labels = { [3] = "SG_BINGO_3", [5] = "SG_BINGO_5" } },
  } },
  parse = function(args) return { size = tonumber(args[1]) or Bingo.SIZES[1] }, nil end,
  prepare = function(params)
    params.size = tonumber(params.size) or Bingo.SIZES[1]
    return 1
  end,
  validate = function(params)
    if params.size ~= 3 and params.size ~= FREE_CENTER_SIZE then return L.SG_ERR_BINGO_SIZE end
  end,
  afterCreate = fill,
  hasCount = function() return false end,
  title = function(goal) return string.format(L.SG_GOAL_BINGO, goal.params.size, goal.params.size) end,
  body = function(goal)
    if not goal.params.cells then return nil end
    return string.format(L.SG_BINGO_CELLS, Bingo.DoneCount(goal), #goal.params.cells)
  end,
})

---------------------------------------------------------------------------
-- BINGO erkennen, Schein abschließen oder abbrechen
---------------------------------------------------------------------------
local function closeCells(board)
  for _, id in ipairs(board.params.cells or {}) do
    local cell = id ~= Bingo.FREE and Goals.Get(id)
    if cell and cell.status == Goals.ACTIVE then Goals.Cancel(cell.id) end
  end
end

local function announce(board)
  LT.Alerts.Show(L.SG_BINGO, LT.Theme.COLORS.gold, { immediate = true, sound = true })
  if not ns.db.settings.bingoAnnounce or LT.GroupChat.Locked() then return end
  local channel = LT.GroupChat.PartyChannel()
  if channel then LT.GroupChat.Send(string.format(L.SG_BINGO_ANNOUNCE, Goals.Title(board)), channel) end
end

Goals.OnChange(function(event, goal)
  if not goal then return end
  if goal.kind == "bingo" and (event == "cancelled" or event == "failed") then
    closeCells(goal)
    return
  end
  if event ~= "done" or not goal.cell then return end
  local board = Goals.Get(goal.parentId)
  if not board or board.kind ~= "bingo" or board.status ~= Goals.ACTIVE then return end
  if Bingo.HasLine(board) then
    ns.Debug("bingo", "#%s bingo", board.id)
    Goals.Complete(board)
    closeCells(board)
    announce(board)
  else
    Goals.Changed(board)
  end
end)

---------------------------------------------------------------------------
-- Eigene Texte (Befehle)
---------------------------------------------------------------------------
function Bingo.AddText(text)
  local clean, err = ns.Kinds.CleanText(text, L.SG_ERR_TEXT)
  if not clean then return err end
  local texts = type(ns.db.settings.bingoTexts) == "table" and ns.db.settings.bingoTexts or {}
  if #texts >= Bingo.MAX_TEXTS then return string.format(L.SG_ERR_BINGO_TEXTS, Bingo.MAX_TEXTS) end
  table.insert(texts, clean)
  ns.db.settings.bingoTexts = texts
end

function Bingo.ClearTexts()
  ns.db.settings.bingoTexts = {}
end
