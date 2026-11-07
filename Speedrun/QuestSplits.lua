-- Quest-Splits: jede Quest von der Annahme bis zur Abgabe in /played-Sekunden, Bestzeit je Quest-ID.
--   Annahme  QUEST_ACCEPTED (Classic: questIndex, questID; Retail/Forever: questID) merkt die /played-Zeit in
--            character.questStarts[questID]
--   Abgabe   neuer Journal-Eintrag im questLog (QuestCounter.lua): bekommt duration (Sekunden) und delta
--            (Abweichung zur bisherigen Bestzeit, nil ohne); Level und XP stehen schon im Eintrag
--   Bestzeit accountweit LevelTimerStatsDB.questBest[questID] = Sekunden, über alle Charaktere
-- Einstellung questSplitNotice (aus): Chatzeile bei jeder Abgabe mit Dauer und Abweichung.
-- Quests, die vor der Installation oder im Questlog eines anderen Clients angenommen wurden, haben keine Dauer.
local _, ns = ...
local L = ns.L

local QuestSplits = {}
ns.QuestSplits = QuestSplits

local function bestTimes()
  LevelTimerStatsDB.questBest = LevelTimerStatsDB.questBest or {}
  return LevelTimerStatsDB.questBest
end

function QuestSplits.GetBest(questID)
  return bestTimes()[questID]
end

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

-- Classic liefert (questIndex, questID), Retail und WoW Forever nur (questID)
ns.RegisterEvent("QUEST_ACCEPTED", function(first, second)
  local questID = readable(second) or readable(first)
  local played = ns.PlayedTime.GetTotalSeconds()
  if type(questID) ~= "number" or not played then return end
  ns.character.questStarts[questID] = played
  ns.Debug("quests", "accepted %s at %s", questID, played)
end)

ns.Journal.OnAdd(function(logName, entry)
  if logName ~= "questLog" or not entry.questID then return end
  local starts = ns.character.questStarts
  local started, played = starts[entry.questID], ns.PlayedTime.GetTotalSeconds()
  starts[entry.questID] = nil
  if not started or not played or played < started then return end

  local best = bestTimes()
  local duration = played - started
  entry.duration = duration
  entry.delta = best[entry.questID] and duration - best[entry.questID] or nil
  if not best[entry.questID] or duration < best[entry.questID] then best[entry.questID] = duration end
  ns.Debug("quests", "quest split %s: %s (delta %s)", entry.questID, duration, entry.delta)

  if ns.db.questSplitNotice then
    local Format = ns.Format
    ns.Print(string.format(L.QUEST_SPLIT, entry.name or L.UNKNOWN_NAME, Format.Duration(duration),
      Format.SplitDelta(entry.delta)))
  end
end)

-- Abgegebene Quests mit Dauer, neueste zuerst (Historie, Speedrun > Quest-Splits)
function QuestSplits.GetRecords(characterKey)
  local records = {}
  for _, entry in ipairs(ns.History.GetQuestLog(characterKey)) do
    if entry.duration then table.insert(records, entry) end
  end
  return records
end
