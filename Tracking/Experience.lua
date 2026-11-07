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

-- Spielzeit, auf die sich Raten und Prognosen beziehen: ohne AFK-Zeit (xpRateWithoutAfk) und ohne Leerlauf
-- (idleMinutes > 0), wenn eingestellt; beide Zeiten aus TimeBreakdown.lua. Auch für Historie-Einträge.
function Experience.RateSeconds(seconds, afkSeconds, idleSeconds)
  if not seconds or not ns.db then return seconds end
  local rated = seconds
  if ns.db.xpRateWithoutAfk then rated = rated - (afkSeconds or 0) end
  if (ns.db.idleMinutes or 0) > 0 then rated = rated - (idleSeconds or 0) end
  return math.max(0, rated)
end

-- Spielzeit eines Eintrags ({ seconds, counters }) für Raten, siehe RateSeconds
function Experience.RecordRateSeconds(record)
  local counters = record.counters or {}
  return Experience.RateSeconds(record.seconds, record.ratedAfkSeconds or counters[Stats.AFK_SECONDS],
    record.ratedIdleSeconds or counters[Stats.IDLE_SECONDS])
end

-- XP/h eines gespeicherten Eintrags ({ xp, seconds, counters }: Level, Session, Instanz-Lauf, Summe),
-- nach denselben Regeln wie die Live-Werte. Einträge ohne AFK-Zähler (Zonen) zählen die volle Zeit.
-- Summen (History.Summarize) bringen ratedXp/ratedAfkSeconds/ratedIdleSeconds mit: nur Einträge mit bekannter Dauer.
function Experience.RecordRate(record)
  return Experience.CalculateRate(record.ratedXp or record.xp, Experience.RecordRateSeconds(record))
end

-- Spielzeit des Bereichs für Raten (ohne AFK/Leerlauf, wenn eingestellt)
function Experience.ScopeRateSeconds(scope)
  local TimeBreakdown = ns.TimeBreakdown
  return Experience.RateSeconds(Stats.GetSeconds(scope), TimeBreakdown.GetSeconds(scope, Stats.AFK_SECONDS),
    TimeBreakdown.GetSeconds(scope, Stats.IDLE_SECONDS))
end

function Experience.GetRatePerHour(scope)
  return Experience.CalculateRate(Stats.GetXp(scope), Experience.ScopeRateSeconds(scope))
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
local MATCHERS = { [KILL_LOG] = isPveKill, [QUEST_LOG] = anyEntry }  -- welche Einträge je Log zählen

-- Basis-XP der neuesten passenden Einträge je Log, neueste zuerst gelesen: ein Ring aus höchstens
-- MAX_TO_LEVEL_SAMPLES Werten. Die Zeilen fragen viermal je Sekunde; statt jedes Mal den Eingang rückwärts zu
-- durchsuchen (bei vielen Einträgen ohne XP bis zu 20000), kommen neue Einträge hinten dazu. Liegt der Eingang nicht
-- mehr so vor wie beim letzten Lesen (anderer Charakter, gekürzt, umgezogen), wird der Ring einmal neu gefüllt.
local recent = {}  -- [logName] = { log, count, last, values, head, size }

local function baseXpOf(entry, matches)
  if type(entry.xp) == "number" and entry.xp > 0 and matches(entry) then return entry.xp - (entry.rested or 0) end
  return nil
end

local function push(ring, value)
  ring.head = ring.head % Experience.MAX_TO_LEVEL_SAMPLES + 1
  ring.values[ring.head] = value
  ring.size = math.min(ring.size + 1, Experience.MAX_TO_LEVEL_SAMPLES)
end

-- Ring aus dem Eingang neu füllen: die neuesten passenden Einträge, in Reihenfolge älteste zuerst eingereiht
local function refill(ring, log, matches)
  local found = {}
  for i = #log, 1, -1 do
    local value = baseXpOf(log[i], matches)
    if value then
      found[#found + 1] = value
      if #found >= Experience.MAX_TO_LEVEL_SAMPLES then break end
    end
  end
  ring.values, ring.head, ring.size = {}, 0, 0
  for i = #found, 1, -1 do push(ring, found[i]) end
end

local function ringFor(logName, matches)
  local log = ns.character[logName] or {}
  local ring = recent[logName]
  local count = #log
  if ring and ring.log == log and count >= ring.count and (ring.count == 0 or log[ring.count] == ring.last) then
    for i = ring.count + 1, count do
      local value = baseXpOf(log[i], matches)
      if value then push(ring, value) end
    end
  else
    ring = { log = log }
    recent[logName] = ring
    refill(ring, log, matches)
  end
  ring.count, ring.last = count, log[count]
  return ring
end

-- Schnitt der Basis-XP der neuesten sampleSize (höchstens MAX_TO_LEVEL_SAMPLES) Einträge mit XP im Eingang von
-- logName (killLog: nur PvE, questLog); nil ohne Einträge
function Experience.RecentBaseXp(logName, sampleSize)
  local ring = ringFor(logName, MATCHERS[logName])
  local count = math.min(sampleSize, ring.size)
  local sum, index = 0, ring.head
  for _ = 1, count do  -- neueste zuerst, wie früher beim Rückwärtslesen des Eingangs
    sum = sum + ring.values[index]
    index = index - 1
    if index < 1 then index = Experience.MAX_TO_LEVEL_SAMPLES end
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
    sampleSize = math.min(sampleSize, Experience.MAX_TO_LEVEL_SAMPLES)
    baseXp = Experience.RecentBaseXp(isKills and KILL_LOG or QUEST_LOG, sampleSize)
  end
  baseXp = baseXp or scopeBaseXp(xpCounter, countCounter, isKills)
  if not baseXp or baseXp <= 0 then return nil end
  local remainingXp = UnitXPMax("player") - UnitXP("player")
  return Experience.CountForXp(remainingXp, baseXp, isKills and (GetXPExhaustion() or 0) or 0)
end

-- XP-Quellen im Bereich: { kills, quests, explore, gather, other, total }. "Sonstige" ist der Rest (Berufe, Ereignisse, ...).
-- Entdecken und Sammeln zählt XpSources.lua.
local function getSources(scope)
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
-- Im Anzeige-Takt (TickCache) je Bereich einmal; die fünf Zeilen der XP-Quellen teilen sich die Tabelle (nicht ändern)
Experience.GetSources = ns.TickCache.Memo(getSources)

---------------------------------------------------------------------------
-- Gewonnene XP: Differenz zum letzten Stand. Liegt ein Level-Up dazwischen, zählt der Rest des
-- alten Levels, ganze übersprungene Level (aus der XP-Tabelle, sofern bekannt) und die XP auf dem neuen.
-- Ein Level-Up ist erkennbar an einem anderen XP-Bedarf (UnitXPMax), sinkender XP oder einem
-- höheren ns.level. Die Reihenfolge von PLAYER_XP_UPDATE und PLAYER_LEVEL_UP spielt keine Rolle:
-- kam die XP zuerst, gilt das nächste Level schon als erreicht und der Level-Up bucht nichts doppelt.
---------------------------------------------------------------------------
local lastXp, lastXpMax, lastLevel
local gainListeners = {}
-- Zuletzt gesehener XP-Bedarf je Level. Beim Level-Up kann UnitXPMax schon den Bedarf des neuen Levels liefern,
-- wenn PLAYER_XP_UPDATE vor PLAYER_LEVEL_UP kam; der Historie-Eintrag braucht aber den des alten.
local xpMaxByLevel = {}

-- XP-Bedarf von level, wie zuletzt gesehen; ohne Beobachtung UnitXPMax (Bedarf des aktuellen Levels)
function Experience.XpMaxOf(level)
  return xpMaxByLevel[level] or UnitXPMax("player")
end

-- listener(amount) bei jedem XP-Gewinn (z.B. um geheime Kill-Meldungen ihrer XP zuzuordnen)
function Experience.OnGain(listener)
  ns.RememberSource(listener, "Experience.lua")
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
      xpMaxByLevel[lastLevel] = lastXpMax
      lastLevel = newLevel
    else
      gained = xp - lastXp
    end
    xpMaxByLevel[lastLevel] = xpMax
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
  xpMaxByLevel = { [lastLevel] = lastXpMax }
  lastRestedPool = restedPool()
end)

ns.RegisterEvent("PLAYER_XP_UPDATE", function()
  trackXpGained()
  trackRestedXp()
end)
ns.RegisterEvent("UPDATE_EXHAUSTION", trackRestedXp)
