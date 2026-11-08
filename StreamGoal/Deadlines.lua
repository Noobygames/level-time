-- Fristen (Roadmap 299): jedes Ziel kann bis zu einer Endzeit laufen, in Echtzeit oder in Spielzeit (/played des
-- Charakters, läuft nur, solange er eingeloggt ist). Abgelaufen = Status "gescheitert" (Goals.Fail; bei Arten mit
-- deadlineSucceeds wie Regeln dagegen erreicht), Einblendung und
-- Historie zeigen es. Restzeit auf der Karte (Tracker) und im Fenster.
-- goal.deadline = { mode = "real"|"played", at = Endzeit (time() bzw. /played-Sekunden), seconds = Dauer }
-- Prüfung einmal je Sekunde, nur solange ein laufendes Ziel des Charakters eine Frist hat (LT.Every mit Prädikat).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L

local Deadlines = {}
ns.Deadlines = Deadlines

Deadlines.REAL, Deadlines.PLAYED = "real", "played"
Deadlines.MODES = { Deadlines.REAL, Deadlines.PLAYED }
Deadlines.MODE_LABELS = { real = "SG_FORM_DEADLINE_REAL", played = "SG_FORM_DEADLINE_PLAYED" }
local TICK_SECONDS = 1
local MAX_SECONDS = 365 * 24 * 3600
local SECONDS = { d = 86400, h = 3600, m = 60, s = 1 }
local DEFAULT_UNIT = 60  -- eine Zahl ohne Einheit = Minuten

-- Einheiten der Eingabe: d/h/m/s und die von Level Time in der gewählten Sprache (z.B. "T" für Tage)
local function unitSeconds(letter)
  letter = letter:lower()
  if SECONDS[letter] then return SECONDS[letter] end
  local localized = {
    [L.UNIT_DAY_SHORT:lower()] = SECONDS.d, [L.UNIT_HOUR_SHORT:lower()] = SECONDS.h,
    [L.UNIT_MINUTE_SHORT:lower()] = SECONDS.m, [L.UNIT_SECOND_SHORT:lower()] = SECONDS.s,
  }
  return localized[letter]
end

-- "90" (Minuten), "2h", "1h30m", "3d" -> Sekunden; nil bei ungültiger Eingabe
function Deadlines.ParseDuration(text)
  text = strtrim(text or "")
  if text == "" then return nil end
  if text:match("^%d+$") then return tonumber(text) * DEFAULT_UNIT end
  local total, rest = 0, text
  while rest ~= "" do
    local number, letter, remainder = rest:match("^(%d+)%s*(%a+)%s*(.*)$")
    local factor = letter and unitSeconds(letter)
    if not factor then return nil end
    total = total + tonumber(number) * factor
    rest = remainder
  end
  if total <= 0 or total > MAX_SECONDS then return nil end
  return total
end

-- Jetzt in der Zeitrechnung der Frist; nil, wenn /played noch nicht bekannt ist
local function now(mode)
  if mode == Deadlines.PLAYED then return LT.PlayedTime.GetTotalSeconds() end
  return time()
end

-- Eingabe des Ziels mitführen (Vorlagen und Export legen die Frist wieder an)
local function rememberInput(goal, seconds, mode)
  local extras = goal.source and goal.source.extras
  if not extras then return end
  extras.deadline = seconds and (seconds .. "s") or nil
  extras.deadlineMode = seconds and mode or nil
end

-- Frist setzen (seconds nil = keine Frist mehr)
function Deadlines.Set(goal, seconds, mode)
  if not seconds then
    goal.deadline = nil
    rememberInput(goal, nil)
    return true
  end
  mode = mode == Deadlines.PLAYED and Deadlines.PLAYED or Deadlines.REAL
  local current = now(mode)
  if not current then return false end
  goal.deadline = { mode = mode, at = current + seconds, seconds = seconds }
  rememberInput(goal, seconds, mode)
  LT.RefreshTasks()
  return true
end

-- Restliche Sekunden (nie unter 0) oder nil ohne Frist bzw. unbekannte Spielzeit
function Deadlines.Remaining(goal)
  local deadline = goal.deadline
  if not deadline then return nil end
  local current = now(deadline.mode)
  if not current then return nil end
  return math.max(0, deadline.at - current)
end

-- "noch 1h 12m", "noch 5m 50s" bzw. "noch 2h 05m Spielzeit" (zwei größte Einheiten, passt auf die Karte)
function Deadlines.Text(goal)
  local remaining = Deadlines.Remaining(goal)
  if not remaining then return nil end
  local key = goal.deadline.mode == Deadlines.PLAYED and "SG_DEADLINE_LEFT_PLAYED" or "SG_DEADLINE_LEFT"
  return string.format(L[key], LT.Format.Duration(remaining))
end

-- Hat ein laufendes Ziel des eingeloggten Charakters eine Frist?
function Deadlines.Any()
  if not ns.db then return false end
  for _, goal in ipairs(Goals.Active()) do
    if goal.deadline then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- Zusatz für Goals.Create: extras.deadline (Text, z.B. "2h") und extras.deadlineMode
---------------------------------------------------------------------------
Goals.RegisterExtra("deadline", {
  fields = {
    { type = "text", param = "deadline", label = "SG_FORM_DEADLINE", short = true },
    { type = "choice", param = "deadlineMode", label = "SG_FORM_DEADLINE_MODE", values = Deadlines.MODES,
      labels = Deadlines.MODE_LABELS },
  },
  validate = function(extras)
    if extras.deadline == nil or extras.deadline == "" then return nil end
    if not Deadlines.ParseDuration(extras.deadline) then return L.SG_ERR_DEADLINE end
    if extras.deadlineMode == Deadlines.PLAYED and not now(Deadlines.PLAYED) then return L.SG_ERR_PLAYED_UNKNOWN end
  end,
  apply = function(goal, extras)
    if extras.deadline == nil or extras.deadline == "" then return end
    Deadlines.Set(goal, Deadlines.ParseDuration(extras.deadline), extras.deadlineMode)
  end,
})

---------------------------------------------------------------------------
-- Ablauf prüfen
---------------------------------------------------------------------------
-- Abgelaufene Ziele scheitern; die Liste ist zwischengespeichert, Scheitern baut sie neu (durchlaufene bleibt gleich)
function Deadlines.Check()
  for _, goal in ipairs(Goals.Active()) do
    if goal.status == Goals.ACTIVE and Deadlines.Remaining(goal) == 0 then
      ns.Debug("deadline", "#%s expired", goal.id)
      if Goals.GetKind(goal.kind).deadlineSucceeds then
        Goals.Complete(goal)
      else
        Goals.Fail(goal, L.SG_FAIL_DEADLINE)
      end
    end
  end
end

LT.Every(TICK_SECONDS, Deadlines.Check, Deadlines.Any)
-- Nach dem Login: Echtzeit-Fristen, die während der Abwesenheit abgelaufen sind, sofort
LT.OnLogin(function() LT.RefreshTasks() end)
Goals.OnChange(function(event)
  if event == "added" or event == "changed" then LT.RefreshTasks() end
end)
