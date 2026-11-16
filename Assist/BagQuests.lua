-- Taschen-Hinweise, Regeln (nur mit ns.BagData, also Classic Era und Forever; Daten: Assist/InstanceData/bags.lua):
-- welche Quests mit Taschen-Belohnung kann der Charakter jetzt annehmen, welcher Gegner lässt eine Tasche fallen.
-- Annehmbar = Mindestlevel erreicht, Fraktion passt, nicht abgegeben und nicht im Log, alle "pre" und eine aus "preAny"
-- abgegeben (Abgegeben = QuestItemTooltip.IsQuestDone). Ergebnisse gelten bis zur nächsten Änderung an Questlog,
-- Abgaben oder Level (Revision). Nur Daten und Text, keine Anzeige (BagQuestMarks.lua).
-- Taschenname aus dem Client (C_Item.GetItemNameByID, solange nicht im Cache: englischer Name aus den Daten).
local _, ns = ...

local L = ns.L

local BagQuests = {}
ns.BagQuests = BagQuests

local FACTION_CODES = { Alliance = "A", Horde = "H" }
local GIVER_NPC = "npc"

local revision = 0
local takeCache = {}  -- [questID] = true/false für die aktuelle Revision
local questsByMap     -- [uiMapID] = { questID, ... } mit Geber-Ort auf dieser Karte; nil = noch nicht aufgebaut
local mapIDs          -- sortierte Liste der Karten mit Gebern

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

function BagQuests.IsAvailable()
  return ns.BagData ~= nil
end

function BagQuests.Revision()
  return revision
end

local function invalidate()
  revision = revision + 1
  takeCache = {}
end

local function allDone(questIDs)
  for _, questID in ipairs(questIDs or {}) do
    if not ns.QuestItemTooltip.IsQuestDone(questID) then return false end
  end
  return true
end

local function anyDone(questIDs)
  if not questIDs then return true end
  for _, questID in ipairs(questIDs) do
    if ns.QuestItemTooltip.IsQuestDone(questID) then return true end
  end
  return false
end

local function computeCanTake(questID)
  local quest = ns.BagData.quests[questID]
  if not quest then return false end
  local faction = FACTION_CODES[readable(UnitFactionGroup("player"))]
  if quest.faction and quest.faction ~= faction then return false end
  if (UnitLevel("player") or 0) < quest.minLevel then return false end
  if ns.QuestItemTooltip.IsQuestDone(questID) or ns.QuestLog.Find(questID) then return false end
  return allDone(quest.pre) and anyDone(quest.preAny)
end

function BagQuests.CanTake(questID)
  if not ns.BagData then return false end
  local cached = takeCache[questID]
  if cached == nil then
    cached = computeCanTake(questID)
    takeCache[questID] = cached
  end
  return cached
end

-- Tooltipzeile "Tasche: Name (N Plätze)" für Daten { item, slots, name }
function BagQuests.Line(bag)
  local name = C_Item and C_Item.GetItemNameByID and readable(C_Item.GetItemNameByID(bag.item))
  return string.format(L.BAG_HINT_LINE, name or bag.name, bag.slots)
end

-- Annehmbare Quests eines NPC-Gebers: Liste von Quest-Daten, nach Mindestlevel
function BagQuests.NpcOffers(npcID)
  local offers = {}
  if not ns.BagData then return offers end
  for questID, quest in pairs(ns.BagData.quests) do
    for _, giver in ipairs(quest.givers) do
      if giver.kind == GIVER_NPC and giver.id == npcID and BagQuests.CanTake(questID) then
        table.insert(offers, quest)
        break
      end
    end
  end
  table.sort(offers, function(a, b) return a.minLevel < b.minLevel end)
  return offers
end

-- Angebote der Einheit (nur NPCs); leer ohne Angebot
function BagQuests.UnitOffers(unit)
  local npcID = ns.BagData and ns.QuestBlocklist.NpcId(UnitGUID(unit))
  if not npcID then return {} end
  return BagQuests.NpcOffers(npcID)
end

-- Taschen-Daten des Gegners (lässt eine Tasche fallen), sonst nil
function BagQuests.UnitMobBag(unit)
  local npcID = ns.BagData and ns.QuestBlocklist.NpcId(UnitGUID(unit))
  return npcID and ns.BagData.mobs[npcID] or nil
end

local function buildQuestsByMap()
  questsByMap, mapIDs = {}, {}
  for questID, quest in pairs(ns.BagData.quests) do
    for _, giver in ipairs(quest.givers) do
      if not questsByMap[giver.uiMapID] then
        questsByMap[giver.uiMapID] = {}
        table.insert(mapIDs, giver.uiMapID)
      end
      table.insert(questsByMap[giver.uiMapID], questID)
    end
  end
  table.sort(mapIDs)
end

-- Zonenkarten mit Gebern (nicht verändern)
function BagQuests.GiverMapIDs()
  if not ns.BagData then return {} end
  if not mapIDs then buildQuestsByMap() end
  return mapIDs
end

-- Annehmbare Quests, deren Geber auf der Zonenkarte steht: { { x, y, offers = { Quest-Daten, ... } }, ... }
-- (Geber am selben Ort zusammengefasst)
function BagQuests.OffersOnMap(uiMapID)
  local points, byPlace = {}, {}
  if not ns.BagData then return points end
  if not mapIDs then buildQuestsByMap() end
  for _, questID in ipairs(questsByMap[uiMapID] or {}) do
    local quest = ns.BagData.quests[questID]
    if BagQuests.CanTake(questID) then
      for _, giver in ipairs(quest.givers) do
        if giver.uiMapID == uiMapID then
          local place = giver.x .. ":" .. giver.y
          if not byPlace[place] then
            byPlace[place] = { x = giver.x, y = giver.y, offers = {} }
            table.insert(points, byPlace[place])
          end
          table.insert(byPlace[place].offers, quest)
        end
      end
    end
  end
  return points
end

ns.RegisterEvent("QUEST_LOG_UPDATE", invalidate)
ns.RegisterEvent("QUEST_TURNED_IN", invalidate)
ns.OnLevelStarted(invalidate)
ns.OnLogin(invalidate)
