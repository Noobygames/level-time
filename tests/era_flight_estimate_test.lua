-- Classic Era: C_TaxiMap liefert hier (vermutlich) keine Knoten, Schlüssel sind dann die gerundeten Positionen;
-- Daten liegen unter dem Flavor classic_era. Tooltip über Blizzards TaxiFrame.
local L = addon.L
local FlightTimer, FlightTimes = addon.FlightTimer, addon.FlightTimes

local function openMap(current)
  wow.state.taxiNodes = {
    { name = "Crossroads, Brachland", x = 0.55735743045807, y = 0.53047657012939 },
    { name = "Camp Taurajo, Brachland", x = 0.52804720401764, y = 0.61013436317444 },
  }
  wow.state.taxiNodes[current].type = "CURRENT"
  wow.state.taxiNodes[3 - current].type = "REACHABLE"
  wow.state.taxiMapID = 1411
  wow.fire("TAXIMAP_OPENED", 1)
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)
expect("Flavor", addon.Client.Flavor(), "classic_era")

openMap(1)
TakeTaxiNode(2)
wow.state.onTaxi = true
wow.advance(91)
wow.update(1)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")

local store = LevelTimerStatsDB.flights.classic_era["1411"]
expect("Schlüssel aus Positionen", store.routes["0.557,0.530>0.528,0.610"].seconds, 91)

openMap(2)
local reverse = FlightTimer.Lookup(1)
expect("Gegenrichtung", reverse.source, FlightTimes.REVERSE)
TaxiNodeOnButtonEnter({ GetID = function() return 1 end })
expect("Tooltip", GameTooltip._lines[2], string.format(L.FLIGHT_TOOLTIP_ESTIMATE, "1:31"))
expect("keine Fehler", #wow.errors, 0)
