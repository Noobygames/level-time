-- Split-Liste wie bei LiveSplit: eigene kleine Anzeige mit dem laufenden Level und den zuletzt
-- abgeschlossenen Leveln (Level, Zeit, Abweichung zum Vergleich aus Splits.lua), darunter die Summe
-- und die gesamte Spielzeit (/played); optional die Speedrun-Rekorde je Abschnitt (WorldRecords.lua).
-- Einstellungen (Reiter Speedrun): showSplitList (an/aus, /lt splits), splitListRows (Zahl der Level),
-- splitListScale (eigene Größe, sonst die des Hauptfensters), splitListShowTotal, splitListShowPlayed,
-- showWorldRecords mit WorldRecords.IsBracketShown je Abschnitt, showRecordsAge (Stand der Rekorde),
-- splitListShowForecast (Prognose des nächsten Abschnitts gegen PB, Summe der Bestzeiten und Rekord),
-- ssfCategory (SSF-Regelhelfer, SsfRules.lua), splitListShowCustom (die letzten eigenen Splits, CustomSplits.lua).
-- Mit friendRace und einem gehörten Freund (FriendRace.lua) eine vierte Spalte "gegen Freund" je Level.
-- Position splitListPos; Hintergrund und Fixieren folgen dem Hauptfenster.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats
local Splits = ns.Splits
local TimerWindow = ns.TimerWindow

local SplitList = {
  MIN_ROWS = 3,
  MAX_ROWS = 15,
}
ns.SplitList = SplitList

local UPDATE_INTERVAL = 0.5
local PADDING_X = 12
local PADDING_Y = 8
local ROW_HEIGHT = 14
local COLUMN_GAP = 12
local MIN_WIDTH = 140
local DEFAULT_POSITION = { "TOPLEFT", "TOPLEFT", 20, -200 }

local panel = Widgets.CreatePanel("LevelTimerSplits", 0.8)
panel:Hide()

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", PADDING_X, -PADDING_Y)

-- Zeilen: Level links, Zeit und Abweichung rechtsbündig in eigenen Spalten
local rows = {}

local function getRow(index)
  if rows[index] then return rows[index] end
  local function cell(font) return panel:CreateFontString(nil, "OVERLAY", font) end
  rows[index] = {
    level = cell("GameFontNormalSmall"),
    time = cell("GameFontHighlightSmall"),
    delta = cell("GameFontHighlightSmall"),
    friend = cell("GameFontHighlightSmall"),
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
    table.insert(lines, { L.SPLIT_LIST_TOTAL, "", Format.SplitDelta(Splits.GetTotalDelta()) })
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

local function setCells(row, levelText, timeText, deltaText, friendText)
  row.level:SetText(levelText)
  row.time:SetText(timeText)
  row.delta:SetText(deltaText)
  row.friend:SetText(friendText or "")
  for _, fontString in pairs(row) do fontString:Show() end
end

-- Spalten so breit wie ihr breitester Text, Fenster entsprechend
local function layout(count)
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
    local y = -PADDING_Y - i * ROW_HEIGHT
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
    2 * PADDING_Y + (count + 1) * ROW_HEIGHT)
end

local function render()
  local friend = ns.FriendRace.Current()
  title:SetText(friend and string.format(L.SPLIT_LIST_TITLE_FRIEND, L.SPLIT_LIST_TITLE, friend) or L.SPLIT_LIST_TITLE)
  local lines = SplitList.BuildLines()
  for i, line in ipairs(lines) do
    setCells(getRow(i), tostring(line.level),
      line.seconds and Format.Duration(line.seconds) or "...", line.deltaText, line.friendText)
  end
  local used = #lines
  for _, line in ipairs(SplitList.BuildFooterLines()) do
    used = used + 1
    setCells(getRow(used), line[1], line[2], line[3])
  end
  for i = used + 1, #rows do
    for _, fontString in pairs(rows[i]) do fontString:Hide() end
  end
  layout(used)
end

---------------------------------------------------------------------------
-- Position, Ablauf
---------------------------------------------------------------------------
panel:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
-- Zuletzt angewendete bzw. gespeicherte Positionstabelle (wie beim Hauptfenster: ein Profilwechsel
-- bringt eine neue Tabelle mit)
local appliedPos
local positioned = false  -- schon einmal positioniert (Login)

local function savePosition()
  local point, _, relativePoint, x, y = panel:GetPoint()
  ns.db.splitListPos = { point, relativePoint, x, y }
  appliedPos = ns.db.splitListPos
end

panel:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)
panel:SetScript("OnMouseUp", function(_, mouseButton)
  if mouseButton == "RightButton" then ns.ToggleOptions() end
end)

-- Ziehgriff unten rechts ändert die eigene Größe (splitListScale), wie beim Hauptfenster
local grip = Widgets.CreateResizeGrip(panel, function(scale)
  return math.max(TimerWindow.MIN_SCALE, math.min(TimerWindow.MAX_SCALE, scale))
end, function(scale)
  savePosition()
  ns.Set("splitListScale", scale)
end)

local sinceUpdate = 0
panel:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  render()
  grip:UpdateAlpha()  -- nur bei Mauskontakt sichtbar
end)

-- Abstände gelten in der Skalierung der Anzeige, daher vor dem Positionieren skalieren
-- Eigene Größe der Split-Liste; ohne eigene Einstellung die des Hauptfensters
function SplitList.GetScale(db)
  return db.splitListScale or db.scale
end

local function restorePosition(db)
  appliedPos, positioned = db.splitListPos, true
  local pos = db.splitListPos or DEFAULT_POSITION
  panel:SetScale(SplitList.GetScale(db))
  panel:ClearAllPoints()
  panel:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- Neue Position (Login, Profil, Zurücksetzen): dorthin. Nur andere Größe: um die linke obere Ecke
-- skalieren, sonst würde die Liste mit den alten Abständen in neuer Skalierung springen.
local function applyPosition(db)
  local scale = SplitList.GetScale(db)
  if not positioned or db.splitListPos ~= appliedPos then
    restorePosition(db)
  elseif math.abs(panel:GetScale() - scale) > 0.001 then
    Widgets.SetScaleKeepingTopLeft(panel, scale)
    savePosition()
  end
end

ns.RegisterApply(function(db)
  applyPosition(db)
  grip:SetShown(not db.locked)
  TimerWindow.ApplyBackground(panel, db)
  panel:SetShown(db.showSplitList)
  if db.showSplitList then render() end
end)
