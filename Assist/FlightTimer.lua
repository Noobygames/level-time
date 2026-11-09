-- Flugzeiten (Einstellung flightTimer): misst jeden Flug selbst und zeigt beim Abflug die Restzeit
-- (UI/FlightDisplay.lua) plus eine Chatzeile. Woher die Zeit kommt, entscheidet Assist/FlightTimes.lua: eigene
-- Messung, mitgelieferte Messung, Gegenrichtung oder Schätzung aus der Strecke (dann mit "~" und leiser Farbe).
-- Ganz ohne Anhaltspunkt wird die Strecke gemessen ("hint").
-- Ablauf wie Blizzards TaxiFrame (alle Clients; im Spiel geprüft in WoW Forever 1.60.1, Debug-Log):
--   TAXIMAP_OPENED   Karte lesen (Assist/FlightMap.lua): Start = Knoten vom Typ CURRENT, Positionen, nodeIDs
--   TakeTaxiNode(i)  Ziel = Slot i (hooksecurefunc, kein Eingriff in den Flug), Strecke über die Teilstrecken
--   Landung          PLAYER_CONTROL_GAINED, sobald UnitOnTaxi("player") false ist
-- Ein /reload im Flug verliert die Messung.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    flightTimer = false,
    flightSound = false,
  },
})
local L = ns.L

local FlightTimer = {}
ns.FlightTimer = FlightTimer

local MIN_FLIGHT_SECONDS = 5       -- kürzere "Flüge" (abgebrochen) werden nicht gemerkt
local LANDING_CHECK_SECONDS = 1    -- wie oft im Flug geprüft wird, ob man gelandet ist

local map          -- Momentaufnahme der offenen Flugkarte (FlightMap.Read)
local flight       -- { fromName, toName, map, fromKey, toKey, distance, hops, startedAt, known } während des Flugs

-- Letzte gemessene Dauer einer Strecke nach Namen (alter Schlüssel) oder nil
function FlightTimer.Get(from, to)
  if not from or not to then return nil end
  return (LevelTimerStatsDB.flightTimes or {})[ns.FlightTimes.LegacyKey(from, to)]
end

-- Ziel-Slot der offenen Karte als Abfrage für FlightTimes.Lookup (nil ohne Karte oder Startknoten)
local function queryFor(slot)
  if not map or not map.current then return nil end
  local from, to = map.nodes[map.current], map.nodes[slot]
  if not from or not to then return nil end
  local distance, hops = ns.FlightMap.Distance(map, map.current, slot)
  return { map = map.map, fromKey = from.key, toKey = to.key, fromName = from.name, toName = to.name,
    distance = distance, hops = hops }
end

-- Bekannte oder geschätzte Dauer zum Slot der offenen Karte: { seconds, source, estimated, origin } oder nil
function FlightTimer.Lookup(slot)
  local query = queryFor(slot)
  return query and ns.FlightTimes.Lookup(query)
end

local function onMapOpened()
  map = ns.FlightMap.Read()
  if not map then return end
  ns.FlightTimes.Learn(map, function(fromSlot, toSlot) return ns.FlightMap.Distance(map, fromSlot, toSlot) end)
  ns.Debug("flight", "taxi map %s opened at %s", map.map, map.current and map.nodes[map.current].name)
end

local function show()
  if not ns.db.flightTimer or not flight then return end
  local known = flight.known
  if known then
    local remaining = known.seconds - (GetTime() - flight.startedAt)
    ns.FlightDisplay.Show({ kind = "countdown", spellId = ns.FlightDisplay.ICON, title = flight.toName,
      remaining = math.max(0, remaining), duration = known.seconds, estimated = known.estimated })
  else
    ns.FlightDisplay.Show({ kind = "hint", spellId = ns.FlightDisplay.ICON, title = flight.toName })
  end
end

local function announce()
  local known = flight.known
  if not known then
    ns.Print(string.format(L.FLIGHT_STARTED_UNKNOWN, flight.toName))
  elseif known.estimated then
    ns.Print(string.format(L.FLIGHT_STARTED_ESTIMATE, flight.toName, ns.Format.Duration(known.seconds)))
  else
    ns.Print(string.format(L.FLIGHT_STARTED, flight.toName, ns.Format.Duration(known.seconds)))
  end
end

local function onTakeoff(slot)
  local query = queryFor(slot)
  if not query then return end
  flight = query
  flight.startedAt = GetTime()
  flight.known = ns.FlightTimes.Lookup(query)
  ns.Debug("flight", "takeoff %s (%s > %s) on map %s, distance %s, hops %s, source %s, seconds %s, origin %s",
    ns.FlightMap.RouteKey(tostring(query.fromKey), tostring(query.toKey)), query.fromName, query.toName, query.map,
    query.distance, query.hops, flight.known and flight.known.source, flight.known and flight.known.seconds,
    flight.known and flight.known.origin)
  if ns.db.flightTimer then announce() end
  show()
end

local function onLanded()
  if not flight or UnitOnTaxi("player") then return end
  local seconds = GetTime() - flight.startedAt
  local landed = flight
  flight = nil
  -- Noch nicht abgeflogen (Kontrolle kurz zurück vor dem Start): nichts messen
  if seconds < MIN_FLIGHT_SECONDS then
    ns.FlightDisplay.Show(nil)
    return
  end
  ns.FlightTimes.Record(landed, math.floor(seconds + 0.5))
  ns.Debug("flight", "landed %s > %s after %s s (expected %s, %s)", landed.fromName, landed.toName, seconds,
    landed.known and landed.known.seconds, landed.known and landed.known.source)
  if ns.db.flightTimer then ns.FlightDisplay.ShowDone(ns.FlightDisplay.ICON, landed.toName) end
end

ns.RegisterEvent("TAXIMAP_OPENED", onMapOpened)
ns.RegisterEvent("PLAYER_CONTROL_GAINED", onLanded)
if hooksecurefunc and TakeTaxiNode then hooksecurefunc("TakeTaxiNode", onTakeoff) end

-- Restzeit nachführen und verpasste Landung erkennen (z.B. Kontrolle schon vorher zurück)
ns.Every(LANDING_CHECK_SECONDS, function()
  if not flight then return end
  if GetTime() - flight.startedAt >= MIN_FLIGHT_SECONDS and not UnitOnTaxi("player") then
    onLanded()
    return
  end
  show()
end)

ns.OnLogin(function()
  map, flight = nil, nil
end)
