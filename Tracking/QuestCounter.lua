-- Zählt abgegebene Quests und die XP daraus und schreibt jede Quest ins Journal.
-- Name: C_QuestLog.GetTitleForQuestID, wo vorhanden; sonst der Titel aus dem Quest-Fenster,
-- der bei QUEST_COMPLETE (Abgabe-Dialog offen) gemerkt wird.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showQuests = false,
  },
  counters = {
    quests = 0,
  },
})
local Stats = ns.Stats
local Journal = ns.Journal

local PENDING_TITLE_MAX_AGE = 60  -- Sekunden; ein verworfener Dialog soll keiner späteren Quest den Titel geben
local pendingTitle  -- Titel der Quest im offenen Abgabe-Dialog
local pendingTitleAt

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function questName(questID)
  local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
  local fresh = pendingTitleAt and GetTime() - pendingTitleAt <= PENDING_TITLE_MAX_AGE
  return readable(title) or (fresh and pendingTitle or nil)
end

ns.RegisterEvent("QUEST_COMPLETE", function()
  pendingTitle = GetTitleText and readable(GetTitleText()) or nil
  pendingTitleAt = GetTime()
end)

ns.RegisterEvent("QUEST_TURNED_IN", function(questID, xpReward, moneyReward)
  xpReward, moneyReward = readable(xpReward), readable(moneyReward)
  Stats.Increment(Stats.QUESTS)
  if xpReward then
    Stats.Increment(Stats.XP_QUESTS, xpReward)
  end
  Journal.AddQuest(questID, questName(questID), xpReward, moneyReward)
  pendingTitle = nil
end)
