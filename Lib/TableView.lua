-- Tabellen-Ansicht für Fenster mit Reitern (z.B. die Historie): Suchfeld, sortierbare Kopfzeile,
-- Zeilen mit Lazy Load, Summenzeile, CSV-Export und optionale Buttons.
-- Lazy Load: Es gibt nur so viele Zeilen-Widgets, wie sichtbar sind; beim Scrollen (Mausrad oder
-- Leiste) werden sie mit den passenden Einträgen neu gefüllt. So bleiben auch tausende Einträge flüssig.
-- Spalten: header = Locale-Key, value(record) = Zellentext, width, align = "LEFT" für Text
-- (Standard: erste Spalte links, Zahlen rechts), sort(record) = Sortierschlüssel, wenn der Zellentext
-- formatiert ist (Dauer, Gold, Datum); sonst wird nach value sortiert.
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

---------------------------------------------------------------------------
-- Sortieren und Filtern
---------------------------------------------------------------------------

local plainText = Format.PlainText

-- Sortierschlüssel einmal je Zeile aufbereiten (nicht in jedem Vergleich): Zahlen bleiben Zahlen,
-- Text ohne Farbcodes und Groß-/Kleinschreibung, leere Werte = nil
local function sortKey(column, record)
  local key
  if column.sort then key = column.sort(record) else key = column.value(record) end
  if key == nil or key == "" or type(key) == "number" then return key ~= "" and key or nil end
  return plainText(key):lower()
end

-- Fehlende Werte immer ans Ende; Zahlen vor Text, damit gemischte Spalten eine feste Ordnung haben
local function compareKeys(a, b, descending)
  if a == nil then return false end
  if b == nil then return true end
  local aIsNumber, bIsNumber = type(a) == "number", type(b) == "number"
  if aIsNumber ~= bIsNumber then return aIsNumber end
  if descending then return a > b end
  return a < b
end

-- Gefilterte und sortierte Kopie; sort = { column, descending } oder nil
local function filterAndSort(columns, records, filterText, sort)
  local result = {}
  for index, record in ipairs(records) do
    local include = filterText == ""
    if not include then
      for _, column in ipairs(columns) do
        if plainText(column.value(record)):lower():find(filterText, 1, true) then
          include = true
          break
        end
      end
    end
    if include then
      table.insert(result, { record = record, index = index, key = sort and sortKey(sort.column, record) })
    end
  end

  if sort then
    table.sort(result, function(a, b)
      if a.key == b.key then return a.index < b.index end  -- gleiche Werte: ursprüngliche Reihenfolge
      return compareKeys(a.key, b.key, sort.descending)
    end)
  end

  for i, entry in ipairs(result) do
    result[i] = entry.record
  end
  return result
end

---------------------------------------------------------------------------
-- Tabellen-Ansicht: Suchfeld, sortierbare Kopfzeile, Zeilen (Lazy Load), Summenzeile
---------------------------------------------------------------------------

-- definition = { tab, group (optional), columns, records(characterKey), footer(columns, records),
--   rowColor(record) optional (Standard: laufender Eintrag hervorgehoben, sonst weiß),
--   onRowClick(record, mouseButton) optional,
--   rowLink(record) optional: Spiel-Link der Zeile ("item:...", "quest:..."); Maus darüber zeigt den Spiel-Tooltip,
--   hint = Locale-Key oder function() -> Text optional,
--   buttons = { { label = Locale-Key, onClick() }, ... } optional (neben dem Export-Button),
--   revision() optional: Stand der Daten (z.B. Journal.Revision); dann wird nur bei geändertem Stand neu gefiltert
--   und sortiert, höchstens alle REFRESH_SECONDS (große Journale), statt zusätzlich alle REFRESH_SECONDS }
-- Ergebnis: Ansicht { tab, group, Create(parent, width, height) -> frame } für HistoryWindow.AddView
function TableView.Create(definition)
  local columns = definition.columns
  local rowColor = definition.rowColor or defaultRowColor

  local function create(parent, _, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame.offset = 0  -- Index vor dem ersten sichtbaren Eintrag

    local visibleRows = math.floor((height - TOOLBAR_HEIGHT - HINT_HEIGHT) / ROW_HEIGHT) - 2  -- ohne Kopf- und Summenzeile
    local allRecords, records = {}, {}  -- alle Einträge bzw. gefiltert und sortiert
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
          local record = records[frame.offset + i]
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
          local record = records[frame.offset + i]
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
        local record = records[frame.offset + i]
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
      frame.offset = math.max(0, math.min(offset, #records - visibleRows))
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

    local function showHeaders()
      for i, column in ipairs(columns) do
        local marker = ""
        if sort and sort.index == i then
          marker = sort.descending and SORT_DESCENDING or SORT_ASCENDING
        end
        headerRow.cells[i]:SetText(marker .. L[column.header])
      end
    end

    -- Filter und Sortierung auf alle Einträge anwenden und neu zeichnen
    function apply()
      records = filterAndSort(columns, allRecords, filterText, sort)
      showHeaders()
      scrollBar:SetRange(math.max(0, #records - visibleRows))
      scrollTo(frame.offset)
      fillRow(footerRow, definition.footer(columns, records), Widgets.COLORS.highlight)
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
      return records
    end

    -- Angezeigte Zeilen als CSV (Spaltenköpfe in der aktuellen Sprache, Zellen ohne Farbcodes)
    function frame:BuildCsv()
      local headers, rowsText = {}, {}
      for i, column in ipairs(columns) do
        headers[i] = L[column.header]
      end
      for _, record in ipairs(records) do
        local cells = recordCells(columns, record)
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
      if newest and newest.isCurrent and filterText == "" and not sort and records[1] and records[1].isCurrent then
        records[1] = newest
        draw()
        fillRow(footerRow, definition.footer(columns, records), Widgets.COLORS.highlight)
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
      local newest = allRecords[1]
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
