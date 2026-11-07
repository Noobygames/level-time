-- Glücksrad (Roadmap 306): ein Zufallsziel aus dem Pool von Bingo (Ziele relativ zum Level und eigene Texte, siehe
-- Kinds/Bingo.lua) per Befehl/Knopf oder bei jedem Level-Up (settings.wheelOnLevelUp). Vor dem Ergebnis läuft eine
-- kurze Dreh-Animation auf einer eigenen Karte (Lib/Card.lua, an der Stelle des Trackers): SPIN_STEPS Titel nacheinander
-- mit wachsender Pause über C_Timer (kein OnUpdate). Neu drehen ersetzt das letzte Ergebnis, höchstens
-- settings.wheelRerolls-mal je Drehung. Stand in StreamGoalDB.wheel = { goalId, rerollsLeft }.
-- Offen: Abstimmung der Zuschauer (Twitch-Chat ist für Addons nicht lesbar).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L

local Wheel = {}
ns.Wheel = Wheel

Wheel.MAX_REROLLS = 5
local SPIN_STEPS = 8
local FIRST_DELAY = 0.08
local DELAY_GROWTH = 1.35
local RESULT_SECONDS = 2
local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local spinning = false

local card = LT.Card.Create("StreamGoalWheelCard")
card.frame:SetFrameStrata("HIGH")
Wheel.card = card

local function state()
  ns.db.wheel = type(ns.db.wheel) == "table" and ns.db.wheel or {}
  return ns.db.wheel
end

-- Titel eines Pool-Eintrags ohne Ziel anzulegen (für die Animation)
local function entryTitle(entry)
  local def = Goals.GetKind(entry.kind)
  local preview = { kind = entry.kind, params = Goals.CopyFlat(entry.params), target = entry.target or 1, progress = 0,
    start = 0 }
  if def.prepare then preview.target = def.prepare(preview.params, preview.target) or preview.target end
  local ok, title = pcall(def.title, preview)
  return ok and title or L[def.label]
end

local function showCard(title, done)
  card.Set({ color = done and LT.Theme.COLORS.success or LT.Theme.COLORS.gold, icon = ICON, title = L.SG_WHEEL,
    body = title })
  card.frame:ClearAllPoints()
  card.frame:SetPoint("TOPRIGHT", ns.Tracker.frame, "TOPLEFT", -8, 0)
  card.frame:Show()
end

-- Erstes Pool-Ergebnis, das sich anlegen lässt (schon erreichte Ziele lehnt die Art ab)
local function createFrom(pool)
  local lastError
  for _, entry in ipairs(pool) do
    local goal, err = Goals.Create(entry.kind, Goals.CopyFlat(entry.params), entry.target)
    if goal then return goal end
    lastError = err
    if Goals.UsedSlots() >= Goals.MAX_ACTIVE then break end
  end
  return nil, lastError
end

-- Drehen; rerolls = verbleibende Neuwürfe für diese Drehung. Rückgabe: false und Fehlertext, wenn nicht möglich
local function spin(rerollsLeft)
  if spinning then return false, L.SG_WHEEL_BUSY end
  if Goals.UsedSlots() >= Goals.MAX_ACTIVE then return false, string.format(L.SG_ERR_TOO_MANY, Goals.MAX_ACTIVE) end
  local pool = ns.Bingo.ShuffledPool()
  if #pool == 0 then return false, L.SG_WHEEL_EMPTY end
  spinning = true
  local step, delay = 0, FIRST_DELAY
  local function tick()
    step = step + 1
    if step <= SPIN_STEPS then
      showCard(entryTitle(pool[(step - 1) % #pool + 1]), false)
      delay = delay * DELAY_GROWTH
      C_Timer.After(delay, tick)
      return
    end
    spinning = false
    local goal, err = createFrom(pool)
    if not goal then
      card.frame:Hide()
      ns.Print(err or L.SG_WHEEL_EMPTY)
      return
    end
    local wheel = state()
    wheel.goalId, wheel.rerollsLeft = goal.id, rerollsLeft
    showCard(Goals.Title(goal), true)
    ns.Print(string.format(L.SG_CHAT_WHEEL, Goals.Title(goal), rerollsLeft))
    C_Timer.After(RESULT_SECONDS, function() if not spinning then card.frame:Hide() end end)
  end
  tick()
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
