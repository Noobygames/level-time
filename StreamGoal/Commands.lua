-- Chatbefehle: /sg oder /streamgoal. Ohne Argument öffnet sich das Fenster.
--   add <Art> ... (Syntax je Art aus def.parse, Hilfezeile def.usage) | count <Nr> [+/-Betrag]
--   deadline <Nr> <Dauer|off> [played] | repeat <Nr> daily|weekly|none | sub <Checkliste> <Ziel> | pack ... | list | cancel <Nr> | history | tracker | options | move | scale <0.5-2> | help
local _, ns = ...
local Goals = ns.Goals
local Kinds = ns.Kinds
local Tracker = ns.Tracker
local Manager = ns.Manager
local L = ns.L
local LT = ns.LT
local Format = LT.Format

local DEFAULT_STEP = 1

-- Befehle für Zusätze laufender Ziele (eine Hilfezeile je Befehl)
ns.EXTRA_USAGES = { "SG_USAGE_DEADLINE", "SG_USAGE_REPEAT", "SG_USAGE_SUB", "SG_USAGE_PACK" }

-- Hilfe: allgemeine Zeile, dann je Zielart ihre add-Syntax, dann die Befehle für Zusätze
local function help()
  ns.Print(L.SG_HELP)
  for _, kind in ipairs(Goals.KindOrder()) do
    local usage = Goals.GetKind(kind).usage
    if usage and Goals.IsAvailable(kind) then ns.Print("  " .. L[usage]) end
  end
  for _, usage in ipairs(ns.EXTRA_USAGES) do ns.Print("  " .. L[usage]) end
end

-- Kurze Namen für /sg add
local KIND_ALIASES = { list = "checklist", boss = "dungeon" }

local function add(rest)
  local kind, remainder = rest:match("^(%S+)%s*(.*)$")
  kind = kind and kind:lower()
  local def = kind and Goals.GetKind(KIND_ALIASES[kind] or kind)
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

-- Laufendes Ziel des Charakters nach Nummer; sonst Meldung und nil
local function ownActiveGoal(id)
  local goal = Goals.Get(tonumber(id))
  if goal and goal.status == Goals.ACTIVE and goal.character == ns.LT.characterKey then return goal end
  ns.Print(string.format(L.SG_ERR_NO_GOAL, id ~= "" and id or "?"))
end

-- Frist setzen oder entfernen: "deadline 3 2h", "deadline 3 5h played", "deadline 3 off"
local function deadline(argument)
  local id, duration, mode = argument:match("^(%S*)%s*(%S*)%s*(%S*)")
  local goal = ownActiveGoal(id)
  if not goal then return end
  if duration:lower() == "off" then
    ns.Deadlines.Set(goal, nil)
  else
    local seconds = ns.Deadlines.ParseDuration(duration)
    local played = mode:lower() == ns.Deadlines.PLAYED
    if not seconds or not ns.Deadlines.Set(goal, seconds, played and ns.Deadlines.PLAYED or ns.Deadlines.REAL) then
      ns.Print(seconds and L.SG_ERR_PLAYED_UNKNOWN or L.SG_ERR_DEADLINE)
      return
    end
  end
  Goals.Changed(goal)
  ns.Print(goalLine(goal) .. (ns.Deadlines.Text(goal) and ("  " .. ns.Deadlines.Text(goal)) or ""))
end

-- Wiederholung: "repeat 3 daily", "repeat 3 weekly", "repeat 3 none"
local function repeatGoal(argument)
  local id, period = argument:match("^(%S*)%s*(%S*)")
  local goal = ownActiveGoal(id)
  if not goal then return end
  if not ns.Recurring.Set(goal, period:lower()) then
    ns.Print(L.SG_ERR_REPEAT)
    return
  end
  Goals.Changed(goal)
  ns.Print(goalLine(goal) .. (ns.Recurring.Text(goal) and ("  " .. ns.Recurring.Text(goal)) or ""))
end

-- Laufendes Ziel als Teilziel an eine Checkliste hängen: "sub <Checkliste> <Ziel>"
local function sub(argument)
  local parentId, childId = argument:match("^(%S*)%s*(%S*)")
  local parent, child = ownActiveGoal(parentId), ownActiveGoal(childId)
  if not parent or not child then return end
  local err = ns.Checklist.Attach(parent, child)
  ns.Print(err or string.format(L.SG_CHAT_SUBGOAL, Goals.Title(child), Goals.Title(parent)))
end

-- Vorlagen: "pack" (Liste), "pack <Name>" (anlegen), "pack save <Name>", "pack delete <Name>",
-- "pack export <Name>", "pack import" (Fenster zum Einfügen); ohne Fenster reicht der Reiter "Vorlagen"
local function pack(argument)
  local action, name = argument:match("^(%S*)%s*(.-)$")
  local Packs = ns.Packs
  action = action:lower()
  if action == "" or action == "list" then
    for _, entry in ipairs(Packs.List()) do
      ns.Print(string.format("%s  (%s)", Packs.Label(entry.key), entry.key))
    end
  elseif action == "save" then
    local err = Packs.Save(name)
    ns.Print(err or string.format(L.SG_CHAT_PACK_SAVED, name))
  elseif action == "delete" then
    ns.Print(Packs.Delete(name) and string.format(L.SG_CHAT_PACK_DELETED, name)
      or string.format(L.SG_ERR_PACK_UNKNOWN, name))
  elseif action == "export" then
    local text = Packs.Export(name)
    if text then LT.Export.Show(Packs.Label(name), text) else ns.Print(string.format(L.SG_ERR_PACK_UNKNOWN, name)) end
  elseif action == "import" then
    Manager.Toggle("packs")
  else
    ns.PacksView.Apply(strtrim(argument))
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
  deadline = deadline,
  sub = sub,
  ["repeat"] = repeatGoal,
  pack = pack,
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
