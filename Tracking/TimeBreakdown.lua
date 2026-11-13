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
local _, ns = ...

local TimeBreakdown = {}
ns.TimeBreakdown = TimeBreakdown

-- Grenzen der Einstellung idleMinutes
TimeBreakdown.MIN_IDLE_MINUTES = 0   -- 0 = kein Leerlauf
TimeBreakdown.MAX_IDLE_MINUTES = 30

ns.RegisterDefaults({
  settings = {
    showTimeBreakdown = false,
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
  },
})
local Stats = ns.Stats

local TICK = 1             -- Sekunden zwischen zwei Prüfungen
local FLUSH_INTERVAL = 10  -- Sekunden, nach denen gesammelte Zeit spätestens gebucht wird

-- Zähler, aus denen sich die Aufteilung zusammensetzt (ohne Rest)
TimeBreakdown.PARTS = { Stats.COMBAT_SECONDS, Stats.TAXI_SECONDS, Stats.AFK_SECONDS, Stats.IDLE_SECONDS,
  Stats.DEAD_SECONDS }
local SECONDS_PER_MINUTE = 60

local activity       -- Zähler der laufenden Tätigkeit, nil = Rest oder tot
local pending = 0    -- Sekunden der laufenden Tätigkeit, noch nicht gebucht
local sinceFlush = 0
local lastActiveAt   -- GetTime() des letzten XP-Gewinns oder Kampfs (Leerlauf)

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

local function flush()
  -- Zuerst zurücksetzen: scheitert ein Listener, dürfen die Sekunden nicht ein zweites Mal gebucht werden
  local booked, counter = pending, activity
  pending = 0
  sinceFlush = 0
  if counter and booked > 0 then
    Stats.Increment(counter, booked)
  end
end

-- Gesammelte Zeit sofort buchen (z.B. wenn der Instanz-Lauf anhält oder weiterläuft, damit nichts davor/danach
-- im falschen Bereich landet)
function TimeBreakdown.Flush()
  flush()
end

-- elapsed Sekunden der bisherigen Tätigkeit zuordnen, dann die Tätigkeit neu bestimmen
function TimeBreakdown.Update(elapsed)
  if activity then pending = pending + elapsed end
  sinceFlush = sinceFlush + elapsed
  local now = currentActivity()
  if now ~= activity or sinceFlush >= FLUSH_INTERVAL then
    flush()
    activity = now
  end
end

-- Sekunden einer Tätigkeit im Bereich, inklusive der noch nicht gebuchten
function TimeBreakdown.GetSeconds(scope, counter)
  if counter == Stats.DEAD_SECONDS then return ns.DeathCounter.GetDeadSeconds(scope) end
  local running = (activity == counter and Stats.IsCounting(scope)) and pending or 0
  return Stats.Get(scope, counter) + running
end

-- Alle Zähler des Bereichs wie Stats.Snapshot, aber mit der noch nicht gebuchten Zeit der Aufteilung,
-- damit Historie-Zeilen des laufenden Levels/der Session dieselbe Rate zeigen wie das Fenster
function TimeBreakdown.Snapshot(scope)
  local counters = Stats.Snapshot(scope)
  for _, counter in ipairs(TimeBreakdown.PARTS) do
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
  activity, pending, sinceFlush = nil, 0, 0
  markActive()
end)
ns.OnLevelCompleted(flush)
ns.OnLogout(flush)
