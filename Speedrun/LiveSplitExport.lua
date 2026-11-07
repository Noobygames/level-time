-- Export der Level-Splits als LiveSplit-Datei (.lss) für das Kopierfenster (/lt runs lss, Button in Speedrun > Läufe).
-- Format wie LiveSplits XMLRunSaver (Run version 1.7.0): je Level ein Segment mit SplitTime "Personal Best"
-- (kumulierte Zeit ab dem ersten Level) und BestSegmentTime (schnellste Zeit dieses Levels über alle eigenen
-- Charaktere, ohne Teil-Level). Zeiten als .NET-TimeSpan "[d.]hh:mm:ss.fffffff", als RealTime und GameTime
-- (beides /played, das ist Spielzeit). Exportiert werden die zusammenhängend abgeschlossenen Level des
-- eingeloggten Charakters ab dem ersten erfassten Level.
local _, ns = ...
local L = ns.L
local Runs = ns.Runs
local History = ns.History

local LiveSplitExport = {}
ns.LiveSplitExport = LiveSplitExport

local GAME_NAME = "World of Warcraft"
local PERSONAL_BEST = "Personal Best"
local SECONDS_PER_DAY = 86400
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_MINUTE = 60
local TICKS_PER_SECOND = 10000000  -- .NET: 100 ns je Tick, sieben Nachkommastellen

-- .NET-TimeSpan wie TimeSpan.ToString(): "hh:mm:ss.fffffff", ab einem Tag "d.hh:mm:ss.fffffff"
function LiveSplitExport.TimeSpan(seconds)
  local whole = math.floor(seconds)
  local ticks = math.floor((seconds - whole) * TICKS_PER_SECOND + 0.5)
  local days = math.floor(whole / SECONDS_PER_DAY)
  local text = string.format("%02d:%02d:%02d.%07d", math.floor(whole / SECONDS_PER_HOUR) % 24,
    math.floor(whole / SECONDS_PER_MINUTE) % 60, whole % 60, ticks)
  return days > 0 and (days .. "." .. text) or text
end

local function escape(text)
  return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

-- Schnellste Zeit je Level über alle eigenen Charaktere (ohne Teil-Level)
local function bestSegments()
  local best = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    for level, seconds in pairs(Runs.LevelTimes(key, true)) do
      if not best[level] or seconds < best[level] then best[level] = seconds end
    end
  end
  return best
end

-- Erstes Level mit Zeit und das letzte davon ohne Lücke; nil ohne abgeschlossenes Level
local function contiguousRange(times)
  local first
  for level in pairs(times) do first = math.min(first or level, level) end
  if not first then return nil end
  local last = first
  while times[last + 1] do last = last + 1 end
  return first, last
end

local function timeElement(lines, indent, name, seconds, attribute)
  local value = LiveSplitExport.TimeSpan(seconds)
  table.insert(lines, string.format("%s<%s%s>", indent, name, attribute or ""))
  table.insert(lines, string.format("%s  <RealTime>%s</RealTime>", indent, value))
  table.insert(lines, string.format("%s  <GameTime>%s</GameTime>", indent, value))
  table.insert(lines, string.format("%s</%s>", indent, name))
end

-- XML-Text der .lss-Datei; nil ohne abgeschlossenes Level
function LiveSplitExport.Build(characterKey)
  local times = Runs.LevelTimes(characterKey)
  local first, last = contiguousRange(times)
  if not first then return nil end
  local best = bestSegments()
  local lines = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<Run version="1.7.0">',
    "  <GameIcon />",
    "  <GameName>" .. GAME_NAME .. "</GameName>",
    "  <CategoryName>" .. escape(string.format(L.LIVESPLIT_CATEGORY, first, last + 1)) .. "</CategoryName>",
    "  <LayoutPath />",
    '  <Metadata><Run id="" /><Platform usesEmulator="False" /><Region /><Variables /><CustomVariables /></Metadata>',
    "  <Offset>00:00:00</Offset>",
    "  <AttemptCount>1</AttemptCount>",
    "  <AttemptHistory />",
    "  <Segments>",
  }
  local total = 0
  for level = first, last do
    total = total + times[level]
    table.insert(lines, "    <Segment>")
    table.insert(lines, "      <Name>" .. escape(string.format(L.LIVESPLIT_SEGMENT, level + 1)) .. "</Name>")
    table.insert(lines, "      <Icon />")
    table.insert(lines, "      <SplitTimes>")
    timeElement(lines, "        ", "SplitTime", total, ' name="' .. PERSONAL_BEST .. '"')
    table.insert(lines, "      </SplitTimes>")
    timeElement(lines, "      ", "BestSegmentTime", math.min(best[level] or times[level], times[level]))
    table.insert(lines, "      <SegmentHistory />")
    table.insert(lines, "    </Segment>")
  end
  table.insert(lines, "  </Segments>")
  table.insert(lines, "  <AutoSplitterSettings />")
  table.insert(lines, "</Run>")
  return table.concat(lines, "\n")
end

-- Kopierfenster mit der .lss des eingeloggten Charakters
function LiveSplitExport.Show()
  local text = LiveSplitExport.Build(ns.characterKey)
  if not text then
    ns.Print(L.LIVESPLIT_EMPTY)
    return
  end
  ns.Export.Show(L.LIVESPLIT_TITLE, text)
end
