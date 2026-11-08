-- Bausteine des Hauptfensters, die sich die Layouts (UI/Layouts/) teilen: Reiter (von TimerWindow angelegt), Zeit,
-- große Zeit mit Unterzeile, XP-Balken mit Tooltip, Textfelder des schmalen Balkens, Zeilen (Bezeichnung + Wert) und
-- Kacheln. Zeilen und Kacheln entstehen nach Bedarf (Pool). Texte setzen die Layouts über Widgets.SetTextIfChanged,
-- daher gibt es sie nur hier und nie mit SetText von außen.
-- Zeilen und Kacheln haben eine Mausfläche mit Tooltip (Erklärung der Stat aus STAT_*_TIP, dazu die Bedeutung von
-- Platzhaltern wie "..."); Ziehen und Rechtsklick gehen an das Fenster weiter.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Format = ns.Format

local WindowElements = {
  XP_BAR_HEIGHT = 6,
}
ns.WindowElements = WindowElements

local XP_BAR_BACKGROUND = { 1, 1, 1, 0.1 }
local XP_BAR_RESTED = { 0.3, 0.55, 1, 0.6 }
local XP_BAR_QUESTS = { 1, 0.8, 0.2, 0.75 }  -- XP der fertigen Quests (Einstellung questXpOnBar)
local MIN_PART_WIDTH = 1
WindowElements.TILE_PADDING = 4  -- Abstand von Wert und Beschriftung zum Rand der Kachel

local Elements = {}
Elements.__index = Elements

---------------------------------------------------------------------------
-- Mausflächen: Ziehen, Loslassen (Rechtsklick = Einstellungen) gehen an das Fenster weiter
---------------------------------------------------------------------------
local FORWARDED_SCRIPTS = { "OnDragStart", "OnDragStop", "OnMouseUp" }

local function forwardMouse(frame, window)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  for _, script in ipairs(FORWARDED_SCRIPTS) do
    frame:SetScript(script, function(_, ...)
      local handler = window:GetScript(script)
      if handler then handler(window, ...) end
    end)
  end
end

-- Tooltip-Text einer Zeile des Modells (WindowModel: { label, stat, value }): Erklärung der Stat, dazu die Bedeutung
-- eines Platzhalters, wenn gerade einer dasteht; nil = kein Tooltip
function WindowElements.RowTip(data)
  if not data then return nil end
  local parts = {}
  if data.stat then table.insert(parts, L[data.stat.label .. "_TIP"]) end
  if data.value == Format.PENDING then
    table.insert(parts, L.ROW_PENDING_TIP)
  elseif data.value == Format.NO_VALUE then
    table.insert(parts, L.ROW_NO_VALUE_TIP)
  end
  if #parts == 0 then return nil end
  return table.concat(parts, "\n\n")
end

-- Mausfläche mit Tooltip zu den Daten in hover.data (setzt Elements:SetHoverData); watch meldet sie der Sichtbarkeit
local function newRowHover(el, parent)
  local hover = CreateFrame("Frame", nil, parent)
  forwardMouse(hover, el.window)
  Widgets.AttachTooltip(hover, function() return hover.data and hover.data.label or "" end,
    function() return WindowElements.RowTip(hover.data) end)
  if el.watchHover then el.watchHover(hover) end
  return hover
end

---------------------------------------------------------------------------
-- XP-Balken: Grund, Erholt-Bonus, fertige Quests, Fortschritt; darüber eine Mausfläche für den Tooltip
---------------------------------------------------------------------------
local XpBar = {}
XpBar.__index = XpBar

local function newXpBar(window)
  local bar = setmetatable({ window = window, height = WindowElements.XP_BAR_HEIGHT, inset = 0 }, XpBar)
  bar.background = window:CreateTexture(nil, "ARTWORK")
  bar.background:SetColorTexture(unpack(XP_BAR_BACKGROUND))
  bar.rested = window:CreateTexture(nil, "ARTWORK", nil, 1)
  bar.rested:SetPoint("TOPLEFT", bar.background)
  bar.quests = window:CreateTexture(nil, "ARTWORK", nil, 2)
  bar.quests:SetPoint("TOPLEFT", bar.background)
  bar.fill = window:CreateTexture(nil, "ARTWORK", nil, 3)
  bar.fill:SetPoint("TOPLEFT", bar.background)
  bar.parts = { bar.background, bar.rested, bar.quests, bar.fill }

  -- Mausfläche: Tooltip mit genauen Zahlen; Ziehen und Rechtsklick gehen an das Fenster weiter
  bar.hover = CreateFrame("Frame", nil, window)
  bar.hover:SetAllPoints(bar.background)
  forwardMouse(bar.hover, window)
  ns.XpTooltip.Attach(bar.hover)
  bar:SetShown(false)
  return bar
end

-- Füllungen in der Balkentextur des Themes (themeBarTexture), Fortschritt in der Akzentfarbe; nach jedem Apply
function XpBar:ApplyTexture()
  Theme.SetBarTexture(self.rested, unpack(XP_BAR_RESTED))
  Theme.SetBarTexture(self.quests, unpack(XP_BAR_QUESTS))
  Theme.SetBarTexture(self.fill, Theme.RGB("accent"))
end

function XpBar:SetHeight(height)
  self.height = height
  for _, part in ipairs(self.parts) do part:SetHeight(height) end
end

-- Über die ganze Fensterbreite bei Höhe y (von oben), inset = Abstand links und rechts
function XpBar:Place(y, inset)
  self.inset = inset
  self.background:ClearAllPoints()
  self.background:SetPoint("TOPLEFT", self.window, "TOPLEFT", inset, -y)
  self.background:SetPoint("TOPRIGHT", self.window, "TOPRIGHT", -inset, -y)
  self.drawn = nil
end

function XpBar:SetShown(shown, questsShown)
  self.shown = shown
  for _, part in ipairs(self.parts) do part:SetShown(shown) end
  self.quests:SetShown(shown and questsShown or false)
  self.hover:SetShown(shown)
  self.drawn = nil
end

-- Breiten aus dem Modell (model.xpBar); nur wenn sich Werte oder Fensterbreite geändert haben
function XpBar:Update(values)
  if not self.shown or not values.shown or values.max <= 0 then return end
  local width = self.window:GetWidth() - 2 * self.inset
  local drawn = self.drawn
  if drawn and drawn.width == width and drawn.xp == values.xp and drawn.max == values.max
    and drawn.rested == values.rested and drawn.quests == values.quests then return end
  self.drawn = { width = width, xp = values.xp, max = values.max, rested = values.rested, quests = values.quests }
  self.fill:SetWidth(math.max(MIN_PART_WIDTH, width * values.xp / values.max))
  self.rested:SetWidth(math.max(MIN_PART_WIDTH, width * values.rested / values.max))
  if values.quests then self.quests:SetWidth(math.max(MIN_PART_WIDTH, width * values.quests / values.max)) end
end

---------------------------------------------------------------------------
-- Elemente eines Fensters
---------------------------------------------------------------------------
-- tabs = { Reiter Level, Session, Instanz } (Buttons mit SetLabel/SetActive, von TimerWindow); el.watchHover(frame)
-- optional: neue Mausflächen (Zeilen, Kacheln) anmelden, z.B. bei der Sichtbarkeitsregel "bei Mauskontakt"
function WindowElements.New(window, tabs)
  local el = setmetatable({
    window = window, tabs = tabs, rows = {}, tiles = {}, tabTexts = {},
    labelFont = Theme.Font("label"), valueFont = Theme.Font("small"),
  }, Elements)
  el.time = window:CreateFontString(nil, "OVERLAY", Theme.Font("number"))
  el.big = window:CreateFontString(nil, "OVERLAY", Theme.Font("huge"))
  el.sub = window:CreateFontString(nil, "OVERLAY", Theme.Font("label"))
  el.fields = {}
  for index, justify in ipairs({ "LEFT", "CENTER", "RIGHT" }) do
    local field = window:CreateFontString(nil, "OVERLAY", Theme.Font("small", true))
    field:SetJustifyH(justify)
    el.fields[index] = field
  end
  el.xpBar = newXpBar(window)
  el:HideAll()
  return el
end

-- Schriften der Zeilen (Layout "text" mit Kontur); wirkt auf vorhandene und künftige Zeilen
function Elements:SetRowFonts(labelFont, valueFont)
  if self.labelFont == labelFont and self.valueFont == valueFont then return end
  self.labelFont, self.valueFont = labelFont, valueFont
  for _, row in ipairs(self.rows) do
    row.label:SetFontObject(labelFont)
    row.value:SetFontObject(valueFont)
  end
end

-- Zeile index ({ label, value, hover }), bei Bedarf angelegt; die Mausfläche reicht von der Bezeichnung bis zum Wert,
-- folgt also jedem Layout, das beide anordnet
function Elements:Row(index)
  local row = self.rows[index]
  if row then return row end
  row = {
    label = self.window:CreateFontString(nil, "OVERLAY", self.labelFont),
    value = self.window:CreateFontString(nil, "OVERLAY", self.valueFont),
  }
  row.hover = newRowHover(self, self.window)
  row.hover:SetPoint("TOPLEFT", row.label, "TOPLEFT")
  row.hover:SetPoint("BOTTOMRIGHT", row.value, "BOTTOMRIGHT")
  row.hover:Hide()
  self.rows[index] = row
  return row
end

-- Tooltip-Daten einer Zeile oder Kachel (Zeile aus model.rows, nil = kein Tooltip) und Mausfläche zeigen
function Elements:SetHoverData(hover, data)
  hover.data = data
  hover:SetShown(data ~= nil)
end

-- Kachel index ({ frame, value, label }): Fläche im Stil der Karten, Wert groß, Beschriftung klein darunter
function Elements:Tile(index)
  local tile = self.tiles[index]
  if tile then return tile end
  local frame = CreateFrame("Frame", nil, self.window)
  tile = {
    frame = frame,
    value = frame:CreateFontString(nil, "OVERLAY", Theme.Font("number")),
    label = frame:CreateFontString(nil, "OVERLAY", Theme.Font("label")),
  }
  forwardMouse(frame, self.window)
  Widgets.AttachTooltip(frame, function() return tile.data and tile.data.label or "" end,
    function() return WindowElements.RowTip(tile.data) end)
  if self.watchHover then self.watchHover(frame) end
  tile.value:SetPoint("TOP", frame, "TOP", 0, -WindowElements.TILE_PADDING)
  tile.label:SetPoint("BOTTOM", frame, "BOTTOM", 0, WindowElements.TILE_PADDING)
  self.tiles[index] = tile
  return tile
end

-- Zeilen ab index verstecken (nach dem Layout der sichtbaren)
function Elements:HideRowsFrom(index)
  for i = index, #self.rows do
    self.rows[i].label:Hide()
    self.rows[i].value:Hide()
    self.rows[i].hover:Hide()
  end
end

function Elements:HideTilesFrom(index)
  for i = index, #self.tiles do self.tiles[i].frame:Hide() end
end

-- Alles verstecken (Layoutwechsel); das neue Layout zeigt, was es braucht
function Elements:HideAll()
  for _, tab in ipairs(self.tabs) do tab:Hide() end
  self.time:Hide()
  self.big:Hide()
  self.sub:Hide()
  for _, field in ipairs(self.fields) do field:Hide() end
  self.xpBar:SetShown(false)
  self:HideRowsFrom(1)
  self:HideTilesFrom(1)
end

-- Nach einem Apply alles neu setzen (Farben, Schriften und Sprache können gewechselt haben)
function Elements:ResetCache()
  self.tabTexts = {}
  for _, tab in ipairs(self.tabs) do tab.active = nil end
end

-- Reiter: Beschriftung nur bei geändertem Text (SetLabel misst und ändert die Größe); true = etwas hat sich geändert
function Elements:RenderTabs(model)
  local changed = false
  for index, tab in ipairs(self.tabs) do
    local data = model.tabs[index]
    if self.tabTexts[index] ~= data.text then
      self.tabTexts[index] = data.text
      tab:SetLabel(data.text)
      changed = true
    end
    if tab.active ~= data.active then
      tab.active = data.active
      tab:SetActive(data.active)
    end
  end
  return changed
end

-- Text setzen; true, wenn er sich geändert hat
function WindowElements.SetText(fontString, text)
  return Widgets.SetTextIfChanged(fontString, text)
end

-- Schriftgröße eines FontStrings in Punkten (Zeilenhöhen folgen der Schrift)
function WindowElements.FontSize(fontString)
  local _, size = fontString:GetFont()
  return size or 0
end
