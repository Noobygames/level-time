-- Punkte auf der Minimap (Dungeonquest-Geber LT-37, gelernte Questorte LT-258): Kandidaten mit Weltkoordinaten
-- erscheinen nach Entfernung zum Spieler, unabhängig von der Zone (über Zonengrenzen hinweg). Kandidaten = alle Punkte
-- auf demselben Kontinent (Weltkoordinaten über Lib/MapCoords.lua), neu gesammelt bei geändertem Datenstand oder
-- anderem Kontinent. Außerhalb des Minimap-Radius bis EDGE_YARDS: kleineres, blasses Symbol am Rand in Richtung des
-- Punkts. Gedrosselt über ns.Every, kein eigenes OnUpdate.
-- Quellen: Minimap:GetZoom() (alle Clients), IsIndoors() (alle Clients), CVar rotateMinimap, GetPlayerFacing()
-- (Bogenmaß, 0 = Norden, gegen den Uhrzeigersinn; kann geheim sein), GetMinimapShape() (von Addons gesetzt, sonst rund;
-- Assist/MinimapTweaks.lua). Minimap-Durchmesser je Zoomstufe in Yards wie HereBeDragons-Pins (außen/innen).
-- OpenMap und Leatrix Maps verändern die echte Minimap nicht (Lib/MapCompat.lua).
-- MinimapPins.Create({ size, enabled(db), edge(db), key() -> Datenstand, candidates(instanceID) -> { { north, west,
-- size (optional), ... } }, newPin(parent, size), show(pin, candidate) }) -> { Update(), Reset() }.
local _, ns = ...

local MinimapPins = {}
ns.MinimapPins = MinimapPins

local OUTDOOR_DIAMETER = { 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }  -- [Zoom + 1] = Yards
local INDOOR_DIAMETER = { 300, 240, 180, 120, 80, 50 }
local UPDATE_SECONDS = 0.2
local EDGE_SCALE = 10 / 14
local EDGE_ALPHA = 0.6
local EDGE_YARDS = 800
local LEVEL_ABOVE_MINIMAP = 5
local SQUARE = "SQUARE"
local ROTATE_CVAR = "rotateMinimap"

local function readable(value)
  return type(value) == "number" and not ns.IsSecret(value)
end

-- Spieler in Weltkoordinaten: Instanz, Nord, West oder nil (in Instanzen keine Kartenposition)
function MinimapPins.PlayerWorld()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local mapID = C_Map.GetBestMapForUnit("player")
  if not readable(mapID) then return nil end
  local position = C_Map.GetPlayerMapPosition(mapID, "player")
  if type(position) ~= "table" or not position.GetXY then return nil end
  return ns.MapCoords.MapToWorld(mapID, position:GetXY())
end

-- Kandidaten aus Kartenpunkten { x, y, ... } mehrerer Karten: nur Punkte auf dem Kontinent instanceID, mit north/west
function MinimapPins.Collect(instanceID, mapIDs, pointsOn)
  local list = {}
  for _, uiMapID in ipairs(mapIDs) do
    for _, point in ipairs(pointsOn(uiMapID)) do
      local placeInstance, north, west = ns.MapCoords.MapToWorld(uiMapID, point.x, point.y)
      if placeInstance == instanceID then
        table.insert(list, setmetatable({ north = north, west = west }, { __index = point }))
      end
    end
  end
  return list
end

-- Sichtradius der Minimap in Yards
function MinimapPins.Radius()
  local zoom = Minimap:GetZoom() or 0
  local diameters = IsIndoors and IsIndoors() and INDOOR_DIAMETER or OUTDOOR_DIAMETER
  return (diameters[zoom + 1] or diameters[1]) / 2
end

local function rotation()
  if ns.CVars.Get(ROTATE_CVAR) ~= "1" or not GetPlayerFacing then return 0 end
  local facing = GetPlayerFacing()
  return readable(facing) and facing or 0
end

-- Versatz auf der Minimap (Osten, Norden in Yards, nach Drehung) und ob er am Rand festgehalten wurde; nil = nicht zeigen
function MinimapPins.Offset(east, north, radius, facing, square, edge)
  if facing ~= 0 then
    local cos, sin = math.cos(facing), math.sin(facing)
    -- getrennt berechnet: gopher-lua (Tests) wertet Mehrfachzuweisungen nicht wie Lua 5.1 aus
    local rotatedEast = east * cos + north * sin
    north = north * cos - east * sin
    east = rotatedEast
  end
  local reach = square and math.max(math.abs(east), math.abs(north)) or math.sqrt(east * east + north * north)
  if reach <= radius then return east, north, false end
  if not edge or reach > EDGE_YARDS then return nil end
  local factor = radius / reach
  return east * factor, north * factor, true
end

function MinimapPins.Create(definition)
  local layer = {}
  local pins = {}
  local candidates = {}
  local candidateKey

  local function isEnabled(db)
    return db and Minimap ~= nil and definition.enabled(db)
  end

  local function getPin(index)
    if pins[index] then return pins[index] end
    local pin = definition.newPin(Minimap, definition.size)
    pin:SetFrameLevel((Minimap:GetFrameLevel() or 1) + LEVEL_ABOVE_MINIMAP)
    pin:EnableMouse(true)
    pins[index] = pin
    return pin
  end

  local function hideFrom(index)
    for i = index, #pins do pins[i]:Hide() end
  end

  function layer.Update()
    local db = ns.db
    if not isEnabled(db) then return hideFrom(1) end
    local instanceID, north, west = MinimapPins.PlayerWorld()
    if not instanceID then return hideFrom(1) end
    local key = instanceID .. ":" .. tostring(definition.key())
    if key ~= candidateKey then
      candidateKey = key
      candidates = definition.candidates(instanceID)
    end
    local radius = MinimapPins.Radius()
    local pixels = (Minimap:GetWidth() or 0) / 2 / radius
    local facing = rotation()
    local square = GetMinimapShape and GetMinimapShape() == SQUARE
    local edge = definition.edge(db)
    local shown = 0
    for _, candidate in ipairs(candidates) do
      -- Weltachsen: Nord = x, West = y; Bildschirm: rechts = Osten
      local east, up, atEdge = MinimapPins.Offset(west - candidate.west, candidate.north - north, radius, facing,
        square, edge)
      if east then
        shown = shown + 1
        local pin = getPin(shown)
        local size = candidate.size or definition.size
        if atEdge then size = size * EDGE_SCALE end
        pin:SetSize(size, size)
        pin:SetAlpha(atEdge and EDGE_ALPHA or 1)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER", east * pixels, up * pixels)
        definition.show(pin, candidate)
      end
    end
    hideFrom(shown + 1)
  end

  function layer.Reset()
    candidateKey = nil
    layer.Update()
  end

  ns.Every(UPDATE_SECONDS, layer.Update, definition.enabled)
  ns.OnLogin(layer.Reset)
  ns.RegisterApply(layer.Reset)
  return layer
end
