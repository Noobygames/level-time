-- Speedrun-Rekorde: Vergleich der /played-Zeit beim Erreichen eines Levels mit dem Rekord je Abschnitt.
local L = addon.L
local WorldRecords = addon.WorldRecords

-- Feste Testdaten statt der erzeugten Datei (die ändert sich mit jedem "make records")
addon.SpeedrunRecordsData = {
  source = "test",
  fetched = "2026-10-02",
  brackets = {
    { label = "1-10", level = 10,
      best = { seconds = 3331, runner = "Schnell", class = "PALADIN", date = "2025-11-20" },
      classes = {
        PALADIN = { seconds = 3331, runner = "Schnell", class = "PALADIN", date = "2025-11-20" },
        WARRIOR = { seconds = 3635, runner = "Krieger", class = "WARRIOR", date = "2025-04-26" },
      } },
    { label = "1-20", level = 20,
      best = { seconds = 18369, runner = "Jäger", class = "HUNTER", date = "2026-08-31" },
      classes = {} },
  },
}

wow.login({ level = 12, class = "WARRIOR" })
wow.fire("TIME_PLAYED_MSG", 5000, 100)  -- /played gesamt 5000 s
addon.character.levelHistory[9] = { level = 9, seconds = 400, totalPlayed = 3000, counters = {} }

-- Standard: Rekord der eigenen Klasse, ohne Klassenrekord der Gesamtrekord
local comparisons = WorldRecords.GetComparisons()
expect("1-10 Klassenrekord", comparisons[1].record.runner, "Krieger")
expect("1-10 erreicht", comparisons[1].reached, true)
expect("1-10 eigene Zeit beim Erreichen", comparisons[1].ownSeconds, 3000)
expect("1-10 schneller", comparisons[1].delta, 3000 - 3635)
expect("1-20 ohne Klassenrekord: gesamt", comparisons[2].record.runner, "Jäger")
expect("1-20 noch nicht erreicht", comparisons[2].reached, false)
expect("1-20 laufende /played-Zeit", comparisons[2].ownSeconds, 5000)

addon.Set("worldRecordScope", "overall")
expect("Gesamtrekord", WorldRecords.GetComparisons()[1].record.runner, "Schnell")

-- Split-Liste: Rekorde als eigene Zeilen, einzeln abschaltbar, dazu der Stand der Daten
local function footerLabels()
  local labels = {}
  for _, line in ipairs(addon.SplitList.BuildFooterLines()) do labels[line[1]] = line end
  return labels
end
local recordRow = string.format(L.WORLD_RECORD_ROW, "1-10")
expectTrue("Rekord-Zeile", footerLabels()[recordRow] ~= nil)
expectTrue("Stand der Rekorde", footerLabels()[L.RECORDS_AGE] ~= nil)
expect("Stand als lokalisiertes Datum", footerLabels()[L.RECORDS_AGE][2], "02.10.2026")
addon.Set("language", "enUS")
expect("Stand auf Englisch", footerLabels()[L.RECORDS_AGE][2], "10/02/2026")
addon.Set("language", "deDE")
LevelTimerDB.recordBrackets["1-10"] = false
expect("Abschnitt ausblendbar", footerLabels()[recordRow], nil)
expectTrue("anderer Abschnitt bleibt", footerLabels()[string.format(L.WORLD_RECORD_ROW, "1-20")] ~= nil)
LevelTimerDB.recordBrackets["1-10"] = nil
addon.Set("showRecordsAge", false)
expect("Stand ausblendbar", footerLabels()[L.RECORDS_AGE], nil)
addon.Set("splitListShowPlayed", false)
expect("/played ausblendbar", footerLabels()[L.SPLIT_LIST_PLAYED], nil)
addon.Set("showWorldRecords", false)
expect("Rekorde ausblendbar", footerLabels()[recordRow], nil)
addon.Set("showWorldRecords", true)

-- Alter der Daten in Tagen (Uhr im Stub: November 2023, Daten vom 2026-10-02 => 0)
expect("Alter nie negativ", WorldRecords.GetAgeDays(), 0)
wow.state.clock = time({ year = 2026, month = 10, day = 14, hour = 18 })
expect("Alter in Tagen", WorldRecords.GetAgeDays(), 12)

-- Eigene Größe der Split-Liste
addon.Set("showSplitList", true)
addon.Frames.SetScale("splitList", 1.4)
expect("eigene Größe", LevelTimerSplits:GetScale(), 1.4)

-- Historie: alle Rekorde, eigene Klasse hervorgehoben
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Speedrun", wow.click(L.HISTORY_GROUP_SPEEDRUN))
expectTrue("Unterreiter Rekorde", wow.click(L.HISTORY_TAB_WORLD_RECORDS))
local rows = wow.shownTable():GetVisibleRecords()
expect("gesamt und je Klasse", #rows, 4)
expect("eigene Klasse markiert", rows[3].isCurrent, true)
expect("Abweichung zum Klassenrekord", rows[3].delta, 3000 - 3635)
