-- Quest-Effizienz (Roadmap 347): Ø Dauer, Ø XP und XP/min je Quest über alle Charaktere, Tooltipzeile an Quest-Links.
local L = addon.L
local QuestEfficiency = addon.QuestEfficiency

wow.login({ level = 10 })
-- Zweiter Charakter mit derselben Quest
LevelTimerStatsDB.characters["Twink-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Twink", realm = "Testrealm", currentLevel = {},
  questLog = { { time = 1, questID = 7, name = "Eber", xp = 400, duration = 120 } },
}
local journal = addon.character.questLog
table.insert(journal, { time = 2, questID = 7, name = "Eber", xp = 600, duration = 240 })
table.insert(journal, { time = 3, questID = 8, name = "Ohne Zeit", xp = 100 })

local stat = QuestEfficiency.Of(7)
expect("zwei Abgaben", stat.count, 2)
expectNear("Ø Dauer", stat.averageSeconds, 180)
expectNear("Ø XP", stat.averageXp, 500)
expectNear("XP/min", stat.xpPerMinute, 500 / 3)
expect("ohne Dauer keine Rate", QuestEfficiency.Of(8).xpPerMinute, nil)

-- Tooltipzeile an Quest-Links
addon.Set("questEfficiencyTooltip", true)
GameTooltip:SetHyperlink("quest:7:10")
local lines = GameTooltip._lines or {}
expect("Tooltipzeile", lines[#lines], QuestEfficiency.Text(7))
expectTrue("Zeile nennt Rate", QuestEfficiency.Text(7):find(string.format(L.QUEST_EFFICIENCY_RATE, "167"), 1, true) ~= nil)
GameTooltip._lines = {}
GameTooltip:SetHyperlink("item:5")
expect("Item-Link: keine Zeile", #GameTooltip._lines, 0)

-- Historie: Unterreiter Effizienz
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Quests", wow.click(L.HISTORY_GROUP_ANALYSIS))
expectTrue("Unterreiter Effizienz", wow.click(L.HISTORY_TAB_QUEST_EFFICIENCY))
expect("zwei Quests", #wow.shownTable():GetVisibleRecords(), 2)
expect("Fehler?", #wow.errors, 0)
