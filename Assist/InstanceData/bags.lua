-- Taschen-Daten ns.BagData (nur WoW Forever und Classic Era): Quests mit Taschen-Belohnung und Gegner, die eine Tasche
-- fallen lassen. Von Hand gepflegt (Herkunft: sources.md, Abschnitt 4); Stand 2026-11-16.
-- ns.BagData = {
--   quests = { [questID] = { item = itemID, slots = Plätze, name = Taschenname (enUS, Rückfall ohne Client-Name),
--              minLevel, faction = "A"/"H" (nil = beide), forever = true (nur WoW Forever: Era kennt Quest/Item nicht),
--              pre = { alle diese Vorquests }, preAny = { eine davon },
--              givers = { { kind = "npc"/"object", id, uiMapID, x, y (0-1) }, ... } } },
--   mobs   = { [npcID] = { item, slots, name } } }
-- Offen: Red Bag (Quest 84146, 16 Plätze) fehlt, die Questdaten kennen sie nicht.
local _, ns = ...
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

local quests = {
  [1003] = { item = 2082, slots = 8, name = "Wizbang's Gunnysack", minLevel = 7, faction = "A", pre = { 1002 },
    givers = { { kind = "object", id = 17184, uiMapID = 1439, x = 0.513, y = 0.246 } } },
  [151] = { item = 1537, slots = 8, name = "Old Blanchy's Feed Pouch", minLevel = 9, faction = "A",
    givers = { { kind = "npc", id = 238, uiMapID = 1436, x = 0.599, y = 0.194 } } },
  [97253] = { item = 277332, slots = 8, name = "Scuffed Shipping Crate", minLevel = 9, forever = true,
    givers = { { kind = "npc", id = 7161, uiMapID = 1413, x = 0.631, y = 0.363 } } },
  [140] = { item = 3343, slots = 8, name = "Captain Sander's Booty Bag", minLevel = 10, pre = { 139 },
    givers = { { kind = "object", id = 34, uiMapID = 1436, x = 0.406, y = 0.170 } } },
  [1486] = { item = 918, slots = 10, name = "Deviate Hide Pack", minLevel = 13,
    givers = { { kind = "npc", id = 5767, uiMapID = 1413, x = 0.460, y = 0.357 } } },
  [531] = { item = 270017, slots = 10, name = "Hunting Satchel", minLevel = 15, faction = "A", pre = { 271 },
    forever = true, givers = { { kind = "npc", id = 1187, uiMapID = 1432, x = 0.835, y = 0.655 } } },
  [58] = { item = 1729, slots = 10, name = "Gunnysack of the Night Watch", minLevel = 18, faction = "A", pre = { 57 },
    givers = { { kind = "npc", id = 264, uiMapID = 1431, x = 0.735, y = 0.468 } } },
  [470] = { item = 3352, slots = 10, name = "Ooze-covered Bag", minLevel = 19, faction = "A",
    givers = { { kind = "npc", id = 2111, uiMapID = 1437, x = 0.118, y = 0.580 } } },
  [96260] = { item = 276891, slots = 12, name = "Spidersilk Pouch", minLevel = 23, faction = "H", forever = true,
    givers = { { kind = "npc", id = 264072, uiMapID = 1412, x = 0.325, y = 0.200 } } },
  [79192] = { item = 221498, slots = 12, name = "Old Toolbox", minLevel = 14, preAny = { 79007, 79008 }, forever = true,
    givers = {
      { kind = "object", id = 417072, uiMapID = 1413, x = 0.464, y = 0.738 },
      { kind = "object", id = 424010, uiMapID = 1436, x = 0.374, y = 0.508 },
    } },
  [626] = { item = 11324, slots = 14, name = "Explorer's Knapsack", minLevel = 35, pre = { 625 },
    givers = { { kind = "object", id = 2555, uiMapID = 1445, x = 0.311, y = 0.661 } } },
  [2439] = { item = 9587, slots = 14, name = "Thawpelt Sack", minLevel = 40, faction = "A", pre = { 2279 },
    givers = { { kind = "npc", id = 5387, uiMapID = 1455, x = 0.699, y = 0.186 } } },
  [2440] = { item = 9587, slots = 14, name = "Thawpelt Sack", minLevel = 40, faction = "H", pre = { 2280 },
    givers = { { kind = "npc", id = 3978, uiMapID = 1456, x = 0.344, y = 0.469 } } },
  [3628] = { item = 10959, slots = 16, name = "Demon Hide Sack", minLevel = 45, pre = { 3627 },
    givers = { { kind = "npc", id = 7572, uiMapID = 1435, x = 0.343, y = 0.661 } } },
  [93269] = { item = 260307, slots = 18, name = "Hyjal Postal Satchel", minLevel = 56, pre = { 93406 }, forever = true,
    givers = { { kind = "npc", id = 11118, uiMapID = 1452, x = 0.614, y = 0.388 } } },
}

local mobs = {
  [472] = { item = 3233, slots = 8, name = "Gnoll Hide Sack" },          -- Fedfennel, Elwynn
  [3864] = { item = 932, slots = 10, name = "Fel Steed Saddlebags" },    -- Fel Steed, Burg Schattenfang
  [573] = { item = 933, slots = 10, name = "Large Rucksack" },           -- Foe Reaper 4000, Westfall
  [6243] = { item = 1470, slots = 10, name = "Murloc Skin Bag" },        -- Gelihast, Tiefschwarze Grotte
  [3671] = { item = 6446, slots = 10, name = "Snakeskin Bag" },          -- Lady Anacondra, Höhlen des Wehklagens
  [675] = { item = 1652, slots = 12, name = "Sturdy Lunchbox" },         -- Venture Co. Foreman, Schlingendorntal
  [9543] = { item = 11742, slots = 16, name = "Wayfarer's Knapsack" },   -- Ribbly Screwspigot, Schwarzfels-Tiefen
}

-- Classic Era kennt die Forever-eigenen Quests und Items nicht
if flavor == "classic_era" then
  for questID, quest in pairs(quests) do
    if quest.forever then quests[questID] = nil end
  end
end

ns.BagData = { quests = quests, mobs = mobs }
