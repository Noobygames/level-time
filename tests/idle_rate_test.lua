-- Leerlauf ohne AFK-Flag (Roadmap 283): nach idleMinutes ohne XP-Gewinn und Kampf zählt die Zeit als Leerlauf
-- und fällt aus XP/h, Level-ETA und Historie-Raten heraus.
local TimeBreakdown = addon.TimeBreakdown
local Stats = addon.Stats
local Experience = addon.Experience

wow.login({ level = 10, xp = 0, xpMax = 10000, playedSeconds = 0 })

local function tick(seconds)
  for _ = 1, seconds do
    wow.advance(1)
    TimeBreakdown.Update(1)
  end
end

local function gain(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

-- Aus (Standard): kein Leerlauf
tick(400)
expect("aus: kein Leerlauf", TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS), 0)

-- Grenze 2 min: nach 120 s ohne Gewinn beginnt Leerlauf
addon.Set("idleMinutes", 2)
gain(100)
tick(100)
expect("unter der Grenze", TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS), 0)
tick(80)
local idle = TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS)
expectTrue("über der Grenze: ~60 s Leerlauf (" .. idle .. ")", idle >= 58 and idle <= 61)

-- Ein Gewinn beendet den Leerlauf
gain(100)
tick(30)
expectNear("Gewinn beendet Leerlauf", TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS), idle, 1)

-- Kampf zählt als aktiv, auch ohne Gewinn
wow.state.inCombat = true
tick(200)
wow.state.inCombat = false
tick(60)
expectNear("Kampf ist aktiv", TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS), idle, 1)

-- AFK hat Vorrang vor Leerlauf
tick(130)
local beforeAfk = TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS)
wow.state.afk = true
tick(50)
wow.state.afk = false
expectNear("AFK zählt nicht doppelt", TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS), beforeAfk, 1)

-- XP/h ohne Leerlauf: Spielzeit minus Leerlauf
gain(100)
TimeBreakdown.Flush()
wow.fire("TIME_PLAYED_MSG", 100000, 1200)
idle = TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.IDLE_SECONDS)
expectNear("XP/h ohne Leerlauf", Experience.GetRatePerHour(Stats.LEVEL), 300 / (1200 - idle) * 3600, 0.5)
addon.Set("idleMinutes", 0)
expectNear("Grenze aus: volle Zeit", Experience.GetRatePerHour(Stats.LEVEL), 300 / 1200 * 3600, 0.5)
addon.Set("idleMinutes", 2)

-- Historie: Level-Eintrag und Summe rechnen ebenso
wow.state.xp = 10000
wow.levelUp(11, 12000)
local record = addon.character.levelHistory[10]
expectTrue("Leerlauf im Level-Eintrag", (record.counters[Stats.IDLE_SECONDS] or 0) > 0)
expectNear("Historie-Rate", Experience.RecordRate(record),
  record.xp / (record.seconds - record.counters[Stats.IDLE_SECONDS]) * 3600, 0.5)
local summary = addon.History.Summarize({ record })
expect("Summe Leerlauf", summary.ratedIdleSeconds, record.counters[Stats.IDLE_SECONDS])

-- Zeile der Zeitaufteilung
local line
for _, entry in ipairs(addon.STAT_LINES) do
  if entry.setting == "showTimeBreakdown" then line = entry end
end
expect("Zeile Leerlauf vorhanden", line.rows[4].label, "ROW_TIME_IDLE")
