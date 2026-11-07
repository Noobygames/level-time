-- Quest-Gegenstand im Tooltip (Roadmap 349, Einstellung questItemTooltip, aus): der Item-Tooltip nennt die offene
-- Quest, zu der ein Gegenstand gehört, mit Stand ("Für Quest: Wölfe jagen (3/8)"); gehört er nur zu erledigten
-- Quests, steht dort "Quest erledigt – verkaufbar".
-- Zuordnung: gelernte Daten (QuestMobs.ForItem / QuestsOfItem), sonst der Name im Text eines offenen Sammelziels
-- (QuestLog.Objectives, nicht bei Tötungszielen). Erledigt = C_QuestLog.IsQuestFlaggedCompleted (alle Clients laut
-- Doku, sonst globales IsQuestFlaggedCompleted) oder in dieser Session abgegeben (QUEST_TURNED_IN; das Flag kommt
-- verzögert).
-- Anschluss wie Tooltip.lua: TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item) mit dem Tooltip-
-- Datensystem, sonst GameTooltip:HookScript("OnTooltipSetItem"); Gegenstand über tooltip:GetItem().
local _, ns = ...
local L = ns.L
local QuestLog = ns.QuestLog

local QuestItemTooltip = {}
ns.QuestItemTooltip = QuestItemTooltip

local MIN_NAME_LENGTH = 4
local MONSTER_KIND = "monster"
local OPEN_COLOR = { 1, 0.82, 0 }
local DONE_COLOR = { 0.6, 0.6, 0.6 }

local turnedIn = {}       -- [questID] = true, in dieser Session abgegeben
local objectiveTexts      -- offene Sammelziele { name, title, objective }; nil = neu lesen

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function progressText(title, objective)
  if objective.have and objective.need then
    return string.format("%s (%d/%d)", title or L.UNKNOWN_NAME, objective.have, objective.need)
  end
  return title or L.UNKNOWN_NAME
end

local function readObjectives()
  objectiveTexts = {}
  for _, entry in ipairs(QuestLog.Entries()) do
    for _, objective in ipairs(QuestLog.Objectives(entry.questID)) do
      if objective.finished == false and objective.kind ~= MONSTER_KIND and #objective.name >= MIN_NAME_LENGTH then
        table.insert(objectiveTexts, { name = objective.name, title = entry.title, objective = objective })
      end
    end
  end
end

-- Offenes Ziel, in dessen Text der Gegenstandsname steht
local function objectiveFor(itemName)
  if type(itemName) ~= "string" then return nil end
  local name = QuestLog.NormalizeObjective(itemName)
  if #name < MIN_NAME_LENGTH then return nil end
  if not objectiveTexts then readObjectives() end
  for _, entry in ipairs(objectiveTexts) do
    if entry.name:find(name, 1, true) then return entry end
  end
end

function QuestItemTooltip.IsQuestDone(questID)
  if turnedIn[questID] then return true end
  local check = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
  return check ~= nil and readable(check(questID)) == true
end

-- Zeile und Farbe für einen Gegenstand; nil ohne Questbezug
function QuestItemTooltip.Line(itemID, itemName)
  local hits = ns.QuestMobs.ForItem(itemID)
  if hits then
    return string.format(L.QUEST_ITEM_FOR_QUEST, progressText(hits[1].title, hits[1].objective)), OPEN_COLOR
  end
  local open = objectiveFor(itemName)
  if open then return string.format(L.QUEST_ITEM_FOR_QUEST, progressText(open.title, open.objective)), OPEN_COLOR end
  local quests = ns.QuestMobs.QuestsOfItem(itemID)
  if #quests == 0 then return nil end
  for _, questID in ipairs(quests) do
    if QuestLog.Find(questID) or not QuestItemTooltip.IsQuestDone(questID) then return nil end
  end
  return L.QUEST_ITEM_DONE, DONE_COLOR
end

local function onItemTooltip(tooltip)
  if not (ns.db and ns.db.questItemTooltip) or type(tooltip) ~= "table" or type(tooltip.GetItem) ~= "function" then
    return
  end
  local name, link = tooltip:GetItem()
  name, link = readable(name), readable(link)
  local itemID = type(link) == "string" and tonumber((link:match("item:(%d+)")))
  if not itemID then return end
  local text, color = QuestItemTooltip.Line(itemID, name)
  if text then tooltip:AddLine(text, unpack(color)) end
end

local hooked = false
local function hook()
  if hooked or not GameTooltip then return end
  hooked = true
  local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and itemType then
    TooltipDataProcessor.AddTooltipPostCall(itemType, onItemTooltip)
  else
    GameTooltip:HookScript("OnTooltipSetItem", function(self)
      onItemTooltip(self)
      self:Show()  -- Größe nach der neuen Zeile anpassen
    end)
  end
end

ns.RegisterEvent("QUEST_LOG_UPDATE", function() objectiveTexts = nil end)
ns.RegisterEvent("QUEST_TURNED_IN", function(questID)
  questID = readable(questID)
  if type(questID) == "number" then turnedIn[questID] = true end
end)
ns.RegisterApply(function(db)
  if db.questItemTooltip then hook() end
end)
