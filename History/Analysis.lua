-- Auswertungen für die Graphen: bereitet Historie und Journal eines Charakters zu Datenreihen auf.
-- Jede Funktion liefert items = { { label, value, text, highlight } }:
-- label = Beschriftung, value = Zahl für die Balkenlänge, text = Anzeige des Werts,
-- highlight = hervorheben (laufendes Level, heutiger Tag).
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Experience = ns.Experience
local History = ns.History

local Analysis = {}
ns.Analysis = Analysis

local MAX_LEVEL_BARS = 30  -- neueste Level; mehr Balken werden zu schmal
local TOP_COUNT = 10

-- Level aufsteigend, höchstens die neuesten MAX_LEVEL_BARS
local function levelRecordsAscending(characterKey)
  local newestFirst = History.GetLevelRecords(characterKey)
  local records = {}
  for i = math.min(#newestFirst, MAX_LEVEL_BARS), 1, -1 do
    table.insert(records, newestFirst[i])
  end
  return records
end

function Analysis.TimePerLevel(characterKey)
  local items = {}
  for _, record in ipairs(levelRecordsAscending(characterKey)) do
    table.insert(items, {
      label = tostring(record.level),
      value = record.seconds or 0,
      text = record.seconds and Format.Duration(record.seconds) or "?",
      highlight = record.isCurrent,
    })
  end
  return items
end

function Analysis.XpRatePerLevel(characterKey)
  local items = {}
  for _, record in ipairs(levelRecordsAscending(characterKey)) do
    local rate = Experience.RecordRate(record)
    table.insert(items, {
      label = tostring(record.level),
      value = rate or 0,
      text = rate and Format.Number(rate) or "-",
      highlight = record.isCurrent,
    })
  end
  return items
end

---------------------------------------------------------------------------
-- Tages- und Wochenreihen aus den Tageswerten (Daily.lua). Diese bleiben auch erhalten,
-- wenn das Journal alte Einzeleinträge verwirft, und eignen sich daher für lange Zeiträume.
---------------------------------------------------------------------------
local KILL_DAYS = 30
local PLAYTIME_DAYS = 14
local PLAYTIME_WEEKS = 8
local DAYS_PER_WEEK = 7

-- Summe eines Feldes über dayCount Tage ab firstDay (Mitternacht)
local function sumDays(dailyStats, field, firstDay, dayCount)
  local sum = 0
  for offset = 0, dayCount - 1 do
    local entry = dailyStats[ns.Daily.DayKey(ns.Daily.AddDays(firstDay, offset))]
    sum = sum + (entry and entry[field] or 0)
  end
  return sum
end

-- Eine Säule je Tag der letzten dayCount Tage, heute zuletzt und hervorgehoben
local function perDay(characterKey, field, dayCount, formatValue)
  local dailyStats = ns.Daily.GetStats(characterKey)
  local today = ns.Daily.StartOfDay(time())
  local items = {}
  for index = 1, dayCount do
    local day = ns.Daily.AddDays(today, index - dayCount)
    local value = sumDays(dailyStats, field, day, 1)
    table.insert(items, {
      label = date(L.DAY_FORMAT, day),
      value = value,
      text = formatValue(value),
      highlight = index == dayCount,
    })
  end
  return items
end

function Analysis.KillsPerDay(characterKey)
  return perDay(characterKey, "kills", KILL_DAYS, tostring)
end

function Analysis.PlayTimePerDay(characterKey)
  return perDay(characterKey, "seconds", PLAYTIME_DAYS, Format.Duration)
end

-- Wochen beginnen am Montag; Beschriftung = Datum des Montags
function Analysis.PlayTimePerWeek(characterKey)
  local dailyStats = ns.Daily.GetStats(characterKey)
  local today = ns.Daily.StartOfDay(time())
  local daysSinceMonday = (date("*t", today).wday + 5) % DAYS_PER_WEEK  -- wday: 1 = Sonntag
  local thisWeek = ns.Daily.AddDays(today, -daysSinceMonday)
  local items = {}
  for index = 1, PLAYTIME_WEEKS do
    local week = ns.Daily.AddDays(thisWeek, (index - PLAYTIME_WEEKS) * DAYS_PER_WEEK)
    local seconds = sumDays(dailyStats, "seconds", week, DAYS_PER_WEEK)
    table.insert(items, {
      label = date(L.DAY_FORMAT, week),
      value = seconds,
      text = Format.Duration(seconds),
      highlight = index == PLAYTIME_WEEKS,
    })
  end
  return items
end

---------------------------------------------------------------------------
-- XP-Verlauf der laufenden (bei anderen Charakteren: letzten) Session in Abschnitten
---------------------------------------------------------------------------
local MAX_TIMELINE_STEPS = 36  -- 3 Stunden bei 5-Minuten-Abschnitten

-- Beschriftung "h:mm" für den Beginn eines Abschnitts
local function sessionClock(seconds)
  return string.format("%d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
end

function Analysis.SessionXpTimeline(characterKey)
  local session = History.GetCharacter(characterKey).currentSession
  local timeline = session.xpTimeline or {}
  local step = ns.Session.TIMELINE_STEP

  local lastStep = 0
  if characterKey == ns.characterKey and session.startedAt then
    lastStep = math.floor(ns.Session.GetSeconds() / step) + 1
  else
    for index in pairs(timeline) do
      lastStep = math.max(lastStep, index)
    end
  end
  if next(timeline) == nil then return {} end

  local items = {}
  for index = math.max(1, lastStep - MAX_TIMELINE_STEPS + 1), lastStep do
    local xp = timeline[index] or 0
    table.insert(items, {
      label = sessionClock((index - 1) * step),
      value = xp,
      text = Format.Number(xp),
      highlight = index == lastStep and characterKey == ns.characterKey,
    })
  end
  return items
end

-- Häufigkeit je Name über ein Journal (Journal.GetEntries: wächst nur hinten an derselben Liste). Je Liste und
-- Zählweise gemerkt und um neue Einträge ergänzt, statt bei jedem neuen Kill das ganze Journal zu zählen; neu gezählt
-- bei anderer oder kürzerer Liste und bei neuem Stand (Sprache der Namen, nachgetragene Todesursachen).
local tallies = setmetatable({}, { __mode = "k" })  -- [Liste] = { [nameOf] = { count, epoch, counts } }

local function countsOf(entries, nameOf, epoch)
  tallies[entries] = tallies[entries] or {}
  local tally = tallies[entries][nameOf]
  if not tally or tally.epoch ~= epoch or #entries < tally.count then
    tally = { count = 0, epoch = epoch, counts = {} }
    tallies[entries][nameOf] = tally
  end
  local counts = tally.counts
  for i = tally.count + 1, #entries do
    local name = nameOf(entries[i])
    counts[name] = (counts[name] or 0) + 1
  end
  tally.count = #entries
  return counts
end

local function ranksBefore(a, b)
  if a.value ~= b.value then return a.value > b.value end
  return a.label < b.label
end

-- Die TOP_COUNT häufigsten Namen absteigend (bei Gleichstand alphabetisch), ohne alle Namen zu sortieren.
-- text zeigt Anzahl und Anteil an allen Einträgen, z.B. "11 (13%)".
local function topCounts(entries, nameOf, epoch)
  local top = {}
  for name, count in pairs(countsOf(entries, nameOf, epoch)) do
    local item = { label = name, value = count }
    if #top < TOP_COUNT or ranksBefore(item, top[#top]) then
      local position = #top + 1
      while position > 1 and ranksBefore(item, top[position - 1]) do position = position - 1 end
      table.insert(top, position, item)
      if #top > TOP_COUNT then table.remove(top) end
    end
  end
  for _, item in ipairs(top) do
    item.text = string.format("%d (%s)", item.value, Format.Percent(item.value, #entries))
  end
  return top
end

-- Zonen mit der besten XP pro Stunde; kurze Aufenthalte sind zu ungenau und fallen weg
local MIN_ZONE_SECONDS = 300

function Analysis.XpRatePerZone(characterKey)
  local items = {}
  for _, record in ipairs(ns.Zones.GetRecords(characterKey)) do
    local rate = record.seconds >= MIN_ZONE_SECONDS and Experience.RecordRate(record)
    if rate then
      table.insert(items, { label = record.zone, value = rate, text = Format.Number(rate), highlight = record.isCurrent })
    end
  end
  while #items > TOP_COUNT do
    table.remove(items)
  end
  return items
end

local function killName(kill)
  return kill.name or L.UNKNOWN_NAME
end

local function cacheEpoch(logName)
  return (ns.db and ns.db.language or "") .. ":" .. ns.Journal.EditRevision(logName)
end

function Analysis.TopKills(characterKey)
  return topCounts(ns.Journal.GetEntries(characterKey, "killLog"), killName, cacheEpoch("killLog"))
end

function Analysis.DeathCauses(characterKey)
  return topCounts(ns.Journal.GetEntries(characterKey, "deathLog"), History.DeathCauseText, cacheEpoch("deathLog"))
end

-- Wann ich spiele (PlayHours.lua): Heatmap Wochentag × Stunde, Farbe = aktive Zeit, Tooltip mit Zeit und XP.
-- Liefert ein Raster für Charts.CreateHeatmap statt einer Liste; total = gesamte aktive Zeit (0 = keine Daten).
function Analysis.PlayHours(characterKey)
  local PlayHours = ns.PlayHours
  local source = PlayHours.Grid(characterKey)
  local grid = { rows = {}, columns = {}, cells = {}, total = source.total }
  for hour = 0, PlayHours.HOURS - 1 do grid.columns[hour + 1] = tostring(hour) end
  for day = 1, PlayHours.DAYS do
    grid.rows[day] = L["WEEKDAY_SHORT_" .. day]
    grid.cells[day] = {}
    for hour = 0, PlayHours.HOURS - 1 do
      local cell = source.cells[day][hour]
      local label, text = PlayHours.CellText(day, hour, cell)
      grid.cells[day][hour + 1] = { value = cell.seconds, label = label, text = text }
    end
  end
  return grid
end
