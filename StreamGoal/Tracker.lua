-- Anzeige der laufenden Ziele am Bildschirm: je Ziel eine Karte (Lib/Card.lua von Level Time) mit Titel, Zeile,
-- Stand "12 / 100" und Fortschrittsbalken, untereinander in einem verschiebbaren Rahmen. Beim Erreichen eines
-- Ziels erscheint die Einblendung von Level Time (Alerts.Show) und eine Chatzeile.
-- Selbst gezählte Ziele (Goals.IsManual): Linksklick auf die Karte zählt eins hoch, Rechtsklick eins zurück.
-- Arten mit tooltip (Item) zeigen beim Überfahren der Karte ihren Tooltip (z.B. den des Items).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L
local Card = LT.Card
local Widgets = LT.Widgets
local Alerts = LT.Alerts

local Tracker = {}
ns.Tracker = Tracker

local CARD_GAP = 6
local DEFAULT_POSITION = { "TOPRIGHT", "TOPRIGHT", -40, -220 }
local DONE_COLOR = LT.Theme.COLORS.success

local frame = CreateFrame("Frame", "StreamGoalTracker", UIParent)
frame:SetSize(1, 1)
frame:Hide()
Tracker.frame = frame

local STEP_UP, STEP_DOWN = 1, -1
local TOOLTIP_ANCHOR = "ANCHOR_LEFT"  -- Karten stehen meist am rechten Rand

local cards = {}  -- eine Karte je Platz, wird wiederverwendet; card.goal = gezeigtes Ziel (nil = Beispielkarte)
local editing = false  -- Edit-Modus von Level Time: Karten nehmen keine Klicks, ohne Ziele eine Beispielkarte

-- Klick auf die Karte eines selbst gezählten Ziels
local function onCardClick(card, mouseButton)
  local goal = card.goal
  if not goal or not Goals.IsManual(goal) or editing then return end
  Goals.Step(goal.id, mouseButton == "RightButton" and STEP_DOWN or STEP_UP)
end

-- Tooltip einer Karte: der der Zielart (Item), sonst bei selbst gezählten Zielen der Hinweis zu den Klicks
local function showCardTooltip(owner, goal)
  if not goal then return end
  local def = Goals.GetKind(goal.kind)
  if not def.tooltip and not Goals.IsManual(goal) then return end
  GameTooltip:SetOwner(owner, TOOLTIP_ANCHOR)
  if def.tooltip then
    def.tooltip(goal, GameTooltip)
  else
    GameTooltip:SetText(Goals.Title(goal), unpack(Widgets.COLORS.highlight))
    GameTooltip:AddLine(Goals.HasCount(goal) and L.SG_CARD_TIP_COUNT or L.SG_CARD_TIP_DONE, 1, 1, 1, true)
  end
  GameTooltip:Show()
end

local function cardAt(index)
  if not cards[index] then
    local card = Card.Create("StreamGoalCard" .. index)
    card.frame:SetParent(frame)
    card.frame:SetScript("OnMouseUp", function(_, mouseButton) onCardClick(card, mouseButton) end)
    card.frame:SetScript("OnEnter", function(self) showCardTooltip(self, card.goal) end)
    card.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cards[index] = card
  end
  return cards[index]
end

-- Nur Karten mit Klick oder Tooltip nehmen die Maus an (die anderen lassen sie zur Spielwelt durch); im
-- Edit-Modus keine
local function updateCardMouse(card)
  local goal = card.goal
  local interactive = goal ~= nil and (Goals.IsManual(goal) or Goals.GetKind(goal.kind).tooltip ~= nil)
  card.frame:EnableMouse(interactive and not editing)
end

-- Karten neu aufbauen: Inhalt aus den Zielen, gleiche Breite, untereinander
function Tracker.Refresh()
  if not ns.db then return end
  local active = Goals.Active()
  if editing and #active == 0 then
    Tracker.ShowSample()  -- etwas zum Greifen im Edit-Modus
    return
  end
  local visible = (ns.db.settings.showTracker or editing) and #active > 0
  frame:SetShown(visible)
  for i = #active + 1, #cards do
    cards[i].goal = nil
    cards[i].frame:Hide()
  end
  if not visible then return end

  local width, height = 0, 0
  for i, goal in ipairs(active) do
    local def = Goals.GetKind(goal.kind)
    local card = cardAt(i)
    local counted = Goals.HasCount(goal)
    card.goal = goal
    card.Set({
      color = def.color,
      icon = def.icon,
      texture = def.texture and def.texture(goal) or nil,
      title = def.title(goal),
      body = def.body and def.body(goal) or nil,
      time = counted,
    })
    if counted then card.SetTime(string.format("%d / %d", goal.progress, goal.target)) end
    updateCardMouse(card)
    card.frame:Show()
    width = math.max(width, card.frame:GetWidth())
  end
  for i, goal in ipairs(active) do
    local card = cards[i]
    card.frame:SetWidth(width)
    card.SetFraction(Goals.Fraction(goal))
    card.frame:ClearAllPoints()
    if i == 1 then
      card.frame:SetPoint("TOPLEFT", frame, "TOPLEFT")
    else
      card.frame:SetPoint("TOPLEFT", cards[i - 1].frame, "BOTTOMLEFT", 0, -CARD_GAP)
    end
    height = height + card.frame:GetHeight() + (i > 1 and CARD_GAP or 0)
  end
  frame:SetSize(width, height)
end

---------------------------------------------------------------------------
-- Position und Größe
---------------------------------------------------------------------------
-- Über den Positions-Speicher von Level Time (Lib/Frames.lua); gespeichert in StreamGoalDB.settings.frame
LT.Frames.Register({
  id = "streamGoal", frame = frame, label = "SG_EDIT_FRAME", default = DEFAULT_POSITION,
  store = {
    get = function() return ns.db and ns.db.settings.frame end,
    set = function(entry) ns.db.settings.frame = entry end,
  },
  preview = function(on)
    editing = on
    Tracker.Refresh()
  end,
  hide = function() Tracker.SetShown(false) end,
})

function Tracker.ShowSample()
  local card = cardAt(1)
  card.goal = nil
  updateCardMouse(card)
  card.Set({ color = LT.Theme.COLORS.accent, icon = Alerts.ICONS.levelUp,
    title = string.format(L.SG_GOAL_LEVEL, 20), time = true })
  card.SetTime("12 / 20")
  card.frame:Show()
  card.frame:ClearAllPoints()
  card.frame:SetPoint("TOPLEFT", frame, "TOPLEFT")
  frame:SetSize(card.frame:GetWidth(), card.frame:GetHeight())
  card.SetFraction(0.6)
  frame:Show()
end

function Tracker.SetScale(scale)
  LT.Frames.SetScale("streamGoal", scale)
  return LT.Frames.GetScale("streamGoal")
end

function Tracker.SetShown(shown)
  ns.db.settings.showTracker = shown and true or false
  Tracker.Refresh()
end

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------
Goals.OnChange(function(event, goal)
  if event == "done" then
    local title = Goals.Title(goal)
    ns.Print(string.format(L.SG_CHAT_DONE, title))
    -- Ton hängt an der eigenen Einstellung, nicht an alertSound von Level Time (Standard aus)
    if ns.db.settings.sound then Alerts.PlaySound() end
    local def = Goals.GetKind(goal.kind)
    Alerts.Show(title, DONE_COLOR, {
      notice = { icon = def.icon, texture = def.texture and def.texture(goal) or nil, title = L.SG_NOTICE_DONE,
        body = title },
    })
  end
  Tracker.Refresh()
end)

-- Sprachwechsel in Level Time: Karten neu aufbauen
LT.RegisterApply(Tracker.Refresh)

LT.OnLogin(function()
  LT.Frames.Restore("streamGoal")  -- StreamGoalDB steht erst jetzt (Core.lua)
  Tracker.Refresh()
end)
