-- Taschen voll: billigster grauer Gegenstand per Klick löschen
local CheapestJunk = addon.CheapestJunk

wow.state.sellPrices = { [1] = 50, [2] = 10, [3] = 5, [4] = 1 }
wow.state.bags = { [0] = {
  { itemID = 1, stackCount = 1, quality = 0 },                             -- grau, 50
  { itemID = 2, stackCount = 3, quality = 0 },                             -- grau, 30
  { itemID = 3, stackCount = 1, quality = 1 },                             -- weiß, billiger, nie
  { itemID = 4, stackCount = 1, quality = 0, questInfo = { isQuestItem = true } }, -- Quest, nie
} }
wow.login({ level = 12 })

addon.Set("deleteCheapestJunk", true)
wow.state.freeSlots = { [0] = { 2, 0 } }
CheapestJunk.Update()
expect("nicht voll: kein Knopf", wow.click("Löschen", false), false)

wow.state.freeSlots = { [0] = { 0, 0 } }
CheapestJunk.Update()
local cheapest = CheapestJunk.Find()
expect("billigster: 3x Item 2", cheapest.itemID, 2)
expect("Wert", cheapest.value, 30)
expectTrue("Knopf zeigt Namen", wow.click(addon.L.DELETE_CHEAPEST_JUNK_BUTTON:format("Item 2 x3", addon.Format.Money(30)), false))
expect("gelöscht", wow.state.bags[0][2], nil)
expectTrue("Rest bleibt", wow.state.bags[0][1] ~= nil and wow.state.bags[0][3] ~= nil and wow.state.bags[0][4] ~= nil)
expect("nächster: Item 1", CheapestJunk.Find().itemID, 1)

-- Platz ändert sich zwischen Anzeige und Klick: nichts löschen, Knopf neu berechnen
CheapestJunk.Update()
local offered = CheapestJunk.Find()
expect("Angebot Item 1", offered.itemID, 1)
wow.state.bags[0][offered.slot] = { itemID = 3, stackCount = 1, quality = 1 }  -- jetzt weiß
wow.click(addon.L.DELETE_CHEAPEST_JUNK_BUTTON:format("Item 1", addon.Format.Money(50)), false)
expectTrue("weißer Gegenstand bleibt", wow.state.bags[0][offered.slot] ~= nil)
expect("Cursor leer", CursorHasItem(), false)
expect("Knopf zeigt keinen Treffer mehr", CheapestJunk.Find(), nil)
