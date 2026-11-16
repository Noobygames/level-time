local _, ns = ...
if ns.Client.Flavor() ~= "forever" then return end
ns.InstanceGuide = {
  levels = { [33] = { 20, 30 } },
  entrances = {
    [33] = { { 1421, 0.448, 0.678 }, },
    [34] = { { 1453, 0.524, 0.7 }, },
  },
  bossLevels = { [222] = 26 },
}
