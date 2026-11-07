-- Eintrag "Level Time" in Blizzards Einstellungsmenü (Esc > Optionen > AddOns): kurzer Text und ein Button, der das
-- eigene Einstellungsfenster öffnet (Roadmap 403). Geprüft in Gethe/wow-ui-source (live, classic_era,
-- classic_anniversary, forever): alle vier laden Blizzard_Settings_Shared beim Start (nicht bei Bedarf) und haben
-- Settings.RegisterCanvasLayoutCategory(frame, name) und Settings.RegisterAddOnCategory(category); ältere Clients
-- ohne Settings bekommen InterfaceOptions_AddCategory(frame) mit frame.name.
-- Kein Taint: SettingsPanel wird nie angefasst (kein Close/HideUIPanel aus unserem Code, das liefe Blizzards Commit
-- mit Speichern der Tastenbelegung über unseren Pfad). Unser Fenster liegt in Strata DIALOG über dem Panel (HIGH)
-- und schließt mit Esc zuerst.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local BlizzardSettings = {}
ns.BlizzardSettings = BlizzardSettings

local MARGIN = 16
local TEXT_WIDTH = 520
local BUTTON_MIN_WIDTH = 200
local BUTTON_HEIGHT = 24

local canvas = CreateFrame("Frame")
canvas.name = ns.DISPLAY_NAME  -- InterfaceOptions_AddCategory liest den Namen aus dem Frame
canvas:Hide()

local title = canvas:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", MARGIN, -MARGIN)

local text = canvas:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -MARGIN / 2)
text:SetWidth(TEXT_WIDTH)
text:SetJustifyH("LEFT")

local openButton = Widgets.CreateButton(canvas, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
  ns.ShowOptionsPage()
end)
openButton:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -MARGIN)
BlizzardSettings.openButton = openButton

-- Texte in der gewählten Sprache, sobald Blizzard die Seite zeigt
canvas:SetScript("OnShow", function()
  title:SetText(ns.DISPLAY_NAME)
  text:SetText(L.BLIZZARD_SETTINGS_TEXT)
  Widgets.SetButtonText(openButton, L.BLIZZARD_SETTINGS_OPEN, BUTTON_MIN_WIDTH)
end)
BlizzardSettings.canvas = canvas

-- Anmelden; nil, wenn der Client keine der beiden Schnittstellen hat
local function register()
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(canvas, ns.DISPLAY_NAME)
    Settings.RegisterAddOnCategory(category)
    return category
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(canvas)
    return canvas
  end
end

BlizzardSettings.category = register()
