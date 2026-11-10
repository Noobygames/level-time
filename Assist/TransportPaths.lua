-- Schiffs- und Zeppelin-Rundkurse aus den Spieldaten (Roadmap 459; Assist/TransportData/<flavor>.lua, generiert von
-- tools/flights aus TaxiPathNode): Halte mit Weltposition, Liegezeit (in Era/TBC/Forever 60 s) und Yards bis zum
-- nächsten Halt. Damit wird aus einer gelernten Strecke (Assist/TransportTimes.lua) ein ganzer Fahrplan:
--   Zuordnung  gelernter Anleger (Karte, x, y) -> Weltposition über Lib/MapCoords.lua (Client-API, sonst erzeugte
--              Kartenbereiche) -> Halt innerhalb MATCH_YARDS; eine Strecke gehört zu dem Rundkurs,
--              der Start- und Zielanleger als Halte hat. Die Achsen der Weltposition werden in beiden Reihenfolgen
--              geprüft (ungeprüft, welche der Client liefert; Debug-Check 440.transport.state zeigt den Treffer).
--   Tempo      liegt beim Server, steht nicht in den Daten: Yards je Sekunde aus jeder Strecke mit gelernter Periode
--              (Rundkurs-Yards / (Periode - Liegezeiten)), Median über alle Strecken des Realms.
--   Ergebnis   Periode jeder zugeordneten Strecke, Fahrzeit Start -> Ziel und Liegezeit am Ziel (für die Phase der
--              Gegenrichtung). Ohne Daten, Zuordnung oder Tempo: nil, dann bleibt es beim Lernen.
local _, ns = ...

local TransportPaths = {}
ns.TransportPaths = TransportPaths

TransportPaths.MATCH_YARDS = 150   -- Abstand Stehplatz an Deck <-> Haltepunkt des Pfads

local worldCache = setmetatable({}, { __mode = "k" })   -- Anleger-Tabelle -> { continent, x, y } oder false

local function paths()
  return ns.TransportData and ns.TransportData.paths
end

-- Weltposition eines gelernten Anlegers { mapID, x, y } oder nil
local function worldOf(dock)
  local cached = worldCache[dock]
  if cached ~= nil and cached.x0 == dock.x and cached.y0 == dock.y then return cached.world or nil end
  local world = false
  local continent, x, y = ns.MapCoords.MapToWorld(dock.mapID, dock.x, dock.y)
  if continent then world = { continent = continent, x = x, y = y } end
  worldCache[dock] = { x0 = dock.x, y0 = dock.y, world = world }
  return world or nil
end

local function nearStop(world, stop)
  if stop.continent ~= world.continent then return false end
  local limit = TransportPaths.MATCH_YARDS ^ 2
  return (stop.x - world.x) ^ 2 + (stop.y - world.y) ^ 2 <= limit
    or (stop.x - world.y) ^ 2 + (stop.y - world.x) ^ 2 <= limit
end

-- Rundkurs einer Strecke: { id, stops, from = Index, to = Index } oder nil
function TransportPaths.Match(route)
  local all, docks = paths(), ns.Transports.Data().docks
  local fromDock, toDock = docks[route.from], docks[route.to]
  if not (all and fromDock and toDock) then return nil end
  local fromWorld, toWorld = worldOf(fromDock), worldOf(toDock)
  if not (fromWorld and toWorld) then return nil end
  for id, stops in pairs(all) do
    local fromIndex, toIndex
    for index, stop in ipairs(stops) do
      if not fromIndex and nearStop(fromWorld, stop) then fromIndex = index
      elseif not toIndex and nearStop(toWorld, stop) then toIndex = index end
    end
    if fromIndex and toIndex then return { id = id, stops = stops, from = fromIndex, to = toIndex } end
  end
  return nil
end

-- Yards und Liegezeiten des ganzen Rundkurses
local function loop(stops)
  local yards, waits = 0, 0
  for _, stop in ipairs(stops) do yards, waits = yards + stop.next, waits + stop.wait end
  return yards, waits
end

-- Yards von Halt a bis Halt b und die Liegezeiten der Halte dazwischen
local function between(stops, a, b)
  local yards, waits, index = 0, 0, a
  repeat
    yards = yards + stops[index].next
    index = index % #stops + 1
    if index ~= b then waits = waits + stops[index].wait end
  until index == b
  return yards, waits
end

local function median(values)
  if #values == 0 then return nil end
  table.sort(values)
  local middle = (#values + 1) / 2
  return (values[math.floor(middle)] + values[math.ceil(middle)]) / 2
end

-- Tempo (Yards je Sekunde) aus allen Strecken mit gelernter Periode oder nil
function TransportPaths.Speed()
  local speeds = {}
  for _, route in pairs(ns.Transports.Data().routes) do
    local match = route.period and TransportPaths.Match(route)
    if match then
      local yards, waits = loop(match.stops)
      if route.period > waits then speeds[#speeds + 1] = yards / (route.period - waits) end
    end
  end
  return median(speeds)
end

-- Periode der Strecke aus Rundkurs und Tempo (Sekunden) oder nil
function TransportPaths.Period(route)
  local match, speed = TransportPaths.Match(route), TransportPaths.Speed()
  if not (match and speed) then return nil end
  local yards, waits = loop(match.stops)
  return waits + yards / speed
end

-- Fahrzeit von der Abfahrt am Start bis zur Ankunft am Ziel (Sekunden) oder nil
function TransportPaths.Travel(route)
  local match, speed = TransportPaths.Match(route), TransportPaths.Speed()
  if not (match and speed) then return nil end
  local yards, waits = between(match.stops, match.from, match.to)
  return waits + yards / speed
end

-- Liegezeit am Ziel der Strecke (Sekunden) oder nil
function TransportPaths.WaitAtDestination(route)
  local match = TransportPaths.Match(route)
  return match and match.stops[match.to].wait or nil
end

-- Für den Debug-Check: je Strecke Rundkurs, Halte-Indizes und die Weltpositionen der Anleger
function TransportPaths.Summary()
  local routes, docks = {}, {}
  for key, route in pairs(ns.Transports.Data().routes) do
    local match = TransportPaths.Match(route)
    routes[key] = match and { path = match.id, from = match.from, to = match.to,
      period = TransportPaths.Period(route), travel = TransportPaths.Travel(route) } or false
  end
  for name, dock in pairs(ns.Transports.Data().docks) do docks[name] = worldOf(dock) or false end
  return { build = ns.TransportData and ns.TransportData.build, speed = TransportPaths.Speed(), routes = routes,
    docks = docks, worldApi = type(C_Map and C_Map.GetWorldPosFromMapPos) }
end
