-- Historie und Auswertung: Fenster mit Charakter-Auswahl, Reitern und Unterreitern.
-- Ansichten registrieren sich über HistoryWindow.AddView (HistoryTables.lua, HistoryCharts.lua, ...).
-- Ansichten mit gleicher group teilen sich einen Reiter und erscheinen dort als Unterreiter;
-- die Ladereihenfolge bestimmt die Reihenfolge.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local History = ns.History

local HistoryWindow = {
  CONTENT_WIDTH = 540,   -- Platz, den jede Ansicht bekommt
  CONTENT_HEIGHT = 290,
}
ns.HistoryWindow = HistoryWindow

local MARGIN = 16
local HEADER_TOP = -14
local CHARACTER_ROW_TOP = -40
local TABS_TOP = -66
local TAB_ROW_HEIGHT = 20     -- Hauptreiter, die nicht in eine Zeile passen, brechen in weitere Zeilen um
local SUBTABS_TOP = -88       -- erste Unterreiter-Zeile bei einer Hauptreiter-Zeile
local SUBTAB_ROW_HEIGHT = 18  -- zu viele Unterreiter für eine Zeile brechen in weitere Zeilen um
local SUBTABS_TO_CONTENT = 22 -- Abstand von der ersten Unterreiter-Zeile zum Inhalt
local ARROW_SIZE = 22
local DELETE_BUTTON_WIDTH = 110
local DELETE_BUTTON_HEIGHT = 20
local CLOSE_BUTTON_GAP = 28  -- Platz für den Schließen-Knopf oben rechts
local TAB_GAP = 12
local SUBTAB_GAP = 10
local UPDATE_INTERVAL = 1  -- Sekunden; hält laufende Einträge aktuell
local NAME_COLOR = { 1, 1, 1 }  -- Charaktername ohne bekannte Klasse

local panel = Widgets.CreatePanel(ns.GlobalName("History"), 0.95)
panel:SetWidth(HistoryWindow.CONTENT_WIDTH + 2 * MARGIN)  -- Höhe hängt von den Unterreiter-Zeilen ab (refresh)
panel:SetPoint("CENTER", UIParent, "CENTER", 40, -40)  -- versetzt zu den Einstellungen
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, ns.GlobalName("History"))  -- mit ESC schließen

Widgets.CreateCloseButton(panel)

local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", 0, HEADER_TOP)

local content = CreateFrame("Frame", nil, panel)
content:SetSize(HistoryWindow.CONTENT_WIDTH, HistoryWindow.CONTENT_HEIGHT)

-- Reiter: entry = { tab = Locale-Key, members = { view, ... }, selected = view, tabButton }
local entries = {}
local entriesByGroup = {}
local selectedEntry
local entryTabs = ns.TabStrip.New(panel, {
  font = "GameFontNormal", left = MARGIN, top = TABS_TOP, gap = TAB_GAP,
  maxWidth = HistoryWindow.CONTENT_WIDTH, rowHeight = TAB_ROW_HEIGHT,
})
local selectedCharacter  -- Schlüssel "Name-Realm"; nil = eingeloggter Charakter
local rendered = {}      -- zuletzt angezeigte Ansicht und Charakter (Wechsel setzt den Bildlauf zurück)
local refresh            -- unten definiert

local function selectView(entry, view)
  selectedEntry = entry
  entry.selected = view
  ns.Set("historyTab", view.tab)  -- beim nächsten Öffnen wieder da
  refresh()
end

-- Zuletzt gewählte Ansicht (Einstellung historyTab) wieder auswählen
local function restoreView()
  for _, entry in ipairs(entries) do
    for _, view in ipairs(entry.members) do
      if view.tab == ns.db.historyTab then
        selectedEntry = entry
        entry.selected = view
        return
      end
    end
  end
end

local function createEntry(tabKey)
  -- Unterreiter von links nach rechts, bei Platzmangel in die nächste Zeile (Position setzt layoutSubtabs, weil die
  -- Breite von der Sprache abhängt)
  local entry = { tab = tabKey, members = {}, subtabs = ns.TabStrip.New(panel, {
    font = "GameFontHighlightSmall", left = MARGIN, top = SUBTABS_TOP, gap = SUBTAB_GAP,
    maxWidth = HistoryWindow.CONTENT_WIDTH, rowHeight = SUBTAB_ROW_HEIGHT,
  }) }
  entry.tabButton = entryTabs:Add(function()
    selectView(entry, entry.selected)
  end)
  Widgets.AttachTooltip(entry.tabButton, function() return L[entry.tab] end, function() return HistoryWindow.EntryTip(entry) end)
  table.insert(entries, entry)
  selectedEntry = selectedEntry or entry
  return entry
end

---------------------------------------------------------------------------
-- Ansichten
---------------------------------------------------------------------------

-- Text zu key, nil, wenn es ihn nicht gibt (L liefert für unbekannte Keys den Key selbst)
local function optionalText(key)
  local text = L[key]
  if text ~= key then return text end
  return nil
end

-- Tooltip eines Unterreiters (UX W23): <tab>_TIP, sonst der Hinweis der Ansicht (Graphen <tab>_HINT, Tabellen hint)
function HistoryWindow.ViewTip(view)
  local text = optionalText(view.tab .. "_TIP") or optionalText(view.tab .. "_HINT")
  if text then return text end
  local hint = view.hint
  if type(hint) == "function" then return hint(selectedCharacter or ns.characterKey) end
  if type(hint) == "string" then return optionalText(hint) end
  return nil
end

-- Tooltip eines Hauptreiters: <tab>_TIP, bei einer Ansicht deren Tooltip, sonst die Namen der Unterreiter
function HistoryWindow.EntryTip(entry)
  local text = optionalText(entry.tab .. "_TIP")
  if text then return text end
  if #entry.members == 1 then return HistoryWindow.ViewTip(entry.members[1]) end
  local names = {}
  for i, view in ipairs(entry.members) do names[i] = L[view.tab] end
  return string.format(L.HISTORY_GROUP_CONTAINS, table.concat(names, ", "))
end

-- view = { tab = Locale-Key, group = Locale-Key (optional), hint = Locale-Key oder function(characterKey) (optional),
--          Create = function(parent, width, height) -> frame mit Render(characterKey, selectionChanged) }
function HistoryWindow.AddView(view)
  view.frame = view.Create(content, HistoryWindow.CONTENT_WIDTH, HistoryWindow.CONTENT_HEIGHT)
  view.frame:Hide()

  local entry = view.group and entriesByGroup[view.group]
  if not entry then
    entry = createEntry(view.group or view.tab)
    if view.group then entriesByGroup[view.group] = entry end
  end

  view.subtabButton = entry.subtabs:Add(function()
    selectView(entry, view)
  end)
  Widgets.AttachTooltip(view.subtabButton, function() return L[view.tab] end, function() return HistoryWindow.ViewTip(view) end)

  table.insert(entry.members, view)
  entry.selected = entry.selected or view
end

---------------------------------------------------------------------------
-- Charakter-Auswahl: Pfeile blättern durch alle gespeicherten Charaktere
---------------------------------------------------------------------------
local characterName = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
characterName:SetPoint("TOP", 0, CHARACTER_ROW_TOP)

local function stepCharacter(step)
  local keys = History.GetCharacterKeys()
  local index = 1
  for i, key in ipairs(keys) do
    if key == selectedCharacter then index = i end
  end
  selectedCharacter = keys[(index - 1 + step) % #keys + 1]
  refresh()
end

local previousButton = Widgets.CreateButton(panel, ARROW_SIZE, ARROW_SIZE, function() stepCharacter(-1) end)
previousButton:SetText("<")
previousButton:SetPoint("TOPLEFT", MARGIN, CHARACTER_ROW_TOP + 4)

local nextButton = Widgets.CreateButton(panel, ARROW_SIZE, ARROW_SIZE, function() stepCharacter(1) end)
nextButton:SetText(">")
nextButton:SetPoint("TOPRIGHT", -MARGIN, CHARACTER_ROW_TOP + 4)

-- Liste aller Charaktere (UI/CharacterMenu.lua): Klick auf den Namen
local menu = ns.CharacterMenu.Create(panel, {
  name = ns.GlobalName("HistoryMenu"), anchor = characterName,
  onSelect = function(characterKey)
    selectedCharacter = characterKey
    refresh()
  end,
})

local nameButton = CreateFrame("Button", nil, panel)
nameButton:SetAllPoints(characterName)
nameButton:SetScript("OnClick", function() menu.Toggle() end)
Widgets.AttachTooltip(nameButton, function() return L.HISTORY end, function() return L.HISTORY_CHARACTER_LIST_TIP end)
panel:HookScript("OnHide", function()
  menu.Hide()
end)

---------------------------------------------------------------------------
-- Daten des gewählten Charakters löschen (mit Rückfrage)
---------------------------------------------------------------------------
local DELETE_POPUP = ns.PopupKey("DELETE_CHARACTER")

local confirmDelete = Widgets.ConfirmPopup(DELETE_POPUP, "DELETE_CHARACTER_CONFIRM", function(characterKey)
  ns.DeleteCharacter(characterKey)
  refresh()
end)

local deleteButton = Widgets.CreateButton(panel, DELETE_BUTTON_WIDTH, DELETE_BUTTON_HEIGHT, function()
  confirmDelete(History.DisplayName(selectedCharacter), selectedCharacter)
end)
deleteButton:SetPoint("TOPRIGHT", -(MARGIN + CLOSE_BUTTON_GAP), HEADER_TOP + 4)

local function showCharacterName(characterKey)
  local character = History.GetCharacter(characterKey)
  characterName:SetText(string.format(L.HISTORY_CHARACTER, History.DisplayName(characterKey), character.currentLevel.level))
  characterName:SetTextColor(unpack(ns.Theme.ClassColor(character.class, NAME_COLOR)))
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

-- Obere Kante der ersten Unterreiter-Zeile: unter allen Hauptreiter-Zeilen
local subtabsTop = SUBTABS_TOP

-- Unterreiter einer Gruppe in Zeilen (TabStrip mit Umbruch). Erwartet gesetzte Beschriftungen (Breite); gibt die Zahl
-- der Zeilen zurück.
local function layoutSubtabs(entry)
  entry.subtabs:SetTop(subtabsTop)
  return entry.subtabs:Layout()
end

-- Inhalt unter die Unterreiter. Platz für die meisten Zeilen aller Gruppen, damit das Fenster
-- beim Reiterwechsel nicht springt.
local function placeContent(subtabRows)
  local contentTop = subtabsTop - (subtabRows - 1) * SUBTAB_ROW_HEIGHT - SUBTABS_TO_CONTENT
  content:ClearAllPoints()
  content:SetPoint("TOPLEFT", MARGIN, contentTop)
  panel:SetHeight(-contentTop + HistoryWindow.CONTENT_HEIGHT + MARGIN)
end

function refresh()
  if not History.GetCharacter(selectedCharacter or "") then
    selectedCharacter = ns.characterKey
  end

  header:SetText(L.HISTORY)
  Widgets.SetButtonText(deleteButton, L.DELETE_CHARACTER, DELETE_BUTTON_WIDTH)
  showCharacterName(selectedCharacter)

  local selectedView = selectedEntry.selected
  local selectionChanged = rendered.view ~= selectedView or rendered.character ~= selectedCharacter
  rendered.view, rendered.character = selectedView, selectedCharacter

  -- Hauptreiter umbrechen wie die Unterreiter (lange Sprachen); die Unterreiter rücken unter die letzte Zeile
  for _, entry in ipairs(entries) do
    entry.tabButton:SetLabel(L[entry.tab])
    entry.tabButton:SetActive(entry == selectedEntry)
  end
  subtabsTop = SUBTABS_TOP - (entryTabs:Layout() - 1) * TAB_ROW_HEIGHT

  local subtabRows = 1
  for _, entry in ipairs(entries) do
    local isSelectedEntry = entry == selectedEntry

    -- Unterreiter nur bei Gruppen mit mehreren Ansichten
    local showSubtabs = isSelectedEntry and #entry.members > 1
    for _, view in ipairs(entry.members) do
      view.subtabButton:SetLabel(L[view.tab])
      view.subtabButton:SetActive(view == entry.selected)
      view.subtabButton:SetShown(showSubtabs)
      if view == selectedView then
        view.frame:Render(selectedCharacter, selectionChanged)
        view.frame:Show()
      else
        view.frame:Hide()
      end
    end
    subtabRows = math.max(subtabRows, layoutSubtabs(entry))
  end
  placeContent(subtabRows)
end

-- Für Tests: Hauptreiter (Buttons) und die obere Kante der ersten Unterreiter-Zeile
function HistoryWindow.MainTabs()
  return entryTabs.tabs
end

-- Für Tests: alle Reiter-Einträge { tab, members = { view, ... }, tabButton }
function HistoryWindow.Entries()
  return entries
end

function HistoryWindow.SubtabsTop()
  return subtabsTop
end

-- Jede Sekunde nur die gewählte Ansicht (laufende Werte) und den Namen samt Level; Reiter, Texte und Anordnung
-- ändern sich nur bei Klick, Sprach- oder Charakterwechsel und laufen dann über refresh (Roadmap 213)
local function tick()
  if selectedCharacter ~= rendered.character or not History.GetCharacter(selectedCharacter or "") then
    refresh()
    return
  end
  showCharacterName(selectedCharacter)
  selectedEntry.selected.frame:Render(selectedCharacter, false)
end

local sinceUpdate = 0
ns.SetUpdateScript(panel, "HistoryWindow", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  tick()
end)

-- Sprachwechsel bei offenem Fenster
ns.RegisterApply(function()
  if panel:IsShown() then refresh() end
end)

function ns.ToggleHistory()
  if not ns.db then return end
  if panel:IsShown() then
    panel:Hide()
  else
    restoreView()  -- bei jedem Öffnen: folgt auch einem Profilwechsel
    refresh()
    panel:Show()
  end
end
