-- Level Time Goals, Roadmap 310: tägliche und wöchentliche Ziele, Serie über erreichte Zeiträume.
local Goals = streamGoal.Goals
local Recurring = streamGoal.Recurring
local L = streamGoal.L
local DAY = 86400

wow.login({ level = 10 })

local function nextDay()
  wow.advance(DAY)
  wow.update(60)
end

-- Täglich: 2 Kills je Tag (über das Formular)
SlashCmdList.STREAMGOAL("")
local Manager = streamGoal.Manager
Manager.SelectKind("kills")
Manager.FormWidget("amount"):SetText("2")
expectTrue("Auswahl Täglich", wow.click(L.SG_FORM_REPEAT_NONE))
local first = Manager.AddFromForm()
StreamGoalWindow:Hide()
expect("täglich", first.recur.period, Recurring.DAILY)
expect("Zeile auf der Karte", Goals.Body(first), string.format(L.SG_REPEAT_LINE, L.SG_FORM_REPEAT_DAILY, 0))

local function kill()
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 45 Erfahrung.")
end

kill()
kill()
expect("Tag 1 erreicht", first.status, Goals.DONE)
expect("Serie 1", first.recur.streak, 1)
expect("vor Mitternacht kein neues", #Goals.Active(), 0)

nextDay()
local second = Goals.Active()[1]
expectTrue("neuer Tag: neues Ziel", second ~= nil and second ~= first)
expect("Serie übernommen", second.recur.streak, 1)
expect("Stand neu", second.progress, 0)
kill()
kill()
expect("Serie 2", second.recur.streak, 2)

-- Ein Tag ohne Erfolg: scheitert, Serie 0
nextDay()
local third = Goals.Active()[1]
kill()
nextDay()
expect("verpasst = gescheitert", third.status, Goals.FAILED)
expect("Grund Zeitraum", third.failReason, L.SG_FAIL_PERIOD)
local fourth = Goals.Active()[1]
expect("Serie zurück auf 0", fourth.recur.streak, 0)
expect("beste Serie bleibt", fourth.recur.best, 2)

-- Abgebrochen: kommt nicht wieder
Goals.Cancel(fourth.id)
nextDay()
expect("abgebrochen bleibt weg", #Goals.Active(), 0)

-- Wöchentlich per Befehl; Montag als Wochenbeginn
SlashCmdList.STREAMGOAL("add custom Wochenziel")
local weekly = Goals.Active()[1]
SlashCmdList.STREAMGOAL("repeat " .. weekly.id .. " weekly")
expect("wöchentlich", weekly.recur.period, Recurring.WEEKLY)
local monday = Recurring.Key(Recurring.WEEKLY)
expect("Wochenschlüssel ist ein Montag", date("*t", time({ year = tonumber(monday:sub(1, 4)),
  month = tonumber(monday:sub(6, 7)), day = tonumber(monday:sub(9, 10)), hour = 12 })).wday, 2)
SlashCmdList.STREAMGOAL("repeat " .. weekly.id .. " monthly")
expect("unbekannter Zeitraum", wow.printed[#wow.printed]:find(L.SG_ERR_REPEAT, 1, true) ~= nil, true)
