-- Ruf pro Stunde (Roadmap 278): Rufmeldungen je Level, Session, Instanz-Lauf, Zone und Fraktion.
local Stats = addon.Stats
local Reputation = addon.Reputation

wow.login({ level = 20 })

local function gain(faction, amount)
  wow.fire("CHAT_MSG_COMBAT_FACTION_CHANGE", string.format(FACTION_STANDING_INCREASED, faction, amount))
end

-- Erkennung: Grundform, Bonus-Form, Kriegsmeute; ohne Menge und geheim nicht
expect("Grundform", select(2, Reputation.Parse(string.format(FACTION_STANDING_INCREASED, "Sturmwind", 25))), 25)
expect("Bonus-Form", select(2, Reputation.Parse("Euer Ruf bei der Fraktion 'Sturmwind' hat sich um 30 verbessert. (+3.0 Bonus)")), 30)
local faction, amount = Reputation.Parse(string.format(FACTION_STANDING_INCREASED_ACCOUNT_WIDE, "Die Tillers", 10))
expect("Kriegsmeute: Fraktion", faction, "Die Tillers")
expect("Kriegsmeute: Menge", amount, 10)
expect("ohne Menge", Reputation.Parse(string.format(FACTION_STANDING_INCREASED_GENERIC, "Sturmwind")), nil)
expect("geheim", Reputation.Parse(wow.SECRET), nil)

-- Zählen in Level, Session, Zone und je Fraktion
gain("Sturmwind", 25)
gain("Sturmwind", 25)
gain("Eisenschmiede", 10)
expect("Level", Stats.Get(Stats.LEVEL, Stats.REPUTATION), 60)
expect("Session", Stats.Get(Stats.SESSION, Stats.REPUTATION), 60)
expect("Zone", addon.character.zoneStats[wow.state.zone].reputation, 60)
local records = Reputation.GetRecords(addon.characterKey)
expect("Fraktionen", #records, 2)
expect("meiste zuerst", records[1].faction, "Sturmwind")
expect("Summe je Fraktion", records[1].amount, 50)

-- Instanz-Lauf: zählt im Lauf und landet im Journal
wow.state.instance = { name = "Todesminen", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
gain("Sturmwind", 40)
expect("Instanz", Stats.Get(Stats.INSTANCE, Stats.REPUTATION), 40)
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Todesminen"))
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Burg Schattenfang", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
local log = addon.character.instanceLog
local finished = log[#log]
expect("Lauf im Journal", finished and finished.name, "Todesminen")
expect("Ruf im Journal", finished and finished.counters.reputation, 40)

-- Ruf/h-Zeile
local stat
for _, line in ipairs(addon.STAT_LINES) do if line.setting == "showReputation" then stat = line end end
expect("Ruf-Zeile", stat.rows[1].value(Stats.SESSION), "100")
expect("Ruf/h-Zeile ist Text", type(stat.rows[2].value(Stats.SESSION)), "string")

-- Historie: Reiter Ruf
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Ruf", wow.click("Ruf"))
expectTrue("Ruf-Tabelle", wow.shownTable() ~= nil)
