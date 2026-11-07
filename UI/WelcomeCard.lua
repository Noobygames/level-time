-- Willkommenskarte beim ersten Start (Roadmap 363): Voreinstellung der Statistik-Zeilen, Layout des Hauptfensters und
-- der Weg zum Edit-Modus, statt nur einer Chatzeile. Einmal account-weit (LevelTimerStatsDB.introShown, gesetzt von
-- Commands.lua, das nach dieser Datei lädt); später wieder über /lt welcome. Alles wirkt sofort und ist in den
-- Einstellungen änderbar.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Layouts = ns.WindowLayouts

local WelcomeCard = {}
ns.WelcomeCard = WelcomeCard

local MARGIN = 16
local MIN_WIDTH = 360
local TEXT_GAP = 8
local ROW_GAP = 10
local BUTTON_HEIGHT = 22
local BUTTON_MIN_WIDTH = 60
local BUTTON_GAP = 6
local TAB_GAP = 10
local ROW_LABEL_HEIGHT = 16

local panel = Widgets.CreatePanel(ns.GlobalName("Welcome"), 0.95)
panel:SetPoint("CENTER", 0, 80)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, ns.GlobalName("Welcome"))
Widgets.CreateCloseButton(panel)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -MARGIN)
local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
intro:SetPoint("TOPLEFT", MARGIN, -MARGIN - 24)
intro:SetPoint("TOPRIGHT", -MARGIN, -MARGIN - 24)
intro:SetJustifyH("LEFT")

-- Beschriftung einer Zeile und die Zeile darunter
local function rowLabel(anchor)
  local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -ROW_GAP)
  return label
end

-- Zeile 1: Voreinstellungen (wie Statistiken > Voreinstellung)
local presetLabel = rowLabel(intro)
local presetButtons = {}
for i, preset in ipairs(ns.STAT_PRESETS) do
  local button = Widgets.CreateButton(panel, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function() ns.ApplyStatPreset(preset) end)
  button.labelKey = preset.label
  if i == 1 then
    button:SetPoint("TOPLEFT", presetLabel, "BOTTOMLEFT", 0, -TEXT_GAP)
  else
    button:SetPoint("LEFT", presetButtons[i - 1], "RIGHT", BUTTON_GAP, 0)
  end
  presetButtons[i] = button
end

-- Zeile 2: Layout des Hauptfensters (Reiter, aktives hervorgehoben)
local layoutLabel = rowLabel(presetButtons[1])
local layoutTabs = {}
for i, id in ipairs(Layouts.ORDER) do
  local tab = Widgets.CreateTab(panel, "GameFontHighlight", function() ns.Set("windowLayout", id) end)
  tab.layoutId = id
  if i == 1 then
    tab:SetPoint("TOPLEFT", layoutLabel, "BOTTOMLEFT", 0, -TEXT_GAP)
  else
    tab:SetPoint("LEFT", layoutTabs[i - 1], "RIGHT", TAB_GAP, 0)
  end
  layoutTabs[i] = tab
end

-- Zeile 3: Position (Edit-Modus), alle Einstellungen, fertig
local actions = {}
local function addAction(labelKey, onClick)
  local button = Widgets.CreateButton(panel, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, onClick)
  button.labelKey = labelKey
  if #actions == 0 then
    button:SetPoint("BOTTOMLEFT", MARGIN, MARGIN)
  else
    button:SetPoint("LEFT", actions[#actions], "RIGHT", BUTTON_GAP, 0)
  end
  table.insert(actions, button)
end
addAction("WELCOME_EDIT_MODE", function()
  panel:Hide()
  ns.EditMode.Enter()
end)
addAction("WELCOME_SETTINGS", function()
  panel:Hide()
  ns.ShowOptionsPage()
end)
addAction("WELCOME_DONE", function() panel:Hide() end)

local function rowWidth(widgets, gap)
  local width = 0
  for i, widget in ipairs(widgets) do width = width + widget:GetWidth() + (i > 1 and gap or 0) end
  return width
end

-- Texte in der gewählten Sprache, Breite aus den Zeilen (fr/es länger), aktives Layout hervorgehoben
local function refresh(db)
  title:SetText(L.WELCOME_TITLE)
  intro:SetText(L.WELCOME_TEXT)
  presetLabel:SetText(L.WELCOME_PRESETS)
  layoutLabel:SetText(L.WELCOME_LAYOUT)
  for _, button in ipairs(presetButtons) do Widgets.SetButtonText(button, L[button.labelKey], BUTTON_MIN_WIDTH) end
  for _, button in ipairs(actions) do Widgets.SetButtonText(button, L[button.labelKey], BUTTON_MIN_WIDTH) end
  local active = Layouts.Get(db.windowLayout).id
  for _, tab in ipairs(layoutTabs) do
    tab:SetLabel(L[Layouts.Get(tab.layoutId).label])
    tab:SetActive(tab.layoutId == active)
  end
  local width = math.max(MIN_WIDTH, rowWidth(presetButtons, BUTTON_GAP), rowWidth(layoutTabs, TAB_GAP),
    rowWidth(actions, BUTTON_GAP)) + 2 * MARGIN
  panel:SetWidth(width)
  local height = MARGIN + 24 + (intro:GetStringHeight() or 0) + 2 * (ROW_GAP + ROW_LABEL_HEIGHT + TEXT_GAP + BUTTON_HEIGHT)
    + ROW_GAP + BUTTON_HEIGHT + 2 * MARGIN
  panel:SetHeight(height)
end

function WelcomeCard.Show()
  if not ns.db then return end
  refresh(ns.db)
  panel:Show()
end

function WelcomeCard.IsShown()
  return panel:IsShown()
end

ns.RegisterApply(function(db)
  if panel:IsShown() then refresh(db) end
end)

-- Erster Start: Karte statt nur der Willkommenszeile (Commands.lua merkt sich den ersten Start danach)
ns.OnLogin(function()
  if LevelTimerStatsDB.introShown then return end
  WelcomeCard.Show()
end)
