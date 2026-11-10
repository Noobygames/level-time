-- Mitgelieferte Flugzeiten (Assist/FlightTimesData.lua): nach der eigenen Messung, vor Gegenrichtung und Schätzung;
-- nur der eigene Flavor; Faktor der Karte, solange eigene Flüge fehlen
local L = addon.L
local FlightTimer, FlightTimes = addon.FlightTimer, addon.FlightTimes

addon.FlightTimesData = {
  retail = {
    ["1411"] = {
      routes = { ["25>77"] = 88, ["80>25"] = 66 },
      factor = { offset = 12, perUnit = 1000, samples = 4 },
    },
  },
  forever = { ["1411"] = { routes = { ["77>23"] = 999 } } },
}

local function openMap(current)
  local nodes = {
    { name = "Crossroads, Brachland", x = 0.55735743045807, y = 0.53047657012939, id = 25 },
    { name = "Camp Taurajo, Brachland", x = 0.52804720401764, y = 0.61013436317444, id = 77 },
    { name = "Orgrimmar, Durotar", x = 0.62800776958466, y = 0.44340223073959, id = 23 },
    { name = "Ratchet, Brachland", x = 0.6057111620903, y = 0.54907929897308, id = 80 },
  }
  for slot, node in ipairs(nodes) do node.type = slot == current and "CURRENT" or "REACHABLE" end
  wow.state.taxiNodes, wow.state.taxiMapID = nodes, 1411
  wow.fire("TAXIMAP_OPENED", 1)
end

local function hover(slot)
  TaxiNodeOnButtonEnter({ GetID = function() return slot end })
  return GameTooltip._lines[2]
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)

openMap(1)
local shipped = FlightTimer.Lookup(2)
expect("mitgeliefert", shipped.source, FlightTimes.DATA)
expect("mitgeliefert: Zeit", shipped.seconds, 88)
expect("mitgeliefert: ohne ~", shipped.estimated, false)
expect("Tooltip: Level-Time-Daten", hover(2), string.format(L.FLIGHT_TOOLTIP_DATA, "1:28"))

-- Gegenrichtung aus mitgelieferten Daten
openMap(2)
expect("Gegenrichtung mitgeliefert", FlightTimer.Lookup(1).source, FlightTimes.REVERSE)

-- Anderer Flavor zählt nicht; Schätzung mit dem mitgelieferten Faktor
openMap(2)
local estimate = FlightTimer.Lookup(3)
expect("forever-Daten nicht in Retail", estimate.source, FlightTimes.ESTIMATE)
expect("mitgelieferter Faktor", estimate.origin, FlightTimes.DATA)

-- Eigene Messung schlägt die mitgelieferte
openMap(1)
TakeTaxiNode(2)
wow.state.onTaxi = true
wow.advance(93)
wow.update(1)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")
openMap(1)
local own = FlightTimer.Lookup(2)
expect("eigene Messung zuerst", own.source, FlightTimes.MEASURED)
expect("eigene Zeit", own.seconds, 93)
expect("Tooltip: dein Flug", hover(2), string.format(L.FLIGHT_TOOLTIP_MEASURED, "1:33"))
expect("eigener Faktor jetzt", select(2, FlightTimes.Factor("1411")), FlightTimes.MEASURED)
expect("keine Fehler", #wow.errors, 0)
