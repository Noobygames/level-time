-- Merkt sich beim Besuch des Klassenlehrers, welche Fähigkeiten er ab welchem Level anbietet, damit das
-- Level-Up-Fenster (UI/LevelUpWindow.lua) die neuen Fähigkeiten zeigen kann. Die Daten stammen aus dem Spiel selbst
-- (kein Abruf von außen); jede Klasse wird einmal gelernt und gilt für alle Charaktere dieser Klasse (Account).
-- Classic Era/TBC und WoW Forever; Retail lernt Zauber automatisch und hat keine Lehrerliste für die Klasse.
--   Gespeichert: LevelTimerStatsDB.trainerCache[Klasse][name .. "|" .. rank] = { name, rank, level, icon }
-- API je Client (Blizzard_TrainerUI, Zweige classic_era und forever):
--   Era/TBC:  GetTrainerServiceInfo(i) -> name, rank, serviceType, isExpanded; Level GetTrainerServiceLevelReq(i), Symbol GetTrainerServiceIcon(i)
--   Forever:  GetTrainerServiceInfo(i) -> name, serviceType, texture, reqLevel, rank, category
local _, ns = ...

local TrainerCache = {}
ns.TrainerCache = TrainerCache

local HEADER = "header"

function TrainerCache.IsAvailable()
  return not ns.Client.IsRetail()
end

local function classKey()
  return (select(2, UnitClass("player")))
end

-- Art einer Zeile der Lehrerliste ("available", "unavailable", "used", "header"); Stelle je Client siehe oben
function TrainerCache.ServiceType(index)
  if ns.Client.IsForever() then return (select(2, GetTrainerServiceInfo(index))) end
  return (select(3, GetTrainerServiceInfo(index)))
end

-- Eine Zeile der Lehrerliste als { name, rank, level, icon }; nil für Überschriften und Unbrauchbares
local function readService(index)
  local name, rank, serviceType, level, icon
  if ns.Client.IsForever() then
    local texture, reqLevel, subText
    name, serviceType, texture, reqLevel, subText = GetTrainerServiceInfo(index)
    rank, level, icon = subText, reqLevel, texture
  else
    name, rank, serviceType = GetTrainerServiceInfo(index)
    level = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(index)
    icon = GetTrainerServiceIcon and GetTrainerServiceIcon(index)
  end
  if serviceType == HEADER or type(name) ~= "string" or name == "" then return nil end
  if type(level) ~= "number" or level < 1 then return nil end
  return { name = name, rank = rank or "", level = level, icon = icon }
end

-- Liste des offenen Lehrers einlesen und zur gemerkten Liste der Klasse hinzufügen (Berufslehrer ignorieren)
function TrainerCache.Read()
  if not TrainerCache.IsAvailable() or not LevelTimerStatsDB or not GetNumTrainerServices then return end
  if IsTradeskillTrainer and IsTradeskillTrainer() then return end
  local class = classKey()
  if not class then return end
  local cache = LevelTimerStatsDB.trainerCache or {}
  LevelTimerStatsDB.trainerCache = cache
  cache[class] = cache[class] or {}
  local added = 0
  for index = 1, GetNumTrainerServices() do
    local entry = readService(index)
    if entry then
      local key = entry.name .. "|" .. entry.rank
      if not cache[class][key] then added = added + 1 end
      cache[class][key] = entry
    end
  end
  ns.Debug("trainer", "cache %s: %s new entries", class, added)
end

-- Fähigkeiten, die der Lehrer ab genau diesem Level anbietet, nach Name sortiert
function TrainerCache.ForLevel(level)
  local result = {}
  local cache = LevelTimerStatsDB and LevelTimerStatsDB.trainerCache
  for _, entry in pairs(cache and cache[classKey()] or {}) do
    if entry.level == level then table.insert(result, entry) end
  end
  table.sort(result, function(a, b)
    if a.name ~= b.name then return a.name < b.name end
    return a.rank < b.rank
  end)
  return result
end

-- Anzahl gemerkter Fähigkeiten der Klasse (0 = Lehrer noch nie besucht)
function TrainerCache.Count()
  local cache = LevelTimerStatsDB and LevelTimerStatsDB.trainerCache
  local count = 0
  for _ in pairs(cache and cache[classKey()] or {}) do count = count + 1 end
  return count
end

function TrainerCache.Clear()
  if LevelTimerStatsDB and LevelTimerStatsDB.trainerCache then LevelTimerStatsDB.trainerCache[classKey()] = nil end
end

ns.RegisterEvent("TRAINER_SHOW", TrainerCache.Read)
ns.RegisterEvent("TRAINER_UPDATE", TrainerCache.Read)
