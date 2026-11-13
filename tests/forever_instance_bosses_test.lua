-- Roadmap 483 in WoW Forever: Bossliste aus ns.BossData, Kill über ENCOUNTER_END
local Bosses = addon.InstanceBosses

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local run = addon.Instances.GetCurrentRun()
local list = Bosses.List(36, 1)
expectTrue("Forever kennt die Bosse", list ~= nil and #list > 0)
wow.fire("ENCOUNTER_END", list[1], "Boss", 1, 5, 1)
expect("Kill gezählt", Bosses.ProgressText(run), "1/" .. #list)
expect("keine Lua-Fehler", #wow.errors, 0)
