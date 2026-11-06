-- Testbefehle für die Fehlersuche: /lt debug <befehl>. Lösen Addon-Funktionen von Hand aus oder
-- zeigen den inneren Zustand, ohne gespeicherte Statistiken zu verändern. /lt debug ohne Befehl
-- schaltet das erweiterte Logging (ns.Debug) an und aus.
-- Ausgaben sind technische Zeilen (ns.DebugPrint, englisch); nur die Hilfe ist übersetzt.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format

local DebugTools = {}
ns.DebugTools = DebugTools

local function out(area, format, ...)
  ns.DebugPrint(area, format, ...)
end

local function seconds(value)
  return value and Format.Duration(value) or "-"
end

local function delta(value)
  return value and Format.SignedDuration(value) or "-"
end

local actions = {}

-- Überblick über Charakter, Spielzeit, Session, Splits, Ziel und Stream-Modus
function actions.state()
  out("core", "%s level %s, interface %s, forever %s", ns.characterKey, ns.level,
    ns.Client.GetInterfaceVersion(), ns.Client.IsForever())
  out("played", "total %s, level %s", seconds(ns.PlayedTime.GetTotalSeconds()),
    seconds(ns.PlayedTime.GetLevelSeconds()))
  out("level", "time %s, xp %s, xp/h %s", seconds(Stats.GetSeconds(Stats.LEVEL)), Stats.GetXp(Stats.LEVEL),
    ns.Experience.GetRatePerHour(Stats.LEVEL) or "-")
  out("session", "time %s, xp %s, started %s, archived %s", seconds(Stats.GetSeconds(Stats.SESSION)),
    Stats.GetXp(Stats.SESSION), ns.character.currentSession.startedAt, #ns.character.sessionHistory)
  out("splits", "comparison %s, level %s, total %s", ns.db.splitComparison,
    delta(ns.Splits.GetCurrentDelta()), delta(ns.Splits.GetTotalDelta()))
  local goal = ns.Goal.Get()
  out("goal", "%s", goal and string.format("level %d, progress %.2f, left %s", goal.level,
    ns.Goal.GetProgress(), seconds(ns.Goal.GetSecondsLeft())) or "none")
  out("death", "since last death %s", seconds(ns.DeathCounter.GetSecondsSinceDeath()))
  out("stream", "mode %s, privacy %s, background %s", ns.StreamMode.IsEnabled(), ns.db.streamerPrivacy,
    ns.db.windowBackground)
end

-- Level-Up-Zusammenfassung und Ansage des laufenden Levels, als wäre es geschafft
function actions.levelup()
  ns.LevelUpSummary.Preview()
  ns.Alerts.ShowSample("levelUp")
  ns.LevelUpWindow.Preview()
end

-- /lt debug alert <art>: Beispiel-Einblendung, auch wenn die Art ausgeschaltet ist
-- Arten ohne Groß-/Kleinschreibung (die Eingabe kommt kleingeschrieben an, die Schlüssel sind z.B. levelUp)
function actions.alert(kind)
  for name in pairs(ns.Alerts.KINDS) do
    if name:lower() == kind and ns.Alerts.ShowSample(name) then return end
  end
  local kinds = {}
  for name in pairs(ns.Alerts.KINDS) do table.insert(kinds, name) end
  table.sort(kinds)
  out("alert", "kinds: %s", table.concat(kinds, ", "))
end

-- Stand der Buff-Hinweise; nil = nicht feststellbar
function actions.remind()
  local BuffReminder = ns.BuffReminder
  out("reminder", "food missing %s (on %s), camp missing %s (on %s, camp system %s)",
    BuffReminder.IsFoodMissing(), ns.db.remindFood, BuffReminder.IsCampMissing(), ns.db.remindCamp,
    BuffReminder.HasCampSystem())
  out("reminder", "charged missing %s (on %s, skyborne %s)",
    BuffReminder.IsChargedMissing(), ns.db.remindCharged, BuffReminder.IsSkyborne())
  out("reminder", "worth reminding now %s (leveling, no combat, alive, not resting)",
    BuffReminder.WorthReminding())
end

-- Todesursache, die ein Tod jetzt bekäme: letzter Treffer aus dem Kampflog und Death Recap
function actions.death()
  local hit = ns.DeathCounter.PeekLastHit()
  out("death", "last hit: %s / %s / %s", hit.killer, hit.spell, hit.environment)
  local recap = ns.DeathRecap.GetLastCause()
  out("death", "death recap (available %s): %s", ns.DeathRecap.IsAvailable(),
    recap and string.format("%s / %s / %s", tostring(recap.killer), tostring(recap.spell),
      tostring(recap.environment)) or "none")
end

-- Vergleichszeiten der Splits für die letzten Level
function actions.splits()
  for level = ns.level, math.max(1, ns.level - 4), -1 do
    local record = ns.character.levelHistory[level]
    out("splits", "level %s: own %s, reference %s, delta %s", level,
      seconds(level == ns.level and Stats.GetSeconds(Stats.LEVEL) or record and record.seconds),
      seconds(ns.Splits.GetReference(level)),
      delta(level == ns.level and ns.Splits.GetCurrentDelta() or ns.Splits.GetLevelDelta(level)))
  end
end

-- Dauerhaftes Debug-Log (DebugLog.lua): an/aus, clear, status
function actions.log(argument)
  ns.DebugLog.Command(argument)
end

-- Alle Prüfungen (DebugLog.CHECKS) einmal ausführen und ins Debug-Log schreiben
function actions.check()
  ns.DebugLog.CheckCommand()
end

function actions.help()
  ns.Print(L.DEBUG_HELP)
end

-- /lt debug <befehl> [argument]
function DebugTools.Run(input)
  local name, argument = input:match("^(%S*)%s*(.-)$")
  local action = actions[name:lower()] or actions.help
  action(argument:lower())
end
