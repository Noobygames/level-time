-- Prognose bis Max-Level: mit XP-Tabelle des Clients (Classic Era, WoW Forever, TBC) aus den
-- benötigten XP und der XP/h der letzten Level; ohne passende Tabelle aus den Level-Zeiten.
local Forecast = addon.Forecast
local XpTable = addon.XpTable

wow.state.interface = 11509  -- Classic Era
wow.login({ level = 57, xp = 0, xpMax = 195000, maxLevel = 60, playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 50000, 0)

expect("Classic: Level 57-59", XpTable.XpBetween(57, 60), 195000 + 202300 + 209800)

-- Level 57 in 1 h, Level 58 nach 30 min halb fertig
wow.state.xp = 195000
wow.fire("PLAYER_XP_UPDATE", "player")
wow.advance(3600)
wow.levelUp(58, 202300)
wow.advance(1800)
wow.state.xp = 101150
wow.fire("PLAYER_XP_UPDATE", "player")

-- Rest Level 58: 101150 XP bei 202300 XP/h = 30 min.
-- Level 59: 209800 XP bei der XP/h aus Level 57 und 58 zusammen: (195000 + 101150) XP in 5400 s
local recentRate = (195000 + 101150) / 5400 * 3600
expectNear("Prognose mit XP-Tabelle", Forecast.SecondsToMaxLevel(), 1800 + 209800 / recentRate * 3600, 1)
expectNear("Ziel nächstes Level = Zeit bis Level-Up", Forecast.SecondsToLevel(59), 1800, 1)

-- WoW Forever nutzt dieselben Werte wie Classic (vor TBC)
wow.state.interface = 16001
expect("Forever: Classic-Werte", XpTable.XpBetween(58, 60), 202300 + 209800)

-- Burning Crusade: Werte ab Patch 2.3 (Level 58 = 165800)
wow.state.interface = 20506
expect("TBC: Tabelle passt nicht zu Classic-Werten", XpTable.XpBetween(58, 60), nil)
wow.state.xpMax = 165800
expect("TBC: Level 58-69", XpTable.XpBetween(58, 70),
  165800 + 172000 + 494000 + 574700 + 614400 + 650300 + 682300 + 710200 + 734100 + 753700 + 768900 + 779700)

-- Retail oder Werte, die nicht zu UnitXPMax passen: Durchschnitt der Level-Zeiten (1 h je Level)
wow.state.interface = 120105
wow.state.xpMax = 202300
expect("Retail: keine Tabelle", XpTable.XpBetween(58, 60), nil)
expectNear("Prognose aus Level-Zeiten", Forecast.SecondsToMaxLevel(), 1800 + 3600, 1)
