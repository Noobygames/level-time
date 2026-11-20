-- Questreste: ein Gegenstand aus einer Quest, der für die eigene Klasse Reagenz ist (Fischöl, Schamane: Wasserwandeln),
-- ist kein Rest, ebenso Handwerkswaren (Seidenstoff aus einer Stoffabgabe); andere Reste bleiben
local QuestLeftovers = addon.QuestLeftovers
local FISH_OIL = 17058
local SILK = 4306
local TRADEGOODS_CLASS, CLOTH_SUBCLASS = 7, 5
wow.state.itemIcons[SILK] = 132905
wow.state.itemClasses = { [SILK] = { TRADEGOODS_CLASS, CLOTH_SUBCLASS } }

wow.state.class = "SHAMAN"
wow.state.bags = { [0] = {
  { itemID = FISH_OIL, stackCount = 5 },
  { itemID = 6000, stackCount = 3 },
  { itemID = SILK, stackCount = 40 },
} }
wow.login({ level = 30 })
LevelTimerStatsDB.questMobs = {
  [72] = { [1] = { mobs = {}, items = { [FISH_OIL] = 5, [6000] = 2, [SILK] = 10 },
    itemNames = { [FISH_OIL] = "Fischöl", [6000] = "Zahnrad", [SILK] = "Seidenstoff" } } },
}
addon.Set("questLeftovers", true)
wow.fire("QUEST_TURNED_IN", 72, 100, 0)
wow.state.sellPrices = {}
expectTrue("Fischöl ist Schamanen-Reagenz", addon.Reagents.IsClassReagent(FISH_OIL))
expect("nur das Zahnrad", QuestLeftovers.Text(), "Zahnrad (3)")
expect("Fischöl vergessen", addon.character.questLeftovers[FISH_OIL], nil)
expect("Seidenstoff (Handwerksware) vergessen", addon.character.questLeftovers[SILK], nil)
expect("keine Lua-Fehler", #wow.errors, 0)
