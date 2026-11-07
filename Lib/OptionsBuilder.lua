-- Baukasten für Einstellungsfenster mit Reitern: legt Steuerelemente von oben nach unten auf der
-- aktuellen Seite an und hält sie aktuell.
-- Jedes Steuerelement registriert eine refresh(db)-Funktion; Refresh(db) (nach jeder Änderung über
-- ns.Set/ns.ApplySettings) zeigt den aktuellen Stand und die gewählte Sprache.
-- Schalter mit available() == false (z.B. nur in WoW Forever) werden gar nicht angelegt.
-- Abhängige Bausteine: enabled(db) optional bei Schaltern, Reglern, Auswahlzeilen und Zyklus-Buttons; false = ausgegraut
-- und nicht bedienbar (z.B. Einstellungen eines anderen Layouts), geprüft bei jedem Refresh.
-- Tooltips: Text aus L["<LABEL>_TIP"] (fehlt er, gibt es keinen Tooltip), Titel = Beschriftung.
-- Unterseiten (AddSubPage ... FinishSubPages): eine Seite mit Seitenleiste links wie bei Leatrix Plus; je Eintrag
-- eine eigene Unterseite rechts daneben mit denselben Bausteinen (Abschnitte, Schalter in zwei Spalten, ...).
-- Breite: die zwei Schalter-Spalten, Auswahlzeilen und die Reiterzeile bestimmen sie (fitWidth),
-- damit längere Sprachen (fr/es) passen; Höhe: längste Seite bzw. Unterseite plus Buttons unten (Finish).
-- Suchindex: jeder Baustein, jede Überschrift, Seite und Unterseite kommt in einen Index (Beschriftung und
-- Tooltip-Text in der gewählten Sprache), Search(query) liefert die Treffer.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local OptionsBuilder = {}
ns.OptionsBuilder = OptionsBuilder

local MIN_WIDTH = 320
local MARGIN = 16
local TABS_TOP = -42
local TAB_GAP = 12
local CONTENT_TOP = -70
local FOOTER_GAP = 8         -- Abstand zwischen Reiterinhalt und den Buttons unten
local MIN_COLUMN_WIDTH = 144
local SCROLL_TOP = CONTENT_TOP + 8  -- Oberkante des scrollbaren Bereichs unter den Reitern
local SCROLL_STEP = 40               -- Pixel je Mausrad-Raste
local MAX_SCREEN_FRACTION = 0.9      -- höher als dieser Anteil des Bildschirms wird das Fenster nicht
local BUTTON_ROW_GAP = 6          -- Abstand zwischen Buttons einer Zeile
local BUTTON_ROW_MIN_WIDTH = 60
local BUTTON_TEXT_PADDING = 24   -- Rand im Button links und rechts zusammen
local FOOTER_COLUMN_GAP = 8     -- Abstand zwischen den beiden Button-Spalten unten
local FOOTER_TEXT_PADDING = 24  -- Rand im Button links und rechts zusammen
local COLUMN_GAP = 12        -- Mindestabstand zwischen einer Beschriftung und der rechten Spalte
local ROW_SECTION = 24
local ROW_CHECKBOX = 26
local ROW_SLIDER = 44
local ROW_CHOOSER = 26
local ROW_HINT = 30
local SECTION_GAP = 8
local DISABLED_ALPHA = 0.4   -- ausgegraute Bausteine (enabled(db) == false)

-- Bausteine nach enabled(db) bedienbar oder ausgegraut; ohne enabled immer bedienbar
local function applyEnabled(enabled, db, ...)
  if not enabled then return end
  local on = enabled(db) and true or false
  for index = 1, select("#", ...) do
    local widget = select(index, ...)
    widget:SetAlpha(on and 1 or DISABLED_ALPHA)
    widget:EnableMouse(on)
  end
end
local SIDEBAR_ROW = 24       -- Höhe eines Eintrags der Seitenleiste
local SIDEBAR_GAP = 16       -- Abstand zwischen Seitenleiste und Unterseite
local TEXT_INPUT_WIDTH = 120 -- Standardbreite eines Eingabefelds (AddTextInput)
local TEXT_INPUT_BORDER = 6  -- InputBoxTemplate zeichnet seinen Rand links außerhalb

-- Für eigene Bausteine des Fensters (z.B. Profil-Liste)
OptionsBuilder.MARGIN = MARGIN
OptionsBuilder.ROW_BUTTON = 30
OptionsBuilder.BUTTON_HEIGHT = 22
OptionsBuilder.CHOOSER_TAB_GAP = 10
local ROW_BUTTON = OptionsBuilder.ROW_BUTTON
local BUTTON_HEIGHT = OptionsBuilder.BUTTON_HEIGHT
local CHOOSER_TAB_GAP = OptionsBuilder.CHOOSER_TAB_GAP

-- Schalter für eine Einstellung in ns.db; available() optional (z.B. nur in WoW Forever)
function OptionsBuilder.Toggle(label, key, available)
  return {
    label = label,
    get = function(db) return db[key] end,
    set = function(checked) ns.Set(key, checked) end,
    available = available,
  }
end

-- Text aus den Locales zum Zeitpunkt der Anzeige (Sprachwechsel live)
function OptionsBuilder.Localized(key)
  return function() return L[key] end
end

-- Neues Fenster: options = { name (globaler Frame-Name), alpha, title() -> Text }
function OptionsBuilder.New(options)
  local builder = {}

  local panel = Widgets.CreatePanel(options.name, options.alpha)
  panel:SetWidth(MIN_WIDTH)  -- wächst mit den Texten der gewählten Sprache (fitWidth)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("DIALOG")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  panel:Hide()
  table.insert(UISpecialFrames, options.name)  -- mit ESC schließen
  Widgets.CreateCloseButton(panel)
  builder.panel = panel

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -14)

  -- { run(db), owner }: owner = Seite oder Unterseite, auf der das Steuerelement steht (nil = immer sichtbar: Reiter,
  -- Fuß-Buttons). Bei offenem Fenster aktualisiert ein Apply nur die sichtbaren (Roadmap 395); verborgene Seiten
  -- merken sich das (stale) und holen es beim Umschalten nach.
  local refreshers = {}
  local stale = {}          -- [owner] = true: Einstellungen geändert, während die Seite verborgen war
  local toggleCells = {}    -- { checkbox, column, y } aller Schalter; Spaltenbreite setzt fitWidth
  local chooserRows = {}    -- { label, tabs } je Auswahlzeile; Breite prüft fitWidth
  local page                -- Seite, auf der die Bausteine gerade anlegen

  local function addRefresher(refresh, owner)
    table.insert(refreshers, { run = refresh, owner = owner })
  end

  function builder.OnRefresh(refresh)
    addRefresher(refresh, page)
  end
  local onRefresh = builder.OnRefresh

  -- Texte, deren Breite fitWidth misst (Reiter, Schalter, Auswahlzeilen, Buttons): nur bei geändertem Text setzen;
  -- Messen und neu Anordnen (fitWidth) nur, wenn sich mindestens einer geändert hat (Sprachwechsel, Werte in
  -- Beschriftungen), nicht bei jeder Einstellungsänderung. true = Text hat sich geändert.
  local measuredTexts = {}  -- [Widget] = zuletzt gesetzter Text
  local layoutStale = true
  local function setMeasuredText(widget, method, text)
    if measuredTexts[widget] == text then return false end
    measuredTexts[widget] = text
    widget[method](widget, text)
    layoutStale = true
    return true
  end

  -------------------------------------------------------------------------
  -- Reiter: je Reiter eine Seite über das ganze Fenster; Steuerelemente hängen an ihrer Seite
  -------------------------------------------------------------------------
  local pages = {}          -- { key, tabButton, frame, bottom } in Reihenfolge
  local nextRowY = CONTENT_TOP
  local sidebars = {}       -- { startY, entries = { { button, frame, bottom } } } je Seite mit Unterseiten
  local sidebar             -- Seitenleiste, deren Unterseiten gerade angelegt werden
  local currentTab, currentSub  -- Reiter und Unterseite der Bausteine, die gerade angelegt werden (Suchindex)
  local shownTab            -- gezeigter Reiter; bleibt beim Schließen erhalten (zuletzt offene Seite)

  local catchUp  -- unten definiert: verborgene Seiten nachholen, die jetzt sichtbar sind

  local function showPage(selected)
    shownTab = selected
    for _, entry in ipairs(pages) do
      entry.scroll:SetShown(entry == selected)
      entry.tabButton:SetActive(entry == selected)
    end
    catchUp()
  end

  -- Seite nach oben scrollen bzw. so weit, dass die Zeile y oben steht (Inhalt in Fensterkoordinaten, s. AddPage)
  local function scrollTo(tab, y)
    local scroll = tab.scroll
    local target = -SCROLL_TOP + (CONTENT_TOP - (y or CONTENT_TOP))
    scroll:SetVerticalScroll(math.max(-SCROLL_TOP, math.min(scroll:GetVerticalScrollRange(), target)))
  end

  -- Unterseite wählen; der Reiter springt nach oben, weil Unterseiten verschieden lang sind
  local function showSubPage(bar, selected)
    bar.shown = selected
    for _, entry in ipairs(bar.entries) do
      entry.frame:SetShown(entry == selected)
      entry.button:SetActive(entry == selected)
    end
    scrollTo(bar.tab)
    catchUp()
  end

  -- Reiter oder Unterseite nach dem Locale-Key zeigen (z.B. "Einstellungen" einer Anzeige im Edit-Modus); eine
  -- Unterseite zeigt auch ihren Reiter. false = unbekannt
  function builder.ShowPage(labelKey)
    for _, entry in ipairs(pages) do
      if entry.key == labelKey then
        showPage(entry)
        return true
      end
    end
    for _, bar in ipairs(sidebars) do
      for _, entry in ipairs(bar.entries) do
        if entry.key == labelKey then
          showPage(bar.tab)
          showSubPage(bar, entry)
          return true
        end
      end
    end
    return false
  end

  -- Gezeigter Reiter und, falls er Unterseiten hat, die gezeigte Unterseite (Locale-Keys)
  function builder.CurrentPage()
    if not shownTab then return nil end
    for _, bar in ipairs(sidebars) do
      if bar.tab == shownTab then return shownTab.key, bar.shown and bar.shown.key end
    end
    return shownTab.key
  end

  -- Alle Reiter und Unterseiten als { tab = Key, sub = Key oder nil } in Fensterreihenfolge (Tests, Suche)
  function builder.PageKeys()
    local list = {}
    for _, tab in ipairs(pages) do
      local bar
      for _, candidate in ipairs(sidebars) do
        if candidate.tab == tab then bar = candidate end
      end
      if bar then
        for _, entry in ipairs(bar.entries) do table.insert(list, { tab = tab.key, sub = entry.key }) end
      else
        table.insert(list, { tab = tab.key })
      end
    end
    return list
  end

  -------------------------------------------------------------------------
  -- Suchindex: { title() -> Text, tipKey, left/right (Ränder der Hervorhebung), parent, y, tab, sub, isPage }
  -------------------------------------------------------------------------
  local searchEntries = {}
  local localized = OptionsBuilder.Localized

  local function index(title, tipKey, left, right, y)
    table.insert(searchEntries, {
      title = title, tipKey = tipKey, left = left, right = right or left, parent = page, y = y or nextRowY,
      tab = currentTab, sub = currentSub,
    })
  end

  local function contains(text, needle)
    return text ~= nil and text:lower():find(needle, 1, true) ~= nil
  end

  -- Treffer zu query (Groß-/Kleinschreibung egal): erst Beschriftungen, dann Tooltip-Texte, je in Fensterreihenfolge
  function builder.Search(query)
    local needle = strtrim(query or ""):lower()
    if needle == "" then return {} end
    local byTitle, byTip = {}, {}
    for _, entry in ipairs(searchEntries) do
      if contains(entry.title(), needle) then
        table.insert(byTitle, entry)
      elseif entry.tipKey then
        local tip = L[entry.tipKey]
        if tip ~= entry.tipKey and contains(tip, needle) then table.insert(byTip, entry) end
      end
    end
    for _, entry in ipairs(byTip) do table.insert(byTitle, entry) end
    return byTitle
  end

  -- Wo ein Treffer liegt: "Reiter > Unterseite"
  function builder.WhereOf(entry)
    local where = L[entry.tab.key]
    if entry.sub then where = where .. " > " .. L[entry.sub.key] end
    return where
  end

  -- Neue Seite beginnen; folgende Add*-Aufrufe landen darauf
  function builder.AddPage(labelKey)
    -- Jede Seite scrollt: Inhalt (frame) in einem Scrollbereich zwischen Reitern und Buttons. Die Inhaltskoordinaten
    -- bleiben die des Fensters (y ab Fensteroberkante); der Bereich beginnt bei SCROLL_TOP, daher steht er
    -- ruhend um -SCROLL_TOP verschoben.
    local scroll = CreateFrame("ScrollFrame", nil, panel)
    local entry = { key = labelKey, scroll = scroll, frame = CreateFrame("Frame", nil, scroll) }
    currentTab, currentSub = entry, nil
    scroll:SetScrollChild(entry.frame)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
      local target = self:GetVerticalScroll() - delta * SCROLL_STEP
      self:SetVerticalScroll(math.max(-SCROLL_TOP, math.min(self:GetVerticalScrollRange(), target)))
    end)
    scroll:SetScript("OnScrollRangeChanged", function(self, _, yRange)
      local current = self:GetVerticalScroll()
      self:SetVerticalScroll(math.max(-SCROLL_TOP, math.min(yRange, current)))
    end)
    entry.tabButton = Widgets.CreateTab(panel, "GameFontNormal", function() showPage(entry) end)
    local previous = pages[#pages]
    if previous then
      entry.tabButton:SetPoint("LEFT", previous.tabButton, "RIGHT", TAB_GAP, 0)
    else
      entry.tabButton:SetPoint("TOPLEFT", MARGIN, TABS_TOP)
    end
    table.insert(pages, entry)
    page = entry.frame
    nextRowY = CONTENT_TOP
    index(localized(labelKey), nil, entry.tabButton)
    searchEntries[#searchEntries].isPage = true
    addRefresher(function() setMeasuredText(entry.tabButton, "SetLabel", L[labelKey]) end, nil)
  end

  -- Neue Unterseite der aktuellen Seite mit Eintrag in der Seitenleiste; folgende Add*-Aufrufe landen darauf.
  -- Die Unterseite deckt die Seite ab (gleiche y-Koordinaten), nur nach rechts versetzt (fitWidth).
  function builder.AddSubPage(labelKey)
    if not sidebar then
      sidebar = { parent = page, tab = currentTab, startY = nextRowY, entries = {} }
      table.insert(sidebars, sidebar)
    else
      sidebar.entries[#sidebar.entries].bottom = nextRowY
    end
    local bar = sidebar
    local entry = { key = labelKey, frame = CreateFrame("Frame", nil, bar.parent) }
    entry.frame:SetPoint("TOPLEFT")
    entry.frame:SetPoint("BOTTOMRIGHT")
    entry.button = Widgets.CreateTab(bar.parent, "GameFontNormal", function() showSubPage(bar, entry) end)
    entry.button:SetPoint("TOPLEFT", MARGIN, bar.startY - #bar.entries * SIDEBAR_ROW)
    table.insert(bar.entries, entry)
    page = entry.frame
    nextRowY = bar.startY
    currentSub = entry
    index(localized(labelKey), nil, entry.button)
    searchEntries[#searchEntries].isPage = true
    addRefresher(function() setMeasuredText(entry.button, "SetLabel", L[labelKey]) end, bar.parent)
  end

  -- Unterseiten abschließen: weiter auf der Seite unter der längsten Unterseite bzw. der Seitenleiste
  function builder.FinishSubPages()
    local entries = sidebar.entries
    entries[#entries].bottom = nextRowY
    local lowest = sidebar.startY - #entries * SIDEBAR_ROW
    for _, entry in ipairs(entries) do lowest = math.min(lowest, entry.bottom) end
    page = sidebar.parent
    nextRowY = lowest
    showSubPage(sidebar, entries[1])
    sidebar, currentSub = nil, nil
  end

  -- Seite abschließen: wie weit sie nach unten reicht (für die Fensterhöhe)
  function builder.FinishPage()
    pages[#pages].bottom = nextRowY
  end

  -- Für eigene Bausteine: aktuelle Seite, y der nächsten Zeile, Zeile weiterschieben
  function builder.Page() return page end
  function builder.RowY() return nextRowY end
  function builder.Advance(height) nextRowY = nextRowY - height end

  -------------------------------------------------------------------------
  -- Bausteine: legen Steuerelemente auf der aktuellen Seite von oben nach unten an
  -------------------------------------------------------------------------

  -- Tooltip aus L[tipKey]; L liefert bei fehlendem Text den Schlüssel, dann kein Tooltip
  function builder.AddTooltip(frame, tipKey, tooltipTitle)
    Widgets.AttachTooltip(frame, tooltipTitle, function()
      local text = L[tipKey]
      if text == tipKey then return nil end
      return text
    end)
  end
  local addTooltip = builder.AddTooltip

  function builder.AddRow(widget, height, stretch)
    widget:SetPoint("TOPLEFT", MARGIN, nextRowY)
    if stretch then widget:SetPoint("TOPRIGHT", -MARGIN, nextRowY) end
    nextRowY = nextRowY - height
  end
  local addRow = builder.AddRow

  function builder.AddSection(labelKey)
    if nextRowY ~= CONTENT_TOP then nextRowY = nextRowY - SECTION_GAP end
    local header = Widgets.CreateSectionHeader(page)
    index(localized(labelKey), nil, header)
    addRow(header, ROW_SECTION, true)
    onRefresh(function() header:SetText(L[labelKey]) end)
  end

  -- slider = { label, min, max, step, get(db) -> Wert, set(Wert), format(Wert) -> Anzeigetext }
  function builder.AddSlider(slider)
    local control = Widgets.CreateSlider(page, slider.min, slider.max, slider.step, slider.set)
    index(localized(slider.label), slider.label .. "_TIP", control)
    addRow(control, ROW_SLIDER, true)
    addTooltip(control.slider, slider.label .. "_TIP", localized(slider.label))
    onRefresh(function(db)
      local value = slider.get(db)
      control.label:SetText(L[slider.label])
      control:SetValueSilently(value, slider.format(value))
      applyEnabled(slider.enabled, db, control, control.slider)
    end)
  end

  -- Checkboxen in zwei Spalten; toggle = { label, get(db) -> bool, set(checked), available() optional,
  --   text() optional statt L[label], z.B. für Beschriftungen mit Werten, tip = Locale-Key optional }
  function builder.AddToggles(allToggles)
    local toggles = {}
    for _, toggle in ipairs(allToggles) do
      if not toggle.available or toggle.available() then table.insert(toggles, toggle) end
    end
    for i, toggle in ipairs(toggles) do
      local column = (i - 1) % 2
      local row = math.floor((i - 1) / 2)
      local checkbox = Widgets.CreateCheckbox(page, toggle.set)
      local y = nextRowY - row * ROW_CHECKBOX
      table.insert(toggleCells, { checkbox = checkbox, column = column, y = y })
      local tipKey = toggle.tip or (toggle.label .. "_TIP")
      local function title() return checkbox.label:GetText() end
      addTooltip(checkbox, tipKey, title)
      index(title, tipKey, checkbox, checkbox.label, y)
      onRefresh(function(db)
        checkbox:SetChecked(toggle.get(db))
        applyEnabled(toggle.enabled, db, checkbox)
        if setMeasuredText(checkbox.label, "SetText", toggle.text and toggle.text() or L[toggle.label]) then
          -- Beschriftung gehört zur Klick- und Tooltip-Fläche
          checkbox:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + checkbox.label:GetStringWidth()), 0, 0)
        end
      end)
    end
    nextRowY = nextRowY - math.ceil(#toggles / 2) * ROW_CHECKBOX
  end

  -- Eine Zeile gleich breiter Buttons: buttons = { { label = Locale-Key, onClick }, ... }; Tooltip aus <label>_TIP
  local buttonRows = {}
  function builder.AddButtonRow(buttons)
    local row = CreateFrame("Frame", nil, page)
    row:SetHeight(BUTTON_HEIGHT)
    addRow(row, ROW_BUTTON, true)
    local widgets = {}
    for i, definition in ipairs(buttons) do
      local button = Widgets.CreateButton(row, BUTTON_ROW_MIN_WIDTH, BUTTON_HEIGHT, definition.onClick)
      if i == 1 then
        button:SetPoint("TOPLEFT", row, "TOPLEFT")
      else
        button:SetPoint("LEFT", widgets[i - 1], "RIGHT", BUTTON_ROW_GAP, 0)
      end
      addTooltip(button, definition.label .. "_TIP", localized(definition.label))
      index(localized(definition.label), definition.label .. "_TIP", button)
      onRefresh(function() setMeasuredText(button, "SetText", L[definition.label]) end)
      widgets[i] = button
    end
    -- Breite gleichmäßig auf die Buttons verteilen, sobald die Zeile ihre Größe kennt
    row:SetScript("OnSizeChanged", function(_, width)
      local each = (width - BUTTON_ROW_GAP * (#widgets - 1)) / #widgets
      for _, button in ipairs(widgets) do button:SetWidth(math.max(BUTTON_ROW_MIN_WIDTH, each)) end
    end)
    table.insert(buttonRows, widgets)
  end

  function builder.AddButton(labelKey, onClick)
    local button = Widgets.CreateButton(page, MIN_WIDTH - 2 * MARGIN, BUTTON_HEIGHT, onClick)
    index(localized(labelKey), labelKey .. "_TIP", button)
    addRow(button, ROW_BUTTON, true)
    addTooltip(button, labelKey .. "_TIP", localized(labelKey))
    onRefresh(function() button:SetText(L[labelKey]) end)
  end

  -- Buttons unten auf allen Reitern in zwei Spalten, Zeilen von unten nach oben
  local footerButtons = {}
  local function footerRows()
    return math.ceil(#footerButtons / 2)
  end
  function builder.AddFooterButton(labelKey, onClick)
    local button = Widgets.CreateButton(panel, MIN_WIDTH / 2, BUTTON_HEIGHT, onClick)
    local index = #footerButtons
    local y = MARGIN + math.floor(index / 2) * ROW_BUTTON
    if index % 2 == 0 then
      button:SetPoint("BOTTOMLEFT", MARGIN, y)
      button:SetPoint("BOTTOMRIGHT", panel, "BOTTOM", -FOOTER_COLUMN_GAP / 2, y)
    else
      button:SetPoint("BOTTOMLEFT", panel, "BOTTOM", FOOTER_COLUMN_GAP / 2, y)
      button:SetPoint("BOTTOMRIGHT", -MARGIN, y)
    end
    table.insert(footerButtons, button)
    addTooltip(button, labelKey .. "_TIP", localized(labelKey))
    addRefresher(function() setMeasuredText(button, "SetText", L[labelKey]) end, nil)
  end

  -- Auswahl als Zeile von Reitern: chooser = { label = Locale-Key, setting, choices = { { value, name() }, ... } }
  function builder.AddChooser(chooser)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local row = { label = label, tabs = {} }
    table.insert(chooserRows, row)
    local anchor = label
    for _, choice in ipairs(chooser.choices) do
      local tab = Widgets.CreateTab(page, "GameFontHighlight", function()
        ns.Set(chooser.setting, choice.value)
      end)
      tab:SetPoint("LEFT", anchor, "RIGHT", CHOOSER_TAB_GAP, 0)
      anchor = tab
      table.insert(row.tabs, tab)
      addTooltip(tab, chooser.label .. "_TIP", localized(chooser.label))
      onRefresh(function(db)
        setMeasuredText(tab, "SetLabel", choice.name())
        tab:SetActive(db[chooser.setting] == choice.value)
        applyEnabled(chooser.enabled, db, tab)
      end)
    end
    index(localized(chooser.label), chooser.label .. "_TIP", label, row.tabs[#row.tabs])
    nextRowY = nextRowY - ROW_CHOOSER
    onRefresh(function() setMeasuredText(label, "SetText", L[chooser.label]) end)
  end

  -- Auswahl aus einer langen oder veränderlichen Liste als ein Button hinter der Beschriftung: Linksklick nächster,
  -- Rechtsklick voriger Eintrag. cycle = { label = Locale-Key, choices() -> { { key, name } }, get(db) -> key,
  -- set(key), nameOf(key) -> Text für die Anzeige }; Tooltip aus <label>_TIP
  function builder.AddCycleButton(cycle)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local button = Widgets.CreateButton(page, BUTTON_ROW_MIN_WIDTH, BUTTON_HEIGHT, function(_, mouseButton)
      local choices = cycle.choices()
      local current = cycle.get(ns.db)
      local index = 1
      for i, choice in ipairs(choices) do
        if choice.key == current then index = i end
      end
      local step = mouseButton == "RightButton" and -1 or 1
      cycle.set(choices[(index - 1 + step) % #choices + 1].key)
    end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetPoint("LEFT", label, "RIGHT", CHOOSER_TAB_GAP, 0)
    addTooltip(button, cycle.label .. "_TIP", localized(cycle.label))
    table.insert(chooserRows, { label = label, tabs = { button } })
    index(localized(cycle.label), cycle.label .. "_TIP", label, button)
    nextRowY = nextRowY - ROW_CHOOSER
    onRefresh(function(db)
      setMeasuredText(label, "SetText", L[cycle.label])
      if setMeasuredText(button, "SetText", cycle.nameOf(cycle.get(db))) then
        Widgets.SetButtonText(button, button:GetText(), BUTTON_ROW_MIN_WIDTH)
      end
      applyEnabled(cycle.enabled, db, label, button)
    end)
  end

  -- Eingabefeld hinter einer Beschriftung: input = { label = Locale-Key, get(db) -> Text, set(Text), width optional };
  -- übernommen mit Enter oder beim Verlassen des Felds, Esc verwirft; Tooltip aus <label>_TIP
  function builder.AddTextInput(input)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local box = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    box:SetSize(input.width or TEXT_INPUT_WIDTH, BUTTON_HEIGHT)
    box:SetAutoFocus(false)
    box:SetPoint("LEFT", label, "RIGHT", CHOOSER_TAB_GAP + TEXT_INPUT_BORDER, 0)
    local current = ""
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self)
      self:SetText(current)
      self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
      if self:GetText() ~= current then input.set(self:GetText()) end
    end)
    addTooltip(box, input.label .. "_TIP", localized(input.label))
    table.insert(chooserRows, { label = label, tabs = { box } })  -- Breite prüft fitWidth wie bei Auswahlzeilen
    index(localized(input.label), input.label .. "_TIP", label, box)
    nextRowY = nextRowY - ROW_CHOOSER
    onRefresh(function(db)
      setMeasuredText(label, "SetText", L[input.label])
      current = input.get(db) or ""
      if not box:HasFocus() then box:SetText(current) end
    end)
  end

  function builder.AddHint(labelKey)
    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetTextColor(unpack(Widgets.COLORS.muted))
    hint:SetJustifyH("LEFT")
    addRow(hint, ROW_HINT, true)
    onRefresh(function() hint:SetText(L[labelKey]) end)
  end

  -- Nach dem letzten Baustein: Höhe für die längste Seite, damit das Fenster beim Reiterwechsel
  -- nicht springt; erste Seite zeigen
  -- Höher als der Bildschirm wird das Fenster nicht; der Rest scrollt (Mausrad)
  local wantedHeight
  local function maxPanelHeight()
    return math.floor(UIParent:GetHeight() * MAX_SCREEN_FRACTION / panel:GetScale())
  end

  function builder.Finish()
    local lowestBottom = CONTENT_TOP
    for _, entry in ipairs(pages) do
      lowestBottom = math.min(lowestBottom, entry.bottom)
    end
    local footerHeight = footerRows() * ROW_BUTTON + MARGIN
    local wanted = -lowestBottom + FOOTER_GAP + footerHeight
    wantedHeight = wanted
    panel:SetHeight(math.min(wanted, maxPanelHeight()))
    for _, entry in ipairs(pages) do
      entry.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, SCROLL_TOP)
      entry.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, footerHeight)
      entry.frame:SetHeight(-lowestBottom + FOOTER_GAP)
      entry.scroll:SetVerticalScroll(-SCROLL_TOP)
    end
    showPage(pages[1])
  end

  -------------------------------------------------------------------------
  -- Aktualisierung
  -------------------------------------------------------------------------

  -- Zwei Schalter-Spalten so breit wie die längste Beschriftung, damit sich nichts überlappt
  local function columnWidth()
    local width = MIN_COLUMN_WIDTH
    for _, cell in ipairs(toggleCells) do
      local checkbox = cell.checkbox
      width = math.max(width, checkbox:GetWidth() + Widgets.CHECKBOX_LABEL_GAP + checkbox.label:GetStringWidth() + COLUMN_GAP)
    end
    return width
  end

  local function widestChooserRow()
    local widest = 0
    for _, row in ipairs(chooserRows) do
      local width = row.label:GetStringWidth()
      for _, tab in ipairs(row.tabs) do
        width = width + CHOOSER_TAB_GAP + tab:GetWidth()
      end
      widest = math.max(widest, width)
    end
    return widest
  end

  local function tabRowWidth()
    local width = 0
    for i, entry in ipairs(pages) do
      width = width + entry.tabButton:GetWidth() + (i > 1 and TAB_GAP or 0)
    end
    return width
  end

  -- Versatz der Unterseiten: breitester Eintrag der Seitenleiste plus Abstand (0 ohne Unterseiten)
  local function sidebarOffset()
    local widest = 0
    for _, bar in ipairs(sidebars) do
      for _, entry in ipairs(bar.entries) do widest = math.max(widest, entry.button:GetWidth()) end
    end
    return widest > 0 and widest + SIDEBAR_GAP or 0
  end

  -- Beide Button-Spalten sind gleich breit: so breit wie der längste Text, doppelt plus Abstand
  local function footerWidth()
    local widest = 0
    for _, button in ipairs(footerButtons) do
      widest = math.max(widest, button:GetTextWidth() + FOOTER_TEXT_PADDING)
    end
    return 2 * widest + FOOTER_COLUMN_GAP
  end

  -- Eine Button-Zeile braucht Platz für alle Texte nebeneinander
  local function buttonRowsWidth()
    local widest = 0
    for _, widgets in ipairs(buttonRows) do
      local width = BUTTON_ROW_GAP * (#widgets - 1)
      for _, button in ipairs(widgets) do width = width + button:GetTextWidth() + BUTTON_TEXT_PADDING end
      widest = math.max(widest, width)
    end
    return widest
  end

  -- Fensterbreite aus den Texten der gewählten Sprache; Abschnitte, Regler und Buttons strecken sich mit
  local function fitWidth()
    local column = columnWidth()
    for _, cell in ipairs(toggleCells) do
      cell.checkbox:ClearAllPoints()
      cell.checkbox:SetPoint("TOPLEFT", MARGIN + cell.column * column, cell.y)
    end
    local offset = sidebarOffset()
    for _, bar in ipairs(sidebars) do
      for _, entry in ipairs(bar.entries) do
        entry.frame:ClearAllPoints()
        entry.frame:SetPoint("TOPLEFT", offset, 0)
        entry.frame:SetPoint("BOTTOMRIGHT")
      end
    end
    local content = math.max(offset + 2 * column, widestChooserRow(), tabRowWidth(), footerWidth(), buttonRowsWidth())
    panel:SetWidth(math.max(MIN_WIDTH, content + 2 * MARGIN))
    for _, entry in ipairs(pages) do entry.frame:SetWidth(panel:GetWidth()) end
  end

  local refreshPending = false  -- Einstellungen haben sich bei geschlossenem Fenster geändert

  local refreshedLanguage  -- Sprache der letzten vollständigen Aktualisierung

  local function finishRefresh()
    if layoutStale then
      layoutStale = false
      fitWidth()
    end
    -- Bildschirmgröße oder UI-Skalierung können sich geändert haben
    if wantedHeight then panel:SetHeight(math.min(wantedHeight, maxPanelHeight())) end
  end

  -- Alle Steuerelemente, auch auf verborgenen Seiten (Öffnen, Sprachwechsel, Profilliste)
  function builder.Refresh(db)
    refreshPending = false
    refreshedLanguage = db.language
    for owner in pairs(stale) do stale[owner] = nil end
    title:SetText(options.title())
    for _, refresher in ipairs(refreshers) do
      refresher.run(db)
    end
    finishRefresh()
  end

  -- Nur die sichtbaren; verborgene Seiten merken sich, dass sie beim Zeigen nachholen müssen
  local function refreshVisible(db)
    title:SetText(options.title())
    for _, refresher in ipairs(refreshers) do
      local owner = refresher.owner
      if not owner or owner:IsVisible() then
        refresher.run(db)
      else
        stale[owner] = true
      end
    end
    finishRefresh()
  end

  function catchUp()
    if not next(stale) or not ns.db or not panel:IsShown() then return end
    local done
    for _, refresher in ipairs(refreshers) do
      local owner = refresher.owner
      if owner and stale[owner] and owner:IsVisible() then
        refresher.run(ns.db)
        done = done or {}
        done[owner] = true
      end
    end
    if not done then return end
    for owner in pairs(done) do stale[owner] = nil end
    finishRefresh()
  end

  -- Für ns.RegisterApply: nur das offene Fenster aktualisieren (jede Einstellungsänderung ruft das, auch bei
  -- geschlossenem Fenster); geschlossen holt OnShow es nach. Offen nur die sichtbare Seite, außer nach einem
  -- Sprachwechsel (alle Texte und Breiten neu).
  function builder.RefreshIfShown(db)
    if not panel:IsShown() then
      refreshPending = true
    elseif db.language ~= refreshedLanguage then
      builder.Refresh(db)
    else
      refreshVisible(db)
    end
  end

  panel:SetScript("OnShow", function()
    if refreshPending and ns.db then builder.Refresh(ns.db) else catchUp() end
  end)

  return builder
end
