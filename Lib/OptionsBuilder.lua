-- Baukasten für Einstellungsfenster mit Reitern: legt Steuerelemente von oben nach unten auf der
-- aktuellen Seite an und hält sie aktuell.
-- Jedes Steuerelement registriert eine refresh(db)-Funktion; Refresh(db) (nach jeder Änderung über
-- host.set/host.apply) zeigt den aktuellen Stand und die gewählte Sprache.
-- Schalter mit available() == false (z.B. nur in WoW Forever) werden gar nicht angelegt.
-- Abhängige Bausteine: enabled(db) optional bei Schaltern, Reglern, Auswahlzeilen und Auswahllisten; false = ausgegraut
-- und nicht bedienbar (z.B. Einstellungen eines anderen Layouts), geprüft bei jedem Refresh.
-- Tooltips: Text aus L["<LABEL>_TIP"] (fehlt er, gibt es keinen Tooltip), Titel = Beschriftung.
-- Unterseiten (AddSubPage ... FinishSubPages): eine Seite mit Seitenleiste links wie bei Leatrix Plus; je Eintrag
-- eine eigene Unterseite rechts daneben mit denselben Bausteinen (Abschnitte, Schalter in zwei Spalten, ...).
-- Breite: die zwei Schalter-Spalten, Auswahlzeilen und die Reiterzeile bestimmen sie (fitWidth),
-- damit längere Sprachen (fr/es) passen; Höhe: längste Seite bzw. Unterseite plus Buttons unten (Finish).
-- Suche (oben links): jeder Baustein, jede Überschrift, Seite und Unterseite kommt in einen Suchindex (Beschriftung
-- und Tooltip-Text in der gewählten Sprache); ein Treffer zeigt Reiter und Unterseite, scrollt hin und hebt ihn kurz
-- hervor. Gesucht wird nur beim Tippen (linear über alle Einträge, ein paar hundert).
-- Zeilen (Roadmap 402, 405, 406): jeder Add*-Aufruf ist ein Eintrag seiner Seite (Höhe, Anker, Widgets, Abschnitt).
-- Ausgeblendete Einträge (advanced = true im Modus "Einfach", eingeklappter Abschnitt) verschieben die folgenden um
-- ihre Höhe nach oben (relayout); Unterseiten ohne sichtbaren Eintrag fallen aus der Seitenleiste.
-- Zurücksetzen je Unterseite: Bausteine mit setting (Schlüssel in den Einstellungen) oder reset = { get, set, default } liefern,
-- was der Button "Standard" unter der Seitenleiste zurücksetzt (Rückfrage, danach "Rückgängig").
-- Anbindung an das Addon (Sprache, Einstellungen, Chat) über einen host (OptionsBuilder.New({ host }), Toggle);
-- ohne Angabe gilt Level Time (DEFAULT_HOST).
local _, ns = ...
local Widgets = ns.Widgets

local OptionsBuilder = {}
ns.OptionsBuilder = OptionsBuilder

-- host = { L = Texte, db() -> Einstellungen, set(key, value), apply(), default(key) -> Standardwert,
--          copy(value) -> Kopie eines Werts (Rückgängig), print(message) }
local DEFAULT_HOST = {
  L = ns.L,
  db = function() return ns.db end,
  set = function(key, value) ns.Set(key, value) end,
  apply = function() ns.ApplySettings() end,
  default = function(key) return ns.Database.SettingDefault(key) end,
  copy = function(value) return ns.Database.CopyValue(value) end,
  print = function(message) ns.Print(message) end,
}
OptionsBuilder.DEFAULT_HOST = DEFAULT_HOST
local L = DEFAULT_HOST.L  -- statische Helfer (Localized); im Fenster gilt host.L

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
local BUTTON_TEXT_PADDING = Widgets.BUTTON_TEXT_PADDING  -- Rand im Button links und rechts zusammen
local FOOTER_COLUMN_GAP = 8     -- Abstand zwischen den beiden Button-Spalten unten
local COLUMN_GAP = 12        -- Mindestabstand zwischen einer Beschriftung und der rechten Spalte
local ROW_SECTION = 24
local ROW_CHECKBOX = 26
local ROW_SLIDER = 44
local ROW_CHOOSER = 26
local ROW_HINT = 30
local SECTION_GAP = 8
local MAX_CHOOSER_TABS = 4   -- mehr Möglichkeiten zeigt AddChooser als Auswahlliste (AddDropdown) statt als Reiter
local DROPDOWN_ARROW = "Interface\\Buttons\\Arrow-Down-Up"
local DROPDOWN_ARROW_SIZE = 14
local DROPDOWN_ARROW_INSET = 6
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
local SEARCH_WIDTH = 150         -- Suchfeld oben links
local SEARCH_TOP = -10
local SEARCH_MIN_CHARS = 2       -- kürzere Eingaben suchen nicht (zu viele Treffer)
local SEARCH_MAX_RESULTS = 10    -- so viele Treffer listet die Ergebnisliste, der Rest als "... und n weitere"
local SEARCH_ROW = 18
local SEARCH_PADDING = 6
local SEARCH_RESULTS_TOP = SEARCH_TOP - 24  -- Ergebnisliste unter dem Suchfeld, über Reitern und Inhalt
local SEARCH_WHERE_GAP = 12     -- Abstand zwischen Beschriftung und "Reiter > Unterseite" in der Ergebnisliste
local HIGHLIGHT_PADDING = 3      -- Rand der Hervorhebung um einen gefundenen Baustein
local HIGHLIGHT_SECONDS = 2
local HIGHLIGHT_ALPHA = 0.3
local SIDEBAR_BUTTON_GAP = 12      -- Abstand zwischen Seitenleiste und "Standard"
local SIDEBAR_BUTTON_MIN_WIDTH = 80
local MODE_RIGHT = 32              -- Schalter "Erweitert": Platz für den Schließen-Knopf rechts daneben
local MODE_TOP = SEARCH_TOP + 1
local COLLAPSED_MARK, EXPANDED_MARK = "+", "-"  -- vor einklappbaren Überschriften

-- Für eigene Bausteine des Fensters (z.B. Profil-Liste)
OptionsBuilder.MARGIN = MARGIN
OptionsBuilder.ROW_BUTTON = 30
OptionsBuilder.BUTTON_HEIGHT = 22
OptionsBuilder.CHOOSER_TAB_GAP = 10
local ROW_BUTTON = OptionsBuilder.ROW_BUTTON
local BUTTON_HEIGHT = OptionsBuilder.BUTTON_HEIGHT
local CHOOSER_TAB_GAP = OptionsBuilder.CHOOSER_TAB_GAP

-- Schalter für eine Einstellung; available() optional (z.B. nur in WoW Forever), host optional (Standard: Level Time)
function OptionsBuilder.Toggle(label, key, available, host)
  host = host or DEFAULT_HOST
  return {
    label = label,
    get = function(db) return db[key] end,
    set = function(checked) host.set(key, checked) end,
    available = available,
    setting = key,  -- Zurücksetzen je Unterseite
  }
end

-- Zurücksetzen eines Bausteins: Schlüssel in den Einstellungen (Standard aus host.default) oder eigene Funktionen
-- reset = { get() -> Wert, set(Wert), default() -> Wert }. Liste, da ein Baustein mehrere Einstellungen tragen kann.
local function resetsOf(definition, host)
  local list = {}
  if not definition then return list end
  local keys = definition.resetKeys or (definition.setting and { definition.setting }) or {}
  for _, key in ipairs(keys) do
    table.insert(list, {
      get = function() return host.copy(host.db()[key]) end,
      set = function(value) host.db()[key] = value end,
      default = function() return host.default(key) end,
    })
  end
  if definition.reset then table.insert(list, definition.reset) end
  return list
end

-- Text aus den Locales zum Zeitpunkt der Anzeige (Sprachwechsel live)
function OptionsBuilder.Localized(key)
  return function() return L[key] end
end

-- Neues Fenster: options = { name (globaler Frame-Name), alpha, title() -> Text, host (optional, siehe DEFAULT_HOST),
--   hideSingleTab (optional: bei nur einer Seite keine Reiterzeile) }
function OptionsBuilder.New(options)
  local builder = {}
  local host = options.host or DEFAULT_HOST
  local L = host.L

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
  local wantedHeight        -- Höhe der längsten Seite (Finish); begrenzt auf maxPanelHeight

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
  local pageTabs = ns.TabStrip.New(panel, { font = "GameFontNormal", left = MARGIN, top = TABS_TOP, gap = TAB_GAP })
  -- options.hideSingleTab: bei genau einer Seite keine Reiterzeile, der Inhalt rückt um ihre Höhe nach oben (Finish)
  local tabsHidden = false
  local nextRowY = CONTENT_TOP
  local sidebars = {}       -- { startY, entries = { { button, frame, bottom } } } je Seite mit Unterseiten
  local sidebar             -- Seitenleiste, deren Unterseiten gerade angelegt werden
  local currentTab, currentSub  -- Reiter und Unterseite der Bausteine, die gerade angelegt werden (Suchindex)
  local shownTab            -- gezeigter Reiter; bleibt beim Schließen erhalten (zuletzt offene Seite)

  local catchUp  -- unten definiert: verborgene Seiten nachholen, die jetzt sichtbar sind

  -------------------------------------------------------------------------
  -- Einträge je Seite: { owner, startY, height, anchors = { { widget, y, stretch } }, widgets, section, advanced,
  -- resets, cells (Schalter), shift (aktueller Versatz nach oben), hidden }
  -------------------------------------------------------------------------
  local itemsOf = {}           -- [Seite] = { Eintrag, ... } in Reihenfolge
  local currentItem            -- Eintrag, der gerade angelegt wird
  local sectionOf = {}         -- [Seite] = Abschnitts-Eintrag, unter dem neue Einträge landen
  local collapsed = {}         -- [Abschnitts-Eintrag] = true: eingeklappt (nur bis /reload)

  local function beginItem(definition, isSection)
    local item = {
      owner = page, startY = nextRowY, anchors = {}, widgets = {}, shift = 0, placedShift = 0, hidden = false,
      advanced = definition and definition.advanced or false, resets = resetsOf(definition, host),
      section = not isSection and sectionOf[page] or nil, isSection = isSection,
    }
    itemsOf[page] = itemsOf[page] or {}
    table.insert(itemsOf[page], item)
    if isSection then sectionOf[page] = item end
    currentItem = item
    return item
  end

  local function endItem()
    currentItem.height = currentItem.startY - nextRowY
    currentItem = nil
  end

  -- Widget gehört zum laufenden Eintrag (wird mit ihm aus- und eingeblendet)
  local function track(widget)
    if currentItem then table.insert(currentItem.widgets, widget) end
    return widget
  end

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
    tab.scroll:ScrollTo(-SCROLL_TOP + (CONTENT_TOP - (y or CONTENT_TOP)))
  end

  -- Unterseite wählen; der Reiter springt nach oben, weil Unterseiten verschieden lang sind
  local function showSubPage(bar, selected)
    bar.shown = selected
    for _, entry in ipairs(bar.entries) do
      entry.frame:SetShown(entry == selected)
      entry.button:SetActive(entry == selected)
    end
    if bar.updateButtons then bar.updateButtons() end
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

  local function index(title, tipKey, left, right, y, cell)
    table.insert(searchEntries, {
      title = title, tipKey = tipKey, left = left, right = right or left, parent = page, y = y or nextRowY,
      tab = currentTab, sub = currentSub, item = currentItem, cell = cell,
    })
  end

  -- Aktuelle Zeile eines Treffers (Einträge können nach oben gerückt sein)
  local function entryY(entry)
    if entry.cell then return entry.cell.y end
    return entry.y + (entry.item and entry.item.shift or 0)
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
    if entry.where then return entry.where() end
    local where = L[entry.tab.key]
    if entry.sub then where = where .. " > " .. L[entry.sub.key] end
    return where
  end

  -- Gefundenen Baustein kurz hervorheben: eine Fläche über ihm, nach HIGHLIGHT_SECONDS wieder weg
  local highlight = CreateFrame("Frame", nil, panel)
  highlight.texture = highlight:CreateTexture(nil, "OVERLAY")
  highlight.texture:SetAllPoints(highlight)
  highlight:Hide()
  local highlightToken = 0

  local function showHighlight(entry)
    highlight:SetParent(entry.parent)
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", entry.left, "TOPLEFT", -HIGHLIGHT_PADDING, HIGHLIGHT_PADDING)
    highlight:SetPoint("BOTTOMRIGHT", entry.right, "BOTTOMRIGHT", HIGHLIGHT_PADDING, -HIGHLIGHT_PADDING)
    local r, g, b = unpack(Widgets.COLORS.highlight)
    highlight.texture:SetColorTexture(r, g, b, HIGHLIGHT_ALPHA)
    highlight:Show()
    highlightToken = highlightToken + 1
    local token = highlightToken
    C_Timer.After(HIGHLIGHT_SECONDS, function()
      if token == highlightToken then highlight:Hide() end
    end)
  end

  -- Treffer zeigen: Reiter, Unterseite, Zeile oben im sichtbaren Bereich, kurz hervorgehoben
  local unhide  -- unten definiert: Eintrag sichtbar machen (Modus "Erweitert", Abschnitt aufklappen)

  function builder.Reveal(entry)
    unhide(entry)
    if entry.sub then builder.ShowPage(entry.sub.key) else showPage(entry.tab) end
    if entry.isPage then return end
    scrollTo(entry.tab, entryY(entry))
    showHighlight(entry)
  end

  function builder.Highlighted()
    return highlight:IsShown() and highlight or nil
  end

  -------------------------------------------------------------------------
  -- Suchfeld oben links und Ergebnisliste darunter (über Reitern und Inhalt); Klick oder Enter zeigt den Treffer
  -------------------------------------------------------------------------
  local searchBox = CreateFrame("EditBox", options.name .. "Search", panel, "InputBoxTemplate")
  searchBox:SetSize(SEARCH_WIDTH, BUTTON_HEIGHT)
  searchBox:SetAutoFocus(false)
  searchBox:SetPoint("TOPLEFT", MARGIN + TEXT_INPUT_BORDER, SEARCH_TOP)
  local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  placeholder:SetPoint("LEFT", 2, 0)
  placeholder:SetTextColor(unpack(Widgets.COLORS.muted))

  local results = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  results:SetFrameStrata("FULLSCREEN_DIALOG")
  results:SetPoint("TOPLEFT", MARGIN, SEARCH_RESULTS_TOP)
  results:SetPoint("TOPRIGHT", -MARGIN, SEARCH_RESULTS_TOP)
  results:Hide()
  ns.Theme.RegisterPanel(results, 1)
  local resultRows = {}  -- angelegt bei Bedarf, höchstens SEARCH_MAX_RESULTS + 1 (Zeile "... und n weitere")
  local rowEntries = {}  -- [Zeilennummer] = Treffer; false = Zeile ohne Sprung ("nichts gefunden", "... weitere")

  local function clearSearch()
    searchBox:SetText("")
    searchBox:ClearFocus()
    placeholder:Show()
    results:Hide()
  end

  -- Klick auf eine Zeile: Feld leeren, Treffer zeigen (Zeilen ohne Treffer tun nichts)
  local function openResult(index)
    local entry = rowEntries[index]
    if not entry then return end
    clearSearch()
    builder.Reveal(entry)
  end

  local function resultRow(index)
    local row = resultRows[index]
    if row then return row end
    row = CreateFrame("Button", nil, results)
    row:SetHeight(SEARCH_ROW)
    row:SetPoint("TOPLEFT", SEARCH_PADDING, -SEARCH_PADDING - (index - 1) * SEARCH_ROW)
    row:SetPoint("TOPRIGHT", -SEARCH_PADDING, -SEARCH_PADDING - (index - 1) * SEARCH_ROW)
    row.where = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.where:SetPoint("RIGHT")
    row.where:SetTextColor(unpack(Widgets.COLORS.muted))
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT")
    row.text:SetPoint("RIGHT", row.where, "LEFT", -SEARCH_WHERE_GAP, 0)
    row.text:SetJustifyH("LEFT")
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(row)
    local r, g, b = unpack(Widgets.COLORS.highlight)
    hover:SetColorTexture(r, g, b, HIGHLIGHT_ALPHA / 2)
    row:SetScript("OnClick", function() openResult(index) end)
    resultRows[index] = row
    return row
  end

  local matches = {}
  local function updateResults()
    local query = strtrim(searchBox:GetText() or "")
    placeholder:SetShown(query == "" and not searchBox:HasFocus())
    if #query < SEARCH_MIN_CHARS then
      matches = {}
      results:Hide()
      return
    end
    matches = builder.Search(query)
    local shown = math.min(#matches, SEARCH_MAX_RESULTS)
    for i = 1, shown do
      local row = resultRow(i)
      rowEntries[i] = matches[i]
      row.text:SetText(matches[i].title())
      row.where:SetText(builder.WhereOf(matches[i]))
      row:Show()
    end
    local lines = shown
    if #matches == 0 or #matches > shown then
      lines = shown + 1
      local row = resultRow(lines)
      rowEntries[lines] = false
      row.text:SetText(#matches == 0 and L.OPTIONS_SEARCH_NONE or string.format(L.OPTIONS_SEARCH_MORE, #matches - shown))
      row.where:SetText("")
      row:Show()
    end
    for i = lines + 1, #resultRows do resultRows[i]:Hide() end
    results:SetHeight(lines * SEARCH_ROW + 2 * SEARCH_PADDING)
    results:Show()
  end

  searchBox:SetScript("OnTextChanged", updateResults)
  searchBox:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
  searchBox:SetScript("OnEditFocusLost", function() placeholder:SetShown((searchBox:GetText() or "") == "") end)
  searchBox:SetScript("OnEscapePressed", clearSearch)
  searchBox:SetScript("OnEnterPressed", function()
    local first = matches[1]
    clearSearch()
    if first then builder.Reveal(first) end
  end)
  Widgets.AttachTooltip(searchBox, localized("OPTIONS_SEARCH"), localized("OPTIONS_SEARCH_TIP"))
  panel:HookScript("OnHide", clearSearch)

  -- Für Tests: Suchtext setzen wie beim Tippen, Zeilen der Ergebnisliste
  function builder.SetSearchText(text)
    searchBox:SetText(text)
    updateResults()
  end
  function builder.SearchResultRows()
    local rows = {}
    for i, row in ipairs(resultRows) do
      if row:IsShown() and results:IsShown() then
        table.insert(rows, {
          text = row.text:GetText(), where = row.where:GetText(), entry = rowEntries[i] or nil,
          click = function() openResult(i) end,
        })
      end
    end
    return rows
  end

  -- Neue Seite beginnen; folgende Add*-Aufrufe landen darauf
  function builder.AddPage(labelKey)
    -- Jede Seite scrollt: Inhalt (frame) in einem Scrollbereich zwischen Reitern und Buttons. Die Inhaltskoordinaten
    -- bleiben die des Fensters (y ab Fensteroberkante); der Bereich beginnt bei SCROLL_TOP, daher steht er
    -- ruhend um -SCROLL_TOP verschoben.
    local scroll = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, top = -SCROLL_TOP, keepInRange = true })
    local entry = { key = labelKey, scroll = scroll, frame = CreateFrame("Frame", nil, scroll) }
    -- Gültige Breite von Anfang an (fitWidth setzt die endgültige): Texte, die der Client bei Breite 0 setzt, zeichnet
    -- er nicht, bis sich der Text ändert (Seitenleiste und "Standard" blieben nach /reload leer)
    entry.frame:SetWidth(panel:GetWidth())
    currentTab, currentSub = entry, nil
    scroll:SetScrollChild(entry.frame)
    entry.tabButton = pageTabs:Add(function() showPage(entry) end)
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

  local createSidebarButtons  -- unten definiert: "Standard" und "Rückgängig" unter der Seitenleiste

  -- Unterseiten abschließen: weiter auf der Seite unter der längsten Unterseite bzw. der Seitenleiste
  function builder.FinishSubPages()
    local entries = sidebar.entries
    entries[#entries].bottom = nextRowY
    local lowest = sidebar.startY - #entries * SIDEBAR_ROW
    for _, entry in ipairs(entries) do lowest = math.min(lowest, entry.bottom) end
    page = sidebar.parent
    nextRowY = lowest
    createSidebarButtons(sidebar)
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
    if currentItem then
      table.insert(currentItem.anchors, { widget = widget, y = nextRowY, stretch = stretch })
      track(widget)
    end
    nextRowY = nextRowY - height
  end
  local addRow = builder.AddRow

  -- Abschnitt; options = { collapsible = true (Klick klappt ein/aus), advanced = true } optional
  function builder.AddSection(labelKey, options)
    local item = beginItem(options, true)
    if nextRowY ~= CONTENT_TOP then nextRowY = nextRowY - SECTION_GAP end
    local header = Widgets.CreateSectionHeader(page)
    index(localized(labelKey), nil, header)
    addRow(header, ROW_SECTION, true)
    local collapsible = options and options.collapsible
    local function text()
      if not collapsible then return L[labelKey] end
      return (collapsed[item] and COLLAPSED_MARK or EXPANDED_MARK) .. " " .. L[labelKey]
    end
    if collapsible then
      item.collapsible = true
      header:EnableMouse(true)
      header:SetScript("OnMouseUp", function() builder.SetCollapsed(item, not collapsed[item]) end)
      addTooltip(header, "SECTION_COLLAPSE_TIP", localized(labelKey))
      item.refreshHeader = function() header:SetText(text()) end
    end
    onRefresh(function() header:SetText(text()) end)
    endItem()
  end

  -- slider = { label, min, max, step, get(db) -> Wert, set(Wert), format(Wert) -> Anzeigetext, setting/reset optional }
  function builder.AddSlider(slider)
    beginItem(slider)
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
    endItem()
  end

  -- Checkboxen in zwei Spalten; toggle = { label, get(db) -> bool, set(checked), available() optional,
  --   text() optional statt L[label], z.B. für Beschriftungen mit Werten, tip = Locale-Key optional,
  --   advanced optional (nur im Modus "Erweitert"), setting/reset optional (Zurücksetzen) }
  -- Ein ausgeblendeter Schalter (advanced) rückt die folgenden der Gruppe nach (relayout)
  function builder.AddToggles(allToggles)
    local toggles = {}
    for _, toggle in ipairs(allToggles) do
      if not toggle.available or toggle.available() then table.insert(toggles, toggle) end
    end
    local item = beginItem(nil)
    item.cells = {}
    for i, toggle in ipairs(toggles) do
      local column = (i - 1) % 2
      local row = math.floor((i - 1) / 2)
      local checkbox = Widgets.CreateCheckbox(page, toggle.set)
      local y = nextRowY - row * ROW_CHECKBOX
      local cell = { checkbox = checkbox, column = column, y = y, advanced = toggle.advanced }
      table.insert(toggleCells, cell)
      table.insert(item.cells, cell)
      for _, reset in ipairs(resetsOf(toggle, host)) do table.insert(item.resets, reset) end
      local tipKey = toggle.tip or (toggle.label .. "_TIP")
      local function title() return checkbox.label:GetText() end
      addTooltip(checkbox, tipKey, title)
      index(title, tipKey, checkbox, checkbox.label, y, cell)
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
    endItem()
  end

  -- Eine Zeile gleich breiter Buttons: buttons = { { label = Locale-Key, onClick }, ... }; Tooltip aus <label>_TIP;
  -- options = { advanced } optional
  local buttonRows = {}
  function builder.AddButtonRow(buttons, options)
    beginItem(options)
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
    endItem()
  end

  -- options = { advanced } optional
  function builder.AddButton(labelKey, onClick, options)
    beginItem(options)
    local button = Widgets.CreateButton(page, MIN_WIDTH - 2 * MARGIN, BUTTON_HEIGHT, onClick)
    index(localized(labelKey), labelKey .. "_TIP", button)
    addRow(button, ROW_BUTTON, true)
    addTooltip(button, labelKey .. "_TIP", localized(labelKey))
    onRefresh(function() button:SetText(L[labelKey]) end)
    endItem()
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

  -- Auswahl als Zeile von Reitern: chooser = { label = Locale-Key, setting, choices = { { value, name() }, ... },
  -- advanced optional }
  -- Mehr als MAX_CHOOSER_TABS Auswahlmöglichkeiten passen nicht mehr als Reiter in eine Zeile: dann AddDropdown
  function builder.AddChooser(chooser)
    if #chooser.choices > MAX_CHOOSER_TABS then
      local names = {}
      local choices = {}
      for i, choice in ipairs(chooser.choices) do
        choices[i] = { key = choice.value }
        names[choice.value] = choice.name
      end
      return builder.AddDropdown({
        label = chooser.label, setting = chooser.setting, advanced = chooser.advanced, enabled = chooser.enabled,
        choices = function() return choices end,
        get = function(db) return db[chooser.setting] end,
        set = function(value) host.set(chooser.setting, value) end,
        nameOf = function(value) return names[value] and names[value]() or tostring(value) end,
      })
    end
    beginItem(chooser)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local row = { label = label, tabs = {} }
    table.insert(chooserRows, row)
    local anchor = label
    for _, choice in ipairs(chooser.choices) do
      local tab = track(Widgets.CreateTab(page, "GameFontHighlight", function()
        host.set(chooser.setting, choice.value)
      end))
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
    endItem()
  end

  -- Auswahl aus einer langen oder veränderlichen Liste als Button hinter der Beschriftung (Roadmap 477): ein Klick öffnet
  -- die Liste (Lib/Dropdown.lua) mit Suchfeld ab 8 Einträgen, Gruppen-Überschriften und Pfeiltasten.
  -- dropdown = { label = Locale-Key, choices() -> { { key, name optional, group optional, font optional } }, get(db) -> key,
  -- set(key), nameOf(key) -> Text für Anzeige und Liste (wenn name fehlt), setting/reset/advanced/enabled optional };
  -- group = Überschrift (Text) über dem ersten Eintrag der Gruppe, die Einträge einer Gruppe stehen nebeneinander;
  -- font = Schriftpfad, in dem der Eintrag in der Liste steht; Tooltip aus <label>_TIP
  function builder.AddDropdown(dropdown)
    beginItem(dropdown)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local button
    button = track(Widgets.CreateButton(page, BUTTON_ROW_MIN_WIDTH, BUTTON_HEIGHT, function()
      if ns.Dropdown.IsOpen() then return ns.Dropdown.Close() end
      local entries = {}
      for i, choice in ipairs(dropdown.choices()) do
        entries[i] = { key = choice.key, text = choice.name or dropdown.nameOf(choice.key), group = choice.group,
          font = choice.font }
      end
      ns.Dropdown.Open(button, {
        entries = entries,
        current = dropdown.get(host.db()),
        onPick = dropdown.set,
      })
    end))
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture(DROPDOWN_ARROW)
    arrow:SetSize(DROPDOWN_ARROW_SIZE, DROPDOWN_ARROW_SIZE)
    arrow:SetPoint("RIGHT", -DROPDOWN_ARROW_INSET, 0)
    button.label:ClearAllPoints()
    button.label:SetPoint("CENTER", -DROPDOWN_ARROW_SIZE / 2, 0)
    button:SetPoint("LEFT", label, "RIGHT", CHOOSER_TAB_GAP, 0)
    addTooltip(button, dropdown.label .. "_TIP", localized(dropdown.label))
    table.insert(chooserRows, { label = label, tabs = { button } })
    index(localized(dropdown.label), dropdown.label .. "_TIP", label, button)
    nextRowY = nextRowY - ROW_CHOOSER
    onRefresh(function(db)
      setMeasuredText(label, "SetText", L[dropdown.label])
      if setMeasuredText(button, "SetText", dropdown.nameOf(dropdown.get(db))) then
        Widgets.SetButtonText(button, button:GetText(), BUTTON_ROW_MIN_WIDTH)
        button:SetWidth(button:GetWidth() + DROPDOWN_ARROW_SIZE)
      end
      applyEnabled(dropdown.enabled, db, label, button)
    end)
    endItem()
  end

  -- Eingabefeld hinter einer Beschriftung: input = { label = Locale-Key, get(db) -> Text, set(Text), width optional,
  -- setting/advanced optional }; übernommen mit Enter oder beim Verlassen des Felds, Esc verwirft; Tooltip aus <label>_TIP
  function builder.AddTextInput(input)
    beginItem(input)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local box = track(CreateFrame("EditBox", nil, page, "InputBoxTemplate"))
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
    endItem()
  end

  -- options = { advanced } optional
  function builder.AddHint(labelKey, options)
    beginItem(options)
    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetTextColor(unpack(Widgets.COLORS.muted))
    hint:SetJustifyH("LEFT")
    addRow(hint, ROW_HINT, true)
    onRefresh(function() hint:SetText(L[labelKey]) end)
    endItem()
  end

  -- Höher als der Bildschirm wird das Fenster nicht; der Rest scrollt (Mausrad)
  local function maxPanelHeight()
    return math.floor(UIParent:GetHeight() * MAX_SCREEN_FRACTION / panel:GetScale())
  end

  -- Nach dem letzten Baustein: Höhe für die längste Seite, damit das Fenster beim Reiterwechsel
  -- nicht springt; erste Seite zeigen
  -- Für Tests: Reiterzeile verborgen (hideSingleTab mit genau einer Seite)
  function builder.TabsHidden()
    return tabsHidden
  end

  function builder.Finish()
    local lowestBottom = CONTENT_TOP
    for _, entry in ipairs(pages) do
      lowestBottom = math.min(lowestBottom, entry.bottom)
    end
    -- Eine einzige Seite (hideSingleTab): Reiter verbergen; der Scrollbereich beginnt um die Reiterzeile höher, die
    -- Inhaltskoordinaten bleiben dieselben (Suche, Hervorheben und Bildlauf rechnen weiter ab CONTENT_TOP)
    tabsHidden = options.hideSingleTab == true and #pages == 1
    local tabRowHeight = tabsHidden and TABS_TOP - CONTENT_TOP or 0
    if tabsHidden then pages[1].tabButton:Hide() end
    local footerHeight = footerRows() * ROW_BUTTON + MARGIN
    local wanted = -lowestBottom + FOOTER_GAP + footerHeight - tabRowHeight
    wantedHeight = wanted
    panel:SetHeight(math.min(wanted, maxPanelHeight()))
    for _, entry in ipairs(pages) do
      entry.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, SCROLL_TOP + tabRowHeight)
      entry.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, footerHeight)
      entry.frame:SetHeight(-lowestBottom + FOOTER_GAP)
      entry.scroll:SetVerticalScroll(-SCROLL_TOP)
    end
    -- Schalter "Erweitert" in der Suche: liegt über allen Reitern, Treffer zeigt den ersten
    if builder.modeCheckbox then
      table.insert(searchEntries, {
        title = localized(options.advanced.label), tipKey = options.advanced.label .. "_TIP",
        left = builder.modeCheckbox, right = builder.modeCheckbox.label, parent = panel, y = CONTENT_TOP,
        tab = pages[1], where = options.title,
      })
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

  -- Versatz der Unterseiten: breitester Eintrag der Seitenleiste plus Abstand (0 ohne Unterseiten)
  local function sidebarOffset()
    local widest = 0
    for _, bar in ipairs(sidebars) do
      for _, entry in ipairs(bar.entries) do widest = math.max(widest, entry.button:GetWidth()) end
      widest = math.max(widest, bar.resetButton:GetWidth(), bar.undoButton:GetWidth())
    end
    return widest > 0 and widest + SIDEBAR_GAP or 0
  end

  -- Platz, den ein Button für seinen Text braucht
  local function fitButton(button)
    return button:GetTextWidth() + BUTTON_TEXT_PADDING
  end

  -- Beide Button-Spalten sind gleich breit: so breit wie der längste Text, doppelt plus Abstand
  local function footerWidth()
    local widest = 0
    for _, button in ipairs(footerButtons) do widest = math.max(widest, fitButton(button)) end
    return 2 * widest + FOOTER_COLUMN_GAP
  end

  -- Eine Button-Zeile braucht Platz für alle Texte nebeneinander
  local function buttonRowsWidth()
    local widest = 0
    for _, widgets in ipairs(buttonRows) do
      local width = BUTTON_ROW_GAP * (#widgets - 1)
      for _, button in ipairs(widgets) do width = width + fitButton(button) end
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
    -- Titel steht mittig: links und rechts je Platz für das Suchfeld
    local titleRow = title:GetStringWidth() + 2 * (SEARCH_WIDTH + TEXT_INPUT_BORDER + MARGIN)
    local content = math.max(offset + 2 * column, widestChooserRow(), tabsHidden and 0 or pageTabs:Width(), footerWidth(),
      buttonRowsWidth(), titleRow)
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

  -------------------------------------------------------------------------
  -- Zeilen neu anordnen (Modus "Einfach", eingeklappte Abschnitte): ausgeblendete Einträge rücken die folgenden um
  -- ihre Höhe nach oben; nur bei Moduswechsel und Klick auf einen Abschnitt, nie im Takt
  -------------------------------------------------------------------------
  local advancedShown = true  -- zuletzt angewendeter Modus (ohne Schalter immer "Erweitert")
  local hasShownItems = {}    -- [Seite] = false: kein sichtbarer Eintrag (fällt aus der Seitenleiste)

  local function isAdvanced(db)
    if not options.advanced or not db then return true end
    return options.advanced.get(db) and true or false
  end

  local function setItemHidden(item, hidden)
    if item.hidden == hidden then return end
    item.hidden = hidden
    for _, widget in ipairs(item.widgets) do widget:SetShown(not hidden) end
    if item.cells then
      for _, cell in ipairs(item.cells) do cell.checkbox:SetShown(not hidden and not cell.modeHidden) end
    end
  end

  -- Schalter einer Gruppe: ausgeblendete fallen weg, die übrigen rücken in zwei Spalten nach; Rückgabe: Höhe
  local function layoutCells(item, top)
    local shown = 0
    for _, cell in ipairs(item.cells) do
      cell.checkbox:SetShown(not item.hidden and not cell.modeHidden)
      if not cell.modeHidden then
        cell.column = shown % 2
        cell.y = top - math.floor(shown / 2) * ROW_CHECKBOX
        shown = shown + 1
      end
    end
    layoutStale = true  -- fitWidth setzt die Schalter an ihre (neuen) Zeilen
    return math.ceil(shown / 2) * ROW_CHECKBOX
  end

  -- Sichtbarkeit nach Modus: advanced-Einträge und -Schalter nur im Modus "Erweitert"; ein Abschnitt fällt weg, wenn
  -- alle seine Einträge weggefallen sind
  local function applyMode(list)
    local sectionHasShown = {}
    for _, item in ipairs(list) do
      item.modeHidden = item.advanced and not advancedShown
      if item.cells and not item.modeHidden then
        local any = false
        for _, cell in ipairs(item.cells) do
          cell.modeHidden = cell.advanced and not advancedShown or false
          any = any or not cell.modeHidden
        end
        item.modeHidden = not any and #item.cells > 0
      elseif item.cells then
        for _, cell in ipairs(item.cells) do cell.modeHidden = true end
      end
      if item.section and not item.modeHidden then sectionHasShown[item.section] = true end
    end
    for _, item in ipairs(list) do
      if item.isSection and not item.modeHidden then
        local hasItems = false
        for _, other in ipairs(list) do
          if other.section == item then hasItems = true end
        end
        if hasItems and not sectionHasShown[item] then item.modeHidden = true end
      end
    end
  end

  local function relayout(owner)
    local list = itemsOf[owner]
    if not list then return end
    applyMode(list)
    local shift = 0
    local shownCount = 0
    for _, item in ipairs(list) do
      local hidden = item.modeHidden or (item.section ~= nil and collapsed[item.section] == true)
      setItemHidden(item, hidden)
      item.shift = shift
      if hidden then
        shift = shift + item.height
      else
        if not item.isSection then shownCount = shownCount + 1 end
        if item.placedShift ~= shift then
          item.placedShift = shift
          for _, anchor in ipairs(item.anchors) do
            anchor.widget:ClearAllPoints()
            anchor.widget:SetPoint("TOPLEFT", MARGIN, anchor.y + shift)
            if anchor.stretch then anchor.widget:SetPoint("TOPRIGHT", -MARGIN, anchor.y + shift) end
          end
        end
        if item.cells then shift = shift + item.height - layoutCells(item, item.startY + shift) end
      end
      if item.refreshHeader then item.refreshHeader() end
    end
    hasShownItems[owner] = shownCount > 0
  end

  -- Seitenleiste: Unterseiten ohne sichtbaren Eintrag fallen weg; darunter "Standard" und "Rückgängig"
  local function relayoutSidebar(bar)
    local row = 0
    local firstShown
    for _, entry in ipairs(bar.entries) do
      local shown = hasShownItems[entry.frame] ~= false
      entry.button:SetShown(shown)
      if shown then
        entry.button:ClearAllPoints()
        entry.button:SetPoint("TOPLEFT", MARGIN, bar.startY - row * SIDEBAR_ROW)
        row = row + 1
        firstShown = firstShown or entry
      end
    end
    local y = bar.startY - row * SIDEBAR_ROW - SIDEBAR_BUTTON_GAP
    bar.resetButton:ClearAllPoints()
    bar.resetButton:SetPoint("TOPLEFT", MARGIN, y)
    bar.undoButton:ClearAllPoints()
    bar.undoButton:SetPoint("TOPLEFT", MARGIN, y - ROW_BUTTON)
    if bar.shown and hasShownItems[bar.shown.frame] == false and firstShown then showSubPage(bar, firstShown) end
  end

  local function relayoutAll()
    for owner in pairs(itemsOf) do relayout(owner) end
    for _, bar in ipairs(sidebars) do relayoutSidebar(bar) end
  end

  -- Modus der Einstellungen angleichen (nach jedem Apply; neu angeordnet wird nur bei einem Wechsel)
  local function syncMode(db)
    local wanted = isAdvanced(db)
    if wanted == advancedShown then return end
    advancedShown = wanted
    relayoutAll()
  end

  -- Abschnitt ein- oder ausklappen (Klick auf die Überschrift, Suche)
  function builder.SetCollapsed(item, isCollapsed)
    collapsed[item] = isCollapsed and true or nil
    relayout(item.owner)
    for _, bar in ipairs(sidebars) do relayoutSidebar(bar) end
    finishRefresh()
  end

  function builder.IsCollapsed(item)
    return collapsed[item] == true
  end

  -- Abschnitts-Eintrag zu einer Überschrift (Locale-Key) auf einer Unterseite oder Seite (Tests, Suche)
  function builder.SectionOf(labelKey)
    for _, entry in ipairs(searchEntries) do
      if entry.item and entry.item.isSection and entry.title() == L[labelKey] then return entry.item end
    end
  end

  -- Gefundener Eintrag ist ausgeblendet: Modus "Erweitert" bzw. Abschnitt aufklappen
  function unhide(entry)
    local item = entry.item
    if not item then return end
    if item.modeHidden or (entry.cell and entry.cell.modeHidden) then options.advanced.set(true) end
    if item.section and collapsed[item.section] then builder.SetCollapsed(item.section, false) end
    if item.isSection and collapsed[item] then builder.SetCollapsed(item, false) end
  end

  -- Für Tests: wird der Baustein gerade angezeigt (nicht per Modus oder Einklappen weg)?
  function builder.IsEntryShown(entry)
    if not entry.item then return true end
    return not entry.item.hidden and not (entry.cell and entry.cell.modeHidden)
  end

  -------------------------------------------------------------------------
  -- Zurücksetzen je Unterseite (Roadmap 405): Werte vorher merken (bis /reload), Standard setzen, ein Apply
  -------------------------------------------------------------------------
  local backups = {}  -- [Unterseiten-Eintrag] = { { reset, value }, ... }
  local RESET_POPUP = options.name .. "_RESET_PAGE"

  local function resetsOfPage(entry)
    local list = {}
    for _, item in ipairs(itemsOf[entry.frame] or {}) do
      for _, reset in ipairs(item.resets) do table.insert(list, reset) end
    end
    return list
  end

  local function subPageEntry(labelKey)
    for _, bar in ipairs(sidebars) do
      for _, entry in ipairs(bar.entries) do
        if entry.key == labelKey then return entry end
      end
    end
  end

  -- Unterseite (Locale-Key) auf Standard; false = unbekannt oder nichts zurückzusetzen
  function builder.ResetPage(labelKey)
    local entry = subPageEntry(labelKey)
    local resets = entry and resetsOfPage(entry) or {}
    if #resets == 0 then return false end
    local backup = {}
    for i, reset in ipairs(resets) do backup[i] = { reset = reset, value = reset.get() } end
    for _, reset in ipairs(resets) do reset.set(reset.default()) end
    backups[entry] = backup
    host.print(string.format(L.OPTIONS_RESET_DONE, L[entry.key]))
    host.apply()
    return true
  end

  -- Letztes Zurücksetzen dieser Unterseite rückgängig machen
  function builder.UndoReset(labelKey)
    local entry = subPageEntry(labelKey)
    local backup = entry and backups[entry]
    if not backup then return false end
    for _, saved in ipairs(backup) do saved.reset.set(saved.value) end
    backups[entry] = nil
    host.print(string.format(L.OPTIONS_RESET_UNDONE, L[entry.key]))
    host.apply()
    return true
  end

  -- Schlüssel, die "Standard" auf einer Unterseite zurücksetzt (Tests)
  function builder.ResetCount(labelKey)
    local entry = subPageEntry(labelKey)
    return entry and #resetsOfPage(entry) or 0
  end

  local confirmReset = Widgets.ConfirmPopup(RESET_POPUP, "OPTIONS_RESET_CONFIRM", function(labelKey) builder.ResetPage(labelKey) end)

  function createSidebarButtons(bar)
    bar.resetButton = Widgets.CreateButton(bar.parent, SIDEBAR_BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
      local entry = bar.shown
      if not entry then return end
      confirmReset(L[entry.key], entry.key)
    end)
    bar.undoButton = Widgets.CreateButton(bar.parent, SIDEBAR_BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
      if bar.shown then builder.UndoReset(bar.shown.key) end
    end)
    addTooltip(bar.resetButton, "OPTIONS_RESET_PAGE_TIP", localized("OPTIONS_RESET_PAGE"))
    addTooltip(bar.undoButton, "OPTIONS_RESET_UNDO_TIP", localized("OPTIONS_RESET_UNDO"))
    function bar.updateButtons()
      local entry = bar.shown
      bar.resetButton:SetShown(entry ~= nil and #resetsOfPage(entry) > 0)
      bar.undoButton:SetShown(entry ~= nil and backups[entry] ~= nil)
    end
    addRefresher(function()
      if setMeasuredText(bar.resetButton, "SetText", L.OPTIONS_RESET_PAGE) then
        Widgets.SetButtonText(bar.resetButton, L.OPTIONS_RESET_PAGE, SIDEBAR_BUTTON_MIN_WIDTH)
      end
      if setMeasuredText(bar.undoButton, "SetText", L.OPTIONS_RESET_UNDO) then
        Widgets.SetButtonText(bar.undoButton, L.OPTIONS_RESET_UNDO, SIDEBAR_BUTTON_MIN_WIDTH)
      end
      bar.updateButtons()
    end, bar.parent)
    relayoutSidebar(bar)
  end

  -------------------------------------------------------------------------
  -- Schalter "Erweitert" oben rechts neben dem Schließen-Knopf (Roadmap 402)
  -------------------------------------------------------------------------
  if options.advanced then
    local mode = Widgets.CreateCheckbox(panel, function(checked) options.advanced.set(checked) end)
    builder.modeCheckbox = mode
    addTooltip(mode, options.advanced.label .. "_TIP", localized(options.advanced.label))
    addRefresher(function(db)
      mode:SetChecked(isAdvanced(db))
      if setMeasuredText(mode.label, "SetText", L[options.advanced.label]) then
        mode:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + mode.label:GetStringWidth()), 0, 0)
        mode:ClearAllPoints()
        mode:SetPoint("TOPRIGHT", -(MODE_RIGHT + Widgets.CHECKBOX_LABEL_GAP + mode.label:GetStringWidth()), MODE_TOP)
      end
    end, nil)
  end


  -- Alle Steuerelemente, auch auf verborgenen Seiten (Öffnen, Sprachwechsel, Profilliste)
  function builder.Refresh(db)
    refreshPending = false
    refreshedLanguage = db.language
    for owner in pairs(stale) do stale[owner] = nil end
    syncMode(db)
    setMeasuredText(title, "SetText", options.title())  -- Breite zählt für das Suchfeld daneben (fitWidth)
    placeholder:SetText(L.OPTIONS_SEARCH)
    for _, refresher in ipairs(refreshers) do
      refresher.run(db)
    end
    finishRefresh()
  end

  -- Nur die sichtbaren; verborgene Seiten merken sich, dass sie beim Zeigen nachholen müssen
  local function refreshVisible(db)
    syncMode(db)
    setMeasuredText(title, "SetText", options.title())
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
    if not next(stale) or not host.db() or not panel:IsShown() then return end
    local done
    for _, refresher in ipairs(refreshers) do
      local owner = refresher.owner
      if owner and stale[owner] and owner:IsVisible() then
        refresher.run(host.db())
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
    if refreshPending and host.db() then builder.Refresh(host.db()) else catchUp() end
  end)

  return builder
end
