-- Erfassungsquote (Roadmap 253): welcher Anteil der Spielzeit (/played) vom Addon erfasst wurde, je Charakter
-- (und damit je eigenem Lauf). Grün ab Coverage.GOOD, gelb ab Coverage.FAIR, sonst rot (wie Hardcore/Chromely).
-- Gespeichert in character.coverage = { untracked, lastPlayed, gaps, rollbacks }:
--   untracked   Sekunden /played, die das Addon nicht gesehen hat
--   lastPlayed  /played gesamt beim letzten Stand (alle SAVE_SECONDS und beim Logout, auch für Disconnects)
-- Bei der ersten /played-Antwort nach dem Login (TIME_PLAYED_MSG, 1. Argument = gesamt, 2. = auf dem Level):
--   /played mehr als GAP_SECONDS über lastPlayed  = ohne Addon gespielt: Lücke zu untracked, Chatzeile;
--   mehr als GAP_SECONDS darunter                 = älterer Spielstand zurückgespielt (Earned): Chatzeile;
--   noch kein lastPlayed (erster Login mit dieser Funktion): untracked = /played minus der Zeit aller gespeicherten
--   Sessions (Schätzung; sehr kurze und mehr als 200 alte Sessions fehlen dort, die Quote ist dann eher zu niedrig).
-- Das laufende Level bekommt currentLevel.partial, wenn mehr als GAP_SECONDS seiner Zeit nicht erfasst wurden
-- (Addon mitten im Level installiert oder eine Lücke); History übernimmt das in den Level-Eintrag. Solche Level
-- zählen nie als Bestzeit (Runs.LevelTimes mit withoutPartial).
local _, ns = ...
local L = ns.L

local Coverage = {}
ns.Coverage = Coverage

Coverage.GOOD = 0.95
Coverage.FAIR = 0.90
local GAP_SECONDS = 45
local SAVE_SECONDS = 30
-- Theme-Farben je Güte (Theme.lua), beim Aufruf gelesen
local COLOR_TOKENS = { good = "good", fair = "gold", poor = "bad" }

local checked  -- erste /played-Antwort seit dem Login ausgewertet

local function data(character)
  character.coverage = character.coverage or {}
  return character.coverage
end

-- Von gespeicherten Sessions erfasste Sekunden (laufende Session inklusive)
local function sessionSeconds()
  local sum = ns.Session.GetSeconds()
  for _, session in ipairs(ns.character.sessionHistory) do sum = sum + (session.seconds or 0) end
  return sum
end

-- Nicht erfasste Sekunden seit dem letzten Stand; liefert außerdem, wie viel davon das laufende Level betrifft
local function evaluate(coverage, total, levelSeconds)
  if not coverage.lastPlayed then
    local tracked = sessionSeconds()
    coverage.untracked = math.max(0, total - tracked)
    ns.Debug("coverage", "first check: played %s, sessions %s", total, tracked)
    return levelSeconds - tracked
  end
  local gap = total - coverage.lastPlayed
  ns.Debug("coverage", "played %s, last known %s, gap %s", total, coverage.lastPlayed, gap)
  if gap > GAP_SECONDS then
    coverage.untracked = (coverage.untracked or 0) + gap
    coverage.gaps = (coverage.gaps or 0) + 1
    ns.Print(string.format(L.COVERAGE_GAP, ns.Format.Duration(gap)))
    return math.min(gap, levelSeconds)
  elseif gap < -GAP_SECONDS then
    coverage.rollbacks = (coverage.rollbacks or 0) + 1
    ns.Print(string.format(L.COVERAGE_ROLLBACK, ns.Format.Duration(-gap)))
    return levelSeconds  -- Stand des Levels passt nicht mehr zu dem, was das Addon gesehen hat
  end
  return 0
end

ns.RegisterEvent("TIME_PLAYED_MSG", function(total, levelSeconds)
  if checked or ns.IsSecret(total) or ns.IsSecret(levelSeconds) or type(total) ~= "number" then return end
  checked = true
  local coverage = data(ns.character)
  local untrackedOnLevel = evaluate(coverage, total, levelSeconds or 0)
  if untrackedOnLevel > GAP_SECONDS and not ns.character.currentLevel.partial then
    ns.Debug("coverage", "level %s only partly tracked (%s s missing)", ns.level, untrackedOnLevel)
    ns.character.currentLevel.partial = true
  end
  coverage.lastPlayed = total
end)

local function saveLastPlayed()
  if not checked then return end
  local total = ns.PlayedTime.GetTotalSeconds()
  if total then data(ns.character).lastPlayed = total end
end

-- Anteil 0..1 der erfassten Spielzeit eines Charakters; nil, solange es keinen Stand gibt
function Coverage.Get(characterKey)
  local character = ns.Database.GetCharacters()[characterKey]
  local coverage = character and character.coverage
  if not coverage or not coverage.lastPlayed then return nil end
  local total = coverage.lastPlayed
  if characterKey == ns.characterKey then
    if not checked then return nil end
    total = ns.PlayedTime.GetTotalSeconds() or total
  end
  if total <= 0 then return nil end
  return math.max(0, math.min(1, (total - (coverage.untracked or 0)) / total))
end

-- Quote als farbiger Prozenttext, "-" ohne Wert
function Coverage.Text(fraction)
  if not fraction then return "-" end
  local quality = fraction >= Coverage.GOOD and "good" or fraction >= Coverage.FAIR and "fair" or "poor"
  local color = ns.Theme.Hex(COLOR_TOKENS[quality])
  return string.format("%s%d%%|r", color, math.floor(fraction * 100))
end

ns.Every(SAVE_SECONDS, saveLastPlayed)
ns.OnLogout(saveLastPlayed)
ns.OnLogin(function()
  checked = false
end)
