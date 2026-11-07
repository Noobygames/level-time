-- Graue Quests in WoW Forever/Retail: grau über C_QuestLog.IsQuestTrivial, Abbruch über C_QuestLog (Roadmap 344)
local calls = {}
wow.state.trivialQuests = { [11] = true, [13] = true }
C_QuestLog.SetSelectedQuest = function(questID) table.insert(calls, "select " .. questID) end
C_QuestLog.SetAbandonQuest = function() table.insert(calls, "set") end
C_QuestLog.AbandonQuest = function()
  table.insert(calls, "abandon")
  table.remove(wow.state.questLog, 2)
end
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
wow.state.questLog = {
  { title = "Zone", isHeader = true },
  { questID = 11, title = "Grau", level = 3 },
  { questID = 12, title = "Offen", level = 20 },
}

wow.login({ level = 20 })
local gray = addon.QuestCleanup.GrayQuests()
expect("eine graue", #gray, 1)
expectTrue("Abbruch", addon.QuestCleanup.Abandon(11))
expect("Reihenfolge", table.concat(calls, ","), "select 11,set,abandon")
expect("nicht im Log: kein Abbruch", addon.QuestCleanup.Abandon(13), false)
expect("Fehler?", #wow.errors, 0)
