-- Karte aufdecken (Einstellung mapReveal, Standard aus): unerkundete Gebiete der Weltkarte werden abgedunkelt
-- eingeblendet. Der Client liefert nur erkundete Kacheln (C_MapExplorationInfo.GetExploredMapTextures); Größe, Lage und
-- Textur-IDs der übrigen Überlagerungen stehen in ns.MapOverlayData (tools/flights, Assist/MapOverlayData/<flavor>.lua
-- aus DB2 WorldMapOverlay/WorldMapOverlayTile). Gezeichnet wie Blizzards MapExplorationDataProvider
-- (Blizzard_SharedMapDataProviders): Kacheln zeilenweise, letzte Spalte/Zeile nur so groß wie nötig (Texturdatei = nächste
-- Zweierpotenz >= 16), Lage = Versatz vom linken oberen Rand der Kartengrafik. Kartengrafik = C_Map.GetMapArtID.
-- Erkundete Überlagerungen (gleicher Versatz) zeichnet Blizzard selbst und werden übersprungen.
-- Kein Takt: neu gezeichnet wird nur bei Kartenwechsel, Größenänderung, Öffnen und MAP_EXPLORATION_UPDATED; Texturen
-- kommen aus einem Pool und werden wiederverwendet.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    mapReveal = false,
  },
})

local MapReveal = {}
ns.MapReveal = MapReveal

local DEFAULT_TILE = 256
local MIN_FILE_SIZE = 16
local OVERLAY_ALPHA = 0.55
local HEADER = 4  -- Breite, Höhe, OffsetX, OffsetY vor den Kachel-IDs

local overlay      -- eigener Rahmen auf der Kartenleinwand
local textures = {}  -- Pool

local function offsetKey(x, y)
  return x .. "," .. y
end

-- Überlagerungen der Kartengrafik von mapID, die noch nicht erkundet sind (nil ohne Daten)
function MapReveal.Overlays(mapID)
  local data = ns.MapOverlayData
  if not data or type(mapID) ~= "number" or not (C_Map and C_Map.GetMapArtID) then return nil end
  local list = data.art[C_Map.GetMapArtID(mapID)]
  if not list then return nil end
  local explored = {}
  local exploredTextures = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures
    and C_MapExplorationInfo.GetExploredMapTextures(mapID)
  for _, info in ipairs(exploredTextures or {}) do
    explored[offsetKey(info.offsetX, info.offsetY)] = true
  end
  local result = {}
  for _, entry in ipairs(list) do
    if not explored[offsetKey(entry[3], entry[4])] then table.insert(result, entry) end
  end
  return result
end

local function fileSize(pixels)
  local size = MIN_FILE_SIZE
  while size < pixels do size = size * 2 end
  return size
end

local function layerInfo(mapID)
  local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(mapID)
  return layers and layers[1] or {}
end

local function hideFrom(index)
  for i = index, #textures do textures[i]:Hide() end
end

local function draw(entries, tileWidth, tileHeight)
  local used = 0
  for _, entry in ipairs(entries) do
    local width, height, offsetX, offsetY = entry[1], entry[2], entry[3], entry[4]
    local wide, tall = math.ceil(width / tileWidth), math.ceil(height / tileHeight)
    for row = 1, tall do
      local pixelHeight = row < tall and tileHeight or (height % tileHeight == 0 and tileHeight or height % tileHeight)
      for column = 1, wide do
        local file = entry[HEADER + (row - 1) * wide + column]
        if file and file ~= 0 then
          local pixelWidth = column < wide and tileWidth or (width % tileWidth == 0 and tileWidth or width % tileWidth)
          used = used + 1
          local texture = textures[used]
          if not texture then
            texture = overlay:CreateTexture(nil, "ARTWORK")
            textures[used] = texture
          end
          texture:SetSize(pixelWidth, pixelHeight)
          texture:SetTexCoord(0, pixelWidth / (column < wide and tileWidth or fileSize(pixelWidth)),
            0, pixelHeight / (row < tall and tileHeight or fileSize(pixelHeight)))
          texture:ClearAllPoints()
          texture:SetPoint("TOPLEFT", overlay, "TOPLEFT", offsetX + tileWidth * (column - 1),
            -(offsetY + tileHeight * (row - 1)))
          texture:SetTexture(file)
          texture:Show()
        end
      end
    end
  end
  hideFrom(used + 1)
  return used
end

function MapReveal.Refresh()
  if not overlay or not overlay:IsShown() then return end
  local map = WorldMapFrame
  local mapID = map and map.GetMapID and map:GetMapID()
  if ns.IsSecret(mapID) then mapID = nil end
  local entries = MapReveal.Overlays(mapID)
  if not entries then return hideFrom(1) end
  local layer = layerInfo(mapID)
  -- Kartenleinwand und Kartengrafik können verschieden groß sein: Rahmen in Grafikgröße, auf die Leinwand skaliert
  local canvasWidth = overlay:GetParent() and overlay:GetParent():GetWidth() or 0
  if layer.layerWidth and canvasWidth and canvasWidth > 0 then
    overlay:SetScale(canvasWidth / layer.layerWidth)
  end
  local used = draw(entries, layer.tileWidth or DEFAULT_TILE, layer.tileHeight or DEFAULT_TILE)
  ns.Debug("mapreveal", "map %s: %s overlays, %s tiles", tostring(mapID), #entries, used)
end

local function create()
  local map = WorldMapFrame
  if overlay or type(map) ~= "table" or not map.GetCanvas then return end
  local canvas = map:GetCanvas()
  if not canvas then return end
  overlay = CreateFrame("Frame", ns.GlobalName("MapReveal"), canvas)
  overlay:SetPoint("TOPLEFT", canvas, "TOPLEFT")
  overlay:SetSize(canvas:GetWidth(), canvas:GetHeight())
  overlay:SetFrameLevel(ns.MapCompat.OverlayLevel(canvas))
  overlay:SetAlpha(OVERLAY_ALPHA)
  overlay:SetShown(ns.db and ns.db.mapReveal or false)
  if map.OnMapChanged then
    hooksecurefunc(map, "OnMapChanged", function() ns.SafeCall(MapReveal.Refresh) end)
  end
  map:HookScript("OnShow", function() ns.SafeCall(MapReveal.Refresh) end)
  ns.Debug("mapreveal", "attached to WorldMapFrame")
end

ns.OnLogin(create)
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == "Blizzard_WorldMap" then create() end
end)
ns.RegisterEvent("MAP_EXPLORATION_UPDATED", function()
  if overlay and overlay:IsVisible() then MapReveal.Refresh() end
end)
ns.RegisterApply(function(db)
  if not overlay then return end
  overlay:SetShown(db.mapReveal)
  if not db.mapReveal then hideFrom(1) else MapReveal.Refresh() end
end)
