-- Wann ich spiele (Roadmap 277): aktive Spielzeit (ohne AFK) und XP je Wochentag und Stunde, über die ganze
-- Aufzeichnung summiert. ns.character.playHours["W-H"] = { seconds, xp } mit W = 1 (Montag) .. 7, H = 0 .. 23
-- (Ortszeit). Fehlt bei älteren Daten und wird beim ersten Buchen angelegt (kein Schema-Wechsel).
local _, ns = ...
local L = ns.L
local Format = ns.Format

local PlayHours = {}
ns.PlayHours = PlayHours

PlayHours.DAYS, PlayHours.HOURS = 7, 24
local TICK_SECONDS = 5   -- so oft wird die aktive Zeit der laufenden Stunde gutgeschrieben
local MONDAY_OFFSET = 5  -- (wday + 5) % 7 + 1: Montag = 1 (date: 1 = Sonntag)

-- Wochentag (Montag = 1) und Stunde eines Zeitpunkts
function PlayHours.Slot(timestamp)
  local moment = date("*t", timestamp)
  return (moment.wday + MONDAY_OFFSET) % PlayHours.DAYS + 1, moment.hour
end

local function cellOf(character, timestamp)
  character.playHours = character.playHours or {}
  local day, hour = PlayHours.Slot(timestamp)
  local key = day .. "-" .. hour
  local cell = character.playHours[key]
  if not cell then
    cell = { seconds = 0, xp = 0 }
    character.playHours[key] = cell
  end
  return cell
end

local function isAfk()
  local afk = UnitIsAFK("player")
  return not ns.IsSecret(afk) and afk == true
end

-- Raster für die Heatmap: cells[Tag][Stunde] = { seconds, xp }, dazu maxSeconds und total (Sekunden)
function PlayHours.Grid(characterKey)
  local character = ns.History.GetCharacter(characterKey)
  local stored = character and character.playHours or {}
  local grid = { cells = {}, maxSeconds = 0, total = 0 }
  for day = 1, PlayHours.DAYS do
    grid.cells[day] = {}
    for hour = 0, PlayHours.HOURS - 1 do
      local cell = stored[day .. "-" .. hour] or {}
      local seconds, xp = cell.seconds or 0, cell.xp or 0
      grid.cells[day][hour] = { seconds = seconds, xp = xp }
      grid.maxSeconds = math.max(grid.maxSeconds, seconds)
      grid.total = grid.total + seconds
    end
  end
  return grid
end

-- Tooltip-Text einer Zelle: "Mo 14-15 Uhr", "2h 10m aktiv, 45.0k XP"
function PlayHours.CellText(day, hour, cell)
  local label = string.format(L.PLAY_HOURS_SLOT, L["WEEKDAY_SHORT_" .. day], hour, (hour + 1) % PlayHours.HOURS)
  return label, string.format(L.PLAY_HOURS_VALUE, Format.Duration(cell.seconds), Format.Number(cell.xp))
end

ns.Every(TICK_SECONDS, function(elapsed)
  if isAfk() then return end
  local cell = cellOf(ns.character, time())
  cell.seconds = cell.seconds + elapsed
end)

ns.Stats.OnIncrement(function(counter, amount)
  if counter ~= ns.Stats.XP_GAINED then return end
  local cell = cellOf(ns.character, time())
  cell.xp = cell.xp + amount
end)
