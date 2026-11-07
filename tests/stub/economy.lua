-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Geld, Questlog, Hooks, Händler, Gildenbank, Taschen, Quest-Aktionen, Dialoge, Ablehnungen.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state

-- Nur C_CurrencyInfo: das globale GetCoinTextureString ist im Client ein Kompatibilitäts-Alias
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end }
function GetTitleText() return state.questTitle end
function IsInInstance()
  if state.instance then return true, state.instance.type end
  return false, "none"
end
function UnitFactionGroup() return state.faction end
function GetBattlefieldWinner() return state.battlefieldWinner end
function GetInstanceInfo()
  if not state.instance then return GetZoneText() end
  return state.instance.name, state.instance.type, state.instance.difficulty or 1
end
C_QuestLog = {
  GetTitleForQuestID = function(questID) return state.questTitles[questID] end,
  IsQuestTrivial = function(questID) return state.trivialQuests[questID] or false end,
  IsRepeatableQuest = function(questID) return (state.repeatableQuests or {})[questID] == true end,
  -- Ziele je Quest: state.questLog[i] = { questID, title, isHeader, objectives = { { text, finished } } }
  GetQuestObjectives = function(questID)
    for _, quest in ipairs(state.questLog or {}) do
      if quest.questID == questID then return quest.objectives end
    end
  end,
}
-- Questlog wie in Classic Era/TBC (GetQuestLogTitle: 2. Level, 3. suggestedGroup, 8. questID); C_QuestLog.GetInfo
-- fehlt im Stub. Beobachtete Quests (Tracker): state.questWatches = { Log-Index, ... }
function GetNumQuestLogEntries() return #(state.questLog or {}) end
function GetQuestLogTitle(index)
  local quest = state.questLog[index]
  return quest.title, quest.level or 1, quest.suggestedGroup or 0, quest.isHeader or false, false, quest.isComplete, 0, quest.questID
end
-- Belohnungs-XP je Quest-ID: questLog[i].rewardXp
function GetQuestLogRewardXP(questID)
  for _, quest in ipairs(state.questLog or {}) do
    if quest.questID == questID then return quest.rewardXp or 0, quest.rewardXp or 0 end
  end
  return 0, 0
end
-- Quest-Item je Logeintrag: questLog[i].specialItem = { link, Symbol }
function GetQuestLogSpecialItemInfo(index)
  local item = ((state.questLog or {})[index] or {}).specialItem
  if item then return item[1], item[2], 0, false end
end
function GetNumQuestWatches() return #(state.questWatches or {}) end
function GetQuestIndexForWatch(index) return (state.questWatches or {})[index] end
function GetNumQuestLeaderBoards(index)
  local quest = (state.questLog or {})[index]
  return quest and #(quest.objectives or {}) or 0
end
function GetQuestID() return state.questID or 0 end
function strtrim(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end
-- Wie im Client: Funktion ersetzen, Original zuerst, dann der Hook
function hooksecurefunc(target, nameOrHook, maybeHook)
  local owner, name, hook = _G, target, nameOrHook
  if type(target) == "table" then owner, name, hook = target, nameOrHook, maybeHook end
  local original = owner[name]
  owner[name] = function(...)
    local results = { original(...) }
    hook(...)
    return unpack(results)
  end
end

-- Geldänderung durch den Server: kommt wie im Client erst später, mit PLAYER_MONEY (wow.runTimers)
local function serverMoneyUpdate(delta)
  C_Timer.After(0, function()
    state.money = state.money + delta
    wow.fire("PLAYER_MONEY")
  end)
end

-- Händler; RepairAllItems bucht die Kosten ab (mit PLAYER_MONEY) und merkt sich die Reparatur in wow.repairs
wow.repairs = {}
function CanMerchantRepair() return state.merchant.canRepair end
function GetRepairAllCost() return state.merchant.repairCost, state.merchant.repairCost > 0 end
-- Gildenreparatur gelingt nur, wenn das, was die Gilde dem Charakter zahlt (merchant.guildFunds:
-- Abhebelimit bzw. Bankstand), die Kosten deckt; sonst bleibt alles kaputt wie im Client
function RepairAllItems(useGuildBank)
  local merchant = state.merchant
  local cost = merchant.repairCost
  if useGuildBank then
    if merchant.guildFunds < cost then return end
    merchant.guildFunds = merchant.guildFunds - cost
  else
    serverMoneyUpdate(-cost)
  end
  table.insert(wow.repairs, { cost = cost, guild = useGuildBank and true or false })
  merchant.repairCost = 0
end
function CanGuildBankRepair() return state.merchant.guildRepair end
-- Nur bekannt, wenn die Gildenbank in dieser Sitzung offen war; das Addon verlässt sich nicht darauf
function GetGuildBankMoney() return 0 end

-- Taschen; UseContainerItem verkauft (Händler offen angenommen): Gegenstand weg, Geld dazu (PLAYER_MONEY)
C_Container = {
  GetContainerNumSlots = function(bag) return state.bags[bag] and state.bagSlots or 0 end,
  GetContainerItemInfo = function(bag, slot) return state.bags[bag] and state.bags[bag][slot] end,
  GetContainerNumFreeSlots = function(bag)
    local entry = state.freeSlots[bag]
    if not entry then return 0, 0 end
    return entry[1], entry[2]
  end,
  UseContainerItem = function(bag, slot)
    local info = state.bags[bag][slot]
    state.bags[bag][slot] = nil
    serverMoneyUpdate((state.sellPrices[info.itemID] or 0) * info.stackCount)
  end,
}
-- Quest-Aktionen landen in wow.questActions, z.B. { "accept" } oder { "selectAvailable", 123 }
wow.questActions = {}
local function questAction(...) table.insert(wow.questActions, { ... }) end
stub.questAction = questAction  -- auch für Gespräche mit NPCs (social.lua)
function QuestFlagsPVP() return state.questPvp end
function QuestGetAutoAccept() return state.questAutoAccept end
function AcceptQuest() questAction("accept") end
function AcknowledgeAutoAcceptQuest() questAction("acknowledge") end
function ConfirmAcceptQuest() questAction("confirm") end
function StaticPopup_Hide(name) questAction("hidePopup", name) end
function DeclineQuest() questAction("decline") end
-- Sichtbarer Dialog (StaticPopup_FindVisible): wow.visiblePopups[name] = Dialog-Frame
wow.visiblePopups = {}
function StaticPopup_FindVisible(name) return wow.visiblePopups[name] end
-- Abgelehnte Anfragen landen in wow.declined (Name der Funktion)
wow.declined = {}
for _, name in ipairs({ "CancelTrade", "DeclineGroup", "DeclineGuild", "CancelDuel" }) do
  _G[name] = function() table.insert(wow.declined, name) end
end
