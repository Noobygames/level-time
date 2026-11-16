-- Eigenes Gruppensuche-Fenster statt Blizzards (Einstellung lfgWindow, aus; nur WoW Forever; Daten und Aufrufe in
-- Assist/LFGSearch.lua und Assist/LFGData.lua). Sieht aus wie Blizzards Vanilla-Stil-Gruppensuche (Blizzard_GroupFinder_
-- VanillaStyle): PortraitFrameTemplate, rote UIPanelButtonTemplate-Knöpfe, WowStyle1DropdownTemplate, Rollen-Atlanten
-- und Hintergründe von Blizzard; unser Detail hängt als Seitenfenster rechts daran. Von Blizzards Mixins kommt nichts
-- mit (die rufen geschützte Funktionen), nur Vorlagen und Atlanten. Diese Datei: Rahmen, Reiter, gemeinsamer Zustand und
-- Hilfen. Die Reiter melden sich mit LFGWindow.RegisterTab an: UI/LFGSearchTab.lua (Suchen) und UI/LFGOwnGroupTab.lua
-- (Eigene Gruppe); das Ersetzen von Blizzards Fenster steht in Assist/LFGWindowHook.lua.
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
local TAB_GAP = 8
local MENU_HEIGHT = 300          -- Höhe der Auswahllisten, danach Bildlauf
local PORTRAIT = "Interface\\ICONS\\INV_SideTab_GroupFinder_c60"  -- wie Blizzards Reiter Eigener Eintrag
LFGWindow.PAD = PAD
LFGWindow.WIDTH, LFGWindow.HEIGHT = WIDTH, HEIGHT
LFGWindow.CONTROL_HEIGHT = 28
LFGWindow.GAP = 8
LFGWindow.TAB_SEARCH, LFGWindow.TAB_LISTING = 2, 1  -- wie Blizzards Reiter (LFGVanilla_ShowFrame(tab)): 1 Eintrag, 2 Suche
LFGWindow.ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
LFGWindow.SOLO_ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }
local TAB_SEARCH, TAB_LISTING = LFGWindow.TAB_SEARCH, LFGWindow.TAB_LISTING

local state = {
  tab = TAB_SEARCH, categoryID = nil, activityID = nil, fitOnly = false, kind = LFGSearch.KIND_ALL,
  hideDelisted = true, moreOpen = false, results = {}, offset = 0, selected = nil, status = "start",
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

-- Reiter hängen wie bei Blizzards Fenstern unter dem Rahmen
local tabs = {}
local function newTab(id, key)
  local tab = Widgets.CreateTab(panel, "GameFontNormal", function() LFGWindow.SetTab(id) end)
  tab.id, tab.labelKey = id, key
  tabs[id] = tab
end
newTab(TAB_SEARCH, "LFG_TAB_SEARCH")
newTab(TAB_LISTING, "LFG_TAB_LISTING")

local function newContainer()
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetAllPoints()
  return frame
end
LFGWindow.searchContainer, LFGWindow.listingContainer = newContainer(), newContainer()

---------------------------------------------------------------------------
-- Gemeinsame Hilfen der Reiter
---------------------------------------------------------------------------
-- Roter Blizzard-Knopf (UIPanelButtonTemplate) mit Tooltip L[key .. "_TIP"]
function LFGWindow.NewButton(parent, width, key, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, LFGWindow.CONTROL_HEIGHT)
  button:SetScript("OnClick", onClick)
  button.textKey = key
  Widgets.AttachTooltip(button, function() return L[key] end, function() return L[key .. "_TIP"] end)
  return button
end

function LFGWindow.Retext(button, text)
  Widgets.SetButtonText(button, text or L[button.textKey], 60)
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
function LFGWindow.RegisterTab(id, refresh) tabModules[id] = refresh end

---------------------------------------------------------------------------
-- Gesamtansicht
---------------------------------------------------------------------------
function LFGWindow.Refresh()
  if panel.SetTitle then panel:SetTitle(L.LFG_WIN_TITLE) end
  local previous
  for _, id in ipairs({ TAB_LISTING, TAB_SEARCH }) do
    local tab = tabs[id]
    tab:SetLabel(L[tab.labelKey])
    tab:SetActive(id == state.tab)
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", previous or panel, previous and "TOPRIGHT" or "BOTTOMLEFT", previous and TAB_GAP or PAD,
      previous and 0 or 2)
    previous = tab
  end
  LFGWindow.searchContainer:SetShown(state.tab == TAB_SEARCH)
  LFGWindow.listingContainer:SetShown(state.tab == TAB_LISTING)
  if parts.detail and state.tab ~= TAB_SEARCH then parts.detail:Hide() end  -- Seitenfenster gehört zur Suche
  if tabModules[state.tab] then tabModules[state.tab]() end
end

function LFGWindow.SetTab(id)
  state.tab = id
  LFGWindow.Refresh()
end

function LFGWindow.Show(tab)
  if not LFGSearch.IsEnabled() then return end
  state.tab = tab == TAB_LISTING and TAB_LISTING or (tab == TAB_SEARCH and TAB_SEARCH or state.tab)
  LFGWindow.Refresh()
  panel:Show()
end

function LFGWindow.Hide() panel:Hide() end
function LFGWindow.IsShown() return panel:IsShown() end
function LFGWindow.State() return state end
function LFGWindow.Parts() return parts end

ns.Frames.Register({
  id = "lfgWindow", frame = panel, label = "EDIT_FRAME_LFG", default = { "CENTER", "CENTER", 0, 20 },
  settingsPage = "OPTIONS_TAB_LFG", available = LFGSearch.IsAvailable,
  hide = function() ns.Set("lfgWindow", false) end,
})

ns.RegisterApply(function()
  if not panel:IsShown() then return end
  if LFGSearch.IsEnabled() then LFGWindow.Refresh() else panel:Hide() end
end)

ns.RegisterEvent("GROUP_ROSTER_UPDATE", function()
  if panel:IsShown() then LFGWindow.Refresh() end
end)
