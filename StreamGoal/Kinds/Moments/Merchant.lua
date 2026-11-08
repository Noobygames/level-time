-- Momente beim Händler: "Quest-Belohnung verkaufen" und "Item aus Versehen verkaufen" (= wieder zurückkaufen).
-- Verkauft ist, was neu im Rückkauf-Fenster des Händlers steht: GetNumBuybackItems und C_MerchantFrame.GetBuybackItemID
-- (alle vier Clients laut MerchantFrameDocumentation; sonst die Item-ID aus GetBuybackItemLink), neu gelesen bei
-- MERCHANT_SHOW, MERCHANT_UPDATE und BAG_UPDATE_DELAYED, solange der Händler offen ist. Egal, wie verkauft wurde
-- (Rechtsklick, Ziehen, Verkaufs-Addons).
--   sellreward  Quest-Belohnungen: Items, die "Ihr erhaltet einen Gegenstand" (Loot.OnSelfLoot von Level Time, pushed)
--               bis REWARD_SECONDS nach einer Abgabe (QUEST_TURNED_IN) oder kurz davor meldet, je Charakter in
--               StreamGoalDB.questRewards[Charakter][itemID] = Zeitpunkt (höchstens MAX_REWARDS, älteste fallen weg).
--               Gemerkt wird immer, damit auch eine vor dem Ziel erhaltene Belohnung zählt; verkauft fällt sie heraus.
--   buyback     "Aus Versehen verkauft" erkennt das Spiel nicht, den Rückkauf schon: jeder Aufruf von BuybackItem
--               (Klick im Rückkauf-Reiter) zählt.
local _, ns = ...
local LT = ns.LT
local Moments = ns.Moments

local MerchantMoments = {}
ns.MerchantMoments = MerchantMoments

MerchantMoments.REWARD_SECONDS = 5
MerchantMoments.MAX_REWARDS = 100
local PUSHED_BEFORE_SECONDS = 2  -- die Meldung kann knapp vor QUEST_TURNED_IN kommen

local merchantOpen = false
local buyback = {}             -- [itemID] = Anzahl im Rückkauf-Fenster beim letzten Lesen
local turnedInAt               -- GetTime() der letzten Abgabe
local recentPushed = {}        -- { itemID, at } der letzten erhaltenen Items (vor der Abgabe gemeldet)

local function rewards()
  ns.db.questRewards = ns.db.questRewards or {}
  local list = ns.db.questRewards[LT.characterKey]
  if not list then
    list = {}
    ns.db.questRewards[LT.characterKey] = list
  end
  return list
end

function MerchantMoments.IsReward(itemID)
  return ns.db ~= nil and rewards()[itemID] ~= nil
end

local function remember(itemID)
  local list = rewards()
  list[itemID] = time()
  local count, oldest, oldestAt = 0, nil, nil
  for id, at in pairs(list) do
    count = count + 1
    if not oldestAt or at < oldestAt then oldest, oldestAt = id, at end
  end
  if count > MerchantMoments.MAX_REWARDS then list[oldest] = nil end
  ns.Debug("moment", "quest reward %s", itemID)
end

local function itemIdOf(link)
  return type(link) == "string" and not LT.IsSecret(link) and tonumber((link:match("item:(%d+)"))) or nil
end

LT.Loot.OnSelfLoot(function(link, _, pushed)
  if not ns.db or not pushed then return end
  local itemID = itemIdOf(link)
  if not itemID then return end
  local now = GetTime()
  if turnedInAt and now - turnedInAt <= MerchantMoments.REWARD_SECONDS then
    remember(itemID)
  else
    table.insert(recentPushed, { itemID = itemID, at = now })
    if #recentPushed > 10 then table.remove(recentPushed, 1) end
  end
end)

LT.RegisterEvent("QUEST_TURNED_IN", function()
  if not ns.db then return end
  local now = GetTime()
  turnedInAt = now
  for _, entry in ipairs(recentPushed) do
    if now - entry.at <= PUSHED_BEFORE_SECONDS then remember(entry.itemID) end
  end
  recentPushed = {}
end)

---------------------------------------------------------------------------
-- Rückkauf-Fenster lesen
---------------------------------------------------------------------------
local function buybackItemId(index)
  if C_MerchantFrame and C_MerchantFrame.GetBuybackItemID then
    local itemID = C_MerchantFrame.GetBuybackItemID(index)
    if not LT.IsSecret(itemID) and type(itemID) == "number" and itemID > 0 then return itemID end
  end
  return GetBuybackItemLink and itemIdOf(GetBuybackItemLink(index)) or nil
end

function MerchantMoments.ReadBuyback()
  local counts = {}
  local total = GetNumBuybackItems and GetNumBuybackItems() or 0
  if LT.IsSecret(total) then return counts end
  for index = 1, total do
    local itemID = buybackItemId(index)
    if itemID then counts[itemID] = (counts[itemID] or 0) + 1 end
  end
  return counts
end

local function onSold(itemID)
  ns.Debug("moment", "sold %s (quest reward %s)", itemID, MerchantMoments.IsReward(itemID))
  if MerchantMoments.IsReward(itemID) then
    rewards()[itemID] = nil
    Moments.Count("sellreward", 1)
  end
end

local function refresh()
  if not merchantOpen then return end
  local counts = MerchantMoments.ReadBuyback()
  for itemID, amount in pairs(counts) do
    if amount > (buyback[itemID] or 0) then onSold(itemID) end
  end
  buyback = counts
end

local events = LT.NewEventGroup()
events.Add("MERCHANT_SHOW", nil, function()
  merchantOpen = true
  buyback = MerchantMoments.ReadBuyback()
end)
events.Add("MERCHANT_CLOSED", nil, function() merchantOpen = false end)
events.Add("MERCHANT_UPDATE", nil, refresh)
events.Add("BAG_UPDATE_DELAYED", nil, refresh)

local function merchantAvailable()
  return GetNumBuybackItems ~= nil and (GetBuybackItemLink ~= nil or C_MerchantFrame ~= nil)
end

-- Ein Händler, der schon offen ist, wenn das Ziel entsteht: ab jetzt lesen
Moments.Register("sellreward", {
  label = "SG_MOMENT_SELLREWARD",
  title = "SG_GOAL_MOMENT_SELLREWARD",
  icon = "Interface\\Icons\\INV_Misc_Coin_02",
  available = merchantAvailable,
  events = events,
  onActive = function(isActive)
    if not isActive then
      merchantOpen = false
      return
    end
    local frame = MerchantFrame
    if not merchantOpen and frame and frame.IsShown and frame:IsShown() then
      merchantOpen = true
      buyback = MerchantMoments.ReadBuyback()
    end
  end,
})

if BuybackItem then
  hooksecurefunc("BuybackItem", function(index)
    if not ns.db or not Moments.IsActive("buyback") then return end
    ns.Debug("moment", "bought back slot %s", index)
    Moments.Count("buyback", 1)
  end)
end

Moments.Register("buyback", {
  label = "SG_MOMENT_BUYBACK",
  title = "SG_GOAL_MOMENT_BUYBACK",
  icon = "Interface\\Icons\\INV_Misc_Coin_01",
  available = function() return BuybackItem ~= nil end,
})
