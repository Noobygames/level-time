-- Reagenzien für Gruppen-Buffs und Wiederbelebung (Roadmap 488, Einstellung warnReagents, Standard aus): Bestand je
-- Klasse, Warnung bei knappem Vorrat (Hinweisliste in GearWarnings.lua, wie die Munition) und ein Chathinweis beim
-- Händler, der ein knappes Reagenz verkauft. Nur Classic-Clients; Retail kennt diese Reagenzien nicht (die Zauber dort
-- brauchen keine, Reinkarnation hat dort sogar dieselbe ID 20608).
-- IDs aus der Classic-Datenbank (wowhead.com/classic, Zauber zeigen ihr Reagenz): Reinkarnation 20608 -> Ankh 17030;
-- Große Segen 25782/25894/25898/25895/25890/25899 -> Symbol der Könige 21177; Göttliches Eingreifen 19752 -> Symbol der
-- Göttlichkeit 17033; Gebet der Seelenstärke 21562 -> Heilige Kerze 17028, 21564, Gebet des Schattenschutzes 27683 und
-- Gebet der Willenskraft 27681 -> Hochheilige Kerze 17029; Arkane Brillanz 23028 -> Arkanes Pulver 17020; Gabe der
-- Wildnis 21849 -> Wilde Beeren 17021, 21850 -> Wilder Dornwurz 17026; Wiedergeburt 20484/20739/20742/20747/20748 ->
-- Ahorn-/Schlingendorn-/Eschen-/Hainbuchen-/Eisenholzsamen 17034..17038; Teleportieren: Sturmwind 3561,
-- Orgrimmar 3567 -> Rune der Teleportation 17031; Seelenstein herstellen (schwach) 693 -> Seelensplitter 6265.
-- WoW Forever: gleiche IDs angenommen, prüft
-- check 488.reagents (Name und Bestand je Item, bekannte Zauber).
-- APIs: IsPlayerSpell (bekannte Zauber, wie ClassBuffs.lua), C_Item.GetItemCount (alle Clients laut Doku),
-- GetMerchantNumItems/GetMerchantItemLink (Blizzards MerchantFrame aller Clients).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    warnReagents = false,
    reagentLow = 10,
  },
  ranges = {
    reagentLow = { 1, 100 },
  },
})
local L = ns.L

local Reagents = {}
ns.Reagents = Reagents

-- Je Klasse Bedarfe; je Bedarf Wahlen vom höchsten Rang abwärts: es zählt das erste Item, zu dem ein Zauber bekannt
-- ist (Priester ab 56 brauchen Hochheilige statt Heiliger Kerzen). scale = Anteil der Grenze reagentLow.
Reagents.MIN_LOW = 1  -- Grenzen des Reglers in den Einstellungen
Reagents.MAX_LOW = 100

-- Anteil der Grenze reagentLow je Reagenz: häufig verbrauchte 1, Kerzen/Beeren/Splitter die Hälfte,
-- seltene ein Fünftel
local OFTEN, HALF, RARE = 1, 0.5, 0.2

Reagents.CLASSES = {
  SHAMAN = {
    { { item = 17030, scale = RARE, spells = { 20608 } } },                                    -- Ankh
  },
  PALADIN = {
    { { item = 21177, scale = OFTEN, spells = { 25782, 25894, 25898, 25895, 25890, 25899 } } }, -- Symbol der Könige
    { { item = 17033, scale = RARE, spells = { 19752 } } },  -- Symbol der Göttlichkeit
  },
  PRIEST = {
    { { item = 17029, scale = HALF, spells = { 21564, 27683, 27681 } },                        -- Hochheilige Kerze
      { item = 17028, scale = HALF, spells = { 21562 } } },                                    -- Heilige Kerze
  },
  MAGE = {
    { { item = 17020, scale = OFTEN, spells = { 23028 } } },                                   -- Arkanes Pulver
    { { item = 17031, scale = RARE, spells = { 3561, 3567 } } },                              -- Rune der Teleportation
  },
  WARLOCK = {
    { { item = 6265, scale = HALF, spells = { 693 } } },                                      -- Seelensplitter
  },
  DRUID = {
    { { item = 17038, scale = RARE, spells = { 20748 } },  -- Samen für Wiedergeburt,
      { item = 17037, scale = RARE, spells = { 20747 } },                                      -- je Rang vom höchsten
      { item = 17036, scale = RARE, spells = { 20742 } },
      { item = 17035, scale = RARE, spells = { 20739 } },
      { item = 17034, scale = RARE, spells = { 20484 } } },
    { { item = 17026, scale = HALF, spells = { 21850 } },                                      -- Wilder Dornwurz
      { item = 17021, scale = HALF, spells = { 21849 } } },                                    -- Wilde Beeren
  },
}

local function className()
  return select(2, UnitClass("player"))
end

-- Einstellung nur, wo die eigene Klasse Reagenzien braucht
function Reagents.IsAvailable()
  return not ns.Client.IsRetail() and Reagents.CLASSES[className()] ~= nil
end

local function knowsAny(spells)
  for _, spell in ipairs(spells) do
    if IsPlayerSpell(spell) then return true end
  end
  return false
end

local function itemCount(item)
  local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
  local count = fn and fn(item)
  if ns.IsSecret(count) or type(count) ~= "number" then return nil end
  return count
end

-- Grenze eines Reagenz: reagentLow mal Anteil, gerundet, mindestens 1 (Ankh bei Standard 10: unter 2)
function Reagents.LowLimit(scale)
  return math.max(Reagents.MIN_LOW, math.floor(ns.db.reagentLow * scale + 0.5))
end

-- Reagenzien der bekannten Zauber: { { item, low, count } }; count nil = unbekannt
function Reagents.Tracked()
  local tracked = {}
  if not Reagents.IsAvailable() then return tracked end
  for _, need in ipairs(Reagents.CLASSES[className()]) do
    for _, option in ipairs(need) do
      if knowsAny(option.spells) then
        table.insert(tracked, { item = option.item, low = Reagents.LowLimit(option.scale),
          count = itemCount(option.item) })
        break
      end
    end
  end
  return tracked
end

-- Knappe Reagenzien (Bestand unter low)
function Reagents.Low()
  local low = {}
  for _, reagent in ipairs(Reagents.Tracked()) do
    if reagent.count and reagent.count < reagent.low then table.insert(low, reagent) end
  end
  return low
end

local function stockText(list)
  local parts = {}
  for _, reagent in ipairs(list) do
    table.insert(parts, string.format(L.REAGENT_STOCK, ns.Items.GetName(reagent.item) or L.UNKNOWN_NAME,
      reagent.count))
  end
  return table.concat(parts, ", ")
end

-- Zusatz hinter der Warnung, z.B. "Ankh: 1, Arkanes Pulver: 4"
function Reagents.LowText()
  return stockText(Reagents.Low())
end

local function merchantItemID(index)
  local link = GetMerchantItemLink(index)
  if ns.IsSecret(link) or type(link) ~= "string" then return nil end
  return tonumber((link:match("item:(%d+)")))
end

-- Knappe Reagenzien, die der offene Händler verkauft
function Reagents.SoldHere()
  local low = Reagents.Low()
  if #low == 0 or not GetMerchantNumItems then return {} end
  local sold = {}
  for index = 1, GetMerchantNumItems() or 0 do
    local itemID = merchantItemID(index)
    if itemID then sold[itemID] = true end
  end
  local result = {}
  for _, reagent in ipairs(low) do
    if sold[reagent.item] then table.insert(result, reagent) end
  end
  return result
end

ns.RegisterEvent("MERCHANT_SHOW", function()
  if not ns.db.warnReagents then return end
  local sold = Reagents.SoldHere()
  ns.Debug("warnings", "reagents sold here: %s", #sold)
  if #sold > 0 then ns.Print(string.format(L.REAGENTS_AT_MERCHANT, stockText(sold))) end
end)
