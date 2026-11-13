-- Roadmap 483: Boss-Kills je Instanz-Lauf in Classic Era (ENCOUNTER_END, Fallback UNIT_DIED über den Bossnamen),
-- Bossliste aus ns.BossData, "abgeschlossen" beim Endboss, Bosse im Journal-Eintrag
local Bosses = addon.InstanceBosses
local Instances = addon.Instances

-- Todesminen (36): sieben Bosse, Rhahk'Zor zuerst, Edwin van Cleef (deDE) als Endboss
local list = Bosses.List(36, 1)
expect("Todesminen: sieben Bosse", #list, 7)
expect("erster Boss", list[1], 2741)
expect("Endboss", list[7], 2747)
expect("Name in Client-Sprache", Bosses.Name(2747), "Edwin van Cleef")
expect("unbekannte Karte", Bosses.List(1, 1), nil)
expect("Blackfathom: Liste je Schwierigkeit", #Bosses.List(48, 1), 7)

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local run = Instances.GetCurrentRun()
expect("ohne Kill: 0/7", Bosses.ProgressText(run), "0/7")

wow.fire("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 0)
expect("Wipe zählt nicht", run.bosses, nil)
wow.fire("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 1)
wow.fire("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 1)
expect("Sieg zählt einmal", run.bosses, "2741")

-- Fallback: Endboss stirbt ohne ENCOUNTER_END
local printedBefore = #wow.printed
wow.state.combatLog = { wow.state.now, "UNIT_DIED", false, "", "", 0, 0, "Creature-0-1-36-1-639-0", "Edwin van Cleef", 0, 0 }
wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
expect("Endboss über UNIT_DIED", run.bosses, "2741,2747")
expect("Fortschritt", Bosses.ProgressText(run), "2/7")
local done = false
for i = printedBefore + 1, #wow.printed do
  local line = wow.printed[i]
  if line:find("Die Todesminen abgeschlossen", 1, true) and line:find("2/7", 1, true) then done = true end
end
expectTrue("Abschluss gemeldet", done)
wow.fire("ENCOUNTER_END", 2747, "Edwin van Cleef", 1, 5, 1)
expect("ENCOUNTER_END danach doppelt nicht", run.bosses, "2741,2747")

-- Anderer Gegner stirbt: nichts
wow.state.combatLog = { wow.state.now, "UNIT_DIED", false, "", "", 0, 0, "Creature-0-1-36-1-1-0", "Defias-Schurke", 0, 0 }
wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
expect("kein Boss", run.bosses, "2741,2747")

-- Tooltip: Totenkopf für besiegte, Kopf für lebende Bosse, Position im Dungeon
local lines = Bosses.TooltipLines(run)
expect("Tooltip: Titel + sieben Bosse", #lines, 8)
expectTrue("Rhahk'Zor besiegt", lines[2]:find("Skull", 1, true) ~= nil and lines[2]:find("1. Rhahk'Zor", 1, true) ~= nil)
expectTrue("Sneed lebt", lines[3]:find("Head", 1, true) ~= nil)

-- Historie: laufender Lauf und beendeter Eintrag tragen die Bosse
expect("Historie laufender Lauf", addon.History.GetInstanceLog(addon.characterKey)[1].bosses, "2741,2747")
addon.Instances.ResetCurrent()
expect("Zurücksetzen leert die Bosse", run.bosses, nil)
wow.fire("ENCOUNTER_END", 2742, "Sneed", 1, 5, 1)
wow.state.instance = { name = "Burg Schattenfang", type = "party", difficulty = 1, mapID = 33, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local log = addon.character.instanceLog
expect("Journal-Eintrag mit Bossen", log[#log].bosses, "2742")

-- Draußen (Lauf angehalten) zählt nichts
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("ENCOUNTER_END", 2748, "Rethilgore", 1, 5, 1)
expect("angehalten: kein Kill", Instances.GetCurrentRun().bosses, nil)
expect("keine Lua-Fehler", #wow.errors, 0)
