-- Zähler des eingeloggten Charakters in drei Bereichen (Scopes):
--   LEVEL     aktuelles Level, beginnt beim Level-Up neu
--   SESSION   aktuelle Session, beginnt beim Login neu (siehe Session.lua)
--   INSTANCE  laufender Instanz-Lauf (siehe Instances.lua), ohne Lauf leer
-- Jedes Increment zählt in Level und Session; den Instanz-Lauf zählt Instances.lua über OnIncrement.
-- Stats kennt die Quellen der Bereiche nicht selbst: Zeitquellen und den Instanz-Bereich melden PlayedTime.lua,
-- Session.lua und Instances.lua über Stats.RegisterScope an (keine Abhängigkeit nach oben).
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
Stats.INCOME_LOOT = "incomeLoot"          -- Einnahmen nach Art (MoneyCounter.lua), zusammen = MONEY_EARNED
Stats.INCOME_QUEST = "incomeQuest"
Stats.INCOME_MERCHANT = "incomeMerchant"
Stats.INCOME_MAIL = "incomeMail"
Stats.INCOME_AUCTION = "incomeAuction"
Stats.INCOME_TRADE = "incomeTrade"
Stats.INCOME_OTHER = "incomeOther"
Stats.REPUTATION = "reputation"          -- Rufgewinne aller Fraktionen (Reputation.lua)
Stats.ITEMS_LOOTED = "itemsLooted"       -- erbeutete Gegenstände nach Anzahl (ItemsLooted.lua)
-- Alle Ausgaben-Zähler (Summe = Ausgaben gesamt)
Stats.SPENDING = { Stats.SPENT_REPAIR, Stats.SPENT_MERCHANT, Stats.SPENT_TAXI, Stats.SPENT_TRAINER, Stats.SPENT_OTHER }

local NO_COUNTERS = {}  -- Bereich ohne Zähler (Instanz ohne laufenden Lauf; nie beschrieben)

local function always() return true end
local function noCounters() return NO_COUNTERS end
local function noSeconds() return 0 end

-- Bereich -> { counters() -> Tabelle, seconds() -> Sekunden oder nil, isOpen(), isCounting() }
local scopes = {}

-- Bereich anmelden oder ergänzen: fields = { counters, seconds, isOpen, isCounting } (fehlende bleiben, wie sie sind;
-- ohne Angabe: keine Zähler, 0 Sekunden, immer offen und zählend)
function Stats.RegisterScope(scope, fields)
  local definition = scopes[scope] or
    { counters = noCounters, seconds = noSeconds, isOpen = always, isCounting = always }
  for key, fn in pairs(fields) do definition[key] = fn end
  scopes[scope] = definition
end

Stats.RegisterScope(Stats.LEVEL, { counters = function() return ns.character.currentLevel.counters end })
Stats.RegisterScope(Stats.SESSION, { counters = function() return ns.character.currentSession.counters end })

-- Unbekannte Bereiche zählen wie das Level (wie bisher)
local function definitionOf(scope)
  return scopes[scope] or scopes[Stats.LEVEL]
end

local function countersOf(scope)
  return definitionOf(scope).counters()
end

-- Zählt der Bereich gerade mit? Level und Session immer, die Instanz nur bei laufender Lauf-Uhr
-- (draußen steht der Lauf still). Noch nicht gebuchte Zeiten gehören nur dann dazu.
function Stats.IsCounting(scope)
  return definitionOf(scope).isCounting()
end

-- Gibt es den Bereich gerade? Level und Session immer, die Instanz nur mit offenem Lauf.
function Stats.IsOpen(scope)
  return definitionOf(scope).isOpen()
end

function Stats.Get(scope, counter)
  return countersOf(scope)[counter] or 0
end

-- Module, die zusätzlich mitzählen (z.B. pro Zone oder pro Tag): listener(counter, amount)
local incrementListeners = {}

function Stats.OnIncrement(listener)
  ns.RememberSource(listener, "Stats.lua")
  table.insert(incrementListeners, listener)
end

-- Bereiche, die jede Erhöhung zählen (fest, damit Increment keine Tabelle je Aufruf baut)
local COUNTED_SCOPES = { Stats.LEVEL, Stats.SESSION }

function Stats.Increment(counter, amount)
  amount = amount or 1
  ns.Debug("stats", "%s +%s", counter, amount)
  for index = 1, #COUNTED_SCOPES do
    local counters = countersOf(COUNTED_SCOPES[index])
    counters[counter] = (counters[counter] or 0) + amount
  end
  for index = 1, #incrementListeners do
    ns.SafeCall(incrementListeners[index], counter, amount)
  end
end

function Stats.GetTotalKills(scope)
  return Stats.Get(scope, Stats.PVE_KILLS) + Stats.Get(scope, Stats.PVP_KILLS)
end

-- Kopie aller Zähler eines Bereichs, z.B. für die Historie
function Stats.Snapshot(scope)
  return ns.Database.CopyCounters(countersOf(scope))
end

-- Gespielte Sekunden im Bereich (Level: vom Server, nil bis zur ersten Antwort)
function Stats.GetSeconds(scope)
  return definitionOf(scope).seconds()
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
