-- Split-Liste wie bei LiveSplit: eigene kleine Anzeige mit dem laufenden Level und den zuletzt
-- abgeschlossenen Leveln (Level, Zeit, Abweichung zum Vergleich aus Splits.lua), darunter die Summe
-- und die gesamte Spielzeit (/played); optional die Speedrun-Rekorde je Abschnitt (WorldRecords.lua).
-- Einstellungen (Reiter Speedrun): showSplitList (an/aus, /lt splits), splitListRows (Zahl der Level),
-- eigene Größe (frames.splitList.scale, sonst die des Hauptfensters), splitListShowTotal, splitListShowPlayed,
-- showWorldRecords mit WorldRecords.IsBracketShown je Abschnitt, showRecordsAge (Stand der Rekorde),
-- splitListShowForecast (Prognose des nächsten Abschnitts gegen PB, Summe der Bestzeiten und Rekord),
-- ssfCategory (SSF-Regelhelfer, SsfRules.lua), splitListShowCustom (die letzten eigenen Splits, CustomSplits.lua).
-- Mit friendRace und einem gehörten Freund (FriendRace.lua) eine vierte Spalte "gegen Freund" je Level.
-- Position über Lib/Frames.lua; Hintergrund und Fixieren folgen dem Hauptfenster, Sichtbarkeit splitListVisibility
-- (UI/DisplayVisibility.lua). Je Takt werden nur geänderte Texte gesetzt; Spalten und Größe nur bei geändertem Text.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Format = ns.Format
local Stats = ns.Stats
local Splits = ns.Splits

local SplitList = {
  MIN_ROWS = 3,
  MAX_ROWS = 15,
}
ns.SplitList = SplitList

local UPDATE_INTERVAL = 0.5
local PADDING_X = 12
local PADDING_Y = 8
local ROW_HEIGHT = 14  -- bei Schriftgröße-Versatz 0 (themeFontSize); wächst mit der Schrift
local MIN_ROW_HEIGHT = 10
local COLUMN_GAP = 12
local MIN_WIDTH = 140
local DEFAULT_POSITION = { "TOPLEFT", "TOPLEFT", 20, -200 }

local panel = Widgets.CreatePanel("LevelTimerSplits", 0.8)
panel:Hide()

local title = panel:CreateFontString(nil, "OVERLAY", Theme.Font("label"))
title:SetPoint("TOPLEFT", PADDING_X, -PADDING_Y)

-- Zeilen: Level links, Zeit und Abweichung rechtsbündig in eigenen Spalten
local rows = {}

local function getRow(index)
  if rows[index] then return rows[index] end
  local function cell(font) return panel:CreateFontString(nil, "OVERLAY", font) end
  rows[index] = {
    level = cell(Theme.Font("label")),
    time = cell(Theme.Font("small")),
    delta = cell(Theme.Font("small")),
    friend = cell(Theme.Font("small")),
  }
  return rows[index]
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Abweichung zum zuletzt gehörten Freund (FriendRace.lua); "" ohne Freund, "-" ohne seine Zeit
function SplitList.FriendDeltaText(level, seconds)
  if not ns.FriendRace.Current() then return "" end
  return Format.SplitDelta(ns.FriendRace.GetLevelDelta(level, seconds))
end

-- { level, seconds, delta, deltaText, gold, friendText } für das laufende Level und die zuletzt abgeschlossenen,
-- neueste zuerst
function SplitList.BuildLines()
  local lines = {
    { level = ns.level, seconds = Stats.GetSeconds(Stats.LEVEL), delta = Splits.GetCurrentDelta(),
      deltaText = Splits.CurrentDeltaText() },
  }
  lines[1].friendText = SplitList.FriendDeltaText(ns.level, lines[1].seconds)
  local level = ns.level - 1
  while #lines < ns.db.splitListRows and level >= 1 do
    local record = ns.character.levelHistory[level]
    if record then
      table.insert(lines, { level = level, seconds = record.seconds, delta = Splits.GetLevelDelta(level),
        deltaText = Splits.LevelDeltaText(level), gold = Splits.IsGoldSplit(level),
        friendText = SplitList.FriendDeltaText(level, record.seconds) })
    end
    level = level - 1
  end
  return lines
end

-- Die letzten eigenen Splits (CustomSplits.lua): Name, /played, Abweichung zur Vorlage
local CUSTOM_SPLIT_ROWS = 3

function SplitList.AddCustomSplitLines(lines)
  local CustomSplits = ns.CustomSplits
  local all = CustomSplits.GetAll()
  for index = math.max(1, #all - CUSTOM_SPLIT_ROWS + 1), #all do
    table.insert(lines, { all[index].name, Format.Duration(all[index].played),
      Format.SplitDelta(CustomSplits.GetDelta(index)) })
  end
end

-- Prognose des nächsten Abschnitts (BracketForecast.lua): Endzeit, darunter der Abstand zu jedem
-- bekannten Vergleich (negativ = voraussichtlich schneller)
function SplitList.AddForecastLines(lines)
  local forecast = ns.BracketForecast.Get()
  if not forecast then return end
  table.insert(lines, { string.format(L.SPLIT_FORECAST, forecast.label), Format.Duration(forecast.forecast), "" })
  local comparisons = {
    { L.SPLIT_FORECAST_PB, forecast.pb },
    { L.SPLIT_FORECAST_SOB, forecast.sumOfBest },
    { L.SPLIT_FORECAST_RECORD, forecast.record },
  }
  for _, comparison in ipairs(comparisons) do
    if comparison[2] then
      table.insert(lines, { comparison[1], Format.Duration(comparison[2]),
        Format.SplitDelta(forecast.forecast - comparison[2]) })
    end
  end
end

-- Zeilen unter den Leveln: { Bezeichnung, Wert, Abweichung }, je nach Einstellungen
function SplitList.BuildFooterLines()
  local db = ns.db
  local lines = {}
  if db.splitListShowCustom then SplitList.AddCustomSplitLines(lines) end
  if db.splitListShowTotal then
    table.insert(lines, { L.SPLIT_LIST_TOTAL, "", Splits.TotalDeltaText() })
  end
  if db.splitListShowPlayed then
    local played = ns.PlayedTime.GetTotalSeconds()
    table.insert(lines, { L.SPLIT_LIST_PLAYED, played and Format.Duration(played) or "...", "" })
  end
  if db.splitListShowForecast then SplitList.AddForecastLines(lines) end
  for _, line in ipairs(ns.SsfRules.BuildLines()) do table.insert(lines, line) end
  if not db.showWorldRecords then return lines end

  local WorldRecords = ns.WorldRecords
  for _, comparison in ipairs(WorldRecords.GetComparisons()) do
    if WorldRecords.IsBracketShown(comparison.label) then
      table.insert(lines, { string.format(L.WORLD_RECORD_ROW, comparison.label),
        Format.Duration(comparison.record.seconds), Format.SplitDelta(comparison.delta) })
    end
  end
  if db.showRecordsAge then
    local days = WorldRecords.GetAgeDays()
    table.insert(lines, { L.RECORDS_AGE, WorldRecords.GetFetchedText(), days and string.format(L.DAYS_AGO, days) or "" })
  end
  return lines
end

local setText = Widgets.SetTextIfChanged

-- true, wenn sich ein Text der Zeile geändert hat
local function setCells(row, levelText, timeText, deltaText, friendText)
  local changed = setText(row.level, levelText)
  changed = setText(row.time, timeText) or changed
  changed = setText(row.delta, deltaText) or changed
  changed = setText(row.friend, friendText or "") or changed
  for _, fontString in pairs(row) do fontString:Show() end
  return changed
end

-- Spalten so breit wie ihr breitester Text, Fenster entsprechend
local function rowHeight()
  return math.max(MIN_ROW_HEIGHT, ROW_HEIGHT + (ns.db.themeFontSize or 0))
end

local function layout(count)
  local height = rowHeight()
  local levelWidth, timeWidth, deltaWidth, friendWidth = 0, 0, 0, 0
  for i = 1, count do
    levelWidth = math.max(levelWidth, rows[i].level:GetStringWidth())
    timeWidth = math.max(timeWidth, rows[i].time:GetStringWidth())
    deltaWidth = math.max(deltaWidth, rows[i].delta:GetStringWidth())
    friendWidth = math.max(friendWidth, rows[i].friend:GetStringWidth())
  end
  local timeRight = PADDING_X + levelWidth + COLUMN_GAP + timeWidth
  local deltaRight = timeRight + COLUMN_GAP + deltaWidth
  local friendSpace = friendWidth > 0 and COLUMN_GAP + friendWidth or 0
  for i = 1, count do
    local y = -PADDING_Y - i * height
    local row = rows[i]
    row.level:ClearAllPoints()
    row.level:SetPoint("TOPLEFT", PADDING_X, y)
    row.time:ClearAllPoints()
    row.time:SetPoint("TOPRIGHT", panel, "TOPLEFT", timeRight, y)
    row.delta:ClearAllPoints()
    if friendSpace > 0 then
      row.delta:SetPoint("TOPRIGHT", panel, "TOPLEFT", deltaRight, y)
    else
      row.delta:SetPoint("TOPRIGHT", -PADDING_X, y)  -- ohne Freund-Spalte am rechten Rand wie bisher
    end
    row.friend:ClearAllPoints()
    row.friend:SetPoint("TOPRIGHT", -PADDING_X, y)
  end
  local width = deltaRight + friendSpace + PADDING_X
  panel:SetSize(math.max(MIN_WIDTH, width, title:GetStringWidth() + 2 * PADDING_X),
    2 * PADDING_Y + (count + 1) * height)
end

local laidOut = { count = -1, height = 0 }  -- Stand des letzten layout(): Zeilenzahl und Zeilenhöhe

local function renderLines()
  local friend = ns.FriendRace.Current()
  local changed = setText(title,
    friend and string.format(L.SPLIT_LIST_TITLE_FRIEND, L.SPLIT_LIST_TITLE, friend) or L.SPLIT_LIST_TITLE)
  local lines = SplitList.BuildLines()
  for i, line in ipairs(lines) do
    changed = setCells(getRow(i), tostring(line.level),
      line.seconds and Format.Duration(line.seconds) or "...", line.deltaText, line.friendText) or changed
  end
  local used = #lines
  for _, line in ipairs(SplitList.BuildFooterLines()) do
    used = used + 1
    changed = setCells(getRow(used), line[1], line[2], line[3]) or changed
  end
  for i = used + 1, #rows do
    for _, fontString in pairs(rows[i]) do fontString:Hide() end
  end
  -- Anker und Größe nur, wenn sich ein Text, die Zahl der Zeilen oder die Schriftgröße geändert hat
  if changed or used ~= laidOut.count or rowHeight() ~= laidOut.height then
    laidOut.count, laidOut.height = used, rowHeight()
    layout(used)
  end
end

-- Ein Takt (TickCache: Gesamt-Split und Vergleich nur einmal berechnet)
local function render()
  ns.TickCache.Run(renderLines)
end

---------------------------------------------------------------------------
-- Position (Lib/Frames.lua; ohne eigene Größe die des Hauptfensters), Ablauf
---------------------------------------------------------------------------
local visibility = ns.DisplayVisibility.Attach({
  frame = panel, setting = "splitListVisibility",
  enabled = function() return ns.db.showSplitList end,
})

ns.Frames.Register({
  id = "splitList", frame = panel, label = "EDIT_FRAME_SPLITS", default = DEFAULT_POSITION,
  keepTopLeft = true, dragWhenUnlocked = true, settingsPage = "OPTIONS_PAGE_SPLIT_LIST",
  fallbackScale = function() return ns.Frames.GetScale("main") end,
  preview = function(on)
    visibility:SetEditing(on)
    if panel:IsShown() then render() end
  end,
  hide = function() ns.Set("showSplitList", false) end,
})

-- Ziehgriff unten rechts ändert die eigene Größe, wie beim Hauptfenster
local grip = Widgets.CreateResizeGrip(panel, ns.Frames.ClampScale, function(scale)
  ns.Frames.SavePosition("splitList")
  ns.Frames.SetScale("splitList", scale)
end)

local sinceUpdate = 0
ns.SetUpdateScript(panel, "SplitList", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  render()
  grip:UpdateAlpha()  -- nur bei Mauskontakt sichtbar
end)

ns.RegisterApply(function(db)
  grip:SetShown(not db.locked)
  Theme.ApplyBackground(panel, db)
  laidOut.count = -1  -- Schrift oder Sprache können gewechselt haben
  visibility:Update()
  if panel:IsShown() then render() end
end)
