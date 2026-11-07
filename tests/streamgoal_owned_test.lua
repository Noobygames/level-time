-- Level Time Goals, Roadmap 298: Items besitzen (Bestand in den Taschen, jede Herkunft, Verkauf senkt den Stand).
local Goals = streamGoal.Goals
local L = streamGoal.L

local LINEN = "|cffffffff|Hitem:2589::::::::20:::::|h[Leinenstoff]|h|r"
wow.state.itemCounts = { [2589] = 4 }
wow.login({ level = 20 })

local function setCount(count)
  wow.state.itemCounts[2589] = count
  wow.fire("BAG_UPDATE_DELAYED")
end

SlashCmdList.STREAMGOAL("add owned " .. LINEN .. " 20")
local goal = Goals.Active()[1]
expect("Besitz-Art", goal.kind, "owned")
expect("Item aus dem Link", goal.params.itemId, 2589)
expect("Bestand beim Anlegen", goal.progress, 4)
expect("Titel", Goals.Title(goal), string.format(L.SG_GOAL_OWNED, LINEN, 20))
expect("Karte zeigt Bestand", StreamGoalCard1.time._text, "4 / 20")

setCount(12)
expect("gekauft oder gelootet", goal.progress, 12)
setCount(9)
expect("verkauft senkt", goal.progress, 9)

SlashCmdList.STREAMGOAL("add owned 2589 3")
expect("schon genug: kein Ziel", #Goals.Active(), 1)
SlashCmdList.STREAMGOAL("add owned 2589 30 bank")
expect("mit Bank", Goals.Active()[2].params.bank, true)
expect("Zeile Bank", Goals.Body(Goals.Active()[2]), L.SG_WITH_BANK)

setCount(20)
expect("erreicht", goal.status, Goals.DONE)
