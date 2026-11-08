-- Fenster von Level Time Goals (/sg): Rahmen, Reiter der Seiten, Fußzeile und gemeinsame Bausteine der Seiten.
-- Jede Seite steht in einer eigenen Datei (Window/*Page.lua) und meldet sich mit Manager.AddPage an; die Reiter stehen
-- in der Reihenfolge der .toc:
--   Ziele (neues Ziel, laufende Ziele) | Bingo (Schein selbst füllen) | Glücksrad (was das Rad ziehen darf, Drehen) |
--   Sammlung (Pakete und Vorlagen, Teilen und Importieren) | Historie
-- Fußzeile: links "Ziel-Karten anzeigen", rechts "Layout bearbeiten" und "Einstellungen" (öffnet die Unterseite
-- der Einstellungen, die zur gezeigten Seite gehört).
-- Seite = { key, label (Locale-Key, Tooltip aus <label>_TIP), settingsPage, refresh(), render() }: refresh setzt Texte
-- und Anordnung (Sprache!), render die Daten; beide laufen beim Zeigen, render auch nach Änderungen der Ziele.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Tracker = ns.Tracker
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local Manager = {}
ns.Manager = Manager

local MARGIN = 16
local CONTENT_WIDTH = 600
local PAGE_HEIGHT = 520
local PAGE_TOP = -66
local PAGE_TABS_TOP = -40
local FOOTER_HEIGHT = 34
local PAGE_TAB_GAP = 14
local FOOTER_BUTTON_GAP = 6
local FOOTER_BUTTON_MIN_WIDTH = 90
local DEFAULT_PAGE = "goals"
-- Frühere Seitennamen (Befehle, gespeicherte Aufrufe anderer Dateien): "packs" ist jetzt ein Teil der Sammlung
local PAGE_ALIASES = { packs = "collection" }

-- Maße, die alle Seiten teilen (gleiche Zeilen, Felder und Knöpfe auf jeder Seite)
Manager.PAGE_WIDTH, Manager.PAGE_HEIGHT = CONTENT_WIDTH, PAGE_HEIGHT
Manager.ROW = 26              -- Höhe einer Zeile mit Feld oder Knopf
Manager.BOX_HEIGHT = 20
Manager.BUTTON_HEIGHT = 22
Manager.BOX_BORDER = 6        -- InputBoxTemplate zeichnet seinen Rand links außerhalb
Manager.BUTTON_GAP = 6
Manager.LABEL_GAP = 8         -- Beschriftung zum Feld daneben
Manager.BUTTON_MIN_WIDTH = 90
Manager.HEADER_HEIGHT = 24    -- Abschnitts-Überschrift oben auf einer Seite

---------------------------------------------------------------------------
-- Bausteine der Seiten
---------------------------------------------------------------------------
-- Knopf mit Text L[labelKey] und Tooltip L[labelKey .. "_TIP"]; Manager.SetLabels setzt die Texte (Sprache)
function Manager.CreateButton(parent, labelKey, onClick, minWidth)
  local button = Widgets.CreateButton(parent, minWidth or Manager.BUTTON_MIN_WIDTH, Manager.BUTTON_HEIGHT, onClick)
  button.labelKey, button.minWidth = labelKey, minWidth or Manager.BUTTON_MIN_WIDTH
  Widgets.AttachTooltip(button, function() return L[button.labelKey] end, function() return L[button.labelKey .. "_TIP"] end)
  return button
end

-- Tooltip mit mehreren Zeilen: title() = Überschrift, lines() = { { text, muted = true|nil }, ... } (gedämpfte Zeilen
-- für Bedienhinweise und Chatbefehle, normale für die Erklärung); ohne Zeilen kein Tooltip
function Manager.AttachTooltip(frame, title, lines)
  frame:HookScript("OnEnter", function(self)
    local list = lines()
    if not list or #list == 0 then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title(), Theme.RGB("accent"))
    for _, line in ipairs(list) do
      if line.muted then
        local r, g, b = Theme.RGB("muted")
        GameTooltip:AddLine(line.text, r, g, b, true)
      else
        GameTooltip:AddLine(line.text, 1, 1, 1, true)
      end
    end
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Texte der Knöpfe aus CreateButton in der gewählten Sprache (Breite wächst mit dem Text)
function Manager.SetLabels(buttons)
  for _, button in ipairs(buttons) do Widgets.SetButtonText(button, L[button.labelKey], button.minWidth) end
end

-- Knöpfe rechtsbündig in einer Zeile, der erste ganz rechts (Hauptaktion); Rückgabe: belegte Breite
function Manager.AlignRight(buttons, parent, point, y)
  local used = 0
  for index, button in ipairs(buttons) do
    button:ClearAllPoints()
    if index == 1 then
      button:SetPoint(point, parent, point, 0, y)
    else
      button:SetPoint("RIGHT", buttons[index - 1], "LEFT", -Manager.BUTTON_GAP, 0)
    end
    used = used + button:GetWidth() + (index > 1 and Manager.BUTTON_GAP or 0)
  end
  return used
end

-- Einzeiliges Textfeld; onEnter läuft bei Enter
function Manager.CreateTextBox(parent, onEnter, numeric)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetHeight(Manager.BOX_HEIGHT)
  box:SetAutoFocus(false)
  box:SetNumeric(numeric and true or false)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  if onEnter then box:SetScript("OnEnterPressed", onEnter) end
  return box
end

-- Beschriftung vor einem Feld
function Manager.CreateLabel(parent)
  local label = parent:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
  label:SetJustifyH("LEFT")
  return label
end

-- Gedämpfter Hinweis über die ganze Breite (bricht um)
function Manager.CreateHint(parent)
  local hint = parent:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
  hint:SetTextColor(Theme.RGB("muted"))
  hint:SetJustifyH("LEFT")
  hint:SetJustifyV("TOP")
  hint:SetWidth(CONTENT_WIDTH)
  return hint
end

-- Zeile "Beschriftung [Feld ......] [Knöpfe]": das Feld füllt den Platz zwischen Beschriftung und Knöpfen
-- (Knöpfe vorher mit AlignRight gesetzt); Rückgabe: Breite des Felds
function Manager.FitBox(label, box, buttonsWidth, width)
  box:ClearAllPoints()
  box:SetPoint("LEFT", label, "RIGHT", Manager.LABEL_GAP + Manager.BOX_BORDER, 0)
  local boxWidth = (width or CONTENT_WIDTH) - math.ceil(label:GetStringWidth() or 0) - Manager.LABEL_GAP
    - Manager.BOX_BORDER - buttonsWidth - Manager.BUTTON_GAP
  box:SetWidth(boxWidth)
  return boxWidth
end

---------------------------------------------------------------------------
-- Fenster und Reiter
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel("StreamGoalWindow", 0.95)
panel:SetSize(CONTENT_WIDTH + 2 * MARGIN, -PAGE_TOP + PAGE_HEIGHT + FOOTER_HEIGHT + MARGIN)
-- Mittig, nicht darüber: das Fenster ist hoch und stieß sonst bei großer UI-Skalierung an den oberen Rand, wo das
-- Schließen-Kreuz abgeschnitten wirkte
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "StreamGoalWindow")  -- mit ESC schließen
Manager.closeButton = Widgets.CreateCloseButton(panel)  -- innen oben rechts wie bei den Fenstern von Level Time
Manager.panel = panel

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

local pages = {}      -- [key] = Seite (siehe Kopf) samt frame und tab
local pageOrder = {}
local shownPage = DEFAULT_PAGE

local function showPage(name)
  shownPage = name
  for key, page in pairs(pages) do
    page.frame:SetShown(key == name)
    page.tab:SetActive(key == name)
  end
  local page = pages[name]
  if page.refresh then page.refresh() end
  if page.render then page.render() end
end

-- Seite anmelden; Rückgabe: Fläche der Seite (PAGE_WIDTH x PAGE_HEIGHT)
function Manager.AddPage(page)
  page.frame = CreateFrame("Frame", nil, panel)
  page.frame:SetSize(CONTENT_WIDTH, PAGE_HEIGHT)
  page.frame:SetPoint("TOPLEFT", MARGIN, PAGE_TOP)
  page.frame:Hide()
  page.tab = Widgets.CreateTab(panel, Theme.Font("title"), function() showPage(page.key) end)
  Widgets.AttachTooltip(page.tab, function() return L[page.label] end, function() return L[page.label .. "_TIP"] end)
  local previous = pages[pageOrder[#pageOrder]]
  if previous then
    page.tab:SetPoint("LEFT", previous.tab, "RIGHT", PAGE_TAB_GAP, 0)
  else
    page.tab:SetPoint("TOPLEFT", MARGIN, PAGE_TABS_TOP)
  end
  pages[page.key] = page
  table.insert(pageOrder, page.key)
  return page.frame
end

function Manager.ShownPage()
  return panel:IsShown() and shownPage or nil
end

-- Seite zeigen, wenn das Fenster offen ist (Knöpfe "Sammlung öffnen" usw.)
function Manager.ShowPage(name)
  name = PAGE_ALIASES[name] or name
  if pages[name] then showPage(name) end
end

-- Reiter der Seiten in ihrer Reihenfolge (Tests: passen alle in die Breite)
function Manager.PageTabs()
  local tabs = {}
  for _, key in ipairs(pageOrder) do table.insert(tabs, pages[key].tab) end
  return tabs
end

-- Reihenfolge der Seiten (Tests)
function Manager.PageKeys()
  return pageOrder
end

---------------------------------------------------------------------------
-- Fußzeile: Tracker an/aus, Layout bearbeiten, Einstellungen der Seite
---------------------------------------------------------------------------
local trackerCheck = Widgets.CreateCheckbox(panel, function(checked) Tracker.SetShown(checked) end)
trackerCheck:SetPoint("BOTTOMLEFT", MARGIN - 4, 8)
trackerCheck:SetHitRectInsets(0, -200, 0, 0)  -- Beschriftung gehört zur Klickfläche
Widgets.AttachTooltip(trackerCheck, function() return L.SG_SHOW_TRACKER end, function() return L.SG_SHOW_TRACKER_TIP end)
Manager.trackerCheck = trackerCheck

-- Unterseite der Einstellungen zur gezeigten Seite (ohne eigene: Tracker)
function Manager.SettingsPage()
  local page = pages[shownPage]
  return page and page.settingsPage or ns.SETTINGS_PAGES.TRACKER
end

local settingsButton = Widgets.CreateButton(panel, FOOTER_BUTTON_MIN_WIDTH, Manager.BUTTON_HEIGHT, function()
  ns.Options.Toggle(Manager.SettingsPage())
end)
settingsButton:SetPoint("BOTTOMRIGHT", -MARGIN, 12)
Widgets.AttachTooltip(settingsButton, function() return L.SG_SETTINGS end, function() return L.SG_SETTINGS_TIP end)
Manager.settingsButton = settingsButton
-- Edit-Modus von Level Time (alle Anzeigen samt Ziel-Karten verschieben und skalieren); das Fenster geht dafür zu,
-- damit es die Karten nicht verdeckt (im Kampf startet der Modus nicht, dann bleibt es offen)
local editButton = Widgets.CreateButton(panel, FOOTER_BUTTON_MIN_WIDTH, Manager.BUTTON_HEIGHT, function()
  if LT.EditMode.Enter() then panel:Hide() end
end)
editButton:SetPoint("BOTTOMRIGHT", settingsButton, "BOTTOMLEFT", -FOOTER_BUTTON_GAP, 0)
Widgets.AttachTooltip(editButton, function() return L.EDIT_MODE end, function() return L.EDIT_MODE_TIP end)
Manager.editButton = editButton

---------------------------------------------------------------------------
-- Anzeige aufbauen
---------------------------------------------------------------------------
-- Alle Texte (Sprache!) und die gezeigte Seite neu setzen
function Manager.Refresh()
  title:SetText(L.SG_TITLE)
  for key, page in pairs(pages) do
    page.tab:SetLabel(L[page.label])
    page.tab:SetActive(key == shownPage)
  end
  trackerCheck.label:SetText(L.SG_SHOW_TRACKER)
  trackerCheck:SetChecked(ns.db.settings.showTracker)
  Widgets.SetButtonText(settingsButton, L.SG_SETTINGS, FOOTER_BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(editButton, L.EDIT_MODE, FOOTER_BUTTON_MIN_WIDTH)
  showPage(shownPage)
end

-- Fenster öffnen (mit Seite: diese zeigen) bzw. ohne Seite schließen, wenn es offen ist
function Manager.Toggle(page)
  if not ns.db then return end
  page = PAGE_ALIASES[page] or page
  if panel:IsShown() and not page then
    panel:Hide()
    return
  end
  if page and pages[page] then shownPage = page end
  panel:Show()
  Manager.Refresh()
end

-- Ziele ändern sich auch durch Spielereignisse: gezeigte Seite aktuell halten
Goals.OnChange(function()
  if not panel:IsShown() then return end
  local page = pages[shownPage]
  if page.render then page.render() end
end)

-- Einstellungen und Sprachwechsel bei offenem Fenster
ns.RegisterApply(function()
  if panel:IsShown() then Manager.Refresh() end
end)
