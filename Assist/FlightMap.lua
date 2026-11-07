-- Liest die offene Flugkarte, gleich in allen Clients (Blizzards TaxiFrame und FlightMap nutzen dieselben Funktionen;
-- geprüft in wow-ui-source live, classic_era, classic_anniversary, forever und Ketho GlobalAPI):
--   GetTaxiMapID()                  Karte (uiMapID) der Flugkarte; Schlüssel, weil Positionen je Karte normiert sind
--   TaxiNodeName/TaxiNodeGetType/TaxiNodePosition(slot)   Name, Typ (CURRENT, REACHABLE, ...), Position 0..1
--   C_TaxiMap.GetAllTaxiNodes(mapID) nodeID je slotIndex (sprachunabhängiger Schlüssel). In Forever laut Debug-Log
--                                   vorhanden; ob Era/TBC dort Knoten liefern, ist offen (Prüfung 364.flight.estimates).
--                                   Ohne nodeID ist der Schlüssel die gerundete Position "x,y".
--   GetNumRoutes(slot), TaxiGetNodeSlot(slot, hop, true/false)  Teilstrecken bis zum Ziel (wie Blizzards Linien)
-- Knoten: { slot, name, key, id, x, y, type }. Nur lesen, kein Eingriff in Blizzards Rahmen.
local _, ns = ...

local FlightMap = {}
ns.FlightMap = FlightMap

FlightMap.CURRENT = "CURRENT"
FlightMap.REACHABLE = "REACHABLE"
local UNKNOWN_MAP = "0"
local POSITION_KEY_FORMAT = "%.3f,%.3f"   -- Ersatzschlüssel ohne nodeID: auf 0,001 der Karte gerundet

local function readable(value)
  return value ~= nil and not ns.IsSecret(value)
end

function FlightMap.MapKey()
  local id = GetTaxiMapID and GetTaxiMapID()
  if readable(id) and id ~= 0 then return tostring(id) end
  return UNKNOWN_MAP
end

-- nodeID und Position je Slot aus C_TaxiMap (leer, wo der Client nichts liefert)
local function taxiNodeInfo(mapID)
  local bySlot = {}
  if not (C_TaxiMap and C_TaxiMap.GetAllTaxiNodes) or not tonumber(mapID) then return bySlot end
  local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, tonumber(mapID))
  if not ok or type(nodes) ~= "table" then return bySlot end
  for _, info in ipairs(nodes) do
    if type(info) == "table" and readable(info.slotIndex) then bySlot[info.slotIndex] = info end
  end
  return bySlot
end

local function positionOf(slot, info)
  if TaxiNodePosition then
    local x, y = TaxiNodePosition(slot)
    if readable(x) and readable(y) then return x, y end
  end
  local position = info and info.position
  if type(position) == "table" and position.GetXY then return position:GetXY() end
  return nil, nil
end

function FlightMap.NodeKey(id, x, y)
  if readable(id) then return tostring(id) end
  if x and y then return string.format(POSITION_KEY_FORMAT, x, y) end
  return nil
end

function FlightMap.RouteKey(fromKey, toKey)
  return fromKey .. ">" .. toKey
end

-- Momentaufnahme der offenen Karte: { map, nodes[slot], current (Slot) } oder nil ohne Karte
function FlightMap.Read()
  if not NumTaxiNodes then return nil end
  local count = NumTaxiNodes()
  if not readable(count) or count == 0 then return nil end
  local map = FlightMap.MapKey()
  local infos = taxiNodeInfo(map)
  local snapshot = { map = map, nodes = {} }
  for slot = 1, count do
    local name, nodeType = TaxiNodeName(slot), TaxiNodeGetType(slot)
    if readable(name) and readable(nodeType) then
      local info = infos[slot]
      local id = info and info.nodeID
      local x, y = positionOf(slot, info)
      snapshot.nodes[slot] = { slot = slot, name = name, type = nodeType, id = readable(id) and id or nil, x = x, y = y,
        key = FlightMap.NodeKey(id, x, y) }
      if nodeType == FlightMap.CURRENT then snapshot.current = slot end
    end
  end
  return snapshot
end

local function distance(a, b)
  if not (a and b and a.x and b.x) then return nil end
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

-- Teilstrecken vom aktuellen Knoten zum Ziel als Liste von Slot-Paaren (leer, wenn der Client keine liefert)
local function hopsTo(slot)
  local hops = {}
  if not (GetNumRoutes and TaxiGetNodeSlot) then return hops end
  local count = GetNumRoutes(slot)
  if not readable(count) then return hops end
  for hop = 1, count do
    local from, to = TaxiGetNodeSlot(slot, hop, true), TaxiGetNodeSlot(slot, hop, false)
    if not (readable(from) and readable(to)) then return {} end
    hops[#hops + 1] = { from, to }
  end
  return hops
end

-- Flugstrecke in Karteneinheiten: Summe der Teilstrecken, sonst Luftlinie; dazu die Zahl der Teilstrecken
function FlightMap.Distance(snapshot, fromSlot, toSlot)
  local nodes = snapshot.nodes
  if fromSlot == snapshot.current then
    local hops, total = hopsTo(toSlot), 0
    for _, hop in ipairs(hops) do
      local part = distance(nodes[hop[1]], nodes[hop[2]])
      if not part then total = nil break end
      total = total + part
    end
    if total and #hops > 0 then return total, #hops end
  end
  return distance(nodes[fromSlot], nodes[toSlot]), 1
end
