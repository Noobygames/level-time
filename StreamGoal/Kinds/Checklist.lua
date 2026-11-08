-- Zielart Checkliste mit Teilzielen (Roadmap 304): eine Karte mit Punkten zum Abhaken (freier Text) und Teilzielen
-- anderer Arten (laufende Ziele, mit /sg sub angehängt: child.parentId). Stand = erledigte Punkte + erreichte
-- Teilziele, Ziel = alle. Teilziele erscheinen nicht als eigene Karte, sondern als Zeile der Checkliste (der Tracker
-- fragt Checklist.IsNested); scheitert oder endet ein Teilziel ohne Erfolg, bleibt seine Zeile offen.
-- Klick auf die Karte hakt den nächsten offenen Punkt ab, Shift+Klick nimmt den letzten zurück.
-- params: { items = { { text, done }, ... } }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Checklist = {}
ns.Checklist = Checklist

local ICON = "Interface\\Icons\\INV_Misc_Note_02"
local MAX_ITEMS = 10
local SEPARATOR = ";"
local CHECK_DONE = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12|t "
local CHECK_OPEN = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:12|t "
local CHECK_FAILED = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:12|t "

-- Teilziele einer Checkliste in der Reihenfolge des Anhängens (alle Status)
function Checklist.Children(parent)
  local children = {}
  for _, goal in ipairs(ns.db.goals) do
    if goal.parentId == parent.id then table.insert(children, goal) end
  end
  return children
end

-- Wird das Ziel als Zeile einer laufenden Checkliste gezeigt (statt als eigene Karte)?
function Checklist.IsNested(goal)
  local parent = goal.parentId and Goals.Get(goal.parentId)
  return parent ~= nil and parent.status == Goals.ACTIVE
end

local function itemsDone(params)
  local count = 0
  for _, item in ipairs(params.items) do
    if item.done then count = count + 1 end
  end
  return count
end

-- Stand und Ziel aus Punkten und Teilzielen
local function evaluate(goal)
  local done, total = itemsDone(goal.params), #goal.params.items
  for _, child in ipairs(Checklist.Children(goal)) do
    total = total + 1
    if child.status == Goals.DONE then done = done + 1 end
  end
  return done, total
end

local function reevaluate(goal)
  local done, total = evaluate(goal)
  goal.target = math.max(1, total)
  Goals.Update(goal, done)
end

-- Teilziel anhängen: child muss laufen, dem Charakter gehören und darf selbst keine Checkliste sein
function Checklist.Attach(parent, child)
  if not parent or parent.kind ~= "checklist" or parent.status ~= Goals.ACTIVE then return L.SG_ERR_NOT_CHECKLIST end
  if not child or child.status ~= Goals.ACTIVE or child == parent or child.kind == "checklist" or child.cell
    or child.kind == "bingo" then
    return L.SG_ERR_SUBGOAL
  end
  child.parentId = parent.id
  reevaluate(parent)
  Goals.Changed(child)
  return nil
end

Goals.RegisterKind("checklist", {
  label = "SG_KIND_CHECKLIST",
  group = "quests",
  usage = "SG_USAGE_CHECKLIST",
  color = LT.Theme.COLORS.accent,
  icon = ICON,
  manual = true,
  form = { fields = { { type = "text", param = "text", label = "SG_FORM_CHECKLIST" } } },
  -- "add list Holz sammeln; Boss legen; Ruf freundlich"
  parse = function(_, rest) return { text = rest }, nil end,
  prepare = function(params)
    local items = {}
    for part in ((params.text or "") .. SEPARATOR):gmatch("(.-)" .. SEPARATOR) do
      local text = strtrim(part)
      if text ~= "" then table.insert(items, { text = text, done = false }) end
    end
    params.items, params.text = items, nil
    return math.max(1, #items)
  end,
  validate = function(params)
    if #params.items == 0 then return L.SG_ERR_CHECKLIST end
    if #params.items > MAX_ITEMS then return string.format(L.SG_ERR_CHECKLIST_MANY, MAX_ITEMS) end
    for _, item in ipairs(params.items) do
      local _, err = Kinds.CleanText(item.text, L.SG_ERR_CHECKLIST)
      if err then return err end
    end
  end,
  -- Klick: nächsten offenen Punkt abhaken (delta > 0) bzw. den letzten erledigten zurücknehmen
  step = function(goal, delta)
    local items = goal.params.items
    if delta > 0 then
      for _, item in ipairs(items) do
        if not item.done then item.done = true break end
      end
    else
      for index = #items, 1, -1 do
        if items[index].done then items[index].done = false break end
      end
    end
    local done = evaluate(goal)
    return done
  end,
  title = function(goal) return string.format(L.SG_GOAL_CHECKLIST, #goal.params.items + #Checklist.Children(goal)) end,
  body = function(goal)
    local lines = {}
    for _, item in ipairs(goal.params.items) do
      table.insert(lines, (item.done and CHECK_DONE or CHECK_OPEN) .. item.text)
    end
    for _, child in ipairs(Checklist.Children(goal)) do
      local mark = CHECK_OPEN
      if child.status == Goals.DONE then mark = CHECK_DONE elseif child.status ~= Goals.ACTIVE then mark = CHECK_FAILED end
      table.insert(lines, mark .. Goals.Title(child))
    end
    return table.concat(lines, "\n")
  end,
})

---------------------------------------------------------------------------
-- Teilziele: Abschluss, Scheitern, Abbrechen und Fortschritt bewerten die Checkliste neu
---------------------------------------------------------------------------
Goals.OnChange(function(event, goal)
  if not goal or not goal.parentId or event == "added" then return end
  local parent = Goals.Get(goal.parentId)
  if not parent or parent.status ~= Goals.ACTIVE or parent.kind ~= "checklist" then return end
  if event == "progress" or event == "changed" then
    Goals.Changed(parent)  -- Zeile des Teilziels neu (Titel mit Stand)
  else
    reevaluate(parent)
  end
end)
