-- Quest-XP im Questlog (Roadmap 270): Summe fertig/offen, "Abgabe reicht für Level-Up", XP-Balken.
local QuestLogXp = addon.QuestLogXp

local function statLine(setting)
  for _, entry in ipairs(addon.STAT_LINES) do
    if entry.setting == setting then return entry end
  end
end

-- Era/TBC: fertig über isComplete == 1 aus GetQuestLogTitle (Stub hat kein C_QuestLog.ReadyForTurnIn)
wow.state.questLog = {
  { title = "Gebiet", isHeader = true },
  { questID = 1, title = "Wölfe", rewardXp = 300, isComplete = 1 },
  { questID = 2, title = "Kobolde", rewardXp = 250 },
  { questID = 3, title = "Gescheitert", rewardXp = 100, isComplete = -1 },
  { questID = 4, title = "Ohne XP", rewardXp = 0, isComplete = 1 },
}
wow.login({ level = 10, xp = 600, xpMax = 1000 })

local ready, open = QuestLogXp.Get()
expect("fertig", ready, 300)
expect("offen (gescheitert zählt als offen)", open, 350)
expect("fehlen nach Abgabe", QuestLogXp.MissingAfterTurnIn(), 100)

local line = statLine("showQuestLogXp")
expect("Zeile fertig", line.rows[1].value(addon.Stats.LEVEL), "300")
expect("Zeile offen", line.rows[2].value(addon.Stats.LEVEL), "350")
expect("reicht nicht", line.rows[3].value(addon.Stats.LEVEL), string.format(addon.L.QUEST_XP_LEVEL_UP_NO, "100"))

-- Zwischengespeichert bis QUEST_LOG_UPDATE
wow.state.questLog[4].isComplete = 1
expect("ohne Ereignis unverändert", (QuestLogXp.Get()), 300)
wow.fire("QUEST_LOG_UPDATE")
expect("nach Update", (QuestLogXp.Get()), 400)
expectTrue("reicht jetzt", line.rows[3].value(addon.Stats.LEVEL):find(string.format(addon.L.QUEST_XP_LEVEL_UP_YES, "0"), 1, true) ~= nil)

-- Retail/Forever: ReadyForTurnIn statt isComplete; geheime Werte gelten als nicht fertig
C_QuestLog.ReadyForTurnIn = function(questID) return questID == 2 end
wow.fire("QUEST_LOG_UPDATE")
ready, open = QuestLogXp.Get()
expect("Retail fertig", ready, 250)
expect("Retail offen", open, 400)
C_QuestLog.ReadyForTurnIn = nil

-- XP-Balken: gelbes Stück bis XP + fertige Quests, nur mit Einstellung
wow.fire("QUEST_LOG_UPDATE")
addon.Set("questXpOnBar", true)
wow.update(1)
expect("Einstellung an", addon.db.questXpOnBar, true)

-- Max-Level: keine Werte
wow.state.level = 60
addon.level = 60
expect("Max-Level", line.rows[1].value(addon.Stats.LEVEL), "-")
