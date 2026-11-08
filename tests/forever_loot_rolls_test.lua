-- Würfeln um Beute in WoW Forever (Roadmap 364): geheime Chatzeilen fallen ohne Fehler weg, lesbare zählen;
-- Forever-Formate ("Ihr habt "Bedarf" ausgewählt für: %s", "Weitergegeben von Euch: %s", Forever deDE).
local LootRolls = addon.LootRolls

local AXE = "|cff1eff00|Hitem:3030::::::::20:::::|h[Axt des Holzfällers]|h|r"

LOOT_ROLL_NEED_SELF = "|HlootHistory:%d|h[Beute]|h: Ihr habt \"Bedarf\" ausgewählt für: %s"
LOOT_ROLL_PASSED_SELF = "|HlootHistory:%d|h[Beute]|h: Weitergegeben von Euch: %s"
LOOT_ROLL_WON_NO_SPAM_GREED = "|HlootHistory:%d|h[Beute]|h: %s hat gewonnen (Gier - %d): %s"

wow.login({ inGroup = true, groupSize = 2, units = { party1 = { name = "Grimbar", class = "MAGE", isPlayer = true } } })
addon.db.lootRollCounts = true
addon.db.lootRollSummary = true
addon.ApplySettings()

wow.state.lootRolls = { [9] = { link = AXE }, [10] = { link = AXE } }
wow.fire("START_LOOT_ROLL", 9, 60000)
wow.fire("START_LOOT_ROLL", 10, 60000)
wow.fire("CHAT_MSG_LOOT", wow.SECRET)
local roll = LootRolls.Get(9)
expect("geheime Zeile zählt nicht", #roll.order, 0)

wow.fire("CHAT_MSG_LOOT", "|HlootHistory:31|h[Beute]|h: Ihr habt \"Bedarf\" ausgewählt für: " .. AXE)
expect("Forever-Format eigene Wahl", roll.choices.Testchar, "need")
wow.fire("CHAT_MSG_LOOT", "|HlootHistory:32|h[Beute]|h: Weitergegeben von Euch: " .. AXE)
expect("zweite Axt: eigenes Passen", LootRolls.Get(10).choices.Testchar, "pass")
wow.fire("CHAT_MSG_LOOT", "|HlootHistory:31|h[Beute]|h: Grimbar hat für " .. AXE .. " Gier ausgewählt")
expect("wartet keiner mehr", LootRolls.Counts(roll).waiting, 0)

-- Gewinnerzeile mit umgestellter Reihenfolge (Wurf vor dem Gegenstand)
wow.fire("CHAT_MSG_LOOT", "|HlootHistory:31|h[Beute]|h: Grimbar hat gewonnen (Gier - 12): " .. AXE)
expect("fertig", LootRolls.Get(9), nil)
expect("Gewinner-Wurf", roll.winnerRoll, 12)
expect("zweite Axt noch offen", LootRolls.Get(10) ~= nil, true)

-- Forever liest die Beute-Historie, bevor sie den Gewinner kennt; die Gewinnerzeile im Chat zählt trotzdem
-- (vorher: "alle haben gepasst", obwohl alle gewählt hatten)
local second = LootRolls.Get(10)
wow.state.lootDrops = { ["100:4"] = { itemHyperlink = AXE, allPassed = false,
  rollInfos = { { playerName = "Grimbar", playerClass = "MAGE", state = 3, roll = 55 },
    { playerName = "Testchar", playerClass = "WARRIOR", state = 5 } } } }
wow.fire("LOOT_HISTORY_UPDATE_DROP", 100, 4)
expect("Wahlen aus der Historie", second.choices.Grimbar, "greed")
wow.fire("CHAT_MSG_LOOT", "|HlootHistory:32|h[Beute]|h: Grimbar hat gewonnen (Gier - 55): " .. AXE)
expect("Gewinner aus der Chatzeile", second.winner, "Grimbar")
expect("nicht alle gepasst", second.allPassed, false)
local summary = addon.LootRollReport.SummaryText(second)
expectTrue("Ergebnis nennt den Gewinner", summary:find("gewinnt mit 55", 1, true) ~= nil)
expect("ohne Gewinner: unbekannt statt gepasst", addon.LootRollReport.SummaryText({ link = AXE, choices = {},
  order = {}, rolls = {}, classes = {}, groupSize = 2, completed = true }),
  string.format(addon.L.LOOT_ROLL_SUMMARY_UNKNOWN, AXE))

-- Debug-Log: Proben zu Start und Historie, Zeile zur geheimen Chatzeile
local function hasLine(text)
  for _, logged in ipairs(LevelTimerDebugLog.lines) do
    if logged:find(text, 1, true) then return logged end
  end
end
SlashCmdList.LEVELTIMER("debug log")
wow.fire("START_LOOT_ROLL", 10, 60000)
wow.fire("LOOT_HISTORY_UPDATE_DROP", 100, 3)
wow.fire("CHAT_MSG_LOOT", wow.SECRET)
expectTrue("Probe START_LOOT_ROLL mit Link", hasLine('"event":"START_LOOT_ROLL"') ~= nil
  and hasLine("Axt des Holzf") ~= nil)
expectTrue("Probe Historie", hasLine('"event":"LOOT_HISTORY_UPDATE_DROP"') ~= nil)
expectTrue("geheime Zeile im Log", hasLine("secret loot chat line skipped") ~= nil)
expect("keine Lua-Fehler", #wow.errors, 0)
