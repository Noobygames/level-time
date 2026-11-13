-- Beute je Quelle: NPCs (X.db.npcs) und Objekte wie Erze, Kräuter, Truhen (X.db.objects[objectID]).
-- LOOT_READY: je Platz GetLootSourceInfo(slot) -> guid1, menge1, guid2, menge2, ... (mehrere Quellen bei
-- Flächenplündern), Art GetLootSlotType (1 Gegenstand, 2 Geld, 3 Währung), Gegenstand über GetLootSlotLink, Geld aus
-- dem Text von GetLootSlotInfo (GOLD_AMOUNT/SILVER_AMOUNT/COPPER_AMOUNT). Felder je Quelle: looted (geplünderte
-- Leichen bzw. Objekte, jede GUID einmal), loot[itemID] = Stückzahl, money = Kupfer gesamt, moneyCount; Objekte
-- zusätzlich names (Tooltip-Name aus GetLootSlotInfo fehlt, daher nur Orte) und spots. Drop-Rate = loot / looted.
local _, X = ...

local Loot = {}
X.Loot = Loot

local SLOT_ITEM, SLOT_MONEY = 1, 2
local COIN_UNITS = { { "GOLD_AMOUNT", 10000 }, { "SILVER_AMOUNT", 100 }, { "COPPER_AMOUNT", 1 } }

local lootedGuids = {}  -- GUID -> Nummer des Beutefensters; eine Leiche zählt nur im ersten Fenster (Rest nicht doppelt)
local window = 0
Loot.lastItem = nil     -- { id, time } für Questfortschritt

local function copperFromText(text)
  text = X.Readable(text)
  if type(text) ~= "string" then return nil end
  local total = 0
  for _, unit in ipairs(COIN_UNITS) do
    local format = _G[unit[1]]
    local pattern = type(format) == "string" and format:gsub("%%d", "(%%d+)")
    local value = pattern and tonumber((text:match(pattern)))
    if value then total = total + value * unit[2] end
  end
  return total > 0 and total or nil
end

-- Quellen eines Platzes als { { guid, quantity }, ... }
local function sources(slot)
  local raw = { pcall(GetLootSourceInfo, slot) }
  local list = {}
  if not raw[1] then return list end
  for index = 2, #raw, 2 do
    local guid = X.Readable(raw[index])
    if guid then table.insert(list, { guid = guid, quantity = X.Readable(raw[index + 1]) or 1 }) end
  end
  return list
end

-- Datensatz einer Quell-GUID (NPC oder Objekt) oder nil
local function sourceRecord(guid)
  local kind, id = X.ParseGuid(guid)
  if not id then return nil end
  if kind == "GameObject" then return X.Record("objects", id), kind, id end
  if kind == "Creature" or kind == "Vehicle" then return X.Record("npcs", id), kind, id end
end

-- Datensatz der Quelle, wenn sie in diesem Fenster zum ersten Mal geplündert wird; sonst nil
local function countSource(guid)
  if lootedGuids[guid] then return lootedGuids[guid] == window and sourceRecord(guid) or nil end
  local record, kind, id = sourceRecord(guid)
  if not record then return nil end
  lootedGuids[guid] = window
  X.Increment(record, "looted")
  if kind == "GameObject" then X.AddSpot(record) end
  if kind ~= "GameObject" then X.Units.lastKill = { id = id, time = GetTime() } end
  return record
end

local function readSlot(slot, counted)
  local slotType = X.Readable(GetLootSlotType and GetLootSlotType(slot))
  local list = sources(slot)
  for _, source in ipairs(list) do
    local record = countSource(source.guid)
    if record and not counted[source.guid] then counted[source.guid] = record end
  end
  if slotType == SLOT_ITEM then
    local itemID = X.ItemIdFromLink(GetLootSlotLink(slot))
    if not itemID then return end
    X.Items.Remember(itemID)
    Loot.lastItem = { id = itemID, time = GetTime() }
    for _, source in ipairs(list) do
      local record = counted[source.guid]
      if record then
        record.loot = record.loot or {}
        X.Increment(record.loot, itemID, source.quantity)
      end
    end
  elseif slotType == SLOT_MONEY and #list == 1 then
    local _, text = GetLootSlotInfo(slot)
    local copper = copperFromText(text)
    local record = counted[list[1].guid]
    if copper and record then
      X.Increment(record, "money", copper)
      X.Increment(record, "moneyCount")
    end
  end
end

X.On("LOOT_READY", function()
  if not X.db or not GetLootSourceInfo then return end
  window = window + 1
  local counted = {}
  for slot = 1, X.Readable(GetNumLootItems()) or 0 do readSlot(slot, counted) end
end)

X.On("PLAYER_ENTERING_WORLD", function() lootedGuids = {} end)

-- Zuletzt geplünderter Gegenstand, wenn höchstens maxAge Sekunden her
function Loot.LastItem(maxAge)
  local item = Loot.lastItem
  if item and GetTime() - item.time <= maxAge then return item.id end
end
