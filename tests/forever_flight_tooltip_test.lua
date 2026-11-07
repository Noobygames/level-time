-- WoW Forever: nodeIDs aus C_TaxiMap, Tooltip auch auf Blizzards FlightMap (lädt bei Bedarf, Pins aus dem Mixin)
local L = addon.L

wow.login({ level = 20 })
addon.Set("flightTimer", true)
expect("Flavor", addon.Client.Flavor(), "forever")

-- Blizzard_FlightMap lädt erst später: Hook kommt mit ADDON_LOADED
FlightMap_FlightPointPinMixin = {
  OnMouseEnter = function(pin)
    GameTooltip:SetOwner(pin, "ANCHOR_PRESERVE")
    GameTooltip:AddLine(pin.taxiNodeData.name)
  end,
}
wow.fire("ADDON_LOADED", "Blizzard_FlightMap")

local function openMap(current)
  wow.state.taxiNodes = {
    { name = "Ratchet, Brachland", x = 0.6057111620903, y = 0.54907929897308, id = 80 },
    { name = "Crossroads, Brachland", x = 0.55735743045807, y = 0.53047657012939, id = 25 },
  }
  wow.state.taxiNodes[current].type = "CURRENT"
  wow.state.taxiNodes[3 - current].type = "REACHABLE"
  wow.state.taxiMapID = 1411
  wow.fire("TAXIMAP_OPENED", 1)
end

openMap(1)
TakeTaxiNode(2)
wow.state.onTaxi = true
wow.advance(70)
wow.update(1)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")
expect("nodeIDs", LevelTimerStatsDB.flights.forever["1411"].routes["80>25"].seconds, 70)

openMap(1)
FlightMap_FlightPointPinMixin.OnMouseEnter({ taxiNodeData = { slotIndex = 2, name = "Crossroads, Brachland" } })
expect("FlightMap-Tooltip", GameTooltip._lines[2], string.format(L.FLIGHT_TOOLTIP_MEASURED, "1:10"))
expect("keine Fehler", #wow.errors, 0)
