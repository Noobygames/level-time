-- Instanz-Bericht an die Gruppe (Roadmap 282, Einstellung announceInstanceReport, Standard aus, wie NovaInstanceTracker):
-- beim Verlassen einer Instanz eine Zeile mit Dauer, XP, Kills, XP je Kill und Geld des offenen Laufs
-- ("Level Time: Todesminen: 32m 10s, 12.3k XP, 45 Kills (273 XP/Kill), 2g 30s 5c").
-- Nur in einer Gruppe (GroupChat.PartyChannel), nicht als Geist (der Lauf geht weiter), erst ab MIN_SECONDS und nur,
-- wenn sich der Lauf seit dem letzten Bericht verändert hat (raus und wieder rein meldet nicht doppelt). Bei
-- gesperrtem Chat (GroupChat.Locked) fällt der Bericht weg. Instances.lua hält die Uhr beim Verlassen vorher an.
-- Von Hand (/lt report): jederzeit in der Instanz, ohne Einstellung, Mindestdauer und Doppelt-Sperre; ohne Gruppe oder
-- bei gesperrtem Chat nur als eigene Chatzeile.
-- Beute (Roadmap 441, Einstellung instanceReportLoot): danach je gewonnenem Gruppen-Wurf des Laufs (Journal rollLog,
-- runStart = startedAt) eine Zeile "Boss: Link - Gewinner (Bedarf 87)", ab instanceReportLootQuality, höchstens
-- instanceReportLootMax, der Rest als "+N weitere". Die Zeilen gehen in eine Warteschlange, höchstens eine je Sekunde,
-- und warten bei gesperrtem Chat; alle Gewürfelt-Passen-Würfe fehlen.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format
local GroupChat = ns.GroupChat

local InstanceReport = {}
ns.InstanceReport = InstanceReport

local MIN_SECONDS = 60

local LOOT_INTERVAL = 1  -- Sekunden zwischen zwei Beute-Zeilen

local lootQueue = {}    -- [i] = Text mit Links, noch zu senden
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

-- Gewinnzeile eines Wurfs: "Boss: [Link] - Gewinner (Bedarf 87)"
function InstanceReport.LootLine(entry)
  local text = string.format(L.INSTANCE_REPORT_LOOT_LINE, entry.link, Format.PlainText(entry.winner or "?"))
  local kind = entry.winnerChoice and ns.LootRollReport.KindLabel(entry.winnerChoice)
  local detail = kind and Format.PlainText(kind)
  if entry.winnerRoll then detail = (detail and detail .. " " or "") .. entry.winnerRoll end
  if detail then text = text .. " (" .. detail .. ")" end
  if entry.encounter then text = string.format(L.INSTANCE_REPORT_LOOT_BOSS, Format.PlainText(entry.encounter), text) end
  return text
end

-- Berichtszeilen der Beute eines Laufs (ohne Warteschlange); leer, wenn aus oder nichts gewonnen
function InstanceReport.LootLines(run)
  local lines = {}
  if not ns.db.instanceReportLoot or not run.startedAt then return lines end
  local minQuality, max = ns.db.instanceReportLootQuality, ns.db.instanceReportLootMax
  local won = 0
  for _, entry in ipairs(ns.Journal.GetEntries(ns.characterKey, "rollLog")) do
    if entry.runStart == run.startedAt and entry.allPassed ~= 1 and entry.winner and entry.link
        and (entry.quality or 0) >= minQuality then
      won = won + 1
      if won <= max then lines[#lines + 1] = InstanceReport.LootLine(entry) end
    end
  end
  if won > max then lines[#lines + 1] = string.format(L.INSTANCE_REPORT_LOOT_MORE, won - max) end
  return lines
end

local function queueLoot(run)
  for _, line in ipairs(InstanceReport.LootLines(run)) do lootQueue[#lootQueue + 1] = line end
  if #lootQueue > 0 then ns.RefreshTasks() end
end

ns.Every(LOOT_INTERVAL, function()
  if #lootQueue == 0 then
    ns.RefreshTasks()  -- leer: Aufgabe ruht, bis wieder etwas ansteht
    return
  end
  if GroupChat.Locked() then return end
  local chatType = GroupChat.PartyChannel()
  if not chatType then
    lootQueue = {}
    return
  end
  GroupChat.SendWithLinks(table.remove(lootQueue, 1), chatType)
end, function() return #lootQueue > 0 end)

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
  queueLoot(run)
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
  queueLoot(run)
end
