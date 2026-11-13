-- Questreste in den Taschen (Roadmap 352, Einstellung questLeftovers, aus): Gegenstände, die zu einer abgegebenen oder
-- abgebrochenen Quest gehörten und von keiner offenen Quest mehr gebraucht werden, als Verkaufsvorschlag beim Händler
-- (Hinweis mit den Namen) und als Zusatz im Hinweis "Taschen fast voll" (GearWarnings.lua). Nur Vorschlag: Level Time
-- verkauft oder löscht nichts.
-- Zu einer Quest gehören: gelernte Gegenstände (QuestMobs.ItemsOf) und ihr Quest-Item (GetQuestLogSpecialItemInfo über
-- QuestItem.Candidates, gemerkt in character.questSpecialItems, damit es auch nach /reload bekannt ist). Von den
-- Taschen-Kandidaten zählen nur sichere Zuordnungen (OWNED_SOURCES: beim Annehmen erhalten, Questinfo des Clients);
-- ein Namenstreffer im Zieltext macht einen Gegenstand nicht zum Questrest.
-- Ereignisse: QUEST_TURNED_IN, QUEST_REMOVED (Abbruch; Retail/Forever auch bei Abgabe), MERCHANT_SHOW;
-- Taschen über Lib/Bags.lua. Reste stehen je Charakter in character.questLeftovers[itemID] = { questID, name }
-- und verschwinden, sobald sie nicht mehr in den Taschen sind.
-- Eigene Müll-Markierung: Alt+Rechtsklick auf einen Taschenplatz (Bags.OnModifiedClick, nur Classic-Clients) merkt den
-- Gegenstand in character.junkMarks[itemID]; markierte zählen wie Questreste und verkauft der Schrottverkauf mit.
-- Löschen nur per Klick: Knopf am Händlerfenster, Bestätigung per Dialog; gelöscht werden nur Reste ohne Verkaufswert
-- (Bags.Pickup + DeleteCursorItem), alles andere bleibt Verkaufsvorschlag.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questLeftovers = false,
  },
})
local L = ns.L

local QuestLeftovers = {}
ns.QuestLeftovers = QuestLeftovers

local MAX_NAMES = 5      -- so viele Namen nennt der Hinweis
local DELETE_BUTTON_MIN_WIDTH, DELETE_BUTTON_HEIGHT = 120, 22
local SCAN_SECONDS = 2

local dirty = true
-- Quellen von QuestItem.Candidates, deren Gegenstand sicher zur Quest gehört
local OWNED_SOURCES = { special = true, handed = true, questInfo = true }

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function leftovers()
  ns.character.questLeftovers = ns.character.questLeftovers or {}
  return ns.character.questLeftovers
end

local function junkMarks()
  ns.character.junkMarks = ns.character.junkMarks or {}
  return ns.character.junkMarks
end

function QuestLeftovers.IsMarked(itemID)
  return ns.character ~= nil and junkMarks()[itemID] == true
end

-- Markierung eines Taschenplatzes umschalten; true = jetzt markiert, nil ohne lesbaren Gegenstand
function QuestLeftovers.ToggleMark(bag, slot)
  local info = C_Container.GetContainerItemInfo(bag, slot)
  local itemID = info and readable(info.itemID)
  if not itemID then return nil end
  local marks = junkMarks()
  marks[itemID] = not marks[itemID] or nil
  local name = ns.Items.GetName(itemID) or tostring(itemID)
  ns.Print(string.format(marks[itemID] and L.JUNK_MARKED or L.JUNK_UNMARKED, name))
  ns.Debug("quests", "junk mark %s: %s", itemID, marks[itemID])
  return marks[itemID] == true
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
  for _, candidate in ipairs(ns.QuestItem.Candidates()) do
    if OWNED_SOURCES[candidate.source] then items[candidate.questID] = candidate.itemId end
  end
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

-- Reste und markierte Gegenstände, die noch in den Taschen sind: Liste { itemID, name, count }; vergisst
-- Questreste, die nicht mehr da sind (Markierungen bleiben, der Gegenstand kann wiederkommen)
function QuestLeftovers.InBags()
  local list, marks = leftovers(), junkMarks()
  local counts = {}
  ns.Bags.ForEachItem(function(_, _, info)
    local itemID = readable(info.itemID)
    if itemID and (list[itemID] or marks[itemID]) then
      counts[itemID] = (counts[itemID] or 0) + (readable(info.stackCount) or 1)
    end
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
  for itemID in pairs(marks) do
    if counts[itemID] and not list[itemID] then
      table.insert(found, { itemID = itemID, name = ns.Items.GetName(itemID) or tostring(itemID), count = counts[itemID] })
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

-- Plätze mit Resten ohne Verkaufswert (die übrigen kann der Händler kaufen): Liste { bag, slot, itemID }
function QuestLeftovers.Deletable()
  local list, marks = leftovers(), junkMarks()
  local slots = {}
  ns.Bags.ForEachItem(function(bag, slot, info)
    local itemID = readable(info.itemID)
    if not itemID or not (list[itemID] or marks[itemID]) or info.isLocked then return end
    if info.hasNoValue or (ns.Items.GetSellPrice(itemID) or 0) == 0 then
      table.insert(slots, { bag = bag, slot = slot, itemID = itemID })
    end
  end)
  return slots
end

-- Nur nach Klick und Bestätigung (DeleteCursorItem braucht eine Spieleraktion)
function QuestLeftovers.DeleteAll()
  local slots = QuestLeftovers.Deletable()
  for _, entry in ipairs(slots) do
    ns.Bags.Pickup(entry.bag, entry.slot)
    DeleteCursorItem()
    ns.Debug("quests", "deleted leftover %s from %s/%s", entry.itemID, entry.bag, entry.slot)
  end
  return #slots
end

local showDeletePopup = ns.Widgets.ConfirmPopup("LEVELTIMER_DELETE_LEFTOVERS", "QUEST_LEFTOVERS_DELETE_CONFIRM",
  function() QuestLeftovers.DeleteAll() end)

function QuestLeftovers.ConfirmDelete()
  local slots = QuestLeftovers.Deletable()
  if #slots == 0 then return end
  local names, seen = {}, {}
  for _, entry in ipairs(slots) do
    if not seen[entry.itemID] then
      seen[entry.itemID] = true
      table.insert(names, ns.Items.GetName(entry.itemID) or tostring(entry.itemID))
    end
  end
  showDeletePopup(table.concat(names, ", "))
end

-- Knopf am Händlerfenster, nur wenn es etwas zu löschen gibt
local deleteButton
local function updateDeleteButton()
  if not MerchantFrame then return end
  local show = ns.db.questLeftovers and #QuestLeftovers.Deletable() > 0
  if show and not deleteButton then
    deleteButton = ns.Widgets.CreateButton(MerchantFrame, DELETE_BUTTON_MIN_WIDTH, DELETE_BUTTON_HEIGHT,
      QuestLeftovers.ConfirmDelete)
    ns.Widgets.SetButtonText(deleteButton, L.QUEST_LEFTOVERS_DELETE, DELETE_BUTTON_MIN_WIDTH)
    deleteButton:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMRIGHT", 0, -2)
    ns.Widgets.AttachTooltip(deleteButton, function() return L.QUEST_LEFTOVERS_DELETE end,
      function() return L.QUEST_LEFTOVERS_DELETE_TIP end)
  end
  if deleteButton then deleteButton:SetShown(show) end
end

ns.Bags.OnModifiedClick(function(bag, slot, mouseButton)
  if mouseButton ~= "RightButton" or not (IsAltKeyDown and IsAltKeyDown()) or not ns.db.questLeftovers then return end
  if SendMailFrame and SendMailFrame:IsShown() then return end  -- Alt-Klick hängt dort an die Post an (Mail.lua)
  QuestLeftovers.ToggleMark(bag, slot)
end)

ns.RegisterEvent("QUEST_TURNED_IN", onQuestGone)
ns.RegisterEvent("QUEST_REMOVED", onQuestGone)
ns.RegisterEvent("QUEST_LOG_UPDATE", function() dirty = true end)
ns.RegisterEvent("MERCHANT_SHOW", function()
  if not ns.db.questLeftovers then return end
  updateDeleteButton()
  local text = QuestLeftovers.Text()
  if text then
    ns.Alerts.Notify({ title = L.QUEST_LEFTOVERS_TITLE, text = string.format(L.QUEST_LEFTOVERS, text),
      icon = ns.Alerts.ICONS.bags }, ns.Alerts.REMINDER_COLOR)
  end
end)
ns.Every(SCAN_SECONDS, rememberSpecialItems, function(db) return db.questLeftovers end)
