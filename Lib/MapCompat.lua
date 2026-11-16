-- Verträglichkeit mit Kartenaddons (LT-39): OpenMap (Forever) und Leatrix Maps (Classic-Zweige).
-- OpenMap (Map/WorldMap.lua, API.lua, MIT): zeigt auf WorldMapFrame eine zusammengesetzte Weltkarte. Die Leinwand gehört
-- weiter der "Karte darunter" (WorldMapFrame:GetMapID(), folgt beim Zoomen der Ansicht und wechselt über SetMapID, also
-- über OnMapChanged); die Ansicht reicht über deren Rechteck hinaus. Die Kartenkunst liegt in hohen Rahmenebenen auf der
-- Leinwand (bis OpenMapAPI.ArtTopLevel()), eigene Punkte müssen darüber liegen. Umrechnung zwischen Zonen über
-- OpenMapAPI.WorldFromMap/MapFromWorld (dieselben Rechtecke wie OpenMaps Kunst). Dungeon-Eingänge zeichnet OpenMap selbst
-- (Einstellung OpenMapDB.worldmap.icons, Standard an).
-- Leatrix Maps (Leatrix_Maps.lua): skaliert und verschiebt WorldMapFrame (SetScale, Fenstermodus), mehr Zoomstufen,
-- eigene Punkte als MapCanvas-Pins. Unsere Punkte hängen an der Leinwand und erben Skalierung und Größe; doppelt wären
-- nur die Dungeon-Symbole ("Show points of interest" + "Show dungeons and raids": LeaMapsDB ShowPointsOfInterest und
-- ShowDungeonIcons = "On", greift erst nach /reload, daher genügt das Lesen der gespeicherten Werte).
-- Keines der beiden Addons verändert die echte Minimap (nur eigene Knöpfe bzw. Minimap-Kacheln als Kartenkunst).
-- Nur lesen: nichts an fremden Rahmen oder Einstellungen wird verändert.
local _, ns = ...

local MapCompat = {}
ns.MapCompat = MapCompat

local OPENMAP, LEATRIX = "OpenMap", "Leatrix_Maps"
local ON = "On"
local BASE_LEVEL_GAP = 10       -- eigene Ebene über der Leinwand (Blizzard-Karte)
local ART_LEVEL_GAP = 2         -- über OpenMaps Kartenkunst (wie OpenMap selbst Leatrix-Symbole anhebt)
local STITCHED_MARGIN = 1       -- OpenMap zeigt über das Rechteck der Karte darunter hinaus: eine Kartenbreite je Seite

local function loaded(name)
  local check = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  return check ~= nil and check(name) == true
end

local function openMapApi()
  local api = loaded(OPENMAP) and rawget(_G, "OpenMapAPI")
  return type(api) == "table" and api or nil
end

-- Zeigt die Weltkarte gerade OpenMaps zusammengesetzte Karte?
function MapCompat.Stitched()
  local api = openMapApi()
  return api ~= nil and type(api.IsStitched) == "function" and api.IsStitched() == true
end

-- Rahmenebene der Punktebene auf der Leinwand
function MapCompat.OverlayLevel(canvas)
  local base = (canvas:GetFrameLevel() or 1) + BASE_LEVEL_GAP
  local api = openMapApi()
  if not (MapCompat.Stitched() and type(api.ArtTopLevel) == "function") then return base end
  local top = api.ArtTopLevel()
  if type(top) ~= "number" then return base end
  return math.max(base, top + ART_LEVEL_GAP)
end

-- Wie weit über das Kartenrechteck (0..1) hinaus Punkte sichtbar sein können
function MapCompat.VisibleMargin()
  return MapCompat.Stitched() and STITCHED_MARGIN or 0
end

-- Punkt einer Zonenkarte auf der gezeigten Karte (nicht begrenzt) oder nil
function MapCompat.Translate(fromMapID, x, y, toMapID)
  if fromMapID == toMapID then return x, y end
  if MapCompat.Stitched() then
    local api = openMapApi()
    local u, v = api.WorldFromMap(fromMapID, x, y)
    if not u then return nil end
    return api.MapFromWorld(toMapID, u, v)
  end
  return ns.MapCoords.Translate(fromMapID, x, y, toMapID)
end

local function openMapShowsEntrances()
  if not MapCompat.Stitched() then return false end
  local db = rawget(_G, "OpenMapDB")
  local settings = type(db) == "table" and db.worldmap
  return not (type(settings) == "table" and settings.icons == false)
end

local function leatrixShowsDungeons()
  if not loaded(LEATRIX) then return false end
  local db = rawget(_G, "LeaMapsDB")
  return type(db) == "table" and db.ShowPointsOfInterest == ON and db.ShowDungeonIcons == ON
end

-- Zeichnet ein Kartenaddon gerade selbst Dungeon-Eingänge? (dann blenden wir unsere aus)
function MapCompat.ShowsDungeonEntrances()
  return openMapShowsEntrances() or leatrixShowsDungeons()
end
