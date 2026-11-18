-- Prognose des nächsten Abschnitts in der Split-Liste: Endzeit gegen PB, Summe der Bestzeiten und Rekord.
local BracketForecast = addon.BracketForecast
local SplitList = addon.SplitList

wow.login({ name = "Neu", level = 8, class = "WARRIOR", playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 2000, 0)  -- /played gesamt 2000 s
for level = 1, 7 do
  addon.character.levelHistory[level] = { level = level, seconds = 300 }
end
local otherLevels = {}
for level = 1, 9 do
  otherLevels[level] = { level = level, seconds = level <= 7 and 350 or 400 }
end
otherLevels[9].totalPlayed = 3400  -- erreichte Level 10 bei /played 3400 s
LevelTimerStatsDB.characters["Alt-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Alt", realm = "Testrealm", class = "MAGE",
  currentLevel = { level = 30, counters = {} }, levelHistory = otherLevels, sessionHistory = {}, killLog = {}, deathLog = {},
}
addon.Forecast.SecondsToLevel = function(level) return level == 10 and 1500 or nil end

local forecast = BracketForecast.Get()
expect("nächster Abschnitt", forecast.label, "1-10")
expect("Prognose = /played + Rest", forecast.forecast, 3500)
expect("PB", forecast.pb, 3400)
expect("Summe der Bestzeiten", forecast.sumOfBest, 7 * 300 + 2 * 400)
expect("Klassenrekord Krieger", forecast.record, 3635)

expect("standardmäßig aus", LevelTimerDB.splitListShowForecast, false)
addon.Set("showWorldRecords", false)
addon.Set("splitListShowTotal", false)
addon.Set("splitListShowPlayed", false)
expect("ohne Prognose keine Zeilen", #SplitList.BuildFooterLines(), 0)
addon.Set("splitListShowForecast", true)
local lines = SplitList.BuildFooterLines()
expect("Prognose und drei Vergleiche", #lines, 4)
expect("Titel", lines[1][1], string.format(addon.L.SPLIT_FORECAST, "1-10"))
expect("gegen PB langsamer", lines[2][3], addon.Format.SplitDelta(100))
expect("gegen Rekord schneller", lines[4][3], addon.Format.SplitDelta(-135))

-- Ausgeblendeter Abschnitt zählt nicht, ohne Prognose keine Zeilen
LevelTimerDB.recordBrackets["1-10"] = false
expect("nächster gezeigter Abschnitt", BracketForecast.Get(), nil)  -- Level 20: keine Prognose im Test
expect("keine Zeilen ohne Prognose", #SplitList.BuildFooterLines(), 0)
