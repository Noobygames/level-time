-- Geld nach Zeitraum (Roadmap 276): Einnahmen und Ausgaben für heute, diese Woche (ab Montag), diesen Monat und
-- gesamt, dazu Gold/h und das Gold aller Charaktere. Tage, Woche und Monat kommen aus den Tageswerten (Daily.lua,
-- moneyIn/moneyOut, erst seit dieser Version erfasst); "Gesamt" aus den Level-Zählern (ganze Aufzeichnung).
local _, ns = ...
local Stats = ns.Stats

local Money = {}
ns.Money = Money

Money.DAY, Money.WEEK, Money.MONTH, Money.TOTAL = "day", "week", "month", "total"
local PERIODS = { Money.DAY, Money.WEEK, Money.MONTH }
local DAYS_PER_WEEK = 7
local MONDAY_OFFSET = 5  -- (wday + 5) % 7 = Tage seit Montag (date: 1 = Sonntag)

-- Beginn des Zeitraums, in dem timestamp liegt (Mitternacht)
function Money.PeriodStart(period, timestamp)
  local day = date("*t", timestamp)
  if period == Money.WEEK then
    return ns.Daily.AddDays(timestamp, -((day.wday + MONDAY_OFFSET) % DAYS_PER_WEEK))
  elseif period == Money.MONTH then
    return time({ year = day.year, month = day.month, day = 1, hour = 0 })
  end
  return ns.Daily.StartOfDay(timestamp)
end

-- Tagesschlüssel ("JJJJ-MM-TT") eines Zeitraums vom Beginn bis heute, höchstens 31; einmal je Tag gebaut statt
-- jede Sekunde über alle gespeicherten Tage zu laufen (dailyStats wächst unbegrenzt)
local periodKeys = {}  -- { today, [period] = { Schlüssel } }

local function daysOf(period, now)
  local todayKey = ns.Daily.DayKey(now)
  if periodKeys.today ~= todayKey then periodKeys = { today = todayKey } end
  local keys = periodKeys[period]
  if not keys then
    keys = {}
    local start, offset = Money.PeriodStart(period, now), 0
    local day = start
    repeat
      keys[#keys + 1] = ns.Daily.DayKey(day)
      offset = offset + 1
      day = ns.Daily.AddDays(start, offset)
    until keys[#keys] == todayKey or day > now
    periodKeys[period] = keys
  end
  return keys
end

-- Summe der Tageswerte des Zeitraums
local function sumDays(dailyStats, keys)
  local record = { moneyIn = 0, moneyOut = 0, seconds = 0 }
  if not dailyStats then return record end
  for _, key in ipairs(keys) do
    local entry = dailyStats[key]
    if entry then
      record.moneyIn = record.moneyIn + (entry.moneyIn or 0)
      record.moneyOut = record.moneyOut + (entry.moneyOut or 0)
      record.seconds = record.seconds + (entry.seconds or 0)
    end
  end
  return record
end

local function totalRecord(characterKey)
  local summary = ns.History.Summarize(ns.History.GetLevelRecords(characterKey))
  local spent = 0
  for _, counter in ipairs(Stats.SPENDING) do spent = spent + (summary.counters[counter] or 0) end
  return { moneyIn = summary.counters[Stats.MONEY_EARNED] or 0, moneyOut = spent, seconds = summary.seconds }
end

-- Zeilen { period, moneyIn, moneyOut, seconds } für heute, Woche, Monat und gesamt
function Money.GetPeriodRecords(characterKey)
  local dailyStats = ns.Daily.GetStats(characterKey)
  local now = time()
  local records = {}
  for _, period in ipairs(PERIODS) do
    local record = sumDays(dailyStats, daysOf(period, now))
    record.period = period
    records[#records + 1] = record
  end
  local total = totalRecord(characterKey)
  total.period = Money.TOTAL
  records[#records + 1] = total
  return records
end

-- Gold je Stunde aus Einnahmen und Spielzeit; nil bei zu wenig Zeit
function Money.PerHour(moneyIn, seconds)
  return ns.Experience.CalculateRate(moneyIn, seconds)
end

-- Gold aller Charaktere mit bekanntem Stand (character.money): Summe, Anzahl
function Money.TotalGold()
  local total, count = 0, 0
  for _, character in pairs(LevelTimerStatsDB and LevelTimerStatsDB.characters or {}) do
    if type(character.money) == "number" then
      total = total + character.money
      count = count + 1
    end
  end
  return total, count
end
