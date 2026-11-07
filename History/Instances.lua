-- Instanz-Läufe: ein Lauf ist eine Kopie eines Dungeons, Raids oder Szenarios (siehe InstanceCopy.lua),
-- vom ersten Betreten bis zum Reset oder bis man eine andere Kopie betritt. Raus und wieder rein in
-- dieselbe Kopie (Händler, /reload) setzt den Lauf fort; die Zeit draußen zählt nicht, außer als Geist
-- auf dem Weg zurück zur Leiche. Wiederbelebt draußen (Geistheiler) hält die Uhr an.
-- Offener Lauf: ns.character.currentRun = { name, instanceType, startedAt, seconds, level,
-- stats = alle Zähler wie bei Level und Session (Bereich Stats.INSTANCE), zoneUID, unconfirmed }.
-- unconfirmed = Stand vor einem Wiedereintritt, dessen Kopie noch nicht bestätigt ist; zeigt sich
-- eine andere Kopie, wird dort geteilt.
-- Beendete Läufe landen im Journal (instanceLog) mit xp und counters = { kills, deaths, reputation }
-- (reputation fehlt bei älteren Läufen).
-- Läufe aus älteren Versionen haben statt stats die Felder xp und counters; beim Login umgewandelt.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal
local InstanceCopy = ns.InstanceCopy

local Instances = {}
ns.Instances = Instances

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

-- Beendeter Lauf als Journal-Eintrag-Teil { xp, counters = { kills, deaths, reputation } }
function Instances.ToRecord(run)
  local xp, kills, deaths = Instances.Summarize(run)
  local reputation = run.stats and run.stats[Stats.REPUTATION] or 0
  return { xp = xp, counters = { kills = kills, deaths = deaths, reputation = reputation } }
end

function Instances.GetRunSeconds(run)
  local running = (run == currentRun() and runningSince) and (GetTime() - runningSince) or 0
  return run.seconds + running
end

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

local function copyCounters(counters)
  local copy = {}
  for counter, value in pairs(counters) do
    copy[counter] = value
  end
  return copy
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
  if runningSince then runningSince = GetTime() end
  ns.Debug("instances", "run reset: %s", run.name)
  return true
end

-- Stand vor einem Wiedereintritt, dessen Kopie noch nicht feststeht
local function snapshot(run)
  return { seconds = run.seconds, stats = copyCounters(run.stats), at = time(), level = ns.level }
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
    local stats = run.stats
    stats[Stats.XP_GAINED] = (stats[Stats.XP_GAINED] or 0) + previous.xp
    stats[Stats.PVE_KILLS] = (stats[Stats.PVE_KILLS] or 0) + previous.counters.kills
    stats[Stats.DEATHS] = (stats[Stats.DEATHS] or 0) + previous.counters.deaths
    stats[Stats.REPUTATION] = (stats[Stats.REPUTATION] or 0) + (previous.counters.reputation or 0)
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

-- Lauf aus einer älteren Version (xp, counters) auf den vollen Zählersatz bringen
local function upgrade(run)
  if run.stats then return end
  run.stats = ns.Database.NewCounters()
  run.stats[Stats.XP_GAINED] = run.xp
  run.stats[Stats.PVE_KILLS] = run.counters.kills
  run.stats[Stats.DEATHS] = run.counters.deaths
  run.xp, run.counters = nil, nil
  if run.unconfirmed and not run.unconfirmed.stats then
    local before = run.unconfirmed
    before.stats = ns.Database.NewCounters()
    before.stats[Stats.XP_GAINED] = before.xp
    before.stats[Stats.PVE_KILLS] = before.kills
    before.stats[Stats.DEATHS] = before.deaths
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
