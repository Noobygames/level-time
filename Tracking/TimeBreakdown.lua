-- Wohin die Spielzeit geht: Kampf, Flugroute, AFK und Leerlauf als Zähler (Sekunden) je Level und Session.
-- Tot zählt DeathCounter (deadSeconds); der Rest (Laufen, Questen, Handeln) ergibt sich aus der
-- Spielzeit des Bereichs minus dieser Anteile (TimeBreakdown.RestOf).
-- Leerlauf (Roadmap 283, Einstellung idleMinutes > 0, nur beim Leveln): länger als die Grenze kein XP-Gewinn und kein
-- Kampf, auch ohne AFK-Flag; die Zeit nach der Grenze zählt als idleSeconds (aktive Zeit = Abstand zum letzten Gewinn,
-- gekappt bei der Grenze).
-- Jede TICK Sekunden wird die Tätigkeit bestimmt (Vorrang: tot > Kampf > Flug > AFK > Leerlauf) und ihre Zeit
-- gesammelt; gebucht wird beim Wechsel, alle FLUSH_INTERVAL Sekunden, beim Level-Up (diese Datei
-- lädt vor History.lua, damit der Historie-Eintrag alles enthält) und beim Logout. Getter rechnen
-- die noch nicht gebuchte Zeit mit ein.
-- APIs in allen Clients: UnitIsDeadOrGhost, UnitAffectingCombat, UnitOnTaxi, UnitIsAFK.
-- Buff-Zeit (Roadmap 485): "Satt" und "Gut erholt" (Schlafsack, Forever) überlappen die Tätigkeiten, darum eigene
-- Zähler (BUFFS) neben PARTS. Gezählt wird nur aktive Zeit (nicht tot, AFK oder im Leerlauf); "ohne Buff" = aktive Zeit
-- minus "mit" (WithoutBuff). Erkennung wie BuffReminder über Lib/Auras.lua; sind die Auren gesperrt (Kampf in
-- Retail/Forever), gilt der zuletzt gelesene Zustand weiter.
local _, ns = ...

local TimeBreakdown = {}
ns.TimeBreakdown = TimeBreakdown

-- Grenzen der Einstellung idleMinutes
TimeBreakdown.MIN_IDLE_MINUTES = 0   -- 0 = kein Leerlauf
TimeBreakdown.MAX_IDLE_MINUTES = 30

ns.RegisterDefaults({
  settings = {
    showTimeBreakdown = false,
    showWellFedTime = false,
    showWellRestedTime = false,
    xpRateWithoutAfk = false,
    idleMinutes = 0,
  },
  ranges = {
    idleMinutes = { TimeBreakdown.MIN_IDLE_MINUTES, TimeBreakdown.MAX_IDLE_MINUTES },
  },
  counters = {
    combatSeconds = 0,
    taxiSeconds = 0,
    afkSeconds = 0,
    idleSeconds = 0,
    wellFedSeconds = 0,
    wellRestedSeconds = 0,
  },
})
local Stats = ns.Stats

local TICK = 1             -- Sekunden zwischen zwei Prüfungen
local FLUSH_INTERVAL = 10  -- Sekunden, nach denen gesammelte Zeit spätestens gebucht wird

-- Zähler, aus denen sich die Aufteilung zusammensetzt (ohne Rest)
TimeBreakdown.PARTS = { Stats.COMBAT_SECONDS, Stats.TAXI_SECONDS, Stats.AFK_SECONDS, Stats.IDLE_SECONDS,
  Stats.DEAD_SECONDS }
-- Nicht aktive Anteile: ohne sie bleibt die aktive Zeit, auf die sich die Buff-Zeit bezieht
local INACTIVE_PARTS = { Stats.AFK_SECONDS, Stats.IDLE_SECONDS, Stats.DEAD_SECONDS }
TimeBreakdown.BUFFS = { Stats.WELL_FED_SECONDS, Stats.WELL_RESTED_SECONDS }
local SECONDS_PER_MINUTE = 60

local activity       -- Zähler der laufenden Tätigkeit, nil = Rest oder tot
local pending = 0    -- Sekunden der laufenden Tätigkeit, noch nicht gebucht
local sinceFlush = 0
local lastActiveAt   -- GetTime() des letzten XP-Gewinns oder Kampfs (Leerlauf)
local counting = false   -- war der Spieler seit der letzten Prüfung aktiv (Buff-Zeit zählt)?
local buffActive = {}    -- Zähler -> zuletzt gelesener Zustand des Buffs
local buffPending = {}   -- Zähler -> Sekunden mit Buff, noch nicht gebucht

-- Geheime Werte (Retail/Forever, z.B. UnitIsAFK während der Chat-Sperre) zuerst ausschließen:
-- schon ein Wahrheitstest auf einen geheimen Wert ist für Addons ein Fehler. Danach nur auf
-- Wahrheit prüfen, nicht auf == true: in Classic sind diese Funktionen nicht dokumentiert (evtl. 1/nil).
local function isTrue(value)
  if ns.IsSecret(value) then return false end
  return value and true or false
end

local function markActive()
  lastActiveAt = GetTime()
end

local function isIdle()
  local minutes = ns.db.idleMinutes or 0
  if minutes <= 0 or not lastActiveAt or not ns.Experience.IsLeveling() then return false end
  return GetTime() - lastActiveAt > minutes * SECONDS_PER_MINUTE
end

local function currentActivity()
  if isTrue(UnitIsDeadOrGhost("player")) then return nil end
  if isTrue(UnitAffectingCombat("player")) then
    markActive()
    return Stats.COMBAT_SECONDS
  end
  if isTrue(UnitOnTaxi("player")) then return Stats.TAXI_SECONDS end
  if isTrue(UnitIsAFK("player")) then return Stats.AFK_SECONDS end
  if isIdle() then return Stats.IDLE_SECONDS end
  return nil
end

-- Buffs lesen (BuffReminder lädt später, wird erst zur Laufzeit gebraucht); nil = gesperrt, Zustand bleibt
local function readBuffs()
  local foodMissing = ns.BuffReminder.IsFoodMissing()
  if foodMissing ~= nil then buffActive[Stats.WELL_FED_SECONDS] = not foodMissing end
  if not ns.BuffReminder.HasSleepingBagSystem() then return end
  local rested = ns.Auras.FindBySpellId(ns.BuffReminder.WELL_RESTED_SPELL_ID)
  if rested ~= nil then buffActive[Stats.WELL_RESTED_SECONDS] = rested ~= false end
end

local function flush()
  -- Zuerst zurücksetzen: scheitert ein Listener, dürfen die Sekunden nicht ein zweites Mal gebucht werden
  local booked, counter, buffs = pending, activity, buffPending
  pending = 0
  sinceFlush = 0
  buffPending = {}
  if counter and booked > 0 then
    Stats.Increment(counter, booked)
  end
  for buff, seconds in pairs(buffs) do Stats.Increment(buff, seconds) end
end

-- Gesammelte Zeit sofort buchen (z.B. wenn der Instanz-Lauf anhält oder weiterläuft, damit nichts davor/danach
-- im falschen Bereich landet)
function TimeBreakdown.Flush()
  flush()
end

-- elapsed Sekunden der bisherigen Tätigkeit zuordnen, dann die Tätigkeit neu bestimmen
function TimeBreakdown.Update(elapsed)
  if activity then pending = pending + elapsed end
  if counting then
    for _, buff in ipairs(TimeBreakdown.BUFFS) do
      if buffActive[buff] then buffPending[buff] = (buffPending[buff] or 0) + elapsed end
    end
  end
  sinceFlush = sinceFlush + elapsed
  local now = currentActivity()
  counting = now ~= Stats.AFK_SECONDS and now ~= Stats.IDLE_SECONDS and not isTrue(UnitIsDeadOrGhost("player"))
  readBuffs()
  if now ~= activity or sinceFlush >= FLUSH_INTERVAL then
    flush()
    activity = now
  end
end

-- Sekunden einer Tätigkeit oder eines Buffs im Bereich, inklusive der noch nicht gebuchten
function TimeBreakdown.GetSeconds(scope, counter)
  if counter == Stats.DEAD_SECONDS then return ns.DeathCounter.GetDeadSeconds(scope) end
  local running = (activity == counter and pending or 0) + (buffPending[counter] or 0)
  return Stats.Get(scope, counter) + (Stats.IsCounting(scope) and running or 0)
end

-- Aktive Zeit ohne den Buff (counter aus BUFFS); nil, solange die Spielzeit unbekannt ist
function TimeBreakdown.WithoutBuff(scope, counter)
  local seconds = Stats.GetSeconds(scope)
  if not seconds then return nil end
  for _, part in ipairs(INACTIVE_PARTS) do seconds = seconds - TimeBreakdown.GetSeconds(scope, part) end
  return math.max(0, seconds - TimeBreakdown.GetSeconds(scope, counter))
end

-- Alle Zähler des Bereichs wie Stats.Snapshot, aber mit der noch nicht gebuchten Zeit der Aufteilung,
-- damit Historie-Zeilen des laufenden Levels/der Session dieselbe Rate zeigen wie das Fenster
function TimeBreakdown.Snapshot(scope)
  local counters = Stats.Snapshot(scope)
  for _, counter in ipairs(TimeBreakdown.PARTS) do
    counters[counter] = TimeBreakdown.GetSeconds(scope, counter)
  end
  for _, counter in ipairs(TimeBreakdown.BUFFS) do
    counters[counter] = TimeBreakdown.GetSeconds(scope, counter)
  end
  return counters
end

-- Rest aus Gesamtzeit und Zählern, auch für Historie-Einträge ({ seconds, counters })
function TimeBreakdown.RestOf(seconds, getPart)
  if not seconds then return nil end
  local rest = seconds
  for _, counter in ipairs(TimeBreakdown.PARTS) do
    rest = rest - getPart(counter)
  end
  return math.max(0, rest)
end

function TimeBreakdown.GetRestSeconds(scope)
  return TimeBreakdown.RestOf(Stats.GetSeconds(scope), function(counter)
    return TimeBreakdown.GetSeconds(scope, counter)
  end)
end

ns.Every(TICK, TimeBreakdown.Update)
ns.Experience.OnGain(markActive)

ns.OnLogin(function()
  activity, pending, sinceFlush, counting, buffActive, buffPending = nil, 0, 0, false, {}, {}
  markActive()
end)
ns.OnLevelCompleted(flush)
ns.OnLogout(flush)
