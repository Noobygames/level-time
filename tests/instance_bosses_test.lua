-- Roadmap 483 in Retail: keine Bossliste (shortcut), nur die Zahl der Kills aus ENCOUNTER_END
local Bosses = addon.InstanceBosses

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local run = addon.Instances.GetCurrentRun()
expect("Retail ohne Liste", Bosses.List(36, 1), nil)
expect("ohne Kill kein Text", Bosses.ProgressText(run), nil)
wow.fire("ENCOUNTER_END", 1144, "Glubtok", 1, 5, 1)
expect("Kill gezählt", Bosses.ProgressText(run), "1")
expect("ohne Liste kein Tooltip", Bosses.TooltipLines(run), nil)
expect("keine Lua-Fehler", #wow.errors, 0)
