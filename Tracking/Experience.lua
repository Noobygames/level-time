-- Erfahrung je Bereich (Level/Session): XP pro Stunde, Zeit bis Level-Up, XP-Quellen.
-- Zählt außerdem gewonnene XP (für Sessions) und verbrauchte Erholungs-XP.
local _, ns = ...
local Stats = ns.Stats

local Experience = {}
ns.Experience = Experience

local SECONDS_PER_HOUR = 3600
local MIN_SECONDS_FOR_RATE = 60  -- darunter schwankt die Rate zu stark

-- Wirksames Max-Level wie in Blizzards XP-Balken: Retail/Forever GameRulesUtil, Classic global;
-- berücksichtigt das Levelcap der Erweiterung des Accounts. Ältere Clients: GetMaxPlayerLevel.
local function isAtMaxLevel()
  if GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel then
    return GameRulesUtil.IsPlayerAtEffectiveMaxLevel()
  end
  if IsPlayerAtEffectiveMaxLevel then return IsPlayerAtEffectiveMaxLevel() end
  return GetMaxPlayerLevel ~= nil and ns.level >= GetMaxPlayerLevel()
end

-- false auf Max-Level oder bei abgeschalteter XP
function Experience.IsLeveling()
  if IsXPUserDisabled and IsXPUserDisabled() then return false end
  if isAtMaxLevel() then return false end
  return UnitXPMax("player") > 0
end

-- XP pro Stunde aus XP und Spielzeit, nil wenn noch nicht aussagekräftig
function Experience.CalculateRate(xp, seconds)
  if not seconds or seconds < MIN_SECONDS_FOR_RATE or not xp or xp <= 0 then return nil end
  return xp / seconds * SECONDS_PER_HOUR
end

-- Spielzeit, auf die sich Raten und Prognosen beziehen: ohne AFK-Zeit, wenn eingestellt
-- (xpRateWithoutAfk, AFK-Zeit aus TimeBreakdown.lua). Auch für Historie-Einträge.
function Experience.RateSeconds(seconds, afkSeconds)
  if not seconds or not ns.db or not ns.db.xpRateWithoutAfk then return seconds end
  return math.max(0, seconds - (afkSeconds or 0))
end

-- XP/h eines gespeicherten Eintrags ({ xp, seconds, counters }: Level, Session, Instanz-Lauf, Summe),
-- nach denselben Regeln wie die Live-Werte. Einträge ohne AFK-Zähler (Zonen) zählen die volle Zeit.
-- Summen (History.Summarize) bringen ratedXp/ratedAfkSeconds mit: nur Einträge mit bekannter Dauer.
function Experience.RecordRate(record)
  local afkSeconds = record.ratedAfkSeconds or (record.counters and record.counters[Stats.AFK_SECONDS])
  return Experience.CalculateRate(record.ratedXp or record.xp, Experience.RateSeconds(record.seconds, afkSeconds))
end

function Experience.GetRatePerHour(scope)
  local afkSeconds = ns.TimeBreakdown.GetSeconds(scope, Stats.AFK_SECONDS)
  return Experience.CalculateRate(Stats.GetXp(scope), Experience.RateSeconds(Stats.GetSeconds(scope), afkSeconds))
end

-- Geschätzte Spielzeit bis zum Level-Up bei der Rate des Bereichs
function Experience.GetSecondsToLevel(scope)
  local rate = Experience.GetRatePerHour(scope)
  if not rate then return nil end
  local remainingXp = UnitXPMax("player") - UnitXP("player")
  return remainingXp / rate * SECONDS_PER_HOUR
end

---------------------------------------------------------------------------
-- Kills bzw. Quests bis zum Level-Up (Roadmap 273). Grundlage ist die Basis-XP (ohne Erholungsbonus) je Kill/Quest:
-- der Schnitt der letzten toLevelSamples Einträge im Journal-Eingang (Kills mit xp/rested aus KillCounter.lua,
-- Quests mit xp), bei 0 oder ohne solche Einträge der Schnitt des Levels (sonst der Session). Kills im Erholungs-Pool
-- (GetXPExhaustion = XP-Spanne, die doppelt zählt) geben das Doppelte; Quests verbrauchen keine Erholung.
---------------------------------------------------------------------------
local KILL_LOG, QUEST_LOG = "killLog", "questLog"
Experience.MIN_TO_LEVEL_SAMPLES = 0   -- 0 = Schnitt des ganzen Levels
Experience.MAX_TO_LEVEL_SAMPLES = 50

local function isPveKill(entry) return entry.kind == ns.Journal.PVE end
local function anyEntry() return true end

-- Schnitt der Basis-XP der neuesten sampleSize Einträge mit XP; nil ohne Einträge
local function recentBaseXp(logName, matches, sampleSize)
  local log = ns.character[logName] or {}
  local sum, count = 0, 0
  for i = #log, 1, -1 do
    local entry = log[i]
    if type(entry.xp) == "number" and entry.xp > 0 and matches(entry) then
      sum = sum + entry.xp - (entry.rested or 0)
      count = count + 1
      if count >= sampleSize then break end
    end
  end
  return count > 0 and sum / count or nil
end

-- Schnitt des Bereichs (Level, sonst Session); bei Kills ohne den dort verbrauchten Erholungsbonus
local function scopeBaseXp(xpCounter, countCounter, withRested)
  for _, scope in ipairs({ Stats.LEVEL, Stats.SESSION }) do
    local count = Stats.Get(scope, countCounter)
    local xp = Stats.Get(scope, xpCounter)
    if withRested then xp = xp - Stats.Get(scope, Stats.XP_RESTED) end
    if count > 0 and xp > 0 then return xp / count end
  end
  return nil
end

-- Anzahl bei Basis-XP je Stück; im Erholungs-Pool zählt jedes Stück doppelt
function Experience.CountForXp(remainingXp, baseXp, restedPool)
  local doubled = math.min(remainingXp, restedPool or 0)
  return math.ceil(doubled / (2 * baseXp) + (remainingXp - doubled) / baseXp)
end

-- Wie viele Kills (countCounter = PVE_KILLS) bzw. Quests (QUESTS) noch bis zum Level-Up fehlen; nil ohne Grundlage
function Experience.CountToLevel(xpCounter, countCounter)
  local isKills = countCounter == Stats.PVE_KILLS
  local sampleSize = ns.db.toLevelSamples or 0
  local baseXp
  if sampleSize > 0 then
    baseXp = recentBaseXp(isKills and KILL_LOG or QUEST_LOG, isKills and isPveKill or anyEntry, sampleSize)
  end
  baseXp = baseXp or scopeBaseXp(xpCounter, countCounter, isKills)
  if not baseXp or baseXp <= 0 then return nil end
  local remainingXp = UnitXPMax("player") - UnitXP("player")
  return Experience.CountForXp(remainingXp, baseXp, isKills and (GetXPExhaustion() or 0) or 0)
end

-- XP-Quellen im Bereich: { kills, quests, explore, gather, other, total }. "Sonstige" ist der Rest (Berufe, Ereignisse, ...).
-- Entdecken und Sammeln zählt XpSources.lua.
function Experience.GetSources(scope)
  local sources = {
    kills = Stats.Get(scope, Stats.XP_KILLS),
    quests = Stats.Get(scope, Stats.XP_QUESTS),
    explore = Stats.Get(scope, Stats.XP_EXPLORE),
    gather = Stats.Get(scope, Stats.XP_GATHER),
  }
  local known = sources.kills + sources.quests + sources.explore + sources.gather
  sources.total = math.max(Stats.GetXp(scope), known)
  sources.other = sources.total - known
  return sources
end

---------------------------------------------------------------------------
-- Gewonnene XP: Differenz zum letzten Stand. Liegt ein Level-Up dazwischen, zählt der Rest des
-- alten Levels, ganze übersprungene Level (aus der XP-Tabelle, sofern bekannt) und die XP auf dem neuen.
-- Ein Level-Up ist erkennbar an einem anderen XP-Bedarf (UnitXPMax), sinkender XP oder einem
-- höheren ns.level. Die Reihenfolge von PLAYER_XP_UPDATE und PLAYER_LEVEL_UP spielt keine Rolle:
-- kam die XP zuerst, gilt das nächste Level schon als erreicht und der Level-Up bucht nichts doppelt.
---------------------------------------------------------------------------
local lastXp, lastXpMax, lastLevel
local gainListeners = {}

-- listener(amount) bei jedem XP-Gewinn (z.B. um geheime Kill-Meldungen ihrer XP zuzuordnen)
function Experience.OnGain(listener)
  gainListeners[#gainListeners + 1] = listener
end

local function notifyGain(amount)
  for _, listener in ipairs(gainListeners) do
    ns.SafeCall(listener, amount)
  end
end

local function skippedLevelsXp(fromLevel, toLevel)
  if toLevel <= fromLevel then return 0 end
  return ns.XpTable and ns.XpTable.XpBetween(fromLevel, toLevel) or 0
end

local function trackXpGained()
  local xp, xpMax = UnitXP("player"), UnitXPMax("player")
  if lastXp then
    local gained
    if xpMax ~= lastXpMax or xp < lastXp or ns.level > lastLevel then
      local newLevel = math.max(ns.level, lastLevel + 1)
      gained = (lastXpMax - lastXp) + skippedLevelsXp(lastLevel + 1, newLevel) + xp
      lastLevel = newLevel
    else
      gained = xp - lastXp
    end
    if gained > 0 then
      Stats.Increment(Stats.XP_GAINED, gained)
      notifyGain(gained)
    end
  end
  lastXp, lastXpMax = xp, xpMax
end

---------------------------------------------------------------------------
-- Erholungs-XP: GetXPExhaustion ist die XP-Spanne, die doppelt zählt; jeder Gewinn darin senkt sie um
-- Grund- plus Bonus-XP (warcraft.wiki.gg, API_GetXPExhaustion). Der Bonus ist also die halbe Abnahme;
-- Zunahmen (Ausruhen) setzen nur die Basis neu.
---------------------------------------------------------------------------
local lastRestedPool

local function restedPool()
  return GetXPExhaustion() or 0
end

local function trackRestedXp()
  local current = restedPool()
  if lastRestedPool and current < lastRestedPool then
    Stats.Increment(Stats.XP_RESTED, math.floor((lastRestedPool - current) / 2 + 0.5))
  end
  lastRestedPool = current
end

ns.OnLogin(function()
  lastXp, lastXpMax, lastLevel = UnitXP("player"), UnitXPMax("player"), ns.level
  lastRestedPool = restedPool()
end)

ns.RegisterEvent("PLAYER_XP_UPDATE", function()
  trackXpGained()
  trackRestedXp()
end)
ns.RegisterEvent("UPDATE_EXHAUSTION", trackRestedXp)
