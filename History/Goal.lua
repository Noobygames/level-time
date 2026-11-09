-- Session-Ziel: ein Ziel-Level (z.B. "Level 30 bis Stream-Ende") mit Fortschritt und Prognose.
-- Gespeichert je Charakter in character.goal = { level, startProgress, reached }, bleibt über
-- Sessions bestehen, bis es ersetzt oder entfernt wird. Fortschritt in Level-Bruchteilen
-- (Level + XP-Anteil), weil der XP-Bedarf künftiger Level vorab nicht bekannt ist.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showGoal = false,
  },
})
local L = ns.L

local Goal = {}
ns.Goal = Goal

-- Aktuelles Level plus Anteil der XP darin, z.B. 12.5 = Level 12 halb geschafft
local function levelProgress()
  local xpMax = UnitXPMax("player")
  local fraction = xpMax > 0 and UnitXP("player") / xpMax or 0
  return ns.level + fraction
end

local function maxLevel()
  return GetMaxPlayerLevel and GetMaxPlayerLevel() or math.huge
end

function Goal.Get()
  return ns.character.goal
end

-- false, wenn das Level nicht über dem aktuellen oder über dem Max-Level liegt
-- Nur ganze Level über dem aktuellen bis zum Max-Level
function Goal.Set(level)
  if type(level) ~= "number" or level ~= math.floor(level) then return false end
  if level <= ns.level or level > maxLevel() then return false end
  ns.character.goal = { level = level, startProgress = levelProgress() }
  return true
end

function Goal.Clear()
  ns.character.goal = nil
end

-- Anteil 0..1 des Wegs vom Setzen des Ziels bis zum Ziel-Level
function Goal.GetProgress()
  local goal = Goal.Get()
  if not goal then return nil end
  if goal.reached then return 1 end
  local span = goal.level - goal.startProgress
  if span <= 0 then return 1 end
  return math.max(0, math.min(1, (levelProgress() - goal.startProgress) / span))
end

-- Geschätzte Spielzeit bis zum Ziel; nil ohne Ziel oder Schätzung
function Goal.GetSecondsLeft()
  local goal = Goal.Get()
  if not goal or goal.reached then return nil end
  return ns.Forecast.SecondsToLevel(goal.level)
end

-- Das Ziel-Level kann auch ohne Level-Up-Ereignis erreicht worden sein (anderer Client, Addon aus)
ns.OnLogin(function()
  local goal = Goal.Get()
  if goal and not goal.reached and ns.level >= goal.level then goal.reached = true end
end)

ns.OnLevelStarted(function(newLevel)
  local goal = Goal.Get()
  if goal and not goal.reached and newLevel >= goal.level then
    goal.reached = true
    ns.Print(string.format(L.GOAL_REACHED, goal.level))
    if ns.ObsSignal then ns.ObsSignal.Trigger("goal") end
  end
end)
