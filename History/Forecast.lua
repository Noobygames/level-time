-- Prognose bis zu einem Level (Max-Level, Session-Ziel): Rest des aktuellen Levels (wie "Zeit bis
-- Level-Up") plus die weiteren Level.
--   Mit XP-Tabelle (XpTable.lua: Classic Era, WoW Forever, TBC): XP der weiteren Level geteilt durch die
--   XP/h der letzten SAMPLE_SIZE abgeschlossenen Level samt dem laufenden. XP/h steigt mit dem Level
--   meist etwas, die Prognose ist daher eher großzügig.
--   Ohne Tabelle (Retail): Durchschnittszeit der letzten SAMPLE_SIZE Level je weiteres Level; höhere
--   Level dauern meist länger, die Prognose ist daher eher knapp.
-- Zeiten ohne AFK und Leerlauf, wenn eingestellt (Experience.RecordRate/RateSeconds).
local _, ns = ...
local Stats = ns.Stats
local Experience = ns.Experience
local History = ns.History
local XpTable = ns.XpTable

local Forecast = {}
ns.Forecast = Forecast

local SAMPLE_SIZE = 5
local SECONDS_PER_HOUR = 3600

-- Die letzten SAMPLE_SIZE abgeschlossenen Level mit bekannter Dauer, neueste zuerst
local function recentCompletedLevels()
  local records = {}
  for _, record in ipairs(History.GetLevelRecords(ns.characterKey)) do
    if not record.isCurrent and record.seconds then
      table.insert(records, record)
      if #records == SAMPLE_SIZE then break end
    end
  end
  return records
end

local function rateSeconds(record)
  return Experience.RecordRateSeconds(record)
end

local function averageRecentLevelSeconds()
  local records = recentCompletedLevels()
  if #records == 0 then return nil end
  local sum = 0
  for _, record in ipairs(records) do
    sum = sum + rateSeconds(record)
  end
  return sum / #records
end

-- XP/h über die letzten Level und das laufende zusammen (gewichtet nach Spielzeit)
local function recentXpRate()
  local current = History.GetLevelRecords(ns.characterKey)[1]
  local xp, seconds = current.xp or 0, current.seconds and rateSeconds(current) or 0
  for _, record in ipairs(recentCompletedLevels()) do
    xp = xp + (record.xp or 0)
    seconds = seconds + rateSeconds(record)
  end
  return Experience.CalculateRate(xp, seconds)
end

-- XP/h der letzten abgeschlossenen Level (ohne das laufende); nil ohne abgeschlossenes Level. Vergleichswert der
-- XP/h-Zeile bei valueColors, je Anzeige-Takt einmal
local function averageLevelXpRate()
  local xp, seconds = 0, 0
  for _, record in ipairs(recentCompletedLevels()) do
    xp = xp + (record.xp or 0)
    seconds = seconds + rateSeconds(record)
  end
  if seconds <= 0 then return nil end
  return Experience.CalculateRate(xp, seconds)
end
Forecast.AverageLevelXpRate = ns.TickCache.Memo(averageLevelXpRate)

-- Weitere Level nach dem aktuellen bis targetLevel: aus der XP-Tabelle, sonst aus den Level-Zeiten
local function secondsForLaterLevels(targetLevel, remaining)
  local xp = XpTable.XpBetween(ns.level + 1, targetLevel)
  local rate = xp and recentXpRate()
  if rate then return xp / rate * SECONDS_PER_HOUR end

  local levelSeconds = Experience.ScopeRateSeconds(Stats.LEVEL)
  local perLevel = averageRecentLevelSeconds() or (levelSeconds + remaining)
  return (targetLevel - ns.level - 1) * perLevel
end

-- Geschätzte Spielzeit bis zum Erreichen von targetLevel; nil, solange keine Schätzung möglich ist.
-- Im Anzeige-Takt (TickCache) je Ziel einmal: Max-Level-Zeile und Session-Ziel fragen oft dasselbe Level ab.
local function secondsToLevel(targetLevel)
  if not Experience.IsLeveling() then return nil end
  if targetLevel <= ns.level then return 0 end
  local remaining = Experience.GetSecondsToLevel(Stats.LEVEL)
  if not remaining then return nil end
  if targetLevel == ns.level + 1 then return remaining end
  return remaining + secondsForLaterLevels(targetLevel, remaining)
end
Forecast.SecondsToLevel = ns.TickCache.Memo(secondsToLevel)

function Forecast.SecondsToMaxLevel()
  if not GetMaxPlayerLevel then return nil end
  return Forecast.SecondsToLevel(GetMaxPlayerLevel())
end
