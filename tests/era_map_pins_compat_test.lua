-- Kartenpunkte über Zonengrenzen und mit Kartenaddons (LT-39): Geber aus Sturmwind (1453) erscheinen auf der Karte von
-- Elwynn (1429) und auf der Kontinentkarte (1415), umgerechnet über die erzeugten Kartenbereiche; Punkte behalten beim
-- Zoomen ihre Größe; OpenMap: über der Kartenkunst, Umrechnung über OpenMapAPI; Leatrix-Dungeon-Symbole erkannt.
local Compat = addon.MapCompat

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end

local shownMap = 1453
local canvasScale = 1
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
local canvas = CreateFrame("Frame")
canvas:SetSize(1000, 600)
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame.GetMapID = function() return shownMap end
WorldMapFrame.OnMapChanged = function() end
WorldMapFrame.OnCanvasScaleChanged = function() end
WorldMapFrame.GetCanvasScale = function() return canvasScale end
WorldMapFrame.ScrollContainer = { GetScaleForMinZoom = function() return 1 end }

local children = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then
    children[parent] = children[parent] or {}
    table.insert(children[parent], frame)
  end
  return frame
end

wow.state.class = "WARRIOR"
wow.login({ level = 15 })
wow.fire("QUEST_LOG_UPDATE")

local overlay = LevelTimerDungeonQuestGivers
expectTrue("Ebene auf der Leinwand", overlay ~= nil and overlay._parent == canvas)

local function shownPins()
  local list = {}
  for _, pin in ipairs(children[overlay] or {}) do
    if pin:IsShown() then table.insert(list, pin) end
  end
  return list
end
local function showMap(mapID)
  shownMap = mapID
  WorldMapFrame:OnMapChanged()
end

showMap(1453)
local own = #shownPins()
expectTrue("Sturmwind: eigene Geber", own > 0)
showMap(1429)
expectTrue("Elwynn: Geber aus Sturmwind mit", #shownPins() >= own)
showMap(1415)
expectTrue("Kontinent: Geber der Zonen", #shownPins() >= own)
showMap(1411)
expectTrue("Durotar ohne Sturmwind-Geber", (function()
  for _, pin in ipairs(shownPins()) do
    for _, offer in ipairs(pin.point.offers) do if offer.questID == 167 then return false end end
  end
  return true
end)())

-- Umrechnung: Mitte von Sturmwind liegt innerhalb von Elwynn
local x, y = addon.MapCoords.Translate(1453, 0.5, 0.5, 1429)
expectTrue("Sturmwind in Elwynn", x > 0 and x < 1 and y > 0 and y < 1)
expect("verschiedene Kontinente", addon.MapCoords.Translate(1453, 0.5, 0.5, 1411), nil)

-- Zoom: Punkte halten ihre Bildschirmgröße (Skalierung minZoom / aktuell)
showMap(1453)
canvasScale = 2
WorldMapFrame:OnCanvasScaleChanged()
expectNear("hineingezoomt: halbe Skalierung", shownPins()[1]._scale, 0.5)

-- OpenMap: zusammengesetzte Karte, Kunst bis Ebene 500, eigene Umrechnung
wow.state.combatLockdown = false
local stitched = true
OpenMapAPI = {
  IsStitched = function() return stitched end,
  ArtTopLevel = function() return 500 end,
  WorldFromMap = function(_, mapX, mapY) return mapX, mapY end,
  MapFromWorld = function(_, u, v) return u + 2, v end,  -- alles weit rechts außerhalb der Ansicht
}
local realLoaded = C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded = function(name) return name == "OpenMap" or realLoaded(name) end
expectTrue("OpenMap erkannt", Compat.Stitched())
showMap(1429)
expect("über der Kartenkunst", overlay:GetFrameLevel(), 502)
expect("Nachbarn außerhalb der Ansicht fallen weg", #shownPins(), #addon.DungeonQuests.OffersOnMap(1429))
expect("Rand der Ansicht", Compat.VisibleMargin(), 1)
OpenMapAPI.MapFromWorld = function(_, u, v) return u + 0.5, v end
showMap(1430)
expectTrue("Nachbarn im Rand der Ansicht", #shownPins() > 0)
expectTrue("OpenMap zeigt Eingänge", Compat.ShowsDungeonEntrances())
OpenMapDB = { worldmap = { icons = false } }
expectTrue("OpenMap-Eingänge aus", not Compat.ShowsDungeonEntrances())
stitched = false
expectTrue("Blizzards Karte unter OpenMap", not Compat.Stitched())

-- Leatrix Maps: Dungeon-Symbole nur mit beiden Einstellungen
C_AddOns.IsAddOnLoaded = function(name) return name == "Leatrix_Maps" end
LeaMapsDB = { ShowPointsOfInterest = "On", ShowDungeonIcons = "Off" }
expectTrue("Leatrix ohne Dungeon-Symbole", not Compat.ShowsDungeonEntrances())
LeaMapsDB.ShowDungeonIcons = "On"
expectTrue("Leatrix mit Dungeon-Symbolen", Compat.ShowsDungeonEntrances())
C_AddOns.IsAddOnLoaded = realLoaded
expectTrue("ohne Kartenaddon", not Compat.ShowsDungeonEntrances())
