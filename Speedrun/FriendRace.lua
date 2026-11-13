-- Rennen gegen Freunde (Einstellung friendRace, aus): Addon-Nachrichten (C_ChatInfo.SendAddonMessage, Präfix
-- "LevelTimer", in allen Clients laut generierter Doku) tauschen Level-Zeiten mit anderen Level-Time-Nutzern.
--   Anfrage   "Q"                         beim Inspizieren (Flüstern) und bei Gruppenänderung (Gruppe)
--   Antwort   "I:<Level>:<Klasse>", dann "T:<ab Level>:<s1>,<s2>,..." in Stücken bis MAX_MESSAGE Byte (Flüstern)
--   Level-Up  "L:<Level>:<Sekunden des Levels>" an die Gruppe und an alle, die in dieser Sitzung gefragt haben
-- Empfangene Läufe: LevelTimerStatsDB.friendRuns[Absender] = { times, level, class, updated }; der zuletzt
-- gehörte ist der Vergleich der Spalte "gegen Freund" in der Split-Liste. Ohne friendRace wird weder gefragt
-- noch geantwortet.
-- Eigene Drossel: eine Nachricht je SEND_INTERVAL Sekunden aus einer Warteschlange; während der Chat-Sperre
-- (GroupChat.Locked: Bosskämpfe in Retail/WoW Forever, SendAddonMessage ist dort ebenfalls gesperrt) bleibt sie
-- liegen. Werte aus CHAT_MSG_ADDON können in Instanzen geheim sein und werden dann verworfen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    friendRace = false,
  },
})
local L = ns.L

local FriendRace = {
  PREFIX = ns.ADDON_ID,
  MAX_MESSAGE = 240,     -- Grenze 255 Byte, mit Reserve
  SEND_INTERVAL = 1,
  MAX_QUEUE = 50,
  REQUEST_PAUSE = 60,    -- dieselbe Anfrage an Gruppe/Spieler höchstens so oft
}
ns.FriendRace = FriendRace

local WHISPER = "WHISPER"
local queue = {}
local peers = {}         -- Absender, die in dieser Sitzung gefragt haben (bekommen Level-Ups)
local lastRequest = {}   -- Ziel -> GetTime() der letzten Anfrage
local current            -- zuletzt gehörter Freund

local function runs()
  LevelTimerStatsDB.friendRuns = LevelTimerStatsDB.friendRuns or {}
  return LevelTimerStatsDB.friendRuns
end

local function enabled()
  return ns.db and ns.db.friendRace == true
end

local function chatInfo()
  return C_ChatInfo and C_ChatInfo.SendAddonMessage and C_ChatInfo or nil
end

local function enqueue(message, chatType, target)
  if #queue >= FriendRace.MAX_QUEUE then table.remove(queue, 1) end
  table.insert(queue, { message = message, chatType = chatType, target = target })
end

local function flush()
  local api = chatInfo()
  if not api or #queue == 0 or ns.GroupChat.Locked() then return end
  local entry = table.remove(queue, 1)
  ns.Debug("friendrace", "send %s to %s %s", entry.message, entry.chatType, entry.target)
  api.SendAddonMessage(FriendRace.PREFIX, entry.message, entry.chatType, entry.target)
end

---------------------------------------------------------------------------
-- Senden
---------------------------------------------------------------------------

-- Anfrage an einen Spieler (Flüstern) oder die Gruppe (target nil), gedrosselt je Ziel
function FriendRace.Request(target)
  if not enabled() then return false end
  local channel = target and WHISPER or ns.GroupChat.PartyChannel()
  if not channel then return false end
  local key = target or channel
  if lastRequest[key] and GetTime() - lastRequest[key] < FriendRace.REQUEST_PAUSE then return false end
  lastRequest[key] = GetTime()
  enqueue("Q", channel, target)
  return true
end

-- Eigene Level-Zeiten in Stücken, die in eine Nachricht passen
local function timeMessages()
  local times = ns.Runs.LevelTimes(ns.characterKey)
  local messages, from, parts, length = {}, nil, {}, 0
  local function close()
    if from then table.insert(messages, "T:" .. from .. ":" .. table.concat(parts, ",")) end
    from, parts, length = nil, {}, 0
  end
  for level = 1, ns.level do
    local seconds = times[level]
    if seconds then
      local text = tostring(math.floor(seconds))
      if not from or length + #text + 1 > FriendRace.MAX_MESSAGE - 10 then close(); from = level end
      table.insert(parts, text)
      length = length + #text + 1
    else
      close()
    end
  end
  close()
  return messages
end

local function answer(sender)
  peers[sender] = true
  enqueue("I:" .. ns.level .. ":" .. (ns.character.class or ""), WHISPER, sender)
  for _, message in ipairs(timeMessages()) do enqueue(message, WHISPER, sender) end
end

-- Level-Up an Gruppe und Freunde, die gefragt haben
ns.OnLevelCompleted(function(level)
  if not enabled() then return end
  local record = ns.character.levelHistory[level]
  if not record or not record.seconds then return end
  local message = "L:" .. (level + 1) .. ":" .. math.floor(record.seconds)
  local party = ns.GroupChat.PartyChannel()
  if party then enqueue(message, party) end
  for peer in pairs(peers) do enqueue(message, WHISPER, peer) end
end)

---------------------------------------------------------------------------
-- Empfangen
---------------------------------------------------------------------------
local function runOf(sender)
  local all = runs()
  all[sender] = all[sender] or { times = {} }
  all[sender].updated = time()
  current = sender
  return all[sender]
end

local HANDLERS = {
  Q = function(sender) answer(sender) end,
  I = function(sender, body)
    local level, class = body:match("^(%d+):(%u*)$")
    if not level then return end
    local run = runOf(sender)
    run.level, run.class = tonumber(level), class ~= "" and class or nil
  end,
  T = function(sender, body)
    local from, list = body:match("^(%d+):([%d,]+)$")
    if not from then return end
    local run, level = runOf(sender), tonumber(from)
    for seconds in list:gmatch("%d+") do
      run.times[level] = tonumber(seconds)
      level = level + 1
    end
  end,
  L = function(sender, body)
    local level, seconds = body:match("^(%d+):(%d+)$")
    if not level then return end
    local run = runOf(sender)
    level, seconds = tonumber(level), tonumber(seconds)
    run.level, run.times[level - 1] = level, seconds
    peers[sender] = true
    ns.Print(string.format(L.FRIEND_LEVEL_UP, sender, level, ns.Format.Duration(seconds)))
  end,
}

local function readable(value)
  return type(value) == "string" and not ns.IsSecret(value) and value or nil
end

ns.RegisterEvent("CHAT_MSG_ADDON", function(prefix, text, _, sender)
  prefix, text, sender = readable(prefix), readable(text), readable(sender)
  if prefix ~= FriendRace.PREFIX or not text or not sender or not enabled() or ns.GroupChat.IsOwnSender(sender) then return end
  local kind, body = text:match("^(%u):?(.*)$")
  local handler = kind and HANDLERS[kind]
  if not handler then return end
  ns.Debug("friendrace", "received %s from %s", text, sender)
  handler(sender, body)
end)

---------------------------------------------------------------------------
-- Auslöser und Abfragen
---------------------------------------------------------------------------
ns.OnLogin(function()
  local api = chatInfo()
  if api and api.RegisterAddonMessagePrefix then api.RegisterAddonMessagePrefix(FriendRace.PREFIX) end
end)

ns.Every(FriendRace.SEND_INTERVAL, flush)

ns.RegisterEvent("GROUP_ROSTER_UPDATE", function()
  if IsInGroup and IsInGroup() == true then FriendRace.Request() end
end)

-- Inspizieren (alle Clients haben NotifyInspect; ohne die Funktion nur die Gruppe)
if NotifyInspect then
  hooksecurefunc("NotifyInspect", function(unit)
    if not unit or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
    local name = GetUnitName and GetUnitName(unit, true) or UnitName(unit)
    if readable(name) then FriendRace.Request((name:gsub("%s", ""))) end
  end)
end

-- Zuletzt gehörter Freund: name, run; nil ohne
function FriendRace.Current()
  if not current or not enabled() then return nil end
  return current, runs()[current]
end

-- Abweichung eines eigenen Levels zum Freund; nil ohne Zeit
function FriendRace.GetLevelDelta(level, seconds)
  local _, run = FriendRace.Current()
  local friendSeconds = run and run.times[level]
  if not friendSeconds or not seconds then return nil end
  return seconds - friendSeconds
end
