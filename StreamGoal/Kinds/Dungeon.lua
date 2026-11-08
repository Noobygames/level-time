-- Zielart Dungeon/Boss (Roadmap 302): N Bosse besiegen, optional nur ein bestimmter Boss und/oder nur in einer
-- Instanz (Teilstrings). Quelle: ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success) mit
-- success = 1 (alle Clients; in WoW Forever lesbar laut Debug-Log des Besitzers), Instanzname aus GetInstanceInfo.
-- Ein Boss zählt je Kampf einmal; "Dungeon N-mal abschließen" (letzter Boss) und "alle Dungeons bis Level Y" sind noch
-- offen (es gibt keine Liste der Endbosse je Client).
-- params: { boss = Name oder nil, instance = Name oder nil }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Dungeon = {}
ns.DungeonGoals = Dungeon

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
  form = { amount = "SG_FORM_AMOUNT", fields = {
    { type = "text", param = "boss", label = "SG_FORM_DUNGEON_BOSS" },
    { type = "text", param = "instance", label = "SG_FORM_DUNGEON_INSTANCE" },
  } },
  -- "add boss 3 [Boss-Name]"; Instanz nur im Fenster
  parse = function(args, rest)
    local amount = tonumber(args[1])
    local boss = amount and rest:match("^%S+%s*(.*)$") or rest
    return { boss = boss }, amount or Kinds.DEFAULT_AMOUNT
  end,
  prepare = function(params, target)
    params.boss, params.instance = optionalText(params.boss), optionalText(params.instance)
    return target or Kinds.DEFAULT_AMOUNT
  end,
  validate = function(params, target)
    for _, text in ipairs({ params.boss or "", params.instance or "" }) do
      if Kinds.TextLength(text) > Kinds.MAX_TEXT_LENGTH then
        return string.format(L.SG_ERR_TEXT_LONG, Kinds.MAX_TEXT_LENGTH)
      end
    end
    return Kinds.ValidAmount(target)
  end,
  title = function(goal)
    local boss = goal.params.boss
    if boss then return string.format(L.SG_GOAL_BOSS_NAMED, boss, goal.target) end
    return Kinds.Counted("SG_GOAL_BOSS_ANY", goal.target)
  end,
  body = function(goal)
    return goal.params.instance and string.format(L.SG_DUNGEON_IN, goal.params.instance) or nil
  end,
})

---------------------------------------------------------------------------
-- Erfassung
---------------------------------------------------------------------------
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
  Goals.Add("dungeon", function(goal)
    return Kinds.Matches(boss, goal.params.boss) and Kinds.Matches(instance, goal.params.instance)
  end, 1)
end)
