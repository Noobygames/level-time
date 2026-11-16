-- Gruppen-Questabgleich: Addon-Nachrichten (Präfix ns.ADDON_ID .. "Q"), Snapshot, Ziel-Updates, Tooltip, Cache und Drossel
local PartyQuestSync = addon.PartyQuestSync
local L = addon.L

local wolves = { text = "Wolf getötet: 3/8", numFulfilled = 3, numRequired = 8, finished = false }
wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 100, title = "Wölfe jagen", objectives = { wolves } },
}

wow.login({ name = "Testchar", realm = "Testrealm", level = 10 })
expect("Präfix registriert", wow.addonPrefixes[addon.PartyQuestSync.PREFIX], true)

-- Standard: partyQuestSync ist false (sendet nichts, kein Peer-Stand)
wow.state.inGroup = true
wow.state.party = { "Thrall" }
wow.fire("GROUP_ROSTER_UPDATE")
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "Q", "PARTY", "Thrall-Realm")
wow.update(2)
expect("Standard aus: keine Addon-Nachrichten gesendet", #wow.addonMessages, 0)
expect("Standard aus: keine Peers", PartyQuestSync.GetPeerCount(), 0)

-- Einschalten
addon.Set("partyQuestSync", true)
expect("Einstellung aktiv", addon.db.partyQuestSync, true)

-- Erster Durchlauf initialisiert QuestWatch
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)

-- Roster-Update sendet Anfrage "Q" an die Gruppe
wow.fire("GROUP_ROSTER_UPDATE")
wow.update(1)
expectTrue("Anfrage Q gesendet", #wow.addonMessages > 0)
local lastMsg = wow.addonMessages[#wow.addonMessages]
expect("Präfix der Anfrage", lastMsg.prefix, addon.PartyQuestSync.PREFIX)
expect("Inhalt der Anfrage", lastMsg.message, "Q")
expect("Kanal der Anfrage", lastMsg.chatType, "PARTY")

-- Gedrosselt: innerhalb des Cooldowns keine erneute Anfrage
local countBefore = #wow.addonMessages
wow.fire("GROUP_ROSTER_UPDATE")
wow.update(1)
expect("Anfrage gedrosselt", #wow.addonMessages, countBefore)

-- Snapshot senden (z.B. auf BroadcastSnapshot oder auf eingehendes "Q")
local msgCountBefore = #wow.addonMessages
PartyQuestSync.BroadcastSnapshot()
wow.update(1)
expectTrue("Snapshot gesendet", #wow.addonMessages > msgCountBefore)
local snapMsg = wow.addonMessages[#wow.addonMessages]
expect("Snapshot-Präfix", snapMsg.prefix, addon.PartyQuestSync.PREFIX)
expect("Snapshot-Kanal", snapMsg.chatType, "PARTY")
expectTrue("Snapshot-Inhalt enthält Quest 100", snapMsg.message:find("S:100:1=3/8") ~= nil)

-- Questziel-Änderung über QuestWatch erzeugt einzelnes Update "U:100:1:4:8"
msgCountBefore = #wow.addonMessages
wolves.text = "Wolf getötet: 4/8"
wolves.numFulfilled = 4
wow.fire("QUEST_LOG_UPDATE")
wow.update(1) -- QuestWatch.Scan (0.5s)
wow.update(1) -- flush (1s)
expectTrue("Ziel-Update gesendet", #wow.addonMessages > msgCountBefore)
local updateMsg = wow.addonMessages[#wow.addonMessages]
expect("Update-Präfix", updateMsg.prefix, addon.PartyQuestSync.PREFIX)
expect("Update-Inhalt", updateMsg.message, "U:100:1:4:8")

-- Eingehende Peer-Nachrichten von Gruppenmitgliedern empfangen
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "U:100:1:3:8", "PARTY", "Thrall-Realm")
local peers = PartyQuestSync.GetPeers()
expectTrue("Peer Thrall im Speicher", peers["Thrall"] ~= nil)
expect("Peer-Anzahl", PartyQuestSync.GetPeerCount(), 1)

local progress = PartyQuestSync.PeerProgress(100)
expect("PeerProgress Anzahl", #progress, 1)
expect("PeerProgress Spieler", progress[1].player, "Thrall")
expect("PeerProgress Stand", progress[1].summary, "3/8")
expect("PeerProgress nicht ready", progress[1].ready, false)

local lines = PartyQuestSync.TooltipLines(100)
expectTrue("TooltipLines vorhanden", #lines == 1)
expectTrue("Tooltip enthält Thrall", lines[1]:find("Thrall") ~= nil)
expectTrue("Tooltip enthält 3/8", lines[1]:find("3/8") ~= nil)

-- Quest-Link im GameTooltip anreichern
GameTooltip:ClearLines()
GameTooltip:SetHyperlink("quest:100")
expectTrue("GameTooltip Zeile hinzugefügt", GameTooltip._lines and #GameTooltip._lines > 0)
expectTrue("GameTooltip enthält Gruppenfortschritt", GameTooltip._lines[#GameTooltip._lines]:find("Thrall") ~= nil)

-- Quest abgabebereit: "C:100"
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "C:100", "PARTY", "Thrall-Realm")
progress = PartyQuestSync.PeerProgress(100)
expect("nach C:100 ready", progress[1].ready, true)
expect("nach C:100 summary Fertig", progress[1].summary, L.PARTY_QUEST_SYNC_READY)
lines = PartyQuestSync.TooltipLines(100)
expectTrue("Tooltip zeigt Fertig", lines[1]:find(L.PARTY_QUEST_SYNC_READY) ~= nil)

-- Snapshot empfangen: mehrere Quests und Ziele
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "S:200:1=2/5,2=1/1;201:ready", "PARTY", "Jaina-Realm")
expect("Peer-Anzahl 2", PartyQuestSync.GetPeerCount(), 2)
local p200 = PartyQuestSync.PeerProgress(200)
expect("Jaina Quest 200 Fortschritt", p200[1].player, "Jaina")
expect("Jaina Quest 200 Stand", p200[1].summary, "2/5, 1/1")
local p201 = PartyQuestSync.PeerProgress(201)
expect("Jaina Quest 201 Fertig", p201[1].summary, L.PARTY_QUEST_SYNC_READY)
expect("Jaina Quest 201 ready", p201[1].ready, true)

-- Quest abgegeben/entfernt: "R:200"
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "R:200", "PARTY", "Jaina-Realm")
expect("Jaina Quest 200 entfernt", #PartyQuestSync.PeerProgress(200), 0)
expect("Jaina Quest 201 noch da", #PartyQuestSync.PeerProgress(201), 1)

-- Eigene Nachrichten ignorieren (kein Selbsteintrag)
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "U:100:1:7:8", "PARTY", "Testchar-Testrealm")
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "U:100:1:7:8", "PARTY", "Testchar")
expect("Eigener Charakter nicht im Peer-Cache", peers["Testchar"], nil)

-- Realm mit Bindestrich: der Client meldet ihn normalisiert ("AzjolNerub")
wow.state.realm = "Azjol-Nerub"
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "U:100:1:7:8", "PARTY", "Testchar-AzjolNerub")
expect("Eigener Charakter mit Bindestrich-Realm nicht im Peer-Cache", peers["Testchar"], nil)
wow.state.realm = "Testrealm"

-- Nur Gruppenkanäle: Geflüstertes wird ignoriert
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "U:100:1:7:8", "WHISPER", "Fremder-Realm")
expect("Flüstern nicht im Peer-Cache", peers["Fremder"], nil)
local beforeWhisperQ = PartyQuestSync.GetQueueLength()
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "Q", "WHISPER", "Fremder-Realm")
expect("Flüster-Anfrage löst keinen Snapshot aus", PartyQuestSync.GetQueueLength(), beforeWhisperQ)

-- Antwort auf "Q" gedrosselt: zweite Anfrage im Cooldown sendet keinen weiteren Snapshot
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "Q", "PARTY", "Thrall-Realm")
local afterFirstQ = PartyQuestSync.GetQueueLength()
expectTrue("Erste Anfrage beantwortet", afterFirstQ > beforeWhisperQ)
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "Q", "PARTY", "Jaina-Realm")
expect("Zweite Anfrage gedrosselt", PartyQuestSync.GetQueueLength(), afterFirstQ)

-- Geheime Werte (wow.SECRET) sauber ignorieren
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, wow.SECRET, "PARTY", "Thrall-Realm")
wow.fire("CHAT_MSG_ADDON", wow.SECRET, "U:100:1:7:8", "PARTY", "Thrall-Realm")
wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "U:100:1:7:8", "PARTY", wow.SECRET)
expect("Keine Lua-Fehler bei SECRET-Werten", #wow.errors, 0)

-- GROUP_LEFT leert den Peer-Cache
expectTrue("Peers vor GROUP_LEFT vorhanden", PartyQuestSync.GetPeerCount() > 0)
wow.fire("GROUP_LEFT")
expect("Nach GROUP_LEFT keine Peers", PartyQuestSync.GetPeerCount(), 0)
expect("Nach GROUP_LEFT kein Fortschritt", #PartyQuestSync.PeerProgress(100), 0)
expect("Nach GROUP_LEFT keine Tooltip-Zeilen", #PartyQuestSync.TooltipLines(100), 0)
expect("Warteschlange leer", PartyQuestSync.GetQueueLength(), 0)
expect("Keine Lua-Fehler insgesamt", #wow.errors, 0)
