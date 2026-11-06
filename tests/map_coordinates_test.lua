-- Kartenkoordinaten: Spieler und Mauszeiger unten auf der Weltkarte, nichts in Instanzen oder neben der Karte
local L = addon.L
local MapCoordinates = addon.MapCoordinates

-- Weltkarte wie Blizzards MapCanvas: Karten-ID, Mausposition 0..1, Scroll-Container
local mouseOver = true
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame.ScrollContainer = CreateFrame("Frame")
WorldMapFrame.ScrollContainer.IsMouseOver = function() return mouseOver end
WorldMapFrame.GetMapID = function() return 1429 end
WorldMapFrame.GetNormalizedCursorPosition = function() return 0.123, 0.4 end
local playerPosition = { 0.452, 0.631 }
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function(mapID)
    if mapID ~= 1429 or not playerPosition then return nil end
    return { GetXY = function() return playerPosition[1], playerPosition[2] end }
  end,
}

wow.login({ level = 10 })
local display = LevelTimerMapCoordinates
expectTrue("auf der Karte eingehängt", display ~= nil and display._parent == WorldMapFrame)
expectTrue("aus: versteckt", not display:IsShown())

addon.Set("mapCoordinates", true)
expectTrue("an: sichtbar", display:IsShown())
wow.update(0.2)
expect("Text", display.text:GetText(), string.format(L.MAP_COORDS, "45.2, 63.1", "12.3, 40.0"))

-- Maus neben der Karte, Spieler in einer Instanz (keine Position)
mouseOver = false
playerPosition = nil
expect("ohne Position", MapCoordinates.Text(WorldMapFrame),
  string.format(L.MAP_COORDS, L.MAP_COORDS_NONE, L.MAP_COORDS_NONE))

-- Geheime Werte: keine Zahl
mouseOver = true
WorldMapFrame.GetNormalizedCursorPosition = function() return wow.SECRET, wow.SECRET end
expect("geheim", MapCoordinates.CursorText(WorldMapFrame), L.MAP_COORDS_NONE)

addon.Set("mapCoordinates", false)
expectTrue("aus: wieder versteckt", not display:IsShown())
