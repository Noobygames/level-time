-- QuestWatch (Roadmap 373): eingelesen wird nur nach Questlog-Ereignissen, mehrere Ereignisse ergeben einen
-- Durchlauf, der Stand je Quest wird fortgeschrieben statt neu gebaut; Meldungen wie vorher
local QuestWatch = addon.QuestWatch

wow.state.questLog = {
  { title = "Elwynn", isHeader = true },
  { title = "Wölfe", questID = 80, objectives = { { text = "Wolf getötet: 1/5", numFulfilled = 1, numRequired = 5,
    finished = false, type = "monster" } } },
}
local events = {}
QuestWatch.Subscribe({
  enabled = function() return true end,
  onObjective = function(quest, objective, old)
    events[#events + 1] = string.format("%s %s->%s", quest.questID, old.have, objective.have)
  end,
  onComplete = function(quest) events[#events + 1] = "complete " .. quest.questID end,
})

wow.login({ level = 10 })
addon.ApplySettings()

local reads = { count = 0 }
local getObjectives = C_QuestLog.GetQuestObjectives
C_QuestLog.GetQuestObjectives = function(questID)
  reads.count = reads.count + 1
  return getObjectives(questID)
end

wow.update(0.5)
expect("erster Durchlauf liest einmal", reads.count, 1)
expect("erster Durchlauf meldet nichts", #events, 0)
for _ = 1, 20 do wow.update(0.5) end
expect("ohne Ereignis kein Durchlauf", reads.count, 1)

local objective = wow.state.questLog[2].objectives[1]
objective.numFulfilled, objective.text = 3, "Wolf getötet: 3/5"
wow.fire("QUEST_LOG_UPDATE")
wow.fire("UNIT_QUEST_LOG_CHANGED", "player")
wow.fire("QUEST_LOG_UPDATE")
wow.update(0.5)
expect("drei Ereignisse: ein Durchlauf", reads.count, 2)
expect("Anstieg gemeldet mit altem Stand", events[1], "80 1->3")

objective.numFulfilled, objective.text, objective.finished = 5, "Wolf getötet: 5/5", true
wow.fire("QUEST_LOG_UPDATE")
wow.update(0.5)
expect("erfüllt gemeldet", events[2], "80 3->5")
expect("Quest fertig", events[3], "complete 80")

wow.fire("QUEST_LOG_UPDATE")
wow.update(0.5)
expect("unverändert: keine neue Meldung", #events, 3)
C_QuestLog.GetQuestObjectives = getObjectives
