-- Loot-Journal: seltene und bessere Beute mit Anzahl und vermuteter Quelle.
local Loot = addon.Loot

local function link(color, name)
  return "|cff" .. color .. "|Hitem:1234::::::::20:::::|h[" .. name .. "]|h|r"
end
local RARE = link("0070dd", "Klinge des Hains")
local EPIC = link("a335ee", "Zornklinge")
local COMMON = link("ffffff", "Leinenstoff")
local QUEST_REWARD = "|cnIQ3:|Hitem:999::::::::20:::::|h[Stiefel des Wächters]|h|r"  -- neueres Linkformat

wow.login({ level = 20, zone = "Dämmerwald" })

expect("Qualität aus Farbe", Loot.QualityOf(RARE), 3)
expect("Qualität aus neuem Format", Loot.QualityOf(QUEST_REWARD), 3)

-- Beute nach einem Kill: Quelle = Gegner
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Nachtschatten stirbt, Ihr bekommt 300 Erfahrung.")
wow.advance(5)
wow.state.sellPrices[RARE] = 4500  -- Item beim Erbeuten bekannt
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. RARE .. ".")
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. COMMON .. "x5.")  -- zu gewöhnlich
wow.fire("CHAT_MSG_LOOT", "Grimbar erhält Beute: " .. EPIC .. ".")    -- fremde Beute

-- Belohnung kurz nach einer Quest-Abgabe: Quelle = Quest
wow.advance(120)
wow.state.questTitles[7] = "Der Dämmerwald-Schrecken"
wow.fire("QUEST_TURNED_IN", 7, 500, 0)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. QUEST_REWARD .. ".")

-- Mehrere Stück, keine erkennbare Quelle
wow.advance(300)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. EPIC .. "x2.")

local loot = addon.character.lootLog
expect("drei Beute-Einträge", #loot, 3)
expect("Name aus Link", loot[1].name, "Klinge des Hains")
expect("Verkaufspreis beim Erbeuten gemerkt", loot[1].value, 4500)
expect("unbekanntes Item ohne Preis", loot[3].value, nil)
expect("Quelle Gegner", loot[1].source, "Nachtschatten")
expect("Zone", loot[1].zone, "Dämmerwald")
expect("Quelle Quest", loot[2].source, "Der Dämmerwald-Schrecken")
expect("Anzahl", loot[3].quantity, 2)
expect("Qualität episch", loot[3].quality, 4)
expect("keine Quelle", loot[3].source, nil)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Beute", wow.click("Beute"))

-- Retail-Formate ohne Punkt am Ende und Punkte im Gegenstandsnamen
local DOTTED = link("0070dd", "Gürtel d. Wächters")
local formatsBefore = LOOT_ITEM_SELF
LOOT_ITEM_SELF = "Ihr erhaltet Beute: %s"
local retailFormat = addon.ChatPatterns.Compile(LOOT_ITEM_SELF, addon.ChatPatterns.LINK)
expect("Link ohne Punkt am Ende", addon.ChatPatterns.Match("Ihr erhaltet Beute: " .. RARE, retailFormat)[1], RARE)
expect("Rest der Zeile ohne Link-Option", addon.ChatPatterns.Match("Ihr erhaltet Beute: " .. RARE,
  addon.ChatPatterns.Compile(LOOT_ITEM_SELF))[1], RARE)
LOOT_ITEM_SELF = formatsBefore
local count = #addon.character.lootLog
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. DOTTED .. ".")
expect("Punkt im Namen", addon.character.lootLog[count + 1].name, "Gürtel d. Wächters")
