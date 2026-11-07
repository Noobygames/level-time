-- Prognose für den nächsten Speedrun-Abschnitt (1-10, 1-20, 1-60 aus WorldRecords.lua): voraussichtliche
-- /played-Zeit beim Erreichen seines Levels (laufende /played-Zeit plus Forecast.SecondsToLevel) und der
-- Abstand zu drei Vergleichen:
--   PB             schnellster anderer eigener Charakter bis zu diesem Level (/played beim Erreichen)
--   Summe der Bestzeiten  je Level die schnellste Zeit über alle eigenen Charaktere (ohne Teil-Level);
--                  nur wenn jedes Level von 1 bis zum Abschnitt eine Zeit hat
--   Rekord         speedrun.com-Rekord des Abschnitts (WorldRecords.RecordFor)
-- Es zählt der erste noch nicht erreichte Abschnitt, der in der Split-Liste gezeigt wird.
local _, ns = ...
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

-- Schnellste /played-Zeit anderer eigener Charaktere beim Erreichen von level
function BracketForecast.PersonalBest(level)
  local best
  for _, key in ipairs(History.GetCharacterKeys()) do
    if key ~= ns.characterKey then
      local played = playedWhenReached(History.GetCharacter(key), level)
      if played and (not best or played < best) then best = played end
    end
  end
  return best
end

-- Summe der schnellsten Zeiten je Level 1..level-1 über alle eigenen Charaktere; nil, wenn eines fehlt
function BracketForecast.SumOfBest(level)
  local best = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    for completed, seconds in pairs(Runs.LevelTimes(key, true)) do
      if not best[completed] or seconds < best[completed] then best[completed] = seconds end
    end
  end
  return Runs.SumOfLevels(best, FIRST_LEVEL, level - 1)
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
