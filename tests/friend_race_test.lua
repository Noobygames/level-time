-- Rennen gegen Freunde: Addon-Nachrichten mit Drossel, Antwort mit Level-Zeiten, Spalte in der Split-Liste.
local FriendRace = addon.FriendRace
local SplitList = addon.SplitList

wow.login({ name = "Neu", level = 4, playedSeconds = 0 })
expect("Präfix registriert", wow.addonPrefixes.LevelTimer, true)
addon.character.levelHistory[2] = { level = 2, seconds = 100 }
addon.character.levelHistory[3] = { level = 3, seconds = 200 }

-- Aus: weder Anfrage noch Antwort
wow.state.inGroup = true
wow.fire("GROUP_ROSTER_UPDATE")
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "Q", "WHISPER", "Freund-Testrealm")
wow.update(5)
expect("aus: nichts gesendet", #wow.addonMessages, 0)

addon.Set("friendRace", true)
wow.fire("GROUP_ROSTER_UPDATE")
wow.update(1)
expect("Anfrage an die Gruppe", wow.addonMessages[1].message .. " " .. wow.addonMessages[1].chatType, "Q PARTY")
wow.fire("GROUP_ROSTER_UPDATE")
wow.update(1)
expect("gedrosselt", #wow.addonMessages, 1)

-- Eigene Nachricht kommt zurück: ignoriert
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "Q", "PARTY", "Neu-Testrealm")
wow.update(1)
expect("eigene ignoriert", #wow.addonMessages, 1)

-- Anfrage beantworten: Info und Zeiten, eine Nachricht je Sekunde
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "Q", "WHISPER", "Freund-Testrealm")
wow.update(1)
expect("eine je Sekunde", #wow.addonMessages, 2)
wow.update(1)
expect("Info", wow.addonMessages[2].message, "I:4:WARRIOR")
expect("Zeiten", wow.addonMessages[3].message, "T:2:100,200")
expect("geflüstert", wow.addonMessages[3].target, "Freund-Testrealm")

-- Chat-Sperre: Warteschlange bleibt liegen
wow.state.chatLockdown = true
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "Q", "WHISPER", "Zweiter-Testrealm")
wow.update(3)
expect("gesperrt", #wow.addonMessages, 3)
wow.state.chatLockdown = false
wow.update(1); wow.update(1)
expect("danach gesendet", #wow.addonMessages, 5)

-- Zeiten des Freundes empfangen: Spalte gegen Freund
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "I:9:MAGE", "WHISPER", "Freund-Testrealm")
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "T:2:150,150", "WHISPER", "Freund-Testrealm")
local name, run = FriendRace.Current()
expect("Freund", name, "Freund-Testrealm")
expect("Zeit", run.times[3], 150)
expect("Klasse", run.class, "MAGE")
local lines = SplitList.BuildLines()
expect("gegen Freund Level 3", lines[2].friendText, addon.Format.SplitDelta(50))
expect("gegen Freund Level 2", lines[3].friendText, addon.Format.SplitDelta(-50))
LevelTimerSplits._scripts.OnUpdate(LevelTimerSplits, 1)

-- Level-Up des Freundes: Chatzeile
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "L:10:900", "WHISPER", "Freund-Testrealm")
expectTrue("Level-Up im Chat", wow.printed[#wow.printed]:find(string.format(addon.L.FRIEND_LEVEL_UP,
  "Freund-Testrealm", 10, addon.Format.Duration(900)), 1, true) ~= nil)

-- Eigenes Level-Up an Gruppe und Freunde, die gefragt haben
local before = #wow.addonMessages
wow.advance(300)
wow.fire("TIME_PLAYED_MSG", 300, 300)
wow.levelUp(5)
wow.update(1); wow.update(1); wow.update(1)
local sent = {}
for i = before + 1, #wow.addonMessages do
  local m = wow.addonMessages[i]
  if m.message:find("^L:5:") then table.insert(sent, m.target or m.chatType) end
end
expectTrue("Level-Up gesendet", #sent >= 2)

-- Ungültiges und fremdes Präfix: nichts
wow.fire("CHAT_MSG_ADDON", "Andere", "Q", "WHISPER", "X")
wow.fire("CHAT_MSG_ADDON", "LevelTimer", "T:abc", "WHISPER", "X")
expect("kein Fehler", #wow.errors, 0)
