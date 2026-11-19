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

-- Leistung: volle Taschen ohne Änderung durchsucht der Takt nicht erneut; nach einer Sperr-Änderung schon
wow.state.bags[0][offered.slot] = { itemID = 1, stackCount = 1, quality = 0 }
wow.fire("BAG_UPDATE_DELAYED")
local finds = { count = 0 }
local find = CheapestJunk.FindAll
CheapestJunk.FindAll = function(...) finds.count = finds.count + 1 return find(...) end
for _ = 1, 5 do wow.update(2) end
expect("unverändert: keine Suche im Takt", finds.count, 0)
wow.fire("ITEM_LOCK_CHANGED", 0, offered.slot)
wow.update(2)
expect("nach Sperr-Änderung: neu gesucht", finds.count, 1)
CheapestJunk.FindAll = find

-- v3.0.1: bis zu drei Angebote, graue vor billigen weißen (nur Ausrüstung/Kram, kein Reagenz), X schließt
wow.state.itemIcons = { [5] = 135000, [6] = 135001, [17020] = 135002 }
wow.state.equipLocs = {}
wow.state.sellPrices = { [1] = 50, [2] = 10, [5] = 20, [6] = 9999, [17020] = 5 }
wow.state.bags = { [0] = {
  { itemID = 1, stackCount = 1, quality = 0 },      -- grau, 50
  { itemID = 2, stackCount = 1, quality = 0 },      -- grau, 10
  { itemID = 5, stackCount = 1, quality = 1 },      -- weiß, Rüstung, 20: angeboten
  { itemID = 6, stackCount = 1, quality = 1 },      -- weiß, zu wertvoll
  { itemID = 17020, stackCount = 1, quality = 1 },  -- Arkanes Pulver: Klassen-Reagenz, nie
} }
wow.fire("BAG_UPDATE_DELAYED")
local offers = CheapestJunk.FindAll()
expect("drei Angebote", #offers, 3)
expect("Reihenfolge", offers[1].itemID .. "," .. offers[2].itemID .. "," .. offers[3].itemID, "2,1,5")
expect("Fenster da", CheapestJunk.IsShown(), true)
expect("dritte Zeile sichtbar", CheapestJunk.Rows()[3]:IsShown(), true)
CheapestJunk.closeButton._scripts.OnClick(CheapestJunk.closeButton)
wow.fire("BAG_UPDATE_DELAYED")
expect("geschlossen bleibt zu", CheapestJunk.IsShown(), false)
wow.state.freeSlots = { [0] = { 1, 0 } }
wow.fire("BAG_UPDATE_DELAYED")
wow.state.freeSlots = { [0] = { 0, 0 } }
wow.fire("BAG_UPDATE_DELAYED")
expect("nach freiem Platz wieder da", CheapestJunk.IsShown(), true)

-- Berufswerkzeuge nie anbieten: Kürschnermesser (per ID) und jede Angel (Unterklasse)
wow.state.itemIcons = { [7005] = 135003, [6365] = 135004 }
wow.state.itemClasses = { [6365] = { 2, 20 } }
wow.state.sellPrices = { [7005] = 1, [6365] = 1 }
wow.state.bags = { [0] = {
  { itemID = 7005, stackCount = 1, quality = 1 },  -- Kürschnermesser
  { itemID = 6365, stackCount = 1, quality = 1 },  -- Kräftige Angelrute
} }
wow.fire("BAG_UPDATE_DELAYED")
expect("keine Werkzeuge angeboten", #CheapestJunk.FindAll(), 0)
expect("keine Fehler", #wow.errors, 0)
