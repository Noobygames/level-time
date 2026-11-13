-- Quests (X.db.quests[questID]):
--   names, objective (Zieltext je Sprache), level, suggestedGroup, frequency (aus dem Questlog)
--   starts / ends["npc:<id>"|"object:<id>"|"item"] = Anzahl, startSpots / endSpots (Ort des Spielers dabei)
--   rewards = { items = { [itemID] = Menge }, choices = { [itemID] = Menge } } (Questfenster)
--   xpAt / moneyAt[Spielerlevel] = Belohnung laut Questfenster bzw. Questlog (GetRewardXP, GetQuestLogRewardXP)
--   turnIns[Spielerlevel] = { xp, money } tatsächlich erhalten (QUEST_TURNED_IN)
--   objectives[i] = { type, text (Sprache), required }; progress[i] = { npcs[id], items[id], spots, maps } = Anzahl,
--   wobei der Fortschritt dem Kill oder der Beute der letzten PROGRESS_SECONDS zugeordnet wird
--   after[questID] = wie oft diese Quest kurz nach jener abgegeben wurde angenommen (Hinweis auf Vorquests)
-- QUEST_ACCEPTED liefert in Retail/Forever (questID), in Classic (questLogIndex, questID): letzter Wert = questID.
-- Log: C_QuestLog.GetInfo (Retail/Forever) bzw. GetQuestLogTitle (Classic: title, level, suggestedGroup, isHeader,
-- isCollapsed, isComplete, frequency, questID); Ziele: C_QuestLog.GetQuestObjectives, sonst GetQuestLogLeaderBoard.
local _, X = ...

local Quests = {}
X.Quests = Quests

local PROGRESS_SECONDS = 5   -- Kill oder Beute so lange vor dem Fortschritt zählt als dessen Quelle
local SCAN_DELAY = 0.3       -- mehrere QUEST_LOG_UPDATE kurz hintereinander = ein Durchlauf
local RECENT_TURN_INS = 3    -- so viele zuletzt abgegebene Quests gelten als mögliche Vorquests
local AFTER_SECONDS = 600    -- und nur, wenn sie höchstens so lange her sind

local snapshot             -- [questID] = { [Zielnummer] = erfüllt }; nil bis zum ersten Durchlauf
local scanQueued = false
local recentTurnIns = {}   -- { { id, time }, ... } neueste zuerst

local function playerLevel()
  return X.Readable(UnitLevel("player")) or 0
end

-- "npc:123", "object:45" oder "item" (Spieler-GUID = aus einem Gegenstand gestartet) für die Questfigur
local function questGiverKey()
  local guid = X.Readable(UnitGUID("questnpc")) or X.Readable(UnitGUID("npc"))
  local kind, id = X.ParseGuid(guid)
  if kind == "Creature" or kind == "Vehicle" then return "npc:" .. id end
  if kind == "GameObject" then return "object:" .. id end
  if kind == "Player" then return "item" end
end

local function noteGiver(record, field, spotField)
  local key = questGiverKey()
  if not key then return end
  record[field] = record[field] or {}
  X.Increment(record[field], key)
  record[spotField] = record[spotField] or {}
  X.AddSpot(record[spotField])
end

local function noteRewards(record)
  local rewards = record.rewards or {}
  record.rewards = rewards
  for _, spec in ipairs({ { "reward", GetNumQuestRewards, "items" }, { "choice", GetNumQuestChoices, "choices" } }) do
    local total = spec[2] and X.Readable(spec[2]()) or 0
    for index = 1, total do
      local itemID = X.ItemIdFromLink(GetQuestItemLink(spec[1], index))
      if itemID then
        local _, _, amount = GetQuestItemInfo(spec[1], index)
        rewards[spec[3]] = rewards[spec[3]] or {}
        rewards[spec[3]][itemID] = X.Readable(amount) or 1
        X.Items.Remember(itemID)
      end
    end
  end
  local level = playerLevel()
  local xp, money = X.Call("GetRewardXP"), X.Call("GetRewardMoney")
  if type(xp) == "number" then
    record.xpAt = record.xpAt or {}
    record.xpAt[level] = xp
  end
  if type(money) == "number" then
    record.moneyAt = record.moneyAt or {}
    record.moneyAt[level] = money
  end
end

local function frameQuest()
  local questID = X.Call("GetQuestID")
  if type(questID) ~= "number" or questID <= 0 or not X.db then return nil end
  local record = X.Record("quests", questID)
  X.SetName(record, X.Call("GetTitleText"))
  return record, questID
end

X.On("QUEST_DETAIL", function()
  local record = frameQuest()
  if not record then return end
  local objective = X.Call("GetObjectiveText")
  if type(objective) == "string" and objective ~= "" then
    record.objective = record.objective or {}
    record.objective[GetLocale()] = objective
  end
  noteGiver(record, "starts", "startSpots")
  noteRewards(record)
end)

X.On("QUEST_COMPLETE", function()
  local record = frameQuest()
  if not record then return end
  noteGiver(record, "ends", "endSpots")
  noteRewards(record)
end)

---------------------------------------------------------------------------
-- Questlog
---------------------------------------------------------------------------
-- { [questID] = { index, level, suggestedGroup, frequency } }
local function logQuests()
  local list = {}
  if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries then
    for index = 1, X.Readable(C_QuestLog.GetNumQuestLogEntries()) or 0 do
      local info = C_QuestLog.GetInfo(index)
      local questID = info and X.Readable(info.questID)
      if questID and questID > 0 and not info.isHeader then
        list[questID] = { index = index, level = X.Readable(info.level), suggestedGroup = X.Readable(info.suggestedGroup),
          frequency = X.Readable(info.frequency) }
      end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for index = 1, X.Readable(GetNumQuestLogEntries()) or 0 do
      local _, level, suggestedGroup, isHeader, _, _, frequency, questID = GetQuestLogTitle(index)
      questID = X.Readable(questID)
      if questID and questID > 0 and not isHeader then
        list[questID] = { index = index, level = X.Readable(level), suggestedGroup = X.Readable(suggestedGroup),
          frequency = X.Readable(frequency) }
      end
    end
  end
  return list
end

-- Ziele: { { type, text, have, need }, ... }
local function objectivesOf(questID, logIndex)
  local list = {}
  local objectives = C_QuestLog and C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)
  if type(objectives) == "table" then
    for index, objective in ipairs(objectives) do
      list[index] = { type = X.Readable(objective.type), text = X.Readable(objective.text),
        have = X.Readable(objective.numFulfilled), need = X.Readable(objective.numRequired) }
    end
    return list
  end
  if not (GetNumQuestLeaderBoards and GetQuestLogLeaderBoard) then return list end
  for index = 1, X.Readable(GetNumQuestLeaderBoards(logIndex)) or 0 do
    local text, kind = GetQuestLogLeaderBoard(index, logIndex)
    text = X.Readable(text)
    local have, need = (text or ""):match("(%d+)%s*/%s*(%d+)")
    list[index] = { type = X.Readable(kind), text = text, have = tonumber(have), need = tonumber(need) }
  end
  return list
end

local function noteObjectives(record, objectives)
  record.objectives = record.objectives or {}
  for index, objective in ipairs(objectives) do
    local stored = record.objectives[index] or {}
    record.objectives[index] = stored
    stored.type = objective.type or stored.type
    stored.required = objective.need or stored.required
    if objective.text then
      stored.text = stored.text or {}
      stored.text[GetLocale()] = objective.text
    end
  end
end

local function noteProgress(record, index)
  record.progress = record.progress or {}
  local progress = record.progress[index] or {}
  record.progress[index] = progress
  local npcID = X.Units.LastKill(PROGRESS_SECONDS)
  if npcID then
    progress.npcs = progress.npcs or {}
    X.Increment(progress.npcs, npcID)
  end
  local itemID = X.Loot.LastItem(PROGRESS_SECONDS)
  if itemID then
    progress.items = progress.items or {}
    X.Increment(progress.items, itemID)
  end
  X.AddSpot(progress)
end

local function scan()
  scanQueued = false
  if not X.db then return end
  local previous = snapshot
  snapshot = {}
  for questID, info in pairs(logQuests()) do
    local objectives = objectivesOf(questID, info.index)
    local counts = {}
    for index, objective in ipairs(objectives) do counts[index] = objective.have or 0 end
    snapshot[questID] = counts
    local before = previous and previous[questID]
    if before then
      for index, have in ipairs(counts) do
        if before[index] and have > before[index] then noteProgress(X.Record("quests", questID), index) end
      end
    end
  end
end

X.On("QUEST_LOG_UPDATE", function()
  if scanQueued then return end
  scanQueued = true
  C_Timer.After(SCAN_DELAY, function() X.SafeCall(scan) end)
end)

X.On("QUEST_ACCEPTED", function(...)
  local questID = select(select("#", ...), ...)
  questID = X.Readable(questID)
  if type(questID) ~= "number" or not X.db then return end
  local record = X.Record("quests", questID)
  local info = logQuests()[questID]
  if info then
    record.level, record.suggestedGroup, record.frequency = info.level, info.suggestedGroup, info.frequency
    noteObjectives(record, objectivesOf(questID, info.index))
  end
  local xp, money = X.Call("GetQuestLogRewardXP", questID), X.Call("GetQuestLogRewardMoney", questID)
  local level = playerLevel()
  if type(xp) == "number" then
    record.xpAt = record.xpAt or {}
    record.xpAt[level] = record.xpAt[level] or xp
  end
  if type(money) == "number" then
    record.moneyAt = record.moneyAt or {}
    record.moneyAt[level] = record.moneyAt[level] or money
  end
  local now = GetTime()
  for _, turnIn in ipairs(recentTurnIns) do
    if now - turnIn.time <= AFTER_SECONDS then
      record.after = record.after or {}
      X.Increment(record.after, turnIn.id)
    end
  end
end)

X.On("QUEST_TURNED_IN", function(questID, xp, money)
  questID = X.Readable(questID)
  if type(questID) ~= "number" or not X.db then return end
  local record = X.Record("quests", questID)
  record.turnIns = record.turnIns or {}
  record.turnIns[playerLevel()] = { xp = X.Readable(xp), money = X.Readable(money) }
  table.insert(recentTurnIns, 1, { id = questID, time = GetTime() })
  recentTurnIns[RECENT_TURN_INS + 1] = nil
end)
