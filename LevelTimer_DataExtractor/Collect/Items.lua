-- Gegenstände (X.db.items[itemID]): Name je Sprache, Qualität, Gegenstandsstufe, Mindestlevel, Typ, Platz,
-- Verkaufspreis, Stapelgröße, Klasse/Unterklasse, Bindung. Andere Sammler melden IDs mit Items.Remember; kennt der
-- Client den Gegenstand noch nicht, kommt er mit GET_ITEM_INFO_RECEIVED nach.
-- C_Item.GetItemInfo (sonst globales GetItemInfo): name, link, quality, itemLevel, minLevel, type, subType,
-- stackCount, equipLoc, texture, sellPrice, classID, subclassID, bindType (warcraft.wiki.gg, alle Zweige).
local _, X = ...

local Items = {}
X.Items = Items

local pending = {}

local function itemInfo(itemID)
  local getInfo = X.Api("C_Item.GetItemInfo") or X.Api("GetItemInfo")
  if not getInfo then return nil end
  local ok, name, _, quality, itemLevel, minLevel, kind, subKind, stack, equipLoc, _, sellPrice, classID, subclassID,
    bindType = pcall(getInfo, itemID)
  if not ok or not X.Readable(name) then return nil end
  return { name = name, quality = quality, itemLevel = itemLevel, minLevel = minLevel, type = kind, subType = subKind,
    stack = stack, equipLoc = equipLoc ~= "" and equipLoc or nil, sellPrice = sellPrice, classID = classID,
    subclassID = subclassID, bindType = bindType }
end

local function store(itemID)
  local info = itemInfo(itemID)
  if not info then return false end
  local record = X.Record("items", itemID)
  X.SetName(record, info.name)
  for key, value in pairs(info) do
    if key ~= "name" and X.Readable(value) ~= nil then record[key] = value end
  end
  return true
end

-- Gegenstand merken (einmal je Sitzung und Sprache ausgelesen)
local done = {}
function Items.Remember(itemID)
  if type(itemID) ~= "number" or done[itemID] or not X.db then return end
  if store(itemID) then
    done[itemID] = true
  else
    pending[itemID] = true
  end
end

X.On("GET_ITEM_INFO_RECEIVED", function(itemID, success)
  if not pending[itemID] then return end
  pending[itemID] = nil
  if success ~= false and store(itemID) then done[itemID] = true end
end)
