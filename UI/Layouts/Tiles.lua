-- Layout "tiles" (Kacheln): Raster mit tileColumns Spalten; jede Kachel zeigt einen Wert groß und darunter klein die
-- Beschriftung (Kurzform). Erste Kachel = Spielzeit mit dem Bereich ("Level 23") als Beschriftung, dann die
-- eingeschalteten Zeilen. Alle Kacheln sind gleich breit (breitester Inhalt); XP-Balken unter dem Raster.
-- Darüber die Reiter Level/Session/Instanz wie in der Tabelle (Bereich umschalten).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    tileColumns = 3,
  },
  ranges = {
    tileColumns = { 1, 6 },
  },
})
local Layouts = ns.WindowLayouts
local WindowModel = ns.WindowModel
local Theme = ns.Theme
local Elements = ns.WindowElements

local Tiles = {
  MIN_COLUMNS = 1,
  MAX_COLUMNS = 6,
}
Layouts.Tiles = Tiles

local PADDING = 8
local GAP = 4
local MIN_TILE_WIDTH = 64
local LABEL_GAP = 2
local setText = Elements.SetText
local fontSize = Layouts.FontSize

local layout = { label = "LAYOUT_TILES", source = WindowModel.VISIBLE }

local function columnsOf(db, count)
  local columns = math.max(Tiles.MIN_COLUMNS, math.min(Tiles.MAX_COLUMNS, math.floor(db.tileColumns or 1)))
  return math.max(1, math.min(columns, count))
end

-- Kachel 1 = Zeit, danach die Zeilen
local function tileCount(model)
  return #model.rows + 1
end

-- Kacheln an ihre Stelle im Raster (bei neuer Struktur und wenn die Kachelbreite wächst)
local function placeTiles(el, model, db)
  local count = tileCount(model)
  local columns = columnsOf(db, count)
  for index = 1, count do
    local tile = el:Tile(index)
    local column, line = (index - 1) % columns, math.floor((index - 1) / columns)
    tile.frame:ClearAllPoints()
    tile.frame:SetPoint("TOPLEFT", el.window, "TOPLEFT", PADDING + column * (el.tileWidth + GAP),
      -(el.tilesTop + line * (el.tileHeight + GAP)))
    tile.frame:SetSize(el.tileWidth, el.tileHeight)
  end
end

function layout.Build(el, model, db)
  local count = tileCount(model)
  local first = el:Tile(1)
  el.tileWidth = MIN_TILE_WIDTH
  el.tileHeight = fontSize(first.value) + fontSize(first.label) + 2 * Elements.TILE_PADDING + LABEL_GAP
  el.tilesTop = PADDING + Layouts.PlaceTabsCentered(el, PADDING)
  for index = 1, count do
    local tile = el:Tile(index)
    Theme.ApplyCard(tile.frame)  -- Fläche im Stil des Themes, auch nach einem Wechsel
    tile.data = model.rows[index - 1]  -- Tooltip der Zeile; Kachel 1 (Zeit) hat keinen
    tile.frame:Show()
  end
  el:HideTilesFrom(count + 1)
  placeTiles(el, model, db)
  local lines = math.ceil(count / columnsOf(db, count))
  local y = el.tilesTop + lines * el.tileHeight + (lines - 1) * GAP + Layouts.TABLE_GAP
  y = Layouts.PlaceXpBar(el, model, y, PADDING)
  return y - Layouts.TABLE_GAP + PADDING
end

function layout.Render(el, model)
  local first = el.tiles[1]
  local changed = el:RenderTabs(model)
  changed = setText(first.value, model.time.text) or changed
  changed = setText(first.label, model.scopeText or "") or changed
  for index, data in ipairs(model.rows) do
    local tile = el.tiles[index + 1]
    changed = setText(tile.value, data.value) or changed
    changed = setText(tile.label, data.shortLabel) or changed
  end
  return changed
end

function layout.Measure(el, model, db)
  local widest = el.tileWidth
  for index = 1, tileCount(model) do
    local tile = el.tiles[index]
    widest = math.max(widest, tile.value:GetStringWidth() + 2 * Elements.TILE_PADDING,
      tile.label:GetStringWidth() + 2 * Elements.TILE_PADDING)
  end
  if widest > el.tileWidth then
    el.tileWidth = widest
    placeTiles(el, model, db)
  end
  local columns = columnsOf(db, tileCount(model))
  return math.max(Layouts.CenteredTabsWidth(el), 2 * PADDING + columns * el.tileWidth + (columns - 1) * GAP)
end

Layouts.Register("tiles", layout)
