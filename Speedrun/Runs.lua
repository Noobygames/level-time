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

local function fromCharacter(characterKey)
  local character = History.GetCharacter(characterKey)
  local check, checkFrom, checkTo = ns.RunCheck.ForCharacter(character)
  return {
    check = check, checkFrom = checkFrom, checkTo = checkTo,
    category = character.runCategory,
    id = characterKey,
    name = character.name,
    realm = character.realm,
    class = character.class,
    times = Runs.LevelTimes(characterKey),
    bestTimes = Runs.LevelTimes(characterKey, true),  -- ohne Teil-Level: nur diese zählen als Bestzeit
    coverage = ns.Coverage.Get(characterKey),
    reachedLevel = character.currentLevel.level,
  }
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

-- Alle Läufe: eigene Charaktere (eingeloggter zuerst), dann importierte
function Runs.GetAll()
  local favorites = store().runFavorites
  local runs = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    table.insert(runs, fromCharacter(key))
  end
  for index, run in ipairs(store().importedRuns) do
    table.insert(runs, fromImport(index, run))
  end
  for _, run in ipairs(runs) do
    run.favorite = favorites[run.id] == true
  end
  return runs
end

function Runs.Get(id)
  for _, run in ipairs(Runs.GetAll()) do
    if run.id == id then return run end
  end
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
    -- Zeiten von außen: nur endliche, positive Zahlen (inf oder negativ würde Summen und Vergleiche zerstören)
    if type(level) ~= "number" or type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0
      or seconds == math.huge then return nil end
    times[level] = seconds
  end
  return {
    name = plain(run.name),
    realm = plain(run.realm),
    class = plain(run.class),
    reachedLevel = type(run.reachedLevel) == "number" and run.reachedLevel or nil,
    times = times,
    coverage = fraction(run.coverage),
    category = ns.RunCategory.IsValid(run.category) and run.category or nil,
    check = checkCode(run.check),
    checkFrom = number(run.checkFrom),
    checkTo = number(run.checkTo),
  }
end

local function sameTimes(a, b)
  for level, seconds in pairs(a) do
    if b[level] ~= seconds then return false end
  end
  for level in pairs(b) do
    if a[level] == nil then return false end
  end
  return true
end

-- Schon vorhanden: Lauf gleichen Namens und Realms mit denselben Zeiten (eigener Charakter oder
-- importiert). Ein alter Versuch eines zurückgesetzten oder neu erstellten Charakters ist neu.
local function isKnown(run)
  for _, existing in ipairs(Runs.GetAll()) do
    if existing.name == run.name and existing.realm == run.realm and sameTimes(existing.times, run.times) then
      return true
    end
  end
  return false
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
  local added = 0
  for _, run in ipairs(runs) do
    if not isKnown(run) then
      table.insert(store().importedRuns, run)
      added = added + 1
    end
  end
  return added
end
