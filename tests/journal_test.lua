-- Journal: Kills mit Name und Art, Tode mit Ursache; Anzeige in der Historie.
local Journal = addon.Journal
local PLAYER = wow.state.guid

wow.login({ level = 12, zone = "Wald von Elwynn" })

---------------------------------------------------------------------------
-- Kills
---------------------------------------------------------------------------
wow.state.clock = 1700000100
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold-Ungeziefer stirbt, Ihr bekommt 45 Erfahrung.")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Ihr bekommt 250 Erfahrung.")  -- Quest: kein Eintrag
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Grimbar stirbt, ehrenhafter Sieg Rang: Gefreiter (Geschätzte Ehrenpunkte: 12)")

local kills = addon.character.killLog
expect("zwei Kills im Journal", #kills, 2)
expect("PvE-Name", kills[1].name, "Kobold-Ungeziefer")
expect("PvE-Art", kills[1].kind, Journal.PVE)
expect("Zeitpunkt", kills[1].time, 1700000100)
expect("Level", kills[1].level, 12)
expect("Zone", kills[1].zone, "Wald von Elwynn")
expect("PvP-Name", kills[2].name, "Grimbar")
expect("PvP-Art", kills[2].kind, Journal.PVP)

---------------------------------------------------------------------------
-- Tode
---------------------------------------------------------------------------
-- Zauber eines Gegners als letzter Treffer; Treffer an andere Ziele zählen nicht
wow.combatLog("SWING_DAMAGE", "Wolf", PLAYER, 20)
wow.combatLog("SPELL_DAMAGE", "Hogger", PLAYER, 123, "Prankenhieb", 1, 80)
wow.combatLog("SPELL_DAMAGE", "Magier", "Creature-2", 133, "Feuerball", 4, 500)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")

-- Sturz
wow.advance(60)
wow.combatLog("ENVIRONMENTAL_DAMAGE", nil, PLAYER, "FALLING", 900)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")

-- Treffer zu lange her: Ursache unbekannt
wow.combatLog("SWING_DAMAGE", "Wolf", PLAYER, 20)
wow.advance(30)
wow.state.dead = true
wow.fire("PLAYER_DEAD")

local deaths = addon.character.deathLog
expect("drei Tode im Journal", #deaths, 3)
expect("Verursacher", deaths[1].killer, "Hogger")
expect("Zauber", deaths[1].spell, "Prankenhieb")
expect("Umgebung", deaths[2].environment, "FALLING")
expect("Sturz ohne Verursacher", deaths[2].killer, nil)
expect("alter Treffer: kein Verursacher", deaths[3].killer, nil)
expect("Tod-Level", deaths[1].level, 12)

---------------------------------------------------------------------------
-- Historie: neueste zuerst, Anzeige rendert
---------------------------------------------------------------------------
local killLog = addon.History.GetKillLog(addon.characterKey)
expect("neuester Kill zuerst", killLog[1].name, "Grimbar")
local deathLog = addon.History.GetDeathLog(addon.characterKey)
expect("neuester Tod zuerst", deathLog[1].killer, nil)
expect("ältester Tod zuletzt", deathLog[3].killer, "Hogger")

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Kills", wow.click("Kills"))
expectTrue("Reiter Tode", wow.click("Tode"))

---------------------------------------------------------------------------
-- Begrenzung des Eingangs (greift nur, wenn das Archiv nicht umziehen kann): nur die neuesten Einträge bleiben
---------------------------------------------------------------------------
-- Gekürzt wird in einem Zug, sobald INBOX_SLACK Einträge zu viel sind (Roadmap 355)
local inboxLimit, inboxSlack = Journal.INBOX_LIMIT, Journal.INBOX_SLACK
Journal.INBOX_LIMIT, Journal.INBOX_SLACK = 50, 5
addon.character.killLog = {}
local log = addon.character.killLog
for i = 1, Journal.INBOX_LIMIT + Journal.INBOX_SLACK do
  Journal.AddKill(Journal.PVE, "Ratte " .. i)
end
expect("bis zur Reserve nicht gekürzt", #log, 55)
Journal.AddKill(Journal.PVE, "Ratte 56")
expect("Kill-Eingang auf die Grenze gekürzt", #log, Journal.INBOX_LIMIT)
expect("älteste fallen weg", log[1].name, "Ratte 7")
expect("neuester Eintrag bleibt", log[#log].name, "Ratte 56")
for i = 57, 60 do Journal.AddKill(Journal.PVE, "Ratte " .. i) end
expect("danach wieder Reserve", #log, 54)
Journal.INBOX_LIMIT, Journal.INBOX_SLACK = inboxLimit, inboxSlack
