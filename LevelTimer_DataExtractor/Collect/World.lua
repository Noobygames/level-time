-- Welt und Fortschritt:
--   levels[level] = { xpMax } (UnitXPMax)
--   exploration[mapID][Name] = { [Spielerlevel] = XP } aus ERR_ZONE_EXPLORED_XP ("Discovered %s: %d experience gained";
--     kommt je nach Client als CHAT_MSG_SYSTEM oder UI_INFO_MESSAGE, daher beide)
--   instances[Karten-ID] = { names, type, difficulties[difficultyID] = maxPlayers, entrances[uiMapID][Zelle] = Anzahl
--     (letzter Ort draußen vor dem Betreten), encounters[encounterID] = { names, kills, wipes, npcs[npcID] = Anzahl
--     (Ziele während des Kampfes) } }
-- GetInstanceInfo: name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic,
-- instanceID (Karten-ID), instanceGroupSize, lfgDungeonID (alle Zweige).
local _, X = ...

local World = {}
X.World = World

local OUTDOOR_SECONDS = 5  -- so oft merkt sich der Sammler draußen den Ort (Eingang = letzter Ort vor dem Portal)
local SUCCESS = 1

local lastOutdoor          -- { mapID, cell }
local currentInstance      -- Karten-ID oder nil
local encounter            -- laufender Bosskampf: { id, npcs = {} }

local function instanceRecord(mapID)
  return X.Record("instances", mapID)
end

local function noteLevel()
  if not X.db then return end
  local level, xpMax = X.Readable(UnitLevel("player")), X.Readable(UnitXPMax("player"))
  if type(level) == "number" and type(xpMax) == "number" and xpMax > 0 then
    X.Record("levels", level).xpMax = xpMax
  end
end
X.OnLogin(noteLevel)
X.On("PLAYER_LEVEL_UP", function() C_Timer.After(1, noteLevel) end)

---------------------------------------------------------------------------
-- Erkundung
---------------------------------------------------------------------------
local explorePattern, exploreOrder = X.PatternFromFormat(ERR_ZONE_EXPLORED_XP)

local function noteExploration(text)
  local args = X.MatchFormat(text, explorePattern, exploreOrder)
  if not args or not X.db then return end
  local mapID = X.Position()
  local xp = tonumber(args[2])
  if not mapID or not xp then return end
  local zone = X.Record("exploration", mapID)
  zone[args[1]] = zone[args[1]] or {}
  zone[args[1]][X.Readable(UnitLevel("player")) or 0] = xp
end
X.On("CHAT_MSG_SYSTEM", noteExploration)
X.On("UI_INFO_MESSAGE", function(_, text) noteExploration(text) end)

---------------------------------------------------------------------------
-- Instanzen
---------------------------------------------------------------------------
local function sampleOutdoor()
  if currentInstance then return end
  local mapID, cell = X.Position()
  if mapID and cell then lastOutdoor = { mapID = mapID, cell = cell } end
end

local function onWorld()
  if not X.db then return end
  local name, kind, difficultyID, _, maxPlayers, _, _, mapID = GetInstanceInfo()
  kind, mapID = X.Readable(kind), X.Readable(mapID)
  if not kind or kind == "none" or type(mapID) ~= "number" then
    currentInstance = nil
    return
  end
  local record = instanceRecord(mapID)
  X.SetName(record, name)
  record.type = kind
  difficultyID = X.Readable(difficultyID)
  if type(difficultyID) == "number" and difficultyID > 0 then
    record.difficulties = record.difficulties or {}
    record.difficulties[difficultyID] = X.Readable(maxPlayers)
  end
  if currentInstance ~= mapID and lastOutdoor then
    record.entrances = record.entrances or {}
    local cells = record.entrances[lastOutdoor.mapID] or {}
    record.entrances[lastOutdoor.mapID] = cells
    X.Increment(cells, lastOutdoor.cell)
  end
  currentInstance = mapID
end

X.OnLogin(function() C_Timer.NewTicker(OUTDOOR_SECONDS, function() X.SafeCall(sampleOutdoor) end) end)
X.On("PLAYER_ENTERING_WORLD", onWorld)
X.On("ZONE_CHANGED_NEW_AREA", onWorld)

X.On("ENCOUNTER_START", function(encounterID, name)
  encounterID = X.Readable(encounterID)
  if type(encounterID) ~= "number" or not X.db or not currentInstance then return end
  local record = instanceRecord(currentInstance)
  record.encounters = record.encounters or {}
  local stored = record.encounters[encounterID] or {}
  record.encounters[encounterID] = stored
  X.SetName(stored, name)
  encounter = { id = encounterID, npcs = {} }
end)

X.On("PLAYER_TARGET_CHANGED", function()
  if not encounter then return end
  local npcID = X.Units.Observe("target")
  if npcID then encounter.npcs[npcID] = true end
end)

X.On("ENCOUNTER_END", function(encounterID, _, _, _, success)
  encounterID = X.Readable(encounterID)
  if not encounter or encounter.id ~= encounterID or not currentInstance then
    encounter = nil
    return
  end
  local stored = instanceRecord(currentInstance).encounters[encounterID]
  X.Increment(stored, X.Readable(success) == SUCCESS and "kills" or "wipes")
  stored.npcs = stored.npcs or {}
  for npcID in pairs(encounter.npcs) do X.Increment(stored.npcs, npcID) end
  encounter = nil
end)
