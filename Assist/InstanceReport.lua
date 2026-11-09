-- Instanz-Bericht an die Gruppe (Roadmap 282, Einstellung announceInstanceReport, Standard aus, wie NovaInstanceTracker):
-- beim Verlassen einer Instanz eine Zeile mit Dauer, XP, Kills, XP je Kill und Geld des offenen Laufs
-- ("Level Time: Todesminen: 32m 10s, 12.3k XP, 45 Kills (273 XP/Kill), 2g 30s 5c").
-- Nur in einer Gruppe (GroupChat.PartyChannel), nicht als Geist (der Lauf geht weiter), erst ab MIN_SECONDS und nur,
-- wenn sich der Lauf seit dem letzten Bericht verändert hat (raus und wieder rein meldet nicht doppelt). Bei
-- gesperrtem Chat (GroupChat.Locked) fällt der Bericht weg. Instances.lua hält die Uhr beim Verlassen vorher an.
-- Von Hand (/lt report): jederzeit in der Instanz, ohne Einstellung, Mindestdauer und Doppelt-Sperre; ohne Gruppe oder
-- bei gesperrtem Chat nur als eigene Chatzeile.
-- Beute (Roadmap 441, Einstellung instanceReportLoot): die gewonnenen Gruppen-Würfe des Laufs (Journal rollLog,
-- runStart = startedAt) ab instanceReportLootQuality, kurz je Gewinner: "Beute: Grimbar [A] [B], Lyra [C], +2 weitere"
-- (höchstens instanceReportLootMax Gegenstände, Name ohne Realm). Passt alles in die Berichtszeile (GroupChat.MAX_TEXT),
-- geht es in einer Nachricht; sonst folgen weitere Nachrichten "Beute: ...", höchstens eine je Sekunde, die bei
-- gesperrtem Chat warten. Alle-Gepasst-Würfe fehlen.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format
local GroupChat = ns.GroupChat

local InstanceReport = {}
ns.InstanceReport = InstanceReport

local MIN_SECONDS = 60

local LOOT_INTERVAL = 1  -- Sekunden zwischen zwei Folgenachrichten
local REPORT_SEPARATOR = " | "
local PART_SEPARATOR = ", "

local lootQueue = {}    -- [i] = Folgenachricht mit Links, noch zu senden
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

-- Gewinner ohne Realm ("Grimbar-Aegwynn" -> "Grimbar"), als reiner Text
local function shortName(name)
  return (Format.PlainText(name or "?"):gsub("%-.*$", ""))
end

-- Beute-Teile eines Laufs: { "Grimbar [A] [B]", "Lyra [C]", "+2 weitere" }; leer, wenn aus oder nichts gewonnen
function InstanceReport.LootParts(run)
  local parts = {}
  if not ns.db.instanceReportLoot or not run.startedAt then return parts end
  local minQuality, max = ns.db.instanceReportLootQuality, ns.db.instanceReportLootMax
  local won, byWinner = 0, {}
  for _, entry in ipairs(ns.Journal.GetEntries(ns.characterKey, "rollLog")) do
    if entry.runStart == run.startedAt and entry.allPassed ~= 1 and entry.winner and entry.link
        and (entry.quality or 0) >= minQuality then
      won = won + 1
      if won <= max then
        local name = shortName(entry.winner)
        local index = byWinner[name]
        if index then
          parts[index] = parts[index] .. " " .. entry.link
        else
          parts[#parts + 1] = name .. " " .. entry.link
          byWinner[name] = #parts
        end
      end
    end
  end
  if won > max then parts[#parts + 1] = string.format(L.INSTANCE_REPORT_LOOT_MORE, won - max) end
  return parts
end

-- Teile zu Nachrichten bündeln: die erste beginnt mit first (Berichtszeile, darf nil sein), jede bleibt unter
-- GroupChat.MAX_TEXT; passt die Beute nicht mehr dazu, beginnt eine neue Nachricht "Beute: ...". Ein einzelner zu
-- langer Teil steht allein (der Client kürzt dann).
function InstanceReport.Pack(first, parts)
  local messages, current, hasLoot = {}, first, false
  for _, part in ipairs(parts) do
    local loot = string.format(L.INSTANCE_REPORT_LOOT, part)
    local candidate
    if not current then
      candidate = loot
    elseif hasLoot then
      candidate = current .. PART_SEPARATOR .. part
    else
      candidate = current .. REPORT_SEPARATOR .. loot
    end
    if current and #candidate > GroupChat.MAX_TEXT then
      messages[#messages + 1] = current
      candidate = loot
    end
    current, hasLoot = candidate, true
  end
  if current then messages[#messages + 1] = current end
  return messages
end

-- Bericht samt Beute senden: erste Nachricht sofort, Folgenachrichten über die Warteschlange
local function sendReport(run, chatType)
  local messages = InstanceReport.Pack(Format.PlainText(InstanceReport.Text(run)), InstanceReport.LootParts(run))
  GroupChat.SendWithLinks(messages[1], chatType)
  for index = 2, #messages do lootQueue[#lootQueue + 1] = messages[index] end
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
  sendReport(run, chatType)
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
  sendReport(run, chatType)
end
