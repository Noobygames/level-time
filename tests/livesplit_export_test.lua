-- LiveSplit-Export: .lss-XML mit Segmenten, Personal Best (kumuliert) und Bestsegmenten.
local LiveSplitExport = addon.LiveSplitExport

expect("TimeSpan", LiveSplitExport.TimeSpan(3725.5), "01:02:05.5000000")
expect("TimeSpan ab einem Tag", LiveSplitExport.TimeSpan(90061), "1.01:01:01.0000000")

wow.login({ name = "Neu", level = 2, playedSeconds = 0 })
expect("ohne Level nichts", LiveSplitExport.Build(addon.characterKey), nil)
SlashCmdList.LEVELTIMER("runs lss")
expect("Hinweis", wow.printed[#wow.printed]:find(addon.L.LIVESPLIT_EMPTY, 1, true) ~= nil, true)

addon.character.levelHistory[2] = { level = 2, seconds = 100 }
addon.character.levelHistory[3] = { level = 3, seconds = 200 }
addon.character.levelHistory[5] = { level = 5, seconds = 50 }  -- nach einer Lücke: nicht im Export
LevelTimerStatsDB.characters["Alt-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Alt", realm = "Testrealm",
  currentLevel = { level = 30, counters = {} }, sessionHistory = {}, killLog = {}, deathLog = {},
  levelHistory = { [3] = { level = 3, seconds = 150 } },
}

local xml = LiveSplitExport.Build(addon.characterKey)
expectTrue("Kopf", xml:find('<Run version="1.7.0">', 1, true) ~= nil)
expectTrue("Kategorie", xml:find("<CategoryName>" .. string.format(addon.L.LIVESPLIT_CATEGORY, 2, 4), 1, true) ~= nil)
local _, segments = xml:gsub("<Segment>", "")
expect("zwei Segmente", segments, 2)
expectTrue("PB kumuliert", xml:find('<SplitTime name="Personal Best">\n          <RealTime>00:05:00.0000000', 1, true) ~= nil)
expectTrue("Bestsegment anderer Charakter",
  xml:find("<BestSegmentTime>\n        <RealTime>00:02:30.0000000", 1, true) ~= nil)
local _, opens = xml:gsub("<Segment>", "")
local _, closes = xml:gsub("</Segment>", "")
expect("XML geschlossen", opens, closes)
