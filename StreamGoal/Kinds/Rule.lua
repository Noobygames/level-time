-- Zielart Regel (Roadmap 300): eine Regel halten, bis ein Level erreicht ist (optional) oder die Frist endet; ein
-- Verstoß lässt das Ziel scheitern (Hardcore-Muster). Regeln (Kinds.RULES):
--   nodeath   kein Tod (Zähler DEATHS von Level Time, ein Tod je Sterben)
--   nohelp    kein Handel, Briefkasten, Auktionshaus (RunCategory.OnOutsideHelp von Level Time: Fenster geöffnet)
--   notaxi    keine Flugpunkte (Zähler TAXI_SECONDS der Zeitaufteilung, kommt spätestens 10 s nach dem Abflug)
--   naked     keine Rüstung (PLAYER_EQUIPMENT_CHANGED; angelegte Rüstung hat NAKED_GRACE_SECONDS Schonfrist, dann
--             gilt sie als Verstoß; Waffen, Hemd, Wappenrock, Schmuck sind erlaubt)
--   nopotion  keine Heiltränke (UNIT_SPELLCAST_SUCCEEDED des Spielers mit den Spell-IDs der Classic/TBC-Heiltränke;
--             im Spiel zu prüfen, Debug-Check "300.goals.potionSpells")
-- Mit Level: Stand = Level wie bei "level"; ohne Level kein Zähler, erledigt nur über die Frist (die bei Regeln
-- Erfolg statt Scheitern bedeutet: deadlineSucceeds) oder offen bis zum Abbrechen.
-- params: { rule = Name, level = true|nil }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Rules = {}
ns.RuleGoals = Rules

Kinds.RULES = { "nodeath", "nohelp", "notaxi", "naked", "nopotion" }
local RULE_LABELS = { nodeath = "SG_RULE_NODEATH", nohelp = "SG_RULE_NOHELP", notaxi = "SG_RULE_NOTAXI",
  naked = "SG_RULE_NAKED", nopotion = "SG_RULE_NOPOTION" }
local BROKEN = { nodeath = "SG_BROKEN_NODEATH", nohelp = "SG_BROKEN_NOHELP", notaxi = "SG_BROKEN_NOTAXI",
  naked = "SG_BROKEN_NAKED", nopotion = "SG_BROKEN_NOPOTION" }
local ICON = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
local OPEN_TARGET = 1
local NAKED_GRACE_SECONDS = 10
-- Rüstungsplätze (INVSLOT_*): Kopf, Hals, Schulter, Brust, Taille, Beine, Füße, Handgelenk, Hände, Rücken
-- (Hals zählt nicht: Schmuck ist erlaubt)
local ARMOR_SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 15 }
-- Heiltränke Classic/TBC (Spell der Benutzung): schwach, gering, normal, groß, erstklassig, mächtig, super
Rules.POTION_SPELLS = { [439] = true, [440] = true, [441] = true, [2024] = true, [4042] = true, [17534] = true,
  [28495] = true }

function Rules.WearsArmor()
  for _, slot in ipairs(ARMOR_SLOTS) do
    if GetInventoryItemLink("player", slot) then return true end
  end
  return false
end

Goals.RegisterKind("rule", {
  label = "SG_KIND_RULE",
  group = "fun",
  usage = "SG_USAGE_RULE",
  color = LT.Theme.COLORS.warning,
  icon = ICON,
  deadlineSucceeds = true,
  form = { amount = "SG_FORM_RULE_LEVEL", fields = {
    { type = "choice", param = "rule", label = "SG_FORM_RULE", values = Kinds.RULES, labels = RULE_LABELS },
  } },
  -- "add rule nodeath [Level]"
  parse = function(args)
    local params, level = {}, nil
    for _, word in ipairs(args) do
      if RULE_LABELS[word:lower()] then params.rule = word:lower() else level = level or tonumber(word) end
    end
    return params, level
  end,
  prepare = function(params, target)
    params.level = target ~= nil or nil
    return target or OPEN_TARGET
  end,
  validate = function(params, target)
    if not RULE_LABELS[params.rule] then return L.SG_ERR_RULE end
    if params.level and (type(target) ~= "number" or target <= LT.level) then
      return string.format(L.SG_ERR_LEVEL, LT.level)
    end
    if params.rule == "naked" and Rules.WearsArmor() then return L.SG_ERR_NAKED end
  end,
  initial = function(params) return params.level and LT.level or 0 end,
  hasCount = function(goal) return goal.params.level == true end,
  title = function(goal)
    local rule = L[RULE_LABELS[goal.params.rule]]
    if goal.params.level then return string.format(L.SG_GOAL_RULE_LEVEL, rule, goal.target) end
    return rule
  end,
  body = function() return L.SG_RULE_BODY end,
})

---------------------------------------------------------------------------
-- Erfassung: Verstöße und Level
---------------------------------------------------------------------------
local function rulesActive(rule)
  for _, goal in ipairs(Goals.Active()) do
    if goal.kind == "rule" and goal.params.rule == rule then return true end
  end
  return false
end

-- Alle laufenden Regel-Ziele dieser Regel scheitern (Liste vorher kopiert: Scheitern baut den Index neu)
function Rules.Break(rule)
  if not ns.db then return end
  local broken = {}
  for _, goal in ipairs(Goals.Active()) do
    if goal.kind == "rule" and goal.params.rule == rule then table.insert(broken, goal) end
  end
  for _, goal in ipairs(broken) do
    ns.Debug("rule", "#%s broken: %s", goal.id, rule)
    Goals.Fail(goal, L[BROKEN[rule]])
  end
end

local function setLevel(level)
  Goals.SetEach("rule", function(goal) return goal.params.level and level or nil end)
end
LT.OnLevelStarted(setLevel)
LT.OnLogin(function() setLevel(LT.level) end)

LT.Stats.OnIncrement(function(counter, amount)
  if counter == LT.Stats.DEATHS then
    Rules.Break("nodeath")
  elseif counter == LT.Stats.TAXI_SECONDS and amount > 0 then
    Rules.Break("notaxi")
  end
end)

LT.RunCategory.OnOutsideHelp(function() Rules.Break("nohelp") end)

-- Nackt: nach einer Änderung die Schonfrist abwarten, dann prüfen (ein Rüstungsteil kurz anprobieren ist erlaubt)
local nakedCheckPending = false
LT.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
  if nakedCheckPending or not ns.db or not rulesActive("naked") or not Rules.WearsArmor() then return end
  nakedCheckPending = true
  C_Timer.After(NAKED_GRACE_SECONDS, function()
    nakedCheckPending = false
    if Rules.WearsArmor() then Rules.Break("naked") end
  end)
end)

-- Heiltränke: nur angemeldet, solange eine solche Regel läuft
local potionEvents = LT.NewEventGroup()
potionEvents.Add("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spellID)
  if not LT.IsSecret(spellID) and Rules.POTION_SPELLS[spellID] then Rules.Break("nopotion") end
end)

local function updatePotionEvents()
  potionEvents.SetActive(ns.db ~= nil and rulesActive("nopotion"))
end
Goals.OnChange(updatePotionEvents)
LT.OnLogin(updatePotionEvents)
