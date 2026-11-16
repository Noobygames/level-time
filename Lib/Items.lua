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

-- Symbol (Datei-ID) auch ohne geladenes Item (C_Item.GetItemIconByID, ältere Clients: globales GetItemIcon); nil ohne
-- API oder für unbekannte Items
function Items.GetIcon(itemID)
  local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
  return getIcon and getIcon(itemID) or nil
end

-- Item-Link nur aus dem Symbol in Qualitätsfarbe: "item:<ID>" reicht GameTooltip:SetHyperlink, auch solange das Item
-- nicht geladen ist (der Tooltip lädt selbst nach). nil ohne Symbol.
function Items.IconLink(itemID, quality, size)
  local icon = Items.GetIcon(itemID)
  if not icon then return nil end
  local link = string.format("|Hitem:%d|h|T%s:%d|t|h", itemID, tostring(icon), size)
  local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  return color and color.hex and (color.hex .. link .. "|r") or link
end
