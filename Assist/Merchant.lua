-- Händler: beim Öffnen (MERCHANT_SHOW) automatisch reparieren (autoRepair), optional zuerst aus
-- der Gildenbank (autoRepairGuild), und grauen Schrott verkaufen (autoSellJunk).
-- APIs wie in Blizzards MerchantFrame aller Clients: CanMerchantRepair, GetRepairAllCost
-- (Kosten, ob etwas zu reparieren ist), RepairAllItems(useGuildBank). Die Gildenbank gibt es nur,
-- wo CanGuildBankRepair existiert (nicht in Classic Era, siehe Client.HasGuildBank).
-- Ob die Gilde zahlen kann, ist vorher nicht verlässlich bekannt (GetGuildBankMoney ist 0 bzw. veraltet,
-- solange die Gildenbank in dieser Sitzung nicht offen war). Daher wie Blizzard einfach versuchen und
-- danach an den restlichen Kosten sehen, was die Gilde bezahlt hat; den Rest zahlt der Charakter. Das Abhebelimit
-- (GetGuildBankWithdrawMoney) wird aus demselben Grund nicht vorab geprüft; ein zu kleines Limit führt nur dazu,
-- dass der Charakter den Rest zahlt (Roadmap 179).
-- Schrott: Taschen über Bags.ForEachItem (quality, hasNoValue, isLocked); verkauft wird mit C_Container.UseContainerItem bei offenem Händler. Den Erlös zählt
-- MoneyCounter wie jede Einnahme, zusätzlich der Zähler moneyJunk (erwarteter Erlös).
local _, ns = ...
local L = ns.L
local Comfort = ns.Comfort
local Format = ns.Format

local Merchant = {}
ns.Merchant = Merchant

local POOR_QUALITY = 0               -- Enum.ItemQuality.Poor (grau)
local GUILD_REPAIR_CHECK_DELAY = 1   -- Sekunden, bis der Server die Gildenreparatur verbucht hat
local JUNK_SETTLE_DELAY = 1          -- Sekunden, bis der Server den Schrotterlös gutgeschrieben hat

local function wantsGuildRepair()
  return ns.db.autoRepairGuild and ns.Client.HasGuildBank() and CanGuildBankRepair()
end

local function repairPersonally(cost)
  if GetMoney() >= cost then
    RepairAllItems()
    ns.Print(string.format(L.REPAIRED, Format.Money(cost)))
  else
    ns.Print(string.format(L.REPAIR_NO_MONEY, Format.Money(cost)))
  end
end

-- Nach dem Versuch über die Gilde: bezahlt ist, was an Kosten weggefallen ist; Rest selbst zahlen
local function finishGuildRepair(cost)
  if not CanMerchantRepair() then return end  -- Händler inzwischen zu
  local left = GetRepairAllCost()
  ns.Debug("merchant", "guild repair: %s of %s left", left, cost)
  if left < cost then
    ns.Print(string.format(L.REPAIRED_GUILD, Format.Money(cost - left)))
  end
  if left > 0 then repairPersonally(left) end
end

function Merchant.Repair()
  if not Comfort.IsActive("autoRepair") or not CanMerchantRepair() then return end
  local cost, canRepair = GetRepairAllCost()
  ns.Debug("merchant", "repair cost %s, can repair %s", cost, canRepair)
  if not canRepair or cost <= 0 then return end
  if wantsGuildRepair() then
    RepairAllItems(true)
    C_Timer.After(GUILD_REPAIR_CHECK_DELAY, function() finishGuildRepair(cost) end)
  else
    repairPersonally(cost)
  end
end

local function isJunk(info)
  return info.quality == POOR_QUALITY and not info.hasNoValue and not info.isLocked
end

local function sellPrice(info)
  return (ns.Items.GetSellPrice(info.itemID) or 0) * info.stackCount
end

-- Erwarteter Erlös des Schrotts in den Taschen (0, wenn nicht verkauft wird)
local function junkValue()
  if not Comfort.IsActive("autoSellJunk") then return 0 end
  local total = 0
  ns.Bags.ForEachItem(function(_, _, info)
    if isJunk(info) then total = total + sellPrice(info) end
  end)
  return total
end

-- Alle grauen Gegenstände mit Verkaufswert verkaufen; Anzahl und erwarteter Erlös im Chat
function Merchant.SellJunk()
  if not Comfort.IsActive("autoSellJunk") then return end
  local count, total = 0, 0
  ns.Bags.ForEachItem(function(bag, slot, info)
    if isJunk(info) then
      count = count + 1
      total = total + sellPrice(info)
      C_Container.UseContainerItem(bag, slot)
    end
  end)
  ns.Debug("merchant", "sold %s junk items for %s", count, total)
  if count > 0 then
    ns.Stats.Increment(ns.Stats.MONEY_JUNK, total)
    ns.Print(string.format(L.JUNK_SOLD, count, Format.Money(total)))
  end
end

-- Reicht das Gold erst mit dem Schrotterlös, zuerst verkaufen und nach der Gutschrift reparieren.
-- Sonst erst reparieren, dann verkaufen: so kommt die Abbuchung getrennt von den Erlösen
-- (MoneyCounter ordnet Abbuchungen der Reparatur zu).
local function needsJunkMoney()
  if not Comfort.IsActive("autoRepair") or not CanMerchantRepair() then return false end
  local cost = GetRepairAllCost()
  return cost > GetMoney() and cost <= GetMoney() + junkValue()
end

ns.RegisterEvent("MERCHANT_SHOW", function()
  if needsJunkMoney() then
    Merchant.SellJunk()
    C_Timer.After(JUNK_SETTLE_DELAY, Merchant.Repair)
    return
  end
  Merchant.Repair()
  Merchant.SellJunk()
end)
