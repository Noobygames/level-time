-- Item-Informationen über C_Item.GetItemInfo (ältere Clients: globales GetItemInfo), mit itemID oder
-- Link. Rückgabewerte laut Doku (ItemDocumentation, alle Clients): 3 = itemQuality, 11 = sellPrice.
-- nil, solange der Client das Item noch nicht geladen hat.
local addonName, ns = ...

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

-- Chat-Link (2. Wert); nil, solange das Item nicht geladen ist
function Items.GetLink(item)
  return (select(2, itemInfo(item)))
end

function Items.GetQuality(item)
  return (select(QUALITY_INDEX, itemInfo(item)))
end

-- Verkaufspreis eines Stücks in Kupfer
function Items.GetSellPrice(item)
  return (select(SELL_PRICE_INDEX, itemInfo(item)))
end

-- Auktionspreis eines Stücks aus Auctionator (API v1, nur wenn das Addon geladen ist); die API wirft bei falschen
-- Argumenten einen Fehler, deshalb pcall. nil ohne Auctionator oder ohne bekannten Preis.
local function auctionPrice(link)
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not (api and api.GetAuctionPriceByItemLink) then return nil end
  local ok, price = pcall(api.GetAuctionPriceByItemLink, addonName, link)
  return ok and price or nil
end

-- Marktwert eines Stücks in Kupfer: Auctionator-Preis, sonst Händlerpreis; nil, solange das Item unbekannt ist
function Items.GetMarketValue(link)
  return auctionPrice(link) or Items.GetSellPrice(link)
end
