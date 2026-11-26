-- Graue Dungeon-Vorquests in der Nähe (LT-412; Einstellungen dungeonQuestTrivialNearby = Hinweis, an, und dungeonQuestTrivialTracking
-- = Filter kurz einschalten, aus; nur mit ns.DungeonDB, also
-- Classic Era und Forever): Blizzard blendet Geber grauer Quests aus, solange der Minimap-Filter "Triviale Quests"
-- (Enum.MinimapTrackingFilter.TrivialQuests) aus ist. Steht der Charakter in der Zonenkarte eines Gebers, der ihm einen
-- grauen Schritt einer Vorquest-Kette oder eine graue Dungeonquest anbietet (DungeonQuests.OffersOnMap), im Umkreis
-- NEAR_YARDS (Weltkoordinaten über Lib/MapCoords.lua), kommt einmal je Geber und Quest ein Hinweis; mit dungeonQuestTrivialTracking
-- geht zusätzlich der Filter an. Ohne ihn (oder ohne Filter-API) bleibt das "!" von DungeonQuestGivers (auch bei grauen Quests).
-- Wir schalten ihn nur auf Wunsch an, wenn er aus war, und danach nur zurück, wenn er noch von uns stammt: schaltet der Spieler ihn
-- selbst um, gehört er ihm (kein Zurückschalten, kein erneutes Einschalten, bis niemand mehr in der Nähe ist).
-- Filter schalten wie Blizzard (InterfaceOverrides.lua CreateQuestSettings): Index über C_Minimap.GetTrackingFilter(i).filterID,
-- C_Minimap.SetTracking(index, an), Zustand über C_Minimap.IsFilteredOut. Classic Era hat nur den Hinweis (kein GetTrackingFilter).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestTrivialNearby = true,
    dungeonQuestTrivialTracking = false,
  },
})
local L = ns.L
local DungeonQuests = ns.DungeonQuests

local TrivialChainGivers = {}
ns.TrivialChainGivers = TrivialChainGivers

local CHECK_SECONDS = 2
local NEAR_YARDS = 60
local BANG_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"

local owned = false      -- wir haben den Filter eingeschaltet und er steht noch so
local optedOut = false   -- der Spieler hat ihn ausgeschaltet, solange Geber in der Nähe sind: nicht erneut einschalten
local hinted = {}        -- ["npcID:questID"] = true (Sitzung)

function TrivialChainGivers.IsAvailable()
  return DungeonQuests.IsAvailable()
end

local function enabled(db)
  return db and (db.dungeonQuestTrivialNearby or db.dungeonQuestTrivialTracking) and TrivialChainGivers.IsAvailable()
end

-- Filter-API vorhanden? (Classic Era: nein)
local function trackingApi()
  local map = C_Minimap
  return map and map.GetNumTrackingTypes and map.GetTrackingFilter and map.SetTracking and map.IsFilteredOut
    and Enum and Enum.MinimapTrackingFilter and Enum.MinimapTrackingFilter.TrivialQuests
end

local function filterIndex()
  local wanted = Enum.MinimapTrackingFilter.TrivialQuests
  for index = 1, C_Minimap.GetNumTrackingTypes() do
    local filter = C_Minimap.GetTrackingFilter(index)
    if type(filter) == "table" and not ns.IsSecret(filter) and filter.filterID == wanted then return index end
  end
end

-- Kann das Addon den Filter schalten? (Option "Graue Quests dort kurz einblenden")
function TrivialChainGivers.CanTrack()
  return TrivialChainGivers.IsAvailable() and trackingApi() and true or false
end

-- true/false; nil, wenn der Wert nicht lesbar ist
local function isTracking()
  local filtered = C_Minimap.IsFilteredOut(Enum.MinimapTrackingFilter.TrivialQuests)
  if ns.IsSecret(filtered) then return nil end
  return not filtered
end

local function setTracking(on)
  local index = filterIndex()
  if not index then
    ns.Debug("trivialgivers", "no tracking index for the trivial quest filter")
    return false
  end
  local ok, err = pcall(C_Minimap.SetTracking, index, on)
  ns.Debug("trivialgivers", "SetTracking(%s, %s) ok=%s %s", index, on, ok, ok and "" or err)
  return ok
end

-- Filter wieder aus, wenn er noch von uns eingeschaltet ist
local function release()
  optedOut = false
  if not owned then return end
  owned = false
  if trackingApi() and isTracking() == true then
    ns.Debug("trivialgivers", "restoring the trivial quest filter")
    setTracking(false)
  else
    ns.Debug("trivialgivers", "filter changed by the player, left alone")
  end
end

local function acquire()
  if not trackingApi() then return end
  if owned then
    if isTracking() == false then  -- der Spieler hat ihn ausgeschaltet
      owned, optedOut = false, true
      ns.Debug("trivialgivers", "player turned the filter off, hands off")
    end
    return
  end
  if optedOut or isTracking() ~= false then return end
  if setTracking(true) and isTracking() == true then owned = true end
end

-- Graue Quest? Wie Blizzards Schwierigkeitsfarbe (DifficultyUtil): Spielerlevel - Questlevel über dem Graubereich
local function isGray(questLevel)
  local level = UnitLevel("player")
  local range = UnitQuestTrivialLevelRange and UnitQuestTrivialLevelRange("player") or GetQuestGreenRange and GetQuestGreenRange()
  if ns.IsSecret(level) or ns.IsSecret(range) or type(level) ~= "number" or type(range) ~= "number"
    or type(questLevel) ~= "number" then
    return false
  end
  return level - questLevel > range
end

-- Entfernung des Spielers zu einem Punkt seiner Zonenkarte in Yards; nil, wenn nicht bestimmbar
local function yardsTo(playerMap, x, y)
  local px, py = ns.MapDirection.XY(C_Map.GetPlayerMapPosition(playerMap, "player"))
  if not px then return nil end
  local fromInstance, fromNorth, fromWest = ns.MapCoords.MapToWorld(playerMap, px, py)
  local toInstance, toNorth, toWest = ns.MapCoords.MapToWorld(playerMap, x, y)
  if not (fromInstance and fromInstance == toInstance) then return nil end
  return math.sqrt((fromNorth - toNorth) ^ 2 + (fromWest - toWest) ^ 2)
end

-- Graue Angebote von Gebern in der Nähe: { { npcID, questID, mapID }, ... }
local function nearbyOffers()
  local found = {}
  local playerMap = ns.MapDirection.PlayerMap()
  if not (playerMap and C_Map.GetPlayerMapPosition) then return found end
  for _, place in ipairs(DungeonQuests.OffersOnMap(playerMap)) do
    local gray = {}
    for _, offer in ipairs(place.offers) do
      if isGray(offer.level) then table.insert(gray, offer) end
    end
    local distance = #gray > 0 and yardsTo(playerMap, place.x, place.y)
    if distance and distance <= NEAR_YARDS then
      for _, offer in ipairs(gray) do
        local kind, giverID = DungeonQuests.Giver(offer.questID)
        if kind == "npc" then table.insert(found, { npcID = giverID, questID = offer.questID, mapID = offer.mapID }) end
      end
    end
  end
  return found
end

local function hint(entry)
  local key = entry.npcID .. ":" .. entry.questID
  if hinted[key] then return end
  hinted[key] = true
  local npc = ns.NpcNames.Get(entry.npcID) or ("#" .. entry.npcID)
  ns.Debug("trivialgivers", "gray quest %s near %s (%s)", entry.questID, npc, entry.npcID)
  ns.Alerts.Notify({ hideKey = "trivialChainGiver", title = L.NOTICE_TRIVIAL_CHAIN_GIVER,
    text = string.format(L.TRIVIAL_CHAIN_GIVER_HINT, DungeonQuests.Title(entry.questID),
      ns.InstanceInfo.MapName(entry.mapID), npc), icon = BANG_ICON }, ns.Alerts.REMINDER_COLOR, ns.Alerts.COLLECT)
end

local function check()
  local found = nearbyOffers()
  if #found == 0 then release() return end
  if ns.db.dungeonQuestTrivialNearby then
    for _, entry in ipairs(found) do hint(entry) end
  end
  if ns.db.dungeonQuestTrivialTracking then acquire() end
end

ns.Every(CHECK_SECONDS, check, enabled)
ns.OnLogout(release)
ns.RegisterApply(function(db)
  if not (enabled(db) and db.dungeonQuestTrivialTracking) then release() end
end)
