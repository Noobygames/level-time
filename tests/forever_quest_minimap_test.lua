-- Gelernte Questorte auf der Minimap (LT-258): Zielorte offener und Abgabe-NPC fertiger Quests, über die Zonengrenze
-- (Spieler in Elwynn, Abgabe in Sturmwind), am Rand blass, Einstellungen questMap/questMinimap.
-- Nur eigene Symbole (mit point) zählen; Dungeonquest-Geber teilen die Minimap.
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
  for _, pin in ipairs(pins) do
    if pin:IsShown() and type(rawget(pin, "point")) == "table" then table.insert(list, pin) end
  end
  return list
end
local function offset(pin)
  local point = pin._points[#pin._points]
  return point[4], point[5]
end

wow.state.questLog = { { questID = 60, title = "Eberjagd", objectives = { { text = "Eber: 1/5", finished = false } } } }
wow.login({ level = 10 })
expect("Standard: an, folgt der Weltkarte", addon.db.questMinimap, true)
expect("Weltkarte aus: Minimap aus", addon.db.questMap, false)

-- Abgabe in Sturmwind, umgerechnet genau am Spieler in Elwynn; ein Zielort direkt am Spieler
local turnX, turnY = 0.5, 0.5
local stormX, stormY = addon.MapCoords.Translate(1429, turnX, turnY, 1453)
expectTrue("Sturmwind umrechenbar", stormX ~= nil)
LevelTimerStatsDB.questNpcs = { [60] = {
  turnIn = { name = "Gryan", mapID = 1453, x = stormX, y = stormY },
  spots = { { mapID = 1429, x = 0.5, y = 0.5 } },
} }
wow.fire("QUEST_LOG_UPDATE")
wow.update(0.3)
expect("Weltkarte aus: keine Symbole", #shown(), 0)

addon.Set("questMap", true)
wow.update(0.3)
local list = shown()
expect("offene Quest: ein Zielort", #list, 1)
expect("Zielort-Tooltipdaten", list[1].point.questID, 60)
local x, y = offset(list[1])
expectTrue("Zielort in der Mitte", math.abs(x) < 0.01 and math.abs(y) < 0.01)

-- Fertig: Fragezeichen am Abgabe-NPC jenseits der Zonengrenze
wow.state.questLog[1].isComplete = 1
wow.fire("QUEST_LOG_UPDATE")
wow.update(0.3)
list = shown()
expect("fertig: nur die Abgabe", #list, 1)
expect("Abgabe-NPC", list[1].point.npc, "Gryan")
x, y = offset(list[1])
expectTrue("Abgabe über die Zonengrenze in der Mitte", math.abs(x) < 0.01 and math.abs(y) < 0.01)

-- Etwas außerhalb des Sichtradius: blass am Rand
local radius = addon.MinimapPins.Radius()
local _, northCenter = addon.MapCoords.MapToWorld(1429, 0.5, 0.5)
local _, northFurther = addon.MapCoords.MapToWorld(1429, 0.5, 0.6)
local yardsPerUnit = math.abs(northFurther - northCenter) / 0.1
player = { 0.5, 0.5 + radius * 1.5 / yardsPerUnit }
wow.update(0.3)
list = shown()
expect("am Rand gezeigt", #list, 1)
expectNear("am Rand blass", list[1]:GetAlpha(), 0.6)
x, y = offset(list[1])
expectTrue("am Rand oben (nach Norden)", y > 0 and math.abs(x) < 0.01)

-- Minimap-Schalter aus: Symbole weg
addon.Set("questMinimap", false)
expect("Minimap aus: keine Symbole", #shown(), 0)
expect("Fehler?", #wow.errors, 0)
