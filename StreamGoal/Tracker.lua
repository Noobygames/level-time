-- Anzeige der laufenden Ziele am Bildschirm: je Ziel eine Karte (Lib/Card.lua von Level Time) mit Titel, Zeile,
-- Stand "12 / 100" und Fortschrittsbalken, untereinander in einem verschiebbaren Rahmen. Höchstens maxCards Karten
-- (Einstellung), weitere Ziele fasst eine Zeile "+n weitere" zusammen. Beim Erreichen eines Ziels erscheint die
-- Einblendung von Level Time (Alerts.Show) und eine Chatzeile (beides abschaltbar).
-- Klicks: Rechtsklick öffnet die Einstellungen der Anzeige; selbst gezählte Ziele (Goals.IsManual) zählt ein
-- Linksklick eins hoch, Shift+Linksklick eins zurück. Arten mit tooltip (Item) zeigen beim Überfahren ihren Tooltip.
-- Farben und Schriften kommen aus dem Theme von Level Time (Karten melden sich in Card.Create selbst an).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L
local Card = LT.Card
local Widgets = LT.Widgets
local Alerts = LT.Alerts
local Theme = LT.Theme

local Tracker = {}
ns.Tracker = Tracker

Tracker.FRAME_ID = "streamGoal"
Tracker.SETTINGS_PAGE = "SG_OPTIONS_PAGE_TRACKER"

local CARD_GAP = 6
local MORE_GAP = 4
local DEFAULT_POSITION = { "TOPRIGHT", "TOPRIGHT", -40, -220 }
local STEP_UP, STEP_DOWN = 1, -1
local TOOLTIP_ANCHOR = "ANCHOR_LEFT"  -- Karten stehen meist am rechten Rand
local SAMPLE_LEVEL, SAMPLE_PROGRESS, SAMPLE_FRACTION = 20, 12, 0.6

local frame = CreateFrame("Frame", "StreamGoalTracker", UIParent)
frame:SetSize(1, 1)
frame:Hide()
Tracker.frame = frame

-- "+2 weitere Ziele" unter der letzten Karte, wenn maxCards nicht alle zeigt
local moreText = frame:CreateFontString(nil, "OVERLAY", Theme.Font("small", true))
moreText:SetJustifyH("LEFT")
moreText:Hide()
Tracker.moreText = moreText

local cards = {}  -- eine Karte je Platz, wird wiederverwendet; card.goal = gezeigtes Ziel (nil = Beispielkarte)
local editing = false  -- Edit-Modus von Level Time: Karten nehmen keine Klicks, ohne Ziele eine Beispielkarte

-- Farbe einer Karte: die der Zielart oder für alle die Akzentfarbe des Themes (Einstellung cardColors)
function Tracker.ColorOf(goal)
  if ns.db and ns.db.settings.cardColors == "accent" then return Theme.COLORS.accent end
  return Goals.GetKind(goal.kind).color
end

function Tracker.ToggleSettings()
  LT.ToggleOptionsPage(Tracker.SETTINGS_PAGE)
end

-- Klick auf eine Karte: rechts Einstellungen, links (selbst gezählt) zählen
local function onCardClick(card, mouseButton)
  if editing then return end
  if mouseButton == "RightButton" then
    Tracker.ToggleSettings()
    return
  end
  local goal = card.goal
  if not goal or not Goals.IsManual(goal) then return end
  Goals.Step(goal.id, IsShiftKeyDown() and STEP_DOWN or STEP_UP)
end

-- Tooltip einer Karte: der der Zielart (Item) bzw. der Titel, dazu die Klicks
local function showCardTooltip(owner, goal)
  if not goal then return end
  local def = Goals.GetKind(goal.kind)
  GameTooltip:SetOwner(owner, TOOLTIP_ANCHOR)
  if def.tooltip then
    def.tooltip(goal, GameTooltip)
  else
    GameTooltip:SetText(Goals.Title(goal), Theme.RGB("accent"))
  end
  local r, g, b = Theme.RGB("muted")
  if Goals.IsManual(goal) then
    GameTooltip:AddLine(Goals.HasCount(goal) and L.SG_CARD_TIP_COUNT or L.SG_CARD_TIP_DONE, r, g, b, true)
  end
  GameTooltip:AddLine(L.SG_CARD_TIP_SETTINGS, r, g, b, true)
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

-- Karten nehmen die Maus (Rechtsklick = Einstellungen), im Edit-Modus nicht (dort zieht der Edit-Modus)
local function updateCardMouse(card)
  card.frame:EnableMouse(card.goal ~= nil and not editing)
end

local function hideCardsFrom(first)
  for i = first, #cards do
    cards[i].goal = nil
    cards[i].frame:Hide()
  end
end

-- Karten untereinander stapeln (gleiche Breite), darunter "+n weitere"; setzt die Größe des Rahmens
local function stack(count, hidden)
  local width, height = 0, 0
  for i = 1, count do width = math.max(width, cards[i].frame:GetWidth()) end
  for i = 1, count do
    local card = cards[i]
    card.frame:SetWidth(width)
    card.frame:ClearAllPoints()
    if i == 1 then
      card.frame:SetPoint("TOPLEFT", frame, "TOPLEFT")
    else
      card.frame:SetPoint("TOPLEFT", cards[i - 1].frame, "BOTTOMLEFT", 0, -CARD_GAP)
    end
    height = height + card.frame:GetHeight() + (i > 1 and CARD_GAP or 0)
  end
  moreText:SetShown(hidden > 0)
  if hidden > 0 then
    moreText:SetText(string.format(L.SG_MORE_GOALS, hidden))
    moreText:ClearAllPoints()
    moreText:SetPoint("TOPLEFT", cards[count].frame, "BOTTOMLEFT", 0, -MORE_GAP)
    height = height + MORE_GAP + (moreText:GetStringHeight() or 0)
  end
  frame:SetSize(width, height)
end

local function fillCard(card, goal)
  local def = Goals.GetKind(goal.kind)
  local counted = Goals.HasCount(goal)
  card.goal = goal
  card.Set({
    color = Tracker.ColorOf(goal),
    icon = def.icon,
    texture = def.texture and def.texture(goal) or nil,
    title = Goals.Title(goal),
    body = Goals.Body(goal),
    time = counted,
  })
  if counted then card.SetTime(Goals.CountText(goal)) end
  updateCardMouse(card)
  card.frame:Show()
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
  local count = visible and math.min(#active, ns.db.settings.maxCards) or 0
  hideCardsFrom(count + 1)
  if not visible then
    moreText:Hide()
    return
  end
  for i = 1, count do fillCard(cardAt(i), active[i]) end
  stack(count, #active - count)
  for i = 1, count do cards[i].SetFraction(Goals.Fraction(active[i])) end
end

---------------------------------------------------------------------------
-- Position und Größe
---------------------------------------------------------------------------
-- Über den Positions-Speicher von Level Time (Lib/Frames.lua); gespeichert in StreamGoalDB.settings.frame
LT.Frames.Register({
  id = Tracker.FRAME_ID, frame = frame, label = "SG_EDIT_FRAME", default = DEFAULT_POSITION,
  settingsPage = Tracker.SETTINGS_PAGE,  -- Knopf "Einstellungen" im Edit-Modus (Options.lua meldet die Seite an)
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

-- Beispielkarte für den Edit-Modus ohne laufende Ziele
function Tracker.ShowSample()
  hideCardsFrom(2)
  local card = cardAt(1)
  card.goal = nil
  updateCardMouse(card)
  card.Set({ color = Theme.COLORS.accent, icon = Alerts.ICONS.levelUp,
    title = string.format(L.SG_GOAL_LEVEL, SAMPLE_LEVEL), time = true })
  card.SetTime(string.format("%d / %d", SAMPLE_PROGRESS, SAMPLE_LEVEL))
  card.frame:Show()
  stack(1, 0)
  card.SetFraction(SAMPLE_FRACTION)
  frame:Show()
end

function Tracker.SetScale(scale)
  LT.Frames.SetScale(Tracker.FRAME_ID, scale)
  return LT.Frames.GetScale(Tracker.FRAME_ID)
end

function Tracker.SetShown(shown)
  ns.SetSetting("showTracker", shown and true or false)
end

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------
-- Abschluss melden: Chatzeile, Ton (eigene Einstellung, nicht alertSound von Level Time) und Einblendung
local function announceDone(goal)
  local settings = ns.db.settings
  local title = Goals.Title(goal)
  if settings.doneChat then ns.Print(string.format(L.SG_CHAT_DONE, title)) end
  if settings.sound then Alerts.PlaySound() end
  if not settings.doneAlert then return end
  local def = Goals.GetKind(goal.kind)
  Alerts.Show(title, Theme.COLORS.success, {
    notice = { icon = def.icon, texture = def.texture and def.texture(goal) or nil, title = L.SG_NOTICE_DONE,
      body = title },
  })
end

Goals.OnChange(function(event, goal)
  if event == "done" then announceDone(goal) end
  Tracker.Refresh()
end)

-- Einstellungen, Sprach- und Theme-Wechsel: Karten neu aufbauen
ns.RegisterApply(Tracker.Refresh)

LT.OnLogin(function()
  LT.Frames.Restore(Tracker.FRAME_ID)  -- StreamGoalDB steht erst jetzt (Core.lua)
end)
