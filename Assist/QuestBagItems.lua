-- Benutzbare Quest-Gegenstände aus den Taschen für den Quest-Item-Knopf (QuestItemButton.lua), für Quests ohne
-- Quest-Item laut GetQuestLogSpecialItemInfo (z.B. "Geätzte Phiole" am Mondbrunnen benutzen, Ziel "Gefüllte geätzte
-- Phiole: 0/1"). Ein Taschengegenstand kommt nur in Frage, wenn er einen Benutzen-Zauber hat
-- (C_Item.GetItemSpell(itemID) -> spellName, spellID, laut ItemDocumentation in live, classic_era,
-- classic_anniversary und forever; älterer Client: globales GetItemSpell) und zu einer offenen Quest gehört.
-- Hinweise, in dieser Reihenfolge (der erste Treffer gewinnt, je Quest höchstens ein Gegenstand):
--   handed     Der Gegenstand kam beim Annehmen der Quest in die Taschen (Questgeber gibt ihn mit). Taschenstand bei
--              QUEST_DETAIL (Questtext offen, vor der Annahme) bzw. bei QUEST_ACCEPTED, neue Gegenstände bis
--              HANDOVER_SECONDS danach (BAG_UPDATE_DELAYED) gehören zur Quest. Gemerkt je Charakter in
--              character.questStartItems[questID] = { [itemID] = true }, weg mit QUEST_TURNED_IN/QUEST_REMOVED oder
--              wenn die Quest beim vollständig lesbaren Questlog fehlt.
--   questInfo  C_Container.GetContainerItemQuestInfo(bag, slot) -> { isQuestItem, questID, isActive } (ItemQuestInfo,
--              alle vier Zweige). Blizzards ContainerFrame (live/forever) zeigt bei questID und nicht isActive das
--              Ausrufezeichen: questID ist die Quest, die der Gegenstand startet; mit isActive läuft sie, dann gehört
--              er zu ihr. isQuestItem allein ordnet keiner Quest zu (nur Debug-Ausgabe).
--   objective  Der Name steckt in einem offenen, unerfüllten Zieltext der Quest (QuestLog.NormalizeObjective auf
--              beiden Seiten: "geätzte phiole" in "gefüllte geätzte phiole").
--   learned    Gelernt beim Looten (QuestMobs.QuestsOfItem) für eine Quest im Log.
-- Ein Gegenstand, dessen Name genau ein Ziel einer offenen Quest ist, wird gesammelt und nicht benutzt: nie Kandidat.
-- Taschen werden nur bis zur nächsten Taschenänderung gelesen (BAG_UPDATE_DELAYED), der Abgleich mit dem Questlog
-- läuft nur, wenn QuestItemButton seine gespeicherten Kandidaten verwirft.
local _, ns = ...

local QuestBagItems = {}
ns.QuestBagItems = QuestBagItems

local HANDOVER_SECONDS = 5  -- so lange nach der Annahme gehören neue Gegenstände zur Quest
local DETAIL_MAX_SECONDS = 120  -- so lange gilt der Taschenstand von QUEST_DETAIL als "vor der Annahme"
local MIN_NAME_LENGTH = 3   -- kürzere Namen passen zu leicht in fremde Zieltexte
QuestBagItems.SOURCES = { "handed", "questInfo", "objective", "learned" }  -- Vorrang

local usable              -- { itemId, name, link, texture, questID, isQuestItem } je Gegenstand, bis zur Taschenänderung
local spellOf = {}        -- [itemID] = true/false: Benutzen-Zauber (ändert sich nicht)
local before              -- [itemID] = true: Taschen vor der Annahme (QUEST_DETAIL/QUEST_ACCEPTED)
local detailAt            -- GetTime() des Taschenstands von QUEST_DETAIL
local handover            -- { questID, untilTime } während HANDOVER_SECONDS nach der Annahme
local lastMatch = {}      -- [questID] = itemID der letzten Zuordnung (Debug nur bei Änderung)

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function startItems()
  ns.character.questStartItems = ns.character.questStartItems or {}
  return ns.character.questStartItems
end

local function hasUseSpell(itemId)
  local known = spellOf[itemId]
  if known ~= nil then return known end
  local getSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
  if not getSpell then return false end
  local name, spellId = getSpell(itemId)
  name, spellId = readable(name), readable(spellId)
  local result = name ~= nil or spellId ~= nil
  -- Ohne Ergebnis evtl. noch nicht geladen: nur Treffer merken
  if result then spellOf[itemId] = true end
  return result
end

local function questInfoOf(bag, slot)
  if not (C_Container and C_Container.GetContainerItemQuestInfo) then return nil, nil end
  local info = C_Container.GetContainerItemQuestInfo(bag, slot)
  if type(info) ~= "table" then return nil, nil end
  local questID = readable(info.questID)
  local active = readable(info.isActive) == true
  return active and type(questID) == "number" and questID or nil, readable(info.isQuestItem) == true
end

-- Benutzbare Gegenstände der Taschen (je itemID einmal), gespeichert bis BAG_UPDATE_DELAYED
local function usableItems()
  if usable then return usable end
  usable = {}
  local seen = {}
  ns.Bags.ForEachItem(function(bag, slot, info)
    local itemId = readable(info.itemID)
    if type(itemId) ~= "number" or seen[itemId] or not hasUseSpell(itemId) then return end
    seen[itemId] = true
    local name = readable(info.itemName) or ns.Items.GetName(itemId)
    local questID, isQuestItem = questInfoOf(bag, slot)
    usable[#usable + 1] = { itemId = itemId, name = QuestBagItems.NormalizeName(name), link = readable(info.hyperlink),
      texture = readable(info.iconFileID), questID = questID, isQuestItem = isQuestItem }
  end)
  return usable
end

function QuestBagItems.NormalizeName(name)
  if type(name) ~= "string" then return nil end
  return ns.QuestLog.NormalizeObjective(name)
end

-- Gegenstände in den Taschen: [itemID] = true
local function bagItemIds()
  local ids = {}
  ns.Bags.ForEachItem(function(_, _, info)
    local itemId = readable(info.itemID)
    if type(itemId) == "number" then ids[itemId] = true end
  end)
  return ids
end

-- Neu seit "before" dazugekommene Gegenstände der Quest zuordnen
local function learnHandover()
  if not (handover and before) then return end
  local items
  for itemId in pairs(bagItemIds()) do
    if not before[itemId] then
      items = items or startItems()[handover.questID] or {}
      if not items[itemId] then
        items[itemId] = true
        ns.Debug("questitem", "item %s handed over with quest %s", itemId, handover.questID)
      end
    end
  end
  if items then startItems()[handover.questID] = items end
end

local function learning()
  return ns.db and (ns.db.questItemButton or ns.db.questLeftovers) and ns.character ~= nil
end

ns.RegisterEvent("QUEST_DETAIL", function()
  if learning() then before, detailAt = bagItemIds(), GetTime() end
end)

ns.RegisterEvent("QUEST_ACCEPTED", function(...)
  if not learning() then return end
  local questID = readable((select(select("#", ...), ...)))  -- Era: questIndex, questID; Retail/Forever: questID
  if type(questID) ~= "number" then return end
  if not (detailAt and GetTime() - detailAt <= DETAIL_MAX_SECONDS) then before = bagItemIds() end
  detailAt = nil
  handover = { questID = questID, untilTime = GetTime() + HANDOVER_SECONDS }
  learnHandover()  -- Gegenstand evtl. schon vor dem Ereignis da
end)

ns.RegisterEvent("BAG_UPDATE_DELAYED", function()
  usable = nil
  if not handover then return end
  if GetTime() > handover.untilTime then
    handover, before = nil, nil
    return
  end
  learnHandover()
end)

local function forgetQuest(questID)
  questID = readable(questID)
  if type(questID) == "number" and ns.character and ns.character.questStartItems then
    ns.character.questStartItems[questID] = nil
  end
  if type(questID) == "number" then lastMatch[questID] = nil end
end
ns.RegisterEvent("QUEST_TURNED_IN", forgetQuest)
ns.RegisterEvent("QUEST_REMOVED", forgetQuest)

local function inObjective(name, objectives)
  if not name or #name < MIN_NAME_LENGTH then return false end
  for _, objective in ipairs(objectives) do
    if objective.finished ~= true and objective.name ~= name and objective.name:find(name, 1, true) then
      return true
    end
  end
  return false
end

local function learnedFor(item, questID)
  for _, learnedQuest in ipairs(ns.QuestMobs.QuestsOfItem(item.itemId)) do
    if learnedQuest == questID then return true end
  end
  return false
end

-- Hinweis, mit dem der Gegenstand zur Quest gehört; nil = gehört nicht dazu
local function sourceOf(item, questID, objectives, handed)
  if handed and handed[item.itemId] then return "handed" end
  if item.questID == questID then return "questInfo" end
  if inObjective(item.name, objectives) then return "objective" end
  if learnedFor(item, questID) then return "learned" end
  return nil
end

local RANK = {}
for rank, source in ipairs(QuestBagItems.SOURCES) do RANK[source] = rank end

-- Gemerkte Übergaben von Quests, die nicht mehr im Log stehen, vergessen (nur wenn das Log ganz lesbar ist;
-- Classic sieht Quests unter eingeklappten Überschriften nicht)
local function pruneStartItems(entries, inLog)
  local stored = ns.character and ns.character.questStartItems
  if not stored or ns.QuestLog.QuestCount() ~= #entries then return end
  for questID in pairs(stored) do
    if not inLog[questID] then stored[questID] = nil end
  end
end

-- Kandidaten aus den Taschen für die Quests in entries (QuestLog.Entries()), ohne die Quests in taken
-- ([questID] = true, haben schon ein Quest-Item): Liste { questID, index, header, link, itemId, texture, source }
function QuestBagItems.Find(entries, taken)
  local list = {}
  local inLog = {}
  for _, entry in ipairs(entries) do inLog[entry.questID] = true end
  pruneStartItems(entries, inLog)
  local items = usableItems()
  if #items == 0 then return list end
  -- Ziele aller offenen Quests; ein Name, der genau ein Ziel ist, wird gesammelt (nie Kandidat)
  local objectivesOf, objectiveNames = {}, {}
  for _, entry in ipairs(entries) do
    local objectives = ns.QuestLog.Objectives(entry.questID)
    objectivesOf[entry.questID] = objectives
    for _, objective in ipairs(objectives) do objectiveNames[objective.name] = true end
  end
  local stored = ns.character and ns.character.questStartItems or {}
  for _, entry in ipairs(entries) do
    if not taken[entry.questID] then
      local best, bestSource
      for _, item in ipairs(items) do
        if not (item.name and objectiveNames[item.name]) then
          local source = sourceOf(item, entry.questID, objectivesOf[entry.questID], stored[entry.questID])
          if source and (not best or RANK[source] < RANK[bestSource]) then best, bestSource = item, source end
        end
      end
      if best then
        list[#list + 1] = { questID = entry.questID, index = entry.index, header = entry.header, link = best.link,
          itemId = best.itemId, texture = best.texture, source = bestSource }
        if lastMatch[entry.questID] ~= best.itemId then
          lastMatch[entry.questID] = best.itemId
          ns.Debug("questitem", "bag item %s for quest %s via %s (quest item flag %s)", best.itemId, entry.questID,
            bestSource, best.isQuestItem)
        end
      end
    end
  end
  return list
end

-- Für die Debug-Prüfung: benutzbare Taschengegenstände mit den Rohdaten von GetContainerItemQuestInfo
function QuestBagItems.Inspect()
  local result = {}
  ns.Bags.ForEachItem(function(bag, slot, info)
    local itemId = readable(info.itemID)
    if type(itemId) ~= "number" or not hasUseSpell(itemId) then return end
    local getInfo = C_Container and C_Container.GetContainerItemQuestInfo
    local raw = getInfo and getInfo(bag, slot)
    result[#result + 1] = { itemId = itemId, name = readable(info.itemName), bag = bag, slot = slot,
      questInfo = type(raw) == "table" and { isQuestItem = raw.isQuestItem, questID = raw.questID,
        isActive = raw.isActive } or tostring(raw) }
  end)
  return result
end
