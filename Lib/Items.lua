-- Item-Informationen über C_Item.GetItemInfo (ältere Clients: globales GetItemInfo), mit itemID oder
-- Link. Rückgabewerte laut Doku (ItemDocumentation, alle Clients): 3 = itemQuality, 11 = sellPrice.
-- nil, solange der Client das Item noch nicht geladen hat.
local _, ns = ...

local Items = {}
ns.Items = Items

local QUALITY_INDEX = 3
local SELL_PRICE_INDEX = 11

-- Erst beim Aufruf nachschlagen: nicht jeder Client hat C_Item.GetItemInfo
local function itemInfo(item)
  local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not getItemInfo then return nil end
  return getItemInfo(item)
end

-- Name in der Sprache des Clients; nil, solange das Item nicht geladen ist
function Items.GetName(item)
  return (itemInfo(item))
end

function Items.GetQuality(item)
  return (select(QUALITY_INDEX, itemInfo(item)))
end

-- Verkaufspreis eines Stücks in Kupfer
function Items.GetSellPrice(item)
  return (select(SELL_PRICE_INDEX, itemInfo(item)))
end
