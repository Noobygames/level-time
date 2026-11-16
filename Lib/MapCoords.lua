-- Welt- und Kartenkoordinaten umrechnen (Roadmap 461). Weltkoordinaten sind Yards im Format von
-- C_Map.GetWorldPosFromMapPos: x = Nord-Achse, y = West-Achse (am Wald von Elwynn nachgerechnet: Karte (0,0) liegt bei
-- Nord-Maximum und West-Maximum; UnitPosition liefert dieselben Werte als y, x). Kartenkoordinaten sind 0..1 von oben links.
--   MapCoords.MapToWorld(uiMapID, x, y)   -> instanceID, worldX, worldY oder nil
--   MapCoords.WorldToMap(uiMapID, worldX, worldY) -> x, y oder nil (nicht begrenzt: außerhalb der Karte < 0 oder > 1)
--   MapCoords.Size(uiMapID)               -> Breite (West-Ost), Höhe (Nord-Süd) in Yards oder nil
--   MapCoords.Translate(fromMapID, x, y, toMapID) -> x, y auf der anderen Karte (nicht begrenzt) oder nil, wenn die
--                                         Karten auf verschiedenen Kontinenten liegen oder eine Umrechnung fehlt
-- Zuerst die Client-API (C_Map.GetWorldPosFromMapPos / GetMapPosFromWorldPos), sonst die erzeugten Bereiche
-- ns.MapCoordsData (tools/flights, Assist/MapCoordsData/<flavor>.lua: Kontinent- und Zonenkarten).
local _, ns = ...

local MapCoords = {}
ns.MapCoords = MapCoords

local AREA_INSTANCE, AREA_MIN_NORTH, AREA_MIN_WEST, AREA_MAX_NORTH, AREA_MAX_WEST = 1, 2, 3, 4, 5

local function area(uiMapID)
  local data = ns.MapCoordsData
  return data and data.areas[uiMapID]
end

local function readable(value)
  return type(value) == "number" and not ns.IsSecret(value)
end

local function hasApi()
  return C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D
end

-- Client-API: instanceID, worldX, worldY oder nil
local function liveMapToWorld(uiMapID, x, y)
  if not hasApi() then return nil end
  local ok, instanceID, position = pcall(C_Map.GetWorldPosFromMapPos, uiMapID, CreateVector2D(x, y))
  if not (ok and type(position) == "table" and position.GetXY and readable(instanceID)) then return nil end
  local worldX, worldY = position:GetXY()
  if not (readable(worldX) and readable(worldY)) then return nil end
  return instanceID, worldX, worldY
end

local function liveWorldToMap(uiMapID, worldX, worldY)
  if not (hasApi() and C_Map.GetMapPosFromWorldPos) then return nil end
  local instanceID = liveMapToWorld(uiMapID, 0, 0)
  if not instanceID then return nil end
  local ok, _, position = pcall(C_Map.GetMapPosFromWorldPos, instanceID, CreateVector2D(worldX, worldY), uiMapID)
  if not (ok and type(position) == "table" and position.GetXY) then return nil end
  local x, y = position:GetXY()
  if not (readable(x) and readable(y)) then return nil end
  return x, y
end

-- Nur die erzeugten Daten (auch Vergleich mit der Client-API im Debug-Check 440.transport.state)
function MapCoords.MapToWorldData(uiMapID, x, y)
  if not (readable(uiMapID) and readable(x) and readable(y)) then return nil end
  local a = area(uiMapID)
  if not a then return nil end
  return a[AREA_INSTANCE], a[AREA_MAX_NORTH] - y * (a[AREA_MAX_NORTH] - a[AREA_MIN_NORTH]),
    a[AREA_MAX_WEST] - x * (a[AREA_MAX_WEST] - a[AREA_MIN_WEST])
end

function MapCoords.MapToWorld(uiMapID, x, y)
  if not (readable(uiMapID) and readable(x) and readable(y)) then return nil end
  local instanceID, worldX, worldY = liveMapToWorld(uiMapID, x, y)
  if instanceID then return instanceID, worldX, worldY end
  return MapCoords.MapToWorldData(uiMapID, x, y)
end

function MapCoords.WorldToMap(uiMapID, worldX, worldY)
  if not (readable(uiMapID) and readable(worldX) and readable(worldY)) then return nil end
  local liveX, liveY = liveWorldToMap(uiMapID, worldX, worldY)
  if liveX then return liveX, liveY end
  local a = area(uiMapID)
  if not a then return nil end
  return (a[AREA_MAX_WEST] - worldY) / (a[AREA_MAX_WEST] - a[AREA_MIN_WEST]),
    (a[AREA_MAX_NORTH] - worldX) / (a[AREA_MAX_NORTH] - a[AREA_MIN_NORTH])
end

function MapCoords.Size(uiMapID)
  local a = area(uiMapID)
  if not a then return nil end
  return a[AREA_MAX_WEST] - a[AREA_MIN_WEST], a[AREA_MAX_NORTH] - a[AREA_MIN_NORTH]
end

function MapCoords.Translate(fromMapID, x, y, toMapID)
  if fromMapID == toMapID then return x, y end
  local instanceID, worldX, worldY = MapCoords.MapToWorld(fromMapID, x, y)
  if not instanceID or MapCoords.MapToWorld(toMapID, 0, 0) ~= instanceID then return nil end
  return MapCoords.WorldToMap(toMapID, worldX, worldY)
end
