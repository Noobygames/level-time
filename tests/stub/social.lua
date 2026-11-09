-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Sozial, Spieler-Infos, Gespräche mit NPCs, Questbelohnungen, Gegenstände.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state
local questAction = stub.questAction

-- Sozial: Annahmen, Einladungen und abgelehnte Freundschaftsanfragen landen in wow.socialActions
wow.socialActions = {}
local function socialAction(...) table.insert(wow.socialActions, { ... }) end
function AcceptGroup() socialAction("acceptGroup") end
C_FriendList = {
  IsFriend = function(guid) return state.friends[guid] == true end,
  GetFriendInfo = function(name) if state.friends[name] then return { name = name } end end,
}
C_BattleNet = {
  GetAccountInfoByGUID = function(guid) if state.bnetFriends[guid] then return { isFriend = true } end end,
  GetAccountInfoByID = function(id) return state.bnetAccounts[id] end,
  GetFriendInviteInfo = function(index) return state.friendInvites[index] end,
  InviteFriend = function(gameAccountID) socialAction("bnetInvite", gameAccountID) end,
}
C_GuildInfo = { MemberExistsByName = function(name) return state.guildMembers[name] == true end }
local function clubById(clubId)
  for _, club in ipairs(state.clubs) do if club.clubId == clubId then return club end end
end
C_Club = {
  GetSubscribedClubs = function()
    local list = {}
    for _, club in ipairs(state.clubs) do table.insert(list, { clubId = club.clubId, clubType = club.clubType }) end
    return list
  end,
  GetClubMembers = function(clubId)
    local ids = {}
    for index in ipairs((clubById(clubId) or { members = {} }).members) do table.insert(ids, index) end
    return ids
  end,
  GetMemberInfo = function(clubId, memberId)
    local club = clubById(clubId)
    return club and club.members[memberId]
  end,
}
C_PartyInfo = { InviteUnit = function(name) socialAction("invite", name) end }
function BNGetNumFriendInvites() return #state.friendInvites end
function BNDeclineFriendInvite(inviteID)
  for index, invite in ipairs(state.friendInvites) do
    if invite.inviteID == inviteID then table.remove(state.friendInvites, index) end
  end
  socialAction("declineFriend", inviteID)
end
function UnitIsGroupLeader() return state.groupLeader end
-- Spieler-Infos je GUID: state.playerInfo[guid] = { localizedClass, englishClass, localizedRace, englishRace, ... }
function GetPlayerInfoByGUID(guid)
  local info = (state.playerInfo or {})[guid]
  if info then return unpack(info) end
end
C_GossipInfo = {
  GetAvailableQuests = function() return state.gossip.available end,
  GetActiveQuests = function() return state.gossip.active end,
  GetOptions = function() return state.gossip.options end,
  GetNumAvailableQuests = function() return #state.gossip.available end,
  GetNumActiveQuests = function() return #state.gossip.active end,
  ForceGossip = function() return false end,
  SelectAvailableQuest = function(questID) questAction("selectAvailable", questID) end,
  SelectActiveQuest = function(questID) questAction("selectActive", questID) end,
  SelectOptionByIndex = function(index) questAction("selectOption", index) end,
  SelectOption = function(optionID) questAction("selectOption", optionID) end,
}
function GetNumAvailableQuests() return #state.greeting.available end
function GetAvailableQuestInfo(index)
  local quest = state.greeting.available[index]
  return quest.isTrivial, quest.frequency, quest.isRepeatable
end
function SelectAvailableQuest(index) questAction("greetingAvailable", index) end
function GetNumActiveQuests() return #state.greeting.active end
function GetAvailableTitle(index) return state.greeting.available[index].title end
function GetActiveTitle(index)
  local quest = state.greeting.active[index]
  return quest.title, quest.isComplete
end
function SelectActiveQuest(index) questAction("greetingActive", index) end
function IsQuestCompletable() return state.questCompletable end
function CompleteQuest() questAction("complete") end
function GetQuestMoneyToGet() return state.questMoney end
function GetNumQuestChoices() return #state.questChoices end
function GetQuestItemLink(kind, index) return kind == "choice" and state.questChoices[index] or nil end
-- 5. Wert isUsable: state.questChoiceUnusable[i] = true für nicht benutzbare Wahlen
function GetQuestItemInfo(kind, index)
  if kind ~= "choice" or not state.questChoices[index] then return nil end
  return "Wahl " .. index, 134000, 1, 2, not (state.questChoiceUnusable or {})[index]
end
-- Angelegte Ausrüstung: state.equipped[platz] = Link
function GetInventoryItemLink(_, slot) return (state.equipped or {})[slot] end
function GetQuestReward(choice) questAction("reward", choice) end

C_Item = {
  GetItemCount = function(itemID) return (state.itemCounts or {})[itemID] or 0 end,
  -- itemID oder Link; Verkaufspreis aus state.sellPrices
  GetItemInfo = function(itemID)
    return "Item " .. itemID, nil, nil, nil, nil, nil, nil, nil, nil, nil, state.sellPrices[itemID]
  end,
  -- Wie im Client: nichts für unbekannte IDs, sonst itemID, Typ, Untertyp, Platz, Symbol, Klasse, Unterklasse
  GetItemInfoInstant = function(item)
    local itemID = type(item) == "string" and tonumber(item:match("item:(%d+)")) or item
    local icon = state.itemIcons[itemID]
    if not icon then return nil end
    return itemID, "Rüstung", "Leder", (state.equipLocs or {})[itemID] or "INVTYPE_FEET", icon, 4, 2
  end,
  GetItemIconByID = function(itemID) return state.itemIcons[itemID] end,
  -- Zauber eines benutzbaren Items: state.itemSpells[itemID] = { name, id }; sonst nichts
  GetItemSpell = function(itemID)
    local spell = (state.itemSpells or {})[itemID]
    if spell then return spell.name, spell.id end
  end,
  -- Itemlevel je itemID: state.itemLevels
  GetDetailedItemLevelInfo = function(item)
    local itemID = type(item) == "string" and tonumber(item:match("item:(%d+)")) or item
    return (state.itemLevels or {})[itemID]
  end,
}
