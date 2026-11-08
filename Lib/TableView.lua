-- Tabellen-Ansicht für Fenster mit Reitern (z.B. die Historie): Suchfeld, sortierbare Kopfzeile,
-- Zeilen mit Lazy Load, Summenzeile, CSV-Export und optionale Buttons.
-- Lazy Load: Es gibt nur so viele Zeilen-Widgets, wie sichtbar sind; beim Scrollen (Mausrad oder
-- Leiste) werden sie mit den passenden Einträgen neu gefüllt. So bleiben auch tausende Einträge flüssig.
-- Spalten: header = Locale-Key, value(record) = Zellentext, width, align = "LEFT" für Text
-- (Standard: erste Spalte links, Zahlen rechts), sort(record) = Sortierschlüssel, wenn der Zellentext
-- formatiert ist (Dauer, Gold, Datum); sonst wird nach value sortiert. volatile = true: Wert kann sich ohne neuen
-- Eintrag ändern (nur für appendOnly wichtig, siehe TableOrder.lua). Reihenfolge, Filter: TableOrder.lua.
-- tip = Locale-Key optional: erklärt die Spalte im Tooltip des Kopfes; ohne tip gilt <header>_TIP, wenn es den Text
-- gibt (eine Erklärung je Spaltenkopf, in allen Tabellen gleich), sonst zeigt er den Sortier-Hinweis.
-- Werkzeugzeile: Export und weitere Buttons links (so breit wie ihr Text), Suchfeld rechts; reicht der Platz nicht
-- (lange Sprachen, viele Buttons), wird das Suchfeld schmaler und rutscht notfalls in eine zweite Zeile.
local _, ns = ...
local Widgets = ns.Widgets
local Format = ns.Format

local TableView = {}
ns.TableView = TableView

local ROW_HEIGHT = 16
local CELL_GAP = 6
local SCROLLBAR_GAP = 6
local REFRESH_SECONDS = 5  -- so oft werden Zeilen ohne erkennbare Änderung spätestens neu aufgebaut
local WHEEL_STEP = 3  -- Zeilen pro Mausrad-Raste
local WHITE = { 1, 1, 1 }
local LEFT, RIGHT = "LEFT", "RIGHT"
local TOOLBAR_HEIGHT = 22     -- Zeile mit dem Suchfeld über der Tabelle
local HINT_LINE_HEIGHT = 12  -- je Zeile des Hinweises unter der Summenzeile (sonst überdeckt er die Summen)
local MAX_HINT_LINES = 3     -- längere Hinweise bricht der Hinweis um, darüber hinaus wird er abgeschnitten
local FILTER_WIDTH = 150
local FILTER_MIN_WIDTH = 90    -- schmaler wird das Suchfeld nicht, dann bekommt es eine eigene Zeile
local FILTER_HEIGHT = 18
local FILTER_LABEL_GAP = 8     -- Abstand "Filter" zum Feld (InputBoxTemplate zeichnet seinen Rand links außerhalb)
local TOOLBAR_GAP = 6          -- Abstand zwischen den Buttons und zwischen Buttons und "Filter"
local EXPORT_BUTTON_WIDTH = 70
local EXTRA_BUTTON_WIDTH = 90   -- weitere Buttons der Ansicht (definition.buttons), Mindestbreite
-- Vor dem Text: bei schmalen Spalten wird das Ende abgeschnitten, die Richtung bleibt so sichtbar
local SORT_DESCENDING = "v "
local SORT_ASCENDING = "^ "

---------------------------------------------------------------------------
-- Tabelle mit fester Zeilenzahl (Lazy Load)
---------------------------------------------------------------------------
local function tableWidth(columns)
  local width = 0
  for _, column in ipairs(columns) do
    width = width + column.width
  end
  return width
end

local function createRow(parent, columns, fontObject)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(tableWidth(columns), ROW_HEIGHT)
  row.cells = {}
  local x = 0
  for i, column in ipairs(columns) do
    local cell = row:CreateFontString(nil, "OVERLAY", fontObject)
    cell:SetPoint("LEFT", x, 0)
    cell:SetWidth(column.width - CELL_GAP)
    cell:SetJustifyH(column.align or (i == 1 and LEFT or RIGHT))
    cell:SetWordWrap(false)
    row.cells[i] = cell
    x = x + column.width
  end
  return row
end

-- Spaltenbreiten aus den Kopftexten der gewählten Sprache (UX 203): jede Spalte mindestens so breit wie ihr Kopf samt
-- Sortierzeichen; was zusätzlich gebraucht wird, geben die Spalten mit Spielraum über ihrem Kopf anteilig ab, damit
-- die Tabelle ihre Gesamtbreite behält. Reicht der Spielraum nicht und die Tabelle würde breiter als maxTotal (Platz
-- links der Bildlaufleiste), geben die gewachsenen Spalten das Zuviel anteilig wieder ab; ihr Kopf wird dann
-- abgeschnitten (voller Text im Tooltip). Rückgabe: Breite je Spalte
local SORT_MARKER_WIDTH = 10  -- Platz für "v "/"^ " vor dem Kopf

-- Zuviel über maxTotal (mindestens die festgelegte Gesamtbreite) von den Spalten nehmen, die gewachsen sind
local function capWidths(columns, widths, maxTotal)
  local sum, grown = 0, 0
  for i, column in ipairs(columns) do
    sum = sum + widths[i]
    grown = grown + math.max(0, widths[i] - column.width)
  end
  local excess = sum - math.max(maxTotal, tableWidth(columns))  -- nie schmaler als festgelegt
  if excess <= 0 or grown <= 0 then return widths end
  local share = math.min(1, excess / grown)
  for i, column in ipairs(columns) do
    local growth = math.max(0, widths[i] - column.width)
    widths[i] = widths[i] - math.ceil(growth * share)
  end
  return widths
end

local function fittedWidths(columns, headerCells, maxTotal)
  local widths, needs, total, extra = {}, {}, 0, 0
  for i, column in ipairs(columns) do
    local need = math.ceil(headerCells[i]:GetStringWidth() or 0) + CELL_GAP + SORT_MARKER_WIDTH
    needs[i] = need
    widths[i] = math.max(column.width, need)
    extra = extra + widths[i] - column.width
    total = total + column.width
  end
  if extra <= 0 then return widths end
  local slack = 0
  for i in ipairs(columns) do slack = slack + math.max(0, widths[i] - needs[i]) end
  local share = slack > 0 and math.min(1, extra / slack) or 0
  local roomiest, sum = nil, 0
  for i in ipairs(columns) do
    local spare = math.max(0, widths[i] - needs[i])
    widths[i] = widths[i] - math.floor(spare * share)
    sum = sum + widths[i]
    if not roomiest or widths[i] - needs[i] > widths[roomiest] - needs[roomiest] then roomiest = i end
  end
  -- Rundungsrest nimmt die Spalte mit dem meisten Spielraum
  local overshoot = sum - total
  if overshoot > 0 and widths[roomiest] - overshoot >= needs[roomiest] then
    widths[roomiest] = widths[roomiest] - overshoot
  end
  return capWidths(columns, widths, maxTotal)
end

-- Zellen einer Zeile auf neue Spaltenbreiten setzen
local function placeCells(row, widths)
  local x = 0
  for i, cell in ipairs(row.cells) do
    cell:ClearAllPoints()
    cell:SetPoint("LEFT", x, 0)
    cell:SetWidth(widths[i] - CELL_GAP)
    x = x + widths[i]
  end
  row:SetWidth(x)
end

local function fillRow(row, cells, color)
  for i, cell in ipairs(row.cells) do
    cell:SetText(cells[i] or "")
    cell:SetTextColor(unpack(color))
  end
  row:Show()
end

local function recordCells(columns, record)
  local cells = {}
  for i, column in ipairs(columns) do
    cells[i] = column.value(record)
  end
  return cells
end

local function defaultRowColor(record)
  return record.isCurrent and Widgets.COLORS.highlight or WHITE
end

local plainText = Format.PlainText
local TableOrder = ns.TableOrder

---------------------------------------------------------------------------
-- Tabellen-Ansicht: Suchfeld, sortierbare Kopfzeile, Zeilen (Lazy Load), Summenzeile
---------------------------------------------------------------------------

-- definition = { tab, group (optional), columns, records(characterKey), footer(columns, records, count),
--   rowColor(record) optional (Standard: laufender Eintrag hervorgehoben, sonst weiß),
--   onRowClick(record, mouseButton) optional,
--   rowLink(record) optional: Spiel-Link der Zeile ("item:...", "quest:..."); Maus darüber zeigt den Spiel-Tooltip,
--   rowTooltip(record) optional: { Titel, Zeile, ... } als eigener Tooltip der Zeile (wenn rowLink nichts liefert),
--   hint = Locale-Key oder function(characterKey) -> Text optional (bricht in der Tabellenbreite um, die Zeilen rücken
--   nach oben),
--   empty = Locale-Key oder function(characterKey) -> Text optional: Hinweis ohne Einträge (Standard TABLE_EMPTY),
--   buttons = { { label = Locale-Key, onClick(), tip = Locale-Key optional (Standard <label>_TIP) }, ... } optional
--   (neben dem Export-Button),
--   revision() optional: Stand der Daten (z.B. Journal.Revision); dann wird nur bei geändertem Stand neu gefiltert
--   und sortiert, höchstens alle REFRESH_SECONDS (große Journale), statt zusätzlich alle REFRESH_SECONDS,
--   appendOnly optional: records() liefert älteste zuerst dieselbe Liste, die nur hinten wächst (oder eine neue);
--   angezeigt neueste zuerst, ohne Kopie und mit Zwischenspeicher je Eintrag (TableOrder.NewAppendOnly). footer
--   bekommt dann records = nil, nur count. Einträge ändern sich nicht, außer edits() optional meldet es,
--   locale, language(), export optional: Texte, gewählte Sprache (Teil der Zwischenspeicher-Schlüssel) und das
--   Export-Fenster (ToCsv, Show); ohne Angabe die von Level Time }
-- Ergebnis: Ansicht { tab, group, Create(parent, width, height) -> frame } für HistoryWindow.AddView
local function addonLanguage()
  return ns.db and ns.db.language or ""
end

-- Text zu key, nil, wenn es ihn nicht gibt (L liefert für unbekannte Keys den Key selbst)
local function optionalText(L, key)
  local text = L[key]
  if text ~= key then return text end
  return nil
end

-- Tooltip-Text eines Spaltenkopfs (siehe oben); L optional (Standard ns.L), auch für Tests
local function headerTip(L, column)
  if column.tip then return L[column.tip] end
  return optionalText(L, column.header .. "_TIP") or L.TABLE_SORT_HINT
end

function TableView.HeaderTip(column, L)
  return headerTip(L or ns.L, column)
end

-- Tooltip eines Buttons der Werkzeugzeile: Beschriftung als Titel, Erklärung aus tip oder <label>_TIP
-- (ohne Text keiner)
local function attachButtonTip(L, widget, label, tip)
  Widgets.AttachTooltip(widget, function() return L[label] end,
    function() return optionalText(L, tip or label .. "_TIP") end)
end

function TableView.Create(definition)
  local L = definition.locale or ns.L
  local language = definition.language or addonLanguage
  local export = definition.export or ns.Export
  local columns = definition.columns
  local rowColor = definition.rowColor or defaultRowColor

  local function create(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame.offset = 0  -- Index vor dem ersten sichtbaren Eintrag

    -- Sichtbare Zeilen ohne Kopf- und Summenzeile bei toolbarRows Werkzeugzeilen. Zeilen-Widgets gibt es für eine
    -- Werkzeugzeile (der Normalfall); bei zwei bleiben die letzten verborgen
    local function rowsFor(toolbarCount, hintLines)
      return math.floor((height - toolbarCount * TOOLBAR_HEIGHT - hintLines * HINT_LINE_HEIGHT) / ROW_HEIGHT) - 2
    end
    local rowCapacity = rowsFor(1, 1)
    local hintLines = 1
    local visibleRows = rowCapacity
    local allRecords, records = {}, {}  -- alle Einträge bzw. gefiltert und sortiert (ohne appendOnly)
    local view = definition.appendOnly and TableOrder.NewAppendOnly(columns)  -- angezeigte Einträge mit appendOnly
    local function visibleCount()
      if view then return view:Count() end
      return #records
    end
    local function visibleAt(position)
      if view then return view:At(position) end
      return records[position]
    end
    local filterText, filterInput = "", ""  -- Suchbegriff klein und ohne Farbcodes bzw. wie eingegeben
    local sort  -- { column, index, descending } oder nil (ursprüngliche Reihenfolge)

    -- Suchfeld oben rechts (Breite und Zeile setzt layoutToolbar)
    local filterBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    filterBox:SetSize(FILTER_WIDTH, FILTER_HEIGHT)
    filterBox:SetPoint("TOPRIGHT", -SCROLLBAR_GAP, -2)
    filterBox:SetAutoFocus(false)
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("RIGHT", filterBox, "LEFT", -FILTER_LABEL_GAP, 0)

    local headerRow = createRow(frame, columns, "GameFontNormalSmall")
    headerRow:SetPoint("TOPLEFT", 0, -TOOLBAR_HEIGHT)
    local footerRow = createRow(frame, columns, "GameFontNormalSmall")

    local rows = {}
    local apply  -- unten definiert
    for i = 1, rowCapacity do
      rows[i] = createRow(frame, columns, "GameFontHighlightSmall")
      rows[i]:SetPoint("TOPLEFT", 0, -TOOLBAR_HEIGHT - i * ROW_HEIGHT)
    end

    -- Klick auf eine Zeile (nur, wenn die Ansicht etwas damit macht); danach neu zeichnen
    if definition.onRowClick then
      for i, row in ipairs(rows) do
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(_, mouseButton)
          local record = visibleAt(frame.offset + i)
          if not record then return end
          definition.onRowClick(record, mouseButton)
          frame:Render(frame.characterKey, false, true)
        end)
      end
    end

    -- Spiel-Tooltip des Links einer Zeile (Gegenstand, Quest). pcall: ein Client, der die Link-Art nicht kennt, zeigt
    -- dann einfach nichts statt eines Fehlers
    -- Ohne Link: eigener Tooltip aus rowTooltip (erste Zeile als Titel, weitere weiß und umbrochen)
    local function showRowTooltip(owner, record)
      local link = definition.rowLink and definition.rowLink(record)
      if link then
        GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then GameTooltip:Show() else GameTooltip:Hide() end
        return
      end
      local lines = definition.rowTooltip and definition.rowTooltip(record)
      if not lines or not lines[1] then return end
      GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
      GameTooltip:SetText(lines[1], unpack(Widgets.COLORS.highlight))
      for i = 2, #lines do GameTooltip:AddLine(lines[i], 1, 1, 1, true) end
      GameTooltip:Show()
    end

    if definition.rowLink or definition.rowTooltip then
      for i, row in ipairs(rows) do
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
          local record = visibleAt(frame.offset + i)
          if record then showRowTooltip(self, record) end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
      end
    end

    -- Leerer Zustand: statt nur Kopf und "Gesamt: 0" ein Hinweis in der Mitte
    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:Hide()

    -- Hinweis unter der Summenzeile, z.B. was ein Klick bewirkt; bricht in der Breite der Ansicht um
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetTextColor(unpack(Widgets.COLORS.muted))
    hint:SetPoint("BOTTOMLEFT", 0, 0)
    hint:SetPoint("BOTTOMRIGHT", -SCROLLBAR_GAP, 0)
    hint:SetJustifyH(LEFT)
    hint:SetWordWrap(true)
    hint:SetMaxLines(MAX_HINT_LINES)
    local hintWidth = width - SCROLLBAR_GAP

    -- Weitere Buttons der Ansicht rechts neben dem Export-Button (Position setzt layoutToolbar)
    local extraButtons = {}
    for i, button in ipairs(definition.buttons or {}) do
      local widget = Widgets.CreateButton(frame, EXTRA_BUTTON_WIDTH, FILTER_HEIGHT + 2, button.onClick)
      extraButtons[i] = { widget = widget, label = button.label }
      attachButtonTip(L, widget, button.label, button.tip)
    end

    local function draw()
      for i, row in ipairs(rows) do
        local record = i <= visibleRows and visibleAt(frame.offset + i)
        if record then
          fillRow(row, recordCells(columns, record), rowColor(record))
        else
          row:Hide()
        end
      end
    end

    local scrollBar
    local lastSignature, lastLive, lastCharacterKey, lastApplyAt = nil, nil, nil, 0  -- siehe Render
    local function scrollTo(offset)
      frame.offset = Widgets.ClampOffset(offset, visibleCount(), visibleRows)
      scrollBar:SetOffsetSilently(frame.offset)
      draw()
    end

    scrollBar = Widgets.CreateScrollBar(frame, scrollTo)

    -- Kopf, Zeilen und Bildlaufleiste unter toolbarRows Werkzeugzeilen (1 oder 2, layoutToolbar); die Leiste rechts
    -- der an die Kopftexte angepassten Spalten (fitColumns); die Summenzeile über den hintLines Zeilen des Hinweises
    local toolbarRows, tableRight = 1, tableWidth(columns)
    local function placeTable()
      local top = toolbarRows * TOOLBAR_HEIGHT
      visibleRows = math.min(rowCapacity, rowsFor(toolbarRows, hintLines))
      footerRow:ClearAllPoints()
      footerRow:SetPoint("BOTTOMLEFT", 0, hintLines * HINT_LINE_HEIGHT)
      headerRow:ClearAllPoints()
      headerRow:SetPoint("TOPLEFT", 0, -top)
      for i, row in ipairs(rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -top - i * ROW_HEIGHT)
      end
      scrollBar:ClearAllPoints()
      scrollBar:SetPoint("TOPLEFT", tableRight + SCROLLBAR_GAP, -top - ROW_HEIGHT)
      scrollBar:SetHeight(visibleRows * ROW_HEIGHT)
    end
    placeTable()

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      scrollTo(frame.offset - delta * WHEEL_STEP)
    end)

    local headerButtons = {}  -- unten angelegt: Klick sortiert
    local fittedLanguage      -- Sprache, für die die Spaltenbreiten gelten

    -- Spalten an die Kopftexte anpassen, wenn sich die Sprache geändert hat (nicht je Aktualisierung)
    local function fitColumns()
      local current = language()
      if fittedLanguage == current then return end
      fittedLanguage = current
      for i, column in ipairs(columns) do headerRow.cells[i]:SetText(L[column.header]) end
      local widths = fittedWidths(columns, headerRow.cells, width - SCROLLBAR_GAP - scrollBar:GetWidth())
      for _, row in ipairs(rows) do placeCells(row, widths) end
      placeCells(headerRow, widths)
      placeCells(footerRow, widths)
      tableRight = headerRow:GetWidth()
      placeTable()
      local x = 0
      for i, button in ipairs(headerButtons) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", x, 0)
        button:SetSize(widths[i], ROW_HEIGHT)
        x = x + widths[i]
      end
    end

    local function showHeaders()
      fitColumns()
      for i, column in ipairs(columns) do
        local marker = ""
        if sort and sort.index == i then
          marker = sort.descending and SORT_DESCENDING or SORT_ASCENDING
        end
        headerRow.cells[i]:SetText(marker .. L[column.header])
      end
    end

    local function showFooter()
      fillRow(footerRow, definition.footer(columns, not view and records or nil, visibleCount()),
        Widgets.COLORS.highlight)
    end

    -- Stand, bei dessen Änderung appendOnly-Zwischenspeicher verfallen: Sprache (Texte) und nachgetragene Werte
    local function cacheEpoch()
      local edits = definition.edits and definition.edits() or ""
      return language() .. ":" .. edits
    end

    -- Ohne Einträge der Hinweis der Ansicht (empty), mit Einträgen, aber ohne Treffer für den Filter TABLE_NO_MATCH
    local function showEmpty()
      local text
      if #allRecords == 0 then
        local empty = definition.empty
        if type(empty) == "function" then text = empty(frame.characterKey) elseif empty then text = L[empty] end
        text = text or L.TABLE_EMPTY
      elseif visibleCount() == 0 and filterText ~= "" then
        text = string.format(L.TABLE_NO_MATCH, filterInput)
      end
      if text then emptyText:SetText(text) end
      emptyText:SetShown(text ~= nil)
    end

    -- Filter und Sortierung auf alle Einträge anwenden und neu zeichnen
    function apply()
      if view then
        view:Update(allRecords, filterText, sort, cacheEpoch())
      else
        records = TableOrder.FilterAndSort(columns, allRecords, filterText, sort)
      end
      showHeaders()
      scrollBar:SetRange(math.max(0, visibleCount() - visibleRows))
      scrollTo(frame.offset)
      showFooter()
      showEmpty()
    end

    -- Nach einer Spalte sortieren: erst absteigend, beim nächsten Aufruf für dieselbe Spalte aufsteigend
    function frame:SortBy(index)
      if sort and sort.index == index then
        sort.descending = not sort.descending
      else
        -- Zahlen zuerst absteigend (größte oben), Text-Spalten aufsteigend (A-Z)
        sort = { column = columns[index], index = index, descending = columns[index].align ~= "LEFT" }
      end
      frame.offset = 0
      apply()
    end

    -- Klick auf einen Spaltenkopf sortiert
    local x = 0
    for i, column in ipairs(columns) do
      local headerButton = CreateFrame("Button", nil, headerRow)
      headerButton:SetPoint("TOPLEFT", x, 0)
      headerButton:SetSize(column.width, ROW_HEIGHT)
      headerButton:SetScript("OnClick", function() frame:SortBy(i) end)
      -- Voller Kopftext (falls er trotz allem abgeschnitten ist), darunter was die Spalte zeigt oder wie man sortiert
      Widgets.AttachTooltip(headerButton, function() return L[column.header] end, function()
        return headerTip(L, column)
      end)
      headerButtons[i] = headerButton
      x = x + column.width
    end

    -- Zeilen auf Einträge beschränken, deren Text den Suchbegriff enthält (ohne Groß-/Kleinschreibung)
    function frame:SetFilter(text)
      filterInput = plainText(text)
      filterText = filterInput:lower()
      frame.offset = 0
      apply()
    end

    filterBox:SetScript("OnTextChanged", function(self) frame:SetFilter(self:GetText()) end)
    filterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Aktuell angezeigte (gefilterte und sortierte) Einträge, z.B. für den Export
    function frame:GetVisibleRecords()
      if view then return view:List() end
      return records
    end

    -- Angezeigte Zeilen als CSV (Spaltenköpfe in der aktuellen Sprache, Zellen ohne Farbcodes)
    function frame:BuildCsv()
      local headers, rowsText = {}, {}
      for i, column in ipairs(columns) do
        headers[i] = L[column.header]
      end
      for position = 1, visibleCount() do
        local cells = recordCells(columns, visibleAt(position))
        for i, cell in ipairs(cells) do
          cells[i] = plainText(cell)
        end
        table.insert(rowsText, cells)
      end
      return export.ToCsv(headers, rowsText, L.CSV_SEPARATOR)
    end

    local exportButton = Widgets.CreateButton(frame, EXPORT_BUTTON_WIDTH, FILTER_HEIGHT + 2, function()
      export.Show(L[definition.tab], frame:BuildCsv())
    end)
    exportButton:SetPoint("TOPLEFT", 0, -1)
    attachButtonTip(L, exportButton, "EXPORT")

    -- Werkzeugzeile in der gewählten Sprache: Buttons so breit wie ihr Text nebeneinander, rechts "Filter" und das
    -- Suchfeld. Passt das Feld nicht mehr in voller Breite daneben, wird es schmaler (bis FILTER_MIN_WIDTH), sonst
    -- bekommt es eine eigene zweite Zeile und die Tabelle rückt nach unten. Nur bei Sprachwechsel, nicht je Render.
    local toolbarLanguage
    local function layoutToolbar()
      local current = language()
      if toolbarLanguage == current then return end
      toolbarLanguage = current
      Widgets.SetButtonText(exportButton, L.EXPORT, EXPORT_BUTTON_WIDTH)
      local right = exportButton:GetWidth()
      for _, button in ipairs(extraButtons) do
        Widgets.SetButtonText(button.widget, L[button.label], EXTRA_BUTTON_WIDTH)
        button.widget:ClearAllPoints()
        button.widget:SetPoint("TOPLEFT", right + TOOLBAR_GAP, -1)
        right = right + TOOLBAR_GAP + button.widget:GetWidth()
      end
      filterLabel:SetText(L.FILTER)
      local labelWidth = math.ceil(filterLabel:GetStringWidth() or 0)
      local room = width - SCROLLBAR_GAP - right - TOOLBAR_GAP - labelWidth - FILTER_LABEL_GAP
      toolbarRows = room >= FILTER_MIN_WIDTH and 1 or 2
      filterBox:ClearAllPoints()
      filterBox:SetPoint("TOPRIGHT", -SCROLLBAR_GAP, -2 - (toolbarRows - 1) * TOOLBAR_HEIGHT)
      filterBox:SetWidth(toolbarRows == 1 and math.min(FILTER_WIDTH, room) or FILTER_WIDTH)
      placeTable()
    end

    -- Zeilen der Werkzeugzeile (1 oder 2), für Tests
    function frame:ToolbarRows()
      return toolbarRows
    end

    -- Nur der laufende Eintrag (Level, Session, Instanz-Durchgang) hat sich geändert, z.B. seine Sekunden: ohne Filter
    -- und Sortierung steht er auch in der Anzeige vorne, dann reicht es, ihn dort zu ersetzen und neu zu zeichnen,
    -- statt jede Sekunde alle Einträge zu filtern und zu sortieren (Roadmap 213). Sonst wie bisher alles neu, außer
    -- solange die Drosselung großer Journale greift (fullAllowed false).
    local function updateLive(newest, live, fullAllowed)
      if not view and newest and newest.isCurrent and filterText == "" and not sort and records[1]
        and records[1].isCurrent then
        records[1] = newest
        draw()
        showFooter()
      elseif fullAllowed then
        lastApplyAt = GetTime()
        apply()
      else
        return
      end
      lastLive = live
    end

    -- Hinweis setzen und seine Zeilen zählen (Breite ohne Umbruch geteilt durch die Breite der Ansicht); ändert sich
    -- die Zahl, rücken Summenzeile und Zeilen. Rückgabe: true, wenn sich die Anordnung geändert hat
    local shownHint
    local function showHint()
      local text = definition.hint
      if type(text) == "function" then text = text(frame.characterKey) elseif text then text = L[text] end
      text = text or L.TABLE_SORT_HINT
      if text == shownHint then return false end
      shownHint = text
      hint:SetText(text)
      -- GetUnboundedStringWidth: volle Breite auch bei Umbruch (alle Clients, auch Blizzards Classic-Era-UI nutzt sie);
      -- ohne sie (Test-Stub) GetStringWidth
      local full = hint.GetUnboundedStringWidth and hint:GetUnboundedStringWidth() or hint:GetStringWidth() or 0
      local lines = math.max(1, math.min(MAX_HINT_LINES, math.ceil(full / hintWidth)))
      if lines == hintLines then return false end
      hintLines = lines
      placeTable()
      return true
    end

    -- Für Tests: Zeilen des Hinweises und der angezeigte Leer-/Kein-Treffer-Text (nil, wenn verborgen)
    function frame:HintLines()
      return hintLines, hint
    end

    function frame:EmptyText()
      return emptyText:IsShown() and emptyText:GetText() or nil
    end

    -- force erzwingt das Neuzeichnen (nach Klick auf eine Zeile, die z.B. Favoriten ändert)
    function frame:Render(characterKey, selectionChanged, force)
      frame.characterKey = characterKey
      layoutToolbar()
      local hintChanged = showHint()
      allRecords = definition.records(characterKey)
      if selectionChanged then frame.offset = 0 end
      -- Das Fenster ruft Render jede Sekunde; Filtern und Sortieren aller Einträge nur, wenn sich etwas geändert hat:
      -- Charakter, Sprache, Anzahl, der jüngste Eintrag, Journal-Stand bzw. spätestens alle 5 s. Ändert sich nur der
      -- laufende Eintrag (live), ersetzt updateLive ihn, wo das reicht.
      local newest = allRecords[definition.appendOnly and #allRecords or 1]
      local freshness = definition.revision and definition.revision() or math.floor(GetTime() / REFRESH_SECONDS)
      local signature = table.concat({ characterKey or "", language(), #allRecords,
        newest and (newest.time or newest.startedAt or 0) or 0, freshness }, ":")
      local live = table.concat({ newest and newest.seconds or 0, newest and newest.xp or 0 }, ":")
      local urgent = selectionChanged or force or hintChanged or characterKey ~= lastCharacterKey
      -- Große Journale: neue Einträge höchstens alle REFRESH_SECONDS einsortieren (Charakterwechsel sofort)
      local throttled = definition.revision and GetTime() - lastApplyAt < REFRESH_SECONDS
      if not urgent and (signature == lastSignature or throttled) then
        if live ~= lastLive then updateLive(newest, live, signature == lastSignature and not throttled) end
        return
      end
      lastSignature, lastLive, lastApplyAt, lastCharacterKey = signature, live, GetTime(), characterKey
      apply()
    end

    return frame
  end

  return { tab = definition.tab, group = definition.group, Create = create }
end
