-- Anzeige der laufenden Ziele am Bildschirm: je Ziel eine Karte (Lib/Card.lua von Level Time) mit Titel, Zeile,
-- Stand "12 / 100" und Fortschrittsbalken, untereinander in einem verschiebbaren Rahmen. Höchstens maxCards Karten
-- (Einstellung), weitere Ziele fasst eine Zeile "+n weitere" zusammen. Beim Erreichen eines Ziels erscheint die
-- Einblendung von Level Time (Alerts.Show) und eine Chatzeile (beides abschaltbar).
-- Klicks: Rechtsklick öffnet die Einstellungen der Anzeige; selbst gezählte Ziele (Goals.IsManual) zählt ein
-- Linksklick eins hoch, Shift+Linksklick eins zurück; der abschließende Klick will bestätigt werden (ClickStep.lua).
-- Arten mit tooltip (Item) zeigen beim Überfahren ihren Tooltip.
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
Tracker.SETTINGS_PAGE = ns.SETTINGS_PAGES.TRACKER

local CARD_GAP = 6
local MORE_GAP = 4
local DEFAULT_POSITION = { "TOPRIGHT", "TOPRIGHT", -40, -220 }
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
  ns.ClickStep.Click(card.goal, IsShiftKeyDown())
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

-- Große Zeile der Karte: Stand "4 / 10" und/oder Restzeit der Frist; nil = keine
local function timeLine(goal)
  local count = Goals.HasCount(goal) and Goals.CountText(goal) or nil
  local left = ns.Deadlines.Text(goal)
  if count and left then return count .. "  " .. left end
  return count or left
end

local function fillCard(card, goal)
  local def = Goals.GetKind(goal.kind)
  local line = timeLine(goal)
  card.goal = goal
  card.Set({
    color = Tracker.ColorOf(goal),
    icon = def.icon,
    texture = def.texture and def.texture(goal) or nil,
    title = Goals.Title(goal),
    body = ns.ClickStep.IsArmed(goal) and L.SG_CARD_CONFIRM or Goals.Body(goal),
    time = line ~= nil,
    timeText = line,
  })
  updateCardMouse(card)
  card.frame:Show()
end

-- Jede Sekunde nur die Restzeiten der gezeigten Karten (Texte, kein Neuaufbau)
function Tracker.UpdateTimes()
  if not frame:IsShown() then return end
  for _, card in ipairs(cards) do
    local goal = card.goal
    if goal and goal.deadline and card.frame:IsShown() then card.SetTime(timeLine(goal) or "") end
  end
end
LT.Every(1, Tracker.UpdateTimes, ns.Deadlines.Any)

-- Balken der gezeigten Karten neu (XP im laufenden Level füllt den Balken eines Level-Ziels)
function Tracker.UpdateFractions()
  if not frame:IsShown() then return end
  for _, card in ipairs(cards) do
    if card.goal and card.frame:IsShown() then card.SetFraction(Goals.Fraction(card.goal)) end
  end
end
LT.RegisterEvent("PLAYER_XP_UPDATE", Tracker.UpdateFractions)

-- Ziele mit eigener Karte: laufende ohne Teilziele einer laufenden Checkliste (die stehen als Zeile in ihr)
local shownGoals = {}
local function cardGoals()
  for i = #shownGoals, 1, -1 do shownGoals[i] = nil end
  for _, goal in ipairs(Goals.Active()) do
    if not ns.Checklist.IsNested(goal) then table.insert(shownGoals, goal) end
  end
  return shownGoals
end

-- Karten neu aufbauen: Inhalt aus den Zielen, gleiche Breite, untereinander
function Tracker.Refresh()
  if not ns.db then return end
  local active = cardGoals()
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
  local reward = ns.Rewards.Line(goal)
  Alerts.Show(title, Theme.COLORS.success, {
    notice = { icon = def.icon, texture = def.texture and def.texture(goal) or nil, title = L.SG_NOTICE_DONE,
      body = reward and (title .. "\n" .. reward) or title },
  })
end

-- Gescheitert (Frist, Regel): Chatzeile und Einblendung in der Warnfarbe, ohne Ton
local function announceFailed(goal)
  local settings = ns.db.settings
  local title = Goals.Title(goal)
  if settings.doneChat then ns.Print(string.format(L.SG_CHAT_FAILED, title, goal.failReason or "")) end
  if not settings.doneAlert then return end
  local def = Goals.GetKind(goal.kind)
  Alerts.Show(title, Theme.COLORS.bad, {
    notice = { icon = def.icon, texture = def.texture and def.texture(goal) or nil, title = L.SG_NOTICE_FAILED,
      body = goal.failReason and (title .. "\n" .. goal.failReason) or title },
  })
end

Goals.OnChange(function(event, goal)
  if event == "done" then announceDone(goal) end
  if event == "failed" then announceFailed(goal) end
  Tracker.Refresh()
end)

-- Einstellungen, Sprach- und Theme-Wechsel: Karten neu aufbauen
ns.RegisterApply(Tracker.Refresh)

LT.OnLogin(function()
  LT.Frames.Restore(Tracker.FRAME_ID)  -- StreamGoalDB steht erst jetzt (Core.lua)
end)
