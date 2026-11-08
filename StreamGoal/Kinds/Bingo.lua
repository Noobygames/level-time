-- Zielart Bingo (Roadmap 305, 431): ein Schein mit 3x3 oder 5x5 Feldern (5x5 mit freier Mitte). Jedes Feld ist ein
-- Ziel einer anderen Art (goal.cell, goal.parentId = Schein; belegt keinen der MAX_ACTIVE-Plätze). Felder kann der
-- Spieler selbst wählen (Bingo-Editor im Fenster: Einträge aus Pool.lua, also mitgelieferte und Vorlagen); die
-- übrigen zieht der Schein zufällig aus allen Einträgen des Pools. Eine volle Reihe, Spalte oder Diagonale = BINGO:
-- der Schein ist erreicht, die übrigen Felder werden abgebrochen, große Einblendung, optional eine Ansage in den
-- Gruppenchat (settings.bingoAnnounce).
-- params: { size = 3|5, cells = { [Feld] = Ziel-ID oder FREE }, chosen = { [Feld] = Pool-Schlüssel } }
--   (Felder zeilenweise; chosen nur bei selbst gewählten Feldern, ältere Scheine haben es nicht)
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Pool = ns.Pool
local Library = ns.Library
local L = ns.L

local Bingo = {}
ns.Bingo = Bingo

Bingo.SIZES = { 3, 5 }
Bingo.FREE = 0           -- freies Feld (Mitte bei 5x5)
local ICON = "Interface\\Icons\\INV_Misc_Note_02"
local FREE_CENTER_SIZE = 5
local pendingPicks  -- { [Feld] = Pool-Schlüssel } für den Schein, den Bingo.CreateBoard gerade anlegt

-- Pool gemischt: alle Einträge aus Pool.lua (neue Liste)
function Bingo.ShuffledPool()
  return Pool.Shuffle(Pool.Items())
end

local function cellCount(size)
  return size * size
end

local function isFree(board, index)
  return board.params.size == FREE_CENTER_SIZE and index == math.ceil(cellCount(board.params.size) / 2)
end

-- Freies Feld bei dieser Größe? (Bingo-Editor)
function Bingo.IsFreeCell(size, index)
  return isFree({ params = { size = size } }, index)
end

-- Selbst gewähltes Feld anlegen; nil, wenn der Eintrag fehlt (gelöschte Vorlage) oder abgelehnt wird
local function createPick(board, key)
  local item = Pool.Get(key)
  if not item then return nil end
  local cell, err = Pool.Create(item, board)
  if not cell then ns.Debug("bingo", "pick %s failed: %s", key, err) end
  return cell
end

-- Felder anlegen: erst die selbst gewählten (pendingPicks), dann zufällig aus dem Pool; reicht der Pool nicht (oder
-- lehnt eine Art ab, z.B. schon erreicht), wird weiter gezogen und notfalls wiederholt
local function fill(board)
  local size = board.params.size
  local picks = pendingPicks or {}
  pendingPicks = nil
  local pool = Bingo.ShuffledPool()
  local cells, chosen, cursor, attempts = {}, {}, 1, 0
  for index = 1, cellCount(size) do
    if isFree(board, index) then
      cells[index] = Bingo.FREE
    else
      local cell = picks[index] and createPick(board, picks[index])
      if cell then chosen[index] = picks[index] end
      while not cell and #pool > 0 and attempts < cellCount(size) * 4 do
        local item = pool[(cursor - 1) % #pool + 1]
        cursor, attempts = cursor + 1, attempts + 1
        cell = Pool.Create(item, board)
      end
      cells[index] = cell and cell.id or Bingo.FREE
    end
  end
  board.params.cells = cells
  if next(chosen) then board.params.chosen = chosen end
end

-- Neuer Schein; picks = { [Feld] = Pool-Schlüssel } optional (leere Felder zufällig). Rückgabe wie Goals.Create
function Bingo.CreateBoard(size, picks)
  pendingPicks = picks
  local ok, board, err = pcall(Goals.Create, "bingo", { size = size })
  pendingPicks = nil
  if not ok then error(board) end
  return board, err
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
  group = "fun",
  inForm = false,  -- eigener Reiter "Bingo" im Fenster (Felder selbst wählen oder zufällig)
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
-- Eigene Texte (Befehle /sg bingo text|texts|clear): freie Texte unter den Vorlagen (Library.lua)
---------------------------------------------------------------------------
function Bingo.AddText(text)
  local _, err = Library.AddText(text)
  return err
end

-- Texte der eigenen freien Ziele
function Bingo.Texts()
  local texts = {}
  for _, entry in ipairs(Library.Texts()) do table.insert(texts, entry.params.text) end
  return texts
end

-- Rückgabe: Anzahl gelöschter Texte
function Bingo.ClearTexts()
  return Library.RemoveTexts()
end
