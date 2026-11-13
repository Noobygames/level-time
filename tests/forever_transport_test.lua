-- Schiffe und Zeppeline (Roadmap 440, WoW Forever): Fahrten beobachten, Periode lernen, Vorhersage, Minimap-Text nur
-- am Anleger, Text über dem Transportmeister, Tooltip-Zeile, Teilen per Addon-Nachricht samt Ablehnung schlechter Daten.
local L = addon.L

-- Karten-API: Position und Name der Karte steuert der Test
local mapNames = { [1454] = "Orgrimmar", [1420] = "Tirisfal Glades", [1434] = "Stranglethorn Vale",
  [1415] = "Eastern Kingdoms" }
local mapTypes = { [1415] = 2 }  -- Enum.UIMapType.Continent; ohne Eintrag kein Kartentyp
local here = { map = 1454, x = 0.45, y = 0.60 }
C_Map = {
  GetBestMapForUnit = function() return here.map end,
  GetMapInfo = function(mapID) return { name = mapNames[mapID], mapType = mapTypes[mapID] } end,
  GetPlayerMapPosition = function(mapID)
    if mapID ~= here.map then return nil end
    return { GetXY = function() return here.x, here.y end }
  end,
}
local function placeAt(map, x, y) here.map, here.x, here.y = map, x, y end

-- Tooltip wie in Assist/Tooltip.lua: Post-Call des Tooltip-Datensystems
local postCalls = {}
Enum = Enum or {}
Enum.TooltipDataType = { Unit = 2 }
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
local tooltipUnit, tooltipLines = nil, {}
function GameTooltip:GetUnit() return tooltipUnit and "Name", tooltipUnit end
function GameTooltip:AddLine(text) table.insert(tooltipLines, text) end

wow.login({ level = 20 })
local Transports, Display = addon.Transports, addon.TransportDisplay
expect("Flavor", addon.Client.Flavor(), "forever")
expectTrue("verfügbar", Transports.IsAvailable())

local function tick() wow.update(1) end

-- Aus: nichts wird beobachtet oder angezeigt
placeAt(1454, 0.45, 0.60)
tick()
placeAt(1454, 0.46, 0.60)
tick()
expect("aus: keine Fahrt", Transports.Ride(), nil)
expect("aus: keine Strecken", next(Transports.Data().routes), nil)

addon.Set("transportTimers", true)
expect("Standard Minimap", addon.db.transportMinimap, true)

-- Eine Fahrt: stehen, Transport fährt los, Ladebild, nach dem Ladebild noch 10 s Anflug, dann liegt er am Ziel
local function ride(departureAt, from, to)
  wow.state.moving = false
  placeAt(from[1], from[2], from[3])
  tick()
  wow.advance(math.max(0, departureAt - Transports.Now()))
  placeAt(from[1], from[2] + 0.01, from[3])
  tick()
  expectTrue("Fahrt beginnt", Transports.Ride() ~= nil)
  wow.advance(50)
  wow.fire("PLAYER_LEAVING_WORLD")
  placeAt(to[1], to[2] - 0.05, to[3])
  tick()
  wow.advance(10)
  placeAt(to[1], to[2], to[3])
  tick()
  expectTrue("Anflug: Fahrt läuft noch", Transports.Ride() ~= nil)
  wow.advance(Transports.STAND_MIN_SECONDS)
  tick()
  expect("Fahrt beendet", Transports.Ride(), nil)
end

local ORG, TIRISFAL = { 1454, 0.45, 0.60 }, { 1420, 0.60, 0.50 }
local base = Transports.Now() + 10
ride(base, ORG, TIRISFAL)
local route = Transports.Data().routes["Orgrimmar>Tirisfal Glades"]
expectTrue("Strecke gelernt", route ~= nil)
expect("Abfahrt", route.syncAt, base - 1)
expect("Art unbekannt", route.kind, "zeppelin")  -- aus der Streckenliste
expect("noch keine Periode", route.period, nil)
expect("Ziel-Anleger", Transports.Data().docks["Tirisfal Glades"].mapID, 1420)
expect("Fahrzeit Anleger zu Anleger (nicht bis zum Ladebild)", route.rideTime, 61)
expect("Ziel-Anleger am Liegeplatz, nicht im Anflug", Transports.Data().docks["Tirisfal Glades"].x, 0.60)
expect("ohne Periode unbekannt", Transports.SecondsToDeparture(route), nil)

ride(base + 240, ORG, TIRISFAL)
expect("Periode aus zwei Abfahrten", route.period, 240)
ride(base + 720, ORG, TIRISFAL)  -- ein Vielfaches (3 Zyklen später)
expect("Periode bleibt", route.period, 240)

-- Vorhersage: nächste Abfahrt = syncAt + k * Periode
wow.advance(100)
local untilNext = Transports.SecondsToDeparture(route)
expect("nächste Abfahrt", (Transports.Now() + untilNext - route.syncAt) % 240, 0)
expectTrue("im Zyklus", untilNext >= 0 and untilNext <= 240)

-- Ein Abstand, der kein Vielfaches ist, ergibt keine Periode (Liste wird neu begonnen)
expect("Periode nicht erkennbar", Transports.EstimatePeriod({ 0, 240, 400 }, nil), nil)
expect("Median je Zyklus", Transports.EstimatePeriod({ 0, 241, 722 }, nil), 241)
expect("zu kurz", Transports.EstimatePeriod({ 0, 20 }, nil), nil)

-- Minimap-Text: nur am Anleger
placeAt(1454, 0.45, 0.60)
wow.state.moving = false
tick()
expectTrue("Minimap-Text sichtbar am Anleger", Display.Shown())
local function clock(seconds) return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) end
expect("Text: Abfahrt", Display.Text(),
  string.format(L.TRANSPORT_DEPARTS, "Orgrimmar > Tirisfal Glades", clock(math.floor(untilNext + 0.5))))

placeAt(1454, 0.90, 0.10)
tick()
expect("Minimap-Text weg abseits des Anlegers", Display.Shown(), false)

addon.Set("transportMinimap", false)
placeAt(1454, 0.45, 0.60)
tick()
expect("Minimap-Schalter aus", Display.Shown(), false)
addon.Set("transportMinimap", true)

-- Zielanleger: Ankunftszeit statt Abfahrt (Fahrzeit ist gelernt)
placeAt(1420, 0.60, 0.50)
tick()
expectTrue("am Ziel sichtbar", Display.Shown())
expect("Text: Ankunft", Display.Text(), string.format(L.TRANSPORT_ARRIVES, "Orgrimmar > Tirisfal Glades",
  clock(math.floor(Transports.SecondsToArrival(route) + 0.5))))

-- Transportmeister: Ziel merken, Plakette und Tooltip
placeAt(1454, 0.45, 0.60)
wow.state.units.target = { name = "Frezza", guid = "Creature-0-4379-1-1-3149-00001A2B3C" }
SlashCmdList.LEVELTIMER("transport master")
expect("Meister gemerkt", Transports.Data().docks["Orgrimmar"].npcIds[1], 3149)
SlashCmdList.LEVELTIMER("transport master")
expect("nicht doppelt", #Transports.Data().docks["Orgrimmar"].npcIds, 1)
wow.state.units.target = nil
SlashCmdList.LEVELTIMER("transport master")
expect("ohne Ziel kein neuer Eintrag", #Transports.Data().docks["Orgrimmar"].npcIds, 1)

local plate = CreateFrame("Frame")
C_NamePlate = { GetNamePlateForUnit = function(unit) return unit == "nameplate1" and plate or nil end }
wow.state.units.nameplate1 = { name = "Frezza", guid = "Creature-0-4379-1-1-3149-00001A2B3C" }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local plateText = Display.PlateText("nameplate1")
expectTrue("Plakette: Ziel und Abfahrt", plateText ~= nil and plateText:find("Tirisfal Glades: ", 1, true) == 1)
wow.fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
expect("Plakette weg", Display.PlateText("nameplate1"), nil)

-- anderer NPC bekommt nichts
wow.state.units.nameplate2 = { name = "Wache", guid = "Creature-0-4379-1-1-9999-00001A2B3D" }
C_NamePlate.GetNamePlateForUnit = function() return plate end
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
expect("fremder NPC ohne Text", Display.PlateText("nameplate2"), nil)
-- geheime GUID: kein Fehler, kein Text
wow.state.units.nameplate3 = { name = "Geheim", guid = wow.SECRET }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
expect("geheime GUID ohne Text", Display.PlateText("nameplate3"), nil)

addon.Set("transportNameplate", false)
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("Plakette aus", Display.PlateText("nameplate1"), nil)
addon.Set("transportNameplate", true)

wow.state.units.mouseover = { name = "Frezza", guid = "Creature-0-4379-1-1-3149-00001A2B3C" }
local function hover(unit)
  tooltipUnit, tooltipLines = unit, {}
  postCalls[Enum.TooltipDataType.Unit](GameTooltip)
  return tooltipLines
end
expectTrue("Tooltip-Zeile", #hover("mouseover") >= 1)
addon.Set("transportTooltip", false)
expect("Tooltip aus", #hover("mouseover"), 0)
addon.Set("transportTooltip", true)
wow.state.units.mouseover = { name = "Wache", guid = "Creature-0-4379-1-1-9999-00001A2B3D" }
expect("fremder NPC ohne Tooltip", #hover("mouseover"), 0)

-- Meister mit Titel (Forever: Schiffsmeister ohne bekannte NPC-ID) wird dem Anleger zugeordnet, an dem man steht
local titles = {}
C_TooltipInfo = { GetUnit = function(unit)
  local title = titles[unit]
  return { lines = { { leftText = "Name" }, { leftText = title or "Level 45" } } }
end }
expect("Titel gelesen", Transports.UnitTitle("mouseover"), "Level 45")
expectTrue("Meistertitel erkannt", Transports.IsMasterTitle("<Schiffsmeisterin>"))
expectTrue("kein Meistertitel", not Transports.IsMasterTitle("Level 45"))
wow.state.units.nameplate4 = { name = "Grizzlowe", guid = "Creature-0-4379-1-1-77001-00001A2B3E" }
titles.nameplate4 = "Schiffsmeister"
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate4")
expectTrue("Schiffsmeister per Titel gemerkt", Transports.DockOfNpc(77001) == "Orgrimmar")
expectTrue("Schiffsmeister: Plakette", Display.PlateText("nameplate4") ~= nil)
-- NPC ohne Meistertitel bleibt draußen
wow.state.units.nameplate5 = { name = "Wache", guid = "Creature-0-4379-1-1-77002-00001A2B3F" }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate5")
expect("ohne Titel nicht gemerkt", Transports.DockOfNpc(77002), nil)
-- Meister an einem Anleger ohne gelernte Zeiten: Hinweis im Tooltip
placeAt(1434, 0.10, 0.10)
wow.state.units.mouseover = { name = "Grizzlowe", guid = "Creature-0-4379-1-1-77003-00001A2B40" }
titles.mouseover = "Schiffsmeister"
local hint = hover("mouseover")
expect("Hinweis: einmal mitfahren", hint[1], L.TRANSPORT_MASTER_UNLEARNED)
titles.mouseover = nil
C_TooltipInfo = nil

-- Teilen: gültige Phase wird übernommen, schlechte Daten werden abgelehnt
local function receive(body, sender, prefix)
  local before = Transports.Data().routes
  wow.fire("CHAT_MSG_ADDON", prefix or Transports.PREFIX, body, "GUILD", sender or "Friend-Realm")
end
local function routeCount() local n = 0 for _ in pairs(Transports.Data().routes) do n = n + 1 end return n end
local now = Transports.Now()
local count = routeCount()

expect("Teilen ist Standard", addon.db.transportShare, true)
addon.Set("transportShare", false)
receive(string.format("P:Barrens:Stranglethorn Vale:%d:300", now - 30))
expect("ohne Teilen-Schalter nichts", routeCount(), count)
addon.Set("transportShare", true)
receive(string.format("P:Barrens:Stranglethorn Vale:%d:300", now - 30))
local shared = Transports.Data().routes["Barrens>Stranglethorn Vale"]
expectTrue("geteilte Strecke", shared ~= nil)
expect("geteilte Phase", shared.syncAt, now - 30)
expect("geteilte Periode", shared.period, 300)
expect("als geteilt markiert", shared.sharedAt ~= nil, true)
expectTrue("Vorhersage aus geteilter Phase", Transports.SecondsToDeparture(shared) ~= nil)

local after = routeCount()
receive(string.format("P:Ratchet:Booty:%d:5", now - 30))               -- Periode zu klein
receive(string.format("P:Ratchet:Booty:%d:99999", now - 30))           -- Periode zu groß
receive(string.format("P:Ratchet:Booty:%d:300", now + 5000))           -- Zukunft
receive(string.format("P:Ratchet:Booty:%d:300", now - 10 * 86400))     -- zu alt
receive("P:Ratchet:Booty:abc:300")                                     -- keine Zahl
receive("P:Rat:chet:Booty:1:300")                                      -- Doppelpunkt im Namen
receive("P:Ratchet:Ratchet:" .. now .. ":300")                         -- Start gleich Ziel
receive("P:" .. string.rep("x", 60) .. ":Booty:" .. now .. ":300")     -- Name zu lang
receive(string.format("P:Ratchet:Booty:%d:300", now), "Friend-Realm", "Fremd")  -- anderes Präfix
receive(string.format("P:Ratchet:Booty:%d:300", now), wow.SECRET)      -- geheimer Absender
receive(string.format("P:Ratchet:Booty:%d:300", now), "Testchar")      -- eigene Nachricht
expect("schlechte Daten abgelehnt", routeCount(), after)

receive(string.format("P:Barrens:Stranglethorn Vale:%d:300", now - 100))
expect("ältere Phase überschreibt nicht", shared.syncAt, now - 30)
receive(string.format("P:Barrens:Stranglethorn Vale:%d:301", now - 10))
expect("neuere Phase gilt", shared.syncAt, now - 10)
expect("Periode bleibt", shared.period, 300)

-- Senden: nach einer eigenen Fahrt geht die Phase an die Gilde
wow.state.inGuild = true

ride(base + 960, ORG, TIRISFAL)
wow.advance(2)
tick()
local sent
for _, entry in ipairs(wow.addonMessages) do
  if entry.prefix == Transports.PREFIX then sent = entry end
end
expectTrue("Phase gesendet", sent ~= nil and sent.message:find("^P:Orgrimmar:Tirisfal Glades:%d+:240$") ~= nil)

-- Abgleich: wächst die Gruppe, gehen alle frischen Phasen (auch geteilte) an die Gruppe; kleiner werden sendet nicht
local function drainQueue()
  for _ = 1, Transports.MAX_QUEUE + 1 do wow.update(Transports.SEND_INTERVAL) end
end
local function partyPhases()
  local found = {}
  for _, entry in ipairs(wow.addonMessages) do
    if entry.prefix == Transports.PREFIX and entry.chatType == "PARTY" then
      found[entry.message:match("^P:([^:]+:[^:]+):")] = true
    end
  end
  return found
end
drainQueue()
wow.addonMessages = {}
wow.state.inGroup, wow.state.groupSize = true, 2
wow.fire("GROUP_ROSTER_UPDATE")
drainQueue()
local synced = partyPhases()
expectTrue("Abgleich: eigene Phase an Gruppe", synced["Orgrimmar:Tirisfal Glades"] == true)
expectTrue("Abgleich: geteilte Phase weitergegeben", synced["Barrens:Stranglethorn Vale"] == true)
wow.addonMessages = {}
wow.fire("GROUP_ROSTER_UPDATE")
wow.state.groupSize = 1
wow.fire("GROUP_ROSTER_UPDATE")
drainQueue()
expect("gleiche oder kleinere Gruppe: kein Abgleich", next(partyPhases()), nil)
wow.state.inGroup, wow.state.groupSize = false, nil

-- Hauptschalter aus: alles weg
addon.Set("transportTimers", false)
placeAt(1454, 0.45, 0.60)
tick()
expect("Schalter aus: Minimap leer", Display.Shown(), false)
expect("keine Fehler", #wow.errors, 0)

-- Nach dem Ladebild liefert der Client erst die Kontinentkarte: warten, bis die Zone lesbar ist (Log 2026-11-09:
-- "Durotar>Östliche Königreiche")
local STV = { 1434, 0.30, 0.40 }
addon.Set("transportTimers", true)
wow.state.moving = false
placeAt(STV[1], STV[2], STV[3])
tick()
wow.advance(Transports.STAND_MIN_SECONDS)
placeAt(STV[1], STV[2] + 0.01, STV[3])
tick()
expectTrue("Fahrt ab Schlingendorntal", Transports.Ride() ~= nil)
wow.advance(50)
wow.fire("PLAYER_LEAVING_WORLD")
placeAt(1415, 0.50, 0.50)
tick()
expectTrue("Kontinentkarte: Fahrt läuft weiter", Transports.Ride() ~= nil)
placeAt(1420, 0.61, 0.51)
tick()
expectTrue("Zone lesbar, Ruhezeit läuft", Transports.Ride() ~= nil)
-- Spieler läuft sofort los: der letzte ruhige Punkt gilt als Ankunft
wow.advance(1)
wow.state.moving = true
tick()
wow.state.moving = false
expect("Losgelaufen: Fahrt beendet", Transports.Ride(), nil)
local stvRoute = Transports.Data().routes["Stranglethorn Vale>Tirisfal Glades"]
expectTrue("Ziel ist die Zone", stvRoute ~= nil)
expect("Fahrzeit bis zum ruhigen Punkt", stvRoute.rideTime, 51)
expect("kein Kontinent-Anleger", Transports.Data().docks["Eastern Kingdoms"], nil)

-- Transport legt noch an (Spieler steht, Position wandert): keine Abfahrt vor der Ruhezeit
placeAt(1420, 0.62, 0.51)
tick()
placeAt(1420, 0.63, 0.51)
tick()
placeAt(1420, 0.64, 0.51)
tick()
expect("Anlegen ist keine Abfahrt", Transports.Ride(), nil)

-- Alte Daten mit Kontinent-Anleger werden beim Login entfernt
Transports.Data().docks["Eastern Kingdoms"] = { mapID = 1415, x = 0.5, y = 0.5, npcIds = {} }
Transports.Data().routes["Orgrimmar>Eastern Kingdoms"] = { from = "Orgrimmar", to = "Eastern Kingdoms", samples = {} }
wow.fire("PLAYER_LOGIN")
expect("Kontinent-Anleger entfernt", Transports.Data().docks["Eastern Kingdoms"], nil)
expect("Strecke entfernt", Transports.Data().routes["Orgrimmar>Eastern Kingdoms"], nil)
expectTrue("andere Strecken bleiben", Transports.Data().routes["Orgrimmar>Tirisfal Glades"] ~= nil)
expect("keine Fehler am Ende", #wow.errors, 0)
