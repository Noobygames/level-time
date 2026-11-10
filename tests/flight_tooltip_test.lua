-- Flugzeit im Tooltip der Flugkarte (TaxiFrame): gemessen, geschätzt, aus und nur bei erreichbaren Zielen
local L = addon.L
-- Ohne Flugstrecken aus den Spieldaten (eigenes Szenario flight_paths), sonst gewinnt die Flugroute
addon.FlightPathsData = nil

local NODES = {
  { name = "Crossroads, Brachland", x = 0.55735743045807, y = 0.53047657012939, id = 25 },
  { name = "Camp Taurajo, Brachland", x = 0.52804720401764, y = 0.61013436317444, id = 77 },
  { name = "Orgrimmar, Durotar", x = 0.62800776958466, y = 0.44340223073959, id = 23 },
}

local function openMap(current)
  local list = {}
  for slot, node in ipairs(NODES) do
    list[slot] = { name = node.name, x = node.x, y = node.y, id = node.id,
      type = slot == current and "CURRENT" or "REACHABLE" }
  end
  wow.state.taxiNodes, wow.state.taxiMapID = list, 1411
  wow.fire("TAXIMAP_OPENED", 1)
end

-- Maus auf den Knopf eines Ziels: Blizzards Funktion, danach unser Hook
local function hover(slot)
  TaxiNodeOnButtonEnter({ GetID = function() return slot end })
  return GameTooltip._lines
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)
expect("Standard an", addon.db.flightTimeTooltip, true)

openMap(1)
expect("ohne Messung nur der Name", #hover(2), 1)

TakeTaxiNode(2)
wow.state.onTaxi = true
wow.advance(91)
wow.update(1)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")

openMap(1)
local lines = hover(2)
expect("Name zuerst", lines[1], "Camp Taurajo, Brachland")
expect("gemessen", lines[2], string.format(L.FLIGHT_TOOLTIP_MEASURED, "1:31"))
expectTrue("geschätzt mit ~", hover(3)[2]:find("~", 1, true) ~= nil)
expect("Startknoten ohne Zeile", #hover(1), 1)

openMap(2)
expect("Gegenrichtung geschätzt", hover(1)[2], string.format(L.FLIGHT_TOOLTIP_ESTIMATE, "1:31"))

addon.Set("flightTimeTooltip", false)
expect("Tooltip aus", #hover(1), 1)
addon.Set("flightTimeTooltip", true)
addon.Set("flightTimer", false)
expect("Flugzeiten aus", #hover(1), 1)
expect("keine Fehler", #wow.errors, 0)
