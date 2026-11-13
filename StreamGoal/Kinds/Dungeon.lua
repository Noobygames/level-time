-- Zielart Dungeon/Boss (Roadmap 302): N Bosse besiegen, optional nur ein bestimmter Boss und/oder nur in einer
-- Instanz (Teilstrings), Dungeons abschließen (mindestens ein Boss besiegt je Instanzlauf) oder Dungeon-Tour
-- (N verschiedene Dungeons abschließen). Quelle: ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
-- mit success = 1 (alle Clients; in WoW Forever lesbar laut Debug-Log des Besitzers), Instanzname aus GetInstanceInfo.
-- params: { mode = "boss"|"complete"|"tour", boss = Name oder nil, instance = Name oder nil, doneInstances = { Name, ... } }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Dungeon = {}
ns.DungeonGoals = Dungeon

local MODES = { "boss", "complete", "tour" }
local MODE_LABELS = {
  boss = "SG_FORM_DUNGEON_MODE_BOSS",
  complete = "SG_FORM_DUNGEON_MODE_COMPLETE",
  tour = "SG_FORM_DUNGEON_MODE_TOUR",
}

local ICON = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
local SUCCESS = 1

local function optionalText(text)
  text = strtrim(text or "")
  return text ~= "" and text or nil
end

Goals.RegisterKind("dungeon", {
  label = "SG_KIND_DUNGEON",
  group = "combat",
  usage = "SG_USAGE_DUNGEON",
  color = LT.Theme.COLORS.best,
  icon = ICON,
  editable = { "amount" },  -- nur die Zielzahl; Modus und Filter gelten ab dem Anlegen
  form = { fields = {
    { type = "choice", param = "mode", label = "SG_FORM_DUNGEON_MODE", values = MODES, labels = MODE_LABELS },
    { type = "amount", label = "SG_FORM_AMOUNT" },
    { type = "text", param = "boss", label = "SG_FORM_DUNGEON_BOSS", showIf = { mode = "boss" } },
    { type = "text", param = "instance", label = "SG_FORM_DUNGEON_INSTANCE", showIf = { mode = { "boss", "complete" } } },
  } },
  -- "add boss 3 [Boss-Name]", "add dungeon complete 3 [Instanz]", "add dungeon tour 4"
  parse = function(args, rest)
    local first = args[1] and args[1]:lower()
    if first == "complete" then
      local amount = tonumber(args[2])
      local instance = rest:match("^%S+%s+%d+%s*(.*)$") or rest:match("^%S+%s*(.*)$")
      if amount and instance == tostring(amount) then instance = nil end
      if instance == "" then instance = nil end
      return { mode = "complete", instance = instance }, amount or Kinds.DEFAULT_AMOUNT
    elseif first == "tour" then
      local amount = tonumber(args[2])
      return { mode = "tour" }, amount or Kinds.DEFAULT_AMOUNT
    elseif first == "boss" then
      local amount = tonumber(args[2])
      local boss = rest:match("^%S+%s+%d+%s*(.*)$") or rest:match("^%S+%s*(.*)$")
      if amount and boss == tostring(amount) then boss = nil end
      if boss == "" then boss = nil end
      return { mode = "boss", boss = boss }, amount or Kinds.DEFAULT_AMOUNT
    else
      local amount = tonumber(args[1])
      local boss = amount and rest:match("^%S+%s*(.*)$") or rest
      if boss == "" then boss = nil end
      return { mode = "boss", boss = boss }, amount or Kinds.DEFAULT_AMOUNT
    end
  end,
  prepare = function(params, target)
    params.mode = params.mode or "boss"
    params.boss = optionalText(params.boss)
    params.instance = optionalText(params.instance)
    if params.mode == "complete" then
      params.boss = nil
    elseif params.mode == "tour" then
      params.boss = nil
      params.instance = nil
      params.doneInstances = params.doneInstances or {}
    end
    return target or Kinds.DEFAULT_AMOUNT
  end,
  validate = function(params, target)
    if params.mode and not MODE_LABELS[params.mode] then
      return string.format(L.SG_ERR_UNKNOWN_KIND, tostring(params.mode))
    end
    for _, text in ipairs({ params.boss or "", params.instance or "" }) do
      if Kinds.TextLength(text) > Kinds.MAX_TEXT_LENGTH then
        return string.format(L.SG_ERR_TEXT_LONG, Kinds.MAX_TEXT_LENGTH)
      end
    end
    return Kinds.ValidAmount(target)
  end,
  title = function(goal)
    local mode = goal.params.mode or "boss"
    if mode == "complete" then
      local instance = goal.params.instance
      if instance then return string.format(L.SG_GOAL_DUNGEON_COMPLETE_NAMED, instance, goal.target) end
      return Kinds.Counted("SG_GOAL_DUNGEON_COMPLETE_ANY", goal.target)
    elseif mode == "tour" then
      return Kinds.Counted("SG_GOAL_DUNGEON_TOUR", goal.target)
    else
      local boss = goal.params.boss
      if boss then return string.format(L.SG_GOAL_BOSS_NAMED, boss, goal.target) end
      return Kinds.Counted("SG_GOAL_BOSS_ANY", goal.target)
    end
  end,
  body = function(goal)
    local mode = goal.params.mode or "boss"
    if mode == "boss" then
      return goal.params.instance and string.format(L.SG_DUNGEON_IN, goal.params.instance) or nil
    elseif mode == "tour" then
      if goal.params.doneInstances and #goal.params.doneInstances > 0 then
        return table.concat(goal.params.doneInstances, ", ")
      end
      return nil
    end
    return nil
  end,
})

---------------------------------------------------------------------------
-- Erfassung
---------------------------------------------------------------------------
-- Lauf-Kennung für params.lastRun (gespeichert): der Startzeitpunkt des offenen Laufs aus Level Time (bleibt über
-- /reload gleich, nichts wird in dessen Daten geschrieben). Ohne Lauf ein Zähler ab time(), damit er nach einem
-- Neustart nicht auf einen gespeicherten Wert der letzten Sitzung trifft.
local runToken = time()
local lastSeenInstance = nil

function Dungeon.NewRun()
  runToken = runToken + 1
  return runToken
end

local function currentRunToken(instance)
  local run = LT.Instances and LT.Instances.GetCurrentRun()
  if run and run.startedAt then return run.startedAt end
  if instance and instance ~= lastSeenInstance then
    lastSeenInstance = instance
    runToken = runToken + 1
  end
  return runToken
end

if LT.InstanceCopy and LT.InstanceCopy.OnEnter then
  LT.InstanceCopy.OnEnter(function(name, instanceType, isNew)
    if isNew then
      runToken = runToken + 1
      lastSeenInstance = name
    end
  end)
end
if LT.InstanceCopy and LT.InstanceCopy.OnReset then
  LT.InstanceCopy.OnReset(function(name)
    runToken = runToken + 1
  end)
end

-- Boss besiegt? nil bei geheimen oder fehlenden Werten
function Dungeon.ParseEncounter(encounterName, success)
  if LT.IsSecret(encounterName) or LT.IsSecret(success) then return nil end
  if success ~= SUCCESS or type(encounterName) ~= "string" then return nil end
  return encounterName
end

LT.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
  if not ns.db or not Goals.HasActive("dungeon") then return end
  local boss = Dungeon.ParseEncounter(encounterName, success)
  ns.Debug("tracking", "encounter end %s %s difficulty %s size %s success %s", encounterID, encounterName,
    difficultyID, groupSize, success)
  if not boss then return end
  local instance = (GetInstanceInfo())
  local token = currentRunToken(instance)

  Goals.Add("dungeon", function(goal)
    local mode = goal.params.mode or "boss"
    if mode == "boss" then
      return Kinds.Matches(boss, goal.params.boss) and Kinds.Matches(instance, goal.params.instance)
    elseif mode == "complete" then
      if not Kinds.Matches(instance, goal.params.instance) then return false end
      if goal.params.lastRun == token then return false end
      goal.params.lastRun = token
      return true
    elseif mode == "tour" then
      if not instance or instance == "" then return false end
      goal.params.doneInstances = goal.params.doneInstances or {}
      for _, done in ipairs(goal.params.doneInstances) do
        if done == instance then return false end
      end
      table.insert(goal.params.doneInstances, instance)
      return true
    end
    return false
  end, 1)
end)
