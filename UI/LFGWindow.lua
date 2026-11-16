-- Eigenes Gruppensuche-Fenster statt Blizzards (Einstellung lfgWindow, aus; nur WoW Forever; Daten und Aufrufe in
-- Assist/LFGSearch.lua und Assist/LFGData.lua). Größe "Groß" (1000 x 680). Diese Datei: Rahmen, Fensterkopf, Reiter,
-- gemeinsamer Zustand und gemeinsame Hilfen. Die Reiter melden sich mit LFGWindow.RegisterTab an:
-- UI/LFGSearchTab.lua (Suchen) und UI/LFGOwnGroupTab.lua (Eigene Gruppe); das Ersetzen von Blizzards Fenster steht in
-- Assist/LFGWindowHook.lua.
-- Suche, Einladen und Eintragen laufen nur aus dem Klick eines eigenen Knopfs (Hardware-Ereignis, kein Taint).
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Widgets = ns.Widgets
local LFGSearch = ns.LFGSearch

local LFGWindow = {}
ns.LFGWindow = LFGWindow

local WIDTH, HEIGHT = 1000, 680
local PAD = 16
local CONTENT_TOP = 80          -- Kopf (40) und Reiterzeile
local TAB_ROW_TOP = 48
local TAB_GAP = 8
LFGWindow.PAD = PAD
LFGWindow.WIDTH = WIDTH
LFGWindow.CONTROL_HEIGHT = 28
LFGWindow.GAP = 8
LFGWindow.TAB_SEARCH, LFGWindow.TAB_LISTING = 2, 1  -- wie Blizzards Reiter (LFGVanilla_ShowFrame(tab)): 1 Eintrag, 2 Suche
LFGWindow.ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
LFGWindow.SOLO_ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }
local TAB_SEARCH, TAB_LISTING = LFGWindow.TAB_SEARCH, LFGWindow.TAB_LISTING

local state = {
  tab = TAB_SEARCH, categoryID = nil, activityID = nil, fitOnly = false, kind = LFGSearch.KIND_ALL,
  hideDelisted = true, moreOpen = false, results = {}, offset = 0, selected = nil, status = "start",
  listingActivityID = nil, listingCategoryID = nil,
}
local parts = {}   -- Test-Zugriff: die Reiter tragen ihre Knöpfe, Zeilen und Texte ein
local tabModules = {}

---------------------------------------------------------------------------
-- Rahmen
---------------------------------------------------------------------------
local panelName = ns.GlobalName("LFGWindow")
local panel = Widgets.CreatePanel(panelName, 0.95)
panel:SetSize(WIDTH, HEIGHT)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  ns.Frames.SavePosition("lfgWindow")
end)
panel:Hide()
table.insert(UISpecialFrames, panelName)  -- mit Esc schließen
local header = Widgets.CreateWindowHeader(panel, "")

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
  frame:SetPoint("TOPLEFT", PAD, -CONTENT_TOP)
  frame:SetPoint("BOTTOMRIGHT", -PAD, PAD)
  return frame
end
LFGWindow.searchContainer, LFGWindow.listingContainer = newContainer(), newContainer()

---------------------------------------------------------------------------
-- Gemeinsame Hilfen der Reiter
---------------------------------------------------------------------------
function LFGWindow.NewButton(parent, width, key, onClick)
  local button = Widgets.CreateButton(parent, width, LFGWindow.CONTROL_HEIGHT, onClick)
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

-- Auswahlliste an einem Knopf; entries = { { key, text } }
function LFGWindow.PickFrom(anchor, entries, current, onPick)
  ns.Dropdown.Open(anchor, { entries = entries, current = current, onPick = onPick })
end

function LFGWindow.NameOf(list, id)
  for _, entry in ipairs(list) do
    if entry.id == id then return entry.name end
  end
end

function LFGWindow.EntriesOf(list, withAll)
  local entries = withAll and { { key = 0, text = L.LFG_ALL_ACTIVITIES } } or {}
  for _, entry in ipairs(list) do table.insert(entries, { key = entry.id, text = entry.name }) end
  return entries
end

-- Ein Reiter meldet seinen Inhalt an: refresh() füllt ihn, solange er sichtbar ist
function LFGWindow.RegisterTab(id, refresh) tabModules[id] = refresh end

---------------------------------------------------------------------------
-- Gesamtansicht
---------------------------------------------------------------------------
function LFGWindow.Refresh()
  header:SetTitle(L.LFG_WIN_TITLE)
  local previous
  for _, id in ipairs({ TAB_LISTING, TAB_SEARCH }) do
    local tab = tabs[id]
    tab:SetLabel(L[tab.labelKey])
    tab:SetActive(id == state.tab)
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", previous or panel, previous and "TOPRIGHT" or "TOPLEFT", previous and TAB_GAP or PAD,
      previous and 0 or -TAB_ROW_TOP)
    previous = tab
  end
  LFGWindow.searchContainer:SetShown(state.tab == TAB_SEARCH)
  LFGWindow.listingContainer:SetShown(state.tab == TAB_LISTING)
  if tabModules[state.tab] then tabModules[state.tab]() end
end

function LFGWindow.SetTab(id)
  state.tab = id
  ns.Dropdown.Close()
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
