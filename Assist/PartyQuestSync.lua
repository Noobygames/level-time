-- Gruppen-Questabgleich (Roadmap 453, Einstellung partyQuestSync, Standard aus):
-- Tauscht Addon-Nachrichten (C_ChatInfo.SendAddonMessage, Präfix ns.ADDON_ID .. "Q") mit Gruppenmitgliedern
-- über Quests und deren Fortschritte aus.
-- Formate:
--   "Q"                                             Anfrage bei Gruppenbeitritt / Roster-Update
--   "S:<questID>:<idx>=<have>/<need>,...;..."       Snapshot/Update von Quests und Ziel-Ständen
--   "U:<questID>:<idx>:<have>:<need>"               Einzelnes Ziel-Update
--   "C:<questID>"                                   Quest abgabebereit (ready / complete)
--   "R:<questID>"                                   Quest abgegeben oder abgebrochen
-- Eigene Sendewarteschlange mit Drossel (SEND_INTERVAL = 1 s, MAX_QUEUE = 40).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    partyQuestSync = false,
  },
})
local L = ns.L

local PartyQuestSync = {
  PREFIX = ns.ADDON_ID .. "Q",
  MAX_MESSAGE = 240,
  SEND_INTERVAL = 1,
  MAX_QUEUE = 40,
  REQUEST_COOLDOWN = 30,
}
ns.PartyQuestSync = PartyQuestSync

local queue = {}
local peers = {}         -- [playerName][questID] = { ready = bool, objectives = { [idx] = { have = n, need = m } }, updated = GetTime() }
local lastRequest = 0

local function enabled()
  return ns.db and ns.db.partyQuestSync == true
end

local function chatInfo()
  return C_ChatInfo and C_ChatInfo.SendAddonMessage and C_ChatInfo or nil
end

local function readable(value)
  return type(value) == "string" and not ns.IsSecret(value) and value or nil
end

local function isOwn(sender)
  if not sender or type(sender) ~= "string" then return false end
  local name, realm = sender:match("^([^-]+)-?(.*)$")
  if name ~= UnitName("player") then return false end
  local ownRealm = (GetRealmName and GetRealmName() or ""):gsub("%s", "")
  return realm == "" or realm == ownRealm
end

local function shortName(sender)
  if type(sender) ~= "string" then return "" end
  return sender:match("^([^-]+)") or sender
end

local function partyChannel()
  if not enabled() then return nil end
  if IsInRaid and IsInRaid() and (not GetNumGroupMembers or GetNumGroupMembers() > 5) then
    return nil
  end
  return ns.GroupChat.PartyChannel()
end

local function enqueue(message)
  if #queue >= PartyQuestSync.MAX_QUEUE then table.remove(queue, 1) end
  if queue[#queue] == message then return end
  table.insert(queue, message)
end

local function flush()
  local api = chatInfo()
  if not api or #queue == 0 or ns.GroupChat.Locked() then return end
  local channel = partyChannel()
  if not channel then return end
  local message = table.remove(queue, 1)
  ns.Debug("questsync", "send %s to %s", message, channel)
  api.SendAddonMessage(PartyQuestSync.PREFIX, message, channel)
end

---------------------------------------------------------------------------
-- Senden
---------------------------------------------------------------------------

function PartyQuestSync.Request()
  if not enabled() then return false end
  local channel = partyChannel()
  if not channel then return false end
  local now = GetTime()
  if now - lastRequest < PartyQuestSync.REQUEST_COOLDOWN then return false end
  lastRequest = now
  enqueue("Q")
  return true
end

local function snapshotMessages()
  local entries = ns.QuestLog.Entries()
  local messages = {}
  local parts = {}
  local length = 0

  local function close()
    if #parts > 0 then
      table.insert(messages, "S:" .. table.concat(parts, ";"))
      parts = {}
      length = 0
    end
  end

  for _, entry in ipairs(entries) do
    local qid = entry.questID
    if type(qid) == "number" and qid > 0 and not ns.IsSecret(qid) then
      local objParts = {}
      local objs = ns.QuestLog.Objectives(qid)
      for _, obj in ipairs(objs) do
        local idx, have, need = obj.index, obj.have, obj.need
        if idx and have and need and not ns.IsSecret(idx) and not ns.IsSecret(have) and not ns.IsSecret(need) then
          table.insert(objParts, string.format("%d=%d/%d", idx, have, need))
        end
      end
      local qPart
      if #objParts > 0 then
        qPart = tostring(qid) .. ":" .. table.concat(objParts, ",")
      elseif entry.ready then
        qPart = tostring(qid) .. ":ready"
      else
        qPart = tostring(qid) .. ":"
      end
      if length + #qPart + 1 > PartyQuestSync.MAX_MESSAGE - 10 then
        close()
      end
      table.insert(parts, qPart)
      length = length + #qPart + 1
    end
  end
  close()
  return messages
end

function PartyQuestSync.BroadcastSnapshot()
  if not enabled() then return end
  local channel = partyChannel()
  if not channel then return end
  for _, message in ipairs(snapshotMessages()) do
    enqueue(message)
  end
end

---------------------------------------------------------------------------
-- Empfangen
---------------------------------------------------------------------------

local function handleSnapshot(sender, body)
  local playerName = shortName(sender)
  peers[playerName] = peers[playerName] or {}
  local now = GetTime()
  for questChunk in body:gmatch("([^;]+)") do
    local qid, rest = questChunk:match("^(%d+):?(.*)$")
    if qid then
      qid = tonumber(qid)
      local record = peers[playerName][qid] or { objectives = {} }
      record.updated = now
      if rest == "ready" then
        record.ready = true
      elseif rest ~= "" then
        local allDone = true
        local count = 0
        for idx, have, need in rest:gmatch("(%d+)=(%d+)/(%d+)") do
          idx, have, need = tonumber(idx), tonumber(have), tonumber(need)
          record.objectives[idx] = { have = have, need = need }
          count = count + 1
          if have < need then allDone = false end
        end
        if count > 0 and allDone then
          record.ready = true
        end
      end
      peers[playerName][qid] = record
    end
  end
end

local HANDLERS = {
  Q = function(sender)
    PartyQuestSync.BroadcastSnapshot()
  end,
  S = function(sender, body)
    handleSnapshot(sender, body)
  end,
  U = function(sender, body)
    local qid, idx, have, need = body:match("^(%d+):(%d+):(%d+):(%d+)$")
    if not qid then return end
    qid, idx, have, need = tonumber(qid), tonumber(idx), tonumber(have), tonumber(need)
    local playerName = shortName(sender)
    peers[playerName] = peers[playerName] or {}
    local record = peers[playerName][qid] or { objectives = {} }
    record.updated = GetTime()
    record.objectives[idx] = { have = have, need = need }
    peers[playerName][qid] = record
  end,
  C = function(sender, body)
    local qid = tonumber(body:match("^(%d+)$"))
    if not qid then return end
    local playerName = shortName(sender)
    peers[playerName] = peers[playerName] or {}
    local record = peers[playerName][qid] or { objectives = {} }
    record.ready = true
    record.updated = GetTime()
    peers[playerName][qid] = record
  end,
  R = function(sender, body)
    local qid = tonumber(body:match("^(%d+)$"))
    if not qid then return end
    local playerName = shortName(sender)
    if peers[playerName] then
      peers[playerName][qid] = nil
    end
  end,
}

function PartyQuestSync.HandleMessage(prefix, text, channel, sender)
  prefix, text, sender = readable(prefix), readable(text), readable(sender)
  if prefix ~= PartyQuestSync.PREFIX or not text or not sender or not enabled() or isOwn(sender) then
    return false
  end
  local kind, body = text:match("^(%u):?(.*)$")
  local handler = kind and HANDLERS[kind]
  if not handler then return false end
  ns.Debug("questsync", "received %s from %s", text, sender)
  handler(sender, body)
  return true
end

ns.RegisterEvent("CHAT_MSG_ADDON", function(prefix, text, channel, sender)
  PartyQuestSync.HandleMessage(prefix, text, channel, sender)
end)

---------------------------------------------------------------------------
-- Abfrage & Tooltip-API
---------------------------------------------------------------------------

function PartyQuestSync.GetPeers()
  return peers
end

function PartyQuestSync.GetPeerCount()
  local count = 0
  for _ in pairs(peers) do count = count + 1 end
  return count
end

function PartyQuestSync.GetQueueLength()
  return #queue
end

function PartyQuestSync.PeerProgress(questID)
  local list = {}
  questID = tonumber(questID)
  if not questID then return list end
  for playerName, quests in pairs(peers) do
    local record = quests[questID]
    if record then
      local summary
      if record.ready then
        summary = L.PARTY_QUEST_SYNC_READY
      else
        local parts = {}
        local indices = {}
        for idx in pairs(record.objectives or {}) do
          table.insert(indices, idx)
        end
        table.sort(indices)
        for _, idx in ipairs(indices) do
          local obj = record.objectives[idx]
          if obj and obj.have and obj.need then
            table.insert(parts, string.format("%d/%d", obj.have, obj.need))
          end
        end
        summary = #parts > 0 and table.concat(parts, ", ") or ""
      end
      table.insert(list, {
        player = playerName,
        ready = record.ready == true,
        objectives = record.objectives or {},
        summary = summary,
      })
    end
  end
  table.sort(list, function(a, b) return a.player < b.player end)
  return list
end

function PartyQuestSync.TooltipLines(questID)
  local list = PartyQuestSync.PeerProgress(questID)
  if #list == 0 then return {} end
  local parts = {}
  for _, item in ipairs(list) do
    if item.summary and item.summary ~= "" then
      table.insert(parts, string.format("%s (%s)", item.player, item.summary))
    else
      table.insert(parts, item.player)
    end
  end
  local header = L.PARTY_QUEST_SYNC_HEADER
  return { string.format("%s %s", header, table.concat(parts, ", ")) }
end

function PartyQuestSync.AppendToTooltip(tooltip, questID)
  if not enabled() or not tooltip or type(tooltip.AddLine) ~= "function" then return end
  local lines = PartyQuestSync.TooltipLines(questID)
  if not lines or #lines == 0 then return end
  for _, line in ipairs(lines) do
    tooltip:AddLine(line, 0.6, 0.8, 1)
  end
  if tooltip.Show then tooltip:Show() end
end

local hooked = false
local function hookTooltip()
  if hooked or type(GameTooltip) ~= "table" or type(GameTooltip.SetHyperlink) ~= "function" then return end
  hooked = true
  hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
    if not enabled() or ns.IsSecret(link) or type(link) ~= "string" then return end
    local questID = tonumber((link:match("quest:(%d+)")))
    if questID then
      PartyQuestSync.AppendToTooltip(tooltip, questID)
    end
  end)
end

---------------------------------------------------------------------------
-- Ereignisse & Beobachter
---------------------------------------------------------------------------

ns.OnLogin(function()
  local api = chatInfo()
  if api and api.RegisterAddonMessagePrefix then
    api.RegisterAddonMessagePrefix(PartyQuestSync.PREFIX)
  end
end)

ns.Every(PartyQuestSync.SEND_INTERVAL, flush, function(db) return db.partyQuestSync == true end)

ns.RegisterEvent("GROUP_ROSTER_UPDATE", function()
  if not enabled() then return end
  if not IsInGroup or not IsInGroup() then
    peers = {}
    queue = {}
    return
  end
  PartyQuestSync.Request()
end)

ns.RegisterEvent("GROUP_LEFT", function()
  peers = {}
  queue = {}
end)

local function onQuestRemoved(questID)
  if ns.IsSecret(questID) then return end
  questID = tonumber(questID)
  if not enabled() or not questID then return end
  if not partyChannel() then return end
  enqueue(string.format("R:%d", questID))
end
ns.RegisterEvent("QUEST_REMOVED", onQuestRemoved)
ns.RegisterEvent("QUEST_TURNED_IN", onQuestRemoved)

ns.QuestWatch.Subscribe({
  enabled = function(db) return db and db.partyQuestSync == true end,
  onObjective = function(quest, objective, old)
    if not enabled() or not partyChannel() then return end
    local qid = quest.questID
    local idx = objective.index
    local have = objective.have
    local need = objective.need
    if qid and idx and have and need and not ns.IsSecret(qid) and not ns.IsSecret(idx) and not ns.IsSecret(have) and not ns.IsSecret(need) then
      enqueue(string.format("U:%d:%d:%d:%d", qid, idx, have, need))
    end
  end,
  onComplete = function(quest)
    if not enabled() or not partyChannel() then return end
    local qid = quest.questID
    if type(qid) == "number" and qid > 0 and not ns.IsSecret(qid) then
      enqueue(string.format("C:%d", qid))
    end
  end,
  onReady = function(quest)
    if not enabled() or not partyChannel() then return end
    local qid = quest.questID
    if type(qid) == "number" and qid > 0 and not ns.IsSecret(qid) then
      enqueue(string.format("C:%d", qid))
    end
  end,
  onAccepted = function(quest)
    if not enabled() or not partyChannel() then return end
    local qid = quest.questID
    if type(qid) == "number" and qid > 0 and not ns.IsSecret(qid) then
      local objs = ns.QuestLog.Objectives(qid)
      local parts = {}
      for _, obj in ipairs(objs) do
        if obj.index and obj.have and obj.need then
          table.insert(parts, string.format("%d=%d/%d", obj.index, obj.have, obj.need))
        end
      end
      if #parts > 0 then
        enqueue(string.format("S:%d:%s", qid, table.concat(parts, ",")))
      else
        enqueue(string.format("S:%d:", qid))
      end
    end
  end,
})

ns.RegisterApply(function(db)
  if db.partyQuestSync then
    hookTooltip()
    if IsInGroup and IsInGroup() then
      PartyQuestSync.Request()
    end
  else
    peers = {}
    queue = {}
  end
end)
