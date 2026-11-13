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

-- Eigene Müll-Markierung: Alt+Rechtsklick auf den Taschenplatz
wow.state.bags[0][4] = { itemID = 8000, stackCount = 1 }
wow.state.sellPrices[8000] = 25
local slotButton = CreateFrame("Button")
slotButton.GetBagID = function() return 0 end
slotButton.GetID = function() return 4 end
ContainerFrameItemButton_OnModifiedClick(slotButton, "RightButton")
expect("ohne Alt: keine Markierung", QuestLeftovers.IsMarked(8000), false)
wow.state.altDown = true
ContainerFrameItemButton_OnModifiedClick(slotButton, "LeftButton")
expect("Linksklick: keine Markierung", QuestLeftovers.IsMarked(8000), false)
ContainerFrameItemButton_OnModifiedClick(slotButton, "RightButton")
wow.state.altDown = false
expectTrue("Alt+Rechtsklick markiert", QuestLeftovers.IsMarked(8000))
expect("markiert zählt als Rest", #QuestLeftovers.InBags(), 2)

-- Löschen: nur Reste ohne Verkaufswert, erst nach Bestätigung
local deletable = QuestLeftovers.Deletable()
expect("nur ohne Verkaufswert löschbar", #deletable, 1)
expect("das ist die Fackel", deletable[1].itemID, 5000)
QuestLeftovers.ConfirmDelete()
expect("Rückfrage", wow.popup and wow.popup.name, "LEVELTIMER_DELETE_LEFTOVERS")
expect("noch da vor der Bestätigung", wow.state.bags[0][1] ~= nil, true)
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("Fackel gelöscht", wow.state.bags[0][1], nil)
expect("markierter Gegenstand bleibt", wow.state.bags[0][4].itemID, 8000)

-- Schrottverkauf nimmt markierte Gegenstände mit
addon.Set("autoSellJunk", true)
wow.fire("MERCHANT_SHOW")
expect("markiert verkauft", wow.state.bags[0][4], nil)
addon.Set("autoSellJunk", false)

addon.Set("questLeftovers", false)
expect("aus: kein Zusatz", QuestLeftovers.BagsHint(), nil)
expect("Fehler?", #wow.errors, 0)
