-- LT-263: Zusatz-Tracker für Quests jenseits der fünf beobachteten (nur Classic Era)
local QuestTracker = addon.QuestTracker

wow.state.questLog = {
  { title = "Elwynn", isHeader = true },
  { title = "Wölfe", level = 5, questID = 80, objectives = { { text = "Wolf getötet: 1/5", finished = false } } },
  { title = "Kerzen", level = 6, questID = 81, objectives = { { text = "Kerze: 1/1", finished = true } } },
}
wow.state.questWatches = { 2 }  -- Blizzard-Tracker zeigt nur "Wölfe"

wow.login({ level = 10 })
expectTrue("Era: wählbar", QuestTracker.IsAvailable())
wow.update(1.1)
expectTrue("aus: Karte versteckt", not QuestTracker.Card().frame:IsShown())

addon.Set("questTracker", true)
wow.update(1.1)
local card = QuestTracker.Card()
expectTrue("an: Karte sichtbar", card.frame:IsShown())
local text = card.frame.body:GetText()
expectTrue("unbeobachtete Quest mit Ziel", text:find("Kerzen", 1, true) and text:find("Kerze: 1/1", 1, true))
expectTrue("beobachtete Quest fehlt", not text:find("Wölfe", 1, true))

wow.state.questWatches = { 2, 3 }
wow.update(1.1)
expectTrue("alles beobachtet: Karte versteckt", not card.frame:IsShown())
