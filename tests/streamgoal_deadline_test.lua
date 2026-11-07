-- Level Time Goals, Roadmap 299: Frist in Echtzeit oder Spielzeit, Restzeit auf der Karte, Status "gescheitert".
local Goals = streamGoal.Goals
local Deadlines = streamGoal.Deadlines
local L = streamGoal.L

wow.login({ level = 10 })

expect("Minuten ohne Einheit", Deadlines.ParseDuration("90"), 90 * 60)
expect("Stunden und Minuten", Deadlines.ParseDuration("1h30m"), 5400)
expect("Tage", Deadlines.ParseDuration("2d"), 2 * 86400)
expect("Tage in der Sprache von Level Time", Deadlines.ParseDuration("1" .. addon.L.UNIT_DAY_SHORT), 86400)
expect("Unsinn", Deadlines.ParseDuration("bald"), nil)

-- Formular: Frist in Echtzeit
SlashCmdList.STREAMGOAL("")
local Manager = streamGoal.Manager
Manager.SelectKind("kills")
Manager.FormWidget("amount"):SetText("5")
Manager.FormWidget("deadline"):SetText("1m")
local goal = Manager.AddFromForm()
expectTrue("Ziel mit Frist", goal ~= nil and goal.deadline ~= nil)
expect("Echtzeit", goal.deadline.mode, Deadlines.REAL)
expect("Restzeit", Deadlines.Remaining(goal), 60)
expect("Karte zeigt Stand und Restzeit", StreamGoalCard1.time._text,
  "0 / 5  " .. string.format(L.SG_DEADLINE_LEFT, addon.Format.Clock(60)))

Manager.FormWidget("deadline"):SetText("morgen")
Manager.FormWidget("amount"):SetText("5")
expect("ungültige Frist: kein Ziel", Manager.AddFromForm(), nil)
StreamGoalWindow:Hide()

wow.advance(30)
wow.update(1)
expect("Karte zählt herunter", StreamGoalCard1.time._text,
  "0 / 5  " .. string.format(L.SG_DEADLINE_LEFT, addon.Format.Clock(30)))
wow.advance(31)
wow.update(1)
expect("abgelaufen = gescheitert", goal.status, Goals.FAILED)
expect("Grund", goal.failReason, L.SG_FAIL_DEADLINE)
expect("Chat meldet Scheitern", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_FAILED, Goals.Title(goal),
  L.SG_FAIL_DEADLINE), 1, true) ~= nil, true)
expect("in der Historie", Goals.History()[1], goal)

-- Spielzeit-Frist über den Befehl; zählt nur, während der Charakter spielt
SlashCmdList.STREAMGOAL("add custom Ohne Tod durch RFC")
local custom = Goals.Active()[1]
wow.fire("TIME_PLAYED_MSG", 1000, 100)
SlashCmdList.STREAMGOAL("deadline " .. custom.id .. " 2h played")
expect("Spielzeit-Frist", custom.deadline.mode, Deadlines.PLAYED)
expect("Ende in Spielzeit", custom.deadline.at, 1000 + 7200)
expect("Restzeit Spielzeit", Deadlines.Text(custom), string.format(L.SG_DEADLINE_LEFT_PLAYED, addon.Format.Clock(7200)))
SlashCmdList.STREAMGOAL("deadline " .. custom.id .. " off")
expect("Frist entfernt", custom.deadline, nil)
SlashCmdList.STREAMGOAL("deadline " .. custom.id .. " 3")
expect("Echtzeit in Minuten", custom.deadline.seconds, 180)

-- Echtzeit läuft auch ausgeloggt: nach dem Login sofort gescheitert
wow.logout()
wow.advance(200)
wow.login()
wow.update(1)
expect("nach dem Login abgelaufen", custom.status, Goals.FAILED)
