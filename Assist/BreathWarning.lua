-- Atem-Warnung (Roadmap 255, Einstellung warnBreath, Standard aus): unter Wasser (Leiste "Atem") und in der
-- Erschöpfungszone (Leiste "Erschöpfung") eine Karte, der Raid-Warnton und das Blinken in der Taskleiste
-- (FlashClientIcon, wo es das gibt), sobald weniger als breathWarnSeconds Sekunden übrig sind. Für Hardcore wertvoll.
-- Quelle wie Blizzards MirrorTimer (alle Clients, MirrorTimerDocumentation):
--   MIRROR_TIMER_START(timer, value, maxValue, scale, paused, label)  value in ms, scale < 0 = läuft ab
--                      (Debug-Log Forever: Abtauchen -1, Auftauchen +10 = füllt sich wieder)
--   MIRROR_TIMER_STOP(timer), MIRROR_TIMER_PAUSE(timer, paused)
--   GetMirrorTimerProgress(timer)   Rest in ms; direkt nach START im Debug-Log noch 0, dann zählt die Schätzung
--                                   aus dem Startwert (value / 1000 + scale * vergangene Sekunden)
--   GetMirrorTimerInfo(index)       nach /reload unter Wasser (PLAYER_ENTERING_WORLD), Name "UNKNOWN" = frei
-- Je Abtauchen eine Warnung; wieder scharf, wenn die Leiste über der Schwelle neu startet. Geheime Werte = keine.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    warnBreath = false,
    breathWarnSeconds = 15,
  },
  ranges = {
    breathWarnSeconds = { 5, 30 },
  },
})
local L = ns.L

local BreathWarning = {}
ns.BreathWarning = BreathWarning

BreathWarning.MIN_SECONDS = 5   -- Grenzen des Reglers
BreathWarning.MAX_SECONDS = 30
local CHECK_SECONDS = 0.5
local MS_PER_SECOND = 1000
local TIMER_SLOTS = 3           -- MIRRORTIMER_NUMTIMERS
local FREE_SLOT = "UNKNOWN"

-- Beobachtete Leisten: Texte und Symbol der Warnung
local TIMERS = {
  BREATH = { title = "NOTICE_BREATH", text = "WARN_BREATH", icon = "breath" },
  EXHAUSTION = { title = "NOTICE_FATIGUE", text = "WARN_FATIGUE", icon = "fatigue" },
}

local running = {}  -- [timer] = { value (s), scale, startedAt, paused, warned }

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function start(timer, value, scale, paused)
  timer, value, scale, paused = readable(timer), readable(value), readable(scale), readable(paused)
  if not TIMERS[timer] then return end
  if type(value) ~= "number" or type(scale) ~= "number" or scale >= 0 then
    running[timer] = nil  -- füllt sich wieder (aufgetaucht) oder unlesbar
    return
  end
  local seconds = value / MS_PER_SECOND
  local previous = running[timer]
  running[timer] = {
    value = seconds, scale = scale, startedAt = GetTime(), paused = type(paused) == "number" and paused > 0,
    warned = previous ~= nil and previous.warned and seconds <= ns.db.breathWarnSeconds,
  }
  ns.Debug("warnings", "mirror timer %s: %s s, scale %s", timer, seconds, scale)
end

-- Restsekunden einer laufenden Leiste
function BreathWarning.Remaining(timer)
  local entry = running[timer]
  if not entry then return nil end
  local progress = GetMirrorTimerProgress and readable(GetMirrorTimerProgress(timer))
  if type(progress) == "number" and progress > 0 then return progress / MS_PER_SECOND end
  if entry.paused then return entry.value end
  return math.max(0, entry.value + entry.scale * (GetTime() - entry.startedAt))
end

local function warn(timer, remaining)
  local texts = TIMERS[timer]
  local text = string.format(L[texts.text], math.ceil(remaining))
  ns.Debug("warnings", "%s low: %s s", timer, remaining)
  ns.Alerts.Show(text, ns.Alerts.WARNING_COLOR, { immediate = true,
    notice = { icon = ns.Alerts.ICONS[texts.icon], title = L[texts.title], body = text } })
  ns.Alerts.PlaySound()
  if FlashClientIcon then FlashClientIcon() end
end

-- Vorschau (Testen-Knopf): Atemwarnung beim eingestellten Wert
function BreathWarning.Preview()
  warn("BREATH", ns.db.breathWarnSeconds)
end

function BreathWarning.Check()
  if not ns.db.warnBreath then return end
  for timer, entry in pairs(running) do
    local remaining = BreathWarning.Remaining(timer)
    if not entry.warned and remaining and remaining <= ns.db.breathWarnSeconds then
      entry.warned = true
      warn(timer, remaining)
    end
  end
end

ns.RegisterEvent("MIRROR_TIMER_START", function(timer, value, _, scale, paused)
  start(timer, value, scale, paused)
end)

ns.RegisterEvent("MIRROR_TIMER_STOP", function(timer)
  timer = readable(timer)
  if timer then running[timer] = nil end
end)

ns.RegisterEvent("MIRROR_TIMER_PAUSE", function(timer, paused)
  local entry = running[readable(timer)]
  paused = readable(paused)
  if not entry or type(paused) ~= "number" then return end
  entry.value, entry.startedAt = BreathWarning.Remaining(timer), GetTime()
  entry.paused = paused > 0
end)

-- Nach /reload unter Wasser kommt kein neues START: laufende Leisten wie Blizzard beim Betreten der Welt lesen
ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
  if not GetMirrorTimerInfo then return end
  for index = 1, TIMER_SLOTS do
    local timer, value, _, scale, paused = GetMirrorTimerInfo(index)
    if readable(timer) and timer ~= FREE_SLOT then start(timer, value, scale, paused) end
  end
end)

ns.Every(CHECK_SECONDS, BreathWarning.Check, function(db) return db.warnBreath end)
ns.OnLogin(function() running = {} end)
