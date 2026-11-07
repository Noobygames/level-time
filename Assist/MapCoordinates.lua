-- Kartenkoordinaten (Roadmap 269, Einstellung mapCoordinates, Standard aus): unten auf der Weltkarte die Position des
-- Spielers und des Mauszeigers in Prozent der angezeigten Karte ("Spieler 45.2, 63.1 | Maus 12.3, 40.0").
-- Quellen (Gethe/wow-ui-source, alle vier Zweige):
--   C_Map.GetPlayerMapPosition(uiMapID, "player") -> Vector2DMixin oder nil (in Instanzen und auf fremden Karten),
--   C_Map.GetBestMapForUnit("player") als Ersatz, wenn die Karte keine ID meldet (MapDocumentation).
--   WorldMapFrame ist ein MapCanvas: GetMapID(), GetNormalizedCursorPosition() (Blizzard_MapCanvas.lua),
--   ScrollContainer:IsMouseOver() für "Maus über der Karte". Blizzard_WorldMap ist nicht Load-on-Demand; zur Sicherheit
--   wird auch bei ADDON_LOADED eingehängt.
-- Nur Lesen, eigener Kind-Frame mit eigener Schrift; aktualisiert im eigenen OnUpdate, solange die Karte offen ist.
local _, ns = ...
local L = ns.L

local MapCoordinates = {}
ns.MapCoordinates = MapCoordinates

local UPDATE_SECONDS = 0.1
local PERCENT = 100
local BOTTOM_OFFSET = 4

local display  -- eigener Frame auf der Weltkarte

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function formatPoint(x, y)
  x, y = readable(x), readable(y)
  if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return L.MAP_COORDS_NONE end
  return string.format("%.1f, %.1f", x * PERCENT, y * PERCENT)
end

-- Position des Spielers auf der Karte (angezeigte Karte, sonst die beste für den Spieler)
function MapCoordinates.PlayerText(mapID)
  if not (C_Map and C_Map.GetPlayerMapPosition) then return L.MAP_COORDS_NONE end
  mapID = readable(mapID) or (C_Map.GetBestMapForUnit and readable(C_Map.GetBestMapForUnit("player")))
  if type(mapID) ~= "number" then return L.MAP_COORDS_NONE end
  local position = C_Map.GetPlayerMapPosition(mapID, "player")
  if not position or ns.IsSecret(position) then return L.MAP_COORDS_NONE end
  return formatPoint(position:GetXY())
end

-- Mauszeiger auf der Karte (0..1) oder nil außerhalb
function MapCoordinates.CursorText(map)
  local container = map.ScrollContainer
  if not (container and container:IsMouseOver()) or not map.GetNormalizedCursorPosition then return L.MAP_COORDS_NONE end
  local x, y = map:GetNormalizedCursorPosition()
  x, y = readable(x), readable(y)
  if type(x) ~= "number" or type(y) ~= "number" or x < 0 or x > 1 or y < 0 or y > 1 then return L.MAP_COORDS_NONE end
  return formatPoint(x, y)
end

function MapCoordinates.Text(map)
  local mapID = map.GetMapID and map:GetMapID()
  return string.format(L.MAP_COORDS, MapCoordinates.PlayerText(mapID), MapCoordinates.CursorText(map))
end

local function create()
  local map = WorldMapFrame
  if display or type(map) ~= "table" or not map.CreateFontString then return end
  display = CreateFrame("Frame", "LevelTimerMapCoordinates", map)
  display:SetSize(1, 1)
  display:SetFrameLevel((map:GetFrameLevel() or 1) + 20)
  display.text = display:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  display.text:SetPoint("BOTTOM", map.ScrollContainer or map, "BOTTOM", 0, BOTTOM_OFFSET)
  local elapsedSince = UPDATE_SECONDS
  display:SetScript("OnUpdate", function(_, elapsed)
    elapsedSince = elapsedSince + elapsed
    if elapsedSince < UPDATE_SECONDS then return end
    elapsedSince = 0
    ns.SafeCall(function() display.text:SetText(MapCoordinates.Text(map)) end)
  end)
  display:SetShown(ns.db and ns.db.mapCoordinates or false)
  ns.Debug("mapcoords", "attached to WorldMapFrame")
end

ns.OnLogin(create)
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == "Blizzard_WorldMap" then create() end
end)
ns.RegisterApply(function(db)
  if display then display:SetShown(db.mapCoordinates) end
end)
