-- Zielart Items besitzen (Roadmap 298): N Stück eines Items in den Taschen haben (wie FarmIt/Farming Bar), anders als
-- "item" (N looten) zählt jede Herkunft (Kauf, Post, Handel) und Verkaufen oder Verbrauchen senkt den Stand.
-- Bestand: C_Item.GetItemCount (Retail, Classic ab 1.15) bzw. GetItemCount, neu bei BAG_UPDATE_DELAYED (einmal je
-- Taschenänderung, alle Clients). Optional mit Bank (zweites Argument includeBank; die Bank zählt der Client erst,
-- nachdem sie einmal geöffnet war).
-- params: { itemId, link, bank = true|nil }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local ICON = "Interface\\Icons\\INV_Misc_Bag_08"

local function itemCount(params)
  local count = (C_Item and C_Item.GetItemCount) or GetItemCount
  if not count then return 0 end
  local value = count(params.itemId, params.bank == true)
  if type(value) ~= "number" or LT.IsSecret(value) then return 0 end
  return value
end

Goals.RegisterKind("owned", {
  label = "SG_KIND_OWNED",
  group = "loot",
  usage = "SG_USAGE_OWNED",
  color = LT.Theme.COLORS.info,
  icon = ICON,
  texture = function(goal) return Kinds.ItemTexture(goal.params.itemId) end,
  tooltip = function(goal, tooltip) tooltip:SetHyperlink(Kinds.ItemHyperlink(goal.params)) end,
  form = { amount = "SG_FORM_AMOUNT", fields = {
    { type = "text", param = "item", label = "SG_FORM_ITEM", links = true },
    { type = "check", param = "bank", label = "SG_FORM_WITH_BANK" },
  } },
  -- "add owned <Link oder ID> <Anzahl> [bank]"
  parse = function(_, rest)
    local item, words = Kinds.SplitItemInput(rest)
    local params = { item = item }
    local amount
    for _, word in ipairs(words) do
      if word:lower() == "bank" then params.bank = true else amount = amount or tonumber(word) end
    end
    return params, amount
  end,
  prepare = function(params, target)
    Kinds.PrepareItem(params)
    return target
  end,
  validate = function(params, target)
    if not params.itemId then return L.SG_ERR_ITEM end
    return Kinds.ValidAmount(target)
  end,
  current = function(goal) return itemCount(goal.params) end,
  title = function(goal) return string.format(L.SG_GOAL_OWNED, Kinds.ItemLabel(goal.params), goal.target) end,
  body = function(goal) return goal.params.bank and L.SG_WITH_BANK or nil end,
})

---------------------------------------------------------------------------
-- Erfassung: Bestand nach jeder Taschenänderung
---------------------------------------------------------------------------
local function update()
  if not ns.db or not Goals.HasActive("owned") then return end
  Goals.SetEach("owned", function(goal) return itemCount(goal.params) end)
end

LT.RegisterEvent("BAG_UPDATE_DELAYED", update)
LT.OnLogin(update)
