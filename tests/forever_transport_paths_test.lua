-- Schiffs- und Zeppelin-Rundkurse aus den Spieldaten (Roadmap 459, Assist/TransportPaths.lua): Zuordnung der
-- gelernten Anleger über die Weltposition, Tempo aus einer gelernten Periode, daraus Fahrzeit und Phase der
-- Gegenrichtung; bekannte Zeppelinmeister ohne /lt transport master; Beschriftung für die Weltkarte.
local L = addon.L

-- Rundkurs Orgrimmar <-> Undercity (TaxiPath 302 in Forever): je 60 s Liegezeit
addon.TransportData = { paths = { [302] = {
  { continent = 1, x = 1318, y = -4658, wait = 60, next = 3300 },
  { continent = 0, x = 2062, y = 293, wait = 60, next = 2389 },
} } }

local mapNames = { [1454] = "Orgrimmar", [1420] = "Tirisfal Glades" }
-- Weltposition je Karte (Kontinent, x, y), wie C_Map.GetWorldPosFromMapPos sie liefert; Achsen vertauscht, um die
-- Prüfung beider Reihenfolgen abzudecken
local world = { [1454] = { 1, -4650, 1310 }, [1420] = { 0, 290, 2060 } }
local here = { map = 1454, x = 0.45, y = 0.60 }
C_Map = {
  GetBestMapForUnit = function() return here.map end,
  GetMapInfo = function(mapID) return { name = mapNames[mapID] } end,
  GetPlayerMapPosition = function(mapID)
    if mapID ~= here.map then return nil end
    return { GetXY = function() return here.x, here.y end }
  end,
  GetWorldPosFromMapPos = function(mapID)
    local entry = world[mapID]
    return entry[1], { GetXY = function() return entry[2], entry[3] end }
  end,
}
CreateVector2D = function(x, y) return { x = x, y = y } end

wow.login({ level = 20 })
addon.Set("transportTimers", true)
local Transports, Paths, Display = addon.Transports, addon.TransportPaths, addon.TransportDisplay

local function tick() wow.update(1) end
local function placeAt(map, x, y) here.map, here.x, here.y = map, x, y end

-- Eine Fahrt Orgrimmar -> Tirisfal: legt beide Anleger und die Gegenrichtung an
wow.state.moving = false
placeAt(1454, 0.45, 0.60)
tick()
wow.advance(5)
placeAt(1454, 0.46, 0.60)
tick()
wow.advance(50)
wow.fire("PLAYER_LEAVING_WORLD")
placeAt(1420, 0.60, 0.50)
tick()
local data = Transports.Data()
local route, reverse = data.routes["Orgrimmar>Tirisfal Glades"], data.routes["Tirisfal Glades>Orgrimmar"]
expectTrue("Strecke gelernt", route ~= nil and route.syncAt ~= nil)
expectTrue("Gegenrichtung angelegt", reverse ~= nil and #reverse.samples == 0)

local match = Paths.Match(route)
expectTrue("Rundkurs zugeordnet", match ~= nil and match.id == 302 and match.from == 1 and match.to == 2)
expect("ohne Periode kein Tempo", Paths.Speed(), nil)
expect("ohne Tempo keine Gegenrichtung", Transports.SecondsToDeparture(reverse), nil)

-- Periode bekannt (z.B. geteilt): Tempo = 5689 Yards / (300 - 120) s
route.period = 300
expectNear("Tempo", Paths.Speed(), 5689 / 180, 0.001)
expectNear("Periode der Gegenrichtung", Paths.Period(reverse), 300, 0.001)
expectNear("Fahrzeit aus den Daten", Paths.Travel(route), 3300 / (5689 / 180), 0.001)
local expectedReverse = route.syncAt + Paths.Travel(route) + 60
local now = Transports.Now()
local cycles = math.max(0, math.ceil((now - expectedReverse) / 300))
expectNear("Abfahrt der Gegenrichtung", Transports.SecondsToDeparture(reverse), expectedReverse + cycles * 300 - now, 0.01)

-- Bekannter Zeppelinmeister am Anleger: ohne /lt transport master zugeordnet, Text "Ziel: Abfahrt"
local plate = CreateFrame("Frame")
C_NamePlate = { GetNamePlateForUnit = function() return plate end }
wow.state.units.nameplate1 = { name = "Zapetta", guid = "Creature-0-4379-0-1-9566-00001A2B3C" }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("Meister erkannt", data.docks["Tirisfal Glades"].npcIds[1], 9566)
local plateText = Display.PlateText("nameplate1")
expectTrue("Plakette: Ziel und Abfahrt", plateText ~= nil
  and plateText:find(string.format(L.TRANSPORT_DEPARTS, "Orgrimmar", ""), 1, true) ~= nil)

-- Weltkarte: Beschriftung am Anleger der gezeigten Karte
local entries = addon.TransportWorldMap.Entries(1420)
expectTrue("Weltkarte: Anleger beschriftet", #entries == 1 and entries[1].x == data.docks["Tirisfal Glades"].x)
addon.Set("transportWorldMap", false)
expect("Weltkarte aus", #addon.TransportWorldMap.Entries(1420), 0)
expect("keine Fehler", #wow.errors, 0)
