-- Zähler des eingeloggten Charakters in drei Bereichen (Scopes):
--   LEVEL     aktuelles Level, beginnt beim Level-Up neu
--   SESSION   aktuelle Session, beginnt beim Login neu (siehe Session.lua)
--   INSTANCE  laufender Instanz-Lauf (siehe Instances.lua), ohne Lauf leer
-- Jedes Increment zählt in Level und Session; den Instanz-Lauf zählt Instances.lua über OnIncrement.
local _, ns = ...

local Stats = {}
ns.Stats = Stats

Stats.LEVEL = "level"
Stats.SESSION = "session"
Stats.INSTANCE = "instance"

-- Zähler-Schlüssel (Defaults in Database.lua)
Stats.PVE_KILLS = "pveKills"
Stats.PVP_KILLS = "pvpKills"
Stats.DEATHS = "deaths"
Stats.DEAD_SECONDS = "deadSeconds"
Stats.QUESTS = "quests"
Stats.XP_GAINED = "xpGained"
Stats.XP_KILLS = "xpKills"
Stats.XP_QUESTS = "xpQuests"
Stats.XP_RESTED = "xpRested"
Stats.XP_EXPLORE = "xpExplore"          -- weitere XP-Quellen und Ort der XP (XpSources.lua)
Stats.XP_GATHER = "xpGather"
Stats.XP_WORLD = "xpWorld"
Stats.XP_DUNGEON = "xpDungeon"
Stats.XP_RAID = "xpRaid"
Stats.XP_BATTLEGROUND = "xpBattleground"
Stats.MONEY_EARNED = "moneyEarned"
Stats.ELITE_KILLS = "eliteKills"
Stats.RARE_KILLS = "rareKills"
Stats.NEAR_DEATHS = "nearDeaths"
Stats.COMBAT_SECONDS = "combatSeconds"  -- Zeitaufteilung (TimeBreakdown.lua)
Stats.TAXI_SECONDS = "taxiSeconds"
Stats.AFK_SECONDS = "afkSeconds"
Stats.IDLE_SECONDS = "idleSeconds"        -- Leerlauf ohne AFK-Flag (Einstellung idleMinutes)
Stats.MONEY_JUNK = "moneyJunk"            -- Erlös aus verkauftem Schrott (Merchant.lua), Teil der Einnahmen
Stats.SPENT_REPAIR = "spentRepair"        -- Ausgaben nach Art (MoneyCounter.lua)
Stats.SPENT_MERCHANT = "spentMerchant"
Stats.SPENT_TAXI = "spentTaxi"
Stats.SPENT_TRAINER = "spentTrainer"
Stats.SPENT_OTHER = "spentOther"

local NO_COUNTERS = {}  -- Instanz-Bereich ohne laufenden Lauf (nie beschrieben)

local function countersOf(scope)
  if scope == Stats.SESSION then
    return ns.character.currentSession.counters
  elseif scope == Stats.INSTANCE then
    local run = ns.Instances.GetCurrentRun()
    return run and run.stats or NO_COUNTERS
  end
  return ns.character.currentLevel.counters
end

-- Zählt der Bereich gerade mit? Level und Session immer, die Instanz nur bei laufender Lauf-Uhr
-- (draußen steht der Lauf still). Noch nicht gebuchte Zeiten gehören nur dann dazu.
function Stats.IsCounting(scope)
  return scope ~= Stats.INSTANCE or ns.Instances.IsRunning()
end

-- Gibt es den Bereich gerade? Level und Session immer, die Instanz nur mit offenem Lauf.
function Stats.IsOpen(scope)
  return scope ~= Stats.INSTANCE or ns.Instances.GetCurrentRun() ~= nil
end

function Stats.Get(scope, counter)
  return countersOf(scope)[counter] or 0
end

-- Module, die zusätzlich mitzählen (z.B. pro Zone oder pro Tag): listener(counter, amount)
local incrementListeners = {}

function Stats.OnIncrement(listener)
  table.insert(incrementListeners, listener)
end

function Stats.Increment(counter, amount)
  amount = amount or 1
  ns.Debug("stats", "%s +%s", counter, amount)
  for _, scope in ipairs({ Stats.LEVEL, Stats.SESSION }) do
    local counters = countersOf(scope)
    counters[counter] = (counters[counter] or 0) + amount
  end
  for _, listener in ipairs(incrementListeners) do
    ns.SafeCall(listener, counter, amount)
  end
end

function Stats.GetTotalKills(scope)
  return Stats.Get(scope, Stats.PVE_KILLS) + Stats.Get(scope, Stats.PVP_KILLS)
end

-- Kopie aller Zähler eines Bereichs, z.B. für die Historie
function Stats.Snapshot(scope)
  local copy = {}
  for counter, value in pairs(countersOf(scope)) do
    copy[counter] = value
  end
  return copy
end

-- Gespielte Sekunden im Bereich (Level: vom Server, nil bis zur ersten Antwort)
function Stats.GetSeconds(scope)
  if scope == Stats.SESSION then
    return ns.Session.GetSeconds()
  elseif scope == Stats.INSTANCE then
    local run = ns.Instances.GetCurrentRun()
    return run and ns.Instances.GetRunSeconds(run) or 0
  end
  return ns.PlayedTime.GetLevelSeconds()
end

-- Gewonnene XP im Bereich. Für das Level ist UnitXP exakt (zählt ab Levelbeginn,
-- auch wenn das Addon erst später installiert wurde); Session und Instanz zählen selbst mit.
function Stats.GetXp(scope)
  if scope ~= Stats.LEVEL then
    return Stats.Get(scope, Stats.XP_GAINED)
  end
  return UnitXP("player")
end

local function startLevel(level)
  local currentLevel = ns.character.currentLevel
  currentLevel.level = level
  currentLevel.seconds = 0
  currentLevel.xp = 0
  currentLevel.partial = nil  -- nur teilweise erfasst (Coverage.lua)
  currentLevel.counters = ns.Database.NewCounters()
end

-- Level hat sich geändert, während das Addon nicht lief (oder erster Start)
ns.OnLogin(function()
  if ns.character.currentLevel.level ~= ns.level then
    startLevel(ns.level)
  end
end)

ns.OnLevelStarted(startLevel)

-- Letzte bekannte Werte sichern, damit die Historie sie auch für ausgeloggte Charaktere zeigen kann
ns.OnLogout(function()
  local currentLevel = ns.character.currentLevel
  currentLevel.seconds = Stats.GetSeconds(Stats.LEVEL) or currentLevel.seconds
  currentLevel.xp = UnitXP("player")
end)
