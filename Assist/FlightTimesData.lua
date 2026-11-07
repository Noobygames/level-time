-- Generiert von tools/flights (make flights) aus Flugzeiten, die die Entwickler selbst gemessen haben
-- (SavedVariables LevelTimerStatsDB), Stand 2026-11-07. Nicht von Hand ändern.
-- ns.FlightTimesData[flavor][map] = { routes = { ["vonKey>nachKey"] = Sekunden (Median) },
--   factor = { offset, perUnit, samples } }   (Schlüssel wie Assist/FlightMap.lua: nodeID oder "x,y")
-- ns.FlightTimesData[flavor].names = { ["Start > Ziel"] = Sekunden }   (alte Messungen nach Namen)
local _, ns = ...

ns.FlightTimesData = {
  ["forever"] = {
    names = {
      ["Crossroads, Brachland > Camp Taurajo, Brachland"] = 91,
      ["Das Grabmal, Silberwald > Tarrens Mühle, Hillsbrad"] = 75,
      ["Ratchet, Brachland > Crossroads, Brachland"] = 70,
      ["Ratchet, Brachland > Sonnenfels, Steinkrallengebirge"] = 219,
      ["Ratchet, Brachland > Thunder Bluff, Mulgore"] = 251,
      ["Tarrens Mühle, Hillsbrad > Undercity, Tirisfal"] = 140,
      ["Undercity, Tirisfal > Tarrens Mühle, Hillsbrad"] = 141,
    },
  },
}
