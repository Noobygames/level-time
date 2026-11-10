-- Roadmap 461: Welt-/Kartenkoordinaten (Lib/MapCoords.lua), Retail: Elwynn (37) aus den erzeugten Bereichen
local Coords = addon.MapCoords
wow.login({ level = 20 })

-- Ohne Client-API gelten die Daten: Karte (0,0) liegt bei Nord-Maximum und West-Maximum
C_Map = nil
local instance, northX, westY = Coords.MapToWorld(37, 0, 0)
expect("Elwynn Instanz", instance, 0)
expectNear("Elwynn (0,0) Nord", northX, -7939.58, 0.01)
expectNear("Elwynn (0,0) West", westY, 1535.42, 0.01)
local _, southX, eastY = Coords.MapToWorld(37, 1, 1)
expectNear("Elwynn (1,1) Nord", southX, -10254.2, 0.01)
expectNear("Elwynn (1,1) West", eastY, -1935.42, 0.01)

-- Hin und zurück
local _, wx, wy = Coords.MapToWorld(37, 0.42, 0.67)
local x, y = Coords.WorldToMap(37, wx, wy)
expectNear("Rundreise x", x, 0.42, 1e-6)
expectNear("Rundreise y", y, 0.67, 1e-6)
local width, height = Coords.Size(37)
expectNear("Breite West-Ost", width, 3470.84, 0.01)
expectNear("Höhe Nord-Süd", height, 2314.62, 0.01)

expect("Unbekannte Karte", Coords.MapToWorld(999999, 0.5, 0.5), nil)
expect("Unbekannte Karte Rückweg", Coords.WorldToMap(999999, 0, 0), nil)
expect("Ungültige Eingabe", Coords.MapToWorld(37, nil, 0.5), nil)

-- Mit Client-API gewinnt deren Antwort
CreateVector2D = function(vx, vy) return { x = vx, y = vy } end
C_Map = {
  GetWorldPosFromMapPos = function() return 7, { GetXY = function() return 11, 22 end } end,
  GetMapPosFromWorldPos = function() return 37, { GetXY = function() return 0.3, 0.4 end } end,
}
local liveInstance, liveX, liveY = Coords.MapToWorld(37, 0.5, 0.5)
expect("API Instanz", liveInstance, 7)
expect("API Nord", liveX, 11)
expect("API West", liveY, 22)
local mapX, mapY = Coords.WorldToMap(37, 1, 2)
expect("API Karte x", mapX, 0.3)
expect("API Karte y", mapY, 0.4)
