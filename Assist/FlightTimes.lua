-- Flugzeiten als Daten: eigene Messungen, mitgelieferte Messungen (Assist/FlightTimesData.lua) und Schätzung.
-- Gespeichert account-weit, je Flavor und Flugkarte (Positionen sind je Karte normiert, nur Knoten derselben Karte
-- sind vergleichbar):
--   LevelTimerStatsDB.flights[flavor][map] = {
--     nodes  = { [nodeKey] = { x, y, name } },
--     routes = { ["vonKey>nachKey"] = { seconds, samples = { ... }, distance, hops, from, to } } }
--   nodeKey = nodeID aus C_TaxiMap, sonst gerundete Position "x,y" (Assist/FlightMap.lua). seconds = Median der
--   letzten SAMPLE_LIMIT Messungen. Namen nur zur Anzeige (Sprache des Clients).
-- Ältere Messungen stehen unter LevelTimerStatsDB.flightTimes["Start > Ziel"] (Namen, Sprache des Clients); sie
-- werden übernommen, sobald beide Knoten auf einer offenen Karte zu sehen sind, und bleiben lesbar.
-- Reihenfolge beim Nachschlagen: eigene Messung > mitgelieferte Messung > Gegenrichtung (eigene, dann mitgelieferte)
-- > Schätzung aus der Strecke (Faktor aus eigenen Flügen der Karte, sonst mitgelieferter Faktor).
-- Schätzung: Sekunden = Start/Landung (offset) + Sekunden je Karteneinheit (perUnit) × Strecke. Ab MIN_FIT_SAMPLES
-- Strecken per kleinster Quadrate, sonst offset = DEFAULT_OFFSET und perUnit = Median der Einzelwerte. Ohne
-- gemessenen Flug auf der Karte (eigen oder mitgeliefert) keine Schätzung. tools/flights rechnet genauso.
local _, ns = ...

local FlightTimes = {}
ns.FlightTimes = FlightTimes

FlightTimes.MEASURED, FlightTimes.DATA = "measured", "data"
FlightTimes.REVERSE, FlightTimes.ESTIMATE = "reverse", "estimate"

local SAMPLE_LIMIT = 5
local MIN_FIT_SAMPLES = 3
local DEFAULT_OFFSET = 10      -- Sekunden für Start und Landung, solange zu wenige Strecken für eine Gerade da sind
local MAX_OFFSET = 60          -- größere Achsenabschnitte sind Ausreißer; dann der einfache Faktor
local MIN_DISTANCE = 0.001     -- kürzere Strecken (gleicher Ort) taugen nicht für den Faktor
local LEGACY_SEPARATOR = " > "

local function legacyTimes()
  LevelTimerStatsDB.flightTimes = LevelTimerStatsDB.flightTimes or {}
  return LevelTimerStatsDB.flightTimes
end

function FlightTimes.LegacyKey(from, to)
  return from .. LEGACY_SEPARATOR .. to
end

local function flavorStore()
  LevelTimerStatsDB.flights = LevelTimerStatsDB.flights or {}
  local flavor = ns.Client.Flavor()
  LevelTimerStatsDB.flights[flavor] = LevelTimerStatsDB.flights[flavor] or {}
  return LevelTimerStatsDB.flights[flavor]
end

local function mapStore(map)
  local store = flavorStore()
  store[map] = store[map] or { nodes = {}, routes = {} }
  return store[map]
end

local function shippedMap(map)
  local data = ns.FlightTimesData and ns.FlightTimesData[ns.Client.Flavor()]
  return data and data[map]
end

local function shippedNames()
  local data = ns.FlightTimesData and ns.FlightTimesData[ns.Client.Flavor()]
  return data and data.names
end

---------------------------------------------------------------------------
-- Rechnen
---------------------------------------------------------------------------
local function median(values)
  if #values == 0 then return nil end
  local sorted = {}
  for i, value in ipairs(values) do sorted[i] = value end
  table.sort(sorted)
  local middle = math.floor(#sorted / 2)
  if #sorted % 2 == 1 then return sorted[middle + 1] end
  return (sorted[middle] + sorted[middle + 1]) / 2
end
FlightTimes.Median = median

-- Faktor aus Punkten { distance, seconds }: { offset, perUnit, samples } oder nil
function FlightTimes.Fit(points)
  local usable = {}
  for _, point in ipairs(points) do
    if point.distance and point.distance >= MIN_DISTANCE and point.seconds then usable[#usable + 1] = point end
  end
  local count = #usable
  if count == 0 then return nil end
  if count >= MIN_FIT_SAMPLES then
    local meanX, meanY = 0, 0
    for _, point in ipairs(usable) do meanX, meanY = meanX + point.distance, meanY + point.seconds end
    meanX, meanY = meanX / count, meanY / count
    local sxx, sxy = 0, 0
    for _, point in ipairs(usable) do
      local dx = point.distance - meanX
      sxx, sxy = sxx + dx * dx, sxy + dx * (point.seconds - meanY)
    end
    if sxx > 0 then
      local perUnit = sxy / sxx
      local offset = meanY - perUnit * meanX
      if perUnit > 0 and offset >= 0 and offset <= MAX_OFFSET then
        return { offset = offset, perUnit = perUnit, samples = count }
      end
    end
  end
  local ratios = {}
  for _, point in ipairs(usable) do
    if point.seconds > DEFAULT_OFFSET then
      ratios[#ratios + 1] = (point.seconds - DEFAULT_OFFSET) / point.distance
    end
  end
  local perUnit = median(ratios)
  if not perUnit then return nil end
  return { offset = DEFAULT_OFFSET, perUnit = perUnit, samples = count }
end

-- Eigener Faktor je Karte, zwischengespeichert bis zur nächsten Messung
local factorCache = {}

function FlightTimes.OwnFactor(map)
  local cached = factorCache[map]
  if cached ~= nil then return cached or nil end
  local points = {}
  for _, route in pairs(mapStore(map).routes) do
    points[#points + 1] = { distance = route.distance, seconds = route.seconds }
  end
  local factor = FlightTimes.Fit(points)
  factorCache[map] = factor or false
  return factor
end

function FlightTimes.Factor(map)
  local own = FlightTimes.OwnFactor(map)
  if own then return own, FlightTimes.MEASURED end
  local shipped = shippedMap(map)
  if shipped and shipped.factor then return shipped.factor, FlightTimes.DATA end
  return nil
end

---------------------------------------------------------------------------
-- Karte lernen, alte Messungen übernehmen
---------------------------------------------------------------------------
local function newRoute(seconds, distance, hops, from, to)
  return { seconds = seconds, samples = { seconds }, distance = distance, hops = hops, from = from, to = to }
end

-- Positionen der Knoten merken und alte Namens-Messungen dieser Karte in Strecken mit Knoten-Schlüsseln übernehmen.
-- distanceOf(fromSlot, toSlot) liefert die Flugstrecke (Assist/FlightMap.lua).
function FlightTimes.Learn(snapshot, distanceOf)
  local store = mapStore(snapshot.map)
  local byName = {}
  for _, node in pairs(snapshot.nodes) do
    if node.key then
      store.nodes[node.key] = { x = node.x, y = node.y, name = node.name }
      byName[node.name] = node
    end
  end
  local migrated = 0
  for key, seconds in pairs(legacyTimes()) do
    local fromName, toName = key:match("^(.-)" .. LEGACY_SEPARATOR .. "(.+)$")
    local from, to = byName[fromName or ""], byName[toName or ""]
    if from and to then
      local routeKey = ns.FlightMap.RouteKey(from.key, to.key)
      if not store.routes[routeKey] then
        local distance, hops = distanceOf(from.slot, to.slot)
        store.routes[routeKey] = newRoute(seconds, distance, hops, from.name, to.name)
        migrated = migrated + 1
      end
    end
  end
  if migrated > 0 then
    factorCache[snapshot.map] = nil
    ns.Debug("flight", "map %s: %s old routes moved to node keys", snapshot.map, migrated)
  end
end

-- Gelandet: Messung zur Strecke legen (Median der letzten Messungen) und den alten Namens-Schlüssel nachführen
function FlightTimes.Record(flight, seconds)
  legacyTimes()[FlightTimes.LegacyKey(flight.fromName, flight.toName)] = seconds
  if not (flight.map and flight.fromKey and flight.toKey) then return end
  local routes = mapStore(flight.map).routes
  local routeKey = ns.FlightMap.RouteKey(flight.fromKey, flight.toKey)
  local route = routes[routeKey]
  if route then
    table.insert(route.samples, seconds)
    while #route.samples > SAMPLE_LIMIT do table.remove(route.samples, 1) end
    route.seconds = median(route.samples)
    route.distance, route.hops = flight.distance or route.distance, flight.hops or route.hops
  else
    route = newRoute(seconds, flight.distance, flight.hops, flight.fromName, flight.toName)
    routes[routeKey] = route
  end
  factorCache[flight.map] = nil
  local factor = FlightTimes.OwnFactor(flight.map)
  ns.Debug("flight", "recorded %s on map %s: %s s (median %s, distance %s); factor offset %s, per unit %s, samples %s",
    routeKey, flight.map, seconds, route.seconds, flight.distance, factor and factor.offset,
    factor and factor.perUnit, factor and factor.samples)
end

---------------------------------------------------------------------------
-- Nachschlagen
---------------------------------------------------------------------------
-- Gemessene Dauer einer Richtung: eigene Strecke, sonst alter Namens-Schlüssel, sonst mitgeliefert
local function measured(map, fromKey, toKey, fromName, toName)
  local routeKey = fromKey and toKey and ns.FlightMap.RouteKey(fromKey, toKey)
  local own = routeKey and mapStore(map).routes[routeKey]
  if own then return own.seconds, FlightTimes.MEASURED end
  local legacy = legacyTimes()[FlightTimes.LegacyKey(fromName, toName)]
  if legacy then return legacy, FlightTimes.MEASURED end
  local shipped = shippedMap(map)
  local shippedSeconds = routeKey and shipped and shipped.routes and shipped.routes[routeKey]
  if shippedSeconds then return shippedSeconds, FlightTimes.DATA end
  local names = shippedNames()
  local named = names and names[FlightTimes.LegacyKey(fromName, toName)]
  if named then return named, FlightTimes.DATA end
  return nil
end

-- query = { map, fromKey, toKey, fromName, toName, distance }
-- Ergebnis: { seconds, source, estimated, origin } (origin: Herkunft der Zahl bei Gegenrichtung/Schätzung) oder nil
function FlightTimes.Lookup(query)
  local map = query.map or "0"
  local seconds, origin = measured(map, query.fromKey, query.toKey, query.fromName, query.toName)
  if seconds then return { seconds = seconds, source = origin, estimated = false, origin = origin } end
  seconds, origin = measured(map, query.toKey, query.fromKey, query.toName, query.fromName)
  if seconds then return { seconds = seconds, source = FlightTimes.REVERSE, estimated = true, origin = origin } end
  local factor, factorOrigin = FlightTimes.Factor(map)
  if factor and query.distance and query.distance >= MIN_DISTANCE then
    return { seconds = factor.offset + factor.perUnit * query.distance, source = FlightTimes.ESTIMATE,
      estimated = true, origin = factorOrigin }
  end
  return nil
end

-- Für die Debug-Prüfung: eigene Strecken und Faktoren je Karte
function FlightTimes.Summary()
  local maps = {}
  for map, store in pairs(flavorStore()) do
    local routes, count = {}, 0
    for key, route in pairs(store.routes) do
      count = count + 1
      routes[#routes + 1] = string.format("%s (%s > %s): %s s, %s samples, distance %s, hops %s", key,
        tostring(route.from), tostring(route.to), tostring(route.seconds), #(route.samples or {}),
        tostring(route.distance), tostring(route.hops))
    end
    table.sort(routes)
    local nodes = 0
    for _ in pairs(store.nodes) do nodes = nodes + 1 end
    local shipped = shippedMap(map)
    maps[map] = { routes = routes, routeCount = count, nodes = nodes, factor = FlightTimes.OwnFactor(map),
      shippedFactor = shipped and shipped.factor }
  end
  local legacy = {}
  for key, seconds in pairs(legacyTimes()) do legacy[#legacy + 1] = key .. " = " .. tostring(seconds) end
  table.sort(legacy)
  return { flavor = ns.Client.Flavor(), maps = maps, legacy = legacy }
end

ns.OnLogin(function()
  factorCache = {}
end)
