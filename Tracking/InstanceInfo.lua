-- Instanz-Stammdaten (Roadmap 460): Reset, Gruppengröße und Level-Bereich je Karte aus den Spieldaten
-- (ns.InstanceData, generiert von tools/flights nach Assist/InstanceData/<flavor>.lua; Retail ohne Level). Forever liefert
-- keine Level-Spalten: dort kommen die Bereiche aus dem gepflegten ns.InstanceGuide (Assist/InstanceData/forever_guide.lua).
-- Schlüssel ist die Karten-ID (8. Rückgabewert von GetInstanceInfo) und die Schwierigkeit.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showInstanceInfo = false,
    showInstanceFit = false,
  },
})

local InstanceInfo = {}
ns.InstanceInfo = InstanceInfo

local RESET_INDEX, PLAYERS_INDEX = 1, 2
local MIN_INDEX, MAX_INDEX = 1, 2
local DAILY_DAYS, WEEKLY_DAYS = 1, 7
local MAX_PARTY_PLAYERS = 10  -- größere Karten sind Schlachtzüge (kein Dungeon-Hinweis)

local function data() return ns.InstanceData or {} end
local function levels() return data().levels or (ns.InstanceGuide or {}).levels or {} end

-- Stammdaten einer Schwierigkeit; ohne genaue Schwierigkeit die mit der kleinsten ID der Karte
local function modeOf(mapID, difficultyID)
  local modes = (data().modes or {})[mapID]
  if not modes then return nil end
  if difficultyID and modes[difficultyID] then return modes[difficultyID] end
  local lowest
  for id in pairs(modes) do
    if not lowest or id < lowest then lowest = id end
  end
  return modes[lowest]
end

-- { resetDays (0 = kein Reset), players, minLevel, maxLevel } (Level nil ohne Level-Spalten) oder nil
function InstanceInfo.Get(mapID, difficultyID)
  if type(mapID) ~= "number" or ns.IsSecret(mapID) then return nil end
  local mode = modeOf(mapID, difficultyID)
  if not mode then return nil end
  local range = levels()[mapID]
  return { resetDays = mode[RESET_INDEX], players = mode[PLAYERS_INDEX],
    minLevel = range and range[MIN_INDEX], maxLevel = range and range[MAX_INDEX] }
end

-- Gibt es Level-Bereiche? (Era, Anniversary, Forever)
function InstanceInfo.HasLevels()
  return next(levels()) ~= nil
end

-- "Kein Reset", "Täglich", "Wöchentlich" oder "Alle 3 Tage"
function InstanceInfo.ResetText(days)
  local L = ns.L
  if not days or days <= 0 then return L.INSTANCE_RESET_NONE end
  if days == DAILY_DAYS then return L.INSTANCE_RESET_DAILY end
  if days == WEEKLY_DAYS then return L.INSTANCE_RESET_WEEKLY end
  return string.format(L.INSTANCE_RESET_DAYS, days)
end

function InstanceInfo.PlayersText(players)
  return string.format(ns.L.INSTANCE_PLAYERS, players)
end

-- Ein Satz für die Statistikzeile: "5 Spieler, Reset: Täglich, Level 15-28"
function InstanceInfo.Describe(mapID, difficultyID)
  local info = InstanceInfo.Get(mapID, difficultyID)
  if not info then return nil end
  local parts = { InstanceInfo.PlayersText(info.players), string.format(ns.L.INSTANCE_RESET, InstanceInfo.ResetText(info.resetDays)) }
  if info.minLevel then
    table.insert(parts, string.format(ns.L.INSTANCE_LEVELS, info.minLevel, info.maxLevel))
  end
  return table.concat(parts, ", ")
end

-- Name der Instanz in der Spielsprache (GetRealZoneText nimmt die Karten-ID einer Instanz)
function InstanceInfo.MapName(mapID)
  local name = GetRealZoneText and GetRealZoneText(mapID)
  if type(name) == "string" and name ~= "" and not ns.IsSecret(name) then return name end
  return tostring(mapID)
end

-- Dungeons, deren Level-Bereich das Level enthält, die mit dem höchsten Mindestlevel zuerst:
-- { { mapID, minLevel, maxLevel }, ... }; leer ohne Level-Spalten
function InstanceInfo.ForLevel(level)
  local list = {}
  for mapID, range in pairs(levels()) do
    local mode = modeOf(mapID)
    if mode and mode[PLAYERS_INDEX] <= MAX_PARTY_PLAYERS and level >= range[MIN_INDEX] and level <= range[MAX_INDEX] then
      table.insert(list, { mapID = mapID, minLevel = range[MIN_INDEX], maxLevel = range[MAX_INDEX] })
    end
  end
  table.sort(list, function(a, b)
    if a.minLevel ~= b.minLevel then return a.minLevel > b.minLevel end
    return a.mapID < b.mapID
  end)
  return list
end
