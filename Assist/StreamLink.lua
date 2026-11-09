-- Stream-Link (Roadmap 315): Twitch/Discord-Link im Kopierfeld, optional zeitgesteuert
-- in Gruppe oder Gilde mit Sperren gegen Spam (UltraHardcore).
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local GroupChat = ns.GroupChat

ns.Database.RegisterDefaults({
  settings = {
    streamLink = "",
    streamLinkChannel = "off",
    streamLinkMinutes = 30,
  },
  ranges = {
    streamLinkMinutes = { 15, 120 },
  },
})

local StreamLink = {
  MIN_MINUTES = 15,
  MAX_MINUTES = 120,
}
ns.StreamLink = StreamLink

local lastSentTime = 0
local lastXp = 0
local lastKills = 0
local lastQuests = 0

local function isAfk()
  return UnitIsAFK and UnitIsAFK("player")
end

local function recordActivity()
  lastXp = Stats.GetXp(Stats.SESSION) or 0
  lastKills = Stats.GetTotalKills(Stats.SESSION) or 0
  lastQuests = Stats.Get(Stats.SESSION, Stats.QUESTS) or 0
end

local function hasActivity()
  local xp = Stats.GetXp(Stats.SESSION) or 0
  local kills = Stats.GetTotalKills(Stats.SESSION) or 0
  local quests = Stats.Get(Stats.SESSION, Stats.QUESTS) or 0
  return xp > lastXp or kills > lastKills or quests > lastQuests
end

local function announceChannel(target)
  if target == "guild" then return GroupChat.GuildChannel() end
  if target == "party" then return GroupChat.PartyChannel() end
  return nil
end

function StreamLink.SendNow()
  if not ns.db or not ns.db.streamLink or ns.db.streamLink == "" then return false end
  local target = ns.db.streamLinkChannel
  if not target or target == "off" then return false end

  local channel = announceChannel(target)
  if not channel or GroupChat.Locked() or InCombatLockdown() then return false end

  local text = string.format(L.STREAM_LINK_MESSAGE, ns.db.streamLink)
  GroupChat.Send(text, channel)
  lastSentTime = time()
  recordActivity()
  return true
end

function StreamLink.OpenCopy()
  local link = ns.db and ns.db.streamLink
  if not link or link == "" then
    ns.Print(L.STREAM_LINK_EMPTY)
    return
  end
  ns.Export.Show(L.STREAM_LINK_TITLE, link)
end

local function checkTimer()
  if not ns.db or not ns.db.streamLink or ns.db.streamLink == "" then return end
  if not ns.db.streamLinkChannel or ns.db.streamLinkChannel == "off" then return end

  local intervalSeconds = math.max(StreamLink.MIN_MINUTES, ns.db.streamLinkMinutes or 30) * 60
  if (time() - lastSentTime) < intervalSeconds then return end

  if GroupChat.Locked() or InCombatLockdown() or isAfk() then return end
  if not hasActivity() then return end

  StreamLink.SendNow()
end

ns.Every(60, checkTimer, function(db)
  return db and db.streamLink ~= "" and db.streamLinkChannel ~= "off"
end)

ns.OnLogin(function()
  lastSentTime = time()
  recordActivity()
end)
