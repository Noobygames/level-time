-- Questreste in den Taschen (Roadmap 352, Einstellung questLeftovers, aus): Gegenstände, die zu einer abgegebenen oder
-- abgebrochenen Quest gehörten und von keiner offenen Quest mehr gebraucht werden, als Verkaufsvorschlag beim Händler
-- (Hinweis mit den Namen) und als Zusatz im Hinweis "Taschen fast voll" (GearWarnings.lua). Nur Vorschlag: Level Time
-- verkauft oder löscht nichts.
-- Zu einer Quest gehören: gelernte Gegenstände (QuestMobs.ItemsOf) und ihr Quest-Item (GetQuestLogSpecialItemInfo über
-- QuestItem.Candidates, gemerkt in character.questSpecialItems, damit es auch nach /reload bekannt ist).
-- Ereignisse: QUEST_TURNED_IN, QUEST_REMOVED (Abbruch; Retail/Forever auch bei Abgabe), MERCHANT_SHOW;
-- Taschen über Lib/Bags.lua. Reste stehen je Charakter in character.questLeftovers[itemID] = { questID, name }
-- und verschwinden, sobald sie nicht mehr in den Taschen sind.
local _, ns = ...
local L = ns.L

local QuestLeftovers = {}
ns.QuestLeftovers = QuestLeftovers

local MAX_NAMES = 5      -- so viele Namen nennt der Hinweis
local SCAN_SECONDS = 2

local dirty = true

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function leftovers()
  ns.character.questLeftovers = ns.character.questLeftovers or {}
  return ns.character.questLeftovers
end

local function specialItems()
  ns.character.questSpecialItems = ns.character.questSpecialItems or {}
  return ns.character.questSpecialItems
end

-- Quest-Items der Quests im Log merken
local function rememberSpecialItems()
  if not dirty then return end
  dirty = false
  local items = specialItems()
  for _, candidate in ipairs(ns.QuestItem.Candidates()) do items[candidate.questID] = candidate.itemId end
end

-- Gegenstände einer Quest: { [itemID] = Name oder true }
function QuestLeftovers.ItemsOf(questID)
  local items = ns.QuestMobs.ItemsOf(questID)
  local special = specialItems()[questID]
  if special and not items[special] then items[special] = true end
  return items
end

local function onQuestGone(questID)
  questID = readable(questID)
  if type(questID) ~= "number" or not ns.db.questLeftovers then return end
  local list = leftovers()
  for itemID, name in pairs(QuestLeftovers.ItemsOf(questID)) do
    if not ns.QuestMobs.ForItem(itemID) then
      list[itemID] = { questID = questID, name = type(name) == "string" and name or nil }
      ns.Debug("quests", "leftover %s from quest %s", itemID, questID)
    end
  end
  specialItems()[questID] = nil
end

-- Reste, die noch in den Taschen sind: Liste { itemID, name, count }; vergisst die übrigen
function QuestLeftovers.InBags()
  local list = leftovers()
  local counts = {}
  ns.Bags.ForEachItem(function(_, _, info)
    local itemID = readable(info.itemID)
    if itemID and list[itemID] then counts[itemID] = (counts[itemID] or 0) + (readable(info.stackCount) or 1) end
  end)
  local found = {}
  for itemID, entry in pairs(list) do
    if counts[itemID] then
      local name = entry.name or ns.Items.GetName(itemID) or tostring(itemID)
      table.insert(found, { itemID = itemID, name = name, count = counts[itemID] })
    else
      list[itemID] = nil
    end
  end
  table.sort(found, function(a, b) return a.name < b.name end)
  return found
end

-- "Wolfspelz (3), Altes Zahnrad"; nil ohne Reste
function QuestLeftovers.Text()
  local found = QuestLeftovers.InBags()
  if #found == 0 then return nil end
  local names = {}
  for index, entry in ipairs(found) do
    if index > MAX_NAMES then
      table.insert(names, "...")
      break
    end
    table.insert(names, entry.count > 1 and string.format("%s (%d)", entry.name, entry.count) or entry.name)
  end
  return table.concat(names, ", ")
end

-- Zusatz für "Taschen fast voll"; nil, wenn aus oder keine Reste
function QuestLeftovers.BagsHint()
  if not (ns.db and ns.db.questLeftovers) then return nil end
  local text = QuestLeftovers.Text()
  return text and string.format(L.QUEST_LEFTOVERS_SHORT, text) or nil
end

ns.RegisterEvent("QUEST_TURNED_IN", onQuestGone)
ns.RegisterEvent("QUEST_REMOVED", onQuestGone)
ns.RegisterEvent("QUEST_LOG_UPDATE", function() dirty = true end)
ns.RegisterEvent("MERCHANT_SHOW", function()
  if not ns.db.questLeftovers then return end
  local text = QuestLeftovers.Text()
  if text then
    ns.Alerts.Notify({ title = L.QUEST_LEFTOVERS_TITLE, text = string.format(L.QUEST_LEFTOVERS, text),
      icon = ns.Alerts.ICONS.bags }, ns.Alerts.REMINDER_COLOR)
  end
end)
ns.Every(SCAN_SECONDS, rememberSpecialItems, function(db) return db.questLeftovers end)
