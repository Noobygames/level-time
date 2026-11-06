-- Questfortschritt an die Gruppe (Roadmap 264, Einstellung announceQuestProgress, Standard aus), wie Questie Announce:
-- angenommene Quests, je Ziel einmal, wenn es erfüllt ist ("Wölfe getötet: 8/8"), und die Quest, sobald alle Ziele
-- erfüllt sind. Ein Ziel oder eine Quest wird nur gemeldet, wenn vorher ein unvollständiger Stand gesehen wurde
-- (Schlüssel Quest-ID + Zielnummer): nach Login, /reload oder dem Einschalten zählt der erste Durchlauf nur den Stand.
-- Versand wie die Level-Up-Ansage über GroupChat (Gruppe/Instanz, nur in einer Gruppe); bei gesperrtem Chat
-- (GroupChat.Locked, z.B. Bosskampf) fällt die Meldung weg.
-- Quellen (Blizzard_APIDocumentationGenerated je Client):
--   Questlog  Lib/QuestLog.lua (Retail/Forever C_QuestLog.GetInfo, Classic GetQuestLogTitle). Unter eingeklappten
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
  for _, quest in ipairs(ns.QuestLog.Entries()) do update(quest) end
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
