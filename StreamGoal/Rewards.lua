-- Belohnung und Punkte (Roadmap 308): Zusatz jedes Ziels. Belohnung = freier Text ("Zuschauer wählen die nächste
-- Zone") auf Karte und Einblendung beim Erreichen; Punkte = Zahl je Ziel, erreichte Ziele ergeben eine Gesamtpunktzahl
-- (Historie, /sg points). goal.reward, goal.points
local _, ns = ...
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Rewards = {}
ns.Rewards = Rewards

Rewards.MAX_POINTS = 10000

-- "Belohnung: ... · 10 Punkte" oder nil
function Rewards.Line(goal)
  local parts = {}
  if goal.reward then table.insert(parts, string.format(L.SG_REWARD_LINE, goal.reward)) end
  if goal.points then table.insert(parts, string.format(L.SG_POINTS_LINE, goal.points)) end
  if #parts == 0 then return nil end
  return table.concat(parts, " · ")
end

-- Punkte aller erreichten Ziele; characterKey optional (nil = alle Charaktere)
function Rewards.TotalPoints(characterKey)
  local total = 0
  for _, goal in ipairs(ns.db.goals) do
    if goal.status == Goals.DONE and goal.points and (not characterKey or goal.character == characterKey) then
      total = total + goal.points
    end
  end
  return total
end

local function validPoints(points)
  return type(points) == "number" and points >= 1 and points <= Rewards.MAX_POINTS and points == math.floor(points)
end

-- Belohnung und Punkte eines laufenden Ziels ändern (Befehle); nil löscht. Rückgabe: Fehlertext oder nil
function Rewards.SetReward(goal, text)
  if text == nil or strtrim(text) == "" then
    goal.reward = nil
  else
    local clean, err = Kinds.CleanText(text)
    if not clean then return err end
    goal.reward = clean
  end
  if goal.source then goal.source.extras.reward = goal.reward end
end

function Rewards.SetPoints(goal, points)
  if points ~= nil and not validPoints(points) then return string.format(L.SG_ERR_POINTS, Rewards.MAX_POINTS) end
  goal.points = points
  if goal.source then goal.source.extras.points = points end
end

Goals.RegisterExtra("reward", {
  fields = {
    { type = "text", param = "reward", label = "SG_FORM_REWARD" },
    { type = "text", param = "points", label = "SG_FORM_POINTS", numeric = true },
  },
  validate = function(extras)
    if extras.reward ~= nil and Kinds.TextLength(strtrim(extras.reward)) > Kinds.MAX_TEXT_LENGTH then
      return string.format(L.SG_ERR_TEXT_LONG, Kinds.MAX_TEXT_LENGTH)
    end
    if extras.points ~= nil and not validPoints(extras.points) then
      return string.format(L.SG_ERR_POINTS, Rewards.MAX_POINTS)
    end
  end,
  apply = function(goal, extras)
    Rewards.SetReward(goal, extras.reward)
    Rewards.SetPoints(goal, extras.points)
  end,
  fill = function(goal) return { reward = goal.reward, points = goal.points } end,
  update = function(goal, extras, changed)
    if changed.reward then Rewards.SetReward(goal, extras.reward) end
    if changed.points then Rewards.SetPoints(goal, extras.points) end
  end,
  line = Rewards.Line,
})
