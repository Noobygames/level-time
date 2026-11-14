-- Roadmap 483 in WoW Forever: Bossliste aus ns.BossData, Kill über ENCOUNTER_END
local Bosses = addon.InstanceBosses

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local run = addon.Instances.GetCurrentRun()
local list = Bosses.List(36, 1)
expectTrue("Forever kennt die Bosse", list ~= nil and #list > 0)
wow.fire("ENCOUNTER_END", list[1], "Boss", 1, 5, 1)
expect("Kill gezählt", Bosses.ProgressText(run), "1/7")  -- 8 Bosse, Miner Johnson ist Rar

-- ForeverDungeonJournal-Aliase: alte Encounter-ID (Todesminen 162 = Sneed 2742) zählt für den Listeneintrag
expect("Alias-Name", Bosses.Name(162), Bosses.Name(2742))
expect("Name eines Bosses ohne BossData-Eintrag", Bosses.Name(277), "Solakar Flamewreath")
wow.fire("ENCOUNTER_END", 162, "Sneed", 1, 5, 1)
expect("Alias zählt zum Fortschritt", Bosses.ProgressText(run), "2/7")
expect("als Listeneintrag gespeichert", run.bosses, list[1] .. ",2742")
expect("Split zum Alias-Kill", addon.InstanceRuns.Splits(run)[2742] ~= nil, true)
wow.fire("ENCOUNTER_END", 2742, "Sneed", 1, 5, 1)
expect("Alias und Listen-ID zählen einmal", Bosses.ProgressText(run), "2/7")
expect("Rar-Boss der Todesminen (Miner Johnson) zählt nicht", Bosses.IsRare(3676), true)

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
-- Rare ohne Encounter (Gill, NPC 264177): Erkennung über die NPC-ID, Name beim Kill, nie Fortschritt
wow.advance(30)
wow.combatLog("UNIT_DIED", "", "Creature-0-1-2970-1-99999-0")
expect("unbekannte NPC-ID ist kein Rare", run.rares, nil)
wow.state.combatLog = { wow.state.now, "UNIT_DIED", false, "", "", 0, 0, "Creature-0-1-2970-1-264177-00001", "Kiemling", 0, 0 }
wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
local rares = Bosses.Rares(run)
expect("ein Rare eingetragen (einmal)", #rares, 1)
expect("Rare: NPC-ID", rares[1].npcID, 264177)
expect("Rare: Name beim Kill", rares[1].name, "Kiemling")
expect("Rare: englischer Rückfall-Name", Bosses.RareNpcName(2970, 260468), "\"Pyromancer\" Braxton")
expect("Rare zählt nicht zum Fortschritt", Bosses.ProgressText(run), "5/5")
expect("Rar-Boss und Rare", Bosses.RaresKilled(run), 2)
expect("Rare verschieben", Bosses.ShiftRares("264177:5:Gill;264172:7", 10), "264177:15:Gill;264172:17")
addon.InstanceRunWindow.Show()
local parts = addon.InstanceRunWindow.Parts()
expectTrue("Kachel Bosse: +2 Rar", parts.tiles[5].note:GetText():find(string.format(addon.L.DUNGEON_RUNS_RARES, 2), 1, true) ~= nil)
expectTrue("Bosstabelle zeigt den Rare", parts.bossRows[7].cells[1]:GetText():find("Kiemling", 1, true) ~= nil)
expectTrue("Bosstabelle markiert den Rar-Boss", parts.bossRows[5].cells[1]:GetText():find(addon.L.DUNGEON_RUNS_RARE_TAG, 1, true) ~= nil)
expect("keine Lua-Fehler", #wow.errors, 0)
