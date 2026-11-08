-- Glücksrad (Roadmap 306, 431, 432): ein Zufallsziel aus dem eigenen Pool des Rads per Befehl/Knopf oder bei jedem
-- Level-Up (settings.wheelOnLevelUp). Pool = alle Einträge aus Pool.lua (mitgelieferte und eigene Ziele) außer den
-- abgeschalteten (StreamGoalDB.wheel.pool.off[key] = true; neue eigene Ziele sind an). Der Eintrag steht schon beim
-- Start fest, das Rad (WheelDisplay.lua) landet auf ihm; danach wird das Ziel angelegt und auf einer Karte unter dem
-- Rad gezeigt. Neu drehen ersetzt das letzte Ergebnis, höchstens settings.wheelRerolls-mal je Drehung.
-- Stand in StreamGoalDB.wheel = { goalId, rerollsLeft, pool = { off = { [key] = true } } } (fehlende Felder erlaubt).
-- Offen: Abstimmung der Zuschauer (Twitch-Chat ist für Addons nicht lesbar).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Pool = ns.Pool
local WheelDisplay = ns.WheelDisplay
local L = ns.L

local Wheel = {}
ns.Wheel = Wheel

Wheel.MAX_REROLLS = 5
local RESULT_SECONDS = 3
local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local spinning = false

local card = LT.Card.Create("StreamGoalWheelCard")
card.frame:SetFrameStrata("HIGH")
Wheel.card = card

local function state()
  ns.db.wheel = type(ns.db.wheel) == "table" and ns.db.wheel or {}
  local wheel = ns.db.wheel
  wheel.pool = type(wheel.pool) == "table" and wheel.pool or {}
  wheel.pool.off = type(wheel.pool.off) == "table" and wheel.pool.off or {}
  return wheel
end

---------------------------------------------------------------------------
-- Pool des Rads
---------------------------------------------------------------------------
function Wheel.IsEnabled(key)
  return not state().pool.off[key]
end

function Wheel.SetEnabled(key, enabled)
  state().pool.off[key] = (not enabled) or nil
end

-- Eingeschaltete Einträge, gemischt (neue Liste)
function Wheel.Pool()
  local items = {}
  for _, item in ipairs(Pool.Items()) do
    if Wheel.IsEnabled(item.key) then table.insert(items, item) end
  end
  return Pool.Shuffle(items)
end

---------------------------------------------------------------------------
-- Drehen
---------------------------------------------------------------------------
local function showCard(goal)
  card.Set({ color = LT.Theme.COLORS.success, icon = ICON, title = L.SG_WHEEL, body = Goals.Title(goal) })
  card.frame:ClearAllPoints()
  card.frame:SetPoint("TOP", WheelDisplay.frame, "BOTTOM", 0, -6)
  card.frame:Show()
end

-- Erster Eintrag, der die Prüfung besteht (schon erreichte Ziele lehnt erst Goals.Create ab)
local function pick(items)
  local lastError
  for index, item in ipairs(items) do
    local err = Goals.Check(item.kind, item.params, item.target)
    if not err then return index end
    lastError = err
  end
  return nil, lastError
end

-- Stücke des Rads: die ersten SLICES Einträge (der gezogene ist dabei), bei weniger reihum wiederholt.
-- Rückgabe: Titel je Stück und ein Stück des gezogenen Eintrags (zufällig unter seinen Wiederholungen)
local function slicesFor(items, chosen)
  local shown = { items[chosen] }
  for index, item in ipairs(items) do
    if index ~= chosen and #shown < WheelDisplay.SLICES then table.insert(shown, item) end
  end
  Pool.Shuffle(shown)
  local titles, hits = {}, {}
  for slice = 1, WheelDisplay.SLICES do
    local item = shown[(slice - 1) % #shown + 1]
    titles[slice] = Pool.Title(item)
    if item == items[chosen] then table.insert(hits, slice) end
  end
  return titles, hits[math.random(#hits)]
end

-- Gezogenen Eintrag anlegen; scheitert er (z.B. Bestand schon erreicht), der nächste anlegbare
local function createResult(items, chosen)
  local goal, err = Pool.Create(items[chosen])
  if goal then return goal end
  for index, item in ipairs(items) do
    if index ~= chosen then
      goal = Pool.Create(item)
      if goal then return goal end
      if Goals.UsedSlots() >= Goals.MAX_ACTIVE then break end
    end
  end
  return nil, err
end

local function finish(items, chosen, rerollsLeft)
  spinning = false
  local goal, err = createResult(items, chosen)
  if not goal then
    WheelDisplay.Hide()
    ns.Print(err or L.SG_WHEEL_EMPTY)
    return
  end
  local wheel = state()
  wheel.goalId, wheel.rerollsLeft = goal.id, rerollsLeft
  showCard(goal)
  ns.Print(string.format(L.SG_CHAT_WHEEL, Goals.Title(goal), rerollsLeft))
  C_Timer.After(RESULT_SECONDS, function()
    if spinning then return end
    card.frame:Hide()
    WheelDisplay.Hide()
  end)
end

-- Drehen; rerollsLeft = verbleibende Neuwürfe für diese Drehung. Rückgabe: false und Fehlertext, wenn nicht möglich
local function spin(rerollsLeft)
  if spinning then return false, L.SG_WHEEL_BUSY end
  if Goals.UsedSlots() >= Goals.MAX_ACTIVE then return false, string.format(L.SG_ERR_TOO_MANY, Goals.MAX_ACTIVE) end
  local items = Wheel.Pool()
  if #items == 0 then return false, L.SG_WHEEL_EMPTY end
  local chosen, err = pick(items)
  if not chosen then return false, err end
  ns.Debug("wheel", "pick %s", items[chosen].key)
  spinning = true
  card.frame:Hide()
  local titles, target = slicesFor(items, chosen)
  WheelDisplay.Spin(titles, target, function() finish(items, chosen, rerollsLeft) end)
  return true
end

function Wheel.Spin()
  return spin(ns.db.settings.wheelRerolls)
end

-- Letztes Ergebnis verwerfen (abbrechen) und neu drehen, solange Neuwürfe übrig sind
function Wheel.Reroll()
  local wheel = state()
  local goal = wheel.goalId and Goals.Get(wheel.goalId)
  if not goal or goal.status ~= Goals.ACTIVE then return false, L.SG_WHEEL_NOTHING end
  if (wheel.rerollsLeft or 0) <= 0 then return false, L.SG_WHEEL_NO_REROLLS end
  if spinning then return false, L.SG_WHEEL_BUSY end
  Goals.Cancel(goal.id)
  wheel.goalId = nil
  return spin(wheel.rerollsLeft - 1)
end

function Wheel.IsSpinning()
  return spinning
end

LT.OnLevelStarted(function()
  if ns.db and ns.db.settings.wheelOnLevelUp then
    local ok, err = Wheel.Spin()
    if not ok and err then ns.Print(err) end
  end
end)
