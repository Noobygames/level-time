-- Questfortschritt an die Gruppe (Roadmap 264, Einstellung announceQuestProgress, Standard aus), wie Questie Announce:
-- angenommene Quests, je Ziel einmal, wenn es erfüllt ist ("Wölfe getötet: 8/8"), und die Quest, sobald alle Ziele
-- erfüllt sind. Ein Ziel oder eine Quest wird nur gemeldet, wenn vorher ein unvollständiger Stand gesehen wurde:
-- nach Login, /reload oder dem Einschalten zählt der erste Durchlauf nur den Stand.
-- Versand wie die Level-Up-Ansage über GroupChat (Gruppe/Instanz, nur in einer Gruppe); bei gesperrtem Chat
-- (GroupChat.Locked, z.B. Bosskampf) fällt die Meldung weg.
-- Stand und Änderungen liefert Tracking/QuestWatch.lua (ein gemeinsames Einlesen für alle Quest-Funktionen).
local _, ns = ...
local L = ns.L
local GroupChat = ns.GroupChat

local QuestProgress = {}
ns.QuestProgress = QuestProgress

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

local function title(quest)
  return quest.title or ""
end

ns.QuestWatch.Subscribe({
  enabled = function(db) return db.announceQuestProgress end,
  onObjective = function(quest, objective, old)
    if objective.finished and old.finished == false and objective.text then
      announce(string.format(L.QUEST_PROGRESS_OBJECTIVE, title(quest), objective.text))
    end
  end,
  onAccepted = function(quest) announce(string.format(L.QUEST_PROGRESS_ACCEPTED, title(quest))) end,
  onComplete = function(quest) announce(string.format(L.QUEST_PROGRESS_COMPLETE, title(quest))) end,
})
