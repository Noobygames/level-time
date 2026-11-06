-- Instanzlimit: Der Server lässt pro Stunde nur LIMIT neue Instanzen (Dungeons und Raids) zu, für alle
-- Charaktere eines Accounts auf einem Realm (Classic Era, Anniversary, WoW Forever: 5; Retail: 10).
-- Die Stunde gleitet: ein Platz wird eine Stunde nach dem Betreten der jeweiligen Instanz wieder frei.
-- Classic-Clients zusätzlich DAILY_LIMIT = 30 neue Instanzen in 24 Stunden (gleitend, Roadmap 282; bekannt aus
-- WoW Classic 2019, warcraft.wiki.gg "Instance" nennt nur noch das Stundenlimit, daher nur Anzeige und Warnung,
-- im Spiel zu prüfen). Retail hat kein Tageslimit.
--
-- Betretene Instanzen: LevelTimerStatsDB.instanceEntries[Realm] = { { time, name, character }, ... },
-- älteste zuerst, nur die letzten 24 Stunden. Accountweit, damit alle Charaktere zählen, die das Addon
-- in diesem Client schon gesehen hat.
--
-- Ob eine Kopie neu ist, entscheidet InstanceCopy.lua: zuerst geschätzt, später an der zoneUID der
-- Gegner bestätigt. Widerspricht die Bestätigung der Schätzung, wird der Eintrag nachgetragen bzw.
-- wieder entfernt.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local InstanceCopy = ns.InstanceCopy

local InstanceLimit = {}
ns.InstanceLimit = InstanceLimit

InstanceLimit.WINDOW = 3600               -- Sekunden, für die eine Instanz zählt
local LIMIT_CLASSIC = 5
local LIMIT_RETAIL = 10
local DAILY_LIMIT_CLASSIC = 30
local KEEP_SECONDS = 24 * 3600            -- so lange bleiben Einträge gespeichert (Info "heute")
local COUNTED_TYPES = { party = true, raid = true }  -- Schlachtfelder und Szenarien zählen nicht

function InstanceLimit.GetLimit()
  return ns.Client.IsRetail() and LIMIT_RETAIL or LIMIT_CLASSIC
end

-- Neue Instanzen je 24 Stunden; nil ohne Tageslimit (Retail)
function InstanceLimit.GetDailyLimit()
  if ns.Client.IsRetail() then return nil end
  return DAILY_LIMIT_CLASSIC
end

local function realmEntries()
  LevelTimerStatsDB.instanceEntries = LevelTimerStatsDB.instanceEntries or {}
  local realm = ns.character.realm
  LevelTimerStatsDB.instanceEntries[realm] = LevelTimerStatsDB.instanceEntries[realm] or {}
  return LevelTimerStatsDB.instanceEntries[realm]
end

local function prune(entries, now)
  while entries[1] and now - entries[1].time > KEEP_SECONDS do
    table.remove(entries, 1)
  end
end

-- Einträge seit since (Zeitstempel), älteste zuerst
local function entriesSince(since)
  local result = {}
  for _, entry in ipairs(realmEntries()) do
    if entry.time > since then table.insert(result, entry) end
  end
  return result
end

-- Neue Instanzen in der laufenden Stunde
function InstanceLimit.GetHourCount()
  return #entriesSince(time() - InstanceLimit.WINDOW)
end

-- Sekunden, bis der nächste Platz frei wird (die älteste Instanz der Stunde fällt heraus); nil ohne Einträge
function InstanceLimit.GetSecondsUntilNextFree()
  local oldest = entriesSince(time() - InstanceLimit.WINDOW)[1]
  if not oldest then return nil end
  return oldest.time + InstanceLimit.WINDOW - time()
end

-- Neue Instanzen seit Mitternacht (nur Info, kein Limit)
function InstanceLimit.GetTodayCount()
  return #entriesSince(ns.Daily.StartOfDay(time()) - 1)
end

-- Neue Instanzen in den letzten 24 Stunden (gleitend, für das Tageslimit)
function InstanceLimit.GetDayCount()
  return #entriesSince(time() - KEEP_SECONDS)
end

-- Stand laut Addon; extra = weitere Werte für das Format (z.B. Instanzen heute)
local function notifyCount(format, ...)
  local count, limit = InstanceLimit.GetHourCount(), InstanceLimit.GetLimit()
  local wait = InstanceLimit.GetSecondsUntilNextFree() or 0
  ns.Alerts.Notify({ title = L.NOTICE_INSTANCE_LIMIT, text = string.format(format, count, limit, Format.Duration(wait), ...),
    icon = ns.Alerts.ICONS.instanceLimit }, ns.Alerts.WARNING_COLOR)
end

local function warn()
  if not ns.db.warnInstanceLimit then return end
  local dailyLimit = InstanceLimit.GetDailyLimit()
  if dailyLimit and InstanceLimit.GetDayCount() >= dailyLimit - 1 then
    ns.Alerts.Notify({ title = L.NOTICE_INSTANCE_LIMIT, icon = ns.Alerts.ICONS.instanceLimit,
      text = string.format(L.INSTANCE_DAILY_LIMIT_WARNING, InstanceLimit.GetDayCount(), dailyLimit) },
      ns.Alerts.WARNING_COLOR)
  end
  if InstanceLimit.GetHourCount() < InstanceLimit.GetLimit() - 1 then return end
  notifyCount(L.INSTANCE_LIMIT_WARNING)
end

-- Neue Kopie betreten (enteredAt = Zeitpunkt des Betretens, auch wenn sie erst später erkannt wurde)
local function add(name, enteredAt)
  local entries = realmEntries()
  prune(entries, time())
  table.insert(entries, { time = enteredAt, name = name, character = ns.characterKey })
  -- Eine Korrektur kann einen früheren Zeitpunkt nachtragen; prune und GetSecondsUntilNextFree brauchen "älteste zuerst"
  table.sort(entries, function(a, b) return a.time < b.time end)
  ns.Debug("instances", "new instance %s, %s in the last hour", name, InstanceLimit.GetHourCount())
  warn()
end

-- Vermeintlich neue Kopie war doch die alte: jüngsten Eintrag dieses Charakters für sie entfernen
local function remove(name)
  local entries = realmEntries()
  for index = #entries, 1, -1 do
    local entry = entries[index]
    if entry.name == name and entry.character == ns.characterKey then
      table.remove(entries, index)
      ns.Debug("instances", "same instance %s after all, %s in the last hour", name, InstanceLimit.GetHourCount())
      return
    end
  end
end

InstanceCopy.OnEnter(function(name, instanceType, isNew)
  if isNew and COUNTED_TYPES[instanceType] then add(name, time()) end
end)

InstanceCopy.OnCorrected(function(name, instanceType, isNew, enteredAt)
  if not COUNTED_TYPES[instanceType] then return end
  if isNew then
    add(name, enteredAt)
  else
    remove(name)
  end
end)

-- Der Server weist ab ("zu viele Instanzen"): Stand und Wartezeit laut Addon dazu
local function onSystemMessage(message)
  if not ns.db.warnInstanceLimit or not TRANSFER_ABORT_TOO_MANY_INSTANCES or ns.IsSecret(message) then return end
  if message:find(TRANSFER_ABORT_TOO_MANY_INSTANCES, 1, true) then
    -- Abgewiesen trotz Platz laut Addon: geschätzt zu wenig gezählt oder ein anderes Limit des
    -- Servers (z.B. pro Tag, nicht offiziell belegt); daher auch die Zahl von heute
    notifyCount(L.INSTANCE_LIMIT_BLOCKED, InstanceLimit.GetTodayCount())
  end
end

ns.RegisterEvent("CHAT_MSG_SYSTEM", onSystemMessage)
