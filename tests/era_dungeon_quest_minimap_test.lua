-- Dungeonquest-Geber auf der Minimap (LT-37): nach Entfernung, über Zonengrenzen (Spieler in Elwynn, Geber in
-- Sturmwind), am Rand blass, weiter weg gar nicht; gedrehte Minimap; Einstellungen.
local DQ = addon.DungeonQuests
local MM = addon.MinimapPins

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end

local player = { 0.5, 0.5 }
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function(mapID)
    if mapID ~= 1429 or not player then return nil end
    return { GetXY = function() return player[1], player[2] end }
  end,
}

local pins = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent == Minimap then table.insert(pins, frame) end
  return frame
end
local function shown()
  local list = {}
  for _, pin in ipairs(pins) do if pin:IsShown() then table.insert(list, pin) end end
  return list
end

wow.state.class = "WARRIOR"
wow.login({ level = 15 })
wow.fire("QUEST_LOG_UPDATE")
expect("Standard an", addon.db.dungeonQuestMinimap, true)

-- Spieler genau beim Geber von Quest 167 (Sturmwind), aber auf der Karte von Elwynn
local giver
for _, place in ipairs(DQ.OffersOnMap(1453)) do
  for _, offer in ipairs(place.offers) do if offer.questID == 167 then giver = place end end
end
expectTrue("Geber bekannt", giver ~= nil)
local x, y = addon.MapCoords.Translate(1453, giver.x, giver.y, 1429)
player = { x, y }
wow.update(0.3)
local list = shown()
expectTrue("Geber über die Zonengrenze auf der Minimap", #list > 0)
local centered = false
for _, pin in ipairs(list) do
  local point = pin._points[#pin._points]
  if math.abs(point[4]) < 0.01 and math.abs(point[5]) < 0.01 and pin.offers[1] then centered = true end
end
expectTrue("Geber in der Mitte", centered)

-- Rand und außer Reichweite (Versatz rein rechnerisch)
local east, north, edge = MM.Offset(0, 300, 200, 0, false, true)
expectTrue("am Rand", edge and math.abs(north - 200) < 0.01 and math.abs(east) < 0.01)
expect("Rand aus: nicht zeigen", MM.Offset(0, 300, 200, 0, false, false), nil)
expect("zu weit weg", MM.Offset(0, 5000, 200, 0, false, true), nil)
local squareEast = MM.Offset(180, 180, 200, 0, true, true)
expectNear("eckige Minimap: Ecke bleibt innen", squareEast, 180)
-- gedreht: Blick nach Westen, ein Punkt im Norden liegt rechts
east, north = MM.Offset(0, 100, 200, math.pi / 2, false, true)
expectNear("gedreht: rechts", east, 100)
expectNear("gedreht: nicht oben", north, 0)

-- In einer Instanz (keine Position): nichts
player = nil
wow.update(0.3)
expect("ohne Position keine Symbole", #shown(), 0)

-- Aus: Symbole weg
player = { x, y }
wow.update(0.3)
expectTrue("wieder da", #shown() > 0)
addon.Set("dungeonQuestMinimap", false)
expect("aus: keine Symbole", #shown(), 0)
addon.Set("dungeonQuestMinimap", true)
addon.Set("dungeonQuestGivers", false)
expect("Geber aus: keine Symbole", #shown(), 0)

-- LT-341: stehender Spieler, Level-Up schaltet neue Angebote frei: Symbole folgen ohne Bewegung
addon.Set("dungeonQuestGivers", true)
player = { x, y }
wow.update(0.3)
local function shownOffers()
  local count = 0
  for _, pin in ipairs(shown()) do count = count + #(pin.offers or {}) end
  return count
end
local function mapOffers()
  local count = 0
  for _, place in ipairs(DQ.OffersOnMap(1453)) do count = count + #place.offers end
  return count
end
local before = shownOffers()
wow.levelUp(60, 100000)
wow.update(0.3)
expectTrue("Level-Up bringt neue Angebote", mapOffers() > before)
expect("Symbole folgen im Stehen", shownOffers(), mapOffers())
