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
local SUBTABS_TOP = -88
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
  local entry = { tab = tabKey, members = {} }
  entry.tabButton = Widgets.CreateTab(panel, "GameFontNormal", function()
    selectView(entry, entry.selected)
  end)
  local previous = entries[#entries]
  if previous then
    entry.tabButton:SetPoint("LEFT", previous.tabButton, "RIGHT", TAB_GAP, 0)
  else
    entry.tabButton:SetPoint("TOPLEFT", MARGIN, TABS_TOP)
  end
  table.insert(entries, entry)
  selectedEntry = selectedEntry or entry
  return entry
end

---------------------------------------------------------------------------
-- Ansichten
---------------------------------------------------------------------------

-- view = { tab = Locale-Key, group = Locale-Key (optional),
--          Create = function(parent, width, height) -> frame mit Render(characterKey, selectionChanged) }
function HistoryWindow.AddView(view)
  view.frame = view.Create(content, HistoryWindow.CONTENT_WIDTH, HistoryWindow.CONTENT_HEIGHT)
  view.frame:Hide()

  local entry = view.group and entriesByGroup[view.group]
  if not entry then
    entry = createEntry(view.group or view.tab)
    if view.group then entriesByGroup[view.group] = entry end
  end

  -- Position setzt layoutSubtabs, weil die Breite von der Sprache abhängt
  view.subtabButton = Widgets.CreateTab(panel, "GameFontHighlightSmall", function()
    selectView(entry, view)
  end)

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

-- Unterreiter einer Gruppe von links nach rechts, bei Platzmangel in die nächste Zeile.
-- Erwartet gesetzte Beschriftungen (Breite); gibt die Zahl der Zeilen zurück.
local function layoutSubtabs(entry)
  local x, row = 0, 0
  for _, view in ipairs(entry.members) do
    local width = view.subtabButton:GetWidth()
    if x > 0 and x + width > HistoryWindow.CONTENT_WIDTH then
      x, row = 0, row + 1
    end
    view.subtabButton:ClearAllPoints()
    view.subtabButton:SetPoint("TOPLEFT", MARGIN + x, SUBTABS_TOP - row * SUBTAB_ROW_HEIGHT)
    x = x + width + SUBTAB_GAP
  end
  return row + 1
end

-- Inhalt unter die Unterreiter. Platz für die meisten Zeilen aller Gruppen, damit das Fenster
-- beim Reiterwechsel nicht springt.
local function placeContent(subtabRows)
  local contentTop = SUBTABS_TOP - (subtabRows - 1) * SUBTAB_ROW_HEIGHT - SUBTABS_TO_CONTENT
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

  local subtabRows = 1
  for _, entry in ipairs(entries) do
    local isSelectedEntry = entry == selectedEntry
    entry.tabButton:SetLabel(L[entry.tab])
    entry.tabButton:SetActive(isSelectedEntry)

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
