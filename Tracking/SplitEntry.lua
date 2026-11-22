-- Aufgehobener Doppel-Eintrag "Name-" (leerer Realm, gleiche GUID) eines Charakters: Core/Database.lua legt ihn unter
-- LevelTimerStatsDB.splitCharacters[GUID] ab (LT-414). Hier kann der Spieler ihn in den echten Eintrag
-- zusammenführen (Zähler addieren, Journale nach Zeit einsortieren) oder verwerfen. Nie automatisch.
local _, ns = ...

local SplitEntry = {}
ns.SplitEntry = SplitEntry

local Database = ns.Database

local function stats()
  return LevelTimerStatsDB
end

-- Aufgehobener Eintrag zum Charakter characterKey (gleiche GUID), sonst nil
function SplitEntry.Find(characterKey)
  local character = stats().characters[characterKey]
  local split = character and character.guid and stats().splitCharacters and stats().splitCharacters[character.guid]
  if type(split) ~= "table" then return nil end
  return split
end

-- Schlüssel, unter dem der Eintrag früher lag (und unter dem das Journal-Archiv liegt)
local function splitKey(split)
  return Database.CharacterKey(split.name or "?", "")
end

-- Spielzeit (Sekunden) des aufgehobenen Eintrags: Level-Historie plus aktuelles Level
function SplitEntry.Seconds(split)
  local sum = split.currentLevel and split.currentLevel.seconds or 0
  for _, record in pairs(split.levelHistory or {}) do sum = sum + (record.seconds or 0) end
  return sum
end

-- Alle Zahlen aus src in dst addieren (Tabellen rekursiv; fehlende Felder werden übernommen)
local function addNumbers(dst, src)
  for key, value in pairs(src) do
    if type(value) == "number" and type(dst[key] or 0) == "number" then
      dst[key] = (dst[key] or 0) + value
    elseif type(value) == "table" and type(dst[key]) == "table" then
      addNumbers(dst[key], value)
    elseif dst[key] == nil then
      dst[key] = value
    end
  end
end

-- Spielzeit, XP und Zähler eines Levels
local function addLevel(dst, src)
  dst.seconds = (dst.seconds or 0) + (src.seconds or 0)
  dst.xp = (dst.xp or 0) + (src.xp or 0)
  dst.counters = dst.counters or {}
  addNumbers(dst.counters, src.counters or {})
end

-- Level des Doppel-Eintrags (abgeschlossene und laufendes) in das gleiche Level des echten Eintrags addieren
local function addToLevel(target, level, record)
  local destination = target.currentLevel.level == level and target.currentLevel or target.levelHistory[level]
  if destination then
    addLevel(destination, record)
  else  -- Level kennt der echte Eintrag nicht: als abgeschlossenes Level übernehmen
    target.levelHistory[level] = record
  end
end

local function mergeLevels(target, split)
  for level, record in pairs(split.levelHistory or {}) do addToLevel(target, level, record) end
  local current = split.currentLevel
  if current and current.level and current.level > 0 then addToLevel(target, current.level, current) end
end

local function mergeSessions(target, split)
  for _, session in ipairs(split.sessionHistory or {}) do table.insert(target.sessionHistory, session) end
  table.sort(target.sessionHistory, function(a, b) return (a.startedAt or 0) < (b.startedAt or 0) end)
end

-- Journal-Einträge des aufgehobenen Eintrags: Eingang plus Archiv unter seinem alten Schlüssel
local function entriesOf(split, logName)
  local all = {}
  for _, entry in ipairs(ns.JournalArchive.Entries(splitKey(split), logName)) do all[#all + 1] = entry end
  for _, entry in ipairs(split[logName] or {}) do all[#all + 1] = entry end
  return all
end

-- Archiv-Daten des Doppel-Eintrags löschen (Zuhörer von Database.DeleteCharacter), nur wenn der Schlüssel frei ist
local function dropArchive(split)
  local key = splitKey(split)
  if stats().characters[key] == nil then Database.DeleteCharacter(key) end
end

local function remove(characterKey)
  stats().splitCharacters[stats().characters[characterKey].guid] = nil
end

-- In den Eintrag characterKey zusammenführen und den aufgehobenen Eintrag entfernen; false, wenn es keinen gibt
function SplitEntry.Merge(characterKey)
  local split = SplitEntry.Find(characterKey)
  if not split then return false end
  local target = stats().characters[characterKey]
  mergeLevels(target, split)
  mergeSessions(target, split)
  addNumbers(target.zoneStats, split.zoneStats or {})
  addNumbers(target.dailyStats, split.dailyStats or {})
  for logName in pairs(ns.Journal.LOGS) do
    ns.Journal.MergeEntries(characterKey, logName, entriesOf(split, logName))
  end
  dropArchive(split)
  remove(characterKey)
  ns.Debug("core", "split entry merged into %s", characterKey)
  return true
end

-- Aufgehobenen Eintrag samt Archiv verwerfen
function SplitEntry.Discard(characterKey)
  local split = SplitEntry.Find(characterKey)
  if not split then return false end
  dropArchive(split)
  remove(characterKey)
  ns.Debug("core", "split entry of %s discarded", characterKey)
  return true
end

-- Alle aufgehobenen Einträge: { { characterKey, seconds } } (für die Prüfung)
function SplitEntry.List()
  local list = {}
  for key, character in pairs(stats().characters) do
    local split = SplitEntry.Find(key)
    if split then list[#list + 1] = { characterKey = key, guid = character.guid, seconds = SplitEntry.Seconds(split) } end
  end
  return list
end
