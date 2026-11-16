-- Richtungspfeil zu einem Kartenpunkt (Leichenpfeil Assist/CorpseArrow.lua, Questpfeil Assist/QuestArrow.lua): Rechnung und
-- Anzeige. Quellen (MapDocumentation, PlayerScriptDocumentation; Zweige classic_era, forever, live):
--   C_Map.GetBestMapForUnit("player"), C_Map.GetPlayerMapPosition(uiMapID, "player")  Spieler auf seiner Karte
--   GetPlayerFacing()  Blickrichtung im Bogenmaß, 0 = Norden, gegen den Uhrzeigersinn (in Era nicht dokumentiert: geprüft)
--   Weltkoordinaten über Lib/MapCoords.lua (x = Nord-Achse, y = West-Achse, Yards): Ziel und Spieler dürfen auf
--   verschiedenen Karten desselben Kontinents liegen. Ohne Weltkoordinaten nur auf derselben Karte, dann ohne Entfernung.
-- Texture:SetRotation dreht gegen den Uhrzeigersinn. In Instanzen (oder bei geheimen Werten) gibt es keine Position.
--   MapDirection.PlayerMap() -> uiMapID oder nil
--   MapDirection.Toward(uiMapID, x, y) -> Drehung (Bogenmaß, 0 = geradeaus), Entfernung in Yards (nil = unbekannt)
--   MapDirection.CreateArrow({ name, label, offsetY, direction() -> Drehung, Entfernung }) -> Rahmen (versteckt);
--     solange er sichtbar ist, folgt er direction() gedrosselt; frame.Update() sofort
local _, ns = ...

local MapDirection = {}
ns.MapDirection = MapDirection

local ARROW_TEXTURE = "Interface\\Minimap\\MinimapArrow"
local ARROW_SIZE = 56
local UPDATE_SECONDS = 0.1

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function xy(vector)
  if type(vector) ~= "table" or ns.IsSecret(vector) or not vector.GetXY then return nil end
  local x, y = vector:GetXY()
  x, y = readable(x), readable(y)
  if type(x) ~= "number" or type(y) ~= "number" then return nil end
  return x, y
end
MapDirection.XY = xy

function MapDirection.PlayerMap()
  if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
  local mapID = readable(C_Map.GetBestMapForUnit("player"))
  return type(mapID) == "number" and mapID or nil
end

-- Ost- und Südabstand in Yards (Weltkoordinaten) oder in Kartenanteilen ohne Entfernung (nur gleiche Karte)
local function offset(fromMap, fx, fy, toMap, tx, ty)
  local fromInstance, fromNorth, fromWest = ns.MapCoords.MapToWorld(fromMap, fx, fy)
  local toInstance, toNorth, toWest = ns.MapCoords.MapToWorld(toMap, tx, ty)
  if fromInstance and fromInstance == toInstance then
    local east, south = fromWest - toWest, fromNorth - toNorth
    return east, south, math.sqrt(east * east + south * south)
  end
  if fromMap == toMap then return tx - fx, ty - fy, nil end
  return nil
end

function MapDirection.Toward(mapID, x, y)
  local playerMap = MapDirection.PlayerMap()
  if not playerMap or type(mapID) ~= "number" then return nil end
  local px, py = xy(C_Map.GetPlayerMapPosition(playerMap, "player"))
  local facing = GetPlayerFacing and readable(GetPlayerFacing())
  if not (px and type(facing) == "number") then return nil end
  local east, south, distance = offset(playerMap, px, py, mapID, x, y)
  if not east then return nil end
  local bearing = math.atan2(-east, -south)  -- gegen den Uhrzeigersinn ab Norden
  return bearing - facing, distance
end

local function update(frame)
  local rotation, distance = frame.direction()
  frame.arrow:SetShown(rotation ~= nil)
  if rotation then frame.arrow:SetRotation(rotation) end
  ns.Widgets.SetTextIfChanged(frame.distance,
    (rotation and distance) and string.format(ns.L.CORPSE_DISTANCE, math.floor(distance + 0.5)) or "")
end

function MapDirection.CreateArrow(definition)
  local frame = CreateFrame("Frame", definition.name, UIParent)
  frame.direction = definition.direction
  frame:SetSize(ARROW_SIZE, ARROW_SIZE)
  frame:SetPoint("TOP", UIParent, "TOP", 0, definition.offsetY)
  frame.arrow = frame:CreateTexture(nil, "OVERLAY")
  frame.arrow:SetAllPoints()
  frame.arrow:SetTexture(ARROW_TEXTURE)
  frame.distance = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.distance:SetPoint("TOP", frame, "BOTTOM", 0, -2)
  frame:Hide()
  function frame.Update() update(frame) end
  local since = UPDATE_SECONDS
  ns.SetUpdateScript(frame, definition.label, function(_, elapsed)
    since = since + elapsed
    if since < UPDATE_SECONDS then return end
    since = 0
    ns.SafeCall(update, frame)
  end)
  return frame
end
