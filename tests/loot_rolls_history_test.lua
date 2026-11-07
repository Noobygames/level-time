-- Würfeln um Beute in Retail (Roadmap 364): Stand aus C_LootHistory.GetSortedInfoForDrop (LOOT_HISTORY_UPDATE_DROP
-- und LOOT_HISTORY_UPDATE_ENCOUNTER); Chatzeilen zählen dann nicht mehr dazu. Wartende = Zustand NoRoll (4).
local LootRolls = addon.LootRolls

local SWORD = "|cnIQ4:|Hitem:777::::::::70:::::|h[Klinge des Sturms]|h|r"
local HELM = "|cnIQ3:|Hitem:888::::::::70:::::|h[Helm der Flut]|h|r"
local NEED, TRANSMOG, GREED, NO_ROLL, PASS = 0, 2, 3, 4, 5

local function printedWith(text)
  for _, printed in ipairs(wow.printed) do
    if printed:find(text, 1, true) then return printed end
  end
end

wow.login({ inGroup = true, groupSize = 3, realm = "Testrealm",
  units = { party1 = { name = "Grimbar", class = "MAGE", isPlayer = true } } })
addon.db.lootRollCounts = true
addon.db.lootRollSummary = true
addon.ApplySettings()
expect("Quelle", LootRolls.HistorySource(), "drops")

wow.state.lootRolls = { [7] = { link = SWORD }, [8] = { link = HELM } }
wow.fire("START_LOOT_ROLL", 7, 120000)
wow.state.lootDrops = { ["100:1"] = { itemHyperlink = SWORD, rollInfos = {
  { playerName = "Testchar", playerClass = "WARRIOR", state = NO_ROLL },
  { playerName = "Grimbar", playerClass = "MAGE", state = NEED },
  { playerName = "Lyra-Anderswo", playerClass = "WARRIOR", state = PASS },
} } }
wow.fire("LOOT_HISTORY_UPDATE_DROP", 100, 1)
local roll = LootRolls.Get(7)
local counts = LootRolls.Counts(roll)
expect("Bedarf", counts.need, 1)
expect("Passen", counts.pass, 1)
expect("wartet: aus der Historie", counts.waiting, 1)
expect("Wartende mit Namen", table.concat(LootRolls.NamesOf(roll, "waiting"), ","), "Testchar")
expect("Klasse aus der Historie", LootRolls.ClassOf(roll, "Lyra-Anderswo"), "WARRIOR")
expect("fremder Realm bleibt", roll.choices["Lyra-Anderswo"], "pass")

-- Chatzeilen ändern einen Wurf mit Historie nicht (sonst doppelt)
wow.fire("CHAT_MSG_LOOT", "|HlootHistory:5|h[Beute]|h: Tok passt auf: " .. SWORD)
expect("Chat zählt nicht dazu", LootRolls.Counts(roll).pass, 1)

-- Ende: Gewinner aus der Historie
wow.state.lootDrops["100:1"] = { itemHyperlink = SWORD, winner = { playerName = "Grimbar", roll = 99 }, rollInfos = {
  { playerName = "Testchar", playerClass = "WARRIOR", state = GREED, roll = 55 },
  { playerName = "Grimbar", playerClass = "MAGE", state = NEED, roll = 99, isWinner = true },
  { playerName = "Lyra-Anderswo", playerClass = "WARRIOR", state = PASS },
} }
wow.fire("LOOT_HISTORY_UPDATE_DROP", 100, 1)
expect("fertig", LootRolls.Get(7), nil)
expectTrue("Chatzeile", printedWith("gewinnt mit 99 (Bedarf). Bedarf 1, Gier 1, Passen 1") ~= nil)

-- Begegnung mit mehreren Beuten: Transmog, Zuordnung über den Link
wow.fire("START_LOOT_ROLL", 8, 120000)
wow.state.encounterDrops = { [100] = { { lootListID = 2, itemHyperlink = HELM } } }
wow.state.lootDrops["100:2"] = { itemHyperlink = HELM, rollInfos = {
  { playerName = "Testchar", playerClass = "WARRIOR", state = TRANSMOG },
  { playerName = "Grimbar", playerClass = "MAGE", state = NO_ROLL },
} }
wow.fire("LOOT_HISTORY_UPDATE_ENCOUNTER", 100)
local helm = LootRolls.Get(8)
expect("Transmog", LootRolls.Counts(helm).transmog, 1)
expect("Zuordnung gemerkt", helm.dropKey, "100:2")
expectTrue("Transmog-Atlas in der Zeile",
  addon.LootRollDisplay.CountsLine(helm):find("|A:lootroll-icon-transmog:14:14|a 1", 1, true) ~= nil)
wow.fire("CANCEL_ALL_LOOT_ROLLS")
expectTrue("alle geschlossen", helm.closed)
expect("keine Lua-Fehler", #wow.errors, 0)
