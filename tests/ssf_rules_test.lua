-- SSF-Regelhelfer: Ruhe-XP in Balken, Logouts, Instanzen, Uhr, Hinweis bei Handel/Post/Auktionshaus.
local SsfRules = addon.SsfRules

wow.login({ name = "Neu", level = 5, xpMax = 1000, playedSeconds = 0 })
expect("aus: keine Zeilen", #SsfRules.BuildLines(), 0)
addon.Alerts.Clear()
wow.fire("TRADE_SHOW")
expect("aus: kein Hinweis", LevelTimerNotice:IsShown(), false)

addon.Set("ssfCategory", "1-20")
addon.character.levelHistory[3] = { level = 3, seconds = 100, xp = 800, counters = { xpRested = 400 } }
addon.character.levelHistory[4] = { level = 4, seconds = 100, xp = 1000, counters = { xpRested = 1000 } }
addon.character.levelHistory[25] = { level = 25, seconds = 100, xp = 1000, counters = { xpRested = 9000 } }  -- außerhalb
addon.Stats.Increment(addon.Stats.XP_RESTED, 600)
expectNear("Balken", SsfRules.RestedBars(SsfRules.GetCategory()), 0.5 + 1 + 0.6)

local lines = SsfRules.BuildLines()
expect("Titel", lines[1][1], string.format(addon.L.SSF_TITLE, "1-20"))
expect("über der Grenze", lines[2][3]:find(addon.L.SSF_OVER, 1, true) ~= nil, true)
expect("Logouts", lines[3][2], "|cff40ff400 / 3|r")
expect("Uhr mit Datum", lines[5][2], date("%Y-%m-%d %H:%M:%S"))

-- Hinweis bei Handel, Post und Auktionshaus
for _, event in ipairs({ "TRADE_SHOW", "MAIL_SHOW", "AUCTION_HOUSE_SHOW" }) do
  addon.Alerts.Clear()
  wow.fire(event)
  expect("Hinweis " .. event, LevelTimerNotice.title:GetText(), addon.L.SSF_WARNING_TITLE)
end

-- /reload zählt nicht, ein echter Logout schon
wow.logout()
wow.login()
expect("reload kein Logout", SsfRules.GetLogouts(), 0)
wow.logout()
wow.advance(3600)
wow.login()
expect("Logout gezählt", SsfRules.GetLogouts(), 1)

-- In der Split-Liste unter den Leveln
addon.Set("showWorldRecords", false)
local footer = addon.SplitList.BuildFooterLines()
expect("Zeilen in der Split-Liste", footer[#footer][1], addon.L.SSF_CLOCK)
