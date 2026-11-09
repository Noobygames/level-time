-- Level Time Goals, Roadmap 311: Gruppenziele (PartySync), Ziele teilen und gemeinsamen Fortschritt austauschen.
local Goals = streamGoal.Goals
local PartySync = streamGoal.PartySync
local L = streamGoal.L

wow.login({ level = 20, name = "Held", inGroup = true })
expectTrue("StreamGoal Addon-Präfix registriert", wow.addonPrefixes["StreamGoal"] == true)

-- Ziel anlegen und teilen
SlashCmdList.STREAMGOAL("add kills 10")
local killGoal = Goals.Active()[1]
expect("Kill-Ziel vorhanden", killGoal.kind, "kills")

SlashCmdList.STREAMGOAL("share " .. killGoal.id)
expectTrue("Ziel als geteilt markiert", killGoal.shared == true)
expectTrue("sharedKey vorhanden", killGoal.sharedKey ~= nil)

PartySync.Flush()
expectTrue("Nachricht gesendet", #wow.addonMessages >= 1)
local shareMsg = wow.addonMessages[#wow.addonMessages]
expect("Präfix StreamGoal", shareMsg.prefix, "StreamGoal")
expect("An Gruppe gesendet", shareMsg.chatType, "PARTY")
expectTrue("Share-Format S:kills:10:...", shareMsg.message:find("^S:kills:10:") ~= nil)

-- Gruppenmitglied teilt ein Ziel (S:item:5:itemId=1234;name=Stoff)
wow.fire("CHAT_MSG_ADDON", "StreamGoal", "S:item:5:itemId=1234;name=Stoff", "PARTY", "Gefährte")
local itemGoal = Goals.Active()[#Goals.Active()]
expect("Neues Ziel angelegt", itemGoal.kind, "item")
expect("Zielbetrag 5", itemGoal.target, 5)
expectTrue("Item-Ziel als geteilt markiert", itemGoal.shared == true)

-- Gruppenmitglied teilt dasselbe Ziel noch einmal: kein Duplikat
local activeCount = #Goals.Active()
wow.fire("CHAT_MSG_ADDON", "StreamGoal", "S:item:5:itemId=1234;name=Stoff", "PARTY", "Gefährte")
expect("Kein Duplikat", #Goals.Active(), activeCount)

-- Fortschritt vom Gruppenmitglied empfangen
local msgBefore = #wow.addonMessages
wow.fire("CHAT_MSG_ADDON", "StreamGoal", "P:" .. itemGoal.sharedKey .. ":2", "PARTY", "Gefährte")
expect("Fortschritt auf 2 gestiegen", itemGoal.progress, 2)

-- Echo-Schutz: Empfangener Fortschritt darf keine Nachricht senden
PartySync.Flush()
expect("Keine Nachricht als Echo gesendet", #wow.addonMessages, msgBefore)

-- Lokaler Fortschritt sendet P-Nachricht an Gruppe
Goals.Add("kills", function(g) return g.id == killGoal.id end, 1)
expect("Lokaler Fortschritt 1", killGoal.progress, 1)
PartySync.Flush()
expectTrue("Neue Nachricht gesendet", #wow.addonMessages > msgBefore)
local progressMsg = wow.addonMessages[#wow.addonMessages]
expect("P-Nachricht mit Delta 1", progressMsg.message, "P:" .. killGoal.sharedKey .. ":1")

-- Eigene Nachrichten ignorieren
local ownRealm = GetRealmName():gsub("%s", "")
local ownSender = UnitName("player") .. "-" .. ownRealm
wow.fire("CHAT_MSG_ADDON", "StreamGoal", "P:" .. itemGoal.sharedKey .. ":1", "PARTY", ownSender)
expect("Eigene Addon-Nachricht ignoriert", itemGoal.progress, 2)

-- Geheime Nachrichten ignorieren
wow.fire("CHAT_MSG_ADDON", "StreamGoal", wow.SECRET, "PARTY", "Gefährte")
expect("Geheime Nachricht ignoriert", itemGoal.progress, 2)

-- partySync deaktiviert: keine Annahme fremder Ziele
streamGoal.SetSetting("partySync", false)
wow.fire("CHAT_MSG_ADDON", "StreamGoal", "S:explore:3:", "PARTY", "Gefährte")
expect("Bei ausgeschaltetem partySync kein neues Ziel", #Goals.Active(), activeCount)
