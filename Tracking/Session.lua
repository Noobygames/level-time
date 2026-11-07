-- Aktive Session: vom Login bis zum Logout.
-- /reload und kurze Unterbrechungen setzen die Session fort. Beim nächsten echten Login
-- wird die alte Session in die Session-Historie verschoben und eine neue beginnt.
-- Session.StartNew beendet sie sofort (Button in den Einstellungen, /lt newsession).
local _, ns = ...

local Session = {}
ns.Session = Session

local RESUME_GAP_SECONDS = 300   -- kürzere Pausen (z.B. /reload, Disconnect) gehören zur selben Session
local MIN_ARCHIVED_SECONDS = 60  -- kürzere Sessions werden nicht archiviert
local MAX_ARCHIVED_SESSIONS = 200

local loginTime  -- GetTime() beim Login; Zeit seitdem kommt zu currentSession.seconds dazu
local archivedAtLogin = false  -- beim letzten Login wurde die vorige Session archiviert (SessionCompare.lua)
local afterLogout = false      -- der letzte Login kam nach einem echten Logout (nicht /reload, nicht die erste Session)

local function current()
  return ns.character.currentSession
end

function Session.GetSeconds()
  return current().seconds + (GetTime() - loginTime)
end

-- Zeitquelle des Session-Bereichs (Stats.GetSeconds)
ns.Stats.RegisterScope(ns.Stats.SESSION, { seconds = Session.GetSeconds })

-- Historien-Eintrag aus einer beendeten Session (Form wie in History.lua beschrieben)
function Session.ToRecord(session)
  return {
    startedAt = session.startedAt,
    endedAt = session.lastSeen,
    seconds = session.seconds,
    startLevel = session.startLevel,
    endLevel = session.endLevel or session.startLevel,
    xp = session.counters.xpGained or 0,
    counters = session.counters,
  }
end

-- true, wenn die Session in die Historie kam (zu kurze nicht)
local function archive(session)
  if session.seconds < MIN_ARCHIVED_SECONDS then return false end
  local history = ns.character.sessionHistory
  table.insert(history, Session.ToRecord(session))
  while #history > MAX_ARCHIVED_SESSIONS do
    table.remove(history, 1)
  end
  return true
end

-- Hat der letzte Login die vorige Session archiviert? Dann ist sie der letzte Eintrag in sessionHistory.
function Session.ArchivedAtLogin()
  return archivedAtLogin
end

-- Kam der letzte Login nach einem echten Logout? Auch dann, wenn die Session zu kurz für die Historie war
-- (Logout-Zähler der SSF-Regeln, SsfRules.lua)
function Session.LoggedInAfterLogout()
  return afterLogout
end

local function startNew()
  ns.character.currentSession = {
    startedAt = time(),
    seconds = 0,
    startLevel = ns.level,
    endLevel = ns.level,
    counters = ns.Database.NewCounters(),
  }
end

-- true, wenn seit lastSeen (time()) nur eine kurze Pause war wie bei /reload oder Disconnect
-- (auch ChatHistory.lua)
function Session.IsShortGap(lastSeen)
  if type(lastSeen) ~= "number" then return false end
  local gap = time() - lastSeen
  return gap >= 0 and gap <= RESUME_GAP_SECONDS  -- negativ = Systemuhr zurückgestellt
end

local function canResume(session)
  return Session.IsShortGap(session.lastSeen)
end

-- Laufende Zeit in die Session schreiben und den Stand festhalten (Logout oder manuelles Beenden)
local function closeCurrent()
  local session = current()
  session.seconds = Session.GetSeconds()
  session.lastSeen = time()
  session.endLevel = ns.level
  loginTime = GetTime()  -- falls danach noch gelesen wird, nicht doppelt zählen
end

-- Laufende Session archivieren und eine neue beginnen, z.B. zu Stream-Beginn
function Session.StartNew()
  ns.Debug("session", "started new session manually")
  -- Zeitaufteilung (Kampf/AFK/Flug) gehört noch in die alte Session; TimeBreakdown lädt nach dieser Datei
  if ns.TimeBreakdown then ns.TimeBreakdown.Flush() end
  closeCurrent()
  archive(current())
  startNew()
end

-- Für Button und Befehl: neue Session mit Rückmeldung im Chat
function ns.StartNewSession()
  Session.StartNew()
  ns.Print(ns.L.NEW_SESSION_STARTED)
end

ns.OnLogin(function()
  local session = current()
  archivedAtLogin, afterLogout = false, false
  if not session.startedAt then
    ns.Debug("session", "first session")
    startNew()
  elseif not canResume(session) then
    ns.Debug("session", "archived previous session (%s s), new session", session.seconds)
    archivedAtLogin = archive(session)
    afterLogout = true
    startNew()
  else
    ns.Debug("session", "resumed session (gap %s s)", time() - session.lastSeen)
  end
  loginTime = GetTime()
end)

ns.OnLevelStarted(function(newLevel)
  current().endLevel = newLevel
end)

---------------------------------------------------------------------------
-- XP-Verlauf: gewonnene XP je Abschnitt der Session (currentSession.xpTimeline[abschnitt]).
-- Nur für die laufende Session; archivierte Sessions behalten ihn nicht (spart Platz).
---------------------------------------------------------------------------
Session.TIMELINE_STEP = 300  -- Sekunden je Abschnitt

ns.Stats.OnIncrement(function(counter, amount)
  if counter ~= ns.Stats.XP_GAINED or not loginTime then return end
  local session = current()
  session.xpTimeline = session.xpTimeline or {}
  local step = math.floor(Session.GetSeconds() / Session.TIMELINE_STEP) + 1
  session.xpTimeline[step] = (session.xpTimeline[step] or 0) + amount
end)

ns.OnLogout(closeCurrent)
