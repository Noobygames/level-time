-- "Quest fertig" als Einblendung (Roadmap 343, Einstellungen alertQuestComplete und alertQuestObjective im Reiter
-- Einblendungen, aus): wird eine Quest abgabebereit (QuestLog.Entry().ready: Retail/Forever
-- C_QuestLog.ReadyForTurnIn, Classic isComplete), Karte mit Questname und Belohnungs-XP (QuestLog.RewardXp) und Ton
-- (alertSound); optional auch je erfülltem Ziel, außer wenn damit alle Ziele erfüllt sind (dann folgt "Quest fertig").
-- Im Kampf zurückgehalten und danach gezeigt. Stand und Änderungen liefert Tracking/QuestWatch.lua; der erste Durchlauf
-- nach Login zählt nur den Stand.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    alertQuestComplete = false,
    alertQuestObjective = false,
  },
})
local L = ns.L
local QuestLog = ns.QuestLog
local Alerts = ns.Alerts

local QuestCompleteAlert = {}
ns.QuestCompleteAlert = QuestCompleteAlert

-- Zweite Zeile der Karte: "+1.250 XP"; nil, wenn der Client keine XP nennt
function QuestCompleteAlert.Body(questID)
  local xp = QuestLog.RewardXp(questID)
  if not xp or xp <= 0 then return nil end
  return string.format(L.QUEST_COMPLETE_XP, ns.Format.Number(xp))
end

ns.QuestWatch.Subscribe({
  enabled = function(db) return db.alertQuestComplete or db.alertQuestObjective end,
  onReady = function(quest)
    ns.Debug("quests", "quest ready: %s", quest.questID)
    Alerts.Raise("questComplete", quest.title or L.UNKNOWN_NAME, QuestCompleteAlert.Body(quest.questID))
  end,
  onObjective = function(quest, objective, old)
    if not (objective.finished and old.finished == false and objective.text) then return end
    if ns.db.alertQuestComplete and QuestLog.AllFinished(quest.questID) then return end
    Alerts.Raise("questObjective", objective.text, quest.title)
  end,
})
