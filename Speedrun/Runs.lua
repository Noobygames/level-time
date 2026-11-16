-- Läufe für Speedrun-Vergleiche: Level-Zeiten eines Charakters oder eines importierten Laufs.
-- Lauf: { id, name, realm, class, times = { [level] = Sekunden }, reachedLevel, imported, favorite }
--   eigene Charaktere zusätzlich bestTimes (ohne Teil-Level) und coverage (Erfassungsquote, Coverage.lua)
--   id = Charakter-Schlüssel ("Name-Realm") oder "import:<n>" für importierte Läufe
--   category: ssf/solo/group/boosted (RunCategory.lua), nil = unbekannt
--   check/checkFrom/checkTo: Prüfcode über die Level checkFrom..checkTo (RunCheck.lua), coverage auch bei Importen
-- Importierte Läufe liegen in LevelTimerStatsDB.importedRuns, Favoriten in LevelTimerStatsDB.runFavorites.
local _, ns = ...
local History = ns.History

local Runs = {}
ns.Runs = Runs

local IMPORT_PREFIX = "import:"
-- Grenzen für Level-Zeiten von außen (Import, FriendRace): über dem Max-Level aller Clients, damit Läufe anderer
-- Clients passen; mehr als ein Jahr Spielzeit für ein Level ist kein echter Wert
Runs.MAX_LEVEL = 100
Runs.MAX_LEVEL_SECONDS = 365 * 24 * 3600

-- Level von außen: ganze Zahl 1..MAX_LEVEL
function Runs.IsValidLevel(level)
  return type(level) == "number" and level >= 1 and level <= Runs.MAX_LEVEL and level == math.floor(level)
end

-- Level-Zeit von außen: > 0 und unter MAX_LEVEL_SECONDS (schließt auch inf und NaN aus)
function Runs.IsValidSeconds(seconds)
  return type(seconds) == "number" and seconds > 0 and seconds <= Runs.MAX_LEVEL_SECONDS
end

local function store()
  LevelTimerStatsDB.importedRuns = LevelTimerStatsDB.importedRuns or {}
  LevelTimerStatsDB.runFavorites = LevelTimerStatsDB.runFavorites or {}
  return LevelTimerStatsDB
end

-- Abgeschlossene Level-Zeiten eines Charakters: level -> Sekunden. withoutPartial = ohne nur teilweise erfasste
-- Level (Coverage.lua), z.B. für Bestzeiten
function Runs.LevelTimes(characterKey, withoutPartial)
  local times = {}
  for _, record in ipairs(History.GetLevelRecords(characterKey)) do
    if not record.isCurrent and record.seconds and not (withoutPartial and record.partial) then
      times[record.level] = record.seconds
    end
  end
  return times
end

-- Felder eines eigenen Laufs, die sich ohne neues Level ändern können (Kategorie, Erfassungsquote, Prüfcode,
-- erreichtes Level): billig zu lesen, daher bei jedem Runs.GetAll frisch
local function refreshCharacterRun(run)
  local character = History.GetCharacter(run.id)
  run.check, run.checkFrom, run.checkTo = ns.RunCheck.ForCharacter(character)
  run.category = character.runCategory
  run.name, run.realm, run.class = character.name, character.realm, character.class
  run.coverage = ns.Coverage.Get(run.id)
  run.reachedLevel = character.currentLevel.level
end

local function fromCharacter(characterKey)
  local run = {
    id = characterKey,
    times = Runs.LevelTimes(characterKey),
    bestTimes = Runs.LevelTimes(characterKey, true),  -- ohne Teil-Level: nur diese zählen als Bestzeit
  }
  refreshCharacterRun(run)
  return run
end

local function fromImport(index, run)
  return {
    id = IMPORT_PREFIX .. index,
    name = run.name,
    realm = run.realm,
    class = run.class,
    times = run.times,
    reachedLevel = run.reachedLevel,
    coverage = run.coverage,
    category = run.category,
    check = run.check, checkFrom = run.checkFrom, checkTo = run.checkTo,
    imported = true,
  }
end

-- Zwischenspeicher der Läufe: die Level-Zeiten (Sortieren der Level-Historie je Charakter) nur neu, wenn sich etwas
-- geändert haben kann: Login, Level-Up, Einstellungen, Löschen/Ersetzen eines Charakters, andere Charakterliste
-- (History.GetCharacterKeys liefert dann eine neue) oder Importe (andere Tabelle oder Anzahl). Die Läufe- und
-- Rekorde-Ansicht fragen jede Sekunde.
local revision = 0
local cache = {}  -- { revision, characterKeys, imported, importedCount, list, byId }

-- Läufe beim nächsten Lesen neu aufbauen (z.B. vor einer ausdrücklichen Wahl per Name)
function Runs.Invalidate()
  revision = revision + 1
end

local function upToDate(characterKeys)
  local imported = store().importedRuns
  return cache.revision == revision and cache.characterKeys == characterKeys and cache.imported == imported
    and cache.importedCount == #imported
end

local function build(characterKeys)
  local runs, byId = {}, {}
  for _, key in ipairs(characterKeys) do
    table.insert(runs, fromCharacter(key))
  end
  local imported = store().importedRuns
  for index, run in ipairs(imported) do
    table.insert(runs, fromImport(index, run))
  end
  for _, run in ipairs(runs) do byId[run.id] = run end
  cache = { revision = revision, characterKeys = characterKeys, imported = imported, importedCount = #imported,
    list = runs, byId = byId }
end

-- Alle Läufe: eigene Charaktere (eingeloggter zuerst), dann importierte. Zwischengespeichert: Liste und Läufe nicht
-- verändern (Ansichten setzen nur eigene Anzeige-Felder wie timeToLevel).
function Runs.GetAll()
  local characterKeys = History.GetCharacterKeys()
  if not upToDate(characterKeys) then build(characterKeys) end
  local favorites = store().runFavorites
  for _, run in ipairs(cache.list) do
    if not run.imported then refreshCharacterRun(run) end
    run.favorite = favorites[run.id] == true
  end
  return cache.list
end

function Runs.Get(id)
  Runs.GetAll()
  return cache.byId[id]
end

-- Erster Lauf mit diesem Namen (Groß-/Kleinschreibung egal), außer dem eingeloggten Charakter
function Runs.FindByName(name)
  local wanted = name:lower()
  for _, run in ipairs(Runs.GetAll()) do
    if run.id ~= ns.characterKey and (run.name or ""):lower() == wanted then return run end
  end
end

function Runs.ToggleFavorite(id)
  local favorites = store().runFavorites
  favorites[id] = not favorites[id] or nil
end

ns.OnLogin(Runs.Invalidate)
ns.OnLevelStarted(Runs.Invalidate)  -- nach allen OnLevelCompleted: Level-Historie und Prüfcode stehen schon
ns.RegisterApply(Runs.Invalidate)
ns.Database.OnCharacterDeleted(Runs.Invalidate)
ns.Database.OnCharacterReplaced(Runs.Invalidate)

-- Schnellste Zeit je Level über alle eigenen Charaktere (bestTimes: ohne Teil-Level), außer excludeKey (nil =
-- alle). Rückgabe: best[level] = Sekunden, holders[level] = Lauf mit dieser Zeit
function Runs.BestPerLevel(excludeKey)
  local best, holders = {}, {}
  for _, run in ipairs(Runs.GetAll()) do
    if not run.imported and run.id ~= excludeKey then
      for level, seconds in pairs(run.bestTimes) do
        if not best[level] or seconds < best[level] then best[level], holders[level] = seconds, run end
      end
    end
  end
  return best, holders
end

-- Summe der Zeiten von Level from bis to; nil, wenn eines davon fehlt
function Runs.SumOfLevels(times, from, to)
  if from > to then return nil end  -- leere Spanne (z.B. noch kein eigenes Level abgeschlossen)
  local sum = 0
  for level = from, to do
    if not times[level] then return nil end
    sum = sum + times[level]
  end
  return sum
end

---------------------------------------------------------------------------
-- Teilen und Sichern: Läufe als Text (Serializer) exportieren und importieren
---------------------------------------------------------------------------
local Serializer = ns.Serializer
local KIND_RUN, KIND_RUNS = "run", "runs"

-- Mit Streamer-Datenschutz ohne Realm und mit dem Anzeigenamen der Historie (andere Charaktere als
-- "Charakter N"), wie überall sonst im Addon
local function shareable(run)
  local name, realm = run.name, run.realm
  if ns.db.streamerPrivacy then
    realm = nil
    if not run.imported then name = History.DisplayName(run.id) end
  end
  return { name = name, realm = realm, class = run.class, reachedLevel = run.reachedLevel, times = run.times,
    coverage = run.coverage, check = run.check, checkFrom = run.checkFrom, checkTo = run.checkTo,
    category = run.category }
end

function Runs.Export(run)
  return Serializer.Encode(KIND_RUN, shareable(run))
end

-- Alle Läufe (eigene und importierte) in einem Text, z.B. als Sicherung oder für einen anderen Client
function Runs.ExportAll()
  local list = {}
  for _, run in ipairs(Runs.GetAll()) do
    table.insert(list, shareable(run))
  end
  return Serializer.Encode(KIND_RUNS, list)
end

-- Text von außen ohne "|": sonst würden Escape-Sequenzen (|c Farbe, |H Link, |T Textur) angezeigt
local function plain(text)
  return type(text) == "string" and (text:gsub("|", "")) or nil
end

local function number(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge and value or nil
end

-- Prüfcode von außen: nur Hex-Text (RunCheck.lua), sonst verworfen
local function checkCode(value)
  return type(value) == "string" and value:match("^%x+$") and value or nil
end

-- Erfassungsquote von außen: Anteil 0..1
local function fraction(value)
  value = number(value)
  return value and math.max(0, math.min(1, value)) or nil
end

-- Nur Läufe mit Namen und Level-Zeiten aus Zahlen übernehmen (der Text kommt von außen)
local function sanitize(run)
  if type(run) ~= "table" or type(run.name) ~= "string" or type(run.times) ~= "table" then return nil end
  local times = {}
  for level, seconds in pairs(run.times) do
    -- Zeiten von außen: ganze Level 1..MAX_LEVEL, endliche positive Sekunden (inf oder negativ würde Summen und
    -- Vergleiche zerstören)
    if not Runs.IsValidLevel(level) or not Runs.IsValidSeconds(seconds) then return nil end
    times[level] = seconds
  end
  return {
    name = plain(run.name),
    realm = plain(run.realm),
    class = plain(run.class),
    reachedLevel = number(run.reachedLevel),
    times = times,
    coverage = fraction(run.coverage),
    category = ns.RunCategory.IsValid(run.category) and run.category or nil,
    check = checkCode(run.check),
    checkFrom = number(run.checkFrom),
    checkTo = number(run.checkTo),
  }
end

-- Schlüssel für "schon vorhanden": Name, Realm und alle Level-Zeiten (nach Level sortiert)
local IDENTITY_SEPARATOR = "\1"
local NO_VALUE = "\2"

local function identity(run)
  local levels = {}
  for level in pairs(run.times) do levels[#levels + 1] = level end
  table.sort(levels)
  local parts = { run.name or NO_VALUE, run.realm or NO_VALUE }
  for _, level in ipairs(levels) do parts[#parts + 1] = level .. "=" .. run.times[level] end
  return table.concat(parts, IDENTITY_SEPARATOR)
end

-- Vorhandene Läufe (eigene Charaktere und Importe) als Menge, einmal je Import gebaut
local function knownRuns()
  local known = {}
  for _, existing in ipairs(Runs.GetAll()) do known[identity(existing)] = true end
  return known
end

-- Alter Versuch eines neu erstellten Charakters gleichen Namens: bleibt als importierter Lauf zum
-- Vergleichen erhalten (Database.OnCharacterReplaced, vor dem Neubeginn der Daten)
ns.Database.OnCharacterReplaced(function(data)
  local times = {}
  for level, record in pairs(data.levelHistory or {}) do
    if record.seconds then times[level] = record.seconds end
  end
  if not next(times) then return end
  table.insert(store().importedRuns, {
    name = data.name, realm = data.realm, class = data.class,
    times = times, reachedLevel = data.currentLevel.level,
  })
end)

-- Text mit einem Lauf oder allen Läufen importieren. Rückgabe: Zahl neuer Läufe, nil bei ungültigem Text
function Runs.Import(text)
  local single = Serializer.Decode(KIND_RUN, text)
  local list = single and { single } or Serializer.Decode(KIND_RUNS, text)
  if type(list) ~= "table" then return nil end
  local runs = {}
  for i, candidate in ipairs(list) do
    runs[i] = sanitize(candidate)
    if not runs[i] then return nil end  -- erst alles prüfen, dann übernehmen
  end
  -- Schon vorhanden: Lauf gleichen Namens und Realms mit denselben Zeiten (eigener Charakter, importiert oder
  -- früher im selben Text). Ein alter Versuch eines zurückgesetzten oder neu erstellten Charakters ist neu.
  local known, added = knownRuns(), 0
  for _, run in ipairs(runs) do
    local key = identity(run)
    if not known[key] then
      known[key] = true
      table.insert(store().importedRuns, run)
      added = added + 1
    end
  end
  return added
end
