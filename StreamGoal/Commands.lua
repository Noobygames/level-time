-- Chatbefehle: /sg oder /streamgoal. Ohne Argument öffnet sich das Fenster.
--   add <Art> ... (Syntax je Art aus def.parse, Hilfezeile def.usage) | count <Nr> [+/-Betrag]
--   list | cancel <Nr> | history | tracker | options | move | scale <0.5-2> | help
local _, ns = ...
local Goals = ns.Goals
local Kinds = ns.Kinds
local Tracker = ns.Tracker
local Manager = ns.Manager
local L = ns.L
local Format = ns.LT.Format

local DEFAULT_STEP = 1

-- Hilfe: allgemeine Zeile, dann je Zielart ihre add-Syntax
local function help()
  ns.Print(L.SG_HELP)
  for _, kind in ipairs(Goals.KindOrder()) do
    local usage = Goals.GetKind(kind).usage
    if usage and Goals.IsAvailable(kind) then ns.Print("  " .. L[usage]) end
  end
end

local function add(rest)
  local kind, remainder = rest:match("^(%S+)%s*(.*)$")
  local def = kind and Goals.GetKind(kind:lower())
  if not def or not def.parse or not Goals.IsAvailable(def.name) then
    ns.Print(string.format(L.SG_ERR_UNKNOWN_KIND, kind or "?"))
    return
  end
  local params, target = def.parse(Kinds.Words(remainder), remainder)
  local goal, err = Goals.Create(def.name, params, target)
  if goal then
    ns.Print(string.format(L.SG_CHAT_ADDED, Goals.Title(goal)))
  else
    ns.Print(err)
  end
end

local function goalLine(goal)
  if Goals.HasCount(goal) then
    return string.format("#%d %s (%s)", goal.id, Goals.Title(goal), Goals.CountText(goal))
  end
  return string.format("#%d %s", goal.id, Goals.Title(goal))
end

-- Selbst gezähltes Ziel weiterzählen: "count 3" = +1, "count 3 2" = +2, "count 3 -1" = eins zurück
local function count(argument)
  local id, amount = argument:match("^(%S*)%s*(%S*)")
  local goal, err = Goals.Step(tonumber(id), tonumber(amount) or DEFAULT_STEP)
  if not goal then
    ns.Print(err)
  elseif goal.status == Goals.ACTIVE and Goals.HasCount(goal) then
    ns.Print(goalLine(goal))
  end
end

local function list()
  local active = Goals.Active()
  if #active == 0 then
    ns.Print(L.SG_LIST_EMPTY)
    return
  end
  for _, goal in ipairs(active) do ns.Print(goalLine(goal)) end
end

local function cancel(argument)
  local goal = Goals.Cancel(tonumber(argument))
  if goal then
    ns.Print(string.format(L.SG_CHAT_CANCELLED, Goals.Title(goal)))
  else
    ns.Print(string.format(L.SG_ERR_NO_GOAL, argument ~= "" and argument or "?"))
  end
end

local function toggleTracker()
  local shown = not ns.db.settings.showTracker
  Tracker.SetShown(shown)
  ns.Print(shown and L.SG_TRACKER_ON or L.SG_TRACKER_OFF)
end

local function scale(argument)
  local value = tonumber(argument)
  if not value then return end
  ns.Print(string.format(L.SG_SCALE_SET, Format.Number(Tracker.SetScale(value) * 100) .. " %"))
end

local commands = {
  add = add,
  list = list,
  cancel = cancel,
  count = count,
  tracker = toggleTracker,
  scale = scale,
  options = function() ns.Options.Toggle() end,
  config = function() ns.Options.Toggle() end,
  move = function() ns.LT.EditMode.Toggle() end,  -- Edit-Modus von Level Time
  history = function() Manager.Toggle("history") end,
  help = help,
}
ns.commands = commands  -- weitere Befehle melden die Dateien danach an (z.B. Pakete)

SLASH_STREAMGOAL1 = "/sg"
SLASH_STREAMGOAL2 = "/streamgoal"
SlashCmdList.STREAMGOAL = function(input)
  if not ns.db then return end  -- vor dem Login gibt es keine Daten
  local command, argument = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
  command = command:lower()
  if command == "" then
    Manager.Toggle()
  elseif commands[command] then
    commands[command](argument)
  else
    help()
  end
end
