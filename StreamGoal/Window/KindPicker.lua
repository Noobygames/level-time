-- Auswahl der Zielart im Reiter "Ziele" (UX G15): Zeilen aus Kacheln, je Art Symbol und Name in der Farbe der Art,
-- statt zweier Reiterzeilen (Gruppe, dann Art). Alle Arten sind auf einen Blick sichtbar; die Reihenfolge folgt den
-- Gruppen (Goals.KIND_GROUPS), verwandte Arten stehen so nebeneinander. Tooltip einer Kachel = Erklärung der Art
-- (<label>_TIP) und gedämpft der Chatbefehl (tipLines).
-- Zeilen wie Schlagwörter (Roadmap 439, mehr Arten bei gleicher Seitenhöhe): jede Kachel ist so breit wie ihr Name in
-- der gewählten Sprache samt Symbol; die Kacheln kommen der Reihe nach auf so wenige Zeilen wie möglich, möglichst
-- gleich voll verteilt (KindPicker.Rows), dann wird jede Zeile auf die volle Seitenbreite gestreckt (beide Ränder
-- bündig). Keine feste Textbreite, fr/es passen dadurch genauso wie de/en; kurze Namen sparen Platz für lange.
--   picker = KindPicker.Create(parent, { kinds() -> Liste, label(kind), onSelect(kind), tipLines(kind) })
--   picker:Layout(top, selected) -> Höhe; picker:Tile(kind) (Tests); picker:SetShown(shown); picker:Fits() (Tests);
--   picker.columns (meiste Kacheln einer Zeile), picker.rows
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

-- Breite der Kacheln first..last nebeneinander (natürliche Breiten samt Abständen)
local function rowWidth(widths, first, last)
  local sum = (last - first) * TILE_GAP
  for index = first, last do sum = sum + widths[index] end
  return sum
end

-- Wenigste Zeilen: der Reihe nach auffüllen, bis die nächste Kachel nicht mehr in width passt
local function fewestRows(widths, width)
  local rows, used = 1, 0
  for _, tileWidth in ipairs(widths) do
    if used > 0 and used + TILE_GAP + tileWidth > width then
      rows, used = rows + 1, tileWidth
    else
      used = used > 0 and used + TILE_GAP + tileWidth or tileWidth
    end
  end
  return rows
end

-- Kacheln (natürliche Breiten in Anzeige-Reihenfolge) auf die wenigsten Zeilen der Breite width verteilen, so
-- gleichmäßig wie möglich: die breiteste Zeile so schmal wie möglich (Aufteilung einer Folge, wenige Kacheln, daher
-- einfach durchprobiert). Rückgabe: Liste der ersten Kachel je Zeile, z.B. { 1, 7, 13 }
function KindPicker.Rows(widths, width)
  local count = #widths
  if count == 0 then return {} end
  local rows = fewestRows(widths, width)
  local memo = {}
  -- widest(first, left) = schmalste mögliche breiteste Zeile für first..count auf left Zeilen, plus Beginn der zweiten
  local function widest(first, left)
    if left == 1 then return rowWidth(widths, first, count) end
    local key = first * 100 + left
    if memo[key] then return memo[key][1], memo[key][2] end
    local best, bestNext
    for last = first, count - left + 1 do
      local value = math.max(rowWidth(widths, first, last), (widest(last + 1, left - 1)))
      if not best or value < best then best, bestNext = value, last + 1 end
    end
    memo[key] = { best, bestNext }
    return best, bestNext
  end
  local starts, first = { 1 }, 1
  for left = rows, 2, -1 do
    local _, nextFirst = widest(first, left)
    first = nextFirst
    table.insert(starts, first)
  end
  return starts
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
  -- Eine Zeile (Kacheln first..last) ab y auf die volle Breite strecken: der Rest verteilt sich gleichmäßig, die letzte
  -- Kachel endet genau am rechten Rand
  local function placeRow(kinds, widths, first, last, y, width, selected)
    local extra = width - rowWidth(widths, first, last)
    local share = math.floor(extra / (last - first + 1))
    local x = 0
    for index = first, last do
      local tile = picker.tiles[kinds[index]]
      local tileWidth = index == last and width - x or widths[index] + share
      tile:SetWidth(tileWidth)
      tile:ClearAllPoints()
      tile:SetPoint("TOPLEFT", x, y)
      tile.selected = kinds[index] == selected
      paint(tile)
      tile:SetShown(picker.shown ~= false)
      x = x + tileWidth + TILE_GAP
    end
  end

  -- Kacheln ab y = top in Zeilen; selected = gewählte Art. Rückgabe: Höhe der Zeilen
  function picker:Layout(top, selected)
    local kinds = spec.kinds()
    local shown, widths = {}, {}
    for index, kind in ipairs(kinds) do
      local tile = tileOf(kind)
      tile.label:SetText(spec.label(kind))
      widths[index] = math.ceil(tile.label:GetStringWidth() or 0) + chrome()
      shown[kind] = true
    end
    for kind, tile in pairs(self.tiles) do
      if not shown[kind] then tile:Hide() end
    end
    local width = Manager.PAGE_WIDTH
    local starts = KindPicker.Rows(widths, width)
    self.needed, self.columns, self.rows = {}, 0, #starts
    for index, kind in ipairs(kinds) do self.needed[kind] = widths[index] end
    for row, first in ipairs(starts) do
      local last = (starts[row + 1] or #kinds + 1) - 1
      placeRow(kinds, widths, first, last, top - (row - 1) * (TILE_HEIGHT + TILE_GAP), width, selected)
      self.columns = math.max(self.columns, last - first + 1)
    end
    return #starts * TILE_HEIGHT + math.max(0, #starts - 1) * TILE_GAP
  end

  -- Ganzes Raster ein- oder ausblenden (Bearbeiten eines laufenden Ziels: die Art steht fest)
  function picker:SetShown(shown)
    self.shown = shown and true or false
    for _, tile in pairs(self.tiles) do tile:SetShown(self.shown) end
  end

  function picker:Tile(kind)
    return self.tiles[kind]
  end

  -- Passt jeder Name samt Symbol in seine Kachel? (Tests)
  function picker:Fits()
    for kind, needed in pairs(self.needed or {}) do
      if self.tiles[kind]:GetWidth() < needed then return false end
    end
    return true
  end

  return picker
end
