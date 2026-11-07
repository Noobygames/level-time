-- Eigene Splits: /lt split [Name], undo, Vorlage für neue Charaktere mit Vergleich Lauf gegen Lauf.
local CustomSplits = addon.CustomSplits
local L = addon.L

wow.login({ name = "Erster", level = 5, zone = "Elwynn", playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 1000, 0)
SlashCmdList.LEVELTIMER("split")
expect("Name = Zone", CustomSplits.GetAll()[1].name, "Elwynn")
expect("/played", CustomSplits.GetAll()[1].played, 1000)
wow.advance(500)
SlashCmdList.LEVELTIMER("split Hogger")
expect("eigener Name", CustomSplits.GetAll()[2].name, "Hogger")
expect("Zeit läuft mit", CustomSplits.GetAll()[2].played, 1500)
SlashCmdList.LEVELTIMER("split undo")
expect("undo", #CustomSplits.GetAll(), 1)
expectTrue("undo meldet", wow.printed[#wow.printed]:find(string.format(L.CUSTOM_SPLIT_UNDONE, "Hogger"), 1, true) ~= nil)
SlashCmdList.LEVELTIMER("split Hogger")
SlashCmdList.LEVELTIMER("split template")
expect("Vorlage", LevelTimerStatsDB.splitTemplate.names[2], "Hogger")
expect("eigene Vorlage ohne Abweichung", CustomSplits.GetDelta(2), nil)

-- Tastenbelegung ruft dasselbe wie /lt split ohne Namen
LevelTimer_CustomSplit()
expect("Taste setzt Split", #CustomSplits.GetAll(), 3)
expect("Beschriftung der Taste", BINDING_NAME_LEVELTIMER_CUSTOM_SPLIT, L.CUSTOM_SPLIT_BINDING)

-- Neuer Charakter: Namen aus der Vorlage, Abweichung je Position
wow.logout()
wow.login({ name = "Zweiter", level = 1, zone = "Durotar", playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 900, 0)
SlashCmdList.LEVELTIMER("split")
expect("Name aus der Vorlage", CustomSplits.GetAll()[1].name, "Elwynn")
expect("schneller als die Vorlage", CustomSplits.GetDelta(1), -100)
wow.advance(700)
SlashCmdList.LEVELTIMER("split")
expect("zweiter Name aus der Vorlage", CustomSplits.GetAll()[2].name, "Hogger")
expect("langsamer", CustomSplits.GetDelta(2), 100)
SlashCmdList.LEVELTIMER("split")
expect("nach der Vorlage die Zone", CustomSplits.GetAll()[3].name, "Durotar")

-- In der Split-Liste: die letzten drei
addon.Set("showWorldRecords", false)
addon.Set("splitListShowTotal", false)
addon.Set("splitListShowPlayed", false)
local lines = addon.SplitList.BuildFooterLines()
expect("drei Zeilen", #lines, 3)
expect("Abweichung", lines[2][3], addon.Format.SplitDelta(100))
