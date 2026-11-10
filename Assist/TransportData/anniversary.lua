-- Generiert von tools/flights (make flights) aus den Spieldaten (DB2 TaxiPathNode von wago.tools, Build
-- 2.5.6.70577), Stand 2026-11-10. Nicht von Hand ändern.
-- ns.TransportData = { build, paths = { [TaxiPath-ID] = { { continent, x, y, wait, next }, ... } } }:
-- Halte eines Schiffs- oder Zeppelin-Rundkurses mit Weltposition (Yards), Liegezeit (Sekunden) und Yards bis zum
-- nächsten Halt. Rechnung in Assist/TransportPaths.lua.
local _, ns = ...
if ns.Client.Flavor() ~= "anniversary" then return end

ns.TransportData = {
  build = "2.5.6.70577",
  paths = {
    [241] = {
      { continent = 1, x = -1006, y = -3842, wait = 60, next = 1025 },
      { continent = 0, x = -14278, y = 583, wait = 60, next = 1261 },
    },
    [285] = {
      { continent = 0, x = -12464, y = 232, wait = 60, next = 1574 },
      { continent = 1, x = 1361, y = -4631, wait = 60, next = 1353 },
    },
    [292] = {
      { continent = 0, x = -3905, y = -586, wait = 60, next = 1354 },
      { continent = 1, x = -4016, y = -4741, wait = 60, next = 1209 },
    },
    [293] = {
      { continent = 1, x = 8534, y = 1018, wait = 60, next = 2278 },
      { continent = 1, x = 6595, y = 770, wait = 60, next = 2271 },
    },
    [295] = {
      { continent = 0, x = -3709, y = -575, wait = 60, next = 1259 },
      { continent = 1, x = 6406, y = 823, wait = 60, next = 1159 },
    },
    [301] = {
      { continent = 0, x = -12407, y = 212, wait = 60, next = 2727 },
      { continent = 0, x = 2063, y = 235, wait = 60, next = 16009 },
    },
    [302] = {
      { continent = 1, x = 1318, y = -4658, wait = 60, next = 1590 },
      { continent = 0, x = 2062, y = 293, wait = 60, next = 1117 },
    },
    [303] = {
      { continent = 1, x = -4197, y = 3287, wait = 30, next = 899 },
      { continent = 1, x = -4348, y = 2444, wait = 60, next = 3188 },
      { continent = 1, x = -4197, y = 3287, wait = 30, next = 800 },
    },
    [503] = {
      { continent = 530, x = -4265, y = -11317, wait = 60, next = 1208 },
      { continent = 1, x = 6550, y = 938, wait = 60, next = 1357 },
    },
    [777] = {
      { continent = 1, x = -4352, y = 2441, wait = 30, next = 3275 },
      { continent = 1, x = -4200, y = 3281, wait = 30, next = 1530 },
    },
  },
}
