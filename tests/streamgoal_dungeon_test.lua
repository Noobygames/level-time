-- Level Time Goals, Roadmap 302: Bosse besiegen (ENCOUNTER_END mit Erfolg), optional bestimmter Boss und Instanz.
local Goals = streamGoal.Goals
local L = streamGoal.L

wow.login({ level = 20 })

SlashCmdList.STREAMGOAL("add boss 2")
local any = Goals.Active()[1]
expect("Boss-Art", any.kind, "dungeon")
expect("Titel", Goals.Title(any), string.format(L.SG_GOAL_BOSS_ANY, 2))
SlashCmdList.STREAMGOAL("add boss 1 Bazzalan")
local named = Goals.Active()[2]
expect("bestimmter Boss", named.params.boss, "Bazzalan")

SlashCmdList.STREAMGOAL("")
local Manager = streamGoal.Manager
Manager.SelectKind("dungeon")
Manager.FormWidget("amount"):SetText("1")
Manager.FormWidget("instance"):SetText("Todesmine")
local inMine = Manager.AddFromForm()
StreamGoalWindow:Hide()
expect("Instanz", inMine.params.instance, "Todesmine")
expect("Zeile Instanz", Goals.Body(inMine), string.format(L.SG_DUNGEON_IN, "Todesmine"))

wow.state.instance = { name = "Ragefireabgrund", type = "party" }
wow.fire("ENCOUNTER_END", 2001, "Oggleflint", 1, 5, 0)
expect("Wipe zählt nicht", any.progress, 0)
wow.fire("ENCOUNTER_END", 2001, "Oggleflint", 1, 5, 1)
expect("Sieg zählt", any.progress, 1)
expect("anderer Boss zählt nicht für Bazzalan", named.progress, 0)
expect("andere Instanz zählt nicht", inMine.progress, 0)
wow.fire("ENCOUNTER_END", 2002, "Bazzalan", 1, 5, 1)
expect("alle Bosse erreicht", any.status, Goals.DONE)
expect("Bazzalan erreicht", named.status, Goals.DONE)

wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("ENCOUNTER_END", 2003, "Rhahk'Zor", 1, 5, 1)
expect("Todesmine erreicht", inMine.status, Goals.DONE)

-- Fertiges Paket Dungeon-Tour
SlashCmdList.STREAMGOAL("pack dungeons")
expect("Paket mit Boss-Ziel", Goals.Active()[1].kind, "dungeon")
