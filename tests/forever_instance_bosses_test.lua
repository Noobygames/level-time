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

-- Roadmap 493: optionale Rar-Bosse (Versunkene Stadt: Urtümlicher Elementar 3511) zählen nicht zum Fortschritt und
-- sind nie Endboss; abgeschlossen ist der Lauf, wenn der Endboss fällt
expectTrue("3511 ist ein Rar-Boss", Bosses.IsRare(3511))
expectTrue("Endboss kein Rar-Boss", not Bosses.IsRare(3479))
expect("Endboss der Versunkenen Stadt", Bosses.EndBoss(Bosses.List(2970, 1)), 3479)
wow.state.instance = { name = "Versunkene Stadt", type = "party", difficulty = 1, mapID = 2970, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
run = addon.Instances.GetCurrentRun()
expect("ohne Kill: 0/5", Bosses.ProgressText(run), "0/5")
wow.fire("ENCOUNTER_END", 3511, "Rar", 1, 5, 1)
expect("Rar-Boss zählt nicht zum Fortschritt", Bosses.ProgressText(run), "0/5")
expect("ein Rar-Boss besiegt", Bosses.RaresKilled(run), 1)
for _, id in ipairs({ 3474, 3475, 3476, 3478 }) do wow.fire("ENCOUNTER_END", id, "Boss", 1, 5, 1) end
expectTrue("ohne Endboss nicht abgeschlossen", not addon.InstanceRuns.IsCompleted(run))
wow.fire("ENCOUNTER_END", 3479, "Boss", 1, 5, 1)
expect("alle nötigen Bosse", Bosses.ProgressText(run), "5/5")
expectTrue("abgeschlossen", addon.InstanceRuns.IsCompleted(run))
addon.InstanceRunWindow.Show()
local parts = addon.InstanceRunWindow.Parts()
expectTrue("Kachel Bosse: +1 Rar", parts.tiles[5].note:GetText():find(string.format(addon.L.DUNGEON_RUNS_RARES, 1), 1, true) ~= nil)
expectTrue("Bosstabelle markiert den Rar-Boss", parts.bossRows[5].cells[1]:GetText():find(addon.L.DUNGEON_RUNS_RARE_TAG, 1, true) ~= nil)
expect("keine Lua-Fehler", #wow.errors, 0)
