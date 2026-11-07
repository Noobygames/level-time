-- Graue Quests aufräumen und "Questlog fast voll" (Roadmap 344), Classic Era: grau über GetQuestGreenRange,
-- Abbruch nur nach Rückfrage, eine Quest je Schritt.
local L = addon.L
local QuestCleanup = addon.QuestCleanup

C_QuestLog.IsQuestTrivial = nil  -- Era kennt es nicht
C_QuestLog.GetMaxNumQuestsCanAccept = function() return 6 end
function GetQuestGreenRange() return 5 end
local abandoned = {}
local selected
function SelectQuestLogEntry(index) selected = index end
function SetAbandonQuest() end
function AbandonQuest()
  local quest = table.remove(wow.state.questLog, selected)
  table.insert(abandoned, quest.questID)
end
QuestLogFrame = CreateFrame("Frame", "QuestLogFrame")

wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 1, title = "Alt", level = 4 },
  { questID = 2, title = "Grenzfall", level = 15 },
  { questID = 3, title = "Uralt", level = 2 },
  { questID = 4, title = "Neu", level = 20 },
}

wow.login({ level = 20 })
local gray = QuestCleanup.GrayQuests()
expect("zwei graue (Abstand > 5)", #gray, 2)
expect("erste graue", gray[1].questID, 1)

-- Knopf am Questlog mit Anzahl
addon.Set("questCleanupButton", true)
-- Klick: nur Rückfrage, noch nichts abgebrochen
wow.popup = nil
expectTrue("Knopf mit Anzahl", wow.click(string.format(L.QUEST_CLEANUP_BUTTON, 2)))
expect("Rückfrage", wow.popup.name, "LEVELTIMER_ABANDON_GRAY_QUESTS")
expect("Anzahl in der Rückfrage", wow.popup.text, 2)
expect("noch nichts abgebrochen", #abandoned, 0)

-- Bestätigt: eine je Schritt
StaticPopupDialogs.LEVELTIMER_ABANDON_GRAY_QUESTS.OnAccept(nil, wow.popup.data)
expect("erste abgebrochen", abandoned[1], 1)
expect("zweite wartet", #abandoned, 1)
wow.runTimers()
expect("zweite abgebrochen", abandoned[2], 3)
expect("Rest bleibt", #wow.state.questLog, 3)

-- Questlog fast voll: nach der Annahme, einmal
addon.Set("warnQuestLogFull", true)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
table.insert(wow.state.questLog, { questID = 5, title = "Fünf", level = 20 })
table.insert(wow.state.questLog, { questID = 6, title = "Sechs", level = 20 })
wow.fire("QUEST_ACCEPTED", 5, 6)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
local function warnings()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(string.format(L.QUEST_LOG_FULL, 4, 6), 1, true) then count = count + 1 end
  end
  return count
end
expect("Hinweis bei 4 von 6", warnings(), 1)
wow.fire("QUEST_ACCEPTED", 5, 6)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expect("nur einmal", warnings(), 1)
expect("Fehler?", #wow.errors, 0)
