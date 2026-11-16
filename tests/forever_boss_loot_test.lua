-- LT-57: Boss-Beute in Forever: Drops nur aus Classic-Daten (viertes Feld) bekommen ein Sternchen in Tooltip-Zeile und
-- Symbolzeile, der Tooltip eine Hinweiszeile; bestätigte Drops bleiben unmarkiert
local BossLoot = addon.BossLoot
local L = addon.L

expectTrue("Beutedaten in Forever", BossLoot.IsAvailable())
-- echte Daten: Rhahk'Zor mit Classic-Hammer und Forever-Items
local hammer = false
for _, drop in ipairs(addon.DungeonDB.loot[644] or {}) do hammer = hammer or drop[1] == 5187 end
expectTrue("Rhahk'Zors Hammer in der Dungeon-DB", hammer)
-- Classic-Beute und Forever-Items stehen bei Bossen mit Forever-Items nebeneinander (LT-54)
local classic, forever = 0, 0
for _, drop in ipairs(addon.DungeonDB.loot[644]) do
  if drop[1] >= 250000 then forever = forever + 1 else classic = classic + 1 end
end
expectTrue("Rhahk'Zor: Classic-Drops (Hammer, Felsspalter)", classic >= 2)
expectTrue("Rhahk'Zor: Forever-Items", forever > 0)

-- LT-60: Versunkene Stadt (2970): jeder Boss mit Beute und Level, Urtümlicher Elementar mit NPC-ID
local DB = addon.DungeonDB
for _, bossNpc in ipairs({ 258905, 258924, 260042, 270885, 270887, 260274 }) do
  expectTrue("Beute Versunkene Stadt " .. bossNpc, #(DB.loot[bossNpc] or {}) >= 3)
  expectTrue("Bosslevel Versunkene Stadt " .. bossNpc, DB.npcs[2970][bossNpc][1] > 0)
end
expect("NPC-ID Urtümlicher Elementar", addon.BossNpcs[3511], 270887)
expect("Level Min'loth", DB.npcs[2970][260274][1], 40)

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.itemLinks = { [100] = "[Classic]", [101] = "[Forever]" }
wow.state.itemIcons = { [100] = 1, [101] = 2 }
addon.DungeonDB.loot[990002] = { { 100, 3, nil, 1 }, { 101, 3 } }
local drops = BossLoot.Items(990002)

GameTooltip:ClearLines()
expectTrue("Zeilen", BossLoot.AddLines(GameTooltip, drops))
local lines = GameTooltip._lines
expectTrue("Classic-Drop mit Sternchen", lines[2]:find("[Classic] ", 1, true) == 1 and lines[2]:find("*", 1, true) ~= nil)
expect("bestätigter Drop ohne Sternchen", lines[3], "[Forever]")
expect("Hinweiszeile", lines[4], L.FOREVER_UNVERIFIED)

local icons = BossLoot.IconLinks(drops, 16) or ""
local _, marks = icons:gsub("%*", "")
expect("ein Sternchen in der Symbolzeile", marks, 1)

-- nur bestätigte Drops: kein Hinweis
addon.DungeonDB.loot[990003] = { { 101, 3 } }
GameTooltip:ClearLines()
BossLoot.AddLines(GameTooltip, BossLoot.Items(990003))
expect("ohne Hinweis", #GameTooltip._lines, 2)
expect("keine Lua-Fehler", #wow.errors, 0)
