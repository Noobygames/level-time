-- Tabellen-Ansicht für Fenster mit Reitern (z.B. die Historie): Suchfeld, sortierbare Kopfzeile,
-- Zeilen mit Lazy Load, Summenzeile, CSV-Export und optionale Buttons.
-- Lazy Load: Es gibt nur so viele Zeilen-Widgets, wie sichtbar sind; beim Scrollen (Mausrad oder
-- Leiste) werden sie mit den passenden Einträgen neu gefüllt. So bleiben auch tausende Einträge flüssig.
-- Spalten: header = Locale-Key, value(record) = Zellentext, width, align = "LEFT" für Text
-- (Standard: erste Spalte links, Zahlen rechts), sort(record) = Sortierschlüssel, wenn der Zellentext
-- formatiert ist (Dauer, Gold, Datum); sonst wird nach value sortiert. volatile = true: Wert kann sich ohne neuen
-- Eintrag ändern (nur für appendOnly wichtig, siehe TableOrder.lua). Reihenfolge, Filter: TableOrder.lua.
local _, ns = ...
local L = ns.L
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
local HINT_HEIGHT = 12       -- eigene Zeile unter der Summenzeile für den Hinweis (sonst überdeckt er die Summen)
local FILTER_WIDTH = 150
local FILTER_HEIGHT = 18
local EXPORT_BUTTON_WIDTH = 70
local EXTRA_BUTTON_WIDTH = 90   -- weitere Buttons der Ansicht (definition.buttons)
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
-- die Tabelle ihre Gesamtbreite behält. Rückgabe: Breite je Spalte
local SORT_MARKER_WIDTH = 10  -- Platz für "v "/"^ " vor dem Kopf

local function fittedWidths(columns, headerCells)
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
  return widths
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
--   hint = Locale-Key oder function() -> Text optional,
--   buttons = { { label = Locale-Key, onClick() }, ... } optional (neben dem Export-Button),
--   revision() optional: Stand der Daten (z.B. Journal.Revision); dann wird nur bei geändertem Stand neu gefiltert
--   und sortiert, höchstens alle REFRESH_SECONDS (große Journale), statt zusätzlich alle REFRESH_SECONDS,
--   appendOnly optional: records() liefert älteste zuerst dieselbe Liste, die nur hinten wächst (oder eine neue);
--   angezeigt neueste zuerst, ohne Kopie und mit Zwischenspeicher je Eintrag (TableOrder.NewAppendOnly). footer
--   bekommt dann records = nil, nur count. Einträge ändern sich nicht, außer edits() optional meldet es }
-- Ergebnis: Ansicht { tab, group, Create(parent, width, height) -> frame } für HistoryWindow.AddView
function TableView.Create(definition)
  local columns = definition.columns
  local rowColor = definition.rowColor or defaultRowColor

  local function create(parent, _, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame.offset = 0  -- Index vor dem ersten sichtbaren Eintrag

    local visibleRows = math.floor((height - TOOLBAR_HEIGHT - HINT_HEIGHT) / ROW_HEIGHT) - 2  -- ohne Kopf- und Summenzeile
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
    local filterText = ""
    local sort  -- { column, index, descending } oder nil (ursprüngliche Reihenfolge)

    -- Suchfeld oben rechts
    local filterBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    filterBox:SetSize(FILTER_WIDTH, FILTER_HEIGHT)
    filterBox:SetPoint("TOPRIGHT", -SCROLLBAR_GAP, -2)
    filterBox:SetAutoFocus(false)
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("RIGHT", filterBox, "LEFT", -8, 0)

    local headerRow = createRow(frame, columns, "GameFontNormalSmall")
    headerRow:SetPoint("TOPLEFT", 0, -TOOLBAR_HEIGHT)
    local footerRow = createRow(frame, columns, "GameFontNormalSmall")
    footerRow:SetPoint("BOTTOMLEFT", 0, HINT_HEIGHT)

    local rows = {}
    local apply  -- unten definiert
    for i = 1, visibleRows do
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
    if definition.rowLink then
      for i, row in ipairs(rows) do
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
          local record = visibleAt(frame.offset + i)
          local link = record and definition.rowLink(record)
          if not link then return end
          GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
          if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then GameTooltip:Show() else GameTooltip:Hide() end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
      end
    end

    -- Leerer Zustand: statt nur Kopf und "Gesamt: 0" ein Hinweis in der Mitte
    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:Hide()

    -- Hinweis unter der Summenzeile, z.B. was ein Klick bewirkt
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetTextColor(unpack(Widgets.COLORS.muted))
    hint:SetPoint("BOTTOMRIGHT", -SCROLLBAR_GAP, 0)

    -- Weitere Buttons der Ansicht rechts neben dem Export-Button
    local extraButtons = {}
    for i, button in ipairs(definition.buttons or {}) do
      local widget = Widgets.CreateButton(frame, EXTRA_BUTTON_WIDTH, FILTER_HEIGHT + 2, button.onClick)
      widget:SetPoint("TOPLEFT", EXPORT_BUTTON_WIDTH + CELL_GAP + (i - 1) * (EXTRA_BUTTON_WIDTH + CELL_GAP), -1)
      extraButtons[i] = { widget = widget, label = button.label }
    end

    local function draw()
      for i, row in ipairs(rows) do
        local record = visibleAt(frame.offset + i)
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
      frame.offset = math.max(0, math.min(offset, visibleCount() - visibleRows))
      scrollBar:SetOffsetSilently(frame.offset)
      draw()
    end

    scrollBar = Widgets.CreateScrollBar(frame, scrollTo)
    scrollBar:SetPoint("TOPLEFT", tableWidth(columns) + SCROLLBAR_GAP, -TOOLBAR_HEIGHT - ROW_HEIGHT)
    scrollBar:SetHeight(visibleRows * ROW_HEIGHT)

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      scrollTo(frame.offset - delta * WHEEL_STEP)
    end)

    local headerButtons = {}  -- unten angelegt: Klick sortiert
    local fittedLanguage      -- Sprache, für die die Spaltenbreiten gelten

    -- Spalten an die Kopftexte anpassen, wenn sich die Sprache geändert hat (nicht je Aktualisierung)
    local function fitColumns()
      local language = ns.db and ns.db.language or ""
      if fittedLanguage == language then return end
      fittedLanguage = language
      for i, column in ipairs(columns) do headerRow.cells[i]:SetText(L[column.header]) end
      local widths = fittedWidths(columns, headerRow.cells)
      for _, row in ipairs(rows) do placeCells(row, widths) end
      placeCells(headerRow, widths)
      placeCells(footerRow, widths)
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
      return (ns.db and ns.db.language or "") .. ":" .. edits
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
      emptyText:SetText(L.TABLE_EMPTY)
      emptyText:SetShown(#allRecords == 0)
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
      -- Voller Kopftext, falls er trotz allem abgeschnitten ist
      Widgets.AttachTooltip(headerButton, function() return L[column.header] end)
      headerButtons[i] = headerButton
      x = x + column.width
    end

    -- Zeilen auf Einträge beschränken, deren Text den Suchbegriff enthält (ohne Groß-/Kleinschreibung)
    function frame:SetFilter(text)
      filterText = plainText(text):lower()
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
      return ns.Export.ToCsv(headers, rowsText, L.CSV_SEPARATOR)
    end

    local exportButton = Widgets.CreateButton(frame, EXPORT_BUTTON_WIDTH, FILTER_HEIGHT + 2, function()
      ns.Export.Show(L[definition.tab], frame:BuildCsv())
    end)
    exportButton:SetPoint("TOPLEFT", 0, -1)

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

    -- force erzwingt das Neuzeichnen (nach Klick auf eine Zeile, die z.B. Favoriten ändert)
    function frame:Render(characterKey, selectionChanged, force)
      frame.characterKey = characterKey
      filterLabel:SetText(L.FILTER)
      exportButton:SetText(L.EXPORT)
      local hintText = definition.hint
      if type(hintText) == "function" then hintText = hintText() elseif hintText then hintText = L[hintText] end
      hint:SetText(hintText or L.TABLE_SORT_HINT)
      for _, button in ipairs(extraButtons) do button.widget:SetText(L[button.label]) end
      allRecords = definition.records(characterKey)
      if selectionChanged then frame.offset = 0 end
      -- Das Fenster ruft Render jede Sekunde; Filtern und Sortieren aller Einträge nur, wenn sich etwas geändert hat:
      -- Charakter, Sprache, Anzahl, der jüngste Eintrag, Journal-Stand bzw. spätestens alle 5 s. Ändert sich nur der
      -- laufende Eintrag (live), ersetzt updateLive ihn, wo das reicht.
      local newest = allRecords[definition.appendOnly and #allRecords or 1]
      local freshness = definition.revision and definition.revision() or math.floor(GetTime() / REFRESH_SECONDS)
      local signature = table.concat({ characterKey or "", ns.db and ns.db.language or "", #allRecords,
        newest and (newest.time or newest.startedAt or 0) or 0, freshness }, ":")
      local live = table.concat({ newest and newest.seconds or 0, newest and newest.xp or 0 }, ":")
      local urgent = selectionChanged or force or characterKey ~= lastCharacterKey
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
