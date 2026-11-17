-- LT-339: Level-Up vor dem XP-Update des letzten Kills: die XP darf nicht beim nächsten Kill landen
local Stats = addon.Stats

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end
local function kills() return Stats.Get(Stats.LEVEL, Stats.PVE_KILLS) end
local function killXp() return Stats.Get(Stats.LEVEL, Stats.XP_KILLS) end

wow.login({ level = 10, xp = 900, xpMax = 1000 })
wow.state.inCombat = true

-- Meldung, dann Level-Up, dann erst das XP-Update (übliche Client-Reihenfolge): Rest des alten Levels + 120
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", wow.SECRET)
wow.levelUp(11, 1500)
gainXp(120)
wow.advance(0.5)
wow.runTimers()
expect("Kill gezählt", kills(), 1)
expect("XP gehört zum Kill", killXp(), 220)

-- Der nächste Kill bekommt nicht noch einmal die alte XP
wow.advance(5)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", wow.SECRET)
gainXp(30)
wow.runTimers()
expect("zweiter Kill", kills(), 2)
expect("nur eigene XP", killXp(), 250)
