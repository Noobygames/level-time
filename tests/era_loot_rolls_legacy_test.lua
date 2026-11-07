-- Würfeln um Beute in Classic Era über das alte C_LootHistory (Roadmap 364): GetItem liefert die rollID,
-- GetPlayerInfo je Spieler die Wahl (rollType nil = wartet); fertig mit isDone, Gewinner über winnerIdx.
local LootRolls = addon.LootRolls

local BOOTS = "|cff0070dd|Hitem:4444::::::::30:::::|h[Stiefel des Wanderers]|h|r"

local function printedWith(text)
  for _, printed in ipairs(wow.printed) do
    if printed:find(text, 1, true) then return printed end
  end
end

wow.login({ inGroup = true, groupSize = 3 })
addon.db.lootRollSummary = true
addon.db.lootRollJournal = true
addon.ApplySettings()
expect("Quelle", LootRolls.HistorySource(), "legacy")

wow.state.lootRolls = { [5] = { link = BOOTS } }
wow.fire("START_LOOT_ROLL", 5, 60000)
wow.state.lootHistory = { { rollID = 5, link = BOOTS, players = {
  { name = "Testchar", class = "WARRIOR", rollType = 1 },
  { name = "Grimbar", class = "MAGE" },
} } }
wow.fire("LOOT_HISTORY_ROLL_CHANGED", 1, 1)
local roll = LootRolls.Get(5)
local counts = LootRolls.Counts(roll)
expect("Bedarf aus der Historie", counts.need, 1)
expect("Wartende = Spieler ohne Wahl (nicht Gruppengröße)", counts.waiting, 1)
expect("wartet: Grimbar", table.concat(LootRolls.NamesOf(roll, "waiting"), ","), "Grimbar")

wow.state.lootHistory[1].isDone = true
wow.state.lootHistory[1].winnerIdx = 1
wow.state.lootHistory[1].players = {
  { name = "Testchar", class = "WARRIOR", rollType = 1, roll = 77, isWinner = true },
  { name = "Grimbar", class = "MAGE", rollType = 0 },
}
wow.fire("LOOT_HISTORY_ROLL_COMPLETE")
expect("fertig", LootRolls.Get(5), nil)
expectTrue("Chatzeile", printedWith("gewinnt mit 77 (Bedarf). Bedarf 1, Passen 1") ~= nil)

wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. BOOTS .. ".")
local entry = addon.character.lootLog[#addon.character.lootLog]
expect("Journal: Wurf", entry.roll, 77)
expect("Journal: Passen", entry.rollPass, 1)
expect("keine Lua-Fehler", #wow.errors, 0)
