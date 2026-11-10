-- Optionen, Reiter Speedrun: Split-Liste, Vergleich, Rekorde, Screenshots, SSF.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local addPage, finishPage, addSection, addSlider, addToggles, addChooser, addHint, addSubPage, finishSubPages, toggle, localized, advanced, requires, percent, addVisibilityDropdown, addFrameScaleSlider = O.addPage, O.finishPage, O.addSection, O.addSlider, O.addToggles, O.addChooser, O.addHint, O.addSubPage, O.finishSubPages, O.toggle, O.localized, O.advanced, O.requires, O.percent, O.addVisibilityDropdown, O.addFrameScaleSlider

-- Vergleich der Splits; ein fester Charakter wird per /lt compare Name gewählt
local function addSplitComparisonChooser()
  local Splits = ns.Splits
  addChooser({ label = "SPLIT_COMPARISON", setting = "splitComparison", choices = {
    { value = Splits.BEST, name = localized("COMPARE_CHOICE_BEST") },
    { value = Splits.PERSONAL_BEST, name = localized("COMPARE_CHOICE_PB") },
    { value = Splits.RUN, name = localized("COMPARE_CHOICE_RUN") },
  } })
end

-- Speedrun-Rekorde: schnellster Lauf insgesamt oder der eigenen Klasse
local function addWorldRecordScopeChooser()
  local WorldRecords = ns.WorldRecords
  addChooser({ label = "WORLD_RECORD_SCOPE", setting = "worldRecordScope", choices = {
    { value = WorldRecords.CLASS, name = localized("WORLD_RECORD_OWN_CLASS") },
    { value = WorldRecords.OVERALL, name = localized("WORLD_RECORD_ALL_CLASSES") },
  } })
end

-- SSF-Regelhelfer: aus oder eine Kategorie (SsfRules.lua)
local function addSsfCategoryChooser()
  local choices = { { value = ns.SsfRules.OFF, name = localized("SSF_CATEGORY_OFF") } }
  for _, category in ipairs(ns.SsfRules.ORDER) do
    table.insert(choices, { value = category, name = function() return category end })
  end
  addChooser({ label = "SSF_CATEGORY", setting = "ssfCategory", choices = choices })
end

-- Speedrun: Split-Liste, Vergleich, Speedrun-Rekorde, Screenshots, SSF
addPage("OPTIONS_TAB_SPEEDRUN")
addSubPage("OPTIONS_PAGE_SPLIT_LIST")
addSection("SECTION_SPLIT_LIST")
addToggles({
  toggle("SHOW_SPLIT_LIST", "showSplitList"),
  requires(toggle("SHOW_SPLIT_HEADER", "splitListHeader"), "showSplitList"),
  requires(toggle("SHOW_SPLIT_TOTAL", "splitListShowTotal"), "showSplitList"),
  requires(toggle("SHOW_SPLIT_PLAYED", "splitListShowPlayed"), "showSplitList"),
  requires(toggle("SHOW_SPLIT_FORECAST", "splitListShowForecast"), "showSplitList"),
  requires(toggle("SHOW_CUSTOM_SPLITS", "splitListShowCustom"), "showSplitList"),
})
addFrameScaleSlider("SPLIT_LIST_SIZE", "splitList", function(db) return db.showSplitList end)
O.addFramePreview("SPLIT_LIST_PREVIEW", "splitList")
addVisibilityDropdown("SPLIT_LIST_VISIBILITY", "splitListVisibility")
addSlider(requires({
  label = "SPLIT_LIST_ROWS",
  setting = "splitListRows",
  min = ns.SplitList.MIN_ROWS,
  max = ns.SplitList.MAX_ROWS,
  step = 1,
  get = function(db) return db.splitListRows end,
  set = function(value) ns.SetDeferred("splitListRows", value) end,
  format = tostring,
}, "showSplitList"))
-- Vergleich: wogegen die Splits laufen, Toleranz, Hinweise bei Bestzeiten, Rennen gegen Freunde
addSubPage("OPTIONS_PAGE_COMPARE")
addSplitComparisonChooser()
addToggles({
  advanced(toggle("PB_SAME_CLASS", "pbSameClass")),
  toggle("GOLD_SPLIT_NOTICE", "goldSplitNotice"),
  toggle("QUEST_SPLIT_NOTICE", "questSplitNotice"),
  toggle("FRIEND_RACE", "friendRace"),
})
addSlider({
  label = "SPLIT_TOLERANCE",
  advanced = true,
  setting = "splitTolerancePercent",
  min = 0,
  max = ns.Splits.MAX_TOLERANCE_PERCENT,
  step = 1,
  get = function(db) return db.splitTolerancePercent end,
  set = function(value) ns.SetDeferred("splitTolerancePercent", value) end,
  format = function(value) return value == 0 and L.TOLERANCE_OFF or percent(value) end,
})
addSubPage("OPTIONS_PAGE_RECORDS")
addSection("SECTION_WORLD_RECORDS")
local recordToggles = {
  toggle("SHOW_WORLD_RECORDS", "showWorldRecords"),
  advanced(toggle("SHOW_RECORDS_AGE", "showRecordsAge")),
}
-- Ein Schalter je Abschnitt der Rekord-Daten (1-10, 1-20, ...)
for _, label in ipairs(ns.WorldRecords.GetBracketLabels()) do
  table.insert(recordToggles, {
    text = function() return string.format(L.WORLD_RECORD_ROW, label) end,
    tip = "RECORD_BRACKET_TIP",
    advanced = true,
    setting = "recordBrackets",
    get = function(db) return db.recordBrackets[label] ~= false end,
    set = function(checked)
      ns.db.recordBrackets[label] = checked
      ns.ApplySettings()
    end,
  })
end
addToggles(recordToggles)
addWorldRecordScopeChooser()
addSubPage("OPTIONS_PAGE_SCREENSHOTS")
addSection("SECTION_SCREENSHOTS")
addToggles({
  toggle("MILESTONE_SCREENSHOTS", "milestoneScreenshots"),
  toggle("SCREENSHOT_FIRST_DUNGEON", "screenshotFirstDungeon"),
  toggle("SCREENSHOT_EPIC_LOOT", "screenshotEpicLoot"),
})
addSubPage("OPTIONS_PAGE_SSF")
addSection("SECTION_SSF")
addSsfCategoryChooser()
addHint("SSF_HINT")
finishSubPages()
finishPage()
