-- Pausen-Erinnerung (Roadmap 263, Einstellung remindBreak, Standard aus): nach breakMinutes Minuten Spielzeit in der
-- Session ohne Pause eine Karte "Kurze Pause?" (wie Plumber BreakTime). Nicht im Kampf und nicht in Instanzen; die
-- Karte wartet, bis beides vorbei ist.
-- Spielzeit ohne Pause = Session-Zeit (Session.GetSeconds) minus AFK-Zeit der Session (TimeBreakdown) minus Stand
-- bei der letzten Pause (currentSession.breakBaseline, übersteht /reload). Als Pause zählt: AFK am Stück mindestens
-- AFK_BREAK_SECONDS (dann beginnt die Zählung neu), eine neue Session (Logout länger als die Session-Lücke) und die
-- Erinnerung selbst (nächste nach weiteren breakMinutes).
local _, ns = ...
local L = ns.L
local Stats = ns.Stats

local BreakReminder = {}
ns.BreakReminder = BreakReminder

BreakReminder.MIN_MINUTES = 15   -- Grenzen des Reglers
BreakReminder.MAX_MINUTES = 240
local CHECK_SECONDS = 5
local AFK_BREAK_SECONDS = 300
local SECONDS_PER_MINUTE = 60

local afkSince  -- GetTime() seit dem der Spieler am Stück AFK ist

-- Spielzeit der Session ohne AFK-Zeit
function BreakReminder.ActiveSeconds()
  return ns.Session.GetSeconds() - ns.TimeBreakdown.GetSeconds(Stats.SESSION, Stats.AFK_SECONDS)
end

-- Sekunden seit der letzten Pause
function BreakReminder.SecondsSinceBreak()
  return BreakReminder.ActiveSeconds() - (ns.character.currentSession.breakBaseline or 0)
end

local function takeBreak(reason)
  ns.Debug("reminders", "break counted (%s)", reason)
  ns.character.currentSession.breakBaseline = BreakReminder.ActiveSeconds()
end

local function isAfk()
  local afk = UnitIsAFK("player")
  return not ns.IsSecret(afk) and afk and true or false
end

local function canShow()
  return not ns.InCombat() and not IsInInstance()
end

function BreakReminder.Check()
  if not ns.db.remindBreak then return end
  if isAfk() then
    afkSince = afkSince or GetTime()
    if GetTime() - afkSince >= AFK_BREAK_SECONDS then takeBreak("afk") end
    return
  end
  afkSince = nil
  local played = BreakReminder.SecondsSinceBreak()
  if played < ns.db.breakMinutes * SECONDS_PER_MINUTE or not canShow() then return end
  takeBreak("reminder")
  local text = string.format(L.BREAK_REMINDER, ns.Format.Duration(played))
  ns.Alerts.Notify({ title = L.NOTICE_BREAK, text = text, icon = ns.Alerts.ICONS.rest }, ns.Alerts.REMINDER_COLOR)
end

ns.Every(CHECK_SECONDS, BreakReminder.Check)
ns.OnLogin(function() afkSince = nil end)
