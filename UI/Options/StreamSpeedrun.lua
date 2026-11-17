-- Optionen, Reiter Stream & Speedrun: Stream, Split-Liste, Route, Vergleich, Rekorde, Screenshots, SSF.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local TimerWindow = ns.TimerWindow
local builder, addButton, addOutlineChooser = O.builder, O.addButton, O.addOutlineChooser
local addPage, finishPage, addSection, addSlider, addToggles = O.addPage, O.finishPage, O.addSection, O.addSlider, O.addToggles
local addChooser, addHint, addSubPage, finishSubPages, toggle = O.addChooser, O.addHint, O.addSubPage, O.finishSubPages, O.toggle
local localized, advanced, requires, percent = O.localized, O.advanced, O.requires, O.percent
local addVisibilityDropdown, addFrameScaleSlider = O.addVisibilityDropdown, O.addFrameScaleSlider

-- Hintergrund des Fensters: Standard oder Chroma-Farbe für Streams
local function addBackgroundChooser()
  addChooser({ label = "WINDOW_BACKGROUND", setting = "windowBackground", choices = {
    { value = TimerWindow.BACKGROUND_DEFAULT, name = localized("BACKGROUND_DEFAULT") },
    { value = "green", name = localized("BACKGROUND_GREEN") },
    { value = "magenta", name = localized("BACKGROUND_MAGENTA") },
  } })
end

-- Abkürzung zu den Layouts, die sich für OBS eignen (alle Layouts: Allgemein > Layout)
local STREAM_LAYOUTS = { "text", "clock", "table" }
local function addStreamLayoutChooser()
  local choices = {}
  for i, id in ipairs(STREAM_LAYOUTS) do
    choices[i] = { value = id, name = localized(ns.WindowLayouts.Get(id).label) }
  end
  addChooser({ label = "STREAM_LAYOUT", setting = "windowLayout", choices = choices })
end

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
-- Stream & Speedrun: Stream (Stream-Modus, OBS) und die Speedrun-Seiten Split-Liste, Route, Vergleich, Rekorde, Screenshots, SSF
addPage("OPTIONS_TAB_STREAM_SPEEDRUN")
-- Stream: alles, was nur für Streams gedacht ist (Speedrun hat einen eigenen Reiter), dazu Abkürzungen zu Layout und
-- Kontur, die für OBS zählen (UX S18)
addSubPage("OPTIONS_TAB_STREAM")
addHint("STREAM_MODE_HINT")
addToggles({
  { label = "STREAM_MODE", get = function() return ns.StreamMode.IsEnabled() end,
    set = function(checked) ns.StreamMode.SetEnabled(checked) end },
  toggle("STREAMER_PRIVACY", "streamerPrivacy"),
  toggle("HIGHLIGHT_DEATHS", "highlightDeaths"),
  -- Abkürzung zu "Minimap-Knopf anzeigen" (Allgemein > Minimap), umgekehrt formuliert
  { label = "STREAM_HIDE_MINIMAP", get = function(db) return db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(checked) end, reset = O.minimapReset },
  toggle("SHOW_DEATH_CARD", "showDeathCard"),
  toggle("SHOW_MAX_LEVEL_CARD", "showMaxLevelCard"),
  toggle("OBS_SIGNAL", "obsSignal"),
  toggle("SHOW_SPELL_HISTORY", "showSpellHistory"),
})
addSlider(requires({
  label = "OBS_SIGNAL_SIZE",
  advanced = true,
  setting = "obsSignalSize",
  min = 8,
  max = 64,
  step = 4,
  get = function(db) return db.obsSignalSize end,
  set = function(value) ns.SetDeferred("obsSignalSize", value) end,
  format = function(value) return tostring(value) end,
}, "obsSignal"))
O.addFramePreview("OBS_SIGNAL_PREVIEW", "obsSignal")
O.addFramePreview("SPELL_HISTORY_PREVIEW", "spellHistory")
addSlider(requires({
  label = "SPELL_HISTORY_COUNT",
  setting = "spellHistoryCount",
  min = 3,
  max = 10,
  step = 1,
  get = function(db) return db.spellHistoryCount end,
  set = function(value) ns.SetDeferred("spellHistoryCount", value) end,
  format = function(value) return tostring(value) end,
}, "showSpellHistory"))
addSlider(requires({
  label = "SPELL_HISTORY_FADE",
  advanced = true,
  setting = "spellHistoryFadeSeconds",
  min = 0,
  max = 30,
  step = 5,
  get = function(db) return db.spellHistoryFadeSeconds end,
  set = function(value) ns.SetDeferred("spellHistoryFadeSeconds", value) end,
  format = function(value) return value == 0 and L.SPELL_HISTORY_PERMANENT or string.format(L.SECONDS_SHORT, value) end,
}, "showSpellHistory"))
builder.AddTextInput({
  label = "STREAM_LINK",
  setting = "streamLink",
  width = 180,
  get = function(db) return db.streamLink end,
  set = function(text) ns.Set("streamLink", text) end,
})
addChooser({
  label = "STREAM_LINK_CHANNEL",
  setting = "streamLinkChannel",
  choices = {
    { value = "off", name = localized("STREAM_LINK_CHANNEL_OFF") },
    { value = "party", name = localized("STREAM_LINK_CHANNEL_PARTY") },
    { value = "guild", name = localized("STREAM_LINK_CHANNEL_GUILD") },
  },
})
addSlider({
  label = "STREAM_LINK_MINUTES",
  advanced = true,
  setting = "streamLinkMinutes",
  min = 15,
  max = 120,
  step = 15,
  get = function(db) return db.streamLinkMinutes end,
  set = function(value) ns.SetDeferred("streamLinkMinutes", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
  enabled = function(db) return db.streamLinkChannel ~= "off" end,
})
addButton("STREAM_LINK_COPY", function()
  if ns.StreamLink then ns.StreamLink.OpenCopy() end
end)
addSection("SECTION_STREAM_OBS")
addHint("STREAM_OBS_HINT")
addStreamLayoutChooser()
addBackgroundChooser()
addOutlineChooser()
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
-- Route: Checkliste des besten eigenen Laufs (/lt route)
addSubPage("OPTIONS_PAGE_ROUTE_REPLAY")
addToggles({ toggle("SHOW_ROUTE_REPLAY", "routeReplay") })
O.addFramePreview("ROUTE_REPLAY_PREVIEW", "routeReplay")
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
