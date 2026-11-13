-- Schiffe und Zeppeline (Roadmap 440, Einstellung transportTimers, nicht in Retail): lernt aus eigenen Fahrten, wann
-- ein Transport an einem Anleger abfährt. Es gibt in keinem Client eine Abfahrtszeit-API, und die Annahme "feste
-- Schleifen, 3-5 Minuten, gleicher Takt seit dem Serverstart" ist UNGEPRÜFT. Darum steckt keine Zahl im Code, die
-- nicht beobachtet wurde; die Tabelle ROUTES nennt nur bekannte Strecken (Quelle: method.gg "All Travel Routes in WoW
-- Forever" und warcraft.wiki.gg "Travel guide to zeppelins and boats") und hat bewusst keine Periode, solange es keine
-- belastbare Quelle gibt (NauticusClassic-Daten waren nicht abrufbar). Perioden, Anleger und Phase werden gelernt.
--
-- Beobachtung einer Fahrt (Zustandsautomat im Ein-Sekunden-Takt, ns.Every):
--   1. Stehen: Der Spieler steht (IsPlayerMoving false, nicht im Flug, nicht tot, keine Instanz) auf der Karte: die
--      Stehposition gilt als möglicher Anleger.
--   2. Abfahrt: Steht er weiter still und die Kartenposition ändert sich dauerhaft (> DEPART_DISTANCE), fährt der
--      Transport los. Dieser Zeitpunkt (Serverzeit) ist ein Punkt im Takt der Strecke.
--   3. Ankunft: Zwischen Kontinenten zeigt PLAYER_LEAVING_WORLD das Ladebild, nach PLAYER_ENTERING_WORLD gibt die Karte
--      den Zielanleger. Auf demselben Kontinent (kein Ladebild) gilt: mind. SAME_MAP_MIN_RIDE Sekunden unterwegs,
--      Spieler läuft wieder und ist >= SAME_MAP_MIN_DISTANCE vom Abfahrtsort entfernt (ungeprüft in Forever).
-- Eine Fahrt wird nur gespeichert, wenn Start- und Zielanleger verschiedene Karten-Namen haben und sie höchstens
-- MAX_RIDE_SECONDS dauerte.
--
-- Speicher: LevelTimerStatsDB.transports[Flavor][Realm] = { docks = { [Name] = { mapID, x, y, npcIds = {...} } },
-- routes = { ["Von>Nach"] = { from, to, kind, syncAt, period, samples = { Abfahrten... }, travel, sharedAt } } }.
-- Namen sind die Kartennamen in der Clientsprache (geteilte Daten passen daher nur zwischen gleichen Sprachen).
-- Takt: period aus den Abfahrten (Abstände sind Vielfache der Periode, Median je Zyklus), Vorhersage
-- nächste Abfahrt = syncAt + k * period >= jetzt. Ohne Periode: "unbekannt".
-- Teilen: Addon-Nachrichten wie Speedrun/FriendRace.lua (eigenes Präfix, Warteschlange, GroupChat.Locked).
-- Spieldaten (Roadmap 459, Assist/TransportPaths.lua): Sobald eine Strecke des Realms eine Periode hat, liefern die
-- Rundkurse Periode und Fahrzeit jeder zugeordneten Strecke; eine beobachtete Abfahrt gibt auch der Gegenrichtung
-- ihre Phase (Abfahrt + Fahrzeit + Liegezeit am Ziel). Gelernte Werte gehen vor.
local _, ns = ...

local Transports = {
  PREFIX = ns.ADDON_ID .. "T",
  DOCK_RADIUS = 0.03,           -- Karten-Einheiten (0..1): ab hier gilt man als am Anleger
  DEPART_DISTANCE = 0.006,      -- so weit muss sich ein stehender Spieler bewegen, damit es eine Abfahrt ist
  DEPART_MAX_STEP = 0.05,       -- ein größerer Sprung in einer Sekunde ist keine Abfahrt (Teleport, Karte gewechselt)
  STAND_MIN_SECONDS = 3,        -- so lange muss die Stehposition ruhig sein, bevor eine Bewegung als Abfahrt zählt
  SAME_MAP_MIN_RIDE = 40,       -- Sekunden: früheste Ankunft auf derselben Karte
  SAME_MAP_MIN_DISTANCE = 0.03,
  MAX_RIDE_SECONDS = 900,
  MIN_PERIOD = 60,              -- Grenzen für eine glaubwürdige Periode (Sekunden)
  MAX_PERIOD = 1800,
  PERIOD_TOLERANCE = 0.03,      -- Abstände dürfen höchstens so weit von einem Vielfachen abweichen (mind. 3 s)
  MAX_SAMPLES = 8,
  SHARE_MAX_AGE = 2 * 86400,    -- geteilte Phasen älter als 2 Tage zählen nicht
  SHARE_MAX_FUTURE = 60,
  MAX_NAME = 40,
  MAX_QUEUE = 20,
  SEND_INTERVAL = 1,
}
ns.Transports = Transports

-- Bekannte Strecken (nur Namen und Art; period = nil heißt: nur lernen). Quellen siehe Dateikopf, alle Strecken
-- stehen für WoW Forever laut method.gg; "ungeprüft in Forever" gilt für alles, bis jemand sie dort fährt.
-- Kartennamen wie der Client sie liefert (englisch); in anderen Sprachen greift nur das Lernen.
Transports.ROUTES = {
  { from = "Orgrimmar", to = "Tirisfal Glades", kind = "zeppelin" },
  { from = "Tirisfal Glades", to = "Orgrimmar", kind = "zeppelin" },
  { from = "Orgrimmar", to = "Stranglethorn Vale", kind = "zeppelin" },
  { from = "Stranglethorn Vale", to = "Orgrimmar", kind = "zeppelin" },
  { from = "Tirisfal Glades", to = "Stranglethorn Vale", kind = "zeppelin" },
  { from = "Stranglethorn Vale", to = "Tirisfal Glades", kind = "zeppelin" },
  { from = "The Barrens", to = "Stranglethorn Vale", kind = "boat" },   -- Ratchet <> Booty Bay
  { from = "Stranglethorn Vale", to = "The Barrens", kind = "boat" },
  { from = "Darkshore", to = "Wetlands", kind = "boat" },               -- Auberdine <> Menethil
  { from = "Wetlands", to = "Darkshore", kind = "boat" },
  { from = "Wetlands", to = "Dustwallow Marsh", kind = "boat" },        -- Menethil <> Theramore
  { from = "Dustwallow Marsh", to = "Wetlands", kind = "boat" },
  { from = "Teldrassil", to = "Darkshore", kind = "boat" },             -- Rut'theran <> Auberdine
  { from = "Darkshore", to = "Teldrassil", kind = "boat" },
}

-- Bekannte Zeppelinmeister (NPC-IDs laut Wowhead Classic, Titel "Zeppelin Master"; Boote haben in Classic keinen
-- Meister): Durotar 9564 Frezza, 12136 Snurk Bucksquick; Tirisfal 3150 Hin Denburg, 9566 Zapetta; Schlingendorntal
-- 3149 Nez'raz, 12137 Squibby Overspeck. Sie werden dem nächsten gelernten Anleger zugeordnet, sobald man dort steht.
Transports.KNOWN_MASTERS = { [3149] = true, [3150] = true, [9564] = true, [9566] = true, [12136] = true,
  [12137] = true }

local KIND_UNKNOWN = "unknown"
-- Kartentyp Zone (Enum.UIMapType, Retail und Classic); Kontinent- und Weltkarten taugen nicht als Anleger
local MAP_TYPE_ZONE = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3

-- Ist die Karte zu grob für einen Anleger (Kontinent, Welt)? Ohne lesbaren Kartentyp: nein
local function isCoarseMap(info)
  local mapType = type(info) == "table" and info.mapType or nil
  if ns.IsSecret(mapType) or type(mapType) ~= "number" then return false end
  return mapType < MAP_TYPE_ZONE
end
local queue = {}

---------------------------------------------------------------------------
-- Speicher
---------------------------------------------------------------------------
local function realmKey()
  return (GetRealmName and GetRealmName() or ""):gsub("%s", "")
end

function Transports.Data()
  local all = LevelTimerStatsDB.transports
  if not all then all = {}; LevelTimerStatsDB.transports = all end
  local flavor = ns.Client.Flavor()
  all[flavor] = all[flavor] or {}
  local realm = all[flavor][realmKey()]
  if not realm then
    realm = { docks = {}, routes = {} }
    all[flavor][realmKey()] = realm
  end
  return realm
end

-- Anleger auf Kontinentkarten (vor dem Fix gespeichert) samt ihren Strecken entfernen
local function pruneCoarseDocks()
  if not (C_Map and C_Map.GetMapInfo) then return end
  local data = Transports.Data()
  for name, dock in pairs(data.docks) do
    if isCoarseMap(C_Map.GetMapInfo(dock.mapID)) then
      ns.Debug("transport", "dropped dock %s (continent map %s)", name, dock.mapID)
      data.docks[name] = nil
      for key, route in pairs(data.routes) do
        if route.from == name or route.to == name then data.routes[key] = nil end
      end
    end
  end
end

ns.OnLogin(function()
  if Transports.IsAvailable() then pruneCoarseDocks() end
end)

function Transports.IsAvailable()
  return not ns.Client.IsRetail()
end

function Transports.IsEnabled()
  return ns.db ~= nil and ns.db.transportTimers == true and Transports.IsAvailable()
end

-- Serverzeit (gleich für alle Spieler eines Realms), sonst die lokale Uhr
function Transports.Now()
  if GetServerTime then return GetServerTime() end
  return time()
end

function Transports.RouteKey(from, to)
  return from .. ">" .. to
end

local function routeDefaults(from, to)
  for _, route in ipairs(Transports.ROUTES) do
    if route.from == from and route.to == to then return route end
  end
  return nil
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
-- { mapID, x, y, name } oder nil (unlesbar, in Instanzen, ohne Karte, Kontinentkarte: kurz nach einem Ladebild
-- liefert GetBestMapForUnit noch den Kontinent, z.B. "Östliche Königreiche" statt "Tirisfal")
function Transports.PlayerPosition()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local mapID = C_Map.GetBestMapForUnit("player")
  if ns.IsSecret(mapID) or type(mapID) ~= "number" then return nil end
  local position = C_Map.GetPlayerMapPosition(mapID, "player")
  if not position or ns.IsSecret(position) then return nil end
  local x, y = position:GetXY()
  if ns.IsSecret(x) or ns.IsSecret(y) or type(x) ~= "number" or type(y) ~= "number" then return nil end
  local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
  if isCoarseMap(info) then return nil end
  local name = type(info) == "table" and not ns.IsSecret(info.name) and info.name or nil
  if not name and GetZoneText then name = GetZoneText() end
  if ns.IsSecret(name) or type(name) ~= "string" or name == "" then return nil end
  return { mapID = mapID, x = x, y = y, name = name }
end

local function distance(a, b)
  if a.mapID ~= b.mapID then return math.huge end
  return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

-- Anleger in Reichweite der Position (nächster) oder nil
function Transports.NearestDock(position)
  if not position then return nil end
  local best, bestDistance
  for name, dock in pairs(Transports.Data().docks) do
    local d = distance(position, dock)
    if d <= Transports.DOCK_RADIUS and (not bestDistance or d < bestDistance) then best, bestDistance = name, d end
  end
  return best, best and Transports.Data().docks[best]
end

local function rememberDock(position)
  local docks = Transports.Data().docks
  local dock = docks[position.name]
  if not dock or distance(position, dock) > Transports.DOCK_RADIUS then
    dock = { mapID = position.mapID, x = position.x, y = position.y, npcIds = dock and dock.npcIds or {} }
    docks[position.name] = dock
  end
  return dock
end

---------------------------------------------------------------------------
-- Takt lernen
---------------------------------------------------------------------------
-- Periode aus Abfahrtszeiten (aufsteigend): kleinster glaubwürdiger Abstand als Kandidat (oder die Vorgabe), alle
-- anderen Abstände müssen Vielfache davon sein; Ergebnis = Median von Abstand / Vielfachem. nil = nicht erkennbar.
function Transports.EstimatePeriod(samples, seed)
  if #samples < 2 then return nil end
  local gaps = {}
  for index = 2, #samples do table.insert(gaps, samples[index] - samples[index - 1]) end
  local base = seed
  if not base then
    for _, gap in ipairs(gaps) do
      if gap >= Transports.MIN_PERIOD and (not base or gap < base) then base = gap end
    end
  end
  if not base or base < Transports.MIN_PERIOD or base > Transports.MAX_PERIOD then return nil end
  local cycles = {}
  for _, gap in ipairs(gaps) do
    local count = math.floor(gap / base + 0.5)
    local tolerance = math.max(3, base * Transports.PERIOD_TOLERANCE)
    if count < 1 or math.abs(gap - count * base) > tolerance * math.max(1, count) then return nil end
    table.insert(cycles, gap / count)
  end
  table.sort(cycles)
  local middle = (#cycles + 1) / 2
  local period = (cycles[math.floor(middle)] + cycles[math.ceil(middle)]) / 2
  if period < Transports.MIN_PERIOD or period > Transports.MAX_PERIOD then return nil end
  return math.floor(period + 0.5)
end

-- Periode: gelernt, sonst aus ROUTES, sonst aus den Spieldaten
local function periodOf(route)
  local known = routeDefaults(route.from, route.to)
  return route.period or (known and known.period) or ns.TransportPaths.Period(route)
end

-- Phase (Serverzeit einer Abfahrt): eigene, sonst aus der Gegenrichtung über Fahrzeit und Liegezeit
local function phaseOf(route)
  if route.syncAt then return route.syncAt end
  local reverse = Transports.Data().routes[Transports.RouteKey(route.to, route.from)]
  if not (reverse and reverse.syncAt) then return nil end
  local travel, wait = ns.TransportPaths.Travel(reverse), ns.TransportPaths.WaitAtDestination(reverse)
  if not (travel and wait) then return nil end
  return reverse.syncAt + travel + wait
end

-- Fahrzeit: aus den Spieldaten (genau, auch über ein Ladebild), sonst die gemessene
local function travelOf(route)
  return ns.TransportPaths.Travel(route) or route.travel
end

local function newRoute(from, to)
  local known = routeDefaults(from, to)
  return { from = from, to = to, kind = known and known.kind or KIND_UNKNOWN, samples = {} }
end

-- Eine beobachtete Abfahrt (Serverzeit) einer Strecke verbuchen
function Transports.Record(fromPosition, toPosition, departedAt, arrivedAt)
  local fromName, toName = fromPosition.name, toPosition.name
  if fromName == toName then return nil end
  local data = Transports.Data()
  rememberDock(fromPosition)
  rememberDock(toPosition)
  local key = Transports.RouteKey(fromName, toName)
  local route = data.routes[key]
  if not route then
    route = newRoute(fromName, toName)
    data.routes[key] = route
  end
  -- Gegenrichtung anlegen, damit ihre Phase aus den Spieldaten angezeigt wird
  local reverseKey = Transports.RouteKey(toName, fromName)
  if not data.routes[reverseKey] then data.routes[reverseKey] = newRoute(toName, fromName) end
  -- Abfahrten, die kein Vielfaches ergeben, ersetzen die alte Liste (Neustart des Servers, Fahrplanwechsel)
  table.insert(route.samples, departedAt)
  table.sort(route.samples)
  while #route.samples > Transports.MAX_SAMPLES do table.remove(route.samples, 1) end
  local period = Transports.EstimatePeriod(route.samples, route.period or ns.TransportPaths.Period(route))
  if not period and #route.samples > 2 then
    route.samples = { route.samples[#route.samples] }
    route.period = nil
  elseif period then
    route.period = period
  end
  route.syncAt, route.sharedAt = departedAt, nil
  if arrivedAt and arrivedAt > departedAt then route.travel = arrivedAt - departedAt end
  ns.Debug("transport", "learned %s: departure %s, samples %s, period %s, travel %s", key, departedAt,
    #route.samples, route.period or "unknown", route.travel or "unknown")
  Transports.Share(route)
  return route
end

---------------------------------------------------------------------------
-- Vorhersage
---------------------------------------------------------------------------
-- Sekunden bis zur nächsten Abfahrt der Strecke; nil = unbekannt (keine Phase oder keine Periode)
function Transports.SecondsToDeparture(route, now)
  now = now or Transports.Now()
  local period, syncAt = periodOf(route), phaseOf(route)
  if not (syncAt and period) then return nil end
  local cycles = math.max(0, math.ceil((now - syncAt) / period))
  return syncAt + cycles * period - now
end

-- Sekunden bis zur Ankunft des nächsten Transports am Zielanleger (nur mit gelernter Fahrzeit)
function Transports.SecondsToArrival(route, now)
  now = now or Transports.Now()
  local period, syncAt, travel = periodOf(route), phaseOf(route), travelOf(route)
  if not (syncAt and period and travel) then return nil end
  local cycles = math.max(0, math.ceil((now - syncAt - travel) / period))
  return syncAt + travel + cycles * period - now
end

-- Zeilen für einen Anleger: { { route, kind = "departs"|"arrives"|"unknown", seconds } ... }
function Transports.LinesFor(dockName, now)
  local lines = {}
  for key, route in pairs(Transports.Data().routes) do
    if route.from == dockName then
      local seconds = Transports.SecondsToDeparture(route, now)
      -- Gegenrichtung ohne eigene Messung (bei Record angelegt) nur zeigen, wenn die Spieldaten eine Zeit liefern
      if seconds or #route.samples > 0 or route.syncAt then
        table.insert(lines, { key = key, route = route, kind = seconds and "departs" or "unknown", seconds = seconds })
      end
    elseif route.to == dockName then
      local seconds = Transports.SecondsToArrival(route, now)
      if seconds then table.insert(lines, { key = key, route = route, kind = "arrives", seconds = seconds }) end
    end
  end
  table.sort(lines, function(a, b) return a.key < b.key end)
  return lines
end

-- Anleger, an dem der Transportmeister mit dieser NPC-ID steht (oder nil)
function Transports.DockOfNpc(npcId)
  for name, dock in pairs(Transports.Data().docks) do
    for _, id in ipairs(dock.npcIds or {}) do
      if id == npcId then return name end
    end
  end
  return nil
end

-- Anleger eines Transportmeisters: gemerkt, sonst bei einem bekannten Meister der Anleger, an dem man steht
function Transports.DockOfMaster(npcId)
  local dockName = Transports.DockOfNpc(npcId)
  if dockName or not Transports.KNOWN_MASTERS[npcId] then return dockName end
  local name, dock = Transports.NearestDock(Transports.PlayerPosition())
  if not name then return nil end
  table.insert(dock.npcIds, npcId)
  ns.Debug("transport", "known master npc %s assigned to dock %s", npcId, name)
  return name
end

function Transports.HasMasters()
  for _, dock in pairs(Transports.Data().docks) do
    if #(dock.npcIds or {}) > 0 then return true end
  end
  return false
end

-- NPC-ID aus einer Kreatur-GUID ("Creature-0-realm-instance-zone-npcId-spawn", 6. Feld)
function Transports.NpcId(guid)
  if ns.IsSecret(guid) or type(guid) ~= "string" then return nil end
  local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
  if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
  return tonumber(id)
end

-- /lt transport master: das Ziel als Transportmeister des nächsten Anlegers merken
function Transports.MarkMaster(unit)
  local npcId = Transports.NpcId(UnitGUID(unit or "target"))
  if not npcId then return false, "no-npc" end
  local name, dock = Transports.NearestDock(Transports.PlayerPosition())
  if not name then return false, "no-dock" end
  for _, id in ipairs(dock.npcIds) do
    if id == npcId then return true, name end
  end
  table.insert(dock.npcIds, npcId)
  ns.Debug("transport", "master npc %s marked at dock %s", npcId, name)
  return true, name
end

---------------------------------------------------------------------------
-- Fahrt beobachten
---------------------------------------------------------------------------
local standing   -- Stehposition { mapID, x, y, name, since }
local ride       -- { from, departedAt, startedAt, leftAt, arrivalFrom }

function Transports.Ride() return ride end

local function cannotObserve()
  local taxi = UnitOnTaxi and UnitOnTaxi("player")
  local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
  local instance = IsInInstance and IsInInstance()
  if ns.IsSecret(taxi) or ns.IsSecret(dead) or ns.IsSecret(instance) then return true end
  return taxi == true or dead == true or instance == true
end

local function finishRide(position)
  local current = ride
  ride = nil
  if not current or position.name == current.from.name then return end
  local now = GetTime()
  if now - current.startedAt > Transports.MAX_RIDE_SECONDS then return end
  Transports.Record(current.from, position, current.departedAt, Transports.Now())
end

local function observeRide(position, moving)
  local elapsed = GetTime() - ride.startedAt
  if elapsed > Transports.MAX_RIDE_SECONDS then
    ns.Debug("transport", "ride from %s dropped: too long", ride.from.name)
    ride = nil
    return
  end
  if not position then return end
  if ride.leftAt then
    -- Ladebild gesehen: sobald die Karte lesbar ist, ist das der Zielanleger
    if position.mapID ~= ride.from.mapID then finishRide(position) return end
    ride = nil
    return
  end
  if elapsed >= Transports.SAME_MAP_MIN_RIDE and moving
    and distance(position, ride.from) >= Transports.SAME_MAP_MIN_DISTANCE then
    finishRide(position)
  end
end

local function observe()
  if not Transports.IsEnabled() then standing, ride = nil, nil return end
  if cannotObserve() then standing = nil return end
  local position = Transports.PlayerPosition()
  local moving = IsPlayerMoving and IsPlayerMoving() == true
  if ride then observeRide(position, moving) return end
  if not position then return end
  if moving then standing = nil return end
  if not standing or standing.mapID ~= position.mapID then
    standing = { mapID = position.mapID, x = position.x, y = position.y, name = position.name, since = GetTime() }
    return
  end
  local step = distance(position, standing)
  local settled = GetTime() - standing.since >= Transports.STAND_MIN_SECONDS
  -- Großer Sprung oder Bewegung vor der Ruhezeit (Transport legt noch an): neue Stehposition statt Abfahrt
  if step > Transports.DEPART_MAX_STEP or (step > Transports.DEPART_DISTANCE and not settled) then
    standing = { mapID = position.mapID, x = position.x, y = position.y, name = position.name, since = GetTime() }
  elseif step > Transports.DEPART_DISTANCE then
    ride = { from = standing, departedAt = Transports.Now() - 1, startedAt = GetTime() }
    ns.Debug("transport", "departure from %s at %.3f,%.3f (server time %s)", standing.name, standing.x, standing.y,
      ride.departedAt)
    standing = nil
  end
end

ns.Every(1, observe, Transports.IsEnabled)

ns.RegisterEvent("PLAYER_LEAVING_WORLD", function()
  if ride and not ride.leftAt then
    ride.leftAt = GetTime()
    ns.Debug("transport", "loading screen during ride from %s", ride.from.name)
  end
  standing = nil
end)

---------------------------------------------------------------------------
-- Teilen
---------------------------------------------------------------------------
local function chatInfo()
  return C_ChatInfo and C_ChatInfo.SendAddonMessage and C_ChatInfo or nil
end

local function clean(name)
  return type(name) == "string" and #name > 0 and #name <= Transports.MAX_NAME and not name:find("[:%c|]")
end

local function enqueue(message, chatType)
  if #queue >= Transports.MAX_QUEUE then table.remove(queue, 1) end
  table.insert(queue, { message = message, chatType = chatType })
end

-- Nachricht "P:<von>:<nach>:<Serverzeit>:<Periode oder 0>"
local function messageFor(route)
  if not (route.syncAt and clean(route.from) and clean(route.to)) then return nil end
  return string.format("P:%s:%s:%d:%d", route.from, route.to, route.syncAt, route.period or 0)
end

function Transports.QueueLength() return #queue end

function Transports.Share(route)
  if not (ns.db and ns.db.transportShare and Transports.IsEnabled()) then return false end
  local message = messageFor(route)
  if not message then return false end
  local party, guild = ns.GroupChat.PartyChannel(), ns.GroupChat.GuildChannel()
  if party then enqueue(message, party) end
  if guild then enqueue(message, guild) end
  return true
end

local function flush()
  local api = chatInfo()
  if not api or #queue == 0 or ns.GroupChat.Locked() then return end
  local entry = table.remove(queue, 1)
  ns.Debug("transport", "send %s to %s", entry.message, entry.chatType)
  api.SendAddonMessage(Transports.PREFIX, entry.message, entry.chatType)
end

-- Fremde Phase prüfen und übernehmen. Gibt true zurück, wenn die Strecke geändert wurde.
function Transports.Receive(body)
  local from, to, syncText, periodText = body:match("^([^:]+):([^:]+):(%d+):(%d+)$")
  if not (from and clean(from) and clean(to)) or from == to then return false end
  local syncAt, period = tonumber(syncText), tonumber(periodText)
  local now = Transports.Now()
  if syncAt > now + Transports.SHARE_MAX_FUTURE or syncAt < now - Transports.SHARE_MAX_AGE then return false end
  if period ~= 0 and (period < Transports.MIN_PERIOD or period > Transports.MAX_PERIOD) then return false end
  local data = Transports.Data()
  local key = Transports.RouteKey(from, to)
  local route = data.routes[key]
  if not route then
    route = newRoute(from, to)
    data.routes[key] = route
  end
  if route.syncAt and route.syncAt >= syncAt then return false end
  route.syncAt, route.sharedAt = syncAt, now
  -- Eine eigene Periode bleibt; eine fremde füllt nur die Lücke
  if not route.period and period ~= 0 then route.period = period end
  ns.Debug("transport", "shared phase for %s: %s, period %s", key, syncAt, route.period or "unknown")
  return true
end

ns.RegisterEvent("CHAT_MSG_ADDON", function(prefix, text, _, sender)
  if ns.IsSecret(prefix) or ns.IsSecret(text) or ns.IsSecret(sender) then return end
  if prefix ~= Transports.PREFIX or type(text) ~= "string" or type(sender) ~= "string" then return end
  if not (ns.db and ns.db.transportShare and Transports.IsEnabled()) or ns.GroupChat.IsOwnSender(sender) then return end
  local kind, body = text:match("^(%u):(.*)$")
  if kind == "P" then Transports.Receive(body) end
end)

ns.OnLogin(function()
  local api = chatInfo()
  if api and api.RegisterAddonMessagePrefix then api.RegisterAddonMessagePrefix(Transports.PREFIX) end
end)
ns.Every(Transports.SEND_INTERVAL, flush, function() return ns.db ~= nil and ns.db.transportShare == true end)

---------------------------------------------------------------------------
-- Einstellungen
---------------------------------------------------------------------------
ns.Database.RegisterDefaults({
  settings = {
    transportTimers = false,     -- Hauptschalter (nicht in Retail)
    transportMinimap = true,     -- Beschriftung an der Minimap, solange man an einem Anleger steht
    transportNameplate = true,   -- Text über dem Transportmeister (befreundete NPC-Namensplaketten nötig)
    transportTooltip = true,     -- Zeile im Tooltip des Transportmeisters
    transportShare = false,      -- Phasen mit Gruppe und Gilde teilen
  },
})
