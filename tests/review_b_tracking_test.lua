-- Review B: Mehrfach-Level-Up mit XP vor PLAYER_LEVEL_UP, Erholungs-Pool ohne XP-Gewinn, Bank-Umlagerungen,
-- Einzelreparatur, Todesursache aus altem Recap, Tod vor /played, wirksames Max-Level.
local Stats = addon.Stats

wow.login({ level = 5, xp = 2700, xpMax = 2800, playedSeconds = 0, money = 100000 })

-- 1) Ein Gewinn über zwei Level, XP-Update vor den PLAYER_LEVEL_UP
wow.state.xp, wow.state.xpMax = 1300, 4500
wow.fire("PLAYER_XP_UPDATE", "player")
wow.fire("PLAYER_LEVEL_UP", 6)
wow.fire("PLAYER_LEVEL_UP", 7)
wow.state.level = 7
local booked = Stats.Get(Stats.SESSION, Stats.XP_GAINED)
wow.state.xp = 1400
wow.fire("PLAYER_XP_UPDATE", "player")
expect("nächster Kill zählt nur seine XP", Stats.Get(Stats.SESSION, Stats.XP_GAINED) - booked, 100)

-- 2) Pool fällt ohne XP-Gewinn weg (Max-Level): kein Erholungs-Bonus
wow.state.rested = 1000
wow.fire("UPDATE_EXHAUSTION")
local rested = Stats.Get(Stats.SESSION, Stats.XP_RESTED)
wow.state.maxLevel = 7
wow.state.rested = 0
wow.fire("UPDATE_EXHAUSTION")
expect("Pool weg auf Max-Level", Stats.Get(Stats.SESSION, Stats.XP_RESTED), rested)
wow.state.maxLevel = 60
wow.state.rested = 1000
wow.fire("UPDATE_EXHAUSTION")
wow.state.rested = 800
wow.fire("UPDATE_EXHAUSTION")
expect("Verbrauch beim Leveln zählt", Stats.Get(Stats.SESSION, Stats.XP_RESTED), rested + 100)

-- 3) Bank-Gold ist keine Einnahme/Ausgabe
local function money(delta)
  wow.state.money = wow.state.money + delta
  wow.fire("PLAYER_MONEY")
end
local earned = Stats.Get(Stats.SESSION, Stats.MONEY_EARNED)
wow.fire("BANKFRAME_OPENED")
money(50000)
money(-20000)
wow.fire("BANKFRAME_CLOSED")
wow.advance(5)
wow.runTimers()
expect("Bank: nichts verdient", Stats.Get(Stats.SESSION, Stats.MONEY_EARNED), earned)
expect("Bank: nichts ausgegeben", Stats.Get(Stats.SESSION, Stats.SPENT_OTHER), 0)
wow.fire("GUILDBANKFRAME_OPENED")
money(-1000)
wow.fire("GUILDBANKFRAME_CLOSED")
expect("Gildenbank: nichts ausgegeben", Stats.Get(Stats.SESSION, Stats.SPENT_OTHER), 0)

-- 4) Einzelreparatur (Hammer-Cursor) beim Händler
local repairMode = true
InRepairMode = function() return repairMode end
wow.advance(10)
wow.fire("MERCHANT_SHOW")
money(-200)
expect("Einzelreparatur", Stats.Get(Stats.SESSION, Stats.SPENT_REPAIR), 200)
repairMode = false
money(-300)
expect("Kauf bleibt Händler", Stats.Get(Stats.SESSION, Stats.SPENT_MERCHANT), 300)
InRepairMode = nil
wow.fire("MERCHANT_CLOSED")

-- 5) Tod vor der ersten /played-Antwort: Zeit seit diesem Tod, nicht seit dem früheren
addon.character.lastDeathPlayed = 5000
local total = nil
addon.PlayedTime.GetTotalSeconds = function() return total end
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")
wow.advance(30)
total = 90000
expectNear("seit diesem Tod", addon.DeathCounter.GetSecondsSinceDeath(), 30)

-- 6) Death Recap des früheren Todes wird nicht erneut verwendet
C_DeathRecap = { GetRecapEvents = function() return { { event = "SPELL_DAMAGE", sourceName = "Hogger", timestamp = 100 } } end }
expect("neuer Recap", addon.DeathRecap.GetLastCause().killer, "Hogger")
expect("gleicher Recap = alter Tod", addon.DeathRecap.GetLastCause(), nil)
C_DeathRecap = nil

-- 7) Wirksames Max-Level begrenzt Ziel und Prognose
GameRulesUtil = { GetEffectiveMaxLevelForPlayer = function() return 50 end }
expect("Max-Level aus GameRulesUtil", addon.Experience.MaxLevel(), 50)
expect("Ziel über wirksamem Max-Level", addon.Goal.Set(55), false)
expect("Ziel darunter", addon.Goal.Set(45), true)
GameRulesUtil = nil
