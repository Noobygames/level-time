-- Level Time Goals, Roadmap 308: Belohnungstext und Punkte je Ziel, Gesamtpunktzahl.
local Goals = streamGoal.Goals
local Rewards = streamGoal.Rewards
local L = streamGoal.L

wow.login({ level = 10 })

SlashCmdList.STREAMGOAL("")
local Manager = streamGoal.Manager
Manager.SelectKind("custom")
Manager.FormWidget("text"):SetText("RFC ohne Tod")
Manager.FormWidget("reward"):SetText("Zuschauer wählen die nächste Zone")
Manager.FormWidget("points"):SetText("25")
local goal = Manager.AddFromForm()
StreamGoalWindow:Hide()
expect("Belohnung", goal.reward, "Zuschauer wählen die nächste Zone")
expect("Punkte", goal.points, 25)
local line = string.format(L.SG_REWARD_LINE, goal.reward) .. " · " .. string.format(L.SG_POINTS_LINE, 25)
expect("Zeile auf der Karte", StreamGoalCard1.body._text, line)

expect("zu viele Punkte", select(2, Goals.Create("custom", { text = "x" }, nil, { points = 99999 })),
  string.format(L.SG_ERR_POINTS, Rewards.MAX_POINTS))

-- Einblendung beim Erreichen nennt die Belohnung
addon.Alerts.Clear()
Goals.Step(goal.id, 1)
expect("erreicht", goal.status, Goals.DONE)
expect("Einblendung mit Belohnung", LevelTimerNotice.body._text, Goals.Title(goal) .. "\n" .. line)
expect("Gesamtpunkte", Rewards.TotalPoints(), 25)

-- Befehle
SlashCmdList.STREAMGOAL("add kills 5")
local kills = Goals.Active()[1]
SlashCmdList.STREAMGOAL("points " .. kills.id .. " 10")
expect("Punkte per Befehl", kills.points, 10)
SlashCmdList.STREAMGOAL("reward " .. kills.id .. " Ein Lied singen")
expect("Belohnung per Befehl", kills.reward, "Ein Lied singen")
SlashCmdList.STREAMGOAL("reward " .. kills.id .. " off")
expect("Belohnung entfernt", kills.reward, nil)
SlashCmdList.STREAMGOAL("points " .. kills.id .. " viele")
expect("ungültige Punkte", kills.points, 10)
SlashCmdList.STREAMGOAL("points")
expect("Summe im Chat", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_POINTS, 25, 25), 1, true) ~= nil, true)
