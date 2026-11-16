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

-- Gegenstand eines Taschenplatzes an den Mauszeiger nehmen (C_Container in neueren Clients, sonst global)
function Bags.Pickup(bag, slot)
  if C_Container and C_Container.PickupContainerItem then
    C_Container.PickupContainerItem(bag, slot)
  elseif PickupContainerItem then
    PickupContainerItem(bag, slot)
  end
end

-- Modifizierte Klicks auf Taschenplätze: fn(bag, slot, mouseButton). Über Blizzards
-- ContainerFrameItemButton_OnModifiedClick (Classic-Clients); fehlt die Funktion (Retail: Mixin), passiert nichts.
-- Einmal hooken, auch wenn die Funktion erst nach dem Laden dieser Datei existiert (zweiter Versuch beim Login).
local modifiedClickHandlers = {}
local clickHooked = false

local function hookModifiedClicks()
  if clickHooked or type(hooksecurefunc) ~= "function"
    or type(ContainerFrameItemButton_OnModifiedClick) ~= "function" then return end
  clickHooked = true
  hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(button, mouseButton)
    local bag = (button.GetBagID and button:GetBagID()) or (button.GetParent and button:GetParent():GetID())
    local slot = button.GetID and button:GetID()
    if not (bag and slot) then return end
    for _, handler in ipairs(modifiedClickHandlers) do ns.SafeCall(handler, bag, slot, mouseButton) end
  end)
end

function Bags.OnModifiedClick(fn)
  table.insert(modifiedClickHandlers, fn)
  hookModifiedClicks()
end

ns.OnLogin(hookModifiedClicks)
