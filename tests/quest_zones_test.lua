-- Quests je Zone (LT-261): erledigt (eigenes Journal oder Client-Flag), offen (nur andere eigene Charaktere), Ansicht.
local L = addon.L
local QuestZones = addon.QuestZones

local completed = { [9] = true }  -- vor der Aufzeichnung abgegeben
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end

wow.login({ level = 10 })
LevelTimerStatsDB.characters["Twink-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Twink", realm = "Testrealm", currentLevel = {},
  questLog = {
    { time = 1, questID = 7, name = "Eber", zone = "Westfall" },
    { time = 2, questID = 8, name = "Wölfe", zone = "Westfall" },
    { time = 3, questID = 9, name = "Alt", zone = "Wald von Elwynn" },
  },
}
table.insert(addon.character.questLog, { time = 4, questID = 7, name = "Eber", zone = "Westfall" })
table.insert(addon.character.questLog, { time = 5, questID = 10, name = "Nur ich", zone = "Dämmerwald" })

local function byQuest(records)
  local result = {}
  for _, record in ipairs(records) do result[record.questID] = record end
  return result
end

local records = byQuest(QuestZones.GetRecords(addon.characterKey))
expect("eigene Abgabe erledigt", records[7].done, true)
expectTrue("Twink kennt sie auch", records[7].othersText:find("Twink", 1, true) ~= nil)
expect("nur Twink: offen", records[8].done, false)
expect("Zone vom Twink", records[8].zone, "Westfall")
expect("Client-Flag zählt als erledigt", records[9].done, true)
expect("nur eigene: keine anderen", records[10].othersText, "")

-- Aus Sicht des Twinks: Flag des eingeloggten Charakters zählt nicht
local twink = byQuest(QuestZones.GetRecords("Twink-Testrealm"))
expect("Twink: eigene erledigt", twink[8].done, true)
expect("Twink: nur Hauptcharakter = offen", twink[10].done, false)

-- Historie: Unterreiter Quests je Zone
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Auswertung", wow.click(L.HISTORY_GROUP_ANALYSIS))
expectTrue("Unterreiter Quests je Zone", wow.click(L.HISTORY_TAB_QUEST_ZONES))
expect("vier Quests", #wow.shownTable():GetVisibleRecords(), 4)
expect("Fehler?", #wow.errors, 0)
