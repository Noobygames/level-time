-- Wiederkehrende Ziele (Roadmap 310): Zusatz "täglich" oder "wöchentlich" (ab Montag) für jedes Ziel. Endet der
-- Zeitraum, legt Level Time Goals das Ziel neu an (aus goal.source); ein im Zeitraum nicht erreichtes Ziel scheitert
-- ("Zeitraum vorbei"). Serie = wie viele Zeiträume in Folge erreicht (goal.recur.streak, beste Serie in best); ein
-- verpasster Zeitraum setzt sie auf 0. Tage über Daily.StartOfDay/AddDays/DayKey von Level Time (Ortszeit,
-- Mitternacht, Zeitumstellung beachtet). Prüfung beim Login und einmal je Minute, solange ein solches Ziel existiert.
-- goal.recur = { period = "daily"|"weekly", key = Zeitraum-Schlüssel, streak, best, renewed = true (Nachfolger da) }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L

local Recurring = {}
ns.Recurring = Recurring

Recurring.NONE, Recurring.DAILY, Recurring.WEEKLY = "none", "daily", "weekly"
Recurring.PERIODS = { Recurring.NONE, Recurring.DAILY, Recurring.WEEKLY }
Recurring.LABELS = { none = "SG_FORM_REPEAT_NONE", daily = "SG_FORM_REPEAT_DAILY", weekly = "SG_FORM_REPEAT_WEEKLY" }
local CHECK_SECONDS = 60
local DAYS_PER_WEEK = 7
local MONDAY_OFFSET = 5  -- date("*t").wday: Sonntag = 1; (wday + 5) % 7 = Tage seit Montag

local Daily = LT.Daily

-- Beginn des Zeitraums, in dem timestamp liegt
local function periodStart(period, timestamp)
  local start = Daily.StartOfDay(timestamp)
  if period == Recurring.WEEKLY then
    local weekday = date("*t", timestamp).wday
    start = Daily.AddDays(start, -((weekday + MONDAY_OFFSET) % DAYS_PER_WEEK))
  end
  return start
end

function Recurring.Key(period, timestamp)
  return Daily.DayKey(periodStart(period, timestamp or time()))
end

-- Schlüssel des Zeitraums direkt davor
local function previousKey(period, timestamp)
  local start = periodStart(period, timestamp or time())
  return Daily.DayKey(Daily.AddDays(start, period == Recurring.WEEKLY and -DAYS_PER_WEEK or -1))
end

-- "Täglich · Serie 3"
function Recurring.Text(goal)
  local recur = goal.recur
  if not recur then return nil end
  return string.format(L.SG_REPEAT_LINE, L[Recurring.LABELS[recur.period]], recur.streak or 0)
end

---------------------------------------------------------------------------
-- Zusatz für Goals.Create: extras.repeatPeriod
---------------------------------------------------------------------------
Goals.RegisterExtra("repeat", {
  fields = {
    { type = "choice", param = "repeatPeriod", label = "SG_FORM_REPEAT", values = Recurring.PERIODS,
      labels = Recurring.LABELS },
  },
  validate = function(extras)
    local period = extras.repeatPeriod
    if period ~= nil and not Recurring.LABELS[period] then return L.SG_ERR_REPEAT end
  end,
  apply = function(goal, extras)
    local period = extras.repeatPeriod
    if period == nil or period == Recurring.NONE then return end
    goal.recur = { period = period, key = Recurring.Key(period), streak = 0, best = 0 }
  end,
  line = function(goal) return Recurring.Text(goal) end,
})

-- Wiederholung eines laufenden Ziels setzen oder entfernen (Befehl /sg repeat); Rückgabe: true bei bekanntem Zeitraum
function Recurring.Set(goal, period)
  if not Recurring.LABELS[period] then return false end
  if goal.source then goal.source.extras.repeatPeriod = period ~= Recurring.NONE and period or nil end
  if period == Recurring.NONE then
    goal.recur = nil
  else
    local recur = goal.recur or { streak = 0, best = 0 }
    recur.period, recur.key = period, Recurring.Key(period)
    goal.recur = recur
  end
  LT.RefreshTasks()
  return true
end

---------------------------------------------------------------------------
-- Serie und Erneuern
---------------------------------------------------------------------------
-- Erreicht: Serie +1 (Vorgänger im Zeitraum davor erreicht -> streak schon übernommen)
Goals.OnChange(function(event, goal)
  if event ~= "done" or not goal or not goal.recur then return end
  local recur = goal.recur
  recur.streak = (recur.streak or 0) + 1
  recur.best = math.max(recur.best or 0, recur.streak)
  ns.Debug("recurring", "#%s done, streak %s", goal.id, recur.streak)
end)

-- Nachfolger im neuen Zeitraum; Serie bleibt, wenn der Vorgänger im direkt vorigen Zeitraum erreicht wurde
local function renew(goal, currentKey)
  local recur = goal.recur
  recur.renewed = true
  local source = goal.source
  if not source then return end
  local keepStreak = goal.status == Goals.DONE and recur.key == previousKey(recur.period)
  local next = Goals.Create(goal.kind, Goals.CopyFlat(source.params), source.target, Goals.CopyFlat(source.extras))
  if not next or not next.recur then return end
  next.recur.key = currentKey
  next.recur.streak = keepStreak and recur.streak or 0
  next.recur.best = recur.best or 0
  ns.Debug("recurring", "#%s renewed as #%s, streak %s", goal.id, next.id, next.recur.streak)
  Goals.Changed(next)
end

-- Ziele des Charakters, deren Zeitraum vorbei ist: laufende scheitern, dann neu anlegen (Liste vorher sammeln)
function Recurring.Check()
  if not ns.db then return end
  local due = {}
  for _, goal in ipairs(ns.db.goals) do
    local recur = goal.recur
    if recur and not recur.renewed and goal.character == LT.characterKey and goal.status ~= Goals.CANCELLED
      and recur.key ~= Recurring.Key(recur.period) then
      table.insert(due, goal)
    end
  end
  for _, goal in ipairs(due) do
    if goal.status == Goals.ACTIVE then Goals.Fail(goal, L.SG_FAIL_PERIOD) end
    renew(goal, Recurring.Key(goal.recur.period))
  end
end

-- Läuft (oder wartet) ein wiederkehrendes Ziel des Charakters?
function Recurring.Any()
  if not ns.db then return false end
  for _, goal in ipairs(Goals.Active()) do
    if goal.recur then return true end
  end
  for _, goal in ipairs(ns.db.goals) do
    if goal.recur and not goal.recur.renewed and goal.character == LT.characterKey then return true end
  end
  return false
end

LT.Every(CHECK_SECONDS, Recurring.Check, Recurring.Any)
LT.OnLogin(function() Recurring.Check() end)
Goals.OnChange(function(event)
  if event == "added" then LT.RefreshTasks() end
end)
