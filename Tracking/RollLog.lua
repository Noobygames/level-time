-- Wurf-Historie: jeder abgeschlossene Gruppen-Wurf um Beute (LootRolls.OnComplete) landet im Journal-Log rollLog,
-- also wer was bekommen hat, mit Wahlen, eigenem Wurf und Instanz. Einstellung lootRollHistory (Standard an); nur
-- in einer Gruppe. Anzeige: Historie > Journal > Würfe (HistoryTables.lua).
local _, ns = ...
local LootRolls = ns.LootRolls
local Journal = ns.Journal

local RollLog = {}
ns.RollLog = RollLog

local ALL_PASSED = 1  -- RecordCodec kennt nur Zahlen und Werte, keine Wahrheitswerte

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function inGroup()
  return readable(IsInGroup and IsInGroup()) == true
end

-- Instanzname und Schwierigkeit (GetInstanceInfo: name, instanceType, difficultyID, difficultyName); nil draußen
local function instanceInfo()
  local inside = readable(IsInInstance and IsInInstance())
  if inside ~= true or not GetInstanceInfo then return nil, nil end
  local name, _, _, difficultyName = GetInstanceInfo()
  name, difficultyName = readable(name), readable(difficultyName)
  if difficultyName == "" then difficultyName = nil end
  return type(name) == "string" and name or nil, type(difficultyName) == "string" and difficultyName or nil
end

-- Eintrag aus einem abgeschlossenen Wurf (ohne time/level/zone, die ergänzt Journal.AddRoll)
function RollLog.EntryOf(roll)
  local counts = LootRolls.Counts(roll)
  local self = readable(UnitName("player"))
  local instance, difficulty = instanceInfo()
  local run = ns.Instances.GetCurrentRun()
  return {
    link = roll.link,
    itemId = roll.itemId,
    quality = roll.quality or (roll.link and ns.Items.GetQuality(roll.link)) or nil,
    winner = roll.winner,
    winnerClass = roll.winner and LootRolls.ClassOf(roll, roll.winner) or nil,
    winnerRoll = roll.winnerRoll,
    winnerChoice = LootRolls.WinnerKind(roll),
    allPassed = roll.allPassed and ALL_PASSED or nil,
    need = counts.need, greed = counts.greed, disenchant = counts.disenchant, transmog = counts.transmog,
    pass = counts.pass,
    ownChoice = self and roll.choices[self] or nil,
    ownRoll = self and roll.rolls and roll.rolls[self] or nil,
    instance = instance,
    difficulty = difficulty,
    runStart = instance and run and run.startedAt or nil,
    name = not roll.link and roll.name or nil,
    encounter = LootRolls.EncounterName(roll),
  }
end

LootRolls.OnComplete(function(roll)
  if not ns.db.lootRollHistory then return end
  if not inGroup() then
    ns.Debug("lootroll", "history: %s not recorded (no group)", roll.link)
    return
  end
  if not roll.link and not roll.name then return end
  local entry = Journal.AddRoll(RollLog.EntryOf(roll))
  ns.Debug("lootroll", "history: %s -> %s (%s)", entry.link, entry.winner, entry.winnerRoll)
end)
