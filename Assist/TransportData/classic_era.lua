-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 TaxiPathNode von wago.tools, Build
-- 1.15.9.70576), Stand 2026-11-10. Nicht von Hand ändern.
-- ns.TransportData = { build, paths = { [TaxiPath-ID] = { { continent, x, y, wait, next }, ... } } }:
-- Halte eines Schiffs- oder Zeppelin-Rundkurses mit Weltposition (Yards), Liegezeit (Sekunden) und Yards bis zum
-- nächsten Halt. Rechnung in Assist/TransportPaths.lua.
local _, ns = ...
if ns.Client.Flavor() ~= "classic_era" then return end

ns.TransportData = {
  build = "1.15.9.70576",
  paths = {
    [241] = {
      { continent = 1, x = -1006, y = -3842, wait = 60, next = 2787 },
      { continent = 0, x = -14278, y = 583, wait = 60, next = 3045 },
    },
    [285] = {
      { continent = 0, x = -12464, y = 232, wait = 60, next = 2426 },
      { continent = 1, x = 1361, y = -4631, wait = 60, next = 1619 },
    },
    [292] = {
      { continent = 0, x = -3905, y = -586, wait = 60, next = 2441 },
      { continent = 1, x = -4016, y = -4741, wait = 60, next = 2536 },
    },
    [293] = {
      { continent = 1, x = 8534, y = 1025, wait = 60, next = 2228 },
      { continent = 1, x = 6594, y = 760, wait = 60, next = 2296 },
    },
    [295] = {
      { continent = 0, x = -3709, y = -575, wait = 60, next = 2154 },
      { continent = 1, x = 6406, y = 823, wait = 60, next = 1770 },
    },
    [301] = {
      { continent = 0, x = -12407, y = 212, wait = 60, next = 2727 },
      { continent = 0, x = 2063, y = 235, wait = 60, next = 16505 },
    },
    [302] = {
      { continent = 1, x = 1318, y = -4658, wait = 60, next = 3300 },
      { continent = 0, x = 2062, y = 293, wait = 60, next = 2389 },
    },
    [303] = {
      { continent = 1, x = -4197, y = 3287, wait = 30, next = 899 },
      { continent = 1, x = -4348, y = 2444, wait = 60, next = 3188 },
      { continent = 1, x = -4197, y = 3287, wait = 30, next = 800 },
    },
  },
}
