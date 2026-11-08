-- Glücksrad (Roadmap 306, 431, 432): ein Zufallsziel aus dem eigenen Pool des Rads per Befehl/Knopf oder bei jedem
-- Level-Up (settings.wheelOnLevelUp). Pool = alle Einträge aus Pool.lua (mitgelieferte und Vorlagen) außer den
-- abgeschalteten (StreamGoalDB.wheel.pool.off[key] = true; neue Vorlagen sind an). Der Eintrag steht schon beim
-- Start fest, das Rad (WheelDisplay.lua) landet auf ihm; danach wird das Ziel angelegt und auf einer Karte unter dem
-- Rad gezeigt. Neu drehen ersetzt das letzte Ergebnis, höchstens settings.wheelRerolls-mal je Drehung (Knopf im
-- Reiter Glücksrad, Rechtsklick auf die Ergebnis-Karte, /sg wheel reroll).
-- Ergebnis: Rad und Karte bleiben settings.wheelResultSeconds Sekunden stehen (0 = bis Linksklick auf die Karte oder
-- bis zur nächsten Drehung). Rad und Karte liegen beim Drehen über den Fenstern (WheelDisplay.SPIN_STRATA), sonst
-- drehte ein Knopf im Fenster /sg oder in den Einstellungen das Rad unsichtbar dahinter.
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
local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local TOOLTIP_ANCHOR = "ANCHOR_BOTTOM"
local spinning = false
local resultToken = 0   -- jede gezeigte Ergebnis-Karte bekommt eine Nummer; ein alter Ausblend-Timer lässt neue stehen
local listeners = {}

local card = LT.Card.Create("StreamGoalWheelCard")
card.frame:SetFrameStrata(WheelDisplay.SPIN_STRATA)
Wheel.card = card

-- Auf Änderungen reagieren (Drehen beginnt/endet, Ergebnis weg): listener() ohne Argumente
function Wheel.OnChange(listener)
  table.insert(listeners, listener)
end

local function changed()
  for _, listener in ipairs(listeners) do LT.SafeCall(listener) end
end

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

-- Ergebnis ausblenden (Linksklick auf die Karte, Ablauf der Anzeigedauer); während des Drehens nicht
function Wheel.Dismiss()
  if spinning then return end
  resultToken = resultToken + 1
  card.frame:Hide()
  WheelDisplay.Hide()
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
    changed()
    return
  end
  local wheel = state()
  wheel.goalId, wheel.rerollsLeft = goal.id, rerollsLeft
  showCard(goal)
  if rerollsLeft > 0 then
    ns.Print(string.format(L.SG_CHAT_WHEEL, Goals.Title(goal), rerollsLeft))
  else
    ns.Print(string.format(L.SG_CHAT_WHEEL_LAST, Goals.Title(goal)))
  end
  resultToken = resultToken + 1
  local token = resultToken
  local seconds = ns.db.settings.wheelResultSeconds
  if seconds > 0 then
    C_Timer.After(seconds, function()
      if token == resultToken then Wheel.Dismiss() end
    end)
  end
  changed()
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
  resultToken = resultToken + 1
  card.frame:Hide()
  local titles, target = slicesFor(items, chosen)
  changed()
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

-- Neuwürfe für das gezeigte Ergebnis (0 ohne laufendes Ergebnis oder während des Drehens)
function Wheel.RerollsLeft()
  if spinning or not ns.db then return 0 end
  local wheel = state()
  local goal = wheel.goalId and Goals.Get(wheel.goalId)
  if not goal or goal.status ~= Goals.ACTIVE then return 0 end
  return wheel.rerollsLeft or 0
end

-- Ergebnis-Karte: Linksklick blendet aus, Rechtsklick dreht neu (solange Neuwürfe übrig sind)
local function onCardClick(_, mouseButton)
  if mouseButton == "RightButton" then
    local ok, err = Wheel.Reroll()
    if not ok and err then ns.Print(err) end
  else
    Wheel.Dismiss()
  end
end

local function showCardTooltip(owner)
  GameTooltip:SetOwner(owner, TOOLTIP_ANCHOR)
  GameTooltip:SetText(L.SG_WHEEL, LT.Theme.RGB("accent"))
  local r, g, b = LT.Theme.RGB("muted")
  GameTooltip:AddLine(L.SG_WHEEL_CARD_TIP_DISMISS, r, g, b, true)
  local left = Wheel.RerollsLeft()
  if left > 0 then GameTooltip:AddLine(string.format(L.SG_WHEEL_CARD_TIP_REROLL, left), r, g, b, true) end
  GameTooltip:Show()
end

card.frame:EnableMouse(true)
card.frame:SetScript("OnMouseUp", onCardClick)
card.frame:SetScript("OnEnter", showCardTooltip)
card.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Ergebnis-Ziel anderweitig beendet (abgebrochen, erreicht): Knopf "Neu drehen" aktuell halten
Goals.OnChange(function(_, goal)
  if goal and ns.db and goal.id == state().goalId then changed() end
end)

LT.OnLevelStarted(function()
  if ns.db and ns.db.settings.wheelOnLevelUp then
    local ok, err = Wheel.Spin()
    if not ok and err then ns.Print(err) end
  end
end)
