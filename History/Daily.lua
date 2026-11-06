-- Tageswerte pro Charakter: ns.character.dailyStats["JJJJ-MM-TT"] = { seconds, kills, deaths, xp, moneyIn, moneyOut }.
-- moneyIn/moneyOut (Kupfer, Einnahmen/Ausgaben) gibt es erst seit Roadmap 276; ältere Tage haben 0.
-- Spielzeit wird beim Lesen und beim Logout verbucht und dabei an Mitternacht aufgeteilt.
local _, ns = ...

local Daily = {}
ns.Daily = Daily

local bookedUntil  -- time() bis zu dem die Spielzeit verbucht ist (nil = nicht eingeloggt)

-- Mitternacht des Tages, in dem timestamp liegt
function Daily.StartOfDay(timestamp)
  local day = date("*t", timestamp)
  return time({ year = day.year, month = day.month, day = day.day, hour = 0 })
end

-- Mitternacht dayOffset Tage nach dem Tag von timestamp. Über den Kalender statt + 86400 s,
-- weil Tage bei der Zeitumstellung 23 oder 25 Stunden haben (time() normalisiert den Tagesüberlauf).
function Daily.AddDays(timestamp, dayOffset)
  local day = date("*t", timestamp)
  return time({ year = day.year, month = day.month, day = day.day + dayOffset, hour = 0 })
end

function Daily.DayKey(timestamp)
  return date("%Y-%m-%d", timestamp)
end

-- Felder eines Tageseintrags. Kills, Tode und XP zählen hier dauerhaft mit, auch wenn
-- das Journal alte Einzeleinträge wegen seines Limits verwirft (Langzeit-Graphen).
local DAILY_FIELDS = { seconds = 0, kills = 0, deaths = 0, xp = 0, moneyIn = 0, moneyOut = 0 }

-- Tageseintrag holen oder anlegen (fehlende Felder werden ergänzt)
function Daily.Entry(dailyStats, timestamp)
  local key = Daily.DayKey(timestamp)
  local entry = dailyStats[key] or {}
  for field, default in pairs(DAILY_FIELDS) do
    entry[field] = entry[field] or default
  end
  dailyStats[key] = entry
  return entry
end

-- Spielzeit seit der letzten Verbuchung den jeweiligen Tagen gutschreiben
function Daily.BookPlayTime()
  if not bookedUntil then return end
  local now = time()
  local from = bookedUntil
  while from < now do
    local untilTime = math.min(now, Daily.AddDays(from, 1))
    if untilTime <= from then break end  -- Schutz: nie auf der Stelle treten
    local entry = Daily.Entry(ns.character.dailyStats, from)
    entry.seconds = entry.seconds + (untilTime - from)
    from = untilTime
  end
  bookedUntil = now
end

-- Tageswerte eines Charakters; beim eingeloggten inklusive der laufenden Spielzeit
function Daily.GetStats(characterKey)
  if characterKey == ns.characterKey then
    Daily.BookPlayTime()
  end
  return ns.History.GetCharacter(characterKey).dailyStats
end

-- Zähler, die in die Tageswerte fließen
local DAILY_COUNTERS = {
  [ns.Stats.PVE_KILLS] = "kills",
  [ns.Stats.PVP_KILLS] = "kills",
  [ns.Stats.DEATHS] = "deaths",
  [ns.Stats.XP_GAINED] = "xp",
  [ns.Stats.MONEY_EARNED] = "moneyIn",
}
for _, counter in ipairs(ns.Stats.SPENDING) do DAILY_COUNTERS[counter] = "moneyOut" end

ns.Stats.OnIncrement(function(counter, amount)
  local field = DAILY_COUNTERS[counter]
  if field then
    local entry = Daily.Entry(ns.character.dailyStats, time())
    entry[field] = entry[field] + amount
  end
end)

ns.OnLogin(function()
  bookedUntil = time()
end)

ns.OnLogout(Daily.BookPlayTime)
