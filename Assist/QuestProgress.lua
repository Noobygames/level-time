-- Questfortschritt an die Gruppe (Roadmap 264, Einstellung announceQuestProgress, Standard aus), wie Questie Announce:
-- angenommene Quests, je Ziel einmal, wenn es erfüllt ist ("Wölfe getötet: 8/8"), und die Quest, sobald alle Ziele
-- erfüllt sind. Ein Ziel oder eine Quest wird nur gemeldet, wenn vorher ein unvollständiger Stand gesehen wurde:
-- nach Login, /reload oder dem Einschalten zählt der erste Durchlauf nur den Stand.
-- Versand wie die Level-Up-Ansage über GroupChat (Gruppe/Instanz, nur in einer Gruppe); bei gesperrtem Chat
-- (GroupChat.Locked, z.B. Bosskampf) fällt die Meldung weg.
-- Die Quest steht als Link in der Meldung (anklickbar für die Gruppe): GetQuestLink(questID) gibt es auf Retail, Classic
-- Era und Forever (Blizzard: ChatFrameUtil.TryInsertQuestLinkForQuestID); ohne Link (nicht geladen) der Titel.
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
  GroupChat.SendWithLinks(text, chatType)
end

local function title(quest)
  local link = GetQuestLink and quest.questID and GetQuestLink(quest.questID)
  if type(link) == "string" and not ns.IsSecret(link) and link ~= "" then return link end
  return ns.Format.PlainText(quest.title)
end

local Plain = ns.Format.PlainText

ns.QuestWatch.Subscribe({
  enabled = function(db) return db.announceQuestProgress end,
  onObjective = function(quest, objective, old)
    if objective.finished and old.finished == false and objective.text then
      announce(string.format(L.QUEST_PROGRESS_OBJECTIVE, title(quest), Plain(objective.text)))
    end
  end,
  onAccepted = function(quest) announce(string.format(L.QUEST_PROGRESS_ACCEPTED, title(quest))) end,
  onComplete = function(quest) announce(string.format(L.QUEST_PROGRESS_COMPLETE, title(quest))) end,
})
