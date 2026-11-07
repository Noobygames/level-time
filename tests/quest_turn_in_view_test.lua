-- Abgabe-Übersicht (Roadmap 345): abgabebereite Quests mit Zone, XP und Anteil am Level, Summe in der Fußzeile.
local L = addon.L
local QuestViews = addon.QuestViews

wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 1, title = "Wölfe", level = 8, isComplete = 1, rewardXp = 250 },
  { questID = 2, title = "Offen", level = 9, rewardXp = 400 },
  { title = "Westfall", isHeader = true },
  { questID = 3, title = "Ernte", level = 10, isComplete = 1, rewardXp = 500 },
}

wow.login({ level = 10, xpMax = 1000 })
local records = QuestViews.TurnInRecords(addon.characterKey)
expect("zwei abgabebereite", #records, 2)
expect("Zone aus der Überschrift", records[1].zone, "Wald von Elwynn")
expect("zweite Zone", records[2].zone, "Westfall")
expectNear("Anteil am Level", records[2].share, 0.5)
expect("anderer Charakter: leer", #QuestViews.TurnInRecords("Jemand-Testrealm"), 0)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Quests", wow.click(L.HISTORY_GROUP_QUESTS))
expectTrue("Unterreiter Abgabe", wow.click(L.HISTORY_TAB_TURN_IN))
local shown = wow.shownTable()
expect("Tabelle zeigt beide", #shown:GetVisibleRecords(), 2)

-- Neue fertige Quest: nach QUEST_LOG_UPDATE in der Tabelle
wow.state.questLog[3].isComplete = 1
wow.fire("QUEST_LOG_UPDATE")
wow.advance(6)
wow.update(6)
expect("nach Änderung drei", #shown:GetVisibleRecords(), 3)
expect("Fehler?", #wow.errors, 0)
