-- Zielart Quests (Roadmap 296): "N Quests abgeben" oder bestimmte Quests nach ID: eine Quest oder eine Kette in
-- Reihenfolge (Stand = wie viele von vorn abgegeben sind; eine spätere Quest der Kette zählt erst, wenn die davor
-- erledigt sind). Quelle: Quest-Journal von Level Time (QUEST_TURNED_IN, Journal.OnAdd "questLog").
-- Schon abgegebene Quests (C_QuestLog.IsQuestFlaggedCompleted, in allen vier Clients; ältere: IsQuestFlaggedCompleted)
-- zählen beim Anlegen als erledigt; ist alles erledigt, gibt es kein Ziel.
-- params: { mode = "count"|"ids", quests = { ID, ... }, names = { [ID] = Name }, done = { [ID] = true } }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Quests = {}
ns.QuestGoals = Quests

local MODES = { "count", "ids" }
local MODE_LABELS = { count = "SG_FORM_QUEST_COUNT", ids = "SG_FORM_QUEST_IDS" }
local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local MAX_QUESTS = 25  -- Quests einer Kette

-- Quest-IDs aus Links ("|Hquest:123:20|h[Name]|h") und Zahlen, in der Reihenfolge der Eingabe; Namen aus den Links
function Quests.Parse(text)
  local ids, names, seen = {}, {}, {}
  local rest = (text or ""):gsub("|c%x*|Hquest:(%d+)[^|]*|h%[(.-)%]|h|r", function(id, name)
    id = tonumber(id)
    if id and not seen[id] then
      seen[id] = true
      table.insert(ids, id)
      names[id] = name
    end
    return " "
  end)
  for word in rest:gmatch("%d+") do
    local id = tonumber(word)
    if id and not seen[id] then
      seen[id] = true
      table.insert(ids, id)
    end
  end
  return ids, names
end

local function isCompleted(questID)
  local check = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
  if not check then return false end
  local done = check(questID)
  return not LT.IsSecret(done) and done == true
end

local function questName(goal, questID)
  local name = goal.params.names[questID]
  if name then return name end
  local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
  if title and not LT.IsSecret(title) then return title end
  return string.format(L.SG_QUEST_UNKNOWN, questID)
end

-- Erledigt von vorn: so viele Quests der Kette sind ohne Lücke abgegeben
local function chainProgress(params)
  local count = 0
  for _, questID in ipairs(params.quests) do
    if not params.done[questID] then break end
    count = count + 1
  end
  return count
end

-- Nächste offene Quest der Kette (für die zweite Zeile der Karte)
local function nextQuest(params)
  for _, questID in ipairs(params.quests) do
    if not params.done[questID] then return questID end
  end
end

Goals.RegisterKind("quest", {
  label = "SG_KIND_QUEST",
  group = "quests",
  usage = "SG_USAGE_QUEST",
  color = LT.Theme.COLORS.neutral,
  icon = ICON,
  -- Modus zuerst; darunter nur das Feld des gewählten Modus (Anzahl bzw. Quests)
  form = { fields = {
    { type = "choice", param = "mode", label = "SG_FORM_QUEST_MODE", values = MODES, labels = MODE_LABELS },
    { type = "amount", label = "SG_FORM_AMOUNT", showIf = { mode = "count" } },
    { type = "text", param = "input", label = "SG_FORM_QUEST_INPUT", links = true, showIf = { mode = "ids" } },
  } },
  -- "add quest 10" = 10 Quests abgeben; "add quest <ID/Link> [<ID/Link> ...]" = diese Quests (Kette)
  parse = function(args, rest)
    if #args == 1 and tonumber(args[1]) and not rest:find("|H", 1, true) then
      return { mode = "count" }, tonumber(args[1])
    end
    return { mode = "ids", input = rest }, nil
  end,
  prepare = function(params, target)
    params.mode = params.mode or (params.input and "ids" or "count")
    if params.mode ~= "ids" then return target end
    params.quests, params.names = Quests.Parse(params.input)
    params.input = nil
    params.done = {}
    for _, questID in ipairs(params.quests) do
      if isCompleted(questID) then params.done[questID] = true end
    end
    return #params.quests
  end,
  validate = function(params, target)
    if params.mode == "count" then return Kinds.ValidAmount(target) end
    if params.mode ~= "ids" then return string.format(L.SG_ERR_UNKNOWN_KIND, tostring(params.mode)) end
    if #params.quests == 0 then return L.SG_ERR_QUEST end
    if #params.quests > MAX_QUESTS then return string.format(L.SG_ERR_QUEST_MANY, MAX_QUESTS) end
  end,
  current = function(goal)
    if goal.params.mode == "ids" then return chainProgress(goal.params) end
    return 0
  end,
  title = function(goal)
    local params = goal.params
    if params.mode == "count" then return Kinds.Counted("SG_GOAL_QUESTS", goal.target) end
    local first = questName(goal, params.quests[1])
    if #params.quests == 1 then return string.format(L.SG_GOAL_QUEST, first) end
    return string.format(L.SG_GOAL_QUEST_CHAIN, first, #params.quests)
  end,
  body = function(goal)
    local params = goal.params
    if params.mode ~= "ids" or #params.quests < 2 then return nil end
    local nextID = nextQuest(params)
    return nextID and string.format(L.SG_QUEST_NEXT, questName(goal, nextID)) or nil
  end,
  hasCount = function(goal) return goal.params.mode == "count" or #goal.params.quests > 1 end,
})

---------------------------------------------------------------------------
-- Erfassung: jede abgegebene Quest
---------------------------------------------------------------------------
LT.Journal.OnAdd(function(logName, entry)
  if logName ~= "questLog" or not ns.db then return end
  Goals.Add("quest", function(goal) return goal.params.mode == "count" end, 1)
  local questID = entry.questID
  if not questID then return end
  Goals.SetEach("quest", function(goal)
    local params = goal.params
    if params.mode ~= "ids" or params.done[questID] then return nil end
    for _, id in ipairs(params.quests) do
      if id == questID then
        params.done[questID] = true
        if entry.name and not params.names[questID] then params.names[questID] = entry.name end
        return chainProgress(params)
      end
    end
  end)
end)
