-- Splits wie bei LiveSplit: Zeit je Level gegen eine Vergleichszeit für dieses Level.
-- Vergleich (Einstellung splitComparison):
--   "best"       schnellste Zeit je Level über alle anderen Charaktere ("Sum of Best")
--   "pb"         persönliche Bestzeit: der andere Charakter, der am schnellsten bis zum aktuellen Level kam
--                (Summe seiner Level-Zeiten ab dem ersten eigenen Level; er braucht alle diese Level)
--   "run"        ein gewählter Lauf (db.splitReference = { id, name, times }, /lt compare Name oder
--                Klick in der Ansicht "Läufe"); die Zeiten werden beim Wählen kopiert und bleiben fest
-- Abweichung < 0 = schneller als der Vergleich. Ohne Vergleichswert für ein Level gibt es keinen Split.
-- Gold-Split: abgeschlossenes Level schneller als die Bestzeit aller anderen Charaktere (unabhängig vom
-- Vergleich), lila in der Split-Liste; Einstellung goldSplitNotice meldet ihn beim Level-Up mit Ton.
local _, ns = ...
local Stats = ns.Stats
local History = ns.History

local Splits = {
  BEST = "best",
  PERSONAL_BEST = "pb",
  RUN = "run",
}
ns.Splits = Splits

---------------------------------------------------------------------------
-- Vergleichszeiten
---------------------------------------------------------------------------
local Runs = ns.Runs

local function otherCharacters()
  local keys = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    if key ~= ns.characterKey then table.insert(keys, key) end
  end
  return keys
end

local function bestPerLevel()
  local best = {}
  for _, key in ipairs(otherCharacters()) do
    for level, seconds in pairs(Runs.LevelTimes(key, true)) do  -- Teil-Level zählen nie als Bestzeit
      if not best[level] or seconds < best[level] then best[level] = seconds end
    end
  end
  return best
end

-- Erstes Level, ab dem der eingeloggte Charakter Zeiten hat (Addon evtl. später installiert)
local function firstOwnLevel()
  local first = ns.level
  for level in pairs(ns.character.levelHistory) do
    if level < ns.level then first = math.min(first, level) end
  end
  return first
end

-- Level-Spanne, über die Läufe verglichen werden: erstes eigenes Level bis einschließlich des aktuellen
function Splits.ComparableRange()
  return firstOwnLevel(), ns.level
end

-- Zeiten des anderen Charakters mit der kleinsten Summe über die Level from..to (nur wer alle hat); nil ohne Treffer
local function fastestRun(from, to)
  local bestTimes, bestSum
  for _, key in ipairs(otherCharacters()) do
    local times = Runs.LevelTimes(key)
    local sum = Runs.SumOfLevels(times, from, to)
    if sum and (not bestSum or sum < bestSum) then bestTimes, bestSum = times, sum end
  end
  return bestTimes
end

-- Zeiten des schnellsten anderen Charakters bis einschließlich des aktuellen Levels. Hat kein anderer eine Zeit
-- für das laufende Level (Levelcap, oder man ist Erster auf diesem Level), zählen nur die abgeschlossenen Level,
-- damit der Vergleich dort nicht ganz verschwindet.
local function personalBest()
  local from = firstOwnLevel()
  return fastestRun(from, ns.level) or fastestRun(from, ns.level - 1) or {}
end

-- Gewählter Lauf: beim Wählen kopierte Zeiten, bleiben fest, auch wenn der Charakter weiterlevelt.
-- Der Vergleich ist accountweit; spielt man den gewählten Charakter selbst, wäre er sein eigener
-- Vergleich, dann gilt die Bestzeit je Level.
local function chosenRun()
  local reference = ns.db.splitReference
  if reference and reference.id == ns.characterKey then return bestPerLevel() end
  return reference and reference.times or {}
end

local REFERENCES = {
  [Splits.BEST] = bestPerLevel,
  [Splits.PERSONAL_BEST] = personalBest,
  [Splits.RUN] = chosenRun,
}

-- Neu berechnet, wenn sich Vergleich, Level, eingeloggter Charakter oder die Zahl der Charaktere
-- ändert (Löschen). Innerhalb eines Levels bleibt der Vergleich damit fest.
-- Zwischenspeicher je Art: caches[name] = { key, times }
local caches = {}

local function cacheKey()
  local count = 0
  for _ in pairs(ns.Database.GetCharacters()) do count = count + 1 end
  local reference = ns.db.splitReference
  return table.concat({ ns.characterKey, count, ns.level, ns.db.splitComparison,
    reference and reference.id or "" }, ":")
end

-- Login (auch der Neustart nach dem Löschen des eingeloggten Charakters, bei gleicher Zahl der
-- Charaktere) baut den Vergleich neu
ns.OnLogin(function()
  caches = {}
end)

local function cached(name, build)
  local key = cacheKey()
  local entry = caches[name]
  if entry and entry.key == key then return entry.times end
  entry = { key = key, times = build() }
  caches[name] = entry
  ns.Debug("splits", "%s rebuilt (%s)", name, key)
  return entry.times
end

local function referenceTimes()
  return cached("reference", REFERENCES[ns.db.splitComparison] or REFERENCES[Splits.BEST])
end

---------------------------------------------------------------------------
-- Abweichungen
---------------------------------------------------------------------------
function Splits.GetReference(level)
  return referenceTimes()[level]
end

-- Bestzeit eines Levels über alle anderen Charaktere (ohne Teil-Level), unabhängig vom Vergleich
function Splits.GetBestTime(level)
  return cached("best", bestPerLevel)[level]
end

-- Gold-Split: eigenes, vollständig erfasstes Level schneller als jede bisherige Bestzeit dafür
function Splits.IsGoldSplit(level)
  local record = ns.character.levelHistory[level]
  local best = Splits.GetBestTime(level)
  return record ~= nil and not record.partial and record.seconds ~= nil and best ~= nil and record.seconds < best
end

-- Abweichung des laufenden Levels zum Vergleich; nil ohne Vergleichswert oder solange /played fehlt
function Splits.GetCurrentDelta()
  local reference = Splits.GetReference(ns.level)
  local seconds = Stats.GetSeconds(Stats.LEVEL)
  if not reference or not seconds then return nil end
  return seconds - reference
end

-- Abweichung eines abgeschlossenen eigenen Levels; nil ohne Vergleichswert
function Splits.GetLevelDelta(level)
  local record = ns.character.levelHistory[level]
  local reference = Splits.GetReference(level)
  if not record or not record.seconds or not reference then return nil end
  return record.seconds - reference
end

-- Summe der Abweichungen aller Level mit Vergleichswert, inklusive des laufenden; nil ohne Vergleichswert
function Splits.GetTotalDelta()
  local total
  for level in pairs(ns.character.levelHistory) do
    local delta = level < ns.level and Splits.GetLevelDelta(level)
    if delta then total = (total or 0) + delta end
  end
  local current = Splits.GetCurrentDelta()
  if current then total = (total or 0) + current end
  return total
end

-- Lauf als festen Vergleich wählen: Zeiten werden kopiert (siehe chosenRun)
function Splits.SetReferenceRun(run)
  local times = {}
  for level, seconds in pairs(run.times) do times[level] = seconds end
  ns.db.splitReference = { id = run.id, name = run.name, times = times }
  caches = {}  -- auch bei gleicher Wahl neu lesen (der Lauf kann sich seit dem letzten Mal geändert haben)
  ns.Set("splitComparison", Splits.RUN)
end

-- Lauf per Name wählen; false ohne Treffer
function Splits.CompareWith(name)
  local run = Runs.FindByName(name)
  if not run then return false end
  Splits.SetReferenceRun(run)
  return true
end

-- Anzeigename des gewählten Laufs (eigene Charaktere mit Streamer-Datenschutz)
function Splits.GetReferenceName()
  local reference = ns.db.splitReference
  if not reference then return nil end
  if History.GetCharacter(reference.id) then return History.DisplayName(reference.id) end
  return reference.name
end

---------------------------------------------------------------------------
-- Anzeige
---------------------------------------------------------------------------
local Format = ns.Format

-- Abweichung eines abgeschlossenen Levels als Text, Gold-Splits lila
function Splits.LevelDeltaText(level)
  return Format.SplitDelta(Splits.GetLevelDelta(level), Splits.IsGoldSplit(level) and Format.SPLIT_GOLD or nil)
end

function Splits.CurrentDeltaText()
  return Format.SplitDelta(Splits.GetCurrentDelta())
end

-- Gold-Split beim Level-Up melden (Chatzeile und Ton, Einstellung goldSplitNotice). Läuft nach
-- History.lua (Ladereihenfolge), der Level-Eintrag steht also schon.
ns.OnLevelCompleted(function(level)
  if not ns.db.goldSplitNotice or not Splits.IsGoldSplit(level) then return end
  local seconds, best = ns.character.levelHistory[level].seconds, Splits.GetBestTime(level)
  ns.Debug("splits", "gold split level %s: %s < %s", level, seconds, best)
  ns.Print(string.format(ns.L.GOLD_SPLIT, level, Format.Duration(seconds), Format.SignedDuration(seconds - best)))
  if ns.Alerts then ns.Alerts.PlaySound() end
end)
