-- LT-301, Classic Era: Dungeonquest-Schalter ja, aber nur die Schalter, deren Daten es in Era gibt
local L = addon.L
local Wizard = addon.SetupWizard
wow.login()
wow.runTimers()
expect("Assistent beim ersten Start", LevelTimerSetup:IsShown(), true)
local steps = Wizard.State().steps
expectTrue("Schritt Quest-Helfer", table.concat(steps, ","):find("quests", 1, true) ~= nil)
wow.click(L.SETUP_NEXT)
wow.click(L.SETUP_NEXT)
wow.click(L.SETUP_NEXT)
local first = Wizard.State().toggles[1]
expect("Era: Dungeonquest-Schalter", first:IsShown(), addon.DungeonQuests.IsAvailable())
expect("keine Fehler", #wow.errors, 0)
