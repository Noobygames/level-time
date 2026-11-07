-- Chatbefehle: /sg oder /streamgoal. Ohne Argument öffnet sich das Fenster.
--   add level 20 | add kills 100 [pve|pvp] [bg] | add item <Link oder ID> [Anzahl] | add bgwin 3 [Name]
--   add custom [Anzahl] <Text> | count <Nr> [+/-Betrag]
--   list | cancel <Nr> | history | tracker | move | scale <0.5-2> | help
local _, ns = ...
local Goals = ns.Goals
local Kinds = ns.Kinds
local Tracker = ns.Tracker
local Manager = ns.Manager
local L = ns.L
local Format = ns.LT.Format

local DEFAULT_AMOUNT = 1
local DEFAULT_STEP = 1

local function words(text)
  local list = {}
  for word in text:gmatch("%S+") do table.insert(list, word) end
  return list
end

-- Alle Wörter aus text, die kein Schlüsselwort aus ignore sind, in der Reihenfolge
local function without(list, ignore)
  local rest = {}
  for _, word in ipairs(list) do
    if not ignore[word:lower()] then table.insert(rest, word) end
  end
  return rest
end

local adders = {}

function adders.level(args)
  return "level", {}, tonumber(args[1])
end

function adders.kills(args)
  local params = {}
  for _, word in ipairs(args) do
    word = word:lower()
    if word == "pve" or word == "pvp" or word == "any" then params.source = word end
    if word == "bg" then params.battleground = true end
  end
  return "kills", params, tonumber(args[1])
end

-- Der Link enthält Leerzeichen im Namen ("|Hitem:123|h[Dunkle Klinge]|h"): erst herauslösen, dann die Anzahl
function adders.item(_, rest)
  local link = rest:match("|c.-|r")
  local remainder = link and rest:gsub("|c.-|r", "", 1) or rest
  local itemId, parsedLink = Kinds.ParseItem(link or words(remainder)[1])
  local amountWords = words(remainder)
  if not link then table.remove(amountWords, 1) end
  return "item", { itemId = itemId, link = parsedLink }, tonumber(amountWords[1]) or DEFAULT_AMOUNT
end

function adders.bgwin(args)
  local name = table.concat(args, " ", 2)
  return "bgwin", { battleground = name ~= "" and name or nil }, tonumber(args[1]) or DEFAULT_AMOUNT
end

-- Eine führende Zahl ist der Zähler ("add custom 5 Alle Quests für RFC"), ohne Zahl ein Ziel zum Abhaken
function adders.custom(args, rest)
  local counter = tonumber(args[1])
  local text = counter and rest:match("^%S+%s*(.*)$") or rest
  return "custom", { text = text }, counter
end

local function add(rest)
  local kind, remainder = rest:match("^(%S+)%s*(.*)$")
  local adder = kind and adders[kind:lower()]
  if not adder then
    ns.Print(string.format(L.SG_ERR_UNKNOWN_KIND, kind or "?"))
    return
  end
  local goal, err = Goals.Create(adder(words(remainder), remainder))
  if goal then
    ns.Print(string.format(L.SG_CHAT_ADDED, Goals.Title(goal)))
  else
    ns.Print(err)
  end
end

-- Selbst gezähltes Ziel weiterzählen: "count 3" = +1, "count 3 2" = +2, "count 3 -1" = eins zurück
local function count(argument)
  local id, amount = argument:match("^(%S*)%s*(%S*)")
  local goal, err = Goals.Step(tonumber(id), tonumber(amount) or DEFAULT_STEP)
  if not goal then
    ns.Print(err)
  elseif goal.status == Goals.ACTIVE and Goals.HasCount(goal) then
    ns.Print(string.format("#%d %s (%d / %d)", goal.id, Goals.Title(goal), goal.progress, goal.target))
  end
end

local function list()
  local active = Goals.Active()
  if #active == 0 then
    ns.Print(L.SG_LIST_EMPTY)
    return
  end
  for _, goal in ipairs(active) do
    if Goals.HasCount(goal) then
      ns.Print(string.format("#%d %s (%d / %d)", goal.id, Goals.Title(goal), goal.progress, goal.target))
    else
      ns.Print(string.format("#%d %s", goal.id, Goals.Title(goal)))
    end
  end
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
  move = function() ns.LT.EditMode.Toggle() end,  -- Edit-Modus von Level Time
  history = function() Manager.Toggle("history") end,
  help = function() ns.Print(L.SG_HELP) end,
}

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
    ns.Print(L.SG_HELP)
  end
end
