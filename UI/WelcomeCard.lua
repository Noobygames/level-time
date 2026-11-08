-- Willkommenskarte beim ersten Start (Roadmap 363): Voreinstellung der Statistik-Zeilen, Layout des Hauptfensters,
-- Stream-Modus und der Weg zum Edit-Modus, statt nur einer Chatzeile. Jede Wahl erklärt sich im Tooltip, die aktive
-- Voreinstellung und das aktive Layout sind hervorgehoben, der Fuß sagt, wo Historie und Karte wieder zu finden sind
-- (UX S23/S24). Einmal account-weit (Database.IsFirstStart; gemerkt von Commands.lua über Database.TakeFirstStart,
-- das nach dieser Datei lädt); später wieder über /lt welcome. Alles wirkt sofort und ist in den Einstellungen änderbar.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Layouts = ns.WindowLayouts

local WelcomeCard = {}
ns.WelcomeCard = WelcomeCard

local MARGIN = 16
local MIN_WIDTH = 360
local TITLE_HEIGHT = 24
local TEXT_GAP = 8
local ROW_GAP = 10
local BUTTON_HEIGHT = 22
local BUTTON_MIN_WIDTH = 60
local BUTTON_GAP = 6
local TAB_GAP = 10
local ROW_LABEL_HEIGHT = 16
local TAB_HEIGHT = 18     -- Reiter-Zeile (Voreinstellung, Layout)
local CHECK_HEIGHT = 26   -- Zeile mit dem Stream-Schalter
local CHECK_INSET = 4     -- die Checkbox-Vorlage hat links etwas Rand
local FOOTER_GAP = 6      -- Fußtext über den Knöpfen

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
intro:SetPoint("TOPLEFT", MARGIN, -MARGIN - TITLE_HEIGHT)
intro:SetPoint("TOPRIGHT", -MARGIN, -MARGIN - TITLE_HEIGHT)
intro:SetJustifyH("LEFT")

-- Beschriftung einer Zeile und die Zeile darunter
local function rowLabel(anchor)
  local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -ROW_GAP)
  return label
end

-- Reiter nebeneinander unter einer Beschriftung, je einer für jedes Element von items
local function addTabRow(label, items, onClick)
  local tabs = {}
  for i, item in ipairs(items) do
    local tab = Widgets.CreateTab(panel, "GameFontHighlight", function() onClick(item) end)
    tab.item = item
    if i == 1 then
      tab:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -TEXT_GAP)
    else
      tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", TAB_GAP, 0)
    end
    tabs[i] = tab
  end
  return tabs
end

-- Zeile 1: Voreinstellungen (wie Statistiken > Voreinstellung); der Tooltip sagt, welche Zeilen an sind
local presetLabel = rowLabel(intro)
local presetTabs = addTabRow(presetLabel, ns.STAT_PRESETS, function(preset) ns.ApplyStatPreset(preset) end)
for _, tab in ipairs(presetTabs) do
  Widgets.AttachTooltip(tab, function() return L[tab.item.label] end, function() return L[tab.item.label .. "_TIP"] end)
end

-- Zeile 2: Layout des Hauptfensters; der Tooltip beschreibt es
local layoutLabel = rowLabel(presetTabs[1])
local layoutTabs = addTabRow(layoutLabel, Layouts.ORDER, function(id) ns.Set("windowLayout", id) end)
for _, tab in ipairs(layoutTabs) do
  local labelKey = Layouts.Get(tab.item).label
  Widgets.AttachTooltip(tab, function() return L[labelKey] end, function() return L[labelKey .. "_TIP"] end)
end

-- Zeile 3: Stream-Modus (wie Allgemein > Stream)
local streamLabel = rowLabel(layoutTabs[1])
local streamCheck = Widgets.CreateCheckbox(panel, function(checked) ns.StreamMode.SetEnabled(checked) end)
streamCheck:SetPoint("TOPLEFT", streamLabel, "BOTTOMLEFT", -CHECK_INSET, -2)
Widgets.AttachTooltip(streamCheck, function() return L.STREAM_MODE end, function() return L.STREAM_MODE_TIP end)

-- Fuß über den Knöpfen: wo man Historie und diese Karte wiederfindet
local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
footer:SetTextColor(unpack(Widgets.COLORS.muted))
footer:SetJustifyH("LEFT")
footer:SetPoint("BOTTOMLEFT", MARGIN, MARGIN + BUTTON_HEIGHT + FOOTER_GAP)
footer:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN + BUTTON_HEIGHT + FOOTER_GAP)

-- Knöpfe: Position (Edit-Modus), alle Einstellungen, fertig
local actions = {}
local function addAction(labelKey, onClick)
  local button = Widgets.CreateButton(panel, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, onClick)
  button.labelKey = labelKey
  if #actions == 0 then
    button:SetPoint("BOTTOMLEFT", MARGIN, MARGIN)
  else
    button:SetPoint("LEFT", actions[#actions], "RIGHT", BUTTON_GAP, 0)
  end
  Widgets.AttachTooltip(button, function() return L[labelKey] end, function() return L[labelKey .. "_TIP"] end)
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

-- Reiter beschriften und den aktiven hervorheben
local function refreshTabs(tabs, labelOf, active)
  for _, tab in ipairs(tabs) do
    tab:SetLabel(L[labelOf(tab.item)])
    tab:SetActive(tab.item == active)
  end
end

-- Texte in der gewählten Sprache, Breite aus den Zeilen (fr/es länger), aktive Wahl hervorgehoben
local function refresh(db)
  title:SetText(L.WELCOME_TITLE)
  intro:SetText(L.WELCOME_TEXT)
  presetLabel:SetText(L.WELCOME_PRESETS)
  layoutLabel:SetText(L.WELCOME_LAYOUT)
  streamLabel:SetText(L.WELCOME_STREAM)
  streamCheck.label:SetText(L.STREAM_MODE)
  streamCheck:SetChecked(ns.StreamMode.IsEnabled())
  streamCheck:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + (streamCheck.label:GetStringWidth() or 0)), 0, 0)
  footer:SetText(L.WELCOME_FOOTER)
  for _, button in ipairs(actions) do Widgets.SetButtonText(button, L[button.labelKey], BUTTON_MIN_WIDTH) end
  refreshTabs(presetTabs, function(preset) return preset.label end, ns.ActiveStatPreset(db))
  refreshTabs(layoutTabs, function(id) return Layouts.Get(id).label end, Layouts.Get(db.windowLayout).id)
  local width = math.max(MIN_WIDTH, rowWidth(presetTabs, TAB_GAP), rowWidth(layoutTabs, TAB_GAP),
    rowWidth(actions, BUTTON_GAP)) + 2 * MARGIN
  panel:SetWidth(width)
  local rows = 2 * (ROW_GAP + ROW_LABEL_HEIGHT + TEXT_GAP + TAB_HEIGHT) + ROW_GAP + ROW_LABEL_HEIGHT + CHECK_HEIGHT
  local height = MARGIN + TITLE_HEIGHT + (intro:GetStringHeight() or 0) + rows + ROW_GAP
    + (footer:GetStringHeight() or 0) + FOOTER_GAP + BUTTON_HEIGHT + 2 * MARGIN
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

-- Test-Zugriff: Reiter der Voreinstellungen und Layouts, Stream-Schalter
function WelcomeCard.Widgets()
  return { presets = presetTabs, layouts = layoutTabs, stream = streamCheck, footer = footer }
end

ns.RegisterApply(function(db)
  if panel:IsShown() then refresh(db) end
end)

-- Erster Start: Karte statt nur der Willkommenszeile (Commands.lua merkt sich den ersten Start danach)
ns.OnLogin(function()
  if not ns.Database.IsFirstStart() then return end
  WelcomeCard.Show()
end)
