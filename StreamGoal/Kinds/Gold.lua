-- Zielart Gold (Roadmap 295): "N Gold verdienen" (Einnahmen ab dem Anlegen, Zähler MONEY_EARNED von Level Time, also
-- Beute, Quests, Händler, Post, Auktionshaus, Handel) oder "N Gold besitzen" (Bestand GetMoney, bei PLAYER_MONEY neu).
-- Eingabe und Anzeige in Gold, gespeichert in Kupfer (target, progress).
-- params: { mode = "earn"|"own" }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local COPPER_PER_GOLD = 10000
local MODES = { "earn", "own" }
local MODE_LABELS = { earn = "SG_FORM_GOLD_EARN", own = "SG_FORM_GOLD_OWN" }
local TITLES = { earn = "SG_GOAL_GOLD_EARN", own = "SG_GOAL_GOLD_OWN" }
local ICON = "Interface\\Icons\\INV_Misc_Coin_01"

local function gold(copper)
  return math.floor(copper / COPPER_PER_GOLD)
end

Goals.RegisterKind("gold", {
  label = "SG_KIND_GOLD",
  group = "loot",
  usage = "SG_USAGE_GOLD",
  color = LT.Theme.COLORS.gold,
  icon = ICON,
  form = { amount = "SG_FORM_GOLD", fields = {
    { type = "choice", param = "mode", label = "SG_FORM_GOLD_MODE", values = MODES, labels = MODE_LABELS },
  } },
  parse = function(args)
    local params = {}
    for _, word in ipairs(args) do
      if MODE_LABELS[word:lower()] then params.mode = word:lower() end
    end
    return params, tonumber(args[1])
  end,
  -- Eingabe in Gold, Ziel in Kupfer
  prepare = function(params, target)
    params.mode = params.mode or "earn"
    if type(target) == "number" then return target * COPPER_PER_GOLD end
    return target
  end,
  validate = function(params, target)
    if not TITLES[params.mode] then return string.format(L.SG_ERR_UNKNOWN_KIND, tostring(params.mode)) end
    if type(target) ~= "number" or target < COPPER_PER_GOLD or target % COPPER_PER_GOLD ~= 0 then
      return L.SG_ERR_AMOUNT
    end
  end,
  current = function(goal)
    if goal.params.mode == "own" then return GetMoney() end
    return 0
  end,
  countText = function(goal)
    return string.format("%s / %s", Kinds.GoldText(goal.progress), Kinds.GoldText(goal.target))
  end,
  title = function(goal) return string.format(L[TITLES[goal.params.mode]], gold(goal.target)) end,
})

-- "1.234g" mit der Gold-Einheit von Level Time (L.UNIT_GOLD_SHORT), ohne Silber und Kupfer
function Kinds.GoldText(copper)
  return LT.Format.Integer(gold(copper)) .. L.UNIT_GOLD_SHORT
end

---------------------------------------------------------------------------
-- Erfassung
---------------------------------------------------------------------------
local function isEarn(goal) return goal.params.mode == "earn" end

LT.Stats.OnIncrement(function(counter, amount)
  if counter ~= LT.Stats.MONEY_EARNED or not ns.db then return end
  Goals.Add("gold", isEarn, amount)
end)

local function updateOwned()
  if not ns.db or not Goals.HasActive("gold") then return end
  local money = GetMoney()
  Goals.SetEach("gold", function(goal)
    if goal.params.mode == "own" then return money end
  end)
end

LT.RegisterEvent("PLAYER_MONEY", updateOwned)
LT.OnLogin(updateOwned)
