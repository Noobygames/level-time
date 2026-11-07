-- Gold-Splits: abgeschlossenes Level schneller als die Bestzeit aller anderen Charaktere, lila in der
-- Split-Liste, auf Wunsch mit Chatzeile beim Level-Up.
local Splits = addon.Splits
local SplitList = addon.SplitList

-- Gold-Zeilen seit Index from
local function goldLines(from)
  local count = 0
  for i = from + 1, #wow.printed do
    if wow.printed[i]:find("Gold", 1, true) then count = count + 1 end
  end
  return count
end

wow.login({ name = "Neu", level = 10, playedSeconds = 0 })
LevelTimerStatsDB.characters["Alt-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Alt", realm = "Testrealm",
  currentLevel = { level = 30, counters = {} }, sessionHistory = {}, killLog = {}, deathLog = {},
  levelHistory = { [10] = { level = 10, seconds = 3600 }, [11] = { level = 11, seconds = 1000 } },
}
expect("Bestzeit anderer Charaktere", Splits.GetBestTime(10), 3600)
expect("aus", LevelTimerDB.goldSplitNotice, false)

-- Level 10 in 50 min: Gold-Split, Meldung ist aus
wow.advance(3000)
wow.fire("TIME_PLAYED_MSG", 3000, 3000)
local printed = #wow.printed
wow.levelUp(11)
expect("ohne Einstellung keine Chatzeile", goldLines(printed), 0)
expect("Gold-Split erkannt", Splits.IsGoldSplit(10), true)
expect("lila in der Liste", Splits.LevelDeltaText(10), "|cffc070ff-10m 00s|r")
local lines = SplitList.BuildLines()
expect("Zeile markiert", lines[2].gold, true)

-- Mit Einstellung: Chatzeile beim Level-Up
addon.Set("goldSplitNotice", true)
wow.advance(900)
wow.fire("TIME_PLAYED_MSG", 3900, 900)
printed = #wow.printed
wow.levelUp(12)
local wanted = string.format(addon.L.GOLD_SPLIT, 11, addon.Format.Duration(900), "-1m 40s")
local found = false
for i = printed + 1, #wow.printed do found = found or wow.printed[i]:find(wanted, 1, true) ~= nil end
expectTrue("Chatzeile", found)

-- Langsamer oder nur teilweise erfasst: kein Gold
printed = #wow.printed
wow.advance(500)
wow.fire("TIME_PLAYED_MSG", 4400, 500)
wow.levelUp(13)
expect("ohne Bestzeit kein Gold", Splits.IsGoldSplit(12), false)
expect("keine Meldung", goldLines(printed), 0)
addon.character.levelHistory[11].partial = true
expect("Teil-Level nie Gold", Splits.IsGoldSplit(11), false)
