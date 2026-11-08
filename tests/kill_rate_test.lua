-- Roadmap 382: Kills je Stunde in Level, Session und Instanz über dieselbe Spielzeit wie XP/h (ohne AFK und
-- Leerlauf, wenn eingestellt), Spalte Kills/h in den Level- und Session-Tabellen der Historie.
local Stats = addon.Stats
local Experience = addon.Experience
local TimeBreakdown = addon.TimeBreakdown
local Format = addon.Format

local function row(setting, index)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[index or 1] end
  end
end
local killRate = row("showKillRate")

local function kill(xp)
  wow.state.xp = wow.state.xp + xp
  wow.fire("PLAYER_XP_UPDATE", "player")
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Wolf", xp))
end

local function enter(name)
  wow.state.instance = name and { name = name, type = "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

wow.login({ level = 10, xp = 0, xpMax = 100000, playedSeconds = 0 })
expect("direkt nach Login: noch keine Rate", killRate.value(Stats.SESSION), "...")
expect("ohne Instanz-Lauf: keine Rate", killRate.value(Stats.INSTANCE), "...")

-- 30 Kills in 10 Minuten = 180 Kills/h in Session und Level
for _ = 1, 30 do
  wow.advance(20)
  kill(50)
end
wow.fire("TIME_PLAYED_MSG", 100000, 600)
expect("Session: 180 Kills/h", killRate.value(Stats.SESSION), Format.Number(180))
expect("Level: 180 Kills/h", killRate.value(Stats.LEVEL), Format.Number(180))

-- 10 Minuten ohne Kill: Rate sinkt auf die Hälfte, nie "kein Wert"
wow.advance(600)
wow.fire("TIME_PLAYED_MSG", 100000, 1200)
expect("Session nach Pause", killRate.value(Stats.SESSION), Format.Number(90))

-- Instanz-Lauf: zählt nur die Kills und die Zeit des Laufs
enter("Die Todesminen")
for _ = 1, 10 do
  wow.advance(30)
  kill(100)
end
expectNear("Instanz-Zeit", Stats.GetSeconds(Stats.INSTANCE), 300, 1)
expect("Instanz: 120 Kills/h", killRate.value(Stats.INSTANCE), Format.Number(120))
enter(nil)

-- AFK und Leerlauf fallen aus der Spielzeit wie bei XP/h: Kills/h = XP/h * Kills / XP
addon.Set("xpRateWithoutAfk", true)
wow.state.afk = true
for _ = 1, 300 do
  wow.advance(1)
  TimeBreakdown.Update(1)
end
wow.state.afk = false
TimeBreakdown.Update(1)
Stats.Increment(Stats.IDLE_SECONDS, 120)
addon.Set("idleMinutes", 2)
wow.fire("TIME_PLAYED_MSG", 100000, 1800)
for _, scope in ipairs({ Stats.LEVEL, Stats.SESSION }) do
  local kills, xp = Stats.Get(scope, Stats.PVE_KILLS), Stats.GetXp(scope)
  local seconds = Experience.ScopeRateSeconds(scope)
  expectTrue(scope .. ": AFK und Leerlauf abgezogen", seconds < Stats.GetSeconds(scope) - 400)
  expect(scope .. ": Zeile = Kills je bewertete Stunde", killRate.value(scope), Format.Number(kills / seconds * 3600))
  expectNear(scope .. ": gleiche Zeit wie XP/h", Experience.CountRate(kills, seconds),
    Experience.GetRatePerHour(scope) * kills / xp, 0.001)
end
addon.Set("xpRateWithoutAfk", false)
addon.Set("idleMinutes", 0)

-- Historie: Spalte Kills/h in Level- und Session-Tabelle (CSV der angezeigten Zeilen), auch in der Summenzeile
wow.levelUp(11, 100000)
-- Text an einem Trennzeichen teilen (ohne verschachteltes gmatch, das gopher-lua hier abstürzen ließ)
local function split(text, separator)
  local parts, start = {}, 1
  while true do
    local at = text:find(separator, start, true)
    if not at then
      table.insert(parts, text:sub(start))
      return parts
    end
    table.insert(parts, text:sub(start, at - 1))
    start = at + #separator
  end
end

local function csvRows(tab)
  SlashCmdList.LEVELTIMER("history")
  expectTrue("Reiter " .. tab, addon.HistoryWindow.ShowView(tab))
  local shown = wow.shownTable()
  expectTrue("Tabelle " .. tab, shown ~= nil)
  local rows = {}
  for _, line in ipairs(split(shown:BuildCsv(), "\n")) do
    table.insert(rows, split(line, addon.L.CSV_SEPARATOR))
  end
  SlashCmdList.LEVELTIMER("history")  -- schließen
  return rows
end
local function columnOf(header)
  for index, text in ipairs(header) do
    if text == addon.L.HISTORY_KILL_RATE then return index end
  end
end

local levelRows = csvRows("HISTORY_TAB_LEVEL_KILLS")
local levelColumn = columnOf(levelRows[1])
expectTrue("Level-Tabelle hat Kills/h", levelColumn ~= nil)
local found = false
for _, cells in ipairs(levelRows) do
  if cells[1] == "10" then
    found = true
    expect("Level 10: 40 Kills in 30 min", cells[levelColumn], Format.Number(80))
  end
end
expectTrue("Level 10 in der Tabelle", found)

local sessionRows = csvRows("HISTORY_TAB_SESSION_KILLS")
local sessionColumn = columnOf(sessionRows[1])
expectTrue("Session-Tabelle hat Kills/h", sessionColumn ~= nil)
local session = addon.History.GetSessionRecords(addon.characterKey)[1]
expect("laufende Session", sessionRows[2][sessionColumn],
  Format.Number(Experience.CountRate(session.counters[Stats.PVE_KILLS], Experience.RecordRateSeconds(session))))

-- Summenzeile (History.Summarize) und Eintrag ohne bekannte Spielzeit
local record = addon.character.levelHistory[10]
local summary = addon.History.Summarize({ record, { counters = { [Stats.PVE_KILLS] = 5 } } })
expectNear("Summe: Kills je bekannte Spielzeit", Experience.CountRate(summary.counters[Stats.PVE_KILLS],
  Experience.RecordRateSeconds(summary)), 45 / 1800 * 3600, 0.001)
