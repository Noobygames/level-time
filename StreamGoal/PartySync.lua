-- Gruppenziele (Roadmap 311): Ziel an die Gruppe schicken (/sg share <Nr>, PartySync.ShareGoal),
-- gemeinsame Ziele, bei denen Kills/Beute aller zählen, Abgleich über Addon-Nachrichten mit eigener
-- Drossel (Hardcore-Protokoll / FriendRace.lua als Vorbild).
--   S:<kind>:<target>:<encodedParams>  Ziel teilen
--   P:<sharedKey>:<delta>              Fortschritt buchen
-- Eigene Drossel: eine Nachricht je SEND_INTERVAL Sekunden aus einer Warteschlange; während der Chat-Sperre
-- (LT.GroupChat.Locked) pausiert sie. Eigene Nachrichten und geheime Werte werden ignoriert.
-- Einstellung: settings.partySync (Standard an).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L

local PartySync = {
  PREFIX = "StreamGoal",
  SEND_INTERVAL = 1,
  MAX_QUEUE = 50,
}
ns.PartySync = PartySync

local SHARED_KINDS = {
  kills = true,
  item = true,
  dungeon = true,
  quest = true,
  explore = true,
}

local queue = {}
local receivingRemote = false

local function enabled()
  return ns.db and ns.db.settings and ns.db.settings.partySync == true
end

local function chatInfo()
  return C_ChatInfo and C_ChatInfo.SendAddonMessage and C_ChatInfo or nil
end

local function enqueue(message, chatType)
  if #queue >= PartySync.MAX_QUEUE then table.remove(queue, 1) end
  table.insert(queue, { message = message, chatType = chatType })
end

local function flush()
  local api = chatInfo()
  if not api or #queue == 0 or (LT.GroupChat and LT.GroupChat.Locked()) then return end
  local entry = table.remove(queue, 1)
  ns.Debug("partysync", "send %s to %s", entry.message, entry.chatType)
  api.SendAddonMessage(PartySync.PREFIX, entry.message, entry.chatType)
end

function PartySync.Flush()
  while #queue > 0 do
    flush()
  end
end

---------------------------------------------------------------------------
-- Kodierung und Schlüssel
---------------------------------------------------------------------------
function PartySync.EncodeParams(params)
  if type(params) ~= "table" then return "" end
  local keys = {}
  for k, v in pairs(params) do
    if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
      table.insert(keys, k)
    end
  end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    table.insert(parts, k .. "=" .. tostring(params[k]))
  end
  return table.concat(parts, ";")
end

function PartySync.DecodeParams(str)
  local params = {}
  if not str or str == "" then return params end
  for pair in str:gmatch("[^;]+") do
    local k, v = pair:match("^([^=]+)=(.*)$")
    if k and v then
      if v == "true" then v = true
      elseif v == "false" then v = false
      elseif tonumber(v) then v = tonumber(v)
      end
      if type(v) ~= "string" or v ~= "" then params[k] = v end
    end
  end
  return params
end

function PartySync.SharedKey(kind, target, params)
  local targetStr = target and tostring(target) or ""
  local paramKey = type(params) == "string" and params or PartySync.EncodeParams(params)
  return kind .. ":" .. targetStr .. ":" .. paramKey
end

local function goalSharedKey(goal)
  return goal.sharedKey or PartySync.SharedKey(goal.kind, goal.target, goal.params)
end

---------------------------------------------------------------------------
-- Teilen und Fortschritt senden
---------------------------------------------------------------------------
function PartySync.ShareGoal(goalId)
  local goal = Goals.Get(tonumber(goalId))
  if not goal or goal.status ~= Goals.ACTIVE then
    return false, string.format(L.SG_ERR_NO_GOAL, tostring(goalId or "?"))
  end
  local channel = LT.GroupChat and LT.GroupChat.PartyChannel()
  if not channel then
    return false, L.SG_ERR_NOT_IN_GROUP
  end
  goal.shared = true
  goal.sharedKey = goalSharedKey(goal)
  local message = "S:" .. goal.kind .. ":" .. (goal.target or "") .. ":" .. PartySync.EncodeParams(goal.params)
  enqueue(message, channel)
  ns.Print(string.format(L.SG_PARTY_SHARED, Goals.Title(goal)))
  return true
end

function PartySync.SendProgress(sharedKey, delta)
  local channel = LT.GroupChat and LT.GroupChat.PartyChannel()
  if not channel then return false end
  local message = "P:" .. sharedKey .. ":" .. tostring(delta)
  enqueue(message, channel)
  return true
end

---------------------------------------------------------------------------
-- Empfangen
---------------------------------------------------------------------------
local function isOwn(sender)
  if not sender then return true end
  local name, realm = sender:match("^([^-]+)-?(.*)$")
  if name ~= UnitName("player") then return false end
  local ownRealm = (GetRealmName and GetRealmName() or ""):gsub("%s", "")
  return realm == "" or realm == ownRealm
end

local function readable(value)
  return type(value) == "string" and not LT.IsSecret(value) and value or nil
end

local function handleShare(kind, targetStr, encodedParams)
  if not enabled() then return end
  local target = tonumber(targetStr)
  local params = PartySync.DecodeParams(encodedParams)
  local def = Goals.GetKind(kind)
  if not def or not Goals.IsAvailable(kind) then return end
  local sharedKey = PartySync.SharedKey(kind, target, params)

  -- Schon vorhanden?
  for _, goal in ipairs(Goals.Active()) do
    local key = goalSharedKey(goal)
    if key == sharedKey then
      goal.shared = true
      goal.sharedKey = sharedKey
      ns.Print(string.format(L.SG_PARTY_JOINED_GOAL, Goals.Title(goal)))
      return
    end
  end

  if Goals.UsedSlots() >= Goals.MAX_ACTIVE then return end
  local goal, err = Goals.Create(kind, params, target)
  if goal then
    goal.shared = true
    goal.sharedKey = sharedKey
    ns.Print(string.format(L.SG_PARTY_RECEIVED_GOAL, Goals.Title(goal)))
  end
end

local function handleProgress(sharedKey, delta)
  if not enabled() or not delta or delta <= 0 then return end
  for _, goal in ipairs(Goals.Active()) do
    local key = goalSharedKey(goal)
    if key == sharedKey or (SHARED_KINDS[goal.kind] and key == sharedKey) then
      receivingRemote = true
      Goals.Update(goal, goal.progress + delta)
      receivingRemote = false
      break
    end
  end
end

local HANDLERS = {
  S = function(body)
    local kind, targetStr, encodedParams = body:match("^([^:]+):([^:]*):?(.*)$")
    if kind then handleShare(kind, targetStr, encodedParams) end
  end,
  P = function(body)
    local sharedKey, deltaStr = body:match("^(.-):(%d+)$")
    if sharedKey and deltaStr then handleProgress(sharedKey, tonumber(deltaStr)) end
  end,
}

LT.RegisterEvent("CHAT_MSG_ADDON", function(prefix, text, _, sender)
  prefix, text, sender = readable(prefix), readable(text), readable(sender)
  if prefix ~= PartySync.PREFIX or not text or not sender or not enabled() or isOwn(sender) then return end
  local kind, body = text:match("^(%u):?(.*)$")
  local handler = kind and HANDLERS[kind]
  if not handler then return end
  ns.Debug("partysync", "received %s from %s", text, sender)
  handler(body)
end)

---------------------------------------------------------------------------
-- Lokale Fortschritte erfassen
---------------------------------------------------------------------------
Goals.OnChange(function(event, goal, delta)
  if receivingRemote then return end
  if not (event == "progress" or event == "done") then return end
  if not goal or not delta or delta <= 0 then return end
  if not enabled() then return end
  if not (goal.shared or SHARED_KINDS[goal.kind]) then return end
  local channel = LT.GroupChat and LT.GroupChat.PartyChannel()
  if not channel then return end
  local sharedKey = goalSharedKey(goal)
  PartySync.SendProgress(sharedKey, delta)
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------
LT.OnLogin(function()
  local api = chatInfo()
  if api and api.RegisterAddonMessagePrefix then api.RegisterAddonMessagePrefix(PartySync.PREFIX) end
end)

LT.Every(PartySync.SEND_INTERVAL, flush)
