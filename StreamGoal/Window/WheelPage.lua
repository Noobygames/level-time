-- Reiter "Glücksrad" im Fenster /sg (Roadmap 431): was das Rad ziehen darf, als Tabelle (TableView von Level Time:
-- Filter, Sortieren) mit allen mitgelieferten und eigenen Zielen; Klick schaltet einen Eintrag für das Rad an/aus.
-- Unten links die wichtigsten Einstellungen des Rads (dieselben wie unter Einstellungen > Glücksrad), rechts oben
-- "Alle an"/"Alle aus" (für die gefilterten Zeilen), darunter die Hauptaktion "Glücksrad drehen". Eigene Ziele
-- entstehen und werden gelöscht in der Sammlung (CollectionPage.lua).
local _, ns = ...
local LT = ns.LT
local Pool = ns.Pool
local Wheel = ns.Wheel
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local WheelView = {}
ns.WheelView = WheelView

local BOTTOM_HEIGHT = 60        -- zwei Zeilen Einstellungen unter der Tabelle
local CHECK_ROW = 24
local CHECK_INSET = -4          -- UICheckButtonTemplate hat links Luft im Bild
-- Haken unter der Tabelle: Einstellung und Locale-Key (Tooltip aus <Key>_TIP, wie im Einstellungsfenster)
local CHECKS = {
  { setting = "wheelOnLevelUp", label = "SG_OPTIONS_WHEEL_LEVELUP" },
  { setting = "wheelAnimation", label = "SG_OPTIONS_WHEEL_ANIMATION" },
}

local page = Manager.AddPage({
  key = "wheel", label = "SG_TAB_WHEEL", settingsPage = ns.SETTINGS_PAGES.WHEEL,
  render = function() WheelView.Render() end,
})

local header = Widgets.CreateSectionHeader(page)
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")

-- Klick: Eintrag im Rad an/aus
function WheelView.OnRowClick(item)
  Wheel.SetEnabled(item.key, not Wheel.IsEnabled(item.key))
end

local poolTable

-- Alle gerade sichtbaren (gefilterten) Einträge an- bzw. abschalten
function WheelView.SetAllShown(enabled)
  for _, item in ipairs(poolTable:GetVisibleRecords()) do Wheel.SetEnabled(item.key, enabled) end
  WheelView.Render()
end

local poolView = LT.TableView.Create({
  tab = "SG_TAB_WHEEL",
  columns = {
    { header = "SG_COL_POOL_ON", width = 60, align = "LEFT",
      value = function(item) return Wheel.IsEnabled(item.key) and L.SG_POOL_ON or L.SG_POOL_OFF end },
    { header = "SG_COL_GOAL", width = 390, align = "LEFT", value = function(item) return Pool.Title(item) end },
    { header = "SG_COL_SOURCE", width = 120, align = "LEFT", value = Pool.SourceText },
  },
  records = function() return Pool.Items() end,
  footer = function(_, records)
    local on = 0
    for _, item in ipairs(records) do
      if Wheel.IsEnabled(item.key) then on = on + 1 end
    end
    return { string.format(L.SG_POOL_FOOTER, on, #records) }
  end,
  rowColor = function(item)
    if not Wheel.IsEnabled(item.key) then return Theme.COLORS.muted end
    return item.premade and Theme.COLORS.text or Theme.COLORS.accent
  end,
  onRowClick = function(item, mouseButton)
    if mouseButton ~= "RightButton" then WheelView.OnRowClick(item) end
  end,
  hint = "SG_WHEEL_POOL_HINT",
})

local tableHeight = Manager.PAGE_HEIGHT - Manager.HEADER_HEIGHT - BOTTOM_HEIGHT
local holder = CreateFrame("Frame", nil, page)
holder:SetPoint("TOPLEFT", 0, -Manager.HEADER_HEIGHT)
holder:SetSize(Manager.PAGE_WIDTH, tableHeight)
poolTable = poolView.Create(holder, Manager.PAGE_WIDTH, tableHeight)
WheelView.table = poolTable

-- Einstellungen des Rads direkt unter der Tabelle
local checks = {}
for index, entry in ipairs(CHECKS) do
  local check = Widgets.CreateCheckbox(page, function(checked) ns.SetSetting(entry.setting, checked) end)
  check:SetPoint("BOTTOMLEFT", CHECK_INSET, (#CHECKS - index) * CHECK_ROW)
  check:SetHitRectInsets(0, -200, 0, 0)  -- Beschriftung gehört zur Klickfläche
  check.entry = entry
  Widgets.AttachTooltip(check, function() return L[entry.label] end, function() return L[entry.label .. "_TIP"] end)
  checks[index] = check
end
WheelView.checks = checks

local spinButton = Manager.CreateButton(page, "SG_WHEEL_SPIN", function() ns.Commands.Wheel("") end)
spinButton:SetPoint("BOTTOMRIGHT", 0, 0)
WheelView.spinButton = spinButton
local allOnButton = Manager.CreateButton(page, "SG_WHEEL_ALL_ON", function() WheelView.SetAllShown(true) end)
local allOffButton = Manager.CreateButton(page, "SG_WHEEL_ALL_OFF", function() WheelView.SetAllShown(false) end)
local switchButtons = { allOffButton, allOnButton }
WheelView.switchButtons = switchButtons

function WheelView.Render()
  if not ns.db then return end
  header:SetText(L.SG_WHEEL_POOL_TITLE)
  for _, check in ipairs(checks) do
    check.label:SetText(L[check.entry.label])
    check:SetChecked(ns.db.settings[check.entry.setting] and true or false)
  end
  Manager.SetLabels({ spinButton, allOnButton, allOffButton })
  Manager.AlignRight(switchButtons, page, "BOTTOMRIGHT", CHECK_ROW)
  poolTable:Render(nil, false, true)
end
