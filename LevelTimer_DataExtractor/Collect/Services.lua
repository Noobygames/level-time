-- Dienste an NPCs und Objekten:
--   vendors[npcID][itemID] = { price, stack, available (-1 = unbegrenzt), extendedCost } (MERCHANT_SHOW)
--   trainers[npcID] = { class (Klasse des Spielers beim Besuch), services["Name|Rang"] = { name, rank, level, cost,
--     skill, skillRank } } (TRAINER_SHOW; nur was der Lehrerfilter gerade zeigt)
--   taxiNodes[nodeID] = { names, mapID (Flugkarte), x, y }, flights["von>nach"] = { count, seconds, min, max, cost }
--   (TAXIMAP_OPENED, Hook auf TakeTaxiNode, Ankunft = PLAYER_CONTROL_GAINED ohne UnitOnTaxi)
--   npcs/objects[id].roles[Rolle] = true: vendor, repair, trainer, flightMaster, banker, auctioneer, mailbox, gossip
-- Händler-Info: C_MerchantFrame.GetItemInfo(index) (Retail ab 11.0, Tabelle) bzw. GetMerchantItemInfo(index)
-- (name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost).
local _, X = ...

local Services = {}
X.Services = Services

local NODE_CURRENT = Enum and Enum.FlightPathState and Enum.FlightPathState.Current or 0
local MIN_FLIGHT_SECONDS = 5  -- kürzer = Flug kam nicht zustande (Kontrolle gleich zurück)

-- Datensatz des Gegenübers ("npc"): NPC oder Objekt (Briefkasten); nil sonst
local function counterpart()
  if not X.db then return nil end
  local kind, id = X.ParseGuid(UnitGUID("npc"))
  if kind == "GameObject" then return X.Record("objects", id), id end
  if (kind == "Creature" or kind == "Vehicle") and id then
    local record = X.Record("npcs", id)
    X.SetName(record, X.Readable(UnitName("npc")))
    return record, id
  end
end

local function addRole(record, role)
  record.roles = record.roles or {}
  record.roles[role] = true
end

for event, role in pairs({ BANKFRAME_OPENED = "banker", AUCTION_HOUSE_SHOW = "auctioneer", MAIL_SHOW = "mailbox",
  GOSSIP_SHOW = "gossip" }) do
  X.On(event, function()
    local record = counterpart()
    if record then
      addRole(record, role)
      X.AddSpot(record)
    end
  end)
end

---------------------------------------------------------------------------
-- Händler
---------------------------------------------------------------------------
local function merchantItem(index)
  if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
    local info = C_MerchantFrame.GetItemInfo(index)
    if type(info) ~= "table" then return nil end
    return { price = X.Readable(info.price), stack = X.Readable(info.stackCount),
      available = X.Readable(info.numAvailable), extendedCost = X.Readable(info.hasExtendedCost) or nil }
  end
  local _, _, price, stack, available, _, _, extendedCost = GetMerchantItemInfo(index)
  return { price = X.Readable(price), stack = X.Readable(stack), available = X.Readable(available),
    extendedCost = X.Readable(extendedCost) or nil }
end

X.On("MERCHANT_SHOW", function()
  local record, npcID = counterpart()
  if not record or not npcID then return end
  addRole(record, "vendor")
  if X.Call("CanMerchantRepair") then addRole(record, "repair") end
  X.AddSpot(record)
  local items = X.Record("vendors", npcID)
  for index = 1, X.Call("GetMerchantNumItems") or 0 do
    local itemID = X.ItemIdFromLink(GetMerchantItemLink(index))
    local info = itemID and merchantItem(index)
    if info then
      items[itemID] = info
      X.Items.Remember(itemID)
    end
  end
end)

---------------------------------------------------------------------------
-- Lehrer
---------------------------------------------------------------------------
X.On("TRAINER_SHOW", function()
  local record, npcID = counterpart()
  if not record or not npcID or not GetNumTrainerServices then return end
  addRole(record, "trainer")
  X.AddSpot(record)
  local trainer = X.Record("trainers", npcID)
  local _, class = UnitClass("player")
  trainer.class = class
  trainer.services = trainer.services or {}
  for index = 1, X.Readable(GetNumTrainerServices()) or 0 do
    local name, rank, category = GetTrainerServiceInfo(index)
    name, rank = X.Readable(name), X.Readable(rank)
    if name and category ~= "header" then
      local skill, skillRank
      if GetTrainerServiceSkillReq then skill, skillRank = GetTrainerServiceSkillReq(index) end
      trainer.services[name .. "|" .. (rank or "")] = { name = name, rank = rank,
        level = X.Readable(GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(index)),
        cost = X.Readable((GetTrainerServiceCost and GetTrainerServiceCost(index))), skill = X.Readable(skill),
        skillRank = X.Readable(skillRank), locale = GetLocale() }
    end
  end
end)

---------------------------------------------------------------------------
-- Flugmeister und Flugzeiten
---------------------------------------------------------------------------
local slotNodes = {}   -- Platz auf der offenen Flugkarte -> nodeID
local currentNode      -- nodeID des Flugmeisters
local flight           -- { from, to, cost, started }

X.On("TAXIMAP_OPENED", function()
  local record = counterpart()
  if record then
    addRole(record, "flightMaster")
    X.AddSpot(record)
  end
  local mapID = X.Call("GetTaxiMapID")
  local nodes = mapID and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and C_TaxiMap.GetAllTaxiNodes(mapID)
  slotNodes, currentNode = {}, nil
  for _, node in ipairs(type(nodes) == "table" and nodes or {}) do
    local nodeID = X.Readable(node.nodeID)
    if nodeID then
      local stored = X.Record("taxiNodes", nodeID)
      X.SetName(stored, node.name)
      local position = node.position
      if position and position.x then
        stored.mapID, stored.x, stored.y = mapID, X.Readable(position.x), X.Readable(position.y)
      end
      if node.slotIndex then slotNodes[node.slotIndex] = nodeID end
      if node.state == NODE_CURRENT then currentNode = nodeID end
    end
  end
end)

if type(TakeTaxiNode) == "function" then
  hooksecurefunc("TakeTaxiNode", function(slot)
    local to = slotNodes[slot]
    if not currentNode or not to then return end
    flight = { from = currentNode, to = to, cost = X.Call("TaxiNodeCost", slot), started = GetTime() }
  end)
end

X.On("PLAYER_CONTROL_GAINED", function()
  if not flight or not X.db or X.Readable(UnitOnTaxi("player")) then return end
  local seconds = GetTime() - flight.started
  if seconds < MIN_FLIGHT_SECONDS then flight = nil return end
  local record = X.Record("flights", flight.from .. ">" .. flight.to)
  X.Increment(record, "count")
  X.Increment(record, "seconds", seconds)
  record.min = math.min(record.min or seconds, seconds)
  record.max = math.max(record.max or seconds, seconds)
  record.cost = flight.cost or record.cost
  flight = nil
end)
