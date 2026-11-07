-- Generiert von tools/flights (make flights) aus Flugzeiten, die die Entwickler selbst gemessen haben
-- (SavedVariables LevelTimerStatsDB), Stand 2026-11-07. Nicht von Hand ändern.
-- ns.FlightTimesData[flavor][map] = { routes = { ["vonKey>nachKey"] = Sekunden (Median) },
--   factor = { offset, perUnit, samples } }   (Schlüssel wie Assist/FlightMap.lua: nodeID oder "x,y")
-- ns.FlightTimesData[flavor].names = { ["Start > Ziel"] = Sekunden }   (alte Messungen nach Namen)
local _, ns = ...

ns.FlightTimesData = {
}
