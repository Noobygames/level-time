-- Roadmap 382: Kills der letzten 15 Minuten und hochgerechnete Kills/h, Fenster gleitet mit der Zeit; Ringpuffer
-- (Lib/RecentCounter.lua) wächst über die Startgröße hinaus und verliert dabei nichts.
local Stats = addon.Stats
local RecentCounts = addon.RecentCounts
local RecentCounter = addon.RecentCounter
local Format = addon.Format

local function row(setting, index)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[index] end
  end
end
local recentKills, recentRate = row("showRecentKills", 1), row("showRecentKills", 2)

local function kill()
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Eber", 40))
end

-- Ringpuffer allein: Summe, Ablauf genau nach window, Wachsen über 64 Einträge mit Umlauf
local counter = RecentCounter.New(100)
counter:Add(0, 2)
counter:Add(50)
expect("Summe", counter:Count(60), 3)
expect("nach 100 s fällt der erste weg", counter:Count(100), 1)
expect("leer", counter:Count(200), 0)
for second = 1, 200 do counter:Add(1000 + second * 0.25) end  -- Kopf mitten im Puffer, dann Wachsen
expect("200 Einträge nach Wachsen", counter:Count(1050), 200)
expect("Hälfte abgelaufen", counter:Count(1100 + 25), 100)
counter:Reset()
expect("zurückgesetzt", counter:Count(2000), 0)

wow.login({ level = 10, xp = 0, xpMax = 100000 })
expect("nach Login: keine Kills", recentKills.value(), "0")
expect("nach Login: noch keine Rate", recentRate.value(), "...")

-- 5 Minuten lang ein Kill je 30 s: 10 Kills, hochgerechnet über 5 min = 120 Kills/h
for _ = 1, 10 do
  wow.advance(30)
  kill()
end
expect("10 Kills", recentKills.value(), "10")
expect("Rate im ersten Fenster über die Zeit seit Login", recentRate.value(), Format.Number(120))

-- Weitere 10 min mit doppeltem Tempo: Fenster voll (15 min), 10 + 40 Kills
for _ = 1, 40 do
  wow.advance(15)
  kill()
end
expect("50 Kills in 15 min", RecentCounts.Count(Stats.PVE_KILLS), 50)
expect("Rate = Kills x 4", recentRate.value(), Format.Number(200))

-- Fenster gleitet: nach 5 min Pause sind die ersten 10 Kills (erste 5 min) heraus
wow.advance(300)
expect("Pause: alte Kills fallen heraus", RecentCounts.Count(Stats.PVE_KILLS), 40)
expect("Rate sinkt", recentRate.value(), Format.Number(160))
wow.advance(900)
expect("15 min ohne Kill", recentKills.value(), "0")
expect("Rate 0", recentRate.value(), "0")
expect("Session-Kills bleiben", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 50)

-- Geheime Meldung (Kill ohne Namen) zählt über Stats.OnIncrement mit
wow.state.inCombat = true
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", wow.SECRET)
wow.advance(0.5)
wow.runTimers()
expect("geheimer Kill gezählt", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 51)
expect("geheimer Kill im Fenster", RecentCounts.Count(Stats.PVE_KILLS), 1)
wow.state.inCombat = false

-- /reload: Fenster beginnt neu wie bei XP/h (15 min)
wow.logout()
wow.login({ level = 10 })
expect("nach Reload leer", recentKills.value(), "0")
