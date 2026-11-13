-- Geheime XP-Meldungen (Retail/Forever im Kampf und in Instanzen): im Kampf oder kurz danach ein Kill ohne Namen,
-- die XP stammt aus der XP-Änderung um die Meldung herum.
local Stats = addon.Stats

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function secretMessage()
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", wow.SECRET)
end

local function kills() return Stats.Get(Stats.LEVEL, Stats.PVE_KILLS) end
local function killXp() return Stats.Get(Stats.LEVEL, Stats.XP_KILLS) end

wow.login()
wow.state.inCombat = true

-- Meldung vor der XP-Änderung
secretMessage()
gainXp(120)
wow.advance(0.5)
wow.runTimers()
expect("Kill im Kampf", kills(), 1)
expect("XP aus der Änderung danach", killXp(), 120)
local log = addon.character.killLog
expect("Journal ohne Namen", log[#log].name, nil)

-- XP-Änderung vor der Meldung
wow.advance(5)
gainXp(80)
wow.advance(0.2)
secretMessage()
wow.runTimers()
expect("zweiter Kill", kills(), 2)
expect("XP aus der Änderung davor", killXp(), 200)

-- Zwei Kills auf einmal: Summe stimmt, keine XP doppelt
wow.advance(5)
secretMessage()
secretMessage()
gainXp(50)
gainXp(60)
wow.runTimers()
expect("zwei Kills", kills(), 4)
expect("XP nicht doppelt", killXp(), 310)

-- Kurz nach dem Kampf zählt noch, später nicht mehr
wow.advance(5)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
wow.advance(2)
secretMessage()
gainXp(40)
wow.runTimers()
expect("kurz nach Kampfende", kills(), 5)
wow.advance(10)
secretMessage()
gainXp(500)
wow.runTimers()
expect("außerhalb des Kampfs kein Kill", kills(), 5)
expect("XP bleibt sonstige", killXp(), 350)

-- Questabgabe im Kampf: Meldung gehört zur Quest
wow.advance(10)
wow.state.inCombat = true
wow.fire("QUEST_TURNED_IN", 100, 300, 0)
secretMessage()
gainXp(300)
wow.runTimers()
expect("Quest-XP kein Kill", kills(), 5)
expect("Quest-XP nicht bei Kills", killXp(), 350)

-- Kill bringt den Level-Up: Kill und XP gehören noch zum alten Level, nicht zum neuen
wow.advance(10)
local oldLevel = addon.level
secretMessage()
gainXp(70)
wow.levelUp(oldLevel + 1)
wow.runTimers()
local record = addon.character.levelHistory[oldLevel]
expect("Kill im alten Level", record.counters[Stats.PVE_KILLS], 6)
expect("Kill-XP im alten Level", record.counters[Stats.XP_KILLS], 420)
expect("neues Level ohne Kill", kills(), 0)
expect("nicht doppelt gezählt", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 6)
