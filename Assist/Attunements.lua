-- Schlüssel- und Einstimmungs-Questreihen (LT-254; nur mit ns.AttunementData, also Classic Era und Forever): die
-- Schritte bis zur letzten Quest aus Assist/InstanceData/attunements.lua, rückwärts über die Vorquests der Dungeon-DB
-- (alle aus "pre", aus "preAny" die abgegebene, sonst die erste), Anfang zuerst. Stand je Schritt: erledigt
-- (QuestItemTooltip.IsQuestDone), aktiv (im Questlog, QuestLog.Find) oder offen. Ort des nächsten Schritts: Geber aus
-- der Dungeon-DB, sonst der gelernte Geber-Ort (QuestNpcs). Anzeige im Tooltip der Dungeon-Eingänge.
local _, ns = ...
local L = ns.L

local Attunements = {}
ns.Attunements = Attunements

local MAX_STEP_LINES = 4
local MIN_LEVEL = 2  -- Spalte Mindestlevel in questInfo
local FACTION_CODES = { Alliance = "A", Horde = "H" }
local TITLE_KEYS = { key = "ATTUNEMENT_KEY_TITLE", attunement = "ATTUNEMENT_TITLE" }
local TITLE_COLOR = ns.Theme.COLORS.gold
local TEXT_COLOR = ns.Theme.COLORS.text
local DONE_COLOR = ns.Theme.COLORS.success
local LOW_LEVEL_COLOR = ns.Theme.COLORS.bad

local function isDone(questID) return ns.QuestItemTooltip.IsQuestDone(questID) end

local function pickAny(questIDs)
  for _, questID in ipairs(questIDs) do
    if isDone(questID) then return questID end
  end
  return questIDs[1]
end

local function collect(questID, steps, seen)
  if seen[questID] then return end
  seen[questID] = true
  local info = ns.DungeonDB.questInfo[questID]
  for _, preID in ipairs(info and info.pre or {}) do collect(preID, steps, seen) end
  if info and info.preAny then collect(pickAny(info.preAny), steps, seen) end
  table.insert(steps, questID)
end

-- Letzte Quest des Eintrags für die Fraktion des Charakters; nil ohne passende Reihe
local function finalQuest(entry)
  if type(entry.quest) == "number" then return entry.quest end
  local faction = UnitFactionGroup("player")
  if faction == nil or ns.IsSecret(faction) then return nil end
  return entry.quest[FACTION_CODES[faction]]
end

local function status(questID)
  if isDone(questID) then return "done" end
  if ns.QuestLog.Find(questID) then return "active" end
  return "open"
end

-- Ort des Gebers: Dungeon-DB, sonst gelernt; { uiMapID, x, y } oder nil
local function giverPlace(questID)
  local place = ns.DungeonQuests.GiverPlace(questID)
  if place then return place end
  local learned = ns.QuestNpcs.Get(questID)
  local giver = learned and learned.giver
  if giver and giver.mapID and giver.x then return { uiMapID = giver.mapID, x = giver.x, y = giver.y } end
  return nil
end

-- Reihen am Eingang der Instanz: { { mapID, kind, done, steps = { { questID, status }, ... } }, ... }
function Attunements.At(mapID)
  local list = {}
  if not (ns.AttunementData and ns.DungeonDB) then return list end
  for _, entry in ipairs(ns.AttunementData) do
    local questID = entry.at == mapID and finalQuest(entry)
    if questID then
      local steps, done = {}, 0
      local questIDs = {}
      collect(questID, questIDs, {})
      for _, stepID in ipairs(questIDs) do
        local stepStatus = status(stepID)
        if stepStatus == "done" then done = done + 1 end
        table.insert(steps, { questID = stepID, status = stepStatus })
      end
      table.insert(list, { mapID = entry.mapID, kind = entry.kind, done = done, steps = steps })
    end
  end
  return list
end

-- Rechte Spalte eines offenen Schritts: im Log, ab Level X, beim ersten offenen der Geber-Ort, sonst "offen"
local function stepStatus(step, isNext)
  if step.status == "active" then return L.DUNGEON_QUEST_IN_LOG, DONE_COLOR end
  local info = ns.DungeonDB.questInfo[step.questID]
  if info and (UnitLevel("player") or 0) < info[MIN_LEVEL] then
    return string.format(L.DUNGEON_QUEST_MIN_LEVEL, info[MIN_LEVEL]), LOW_LEVEL_COLOR
  end
  if isNext then return ns.DungeonQuestHints.Detail(step.questID, giverPlace(step.questID)) or "", TEXT_COLOR end
  return L.ATTUNEMENT_OPEN, { ns.Theme.RGB("muted") }
end

local function addAttunement(tooltip, attunement)
  local title = string.format(L[TITLE_KEYS[attunement.kind]], ns.InstanceInfo.MapName(attunement.mapID),
    attunement.done, #attunement.steps)
  if ns.Client.IsForever() then title = title .. " " .. ns.UnverifiedHint.Mark() end
  if attunement.done == #attunement.steps then
    tooltip:AddDoubleLine(title, L.ATTUNEMENT_DONE, TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3], unpack(DONE_COLOR))
    return
  end
  tooltip:AddLine(title, unpack(TITLE_COLOR))
  local shown, open = 0, 0
  for _, step in ipairs(attunement.steps) do
    if step.status ~= "done" then
      open = open + 1
      if shown < MAX_STEP_LINES then
        shown = shown + 1
        local text, color = stepStatus(step, shown == 1)
        tooltip:AddDoubleLine(ns.DungeonQuests.Title(step.questID), text, TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3],
          color[1], color[2], color[3])
      end
    end
  end
  if open > shown then tooltip:AddLine(string.format(L.DUNGEON_QUESTS_MORE, open - shown), ns.Theme.RGB("muted")) end
end

-- Schlüssel- und Einstimmungsreihen am Eingang der Instanz an den Tooltip hängen (offene Schritte mit Stand, erledigte
-- nur gezählt); im Forever-Client mit dem Hinweis "für Forever unbestätigt"
function Attunements.AddLines(tooltip, mapID)
  local attunements = Attunements.At(mapID)
  for _, attunement in ipairs(attunements) do addAttunement(tooltip, attunement) end
  if #attunements > 0 and ns.Client.IsForever() then ns.UnverifiedHint.AddLine(tooltip) end
end
