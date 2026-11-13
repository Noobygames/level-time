-- Leichenpfeil (Roadmap 351, Einstellung corpseArrow, aus): als Geist zeigt ein Pfeil oben in der Bildschirmmitte
-- die Richtung zur eigenen Leiche, darunter die Entfernung. Nur zwischen Freilassen und Wiederbeleben
-- (PLAYER_ALIVE/PLAYER_UNGHOST/PLAYER_DEAD/PLAYER_ENTERING_WORLD, UnitIsGhost("player")).
-- Quellen (DeathInfoDocumentation, MapDocumentation; Zweige classic_era, forever, live):
--   C_DeathInfo.GetCorpseMapPosition(uiMapID)  Leiche auf der Karte (Vector2D, nil auf anderen Karten)
--   C_Map.GetPlayerMapPosition(uiMapID, "player") Spieler auf derselben Karte
--   C_Map.GetWorldPosFromMapPos(uiMapID, pos)   Weltkoordinaten in Metern (Yards): daraus Breite und Höhe der Karte,
--                                               damit Richtung und Entfernung auch auf nicht quadratischen Karten stimmen
--   GetPlayerFacing()                           Blickrichtung im Bogenmaß, 0 = Norden, gegen den Uhrzeigersinn
-- Karten sind genordet: x nach Osten, y nach Süden. Texture:SetRotation dreht gegen den Uhrzeigersinn.
-- In Instanzen (oder bei geheimen Werten) gibt es keine Position: dann ist nichts zu sehen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    corpseArrow = false,
  },
})
local L = ns.L

local CorpseArrow = {}
ns.CorpseArrow = CorpseArrow

local ARROW_TEXTURE = "Interface\\Minimap\\MinimapArrow"
local ARROW_SIZE = 56
local UPDATE_SECONDS = 0.1
local DEFAULT_POSITION = { "TOP", "TOP", 0, -120 }

local frame
local mapSizes = {}  -- [uiMapID] = { width, height } in Metern

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

local function worldPoint(mapID, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local _, position = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
  return xy(position)
end

-- Breite (Ost-West) und Höhe (Nord-Süd) der Karte in Metern; nil, wenn der Client es nicht verrät
local function mapSize(mapID)
  if mapSizes[mapID] then return unpack(mapSizes[mapID]) end
  local ox, oy = worldPoint(mapID, 0, 0)
  local ex, ey = worldPoint(mapID, 1, 0)
  local sx, sy = worldPoint(mapID, 0, 1)
  if not (ox and ex and sx) then return nil end
  local width = math.sqrt((ex - ox) ^ 2 + (ey - oy) ^ 2)
  local height = math.sqrt((sx - ox) ^ 2 + (sy - oy) ^ 2)
  if width <= 0 or height <= 0 then return nil end
  mapSizes[mapID] = { width, height }
  return width, height
end
CorpseArrow.MapSize = mapSize

function CorpseArrow.IsGhost()
  return UnitIsGhost ~= nil and readable(UnitIsGhost("player")) == true
end

-- Drehung des Pfeils (Bogenmaß, gegen den Uhrzeigersinn, 0 = geradeaus) und Entfernung in Metern; nil = unbekannt
function CorpseArrow.Direction()
  if not (C_Map and C_Map.GetBestMapForUnit and C_DeathInfo and C_DeathInfo.GetCorpseMapPosition) then return nil end
  local mapID = readable(C_Map.GetBestMapForUnit("player"))
  if type(mapID) ~= "number" then return nil end
  local cx, cy = xy(C_DeathInfo.GetCorpseMapPosition(mapID))
  local px, py = xy(C_Map.GetPlayerMapPosition(mapID, "player"))
  local facing = GetPlayerFacing and readable(GetPlayerFacing())
  if not (cx and px and type(facing) == "number") then return nil end
  local width, height = mapSize(mapID)
  local east, south = (cx - px) * (width or 1), (cy - py) * (height or 1)
  local bearing = math.atan2(-east, -south)  -- gegen den Uhrzeigersinn ab Norden
  local distance = width and math.sqrt(east * east + south * south) or nil
  return bearing - facing, distance
end

local function update()
  local rotation, distance = CorpseArrow.Direction()
  frame.arrow:SetShown(rotation ~= nil)
  if rotation then frame.arrow:SetRotation(rotation) end
  ns.Widgets.SetTextIfChanged(frame.distance,
    distance and string.format(L.CORPSE_DISTANCE, math.floor(distance + 0.5)) or "")
end

local function create()
  frame = CreateFrame("Frame", ns.GlobalName("CorpseArrow"), UIParent)
  frame:SetSize(ARROW_SIZE, ARROW_SIZE)
  frame:SetPoint(DEFAULT_POSITION[1], UIParent, DEFAULT_POSITION[2], DEFAULT_POSITION[3], DEFAULT_POSITION[4])
  frame.arrow = frame:CreateTexture(nil, "OVERLAY")
  frame.arrow:SetAllPoints()
  frame.arrow:SetTexture(ARROW_TEXTURE)
  frame.distance = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.distance:SetPoint("TOP", frame, "BOTTOM", 0, -2)
  frame:Hide()
  local since = UPDATE_SECONDS
  ns.SetUpdateScript(frame, "CorpseArrow", function(_, elapsed)
    since = since + elapsed
    if since < UPDATE_SECONDS then return end
    since = 0
    ns.SafeCall(update)
  end)
end

function CorpseArrow.Refresh()
  local show = ns.db and ns.db.corpseArrow and CorpseArrow.IsGhost()
  if show and not frame then create() end
  if not frame then return end
  frame:SetShown(show and true or false)
  if show then update() end
end

for _, event in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_ENTERING_WORLD" }) do
  ns.RegisterEvent(event, CorpseArrow.Refresh)
end
ns.RegisterApply(CorpseArrow.Refresh)
