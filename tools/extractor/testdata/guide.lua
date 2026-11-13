local _, ns = ...
if ns.Client.Flavor() ~= "forever" then return end
ns.InstanceGuide = {
  levels = { [33] = { 20, 30 } },
  entrances = {
    [33] = { { 1421, 0.448, 0.678 }, },
    [34] = { { 1453, 0.524, 0.7 }, },
  },
  bossLevels = { [222] = 26 },
  quests = {
    [33] = {
      { 1806, 22, 20, "A", "PALADIN", "The Test of Righteousness", 1426, 0.526, 0.368 },
      { 1098, 25, 18, "H", nil, "Deathstalkers in Shadowfang" },
    },
  },
}
