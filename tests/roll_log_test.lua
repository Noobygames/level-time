-- Wurf-Historie (RollLog.lua): jeder abgeschlossene Gruppen-Wurf landet im Journal-Log rollLog (Gewinner, alle
-- gepasst, Gewinner unbekannt), allein nichts; Historie > Journal > Würfe zeigt die Zeilen mit Filter.
local L = addon.L
local LootRolls, RollLog, Journal = addon.LootRolls, addon.RollLog, addon.Journal

local SWORD = "|cnIQ4:|Hitem:777::::::::70:::::|h[Klinge des Sturms]|h|r"
local HELM = "|cnIQ3:|Hitem:888::::::::70:::::|h[Helm der Flut]|h|r"
local NEED, GREED, PASS = 0, 3, 5

wow.login({ inGroup = true, groupSize = 3, realm = "Testrealm",
  units = { party1 = { name = "Grimbar", class = "MAGE", isPlayer = true } } })
expectTrue("Standard an", addon.db.lootRollHistory)
expect("Quelle", LootRolls.HistorySource(), "drops")
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, difficultyName = "Normal" }

-- Gewinner aus der Historie: Klasse, Wurf, Wahlen, eigene Wahl und Instanz
wow.state.lootRolls = { [7] = { link = SWORD, quality = 4 }, [8] = { link = HELM } }
wow.fire("START_LOOT_ROLL", 7, 120000)
wow.state.lootDrops = { ["100:1"] = { itemHyperlink = SWORD, winner = { playerName = "Grimbar", roll = 99 },
  rollInfos = {
    { playerName = "Testchar", playerClass = "WARRIOR", state = GREED, roll = 55 },
    { playerName = "Grimbar", playerClass = "MAGE", state = NEED, roll = 99, isWinner = true },
    { playerName = "Lyra-Anderswo", playerClass = "WARRIOR", state = PASS },
  } } }
wow.state.encounterNames = { [100] = "Arugal" }
wow.fire("LOOT_HISTORY_UPDATE_DROP", 100, 1)
local log = addon.character.rollLog
expect("ein Eintrag", #log, 1)
local entry = log[1]
expect("Link", entry.link, SWORD)
expect("Item-ID", entry.itemId, 777)
expect("Gewinner", entry.winner, "Grimbar")
expect("Klasse", entry.winnerClass, "MAGE")
expect("Wurf", entry.winnerRoll, 99)
expect("Wahl", entry.winnerChoice, "need")
expect("Bedarf/Gier/Passen", entry.need .. "/" .. entry.greed .. "/" .. entry.pass, "1/1/1")
expect("eigene Wahl", entry.ownChoice, "greed")
expect("eigener Wurf", entry.ownRoll, 55)
expect("Instanz", entry.instance, "Die Todesminen")
expect("Schwierigkeit", entry.difficulty, "Normal")
expect("Begegnung (C_LootHistory.GetInfoForEncounter)", entry.encounter, "Arugal")
expect("nicht alle gepasst", entry.allPassed, nil)

-- Alle gepasst
wow.fire("START_LOOT_ROLL", 8, 120000)
wow.state.encounterDrops = { [100] = { { lootListID = 2, itemHyperlink = HELM } } }
wow.state.lootDrops["100:2"] = { itemHyperlink = HELM, allPassed = true, rollInfos = {
  { playerName = "Testchar", playerClass = "WARRIOR", state = PASS },
  { playerName = "Grimbar", playerClass = "MAGE", state = PASS },
} }
wow.fire("LOOT_HISTORY_UPDATE_ENCOUNTER", 100)
expect("zweiter Eintrag", #log, 2)
expect("alle gepasst", log[2].allPassed, 1)
expect("ohne Gewinner", log[2].winner, nil)

-- Gewinner unbekannt (z.B. geheime Gewinnerzeile): Eintrag ohne Gewinner und ohne "alle gepasst"
local unknown = RollLog.EntryOf({ link = HELM, itemId = 888, choices = {}, order = {}, rolls = {}, classes = {},
  completed = true, groupSize = 3 })
expect("unbekannt: kein Gewinner", unknown.winner, nil)
expect("unbekannt: nicht gepasst", unknown.allPassed, nil)
Journal.AddRoll(unknown)

-- Allein: nichts aufzeichnen
wow.state.inGroup = false
wow.state.lootRolls[9] = { link = SWORD }
wow.fire("START_LOOT_ROLL", 9, 120000)
wow.state.lootDrops["101:1"] = { itemHyperlink = SWORD, winner = { playerName = "Testchar", roll = 12 },
  rollInfos = { { playerName = "Testchar", playerClass = "WARRIOR", state = NEED, roll = 12 } } }
wow.fire("LOOT_HISTORY_UPDATE_DROP", 101, 1)
expect("allein kein Eintrag", #log, 3)
wow.state.inGroup = true

-- Aus: nichts aufzeichnen
addon.Set("lootRollHistory", false)
addon.Set("lootRollCounts", true)
wow.state.lootRolls[10] = { link = SWORD }
wow.fire("START_LOOT_ROLL", 10, 120000)
wow.state.lootDrops["102:1"] = { itemHyperlink = SWORD, winner = { playerName = "Grimbar", roll = 40 },
  rollInfos = { { playerName = "Grimbar", playerClass = "MAGE", state = NEED, roll = 40 } } }
wow.fire("LOOT_HISTORY_UPDATE_DROP", 102, 1)
expect("aus: kein Eintrag", #log, 3)

-- Ansicht: Historie > Journal > Würfe
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Journal", wow.click(L.HISTORY_GROUP_JOURNAL))
expectTrue("Unterreiter Würfe", wow.click(L.HISTORY_TAB_ROLLS))
local view = wow.shownTable()
expect("drei Zeilen", #view:GetVisibleRecords(), 3)
local csv = view:BuildCsv()
expectTrue("Gewinner", csv:find("Grimbar", 1, true) ~= nil)
expectTrue("alle gepasst", csv:find(L.HISTORY_ROLL_ALL_PASSED, 1, true) ~= nil)
expectTrue("Gewinner unbekannt", csv:find(L.HISTORY_ROLL_UNKNOWN, 1, true) ~= nil)
expectTrue("Ort mit Schwierigkeit", csv:find("Die Todesminen (Normal)", 1, true) ~= nil)
expectTrue("Gewinner in Klassenfarbe", addon.LootRollReport.ClassColoredName("MAGE", "Grimbar"):find("|cff", 1, true) == 1)
view:SetFilter("Grimbar")
expect("Filter", #view:GetVisibleRecords(), 1)
view:SetFilter("")
expect("keine Lua-Fehler", #wow.errors, 0)
