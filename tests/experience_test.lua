-- XP pro Stunde, Zeit bis Level-Up, XP-Quellen und Erholungs-XP.
local Stats = addon.Stats
local Experience = addon.Experience

wow.login({ xp = 0, xpMax = 1000, rested = 500, playedSeconds = 30 })
expect("Rate unter 60 s noch nicht aussagekräftig", Experience.GetRatePerHour(Stats.LEVEL), nil)

-- Kill mit 100 XP, davon 50 Erholungsbonus: der Pool sinkt um Grund- plus Bonus-XP
wow.state.xp, wow.state.rested = 100, 400
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung. (+50 Erholt-Bonus)")
wow.fire("PLAYER_XP_UPDATE", "player")
expect("Erholungs-XP aus Pool-Abnahme", Stats.Get(Stats.LEVEL, Stats.XP_RESTED), 50)

-- Quest mit 200 XP, dann 100 XP Entdecken
wow.state.xp = 300
wow.fire("QUEST_TURNED_IN", 1, 200, 0)
wow.state.xp = 400
wow.fire("PLAYER_XP_UPDATE", "player")

wow.state.rested = 600  -- Ausruhen füllt den Pool: kein verbrauchter Bonus
wow.fire("UPDATE_EXHAUSTION")
expect("Pool-Zunahme zählt nicht", Stats.Get(Stats.LEVEL, Stats.XP_RESTED), 50)

local sources = Experience.GetSources(Stats.LEVEL)
expect("XP aus Kills", sources.kills, 100)
expect("XP aus Quests", sources.quests, 200)
expect("sonstige XP", sources.other, 100)
expect("XP gesamt", sources.total, 400)

-- 400 XP in 30 min = 800 XP/h, 600 XP fehlen = 45 min
wow.advance(1770)
expectNear("XP pro Stunde", Experience.GetRatePerHour(Stats.LEVEL), 800)
expectNear("Zeit bis Level-Up", Experience.GetSecondsToLevel(Stats.LEVEL), 2700)

expectTrue("levelt", Experience.IsLeveling())
wow.state.level = 60
addon.level = 60
expect("Max-Level: levelt nicht", Experience.IsLeveling(), false)

-- Levelcap der Erweiterung (Retail): Blizzards wirksames Max-Level zählt
GameRulesUtil = { IsPlayerAtEffectiveMaxLevel = function() return true end }
expect("am Levelcap kein Leveln", Experience.IsLeveling(), false)
GameRulesUtil = nil
