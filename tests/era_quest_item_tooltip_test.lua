-- Quest-Gegenstand im Tooltip (Roadmap 349): offene Quest mit Stand aus gelernten Daten oder dem Zieltext,
-- "Quest erledigt – verkaufbar" für Gegenstände abgegebener Quests.
local L = addon.L
local QuestItemTooltip = addon.QuestItemTooltip

local pelts = { text = "Wolfspelz: 3/8", finished = false, type = "item" }
wow.state.questLog = {
  { title = "Wald", isHeader = true },
  { questID = 50, title = "Pelze", objectives = { pelts, { text = "Wolf getötet: 1/5", finished = false, type = "monster" } } },
}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return questID == 40 end

wow.login({ level = 10 })
-- Gelernt: Gegenstand 7000 gehört zur abgegebenen Quest 40, 7100 zu Quest 50
LevelTimerStatsDB.questMobs = {
  [40] = { [1] = { mobs = {}, items = { [6000] = 3 }, itemNames = { [6000] = "Altes Zahnrad" } } },
  [50] = { [1] = { mobs = {}, items = { [7100] = 2 }, itemNames = { [7100] = "Pelzstück" } } },
}
wow.fire("QUEST_LOG_UPDATE")

expect("gelernt: offene Quest mit Stand", QuestItemTooltip.Line(7100, "Pelzstück"), string.format(L.QUEST_ITEM_FOR_QUEST, "Pelze (3/8)"))
expect("aus dem Zieltext", QuestItemTooltip.Line(7200, "Wolfspelz"), string.format(L.QUEST_ITEM_FOR_QUEST, "Pelze (3/8)"))
expect("Tötungsziel zählt nicht", QuestItemTooltip.Line(7300, "Wolf getötet"), nil)
expect("abgegeben: verkaufbar", QuestItemTooltip.Line(6000, "Altes Zahnrad"), L.QUEST_ITEM_DONE)
expect("fremder Gegenstand", QuestItemTooltip.Line(9999, "Leinenstoff"), nil)

-- Tooltip: OnTooltipSetItem (Classic) hängt die Zeile an
addon.Set("questItemTooltip", true)
GameTooltip.GetItem = function() return "Wolfspelz", "|cffffffff|Hitem:7200::::|h[Wolfspelz]|h|r" end
GameTooltip._lines = {}
GameTooltip._scripts.OnTooltipSetItem(GameTooltip)
expect("Zeile im Tooltip", GameTooltip._lines[1], string.format(L.QUEST_ITEM_FOR_QUEST, "Pelze (3/8)"))

-- Ziel erfüllt: keine Zeile mehr aus dem Text
pelts.finished = true
wow.fire("QUEST_LOG_UPDATE")
expect("erfüllt: keine Zeile", QuestItemTooltip.Line(7200, "Wolfspelz"), nil)

-- In dieser Session abgegeben (Flag kommt verzögert)
table.remove(wow.state.questLog, 2)
wow.fire("QUEST_TURNED_IN", 50, 100, 0)
wow.fire("QUEST_LOG_UPDATE")
expect("eben abgegeben: verkaufbar", QuestItemTooltip.Line(7100, "Pelzstück"), L.QUEST_ITEM_DONE)
expect("Fehler?", #wow.errors, 0)
