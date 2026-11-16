-- Level-Up: Zusammenfassung im Chat, Timeline und Prognose bis Max-Level.

wow.login({ level = 57, xp = 0, xpMax = 1000, maxLevel = 60, playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 50000, 0)  -- gesamt 50000 s, Level gerade begonnen

---------------------------------------------------------------------------
-- Level-Up-Zusammenfassung
---------------------------------------------------------------------------
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
wow.advance(3600)
local printedBefore = #wow.printed
wow.levelUp(58, 1000)
local summary = wow.printed[printedBefore + 1] or ""
expectTrue("Zusammenfassung nennt neues Level", summary:find("Level 58 erreicht", 1, true) ~= nil)
expectTrue("Zusammenfassung nennt Dauer", summary:find("1h 00m", 1, true) ~= nil)
expectTrue("Zusammenfassung nennt Kills", summary:find("1 Kills", 1, true) ~= nil)

---------------------------------------------------------------------------
-- Timeline
---------------------------------------------------------------------------
local record = addon.character.levelHistory[57]
expectNear("/played beim Level-Up gesichert", record.totalPlayed, 53600)
local milestones = addon.History.GetMilestones(addon.characterKey)
expect("ein Meilenstein", #milestones, 1)
expect("erreichtes Level", milestones[1].reachedLevel, 58)
expectNear("Dauer des Levels", milestones[1].seconds, 3600)

wow.advance(1800)
expectNear("Gesamtzeit läuft nach Level-Up weiter", addon.PlayedTime.GetTotalSeconds(), 55400)

---------------------------------------------------------------------------
-- Prognose bis Max-Level: Level 58 halb fertig nach 30 min, danach noch Level 59
-- Rest Level 58: 500 XP bei 1000 XP/h = 30 min; Level 59: Durchschnitt der Level (1 h) = 60 min
---------------------------------------------------------------------------
wow.state.xp = 500
expectNear("Prognose bis Max-Level", addon.Forecast.SecondsToMaxLevel(), 1800 + 3600)

wow.state.level, addon.level = 60, 60
expect("auf Max-Level keine Prognose", addon.Forecast.SecondsToMaxLevel(), nil)
wow.state.level, addon.level = 58, 58

---------------------------------------------------------------------------
-- Zusammenfassung abschaltbar
---------------------------------------------------------------------------
addon.Set("levelUpSummary", false)
printedBefore = #wow.printed
wow.levelUp(59, 1000)
expect("keine Zusammenfassung wenn aus", #wow.printed, printedBefore)

