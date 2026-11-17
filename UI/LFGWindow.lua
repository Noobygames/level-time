-- Eigenes Gruppensuche-Fenster neben Blizzards (nur WoW Forever; Daten und Aufrufe in Assist/LFGSearch.lua und
-- Assist/LFGData.lua). Blizzards Fenster bleibt unberührt; Einstiege (Minikarten-Icon, Knopf an Blizzards Fenster,
-- /lt lfg) stehen in UI/LFGWindowLaunchers.lua. Sieht aus wie Blizzards Vanilla-Stil-Gruppensuche (Blizzard_GroupFinder_
-- VanillaStyle): PortraitFrameTemplate, rote UIPanelButtonTemplate-Knöpfe, WowStyle1DropdownTemplate, Rollen-Atlanten
-- und Hintergründe von Blizzard; unser Detail hängt als Seitenfenster rechts daran. Von Blizzards Mixins kommt nichts
-- mit (die rufen geschützte Funktionen), nur Vorlagen und Atlanten. Diese Datei: Rahmen, Reiter, gemeinsamer Zustand und
-- Hilfen. Die Reiter melden sich mit LFGWindow.RegisterTab an: UI/LFGSearchTab.lua (Suchen) und UI/LFGOwnGroupTab.lua
-- (Eigene Gruppe). Scheitert der Aufbau beim Öffnen, öffnet Blizzards Fenster (der Spieler bleibt nie ohne Gruppensuche).
-- Suche, Einladen und Eintragen laufen nur aus dem Klick eines eigenen Knopfs (Hardware-Ereignis, kein Taint).
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Widgets = ns.Widgets
local LFGSearch = ns.LFGSearch

local LFGWindow = {}
ns.LFGWindow = LFGWindow

local WIDTH, HEIGHT = 480, 600
local PAD = 16
local TAB_X, TAB_Y = 19, 2  -- erster Reiter unter dem Rahmen wie bei Blizzards PVEFrame
local MENU_HEIGHT = 300          -- Höhe der Auswahllisten, danach Bildlauf
local PORTRAIT = "Interface\\ICONS\\INV_SideTab_GroupFinder_c60"  -- wie Blizzards Reiter Eigener Eintrag
LFGWindow.PAD = PAD
LFGWindow.WIDTH, LFGWindow.HEIGHT = WIDTH, HEIGHT
LFGWindow.CONTROL_HEIGHT = 28
LFGWindow.GAP = 8
LFGWindow.TAB_SEARCH, LFGWindow.TAB_LISTING = 2, 1  -- wie Blizzards Reiter (LFGVanilla_ShowFrame(tab)): 1 Eintrag, 2 Suche
LFGWindow.ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
-- Blizzards Rollen-Symbole der Gruppensuche (Atlanten)
LFGWindow.ROLE_ATLAS = { TANK = "groupfinder-icon-role-large-tank", HEALER = "groupfinder-icon-role-large-heal",
  DAMAGER = "groupfinder-icon-role-large-dps" }
LFGWindow.SOLO_ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }
local TAB_SEARCH, TAB_LISTING = LFGWindow.TAB_SEARCH, LFGWindow.TAB_LISTING

local state = {
  tab = TAB_SEARCH, categoryID = nil, activityID = nil, fitOnly = false, moreOpen = false, results = {}, lines = {},
  collapsed = {}, offset = 0, selected = nil, status = "start",
  listingActivities = {}, listingCategoryID = nil, showAllLevels = false, playstyle = nil, voiceMode = nil,
  listingOffset = 0, listingLoaded = false,
}
local parts = {}   -- Test-Zugriff: die Reiter tragen ihre Knöpfe, Zeilen und Texte ein
local tabModules = {}

---------------------------------------------------------------------------
-- Rahmen
---------------------------------------------------------------------------
local panelName = ns.GlobalName("LFGWindow")
local panel = CreateFrame("Frame", panelName, UIParent, "PortraitFrameTemplate")
panel:SetSize(WIDTH, HEIGHT)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:SetClampedToScreen(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  ns.Frames.SavePosition("lfgWindow")
end)
if panel.SetPortraitToAsset then panel:SetPortraitToAsset(PORTRAIT) end
if type(panel.CloseButton) == "table" then panel.CloseButton:SetScript("OnClick", function() panel:Hide() end) end
panel:Hide()
table.insert(UISpecialFrames, panelName)  -- mit Esc schließen
LFGWindow.panel = panel

-- Blizzards Reiter (PanelTabButtonTemplate) unter dem Rahmen; Reihenfolge = Index in panel.Tabs = Reiter-ID
local tabs = {}
local function newTab(id, key, globalName)
  local tab = CreateFrame("Button", panelName .. "Tab" .. id, panel, "PanelTabButtonTemplate")
  tab:SetID(id)
  tab.labelKey, tab.globalName = key, globalName
  tab:SetScript("OnClick", function() LFGWindow.SetTab(id) end)
  tabs[id] = tab
end
newTab(TAB_LISTING, "LFG_TAB_LISTING")
newTab(TAB_SEARCH, "LFG_TAB_SEARCH", "SEARCH")
tabs[1]:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", TAB_X, TAB_Y)
PanelTemplates_SetNumTabs(panel, #tabs)  -- reiht die weiteren Reiter an den ersten
parts.tabs = tabs

local function newContainer()
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetAllPoints()
  return frame
end
LFGWindow.searchContainer, LFGWindow.listingContainer = newContainer(), newContainer()

---------------------------------------------------------------------------
-- Gemeinsame Hilfen der Reiter
---------------------------------------------------------------------------
-- Text wie in Blizzards Fenster: dessen globaler Text (Client-Sprache, z. B. SEARCH, LFG_TITLE), sonst L[key]. Das
-- Fenster ersetzt Blizzards Gruppensuche und spricht deshalb dessen Sprache, auch wenn das Addon anders eingestellt ist.
function LFGWindow.Text(globalName, key)
  local blizzard = globalName and _G[globalName]
  if type(blizzard) == "string" and blizzard ~= "" then return blizzard end
  return L[key]
end

-- Roter Blizzard-Knopf (UIPanelButtonTemplate) mit Tooltip L[key .. "_TIP"]; globalName = Blizzards Text dafür
function LFGWindow.NewButton(parent, width, key, onClick, globalName)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, LFGWindow.CONTROL_HEIGHT)
  button:SetScript("OnClick", onClick)
  button.textKey, button.globalName = key, globalName
  Widgets.AttachTooltip(button, function() return LFGWindow.Text(globalName, key) end,
    function() return L[key .. "_TIP"] end)
  return button
end

function LFGWindow.Retext(button, text)
  Widgets.SetButtonText(button, text or LFGWindow.Text(button.globalName, button.textKey), 60)
end

function LFGWindow.NewCheck(parent, key, onToggle)
  local check = Widgets.CreateCheckbox(parent, onToggle)
  check.textKey = key
  Widgets.AttachTooltip(check, function() return L[key] end, function() return L[key .. "_TIP"] end)
  return check
end

-- Blizzards Auswahlliste (WowStyle1DropdownTemplate) mit Einzelauswahl; entriesFn() liefert { { key, text } },
-- currentFn() den gewählten Schlüssel, onPick(key) wird bei Wahl gerufen (kein geschützter Aufruf darin).
-- Test-Zugriff: dropdown.entriesFn und dropdown.pick.
function LFGWindow.NewDropdown(parent, width, entriesFn, currentFn, onPick)
  local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
  dropdown:SetWidth(width)
  dropdown.entriesFn, dropdown.pick = entriesFn, onPick
  if dropdown.SetupMenu then
    dropdown:SetupMenu(function(_, root)
      if root.SetScrollMode then root:SetScrollMode(MENU_HEIGHT) end
      for _, entry in ipairs(entriesFn()) do
        root:CreateRadio(entry.text, function() return currentFn() == entry.key end, function() onPick(entry.key) end)
      end
    end)
  end
  return dropdown
end

-- Text, solange nichts gewählt ist, und Menü neu aufbauen (Sprache, Auswahl und Einträge können sich geändert haben)
function LFGWindow.RefreshDropdown(dropdown, defaultText)
  dropdown.defaultText = defaultText
  if dropdown.SetDefaultText then dropdown:SetDefaultText(defaultText) end
  if dropdown.GenerateMenu then dropdown:GenerateMenu() end
end

function LFGWindow.NameOf(list, id)
  for _, entry in ipairs(list) do
    if entry.id == id then return entry.name end
  end
end

function LFGWindow.ActivityOf(categoryID, activityID)
  for _, activity in ipairs(LFGSearch.Activities(categoryID)) do
    if activity.id == activityID then return activity end
  end
end

function LFGWindow.EntriesOf(list, withAll)
  local entries = withAll and { { key = 0, text = L.LFG_ALL_ACTIVITIES } } or {}
  for _, entry in ipairs(list) do table.insert(entries, { key = entry.id, text = entry.name }) end
  return entries
end

-- Level-Spanne wie bei Blizzard: "(40 - 47)", "(40)", bei 0 und 0 leer
function LFGWindow.LevelRange(minLevel, maxLevel)
  if (minLevel or 0) == 0 and (maxLevel or 0) == 0 then return "" end
  if minLevel == maxLevel or (maxLevel or 0) == 0 then return string.format("(%d)", minLevel) end
  return string.format("(%d - %d)", minLevel, maxLevel)
end

-- Aktivitäten mit Level-Spanne im Namen, nach Level sortiert (und nur passende, wenn fitOnly)
function LFGWindow.ActivityEntries(categoryID, fitOnly)
  local list = categoryID and LFGSearch.Activities(categoryID) or {}
  if fitOnly then list = LFGSearch.FitActivities(list, UnitLevel("player")) end
  local entries = {}
  for _, activity in ipairs(list) do
    local range = LFGWindow.LevelRange(activity.minLevel, activity.maxLevel)
    table.insert(entries, { key = activity.id, text = range ~= "" and (activity.name .. "  " .. range) or activity.name })
  end
  return entries, list
end

-- Ein Reiter meldet seinen Inhalt an: refresh() füllt ihn, solange er sichtbar ist
-- Wählbare Spielstile (Enum.LFGEntryGeneralPlaystyle ohne "None") in Blizzards Reihenfolge
local playstyles = Enum and Enum.LFGEntryGeneralPlaystyle
LFGWindow.PLAYSTYLE_ORDER = playstyles and { playstyles.Learning, playstyles.FunRelaxed, playstyles.FunSerious,
  playstyles.Expert } or {}

-- Name eines Spielstils (Enum.LFGEntryGeneralPlaystyle) in der Client-Sprache
function LFGWindow.PlaystyleLabel(playstyle)
  return GetGeneralPlaystyleString and GetGeneralPlaystyleString(playstyle) or tostring(playstyle)
end

function LFGWindow.RegisterTab(id, refresh) tabModules[id] = refresh end

-- Nach jedem Neuaufbau (z. B. Seitenleiste neu anhängen, UI/LFGWindowLaunchers.lua)
local afterRefresh = {}
function LFGWindow.OnRefresh(fn) table.insert(afterRefresh, fn) end

---------------------------------------------------------------------------
-- Gesamtansicht
---------------------------------------------------------------------------
function LFGWindow.Refresh()
  if panel.SetTitle then panel:SetTitle(LFGWindow.Text("LFG_TITLE", "LFG_WIN_TITLE")) end
  for _, tab in ipairs(tabs) do
    tab:SetText(LFGWindow.Text(tab.globalName, tab.labelKey))
    PanelTemplates_TabResize(tab)
  end
  PanelTemplates_SetTab(panel, state.tab)
  LFGWindow.searchContainer:SetShown(state.tab == TAB_SEARCH)
  LFGWindow.listingContainer:SetShown(state.tab == TAB_LISTING)
  if parts.detail and state.tab ~= TAB_SEARCH then parts.detail:Hide() end  -- Seitenfenster gehört zur Suche
  if tabModules[state.tab] then tabModules[state.tab]() end
  for _, fn in ipairs(afterRefresh) do fn() end
end

function LFGWindow.SetTab(id)
  state.tab = id
  LFGWindow.Refresh()
end

-- Öffnet das Fenster (tab: TAB_SEARCH oder TAB_LISTING, sonst der zuletzt gewählte). Scheitert der Aufbau, bleibt
-- unser Fenster zu und Blizzards Gruppensuche öffnet stattdessen.
function LFGWindow.Show(tab)
  if not LFGSearch.IsAvailable() then return end
  if tab == TAB_LISTING or tab == TAB_SEARCH then state.tab = tab end
  local ok, err = pcall(LFGWindow.Refresh)
  if ok then
    panel:Show()
    return
  end
  panel:Hide()
  ns.Debug("lfg", "own group finder failed, opening Blizzard's: %s", tostring(err))
  if LFGVanilla_ShowFrame then LFGVanilla_ShowFrame(tab) end
end

function LFGWindow.Toggle()
  if panel:IsShown() then panel:Hide() else LFGWindow.Show() end
end

function LFGWindow.Hide() panel:Hide() end
function LFGWindow.IsShown() return panel:IsShown() end
function LFGWindow.State() return state end
function LFGWindow.Parts() return parts end

ns.Frames.Register({
  id = "lfgWindow", frame = panel, label = "EDIT_FRAME_LFG", default = { "CENTER", "CENTER", 0, 20 },
  settingsPage = "OPTIONS_TAB_LFG", available = LFGSearch.IsAvailable,
})

ns.RegisterApply(function()
  if panel:IsShown() then LFGWindow.Refresh() end
end)

ns.RegisterEvent("GROUP_ROSTER_UPDATE", function()
  if panel:IsShown() then LFGWindow.Refresh() end
end)
