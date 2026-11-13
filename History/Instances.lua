-- Instanz-Läufe: ein Lauf ist eine Kopie eines Dungeons, Raids oder Szenarios (siehe InstanceCopy.lua),
-- vom ersten Betreten bis zum Reset oder bis man eine andere Kopie betritt. Raus und wieder rein in
-- dieselbe Kopie (Händler, /reload) setzt den Lauf fort; die Zeit draußen zählt nicht, außer als Geist
-- auf dem Weg zurück zur Leiche. Wiederbelebt draußen (Geistheiler) hält die Uhr an.
-- Offener Lauf: ns.character.currentRun = { name, instanceType, startedAt, seconds, level, mapID, difficultyID,
-- stats = alle Zähler wie bei Level und Session (Bereich Stats.INSTANCE), zoneUID, unconfirmed, bosses, splits, groupSize }.
-- bosses = besiegte Bosse, splits = Laufzeit je Boss-Kill (InstanceBosses.lua), groupSize = größte gesehene Gruppe
-- (Betreten und Boss-Kills); shortcut: beim Teilen (OnCorrected, neue Kopie) bleiben sie beim alten
-- Lauf, auch wenn einer nach dem Wiedereintritt fiel (Zeitfenster bis zur Bestätigung ist kurz).
-- unconfirmed = Stand vor einem Wiedereintritt, dessen Kopie noch nicht bestätigt ist; zeigt sich
-- eine andere Kopie, wird dort geteilt.
-- Beendete Läufe landen im Journal (instanceLog) mit xp und counters = { kills, deaths, reputation, money, quests }
-- (reputation, money und quests fehlen bei älteren Läufen); mapID/difficultyID (für InstanceInfo) fehlen bei Läufen vor Roadmap 460.
-- Läufe aus älteren Versionen haben statt stats die Felder xp und counters; beim Login umgewandelt. Den offenen Lauf
-- anderer Charaktere wandelt erst deren Login um: Summarize versteht deshalb beide Formen (Historie zeigt ihn).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showInstanceRun = false,
  },
})
local Stats = ns.Stats
local Journal = ns.Journal
local InstanceCopy = ns.InstanceCopy

local Instances = {}
ns.Instances = Instances

-- Felder des Journal-Eintrags (counters.*) und ihre Zähler beim Zusammenführen. Kills im Eintrag sind PvE und PvP
-- zusammen und fließen zurück in die PvE-Kills.
local RECORD_COUNTERS = {
  { field = "kills", counter = Stats.PVE_KILLS },
  { field = "deaths", counter = Stats.DEATHS },
  { field = "reputation", counter = Stats.REPUTATION },
  { field = "money", counter = Stats.MONEY_EARNED },
  { field = "quests", counter = Stats.QUESTS },
}

local runningSince  -- GetTime(), seit dem die Uhr des offenen Laufs läuft (nil = angehalten)

local function currentRun()
  return ns.character and ns.character.currentRun
end

-- Offener Lauf des eingeloggten Charakters (auch angehalten, solange man draußen ist) oder nil
function Instances.GetCurrentRun()
  return currentRun()
end

-- Läuft die Uhr des offenen Laufs? (nicht draußen, außer als Geist)
function Instances.IsRunning()
  return currentRun() ~= nil and runningSince ~= nil
end

-- XP, Kills und Tode eines Laufs (auch im alten Format ohne stats)
function Instances.Summarize(run)
  local stats = run.stats
  if not stats then
    return run.xp, run.counters.kills, run.counters.deaths
  end
  return stats[Stats.XP_GAINED] or 0, (stats[Stats.PVE_KILLS] or 0) + (stats[Stats.PVP_KILLS] or 0),
    stats[Stats.DEATHS] or 0
end

-- Beendeter Lauf als Journal-Eintrag-Teil { xp, counters = { kills, deaths, reputation, money, quests } }
function Instances.ToRecord(run)
  local xp, kills, deaths = Instances.Summarize(run)
  local counters = { kills = kills, deaths = deaths }
  for _, mapping in ipairs(RECORD_COUNTERS) do
    counters[mapping.field] = counters[mapping.field] or (run.stats and run.stats[mapping.counter]) or 0
  end
  return { xp = xp, counters = counters }
end

-- Größte gesehene Gruppe des Laufs merken (allein = 1)
function Instances.NoteGroupSize(run)
  local members = GetNumGroupMembers and GetNumGroupMembers() or 0
  if ns.IsSecret(members) then return end
  run.groupSize = math.max(run.groupSize or 1, members)
end

-- Splits ("192,305") um offset Sekunden verschieben; nil bleibt nil
local function shiftedSplits(splits, offset)
  if not splits then return nil end
  local shifted = {}
  for value in string.gmatch(splits, "%d+") do shifted[#shifted + 1] = tonumber(value) + offset end
  return table.concat(shifted, ",")
end

function Instances.GetRunSeconds(run)
  local running = (run == currentRun() and runningSince) and (GetTime() - runningSince) or 0
  return run.seconds + running
end

-- Bereich Stats.INSTANCE = der offene Lauf; ohne Lauf leer (keine Zähler, 0 Sekunden, nicht offen)
local NO_COUNTERS = {}
Stats.RegisterScope(Stats.INSTANCE, {
  counters = function()
    local run = currentRun()
    return run and run.stats or NO_COUNTERS
  end,
  seconds = function()
    local run = currentRun()
    return run and Instances.GetRunSeconds(run) or 0
  end,
  isOpen = function() return currentRun() ~= nil end,
  isCounting = Instances.IsRunning,
})

local function pause()
  local run = currentRun()
  if not run or not runningSince then return end
  ns.TimeBreakdown.Flush()  -- Zeit bis jetzt gehört noch in den Lauf
  run.seconds = Instances.GetRunSeconds(run)
  runningSince = nil
end

local function resume()
  if runningSince then return end
  ns.TimeBreakdown.Flush()  -- Zeit von draußen gehört nicht in den Lauf
  runningSince = GetTime()
  ns.Debug("instances", "clock started: %s, %s s so far", currentRun().name, currentRun().seconds)
end

local function newRun(name, instanceType, startedAt, level)
  return {
    name = name,
    instanceType = instanceType,
    startedAt = startedAt,
    seconds = 0,
    level = level,
    stats = ns.Database.NewCounters(),
  }
end

-- Karten-ID und Schwierigkeit der Instanz, in der man steht (GetInstanceInfo: 3. und 8. Wert); nil, wenn geheim
local function currentIds()
  local _, _, difficultyID, _, _, _, _, mapID = GetInstanceInfo()
  if ns.IsSecret(mapID) then mapID = nil end
  if ns.IsSecret(difficultyID) then difficultyID = nil end
  return mapID, difficultyID
end

local function finish()
  if not currentRun() then return end
  ns.Debug("instances", "run finished: %s, %s s", currentRun().name, Instances.GetRunSeconds(currentRun()))
  pause()
  Journal.AddInstanceRun(currentRun())
  ns.character.currentRun = nil
end

-- Daten des offenen Laufs verwerfen und neu zählen (Button, /lt resetinstance); die Uhr läuft weiter,
-- falls sie gerade lief. false ohne offenen Lauf.
function Instances.ResetCurrent()
  local run = currentRun()
  if not run then return false end
  ns.TimeBreakdown.Flush()  -- noch ungebuchte Zeit gehört zum Stand vor dem Zurücksetzen
  run.stats = ns.Database.NewCounters()
  run.seconds = 0
  run.startedAt = time()
  run.level = ns.level
  run.unconfirmed = nil
  run.bosses, run.splits, run.groupSize = nil, nil, nil
  Instances.NoteGroupSize(run)
  if runningSince then runningSince = GetTime() end
  ns.Debug("instances", "run reset: %s", run.name)
  return true
end

-- Stand vor einem Wiedereintritt, dessen Kopie noch nicht feststeht
local function snapshot(run)
  return { seconds = run.seconds, stats = ns.Database.CopyCounters(run.stats), at = time(), level = ns.level }
end

InstanceCopy.OnEnter(function(name, instanceType, isNew)
  local run = currentRun()
  if run and run.name == name and not isNew then
    ns.Debug("instances", "run continues: %s, clock was running %s, ghost %s", name, runningSince ~= nil,
      UnitIsDeadOrGhost("player"))
    -- Als Geist zurück zur Leiche läuft die Uhr schon: sicher dieselbe Kopie
    if not runningSince and run.zoneUID then
      run.unconfirmed = run.unconfirmed or snapshot(run)
    end
  else
    ns.Debug("instances", "new run: %s (open run %s, guessed new %s, ghost %s)", name, run and run.name, isNew,
      UnitIsDeadOrGhost("player"))
    finish()
    ns.character.currentRun = newRun(name, instanceType, time(), ns.level)
    currentRun().mapID, currentRun().difficultyID = currentIds()
    Instances.NoteGroupSize(currentRun())
  end
  resume()
end)

-- Als Geist auf dem Weg zum Friedhof und zurück läuft die Uhr weiter
InstanceCopy.OnLeave(function()
  if UnitIsDeadOrGhost("player") then
    ns.Debug("instances", "left as ghost, clock keeps running")
    return
  end
  pause()
end)

-- Draußen wiederbelebt (Geistheiler): Uhr anhalten. PLAYER_ALIVE kommt auch beim Freilassen des Geistes.
local function onPossiblyAlive()
  if UnitIsDeadOrGhost("player") or InstanceCopy.GetInsideName() then return end
  ns.Debug("instances", "alive outside, clock paused")
  pause()
end

-- Andere Kopie als geschätzt: Wiedereintritt war ein neuer Lauf (teilen) bzw. der vermeintlich neue
-- Lauf gehört zum zuletzt beendeten (zusammenführen)
InstanceCopy.OnCorrected(function(name, instanceType, isNew)
  local run = currentRun()
  if not run or run.name ~= name then return end
  ns.Debug("instances", "corrected %s: new copy %s, snapshot %s", name, isNew, run.unconfirmed ~= nil)
  if isNew then
    local before = run.unconfirmed
    if not before then return end
    pause()
    local fresh = newRun(name, instanceType, before.at, before.level)
    fresh.mapID, fresh.difficultyID = run.mapID, run.difficultyID
    fresh.seconds = run.seconds - before.seconds
    for counter, value in pairs(run.stats) do
      fresh.stats[counter] = value - (before.stats[counter] or 0)
    end
    run.seconds, run.stats = before.seconds, before.stats
    run.unconfirmed = nil
    finish()
    ns.character.currentRun = fresh
    resume()
  else
    local previous = Journal.TakeLastInstanceRun(name)
    if not previous then return end
    run.startedAt, run.level = previous.time, previous.level
    run.seconds = run.seconds + previous.seconds
    -- Splits nach dem Wiedereintritt zählen ab dem Start des zusammengeführten Laufs; fehlen sie beim vorigen Teil
    -- trotz Bossen (ältere Version), passen sie nicht mehr zu den Bossen und fallen weg
    local ownSplits = shiftedSplits(run.splits, previous.seconds)
    if previous.bosses then
      run.bosses = run.bosses and (previous.bosses .. "," .. run.bosses) or previous.bosses
      run.splits = previous.splits and (ownSplits and (previous.splits .. "," .. ownSplits) or previous.splits) or nil
    else
      run.splits = ownSplits
    end
    run.groupSize = math.max(run.groupSize or 1, previous.groupSize or 1)
    local stats = run.stats
    stats[Stats.XP_GAINED] = (stats[Stats.XP_GAINED] or 0) + previous.xp
    for _, mapping in ipairs(RECORD_COUNTERS) do
      stats[mapping.counter] = (stats[mapping.counter] or 0) + (previous.counters[mapping.field] or 0)
    end
  end
end)

InstanceCopy.OnConfirmed(function(name, zoneUID)
  local run = currentRun()
  if not run or run.name ~= name then return end
  run.zoneUID = zoneUID
  run.unconfirmed = nil
end)

-- Reset: diese Kopie gibt es nicht mehr, der Lauf ist zu Ende
InstanceCopy.OnReset(function(name)
  local run = currentRun()
  if run and run.name == name then finish() end
end)

-- Voller Zählersatz aus den alten Feldern xp, kills, deaths
local function convert(xp, kills, deaths)
  local stats = ns.Database.NewCounters()
  stats[Stats.XP_GAINED] = xp
  stats[Stats.PVE_KILLS] = kills
  stats[Stats.DEATHS] = deaths
  return stats
end

-- Lauf aus einer älteren Version (xp, counters; Stand davor mit xp, kills, deaths) auf den vollen Zählersatz bringen
local function upgrade(run)
  if run.stats then return end
  run.stats = convert(run.xp, run.counters.kills, run.counters.deaths)
  run.xp, run.counters = nil, nil
  local before = run.unconfirmed
  if before and not before.stats then
    before.stats = convert(before.xp, before.kills, before.deaths)
    before.xp, before.kills, before.deaths = nil, nil, nil
  end
end

-- Nach dem Login steht die Uhr; betritt man die Instanz (wieder), läuft sie weiter
ns.OnLogin(function()
  runningSince = nil
  if currentRun() then upgrade(currentRun()) end
end)

ns.OnLogout(pause)

ns.RegisterEvent("PLAYER_ALIVE", onPossiblyAlive)
ns.RegisterEvent("PLAYER_UNGHOST", onPossiblyAlive)

Stats.OnIncrement(function(counter, amount)
  local run = currentRun()
  if not run or not runningSince then return end
  run.stats[counter] = (run.stats[counter] or 0) + amount
end)
