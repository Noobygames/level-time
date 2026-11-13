-- Dungeon- und Raid-Runs (Roadmap 493): Auswertung der Instanz-Läufe für den Live-Tracker (UI/InstanceRunTracker.lua)
-- und das Run-Fenster (UI/InstanceRunWindow.lua). Läufe kommen aus History.GetInstanceLog (neueste zuerst, der offene
-- Lauf vorne), Felder siehe Instances.lua.
-- Splits: record.splits = Laufzeit je Boss-Kill parallel zu record.bosses (InstanceBosses.lua); passt die Zahl nicht
-- (Lauf aus einer älteren Version), gibt es keine Splits.
-- Gleiche Instanz: Karte und Schwierigkeit, ohne Karten-ID (Läufe vor Roadmap 460) der Name.
-- Vergleich: BEST = schnellster abgeschlossener anderer Lauf derselben Instanz, LAST = der vorige Lauf derselben
-- Instanz. Abgeschlossen = Endboss der Bossliste besiegt (ohne Bossliste nie; Rar-Bosse sind nie Endboss).
-- XP je Boss: erster Kill-Eintrag mit dem Bossnamen im Zeitfenster des Laufs (Start bis Beginn des nächsten Laufs);
-- shortcut: Bossname = Gegnername gilt für Classic-Dungeons, Retail-Bosse mit anderem Gegnernamen bleiben ohne XP.
-- Beute: Würfe mit runStart = Start des Laufs und eigene Beute ab "selten" in der Zone mit dem Instanznamen im
-- Zeitfenster; shortcut: weicht der Zonenname vom Instanznamen ab, fehlt die eigene Beute (Würfe bleiben).
local _, ns = ...
local InstanceBosses = ns.InstanceBosses
local Journal = ns.Journal

local InstanceRuns = {}
ns.InstanceRuns = InstanceRuns

InstanceRuns.BEST = "best"
InstanceRuns.LAST = "last"
InstanceRuns.DUNGEON = "party"
InstanceRuns.RAID = "raid"
local LOOT_MIN_QUALITY = 2  -- ab "selten" (grün)

-- { [encounterID] = Sekunden seit Start } eines Laufs (leer ohne passende Splits)
function InstanceRuns.Splits(record)
  local ids, seconds, splits = {}, {}, {}
  for id in string.gmatch(record.bosses or "", "%d+") do ids[#ids + 1] = tonumber(id) end
  for value in string.gmatch(record.splits or "", "%d+") do seconds[#seconds + 1] = tonumber(value) end
  if #ids ~= #seconds then return splits end
  for index, id in ipairs(ids) do splits[id] = seconds[index] end
  return splits
end

function InstanceRuns.IsCompleted(record)
  local list = InstanceBosses.List(record.mapID, record.difficultyID)
  local endBoss = InstanceBosses.EndBoss(list)
  return endBoss ~= nil and InstanceBosses.Killed(record)[endBoss] == true
end

function InstanceRuns.SameInstance(a, b)
  if a.mapID and b.mapID then return a.mapID == b.mapID and a.difficultyID == b.difficultyID end
  return a.name == b.name
end

-- Vergleichslauf zu records[index] (records neueste zuerst) oder nil
function InstanceRuns.Reference(records, index, mode)
  local record = records[index]
  if mode == InstanceRuns.LAST then
    for i = index + 1, #records do
      if InstanceRuns.SameInstance(records[i], record) then return records[i] end
    end
    return nil
  end
  local best
  for i, other in ipairs(records) do
    if i ~= index and InstanceRuns.SameInstance(other, record) and (not best or other.seconds < best.seconds)
      and InstanceRuns.IsCompleted(other) then
      best = other
    end
  end
  return best
end

-- Abgeschlossen und mindestens so schnell wie jeder andere abgeschlossene Lauf derselben Instanz
function InstanceRuns.IsBest(records, index)
  if not InstanceRuns.IsCompleted(records[index]) then return false end
  local best = InstanceRuns.Reference(records, index, InstanceRuns.BEST)
  return not best or records[index].seconds <= best.seconds
end

-- Offener Lauf schneller als der beste frühere abgeschlossene derselben Instanz (Chat beim Endboss)
function InstanceRuns.IsNewBest(run)
  local records = ns.History.GetInstanceLog(ns.characterKey)
  local best = records[1] and records[1].isCurrent and InstanceRuns.Reference(records, 1, InstanceRuns.BEST)
  return best and ns.Instances.GetRunSeconds(run) < best.seconds or false
end

-- Ende des Zeitfensters von records[index]: Start des nächsten (neueren) Laufs oder jetzt
function InstanceRuns.WindowEnd(records, index)
  local newer = records[index - 1]
  return newer and newer.time or time()
end

-- Erster Eintrag einer Journal-Liste (älteste zuerst) mit time >= since
local function firstIndexSince(list, since)
  local low, high = 1, #list + 1
  while low < high do
    local middle = math.floor((low + high) / 2)
    if (list[middle].time or 0) < since then low = middle + 1 else high = middle end
  end
  return low
end

-- Einträge eines Logs im Zeitfenster [since, untilTime] an visit(entry) geben
local function eachInWindow(characterKey, logName, since, untilTime, visit)
  local list = Journal.GetEntries(characterKey, logName)
  for i = firstIndexSince(list, since), #list do
    local entry = list[i]
    if (entry.time or 0) > untilTime then return end
    visit(entry)
  end
end

-- { [encounterID] = XP } der besiegten Bosse eines Laufs
function InstanceRuns.BossXp(characterKey, record, windowEnd)
  local byName, xp = {}, {}
  for id in pairs(InstanceBosses.Killed(record)) do
    local name = InstanceBosses.Name(id)
    if name then byName[name] = id end
  end
  eachInWindow(characterKey, "killLog", record.time, windowEnd, function(kill)
    local id = kill.name and byName[kill.name]
    if id and not xp[id] then xp[id] = kill.xp end
  end)
  return xp
end

-- Beute eines Laufs: { { link, roll = Wurf-Eintrag oder nil, quantity }, ... }, Würfe zuerst
function InstanceRuns.Loot(characterKey, record, windowEnd)
  local items, rolled = {}, {}
  eachInWindow(characterKey, "rollLog", record.time, windowEnd, function(roll)
    if roll.runStart ~= record.time then return end
    local link = roll.link or roll.name or "?"
    items[#items + 1] = { link = link, roll = roll }
    rolled[link] = true
  end)
  eachInWindow(characterKey, "lootLog", record.time, windowEnd, function(entry)
    local link = entry.link or entry.name
    if link and entry.zone == record.name and (entry.quality or 0) >= LOOT_MIN_QUALITY and not rolled[link] then
      items[#items + 1] = { link = link, quantity = entry.quantity }
    end
  end)
  return items
end
