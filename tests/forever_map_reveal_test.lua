-- Karte aufdecken (WoW Forever): Kacheldaten je Kartengrafik, erkundete Überlagerungen werden übersprungen, Einstellung
local MapReveal = addon.MapReveal

expectTrue("Kacheldaten geladen", addon.MapOverlayData ~= nil and addon.MapOverlayData.art[1194] ~= nil)

local exploredOffsets = {}
C_Map = {
  GetMapArtID = function(mapID) return mapID == 1411 and 1194 or 0 end,
  GetMapArtLayers = function() return { { tileWidth = 256, tileHeight = 256, layerWidth = 1002, layerHeight = 668 } } end,
}
C_MapExplorationInfo = { GetExploredMapTextures = function() return exploredOffsets end }

WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame.GetMapID = function() return 1411 end
WorldMapFrame.GetCanvas = function() return WorldMapFrame end

wow.login({ level = 10 })
local all = MapReveal.Overlays(1411)
local first = addon.MapOverlayData.art[1194][1]
expect("alle unerkundet", #all, #addon.MapOverlayData.art[1194])
expect("andere Karte ohne Daten", MapReveal.Overlays(1))

exploredOffsets = { { offsetX = first[3], offsetY = first[4] } }
local rest = MapReveal.Overlays(1411)
expect("erkundete übersprungen", #rest, #all - 1)

expectTrue("aus: versteckt", LevelTimerMapReveal ~= nil and not LevelTimerMapReveal:IsShown())
addon.Set("mapReveal", true)
expectTrue("an: sichtbar", LevelTimerMapReveal:IsShown())
MapReveal.Refresh()
addon.Set("mapReveal", false)
expectTrue("wieder aus", not LevelTimerMapReveal:IsShown())
