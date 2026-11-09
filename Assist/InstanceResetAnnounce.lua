-- Instanz-Reset-Ansage an die Gruppe (Roadmap 448, Einstellung announceInstanceReset, Standard aus):
-- beim Zurücksetzen von Instanzen (ResetInstances) eine Zeile mit dem Lockout-Stand der Stunde an die Gruppe.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    announceInstanceReset = false,
  },
})
local L = ns.L
local GroupChat = ns.GroupChat
local InstanceLimit = ns.InstanceLimit

local InstanceResetAnnounce = {}
ns.InstanceResetAnnounce = InstanceResetAnnounce

function InstanceResetAnnounce.Text()
  local count = (InstanceLimit and InstanceLimit.GetHourCount and InstanceLimit.GetHourCount()) or 0
  local limit = (InstanceLimit and InstanceLimit.GetLimit and InstanceLimit.GetLimit()) or 5
  local remaining = math.max(0, limit - count)
  return string.format(L.INSTANCE_RESET_ANNOUNCEMENT, remaining, limit)
end

local function getChannel()
  if not IsInGroup or not IsInGroup() then return nil end
  if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
  if IsInRaid and IsInRaid() then return "RAID" end
  return "PARTY"
end

function InstanceResetAnnounce.Send()
  if not ns.db or not ns.db.announceInstanceReset then return false end
  if GroupChat.Locked() then return false end
  local channel = getChannel()
  if not channel then return false end

  local text = InstanceResetAnnounce.Text()
  ns.Debug("announce", "instance reset announce: %s to %s", text, channel)
  GroupChat.Send(text, channel)
  return true
end

local function onResetInstances()
  InstanceResetAnnounce.Send()
end

if type(ResetInstances) == "function" then
  hooksecurefunc("ResetInstances", onResetInstances)
end
