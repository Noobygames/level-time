-- Flugstrecken aus den Spieldaten (Assist/FlightPathsData/<flavor>.lua, generiert von tools/flights aus den
-- DB2-Tabellen TaxiPath und TaxiPathNode): Länge jeder direkten Strecke in Yards und Halte in Sekunden, dazu die aus
-- Messungen gelernte Fluggeschwindigkeit des Flavors. Eine Flugroute über Zwischenhalte ist die Summe ihrer direkten
-- Strecken; welche Zwischenhalte der Flug nimmt, sagt der Client (Assist/FlightMap.lua, TaxiGetNodeSlot).
-- Dauer = Halte + Länge / Geschwindigkeit (Assist/FlightTimes.lua). Nur mit nodeID-Schlüsseln; Positions-Schlüssel
-- finden keine Strecke.
local _, ns = ...

local FlightPaths = {}
ns.FlightPaths = FlightPaths

local function data()
  return ns.FlightPathsData
end

-- Länge (Yards) und Halte (Sekunden) entlang der Knoten-Schlüssel { Start, Zwischenhalte..., Ziel };
-- nil, sobald eine Teilstrecke in den Daten fehlt
function FlightPaths.Measure(keys)
  local paths = data()
  if not (paths and paths.legs and keys and #keys >= 2) then return nil end
  local length, stops = 0, 0
  for index = 2, #keys do
    local legKey = ns.FlightMap.RouteKey(keys[index - 1], keys[index])
    local leg = paths.legs[legKey]
    if not leg then return nil end
    length = length + leg
    stops = stops + (paths.stops and paths.stops[legKey] or 0)
  end
  return length, stops
end

-- Mitgelieferte Geschwindigkeit in Yards je Sekunde und ob sie von einem anderen Flavor geliehen ist (nil ohne)
function FlightPaths.ShippedSpeed()
  local paths = data()
  local speed = paths and paths.speed
  if not (speed and speed.yardsPerSecond) then return nil end
  return speed.yardsPerSecond, speed.borrowedFrom ~= nil
end
