-- Prognose für den nächsten Speedrun-Abschnitt (1-10, 1-20, 1-60 aus WorldRecords.lua): voraussichtliche
-- /played-Zeit beim Erreichen seines Levels (laufende /played-Zeit plus Forecast.SecondsToLevel) und der
-- Abstand zu drei Vergleichen:
--   PB             schnellster anderer eigener Charakter bis zu diesem Level (/played beim Erreichen)
--   Summe der Bestzeiten  je Level die schnellste Zeit über alle eigenen Charaktere (ohne Teil-Level);
--                  nur wenn jedes Level von 1 bis zum Abschnitt eine Zeit hat
--   Rekord         speedrun.com-Rekord des Abschnitts (WorldRecords.RecordFor)
-- Es zählt der erste noch nicht erreichte Abschnitt, der in der Split-Liste gezeigt wird.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    splitListShowForecast = false,
  },
})
local History = ns.History
local Runs = ns.Runs
local WorldRecords = ns.WorldRecords

local BracketForecast = {}
ns.BracketForecast = BracketForecast

local FIRST_LEVEL = 1

-- /played eines anderen Charakters beim Erreichen von level; nil, solange unbekannt
local function playedWhenReached(character, level)
  local record = character.levelHistory and character.levelHistory[level - 1]
  return record and record.totalPlayed
end

-- PB und Summe der Bestzeiten je Abschnitts-Level, solange Runs.GetAll dieselbe Liste liefert (sie wird neu gebaut,
-- sobald sich Level-Zeiten oder Charaktere ändern können, Runs.lua); die Split-Liste fragt zweimal je Sekunde
local memo = {}  -- { runs, personalBest = { [level] = Sekunden oder false }, sumOfBest = { ... } }

local function cached(kind, level, compute)
  local runs = Runs.GetAll()
  if memo.runs ~= runs then memo = { runs = runs, personalBest = {}, sumOfBest = {} } end
  local value = memo[kind][level]
  if value == nil then
    value = compute(runs, level) or false
    memo[kind][level] = value
  end
  return value or nil
end

-- Schnellste /played-Zeit anderer eigener Charaktere beim Erreichen von level
local function personalBest(_, level)
  local best
  for _, key in ipairs(History.GetCharacterKeys()) do
    if key ~= ns.characterKey then
      local played = playedWhenReached(History.GetCharacter(key), level)
      if played and (not best or played < best) then best = played end
    end
  end
  return best
end

function BracketForecast.PersonalBest(level)
  return cached("personalBest", level, personalBest)
end

-- Summe der schnellsten Zeiten je Level 1..level-1 über alle eigenen Charaktere (bestTimes: ohne Teil-Level);
-- nil, wenn eines fehlt
local function sumOfBest(runs, level)
  local best = {}
  for _, run in ipairs(runs) do
    if not run.imported then
      for completed, seconds in pairs(run.bestTimes) do
        if not best[completed] or seconds < best[completed] then best[completed] = seconds end
      end
    end
  end
  return Runs.SumOfLevels(best, FIRST_LEVEL, level - 1)
end

function BracketForecast.SumOfBest(level)
  return cached("sumOfBest", level, sumOfBest)
end

-- { label, level, forecast, pb, sumOfBest, record } des nächsten Abschnitts; nil ohne offenen Abschnitt
-- oder solange keine Prognose möglich ist
function BracketForecast.Get()
  for _, comparison in ipairs(WorldRecords.GetComparisons()) do
    if not comparison.reached and WorldRecords.IsBracketShown(comparison.label) then
      local played = ns.PlayedTime.GetTotalSeconds()
      local remaining = ns.Forecast.SecondsToLevel(comparison.level)
      if not played or not remaining then return nil end
      return {
        label = comparison.label,
        level = comparison.level,
        forecast = played + remaining,
        pb = BracketForecast.PersonalBest(comparison.level),
        sumOfBest = BracketForecast.SumOfBest(comparison.level),
        record = comparison.record.seconds,
      }
    end
  end
  return nil
end
