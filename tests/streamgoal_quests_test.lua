-- Level Time Goals, Roadmap 296: Quests abgeben (Anzahl), bestimmte Quest, Kette in Reihenfolge.
local Goals = streamGoal.Goals
local L = streamGoal.L

local completed = { [300] = true }
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end

wow.login({ level = 20 })

local function turnIn(questID)
  completed[questID] = true
  wow.fire("QUEST_TURNED_IN", questID, 100, 0)
end

local function questLink(id, name)
  return "|cffffff00|Hquest:" .. id .. ":20|h[" .. name .. "]|h|r"
end

SlashCmdList.STREAMGOAL("add quest 3")
local countGoal = Goals.Active()[1]
expect("Anzahl", countGoal.params.mode, "count")
expect("Titel Anzahl", Goals.Title(countGoal), string.format(L.SG_GOAL_QUESTS, 3))

SlashCmdList.STREAMGOAL("add quest " .. questLink(101, "Wölfe jagen"))
local single = Goals.Active()[2]
expect("eine Quest", single.params.mode, "ids")
expect("Name aus dem Link", Goals.Title(single), string.format(L.SG_GOAL_QUEST, "Wölfe jagen"))
expect("ohne Zähler", Goals.HasCount(single), false)

wow.state.questTitles[201] = "Der Anfang"
SlashCmdList.STREAMGOAL("add quest 300 201 202 203")
local chain = Goals.Active()[3]
expect("Kette mit vier Quests", chain.target, 4)
expect("schon abgegebene zählt", chain.params.done[300], true)
expect("Stand 1 von vorn", chain.progress, 1)
expect("Titel Kette", Goals.Title(chain), string.format(L.SG_GOAL_QUEST_CHAIN, string.format(L.SG_QUEST_UNKNOWN, 300), 4))
expect("nächste Quest", Goals.Body(chain), string.format(L.SG_QUEST_NEXT, "Der Anfang"))

local goal, err = Goals.Create("quest", { mode = "ids", input = "300" })
expect("schon erledigt", goal, nil)
expect("Meldung erledigt", err, L.SG_ERR_ALREADY_REACHED)
expect("ohne IDs", select(2, Goals.Create("quest", { mode = "ids", input = "abc" })), L.SG_ERR_QUEST)

-- Außer der Reihe: 202 vor 201 zählt erst, wenn 201 erledigt ist
turnIn(202)
expect("Anzahl zählt jede Quest", countGoal.progress, 1)
expect("Kette wartet auf 201", chain.progress, 1)
turnIn(201)
expect("Kette springt auf 3", chain.progress, 3)
turnIn(101)
expect("einzelne Quest erreicht", single.status, Goals.DONE)
expect("Anzahl erreicht", countGoal.status, Goals.DONE)
turnIn(203)
expect("Kette erreicht", chain.status, Goals.DONE)
