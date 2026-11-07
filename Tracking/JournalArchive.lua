-- Journal-Archiv (Roadmap 252): ältere Journal-Einträge aller Charaktere kompakt (RecordCodec) in der SavedVariable
-- LevelTimerArchiveDB des Load-on-Demand-Addons LevelTimer_Archive. WoW liest und schreibt dessen Datei nur, wenn es
-- in der Sitzung geladen wurde; Login und Logout bleiben so schnell, egal wie groß die Historie ist.
--   Laden    beim Login (Ladebildschirm), wenn ein Eingang des Charakters über INBOX_MAX liegt, oder sobald jemand
--            Archiv-Einträge liest (Historie: Kill-, Tod-, Beute-, Quest-Tabellen und Charts). Danach bleibt es für die
--            Sitzung geladen. Lässt es sich nicht laden (Addon fehlt oder ist aus), bleibt alles im Eingang.
--   Umziehen nach dem Laden für alle Charaktere: aus jedem Eingang alles bis auf die neuesten KEEP_RECENT Einträge
--            (die laufende Module noch brauchen, z.B. Lauf zusammenführen, Todesursache nachtragen).
-- LevelTimerArchiveDB = { schemaVersion, characters = { [Schlüssel] = { dict = { Werte }, logs = { [logName] = {
-- Zeilen, älteste zuerst } } } } }
local _, ns = ...
local Journal = ns.Journal
local RecordCodec = ns.RecordCodec

local Archive = {}
ns.JournalArchive = Archive

Archive.ADDON = "LevelTimer_Archive"
Archive.INBOX_MAX = 3000    -- so viele Einträge in einem Eingang lösen beim Login das Umziehen aus
Archive.KEEP_RECENT = 500   -- so viele neueste Einträge bleiben im Eingang
local SCHEMA_VERSION = 1
local EMPTY = {}

local state = "unloaded"    -- "unloaded" | "loaded" | "unavailable" (Laden schlug in dieser Sitzung fehl)
local version = 0           -- steigt bei jeder Änderung am Archiv (Zwischenspeicher in Journal.GetEntries)
local codecs = {}           -- [logName] = codec
local dictionaries = {}     -- [Schlüssel] = Wörterbuch (Index nur im Speicher)
local decoded = {}          -- [Schlüssel .. "#" .. logName] = Liste der entpackten Einträge; bleibt für die Sitzung
                            -- (Speicher ist billig, jedes Wiederöffnen der Historie müsste sonst alles neu entpacken)

for logName, spec in pairs(Journal.LOGS) do
  codecs[logName] = RecordCodec.New(spec.fields)
end

local function db()
  return LevelTimerArchiveDB
end

local function changed()
  version = version + 1
  decoded = {}
end

local function loadAddOn(name)
  local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
  if not load then return false end
  local ok, loaded = pcall(load, name)
  return ok and loaded and true or false
end

local function characterArchive(characterKey, create)
  local characters = db().characters
  if not characters[characterKey] and create then
    characters[characterKey] = { dict = {}, logs = {} }
  end
  return characters[characterKey]
end

local function dictionaryOf(characterKey, archive)
  dictionaries[characterKey] = dictionaries[characterKey] or RecordCodec.NewDictionary(archive.dict)
  return dictionaries[characterKey]
end

local dropOldest = Journal.DropOldest

-- Eingang eines Charakters ins Archiv umziehen; true, wenn etwas umgezogen ist
local function flushCharacter(characterKey, character)
  local moved = false
  for logName, spec in pairs(Journal.LOGS) do
    local inbox = character[logName]
    local count = inbox and #inbox - Archive.KEEP_RECENT or 0
    if count > 0 then
      local archive = characterArchive(characterKey, true)
      local dict = dictionaryOf(characterKey, archive)
      archive.logs[logName] = archive.logs[logName] or {}
      local lines = archive.logs[logName]
      for i = 1, count do
        lines[#lines + 1] = codecs[logName].Encode(inbox[i], dict)
      end
      dropOldest(inbox, count)
      if #lines > spec.max then dropOldest(lines, #lines - spec.max) end
      moved = true
      ns.Debug("archive", "%s %s: %s moved, %s archived", characterKey, logName, count, #lines)
    end
  end
  return moved
end

-- Alle Charaktere umziehen (nur mit geladenem Archiv)
function Archive.FlushAll()
  if state ~= "loaded" then return end
  local moved = false
  for characterKey, character in pairs(LevelTimerStatsDB.characters) do
    moved = flushCharacter(characterKey, character) or moved
  end
  if moved then changed() end
end

function Archive.Version()
  return version
end

function Archive.IsLoaded()
  return state == "loaded"
end

-- Archiv laden (einmal je Sitzung) und alle Eingänge umziehen; false, wenn es sich nicht laden lässt
function Archive.Load()
  if state == "loaded" then return true end
  if state == "unavailable" then return false end
  if not loadAddOn(Archive.ADDON) then
    state = "unavailable"
    ns.Debug("archive", "%s could not be loaded, journals stay in the inbox", Archive.ADDON)
    return false
  end
  LevelTimerArchiveDB = LevelTimerArchiveDB or {}
  db().schemaVersion = db().schemaVersion or SCHEMA_VERSION
  db().characters = db().characters or {}
  state = "loaded"
  ns.Debug("archive", "loaded")
  Archive.FlushAll()
  return true
end

-- Archivierte Einträge eines Logs, älteste zuerst, und die Version (für Zwischenspeicher); lädt das Archiv
function Archive.Entries(characterKey, logName)
  if not Archive.Load() then return EMPTY, version end
  local cacheKey = characterKey .. "#" .. logName
  if decoded[cacheKey] then return decoded[cacheKey], version end
  local archive = characterArchive(characterKey, false)
  local lines = archive and archive.logs[logName]
  if not lines then return EMPTY, version end
  local dict, codec, list = dictionaryOf(characterKey, archive), codecs[logName], {}
  for i, line in ipairs(lines) do list[i] = codec.Decode(line, dict) end
  decoded[cacheKey] = list
  return list, version
end

-- Anzahl archivierter Einträge (ohne zu entpacken); 0 ohne Archiv
function Archive.Count(characterKey, logName)
  if not Archive.Load() then return 0 end
  local archive = characterArchive(characterKey, false)
  return archive and archive.logs[logName] and #archive.logs[logName] or 0
end

local function deleteCharacter(characterKey)
  if not Archive.Load() or not db().characters[characterKey] then return end
  db().characters[characterKey] = nil
  dictionaries[characterKey] = nil
  changed()
end

ns.Database.OnCharacterDeleted(deleteCharacter)
ns.Database.OnCharacterReplaced(function(_, characterKey) deleteCharacter(characterKey) end)

local function inboxFull(character)
  for logName in pairs(Journal.LOGS) do
    if character[logName] and #character[logName] > Archive.INBOX_MAX then return true end
  end
  return false
end

-- Beim Login (noch im Ladebildschirm) umziehen, wenn ein Eingang voll ist; geladen: immer
ns.OnLogin(function()
  if state == "unavailable" then state = "unloaded" end  -- neuer Versuch je Sitzung
  if state == "loaded" or inboxFull(ns.character) then
    Archive.Load()
    Archive.FlushAll()
  end
end)
