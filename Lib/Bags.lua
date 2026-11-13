-- Taschen des Charakters: Rucksack und ausgerüstete Taschen (Retail zählt die Reagenzientasche mit).
-- APIs in allen Clients: C_Container.GetContainerNumSlots, GetContainerItemInfo (ContainerItemInfo:
-- itemID, quality, stackCount, hasNoValue, isLocked, ...), GetContainerNumFreeSlots -> frei, bagFamily.
local _, ns = ...

local Bags = {}
ns.Bags = Bags

local BACKPACK = 0
local DEFAULT_BAG_SLOTS = 4    -- ausgerüstete Taschen, falls der Client die Konstante nicht kennt
local GENERAL_BAG_FAMILY = 0   -- normale Tasche; Köcher, Munitions- und Berufstaschen haben eine andere

function Bags.LastBag()
  return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or DEFAULT_BAG_SLOTS
end

-- fn(bag, slot, info) für jeden belegten Platz
function Bags.ForEachItem(fn)
  for bag = BACKPACK, Bags.LastBag() do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info then fn(bag, slot, info) end
    end
  end
end

-- Freie Plätze in normalen Taschen
function Bags.GetFreeSlots()
  local free = 0
  for bag = BACKPACK, Bags.LastBag() do
    local slots, family = C_Container.GetContainerNumFreeSlots(bag)
    if family == GENERAL_BAG_FAMILY then free = free + (slots or 0) end
  end
  return free
end
