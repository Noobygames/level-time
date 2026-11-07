-- "Quest fertig" als Einblendung (Roadmap 343): Karte mit Questname und XP bei abgabebereit, optional je Ziel;
-- der erste Durchlauf zählt nur den Stand, im Kampf erst danach.
local L = addon.L
local Alerts = addon.Alerts

local wolves = { text = "Wolf getötet: 7/8", finished = false }
local pelts = { text = "Wolfspelz: 3/4", finished = false }
wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 33, title = "Wölfe jagen", objectives = { wolves, pelts }, rewardXp = 1250 },
}
local function scan()
  wow.fire("QUEST_LOG_UPDATE")
  wow.update(1)
end

wow.login({ level = 10 })
addon.Set("alertStyle", "banner")
addon.Set("alertQuestComplete", true)
addon.Set("alertQuestObjective", true)
scan()  -- nur Stand
expect("erster Durchlauf: nichts", LevelTimerNotice:IsShown(), false)

-- Ein Ziel erfüllt, Quest noch offen: Ziel-Einblendung
Alerts.Clear()
wolves.text, wolves.finished = "Wolf getötet: 8/8", true
scan()
expect("Ziel-Karte", LevelTimerNotice.title:GetText(), string.format(L.ALERT_QUEST_OBJECTIVE, "Wolf getötet: 8/8"))
expect("Questname darunter", LevelTimerNotice.body:GetText(), "Wölfe jagen")

-- Letztes Ziel: nur "Quest fertig" mit XP (Classic: isComplete = 1)
Alerts.Clear()
pelts.text, pelts.finished = "Wolfspelz: 4/4", true
wow.state.questLog[2].isComplete = 1
scan()
expect("Quest fertig", LevelTimerNotice.title:GetText(), string.format(L.ALERT_QUEST_COMPLETE, "Wölfe jagen"))
expect("XP", LevelTimerNotice.body:GetText(), string.format(L.QUEST_COMPLETE_XP, addon.Format.Number(1250)))
Alerts.Clear()
scan()
expect("nur einmal", LevelTimerNotice:IsShown(), false)

-- Im Kampf zurückgehalten
local boars = { text = "Eber: 0/1", finished = false }
table.insert(wow.state.questLog, { questID = 34, title = "Eberjagd", objectives = { boars } })
scan()
wow.state.inCombat = true
boars.text, boars.finished = "Eber: 1/1", true
wow.state.questLog[3].isComplete = 1
scan()
expect("im Kampf: nichts", LevelTimerNotice:IsShown(), false)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf", LevelTimerNotice.title:GetText(), string.format(L.ALERT_QUEST_COMPLETE, "Eberjagd"))

-- Aus: nichts
Alerts.Clear()
addon.Set("alertQuestComplete", false)
addon.Set("alertQuestObjective", false)
table.insert(wow.state.questLog, { questID = 35, title = "Kobolde", objectives = { { text = "Kobold: 0/1", finished = false } } })
scan()
wow.state.questLog[4].objectives[1].finished = true
wow.state.questLog[4].isComplete = 1
scan()
expect("aus: nichts", LevelTimerNotice:IsShown(), false)
expect("Fehler?", #wow.errors, 0)
