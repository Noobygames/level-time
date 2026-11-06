-- Questfortschritt an die Gruppe (Roadmap 264, Einstellung announceQuestProgress, Standard aus), wie Questie Announce:
-- angenommene Quests, je Ziel einmal, wenn es erfüllt ist ("Wölfe getötet: 8/8"), und die Quest, sobald alle Ziele
-- erfüllt sind. Ein Ziel oder eine Quest wird nur gemeldet, wenn vorher ein unvollständiger Stand gesehen wurde
-- (Schlüssel Quest-ID + Zielnummer): nach Login, /reload oder dem Einschalten zählt der erste Durchlauf nur den Stand.
-- Versand wie die Level-Up-Ansage über GroupChat (Gruppe/Instanz, nur in einer Gruppe); bei gesperrtem Chat
-- (GroupChat.Locked, z.B. Bosskampf) fällt die Meldung weg.
-- Quellen (Blizzard_APIDocumentationGenerated je Client):
--   Questlog  Retail/Forever C_QuestLog.GetNumQuestLogEntries + C_QuestLog.GetInfo(i) (questID, title, isHeader);
--             Classic Era/TBC GetNumQuestLogEntries + GetQuestLogTitle(i) (8. Rückgabe questID). Unter eingeklappten
--             Überschriften sieht Classic die Quests nicht; ihr letzter Stand bleibt gemerkt.
--   Ziele     C_QuestLog.GetQuestObjectives(questID) in allen Clients: { text, finished, numFulfilled, numRequired }
--   Ereignisse QUEST_LOG_UPDATE (neu einlesen, gebündelt alle SCAN_SECONDS), QUEST_ACCEPTED (Era: questIndex,
--             questID; Retail/Forever: questID, daher das letzte Argument), QUEST_REMOVED/QUEST_TURNED_IN (vergessen)
local _, ns = ...
local L = ns.L
local GroupChat = ns.GroupChat

local QuestProgress = {}
ns.QuestProgress = QuestProgress

local SCAN_SECONDS = 0.5

local states = {}    -- [questID] = { finished = { [ziel] = true/false }, complete = true/false }
local accepted = {}  -- angenommene Quests, die beim nächsten Einlesen gemeldet werden
local seen = false   -- erster Durchlauf seit Login/Einschalten erledigt
local dirty = true

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Quests im Log: Liste von { questID, title }
local function questLog()
  local quests = {}
  local function add(questID, title, isHeader)
    questID, title = readable(questID), readable(title)
    if not readable(isHeader) and type(questID) == "number" and questID ~= 0 then
      table.insert(quests, { questID = questID, title = title })
    end
  end
  if C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for index = 1, (C_QuestLog.GetNumQuestLogEntries()) or 0 do
      local info = C_QuestLog.GetInfo(index)
      if info then add(info.questID, info.title, info.isHeader) end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for index = 1, (GetNumQuestLogEntries()) or 0 do
      local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
      add(questID, title, isHeader)
    end
  end
  return quests
end

local function announce(text)
  local chatType = GroupChat.PartyChannel()
  if not chatType then return end
  if GroupChat.Locked() then
    ns.Debug("announce", "quest progress skipped (chat lockdown): %s", text)
    return
  end
  ns.Debug("announce", "quest progress: %s", text)
  GroupChat.Send(text, chatType)
end

-- Stand einer Quest einlesen und Änderungen gegenüber dem letzten Stand melden
local function update(quest)
  local questID, title = quest.questID, quest.title or ""
  local old = seen and states[questID] or nil
  local objectives = C_QuestLog.GetQuestObjectives(questID) or {}
  local state = { finished = {}, complete = #objectives > 0 }
  for index, objective in ipairs(objectives) do
    local finished, text = readable(objective.finished), readable(objective.text)
    if finished == nil then
      state.complete = false
    else
      state.finished[index] = finished
      state.complete = state.complete and finished
      if old and old.finished[index] == false and finished and text then
        announce(string.format(L.QUEST_PROGRESS_OBJECTIVE, title, text))
      end
    end
  end
  if accepted[questID] then
    accepted[questID] = nil
    announce(string.format(L.QUEST_PROGRESS_ACCEPTED, title))
  end
  if old and old.complete == false and state.complete then
    announce(string.format(L.QUEST_PROGRESS_COMPLETE, title))
  end
  states[questID] = state
end

function QuestProgress.Scan()
  if not ns.db.announceQuestProgress or not dirty then return end
  dirty = false
  for _, quest in ipairs(questLog()) do update(quest) end
  seen = true
end

local function reset()
  states, accepted, seen, dirty = {}, {}, false, true
end

ns.RegisterEvent("QUEST_LOG_UPDATE", function() dirty = true end)

ns.RegisterEvent("QUEST_ACCEPTED", function(...)
  local questID = readable((select(select("#", ...), ...)))
  if seen and type(questID) == "number" then accepted[questID] = true end
  dirty = true
end)

local function forget(questID)
  questID = readable(questID)
  if questID then states[questID], accepted[questID] = nil, nil end
end
ns.RegisterEvent("QUEST_REMOVED", forget)
ns.RegisterEvent("QUEST_TURNED_IN", forget)

-- Ausgeschaltet nichts merken; beim Einschalten zählt der erste Durchlauf nur den Stand
ns.RegisterApply(function(db)
  if not db.announceQuestProgress then reset() end
end)

ns.Every(SCAN_SECONDS, QuestProgress.Scan)
ns.OnLogin(reset)
