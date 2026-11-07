-- Roadmap 363: Willkommenskarte beim ersten Start (Voreinstellung, Layout, Edit-Modus), danach nur über /lt welcome
local L = addon.L

wow.login()
expect("Karte beim ersten Start", LevelTimerWelcome:IsShown(), true)
expect("Titel", LevelTimerWelcome ~= nil and addon.WelcomeCard.IsShown(), true)
expect("erster Start gemerkt", LevelTimerStatsDB.introShown, true)

-- Voreinstellung und Layout wirken sofort
expectTrue("Voreinstellung Minimal", wow.click(L.PRESET_MINIMAL))
expect("Minimal: Tode aus", LevelTimerDB.showDeaths, false)
local layout = addon.WindowLayouts.Get("tiles")
expectTrue("Layout Kacheln", wow.click(L[layout.label], true))
expect("Layout gesetzt", LevelTimerDB.windowLayout, "tiles")

-- Position anpassen: Karte zu, Edit-Modus an
expectTrue("Position anpassen", wow.click(L.WELCOME_EDIT_MODE))
expect("Karte zu", LevelTimerWelcome:IsShown(), false)
expect("Edit-Modus an", addon.EditMode.IsActive(), true)
addon.EditMode.Leave()

-- Zweiter Login: keine Karte; /lt welcome zeigt sie wieder
wow.logout()
wow.login()
expect("kein zweites Mal", LevelTimerWelcome:IsShown(), false)
SlashCmdList.LEVELTIMER("welcome")
expect("/lt welcome", LevelTimerWelcome:IsShown(), true)
expectTrue("Fertig", wow.click(L.WELCOME_DONE, true))  -- "Fertig" hat auch der Edit-Modus
expect("zu", LevelTimerWelcome:IsShown(), false)

expect("keine Fehler", #wow.errors, 0)
