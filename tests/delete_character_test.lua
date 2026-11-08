-- Daten löschen: anderer Charakter verschwindet, eigener beginnt neu.
local Stats = addon.Stats

wow.login({ level = 57 })
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
local ownKey = addon.characterKey
wow.logout()
wow.login({ name = "Zweitchar", level = 10 })
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
expectTrue("Zweitchar gespeichert", LevelTimerStatsDB.characters["Zweitchar-Testrealm"] ~= nil)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Timeline", wow.click("Verlauf"))
expectTrue("Löschen-Knopf", wow.click("Daten löschen"))
expect("Rückfrage für eingeloggten Charakter", wow.popup.data, "Zweitchar-Testrealm")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("eigene Kills zurückgesetzt", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 0)
expect("eigene Session neu", Stats.Get(Stats.SESSION, Stats.PVE_KILLS), 0)
expect("Kill-Liste leer", #addon.character.killLog, 0)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
expect("zählt nach dem Löschen weiter", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 1)

addon.DeleteCharacter(ownKey)
expect("anderer Charakter gelöscht", LevelTimerStatsDB.characters[ownKey], nil)
expect("eingeloggter Charakter bleibt", LevelTimerStatsDB.characters["Zweitchar-Testrealm"] ~= nil, true)
