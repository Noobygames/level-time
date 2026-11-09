-- Instanz-Bericht an die Gruppe (Roadmap 282, Einstellung announceInstanceReport, Standard aus, wie NovaInstanceTracker):
-- beim Verlassen einer Instanz eine Zeile mit Dauer, XP, Kills, XP je Kill und Geld des offenen Laufs
-- ("Level Time: Todesminen: 32m 10s, 12.3k XP, 45 Kills (273 XP/Kill), 2g 30s 5c").
-- Nur in einer Gruppe (GroupChat.PartyChannel), nicht als Geist (der Lauf geht weiter), erst ab MIN_SECONDS und nur,
-- wenn sich der Lauf seit dem letzten Bericht verändert hat (raus und wieder rein meldet nicht doppelt). Bei
-- gesperrtem Chat (GroupChat.Locked) fällt der Bericht weg. Instances.lua hält die Uhr beim Verlassen vorher an.
-- Von Hand (/lt report): jederzeit in der Instanz, ohne Einstellung, Mindestdauer und Doppelt-Sperre; ohne Gruppe oder
-- bei gesperrtem Chat nur als eigene Chatzeile.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format
local GroupChat = ns.GroupChat

local InstanceReport = {}
ns.InstanceReport = InstanceReport

local MIN_SECONDS = 60

local lastReported  -- Stand des zuletzt gemeldeten Laufs ("Name:Sekunden:XP:Kills")

-- Berichtszeile eines Laufs
function InstanceReport.Text(run)
  local Instances = ns.Instances
  local xp, kills = Instances.Summarize(run)
  local parts = { Format.Duration(Instances.GetRunSeconds(run)), string.format(L.INSTANCE_REPORT_XP, Format.Number(xp)) }
  if kills > 0 then
    local perKill = xp > 0 and string.format(L.INSTANCE_REPORT_PER_KILL, Format.Number(math.floor(xp / kills))) or ""
    parts[#parts + 1] = string.format(L.INSTANCE_REPORT_KILLS, kills) .. perKill
  end
  local money = run.stats and run.stats[Stats.MONEY_EARNED] or 0
  if money > 0 then parts[#parts + 1] = Format.PlainMoney(money) end
  return string.format(L.INSTANCE_REPORT, run.name or "?", table.concat(parts, ", "))
end

local function stateOf(run)
  local xp, kills = ns.Instances.Summarize(run)
  return table.concat({ run.name or "", run.startedAt or 0, xp, kills }, ":")
end

local function report()
  if not ns.db.announceInstanceReport or UnitIsDeadOrGhost("player") then return end
  local run = ns.Instances.GetCurrentRun()
  if not run or ns.Instances.GetRunSeconds(run) < MIN_SECONDS then return end
  local chatType = GroupChat.PartyChannel()
  if not chatType then return end
  local state = stateOf(run)
  if state == lastReported then return end
  local text = InstanceReport.Text(run)
  if GroupChat.Locked() then
    ns.Debug("announce", "instance report skipped (chat lockdown): %s", text)
    return
  end
  lastReported = state
  ns.Debug("announce", "instance report: %s", text)
  GroupChat.Send(text, chatType)
end

ns.InstanceCopy.OnLeave(report)

-- /lt report: Bericht des laufenden (auch pausierten) Laufs sofort
function InstanceReport.SendNow()
  local run = ns.Instances.GetCurrentRun()
  if not run then
    ns.Print(L.INSTANCE_REPORT_NONE)
    return
  end
  local text = InstanceReport.Text(run)
  local chatType = GroupChat.PartyChannel()
  if not chatType or GroupChat.Locked() then
    ns.Print(text)
    return
  end
  lastReported = stateOf(run)
  GroupChat.Send(text, chatType)
end
