-- Questlog lesen, gleich in allen Clients (Blizzard_APIDocumentationGenerated je Client, warcraft.wiki.gg):
--   Retail/Forever  C_QuestLog.GetNumQuestLogEntries + C_QuestLog.GetInfo(i) (questID, title, isHeader, level,
--                   suggestedGroup)
--   Classic Era/TBC GetNumQuestLogEntries + GetQuestLogTitle(i): title, level, suggestedGroup, isHeader, ..., 8. questID
-- Unter eingeklappten Überschriften sieht Classic die Quests nicht. Geheime Werte werden zu nil.
local _, ns = ...

local QuestLog = {}
ns.QuestLog = QuestLog

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function useInfoApi()
  return C_QuestLog ~= nil and C_QuestLog.GetInfo ~= nil and C_QuestLog.GetNumQuestLogEntries ~= nil
end

function QuestLog.Count()
  if useInfoApi() then return readable((C_QuestLog.GetNumQuestLogEntries())) or 0 end
  return GetNumQuestLogEntries and readable((GetNumQuestLogEntries())) or 0
end

-- suggestedGroup: Zahl > 0; ältere Clients liefern evtl. einen Text ("Elite", "Gruppe")
local function isGroup(suggested)
  suggested = readable(suggested)
  if type(suggested) == "number" then return suggested > 0 end
  return type(suggested) == "string" and suggested ~= ""
end

-- Eintrag i als { index, questID, title, level, group }; nil für Überschriften und Unlesbares
function QuestLog.Entry(index)
  local questID, title, level, suggested, isHeader
  if useInfoApi() then
    local info = C_QuestLog.GetInfo(index)
    if type(info) ~= "table" then return nil end
    questID, title, level, suggested, isHeader = info.questID, info.title, info.level, info.suggestedGroup, info.isHeader
  elseif GetQuestLogTitle then
    local _
    title, level, suggested, isHeader, _, _, _, questID = GetQuestLogTitle(index)
  else
    return nil
  end
  if readable(isHeader) then return nil end
  return { index = index, questID = readable(questID), title = readable(title), level = readable(level),
    group = isGroup(suggested) }
end

-- Alle Quests im Log (ohne Überschriften) mit Quest-ID
function QuestLog.Entries()
  local entries = {}
  for index = 1, QuestLog.Count() do
    local entry = QuestLog.Entry(index)
    if entry and type(entry.questID) == "number" and entry.questID ~= 0 then table.insert(entries, entry) end
  end
  return entries
end

-- Eintrag zu einer Quest-ID oder nil
function QuestLog.Find(questID)
  questID = readable(questID)
  if type(questID) ~= "number" then return nil end
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID and useInfoApi() then
    local index = readable(C_QuestLog.GetLogIndexForQuestID(questID))
    return type(index) == "number" and QuestLog.Entry(index) or nil
  end
  for _, entry in ipairs(QuestLog.Entries()) do
    if entry.questID == questID then return entry end
  end
end
