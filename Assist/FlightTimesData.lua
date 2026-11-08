-- Generiert von tools/flights (make flights) aus Flugzeiten, die die Entwickler selbst gemessen haben
-- (SavedVariables LevelTimerStatsDB), Stand 2026-11-08. Nicht von Hand ändern.
-- ns.FlightTimesData[flavor][map] = { routes = { ["vonKey>nachKey"] = Sekunden (Median) },
--   factor = { offset, perUnit, samples } }   (Schlüssel wie Assist/FlightMap.lua: nodeID oder "x,y")
-- ns.FlightTimesData[flavor].names = { ["Start > Ziel"] = Sekunden }   (alte Messungen nach Namen)
local _, ns = ...

ns.FlightTimesData = {
  ["forever"] = {
    ["1463"] = {
      routes = {
        ["10>13"] = 75,
        ["10>17"] = 145,
        ["11>10"] = 107,
        ["11>13"] = 141,
        ["13>11"] = 140,
        ["13>17"] = 119,
      },
      factor = { offset = 10, perUnit = 1057.649, samples = 6 },
    },
    ["1464"] = {
      routes = {
        ["22>77"] = 88,
        ["23>29"] = 261,
        ["25>77"] = 91,
        ["29>25"] = 150,
        ["55>80"] = 214,
        ["58>22"] = 411,
        ["80>22"] = 251,
        ["80>23"] = 211,
        ["80>25"] = 70,
        ["80>29"] = 219,
      },
      factor = { offset = 3.428, perUnit = 1141.203, samples = 10 },
    },
    names = {
      ["Brackenwall, Marschen von Dustwallow > Ratchet, Brachland"] = 214,
      ["Crossroads, Brachland > Camp Taurajo, Brachland"] = 91,
      ["Das Grabmal, Silberwald > Hammerfall, Arathi"] = 145,
      ["Das Grabmal, Silberwald > Tarrens Mühle, Hillsbrad"] = 75,
      ["Orgrimmar, Durotar > Sonnenfels, Steinkrallengebirge"] = 261,
      ["Ratchet, Brachland > Crossroads, Brachland"] = 70,
      ["Ratchet, Brachland > Orgrimmar, Durotar"] = 211,
      ["Ratchet, Brachland > Sonnenfels, Steinkrallengebirge"] = 219,
      ["Ratchet, Brachland > Thunder Bluff, Mulgore"] = 251,
      ["Sonnenfels, Steinkrallengebirge > Crossroads, Brachland"] = 150,
      ["Tarrens Mühle, Hillsbrad > Hammerfall, Arathi"] = 119,
      ["Tarrens Mühle, Hillsbrad > Undercity, Tirisfal"] = 140,
      ["Thunder Bluff, Mulgore > Camp Taurajo, Brachland"] = 88,
      ["Undercity, Tirisfal > Das Grabmal, Silberwald"] = 107,
      ["Undercity, Tirisfal > Tarrens Mühle, Hillsbrad"] = 141,
      ["Zoram'gar-Außenposten, Ashenvale > Thunder Bluff, Mulgore"] = 411,
    },
  },
}
