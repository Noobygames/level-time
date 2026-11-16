-- Level Time Goals in Classic Era (LT-266): Quests nach ID zeigen den Titel aus C_QuestLog.GetQuestInfo, weil Era
-- kein C_QuestLog.GetTitleForQuestID kennt.
local Goals = streamGoal.Goals
local L = streamGoal.L

C_QuestLog.IsQuestFlaggedCompleted = function() return false end
expect("Era ohne GetTitleForQuestID", C_QuestLog.GetTitleForQuestID, nil)

wow.login({ level = 20 })

wow.state.questTitles[201] = "Der Anfang"
SlashCmdList.STREAMGOAL("add quest 201 202")
local chain = Goals.Active()[1]
expect("Titel aus GetQuestInfo", Goals.Title(chain), string.format(L.SG_GOAL_QUEST_CHAIN, "Der Anfang", 2))
expect("nächste Quest", Goals.Body(chain), string.format(L.SG_QUEST_NEXT, "Der Anfang"))
expect("Fallback #ID", addon.QuestLog.Title(202), nil)
