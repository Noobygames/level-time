-- Statistik beim Gruppenbeitritt (Roadmap 317): optional Tode, Dungeons und Level-Zeit
-- in den Gruppenchat beim Beitreten (UltraHardcore).
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format
local GroupChat = ns.GroupChat

ns.Database.RegisterDefaults({
  settings = {
    announceGroupJoin = false,
  },
})

local GroupJoinStats = {
  COOLDOWN = 60,
}
ns.GroupJoinStats = GroupJoinStats

local wasInGroup = false
local lastJoinTime = 0

function GroupJoinStats.Text()
  local deaths = Stats.Get(Stats.LEVEL, Stats.DEATHS) or 0
  for _, record in pairs(ns.character and ns.character.levelHistory or {}) do
    deaths = deaths + ((record.counters and record.counters[Stats.DEATHS]) or 0)
  end

  local dungeons = (ns.character and ns.character.instanceHistory and #ns.character.instanceHistory) or
                   (ns.character and ns.character.instanceLog and #ns.character.instanceLog) or 0
  local levelTime = Format.Duration(Stats.GetSeconds(Stats.LEVEL) or 0)

  return string.format(L.GROUP_JOIN_STATS, ns.level, deaths, dungeons, levelTime)
end

function GroupJoinStats.CheckGroup()
  local inGroup = IsInGroup and IsInGroup() or false
  local joined = inGroup and not wasInGroup
  wasInGroup = inGroup

  if not joined then return false end
  if not ns.db or not ns.db.announceGroupJoin then return false end

  local now = GetTime()
  if now - lastJoinTime < GroupJoinStats.COOLDOWN then return false end
  lastJoinTime = now

  local channel = GroupChat.PartyChannel()
  if channel and not GroupChat.Locked() then
    GroupChat.Send(GroupJoinStats.Text(), channel)
    return true
  end
  return false
end

ns.RegisterEvent("GROUP_ROSTER_UPDATE", GroupJoinStats.CheckGroup)

ns.OnLogin(function()
  wasInGroup = IsInGroup and IsInGroup() or false
end)
