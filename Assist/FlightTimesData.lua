-- Generiert von tools/flights (make flights) aus Flugzeiten, die die Entwickler selbst gemessen haben
-- (SavedVariables LevelTimerStatsDB), Stand 2026-11-10. Nicht von Hand ändern.
-- ns.FlightTimesData[flavor][map] = { routes = { ["vonKey>nachKey"] = Sekunden (Median) },
--   factor = { offset, perUnit, samples } }   (Schlüssel wie Assist/FlightMap.lua: nodeID oder "x,y")
local _, ns = ...

ns.FlightTimesData = {
  ["forever"] = {
    ["1463"] = {
      routes = {
        ["10>13"] = 75,
        ["10>17"] = 145,
        ["11>10"] = 107,
        ["11>13"] = 141,
        ["11>17"] = 301,
        ["13>11"] = 140,
        ["13>17"] = 119,
      },
      factor = { offset = 10, perUnit = 1264.225, samples = 7 },
    },
    ["1464"] = {
      routes = {
        ["22>23"] = 208,
        ["22>30"] = 204.5,
        ["22>40"] = 291,
        ["22>61"] = 297,
        ["22>77"] = 88,
        ["22>80"] = 217.5,
        ["23>22"] = 225.5,
        ["23>25"] = 111,
        ["23>29"] = 261,
        ["23>30"] = 295,
        ["23>80"] = 162,
        ["25>23"] = 143,
        ["25>77"] = 91,
        ["25>80"] = 53,
        ["29>25"] = 150,
        ["30>29"] = 344,
        ["40>30"] = 88,
        ["55>80"] = 214,
        ["58>22"] = 411,
        ["61>22"] = 322,
        ["80>22"] = 251,
        ["80>23"] = 210.5,
        ["80>25"] = 70,
        ["80>29"] = 219,
        ["80>30"] = 253,
        ["80>40"] = 345,
      },
      factor = { offset = 15.906, perUnit = 977.539, samples = 26 },
    },
  },
}
