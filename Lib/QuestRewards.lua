-- Belohnungen zur Auswahl einer Quest bewerten: höchster Händlerpreis und größter Itemlevel-Gewinn gegenüber der
-- angelegten Ausrüstung. Ohne Stat-Gewichte (die bräuchten fremde Daten).
-- Quellen (Blizzard_UIPanels_Game/*/QuestInfo.lua, ItemDocumentation je Zweig):
--   Questfenster  GetQuestItemLink("choice", i), GetQuestItemInfo("choice", i) 5. Wert isUsable
--   Questlog      GetQuestLogItemLink("choice", i), GetQuestLogChoiceInfo(i) 5. Wert isUsable
--   Item          C_Item.GetItemInfoInstant 4. Wert equipLoc, C_Item.GetDetailedItemLevelInfo (alle Clients laut Doku;
--                 ältere Clients: globale Gegenstücke), Verkaufspreis über Lib/Items.lua
--   Angelegt      GetInventoryItemLink("player", Platz)
-- nil-Werte (Item noch nicht geladen, geheim) machen eine Bewertung unbekannt statt falsch.
local _, ns = ...

local QuestRewards = {}
ns.QuestRewards = QuestRewards

QuestRewards.CHOICE = "choice"
local EQUIP_LOC_INDEX = 4

-- Ausrüstungsplätze je equipLoc (INVSLOT_*-Nummern, in allen Clients gleich)
local SLOTS = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
  INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
  INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
  INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function itemInfoInstant(item)
  local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not fn then return nil end
  return fn(item)
end

function QuestRewards.ItemLevel(link)
  if type(link) ~= "string" then return nil end
  local fn = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
  local level = fn and readable((fn(link)))
  return type(level) == "number" and level or nil
end

function QuestRewards.SlotsOf(link)
  if type(link) ~= "string" then return nil end
  local equipLoc = readable((select(EQUIP_LOC_INDEX, itemInfoInstant(link))))
  return equipLoc and SLOTS[equipLoc]
end

-- Itemlevel des schwächsten Platzes, den der Gegenstand ersetzen würde (leerer Platz = 0); nil = unbekannt
local function equippedLevel(slots)
  local lowest
  for _, slot in ipairs(slots) do
    local link = readable(GetInventoryItemLink("player", slot))
    local level = link and QuestRewards.ItemLevel(link) or (not link and 0)
    if not level then return nil end
    if not lowest or level < lowest then lowest = level end
  end
  return lowest
end

-- Wahl index aus Questfenster oder Questlog: { link, usable }
function QuestRewards.Choice(index, fromLog)
  local link, usable
  if fromLog then
    link = GetQuestLogItemLink and GetQuestLogItemLink(QuestRewards.CHOICE, index)
    usable = GetQuestLogChoiceInfo and select(5, GetQuestLogChoiceInfo(index))
  else
    link = GetQuestItemLink(QuestRewards.CHOICE, index)
    usable = GetQuestItemInfo and select(5, GetQuestItemInfo(QuestRewards.CHOICE, index))
  end
  return { link = readable(link), usable = readable(usable) }
end

-- Höchster Händlerpreis unter den Wahlen 1..count; nil, solange ein Wert unbekannt ist
function QuestRewards.MostValuable(count, fromLog)
  local best, bestValue
  for index = 1, count do
    local link = QuestRewards.Choice(index, fromLog).link
    local value = link and ns.Items.GetSellPrice(link)
    if type(value) ~= "number" then return nil end
    if not bestValue or value > bestValue then best, bestValue = index, value end
  end
  return best, bestValue
end

-- Größter Itemlevel-Gewinn unter den benutzbaren Wahlen; nil ohne Verbesserung oder bei unbekannten Werten
function QuestRewards.BestUpgrade(count, fromLog)
  local best, bestGain
  for index = 1, count do
    local choice = QuestRewards.Choice(index, fromLog)
    local slots = choice.usable and QuestRewards.SlotsOf(choice.link)
    if slots then
      local level, current = QuestRewards.ItemLevel(choice.link), equippedLevel(slots)
      if level and current and level - current > 0 and (not bestGain or level - current > bestGain) then
        best, bestGain = index, level - current
      end
    end
  end
  return best, bestGain
end
