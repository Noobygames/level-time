-- Flugzeiten aus den Flugstrecken der Spieldaten (Assist/FlightPaths.lua): Länge / Geschwindigkeit + Halte, Summe
-- über Zwischenhalte, geliehene Geschwindigkeit als Schätzung, eigene Geschwindigkeit nach dem ersten Flug,
-- Messungen gehen vor
local L = addon.L
local FlightTimer, FlightTimes = addon.FlightTimer, addon.FlightTimes

addon.FlightTimesData = { retail = { ["1411"] = { routes = { ["23>25"] = 111 } } } }
addon.FlightPathsData = {
  speed = { yardsPerSecond = 30, samples = 5 },
  legs = { ["25>77"] = 2700, ["77>23"] = 6000, ["23>25"] = 3300, ["25>80"] = 1500 },
  stops = { ["77>23"] = 5 },
}

-- Crossroads (25), Camp Taurajo (77), Orgrimmar (23), Ratchet (80), Splintertree (61, ohne Strecke)
local function openMap(current, hops)
  local nodes = {
    { name = "Crossroads, Brachland", x = 0.557, y = 0.530, id = 25 },
    { name = "Camp Taurajo, Brachland", x = 0.528, y = 0.610, id = 77 },
    { name = "Orgrimmar, Durotar", x = 0.628, y = 0.443, id = 23 },
    { name = "Ratchet, Brachland", x = 0.606, y = 0.549, id = 80 },
    { name = "Splintertree, Eschental", x = 0.600, y = 0.300, id = 61 },
  }
  for slot, node in ipairs(nodes) do
    node.type = slot == current and "CURRENT" or "REACHABLE"
    node.hops = hops and hops[slot]
  end
  wow.state.taxiNodes, wow.state.taxiMapID = nodes, 1411
  wow.fire("TAXIMAP_OPENED", 1)
end

local function hover(slot)
  TaxiNodeOnButtonEnter({ GetID = function() return slot end })
  return GameTooltip._lines[2]
end

local function fly(slot, seconds)
  TakeTaxiNode(slot)
  wow.state.onTaxi = true
  wow.advance(seconds)
  wow.update(1)
  wow.state.onTaxi = false
  wow.fire("PLAYER_CONTROL_GAINED")
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)

-- Direkte Strecke: 2700 Yards / 30 = 90 s, wie mitgelieferte Daten angezeigt
openMap(1)
local direct = FlightTimer.Lookup(2)
expect("Flugroute", direct.source, FlightTimes.PATH)
expectNear("Flugroute: Zeit", direct.seconds, 90, 0.001)
expect("Flugroute: ohne ~", direct.estimated, false)
expect("Flugroute: mitgelieferte Geschwindigkeit", direct.origin, FlightTimes.DATA)
expect("Tooltip: Level-Time-Daten", hover(2), string.format(L.FLIGHT_TOOLTIP_DATA, "1:30"))

-- Über einen Zwischenhalt (Camp Taurajo): (2700 + 6000) / 30 + 5 s Halt
openMap(1, { [3] = { { 1, 2 }, { 2, 3 } } })
expectNear("Zwischenhalt: Summe der Strecken", FlightTimer.Lookup(3).seconds, 295, 0.001)

-- Mitgelieferte Messung geht vor; fehlende Teilstrecke = keine Flugroute
openMap(3)
expect("Messung vor Flugroute", FlightTimer.Lookup(1).source, FlightTimes.DATA)
openMap(1)
expectTrue("ohne Strecke keine Flugroute", FlightTimer.Lookup(5) == nil
  or FlightTimer.Lookup(5).source ~= FlightTimes.PATH)

-- Geliehene Geschwindigkeit (anderer Flavor): Zeit mit ~
addon.FlightPathsData.speed.borrowedFrom = "forever"
openMap(1)
local borrowed = FlightTimer.Lookup(2)
expect("geliehen: Flugroute", borrowed.source, FlightTimes.PATH)
expect("geliehen: Schätzung", borrowed.estimated, true)

-- Ohne Geschwindigkeit keine Flugroute (Retail vor dem ersten Flug)
addon.FlightPathsData.speed = nil
openMap(1)
expect("ohne Geschwindigkeit nichts", FlightTimer.Lookup(2), nil)

-- Erster eigener Flug lernt die Geschwindigkeit: 1500 Yards in 60 s = 25 Yards/s
openMap(1)
fly(4, 60)
local route = LevelTimerStatsDB.flights.retail["1411"].routes["25>80"]
expect("Flugroute gemerkt", route.pathLength, 1500)
expectNear("eigene Geschwindigkeit", FlightTimes.OwnSpeed(), 25, 0.001)
openMap(1)
local own = FlightTimer.Lookup(2)
expect("eigene Geschwindigkeit: Flugroute", own.source, FlightTimes.PATH)
expect("eigene Geschwindigkeit: Herkunft", own.origin, FlightTimes.MEASURED)
expectNear("eigene Geschwindigkeit: Zeit", own.seconds, 108, 0.001)
expect("eigene Geschwindigkeit: ohne ~", own.estimated, false)
expect("gemessene Strecke selbst", FlightTimer.Lookup(4).source, FlightTimes.MEASURED)
expect("keine Fehler", #wow.errors, 0)
