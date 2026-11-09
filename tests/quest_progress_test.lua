-- Questfortschritt an die Gruppe: angenommen, je Ziel einmal nach unvollständigem Stand, Quest fertig; Chat-Sperre
local L = addon.L

local function sent(text)
  local count = 0
  for _, message in ipairs(wow.sentChat) do
    if message.message:find(text, 1, true) then count = count + 1 end
  end
  return count
end

local wolves = { text = "Wolf getötet: 7/8", finished = false }
local pelts = { text = "Wolfspelz: 0/4", finished = false }
wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 33, title = "Wölfe jagen", objectives = { wolves, pelts } },
}

local function scan()
  wow.fire("QUEST_LOG_UPDATE")
  wow.update(1)
end

wow.login({ level = 10 })
wow.state.inGroup = true
scan()
wolves.text, wolves.finished = "Wolf getötet: 8/8", true
scan()
expect("aus: nichts", #wow.sentChat, 0)

addon.Set("announceQuestProgress", true)
scan()
expect("erster Durchlauf merkt nur", #wow.sentChat, 0)
pelts.text, pelts.finished = "Wolfspelz: 4/4", true
scan()
expect("letztes Ziel: nur Quest fertig", sent("Wolfspelz: 4/4"), 0)
expect("Quest fertig", sent(string.format(L.QUEST_PROGRESS_COMPLETE, "Wölfe jagen")), 1)
expect("an die Gruppe", wow.sentChat[1].chatType, "PARTY")
expect("bereits erfülltes Ziel nicht", sent("Wolf getötet: 8/8"), 0)
scan()
expect("nur einmal", #wow.sentChat, 1)

-- Neue Quest: angenommen, Ziele erst nach unvollständigem Stand
local boars = { text = "Eber getötet: 0/5", finished = false }
table.insert(wow.state.questLog, { questID = 34, title = "Eberjagd", objectives = { boars } })
wow.fire("QUEST_ACCEPTED", 3, 34)  -- Era: questIndex, questID
scan()
expect("angenommen", sent(string.format(L.QUEST_PROGRESS_ACCEPTED, "Eberjagd")), 1)

-- Chat gesperrt: Meldung fällt weg
wow.state.chatLockdown = true
boars.text, boars.finished = "Eber getötet: 5/5", true
scan()
expect("gesperrt: nichts", sent("Eber getötet: 5/5"), 0)
wow.state.chatLockdown = false

-- Allein: nichts
wow.state.inGroup = false
boars.finished = false
scan()
boars.finished = true
scan()
expect("allein: nichts", sent("Eber getötet: 5/5"), 0)
wow.state.inGroup = true

-- Retail/Forever: C_QuestLog.GetInfo, QUEST_ACCEPTED nur mit questID
C_QuestLog.GetNumQuestLogEntries = function() return #wow.state.questLog, 2 end
C_QuestLog.GetInfo = function(index)
  local quest = wow.state.questLog[index]
  return { questID = quest.questID or 0, title = quest.title, isHeader = quest.isHeader or false }
end
local rats = { text = "Ratte getötet: 0/1", finished = false }
local tails = { text = "Rattenschwanz: 0/2", finished = false }
table.insert(wow.state.questLog, { questID = 35, title = "Ratten", objectives = { rats, tails } })
wow.fire("QUEST_ACCEPTED", 35)
scan()
rats.text, rats.finished = "Ratte getötet: 1/1", true
scan()
expect("Retail: angenommen", sent(string.format(L.QUEST_PROGRESS_ACCEPTED, "Ratten")), 1)
expect("Retail: Ziel (Quest noch offen)", sent("Ratte getötet: 1/1"), 1)
tails.text, tails.finished = "Rattenschwanz: 2/2", true
scan()
expect("Retail: letztes Ziel nicht extra", sent("Rattenschwanz: 2/2"), 0)
expect("Retail: Quest fertig", sent(string.format(L.QUEST_PROGRESS_COMPLETE, "Ratten")), 1)
C_QuestLog.GetNumQuestLogEntries, C_QuestLog.GetInfo = nil, nil

-- Quest als Link, wenn der Client einen liefert (GetQuestLink(questID)); ohne Link bleibt der Titel
local LINK = "|cffffff00|Hquest:36:12|h[Kobolde vertreiben]|h|r"
GetQuestLink = function(questID) return questID == 36 and LINK or nil end
local kobolds = { text = "Kobold getötet: 0/6", finished = false }
local candles = { text = "Kerze: 0/3", finished = false }
table.insert(wow.state.questLog, { questID = 36, title = "Kobolde vertreiben", objectives = { kobolds, candles } })
wow.fire("QUEST_ACCEPTED", 5, 36)  -- Era: questIndex, questID
scan()
expect("angenommen mit Link", sent(string.format(L.QUEST_PROGRESS_ACCEPTED, LINK)), 1)
kobolds.text, kobolds.finished = "Kobold getötet: 6/6", true
scan()
expect("Ziel mit Link", sent(string.format(L.QUEST_PROGRESS_OBJECTIVE, LINK, "Kobold getötet: 6/6")), 1)
candles.text, candles.finished = "Kerze: 3/3", true
scan()
expect("fertig mit Link", sent(string.format(L.QUEST_PROGRESS_COMPLETE, LINK)), 1)
GetQuestLink = nil

