-- Quest-Check beim Betreten einer Instanz (Einstellung instanceQuestCheck, an; nur mit ns.DungeonDB, also Classic Era
-- und WoW Forever): eine kompakte Chatzeile mit den Dungeonquests, die der Charakter jetzt annehmen könnte, aber nicht
-- im Log hat. Verfügbar = Mindestlevel erreicht, Fraktion und Klasse passen, nicht abgegeben (DungeonQuests.OwnQuests),
-- Vorquests erfüllt (DungeonQuests.PrerequisitesMet: alle "pre", eine aus "preAny", keine aus "excl").
-- Quests über dem eigenen Level fallen weg. Dieselbe Liste meldet es je Instanz nur einmal (kein Wiederholen nach
-- Geisterlauf oder Wiedereintritt), erst wenn sie sich ändert wieder.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    instanceQuestCheck = true,
  },
})
local L = ns.L

local InstanceQuestCheck = {}
ns.InstanceQuestCheck = InstanceQuestCheck

local MAX_LISTED = 6
local SEPARATOR = ", "

-- Zuletzt gemeldeter Text je Instanz-Karten-ID
local lastReport = {}

function InstanceQuestCheck.IsAvailable()
  return ns.DungeonQuests.IsAvailable()
end

-- Verfügbare Dungeonquests der Instanz, die nicht im Log sind (Einträge wie DungeonQuests.OwnQuests)
function InstanceQuestCheck.Missing(mapID)
  local level = UnitLevel("player") or 0
  local missing = {}
  for _, quest in ipairs(ns.DungeonQuests.OwnQuests(mapID)) do
    if not quest.inLog and level >= quest.minLevel
      and ns.DungeonQuests.PrerequisitesMet(quest.pre, quest.preAny, quest.excl) then
      table.insert(missing, quest)
    end
  end
  return missing
end

local function questText(quest)
  local text = string.format("[%d] %s", quest.level, quest.title)
  local start = ns.DungeonEntrances.StartText(quest)
  return start and string.format(L.INSTANCE_QUEST_CHECK_START, text, start) or text
end

-- Chatzeile: "Fehlende Dungeonquests (2): [25] A (Zone (x, y)), [26] B"; nil, wenn nichts fehlt
function InstanceQuestCheck.Text(mapID)
  local missing = InstanceQuestCheck.Missing(mapID)
  if #missing == 0 then return nil end
  local parts = {}
  for index, quest in ipairs(missing) do
    if index > MAX_LISTED then
      table.insert(parts, string.format(L.DUNGEON_QUESTS_MORE, #missing - MAX_LISTED))
      break
    end
    table.insert(parts, questText(quest))
  end
  return string.format(L.INSTANCE_QUEST_CHECK_MISSING, #missing, table.concat(parts, SEPARATOR))
end

local function check()
  if not ns.db.instanceQuestCheck or not InstanceQuestCheck.IsAvailable() then return end
  local mapID = select(8, GetInstanceInfo())  -- 8. Rückgabe: Instanz-Karten-ID
  if not mapID then return end
  local text = InstanceQuestCheck.Text(mapID)
  ns.Debug("instance", "quest check %s: %s", mapID, text or "complete")
  if text == lastReport[mapID] then return end
  lastReport[mapID] = text
  if text then ns.Print(text) end
end

ns.InstanceCopy.OnEnter(check)
