-- Diagramme aus einfachen Texturen: laufen in allen Clients und brauchen keine Bibliothek.
-- Beide Arten bekommen items im Format von Analysis.lua ({ label, value, text, highlight }).
local _, ns = ...
local Widgets = ns.Widgets

local Charts = {}
ns.Charts = Charts

local BAR_COLOR = Widgets.COLORS.highlight
local BAR_HOVER_COLOR = { 1, 0.93, 0.62 }
local HIGHLIGHT_COLOR = { 0.45, 0.75, 1 }  -- laufendes Level, heutiger Tag
local GRID_COLOR = { 1, 1, 1, 0.08 }
local BASELINE_COLOR = { 1, 1, 1, 0.3 }

local function barColor(item)
  return item.highlight and HIGHLIGHT_COLOR or BAR_COLOR
end

local function addHorizontalLine(chart, y, color)
  local line = chart:CreateTexture(nil, "BACKGROUND")
  line:SetColorTexture(unpack(color))
  line:SetHeight(1)
  line:SetPoint("BOTTOMLEFT", 0, y)
  line:SetPoint("BOTTOMRIGHT", 0, y)
end

local function showTooltip(owner, item)
  GameTooltip:SetOwner(owner, "ANCHOR_TOP")
  GameTooltip:AddDoubleLine(item.label, item.text, 1, 0.82, 0, 1, 1, 1)
  GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Säulendiagramm für Verläufe (Zeit pro Level, Kills pro Tag).
-- Wert steht im Tooltip; unten nur jede n-te Beschriftung, damit nichts überlappt.
---------------------------------------------------------------------------
local AXIS_LABEL_HEIGHT = 14  -- Platz für die Beschriftung unter den Säulen
local TOP_LABEL_HEIGHT = 14   -- Platz für den Maximalwert oben
local GRID_LINES = 4
local MAX_AXIS_LABELS = 10
local COLUMN_FILL = 0.7       -- Anteil des Platzes, den eine Säule einnimmt
local MAX_COLUMN_SLOT = 48     -- breitester Platz je Säule; wenige Säulen füllen nicht die ganze Breite

function Charts.CreateColumnChart(parent, width, height)
  local chart = CreateFrame("Frame", nil, parent)
  chart:SetSize(width, height)
  local plotBottom = AXIS_LABEL_HEIGHT
  local plotHeight = height - AXIS_LABEL_HEIGHT - TOP_LABEL_HEIGHT

  for i = 1, GRID_LINES do
    addHorizontalLine(chart, plotBottom + plotHeight * i / GRID_LINES, GRID_COLOR)
  end
  addHorizontalLine(chart, plotBottom, BASELINE_COLOR)

  local maxLabel = chart:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  maxLabel:SetPoint("TOPLEFT")

  local columns = {}  -- werden bei Bedarf angelegt und wiederverwendet

  local function getColumn(index)
    if columns[index] then return columns[index] end
    local hit = CreateFrame("Frame", nil, chart)  -- ganze Höhe, damit auch kleine Säulen leicht zu treffen sind
    hit:EnableMouse(true)
    local bar = hit:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("BOTTOM")
    local label = chart:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", hit, "BOTTOM", 0, -2)

    hit:SetScript("OnEnter", function(self)
      bar:SetColorTexture(unpack(BAR_HOVER_COLOR))
      showTooltip(self, self.item)
    end)
    hit:SetScript("OnLeave", function(self)
      bar:SetColorTexture(unpack(barColor(self.item)))
      GameTooltip:Hide()
    end)

    columns[index] = { hit = hit, bar = bar, label = label }
    return columns[index]
  end

  -- formatAxis(maxValue) beschriftet die oberste Hilfslinie
  function chart:SetItems(items, formatAxis)
    local maxValue = 0
    for _, item in ipairs(items) do
      maxValue = math.max(maxValue, item.value)
    end
    maxLabel:SetText(formatAxis(maxValue))

    local slot = math.min(MAX_COLUMN_SLOT, width / math.max(1, #items))
    local labelStep = math.ceil(#items / MAX_AXIS_LABELS)
    for i, item in ipairs(items) do
      local column = getColumn(i)
      column.hit.item = item
      column.hit:ClearAllPoints()
      column.hit:SetPoint("BOTTOMLEFT", (i - 1) * slot, plotBottom)
      column.hit:SetSize(slot, plotHeight)
      local barHeight = maxValue > 0 and item.value / maxValue * plotHeight or 0
      column.bar:SetSize(math.max(2, slot * COLUMN_FILL), math.max(1, barHeight))
      -- Unter der Maus bleibt die Säule hervorgehoben und der Tooltip zeigt den neuen Wert (sonst springt beides zurück)
      local hovered = column.hit:IsMouseOver()
      column.bar:SetColorTexture(unpack(hovered and BAR_HOVER_COLOR or barColor(item)))
      if hovered then showTooltip(column.hit, item) end
      column.label:SetText(item.label)
      column.label:SetShown((i - 1) % labelStep == 0)
      column.hit:Show()
    end
    for i = #items + 1, #columns do
      columns[i].hit:Hide()
      columns[i].label:Hide()
    end
  end

  return chart
end

---------------------------------------------------------------------------
-- Rangliste als liegende Balken (Top-Gegner, Todesursachen):
-- Rang, Name, Balken auf schwacher Spur (volle Länge = Maximum), Wert.
-- Zeilen teilen sich die verfügbare Höhe; Tooltip zeigt abgeschnittene Namen vollständig.
---------------------------------------------------------------------------
local RANK_MIN_ROW_HEIGHT = 16
local RANK_MAX_ROW_HEIGHT = 26
local RANK_BAR_FILL = 0.55       -- Anteil der Zeilenhöhe, den der Balken einnimmt
local RANK_NUMBER_WIDTH = 22
local RANK_LABEL_WIDTH = 160
local RANK_VALUE_WIDTH = 70
local RANK_GAP = 6
local TRACK_COLOR = { 1, 1, 1, 0.07 }

function Charts.CreateRankChart(parent, width, height)
  local chart = CreateFrame("Frame", nil, parent)
  chart:SetSize(width, height)
  local barX = RANK_NUMBER_WIDTH + RANK_GAP + RANK_LABEL_WIDTH + RANK_GAP
  local barSpace = width - barX - RANK_GAP - RANK_VALUE_WIDTH

  local rows = {}  -- werden bei Bedarf angelegt und wiederverwendet

  local function getRow(index)
    if rows[index] then return rows[index] end
    local row = CreateFrame("Frame", nil, chart)
    row:EnableMouse(true)

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.rank:SetPoint("LEFT")
    row.rank:SetWidth(RANK_NUMBER_WIDTH)
    row.rank:SetJustifyH("RIGHT")

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", RANK_NUMBER_WIDTH + RANK_GAP, 0)
    row.label:SetWidth(RANK_LABEL_WIDTH)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    row.track = row:CreateTexture(nil, "BACKGROUND")
    row.track:SetPoint("LEFT", barX, 0)
    row.track:SetColorTexture(unpack(TRACK_COLOR))

    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetPoint("LEFT", barX, 0)

    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.value:SetPoint("LEFT", row.bar, "RIGHT", RANK_GAP, 0)

    row:SetScript("OnEnter", function(self)
      self.bar:SetColorTexture(unpack(BAR_HOVER_COLOR))
      showTooltip(self, self.item)
    end)
    row:SetScript("OnLeave", function(self)
      self.bar:SetColorTexture(unpack(barColor(self.item)))
      GameTooltip:Hide()
    end)

    rows[index] = row
    return row
  end

  function chart:SetItems(items)
    local maxValue = 0
    for _, item in ipairs(items) do
      maxValue = math.max(maxValue, item.value)
    end

    local rowHeight = math.max(RANK_MIN_ROW_HEIGHT,
      math.min(RANK_MAX_ROW_HEIGHT, math.floor(height / math.max(1, #items))))
    local barHeight = math.floor(rowHeight * RANK_BAR_FILL)
    local shown = math.min(#items, math.floor(height / rowHeight))

    for i = 1, shown do
      local item, row = items[i], getRow(i)
      row.item = item
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
      row:SetSize(width, rowHeight)
      row.rank:SetText(i .. ".")
      row.label:SetText(item.label)
      row.track:SetSize(barSpace, barHeight)
      local barWidth = maxValue > 0 and item.value / maxValue * barSpace or 0
      row.bar:SetSize(math.max(1, barWidth), barHeight)
      row.bar:SetColorTexture(unpack(barColor(item)))
      row.value:SetText(item.text)
      row:Show()
    end
    for i = shown + 1, #rows do
      rows[i]:Hide()
    end
  end

  return chart
end

---------------------------------------------------------------------------
-- Heatmap (Wann ich spiele): Zeilen × Spalten aus Kacheln, Farbe von der schwachen Spur bis zur Balkenfarbe nach
-- Anteil am Maximum. grid = { rows = { Beschriftung }, columns = { Beschriftung }, cells[row][column] = item }
-- mit item = { value, label, text } (Tooltip wie bei den anderen Diagrammen); Spalten-Beschriftung nur jede n-te.
---------------------------------------------------------------------------
local HEAT_ROW_LABEL_WIDTH = 30
local HEAT_COLUMN_LABEL_HEIGHT = 14
local HEAT_LABEL_GAP = 4
local HEAT_GAP = 1
local HEAT_MAX_CELL = 20
local HEAT_COLUMN_LABEL_STEP = 3
local HEAT_EMPTY_COLOR = TRACK_COLOR

-- Farbe einer Kachel: share = 0 schwache Spur, 1 volle Balkenfarbe
local function heatColor(share)
  local function mix(index) return HEAT_EMPTY_COLOR[index] + (BAR_COLOR[index] - HEAT_EMPTY_COLOR[index]) * share end
  return mix(1), mix(2), mix(3), HEAT_EMPTY_COLOR[4] + (1 - HEAT_EMPTY_COLOR[4]) * share
end

function Charts.CreateHeatmap(parent, width, height)
  local chart = CreateFrame("Frame", nil, parent)
  chart:SetSize(width, height)
  local tiles, rowLabels, columnLabels = {}, {}, {}

  local function getTile(row, column)
    tiles[row] = tiles[row] or {}
    if tiles[row][column] then return tiles[row][column] end
    local tile = CreateFrame("Frame", nil, chart)
    tile:EnableMouse(true)
    tile.texture = tile:CreateTexture(nil, "ARTWORK")
    tile.texture:SetAllPoints(tile)
    tile:SetScript("OnEnter", function(self)
      self.texture:SetColorTexture(unpack(BAR_HOVER_COLOR))
      showTooltip(self, self.item)
    end)
    tile:SetScript("OnLeave", function(self)
      self.texture:SetColorTexture(heatColor(self.share))
      GameTooltip:Hide()
    end)
    tiles[row][column] = tile
    return tile
  end

  local function getLabel(list, index)
    list[index] = list[index] or chart:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    return list[index]
  end

  function chart:SetItems(grid)
    local rows, columns = #grid.rows, #grid.columns
    local cell = math.min(HEAT_MAX_CELL, (width - HEAT_ROW_LABEL_WIDTH) / math.max(1, columns),
      (height - HEAT_COLUMN_LABEL_HEIGHT) / math.max(1, rows))
    local maxValue = 0
    for row = 1, rows do
      for column = 1, columns do maxValue = math.max(maxValue, grid.cells[row][column].value) end
    end
    for row = 1, rows do
      local label = getLabel(rowLabels, row)
      label:SetText(grid.rows[row])
      label:ClearAllPoints()
      label:SetPoint("RIGHT", chart, "TOPLEFT", HEAT_ROW_LABEL_WIDTH - HEAT_LABEL_GAP, -(row - 0.5) * cell)
      for column = 1, columns do
        local tile, item = getTile(row, column), grid.cells[row][column]
        tile.item = item
        tile.share = maxValue > 0 and item.value / maxValue or 0
        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", HEAT_ROW_LABEL_WIDTH + (column - 1) * cell, -(row - 1) * cell)
        tile:SetSize(cell - HEAT_GAP, cell - HEAT_GAP)
        tile.texture:SetColorTexture(heatColor(tile.share))
      end
    end
    for column = 1, columns do
      local label = getLabel(columnLabels, column)
      label:SetText(grid.columns[column])
      label:ClearAllPoints()
      label:SetPoint("TOP", chart, "TOPLEFT", HEAT_ROW_LABEL_WIDTH + (column - 0.5) * cell, -rows * cell - 2)
      label:SetShown((column - 1) % HEAT_COLUMN_LABEL_STEP == 0)
    end
  end

  return chart
end
