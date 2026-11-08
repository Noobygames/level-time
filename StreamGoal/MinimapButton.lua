-- Minimap-Button von Level Time Goals, gebaut mit Lib/MinimapButton.lua von Level Time (wie dessen eigener Button).
-- Winkel in settings.minimapAngle, an/aus mit settings.minimapButton (/sg minimap, Einstellungen > Tracker).
-- Links Fenster /sg an/aus, Shift+links Historie, rechts Einstellungen, Shift+rechts Edit-Modus, ziehen verschiebt.
-- Wie bei Level Time kein LibDBIcon: der Button ist immer der eigene, auch wenn ein anderes Addon die Bibliothek lädt.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L
local Theme = LT.Theme

local MinimapButton = {}
ns.MinimapButton = MinimapButton

MinimapButton.ICON = "Interface\\AddOns\\StreamGoal\\Media\\Icon"
MinimapButton.MAX_TOOLTIP_GOALS = 5  -- so viele laufende Ziele listet der Tooltip, der Rest als "+n weitere"
MinimapButton.MIN_ANGLE, MinimapButton.MAX_ANGLE = 0, 360

local function settings()
  return ns.db.settings
end

-- Ziele mit eigener Zeile: laufende ohne Bingo-Felder (wie /sg list)
local listedGoals = {}
function MinimapButton.ListedGoals()
  for i = #listedGoals, 1, -1 do listedGoals[i] = nil end
  for _, goal in ipairs(Goals.Active()) do
    if not goal.cell then table.insert(listedGoals, goal) end
  end
  return listedGoals
end

local function goalLine(goal)
  if Goals.HasCount(goal) then return string.format("%s  %s", Goals.Title(goal), Goals.CountText(goal)) end
  return Goals.Title(goal)
end

-- Tooltip: Titel, Zahl der laufenden Ziele mit ihrem Stand, darunter die Klicks
function MinimapButton.FillTooltip(tooltip)
  tooltip:AddLine(ns.DISPLAY_NAME, Theme.RGB("accent"))
  local goals = MinimapButton.ListedGoals()
  if #goals == 0 then
    tooltip:AddLine(L.SG_LIST_EMPTY, 1, 1, 1)
  else
    tooltip:AddLine(string.format(L.SG_MINIMAP_ACTIVE, #goals), 1, 1, 1)
    for i = 1, math.min(#goals, MinimapButton.MAX_TOOLTIP_GOALS) do
      tooltip:AddLine(goalLine(goals[i]), Theme.RGB("muted"))
    end
    if #goals > MinimapButton.MAX_TOOLTIP_GOALS then
      tooltip:AddLine(string.format(L.SG_MORE_GOALS, #goals - MinimapButton.MAX_TOOLTIP_GOALS), Theme.RGB("muted"))
    end
  end
  tooltip:AddLine(" ")
  tooltip:AddLine(L.SG_MINIMAP_TIP_LEFT, 1, 1, 1)
  tooltip:AddLine(L.SG_MINIMAP_TIP_SHIFT_LEFT, 1, 1, 1)
  tooltip:AddLine(L.SG_MINIMAP_TIP_RIGHT, 1, 1, 1)
  tooltip:AddLine(L.TOOLTIP_SHIFT_RIGHT, 1, 1, 1)
  tooltip:AddLine(L.TOOLTIP_DRAG, 1, 1, 1)
end

function MinimapButton.OnClick(mouseButton)
  if not ns.db then return end
  if mouseButton == "RightButton" and IsShiftKeyDown() then
    LT.EditMode.Toggle()
  elseif mouseButton == "RightButton" then
    ns.Options.Toggle()
  elseif IsShiftKeyDown() then
    ns.Manager.Toggle("history")
  else
    ns.Manager.Toggle()
  end
end

local button = LT.MinimapButton.New({
  name = "StreamGoalMinimapButton",
  icon = MinimapButton.ICON,
  getAngle = function() return settings().minimapAngle end,
  setAngle = function(angle) settings().minimapAngle = angle end,
  onClick = MinimapButton.OnClick,
  tooltip = MinimapButton.FillTooltip,
})
MinimapButton.frame = button.frame

-- Ein- oder ausblenden (Einstellungen, /sg minimap); beim Ausblenden ein Hinweis, wie er zurückkommt
function MinimapButton.SetShown(shown)
  ns.SetSetting("minimapButton", shown and true or false)
  if not shown then ns.Print(L.SG_MINIMAP_HIDDEN) end
end

function MinimapButton.Toggle()
  MinimapButton.SetShown(not settings().minimapButton)
end

-- Gespeicherter Winkel außerhalb 0..360 (alte oder kaputte Daten) = Standard
LT.OnLogin(function()
  local angle = settings().minimapAngle
  if type(angle) ~= "number" or angle < MinimapButton.MIN_ANGLE or angle > MinimapButton.MAX_ANGLE then
    settings().minimapAngle = ns.SettingDefault("minimapAngle")
  end
end)

ns.RegisterApply(function()
  button.SetShown(settings().minimapButton)
end)
