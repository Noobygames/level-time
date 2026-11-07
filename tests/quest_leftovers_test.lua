-- Questreste in den Taschen (Roadmap 352): Gegenstände abgegebener/abgebrochener Quests als Vorschlag beim Händler
-- und im Hinweis "Taschen fast voll"; Gegenstände, die eine offene Quest braucht, bleiben außen vor.
local L = addon.L
local QuestLeftovers = addon.QuestLeftovers

wow.state.questLog = {
  { questID = 70, title = "Fackeln", specialItem = { "|cffffffff|Hitem:5000::::|h[Fackel]|h|r", 134000 } },
  { questID = 71, title = "Pelze", objectives = { { text = "Pelz: 1/5", finished = false } } },
}
wow.state.bags = { [0] = {
  { itemID = 5000, stackCount = 1 },
  { itemID = 6000, stackCount = 3 },
  { itemID = 7000, stackCount = 2 },
} }

wow.login({ level = 12 })
-- Gelernt: 6000 gehört zu 72 (abgegeben gleich), 7000 zu 72 und zur offenen 71
LevelTimerStatsDB.questMobs = {
  [72] = { [1] = { mobs = {}, items = { [6000] = 2, [7000] = 2 }, itemNames = { [6000] = "Zahnrad", [7000] = "Pelz" } } },
  [71] = { [1] = { mobs = {}, items = { [7000] = 2 }, itemNames = { [7000] = "Pelz" } } },
}
addon.Set("questLeftovers", true)
wow.update(2)  -- Quest-Items im Log merken
wow.fire("QUEST_LOG_UPDATE")

wow.fire("QUEST_TURNED_IN", 72, 100, 0)
wow.fire("QUEST_REMOVED", 70)  -- abgebrochen: das Quest-Item bleibt übrig
wow.state.sellPrices = {}
local found = QuestLeftovers.InBags()
expect("zwei Reste", #found, 2)
expect("Pelz bleibt (offene Quest braucht ihn)", addon.character.questLeftovers[7000], nil)
expect("Text", QuestLeftovers.Text(), "Item 5000, Zahnrad (3)")

-- Beim Händler: Hinweis
wow.fire("MERCHANT_SHOW")
local shown = false
for _, line in ipairs(wow.printed) do
  if line:find(string.format(L.QUEST_LEFTOVERS, "Item 5000, Zahnrad (3)"), 1, true) then shown = true end
end
expectTrue("Hinweis beim Händler", shown)

-- Verkauft: vergessen
wow.state.bags[0][2] = nil
expect("verkauft: ein Rest", #QuestLeftovers.InBags(), 1)
expect("vergessen", addon.character.questLeftovers[6000], nil)
expect("Taschen-Zusatz", QuestLeftovers.BagsHint(), string.format(L.QUEST_LEFTOVERS_SHORT, "Item 5000"))

addon.Set("questLeftovers", false)
expect("aus: kein Zusatz", QuestLeftovers.BagsHint(), nil)
expect("Fehler?", #wow.errors, 0)
