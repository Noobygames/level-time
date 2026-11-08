-- Auswahl der Zielart im Reiter "Ziele" (UX G15): ein Raster aus Kacheln, je Art Symbol und Name in der Farbe der Art,
-- statt zweier Reiterzeilen (Gruppe, dann Art). Alle Arten sind auf einen Blick sichtbar; die Reihenfolge folgt den
-- Gruppen (Goals.KIND_GROUPS), verwandte Arten stehen so nebeneinander. Tooltip einer Kachel = Erklärung der Art
-- (<label>_TIP) und gedämpft der Chatbefehl (tipLines).
-- Spaltenzahl aus dem breitesten Namen in der gewählten Sprache: so viele Spalten, wie Kacheln dieser Breite in die
-- Seite passen (höchstens MAX_COLUMNS), dann gleichmäßig auf die Zeilen verteilt; die Kacheln teilen sich die Breite.
-- Keine feste Textbreite, fr/es passen dadurch genauso wie de/en.
--   picker = KindPicker.Create(parent, { kinds() -> Liste, label(kind), onSelect(kind), tipLines(kind) })
--   picker:Layout(top, selected) -> Höhe; picker:Tile(kind) (Tests); picker:SetShown(shown); picker.columns
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Manager = ns.Manager
local L = ns.L
local Theme = LT.Theme

local KindPicker = {}
ns.KindPicker = KindPicker

local TILE_HEIGHT = 20
local TILE_GAP = 3
local ICON_SIZE = 14
local ICON_INSET = 4            -- Abstand des Symbols vom linken Rand (hinter dem Farbstreifen)
local LABEL_GAP = 4             -- Symbol zum Namen
local LABEL_RIGHT = 4           -- Luft rechts vom Namen
local STRIPE_WIDTH = 3          -- Farbstreifen links in der Farbe der Art
local MAX_COLUMNS = 6
local ALPHA = { normal = 0.16, hover = 0.3, selected = 0.55 }

-- Symbol der Art als Textur: Zahl = Spell-ID (wie Alerts.ICONS und die Karten), sonst Pfad
local function iconTexture(icon)
  if type(icon) == "number" then
    local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(icon)
    if not texture and GetSpellTexture then texture = GetSpellTexture(icon) end  -- ältere Clients
    return texture
  end
  return icon
end

-- Platz, den eine Kachel außer dem Namen braucht
local function chrome()
  return STRIPE_WIDTH + ICON_INSET + ICON_SIZE + LABEL_GAP + LABEL_RIGHT
end

-- Spalten für count Kacheln, deren breitester Name widest ist: so viele, wie in width passen, dann gleichmäßig verteilt
-- (14 Arten in 6 Spalten = 3 Zeilen; 5 Spalten füllen die 3 Zeilen auch, mit weniger leeren Plätzen)
function KindPicker.Columns(count, widest, width)
  local fit = math.floor((width + TILE_GAP) / (widest + chrome() + TILE_GAP))
  local columns = math.max(1, math.min(MAX_COLUMNS, fit, count))
  local rows = math.ceil(count / columns)
  return math.max(1, math.ceil(count / rows))
end

function KindPicker.Create(parent, spec)
  local picker = { tiles = {}, columns = 1 }

  local function paint(tile)
    local color = Goals.GetKind(tile.kind).color or Theme.COLORS.accent
    local state = tile.selected and "selected" or (tile.hovered and "hover" or "normal")
    tile.back:SetColorTexture(color[1], color[2], color[3], ALPHA[state])
    tile.stripe:SetColorTexture(color[1], color[2], color[3], 1)
    tile.label:SetTextColor(Theme.RGB(tile.selected and "text" or "muted"))
  end

  local function tileOf(kind)
    if picker.tiles[kind] then return picker.tiles[kind] end
    local def = Goals.GetKind(kind)
    local tile = CreateFrame("Button", nil, parent)
    tile.kind = kind
    tile:SetHeight(TILE_HEIGHT)
    tile.back = tile:CreateTexture(nil, "BACKGROUND")
    tile.back:SetAllPoints()
    tile.stripe = tile:CreateTexture(nil, "BORDER")
    tile.stripe:SetPoint("TOPLEFT")
    tile.stripe:SetPoint("BOTTOMLEFT")
    tile.stripe:SetWidth(STRIPE_WIDTH)
    tile.icon = tile:CreateTexture(nil, "ARTWORK")
    tile.icon:SetSize(ICON_SIZE, ICON_SIZE)
    tile.icon:SetPoint("LEFT", STRIPE_WIDTH + ICON_INSET, 0)
    tile.icon:SetTexture(iconTexture(def.icon))
    tile.label = tile:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
    tile.label:SetPoint("LEFT", tile.icon, "RIGHT", LABEL_GAP, 0)
    tile.label:SetPoint("RIGHT", -LABEL_RIGHT, 0)
    tile.label:SetJustifyH("LEFT")
    tile.label:SetWordWrap(false)
    tile:SetScript("OnClick", function() spec.onSelect(kind) end)
    tile:HookScript("OnEnter", function() tile.hovered = true paint(tile) end)
    tile:HookScript("OnLeave", function() tile.hovered = false paint(tile) end)
    Manager.AttachTooltip(tile, function() return spec.label(kind) end, function() return spec.tipLines(kind) end)
    picker.tiles[kind] = tile
    return tile
  end

  -- Kacheln ab y = top im Raster; selected = gewählte Art. Rückgabe: Höhe des Rasters
  function picker:Layout(top, selected)
    local kinds = spec.kinds()
    local shown, widest = {}, 0
    for _, kind in ipairs(kinds) do
      local tile = tileOf(kind)
      tile.label:SetText(spec.label(kind))
      widest = math.max(widest, math.ceil(tile.label:GetStringWidth() or 0))
      shown[kind] = true
    end
    for kind, tile in pairs(self.tiles) do
      if not shown[kind] then tile:Hide() end
    end
    local width = Manager.PAGE_WIDTH
    local columns = KindPicker.Columns(#kinds, widest, width)
    local tileWidth = math.floor((width - (columns - 1) * TILE_GAP) / columns)
    self.columns, self.tileWidth, self.widest = columns, tileWidth, widest
    for index, kind in ipairs(kinds) do
      local tile = self.tiles[kind]
      local row, column = math.floor((index - 1) / columns), (index - 1) % columns
      tile:SetWidth(tileWidth)
      tile:ClearAllPoints()
      tile:SetPoint("TOPLEFT", column * (tileWidth + TILE_GAP), top - row * (TILE_HEIGHT + TILE_GAP))
      tile.selected = kind == selected
      paint(tile)
      tile:SetShown(self.shown ~= false)
    end
    local rows = math.ceil(#kinds / columns)
    return rows * TILE_HEIGHT + math.max(0, rows - 1) * TILE_GAP
  end

  -- Ganzes Raster ein- oder ausblenden (Bearbeiten eines laufenden Ziels: die Art steht fest)
  function picker:SetShown(shown)
    self.shown = shown and true or false
    for _, tile in pairs(self.tiles) do tile:SetShown(self.shown) end
  end

  function picker:Tile(kind)
    return self.tiles[kind]
  end

  -- Platz, den der breiteste Name samt Symbol braucht (Tests: passt in die Kachel)
  function picker:NeededWidth()
    return (self.widest or 0) + chrome()
  end

  return picker
end
