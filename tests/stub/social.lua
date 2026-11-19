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
-- Gruppensuche: state.lfgResults[resultID] = { { name = ..., areaName = ... }, ... } (Mitglieder)
-- Weitere Felder: state.lfgInfo[resultID] (Felder von GetSearchResultInfo), state.lfgActivities[activityID] = { mapID,
-- maxNumPlayers }, state.lfgEncounters[resultID] = { Bossnamen }, state.lfgMemberCounts[resultID] = { TANK, HEALER, DAMAGER },
-- state.lfgLanguages = { filter = { enUS = true }, available = { "enUS", "deDE" }, defaults = {}, saved = Aufrufe }
C_LFGList = {
  GetSearchResultInfo = function(resultID)
    local members = (state.lfgResults or {})[resultID]
    if not members then return nil end
    local info = { searchResultID = resultID, numMembers = #members, numBNetFriends = 0, numCharFriends = 0, numGuildMates = 0,
      isDelisted = false }
    for key, value in pairs((state.lfgInfo or {})[resultID] or {}) do info[key] = value end
    return info
  end,
  GetActivityInfoTable = function(activityID) return (state.lfgActivities or {})[activityID] end,
  GetSearchResultEncounterInfo = function(resultID) return (state.lfgEncounters or {})[resultID] end,
  GetSearchResultMemberCounts = function(resultID) return (state.lfgMemberCounts or {})[resultID] end,
  GetLanguageSearchFilter = function()
    if not state.lfgLanguages then return nil end
    local copy = {}
    for language, enabled in pairs(state.lfgLanguages.filter) do copy[language] = enabled end
    return copy
  end,
  GetAvailableLanguageSearchFilter = function() return state.lfgLanguages and state.lfgLanguages.available end,
  SaveLanguageSearchFilter = function(filter)
    state.lfgLanguages.filter = filter
    state.lfgLanguages.saved = (state.lfgLanguages.saved or 0) + 1
  end,
  GetSearchResultPlayerInfo = function(resultID, index) return ((state.lfgResults or {})[resultID] or {})[index] end,
  -- Gruppensuche-Fenster: state.lfgWindow = { categories = { [id] = name }, activities = { [categoryID] = { activityIDs } },
  -- filtered = { resultIDs }, entry = aktiver Eintrag oder nil }; Suche, Eintrag und Rollen landen in wow.lfgCalls
  GetAvailableCategories = function()
    local ids = {}
    for id in pairs((state.lfgWindow or {}).categories or {}) do table.insert(ids, id) end
    table.sort(ids)
    return ids
  end,
  GetLfgCategoryInfo = function(id) return { name = state.lfgWindow.categories[id] } end,
  GetAvailableActivities = function(categoryID) return state.lfgWindow.activities[categoryID] or {} end,
  GetFilteredSearchResults = function() return #state.lfgWindow.filtered, state.lfgWindow.filtered end,
  GetDefaultLanguageSearchFilter = function() return state.lfgLanguages and state.lfgLanguages.defaults or { enUS = true } end,
  Search = function(...) table.insert(wow.lfgCalls, { "Search", ... }) end,
  HasActiveEntryInfo = function() return state.lfgWindow ~= nil and state.lfgWindow.entry ~= nil end,
  GetActiveEntryInfo = function() return state.lfgWindow and state.lfgWindow.entry end,
  CreateListing = function(data) table.insert(wow.lfgCalls, { "CreateListing", data }) end,
  UpdateListing = function(data) table.insert(wow.lfgCalls, { "UpdateListing", data }) end,
  RemoveListing = function() table.insert(wow.lfgCalls, { "RemoveListing" }) end,
  GetSearchResults = function()
    local ids = {}
    for resultID in pairs(state.lfgResults or {}) do table.insert(ids, resultID) end
    table.sort(ids)
    return #ids, ids
  end,
}
wow.lfgCalls = {}
Enum = Enum or {}
Enum.LFGEntryGeneralPlaystyle = { None = 0, Learning = 1, FunRelaxed = 2, FunSerious = 3, Expert = 4 }
Enum.LFGEntryVoiceMode = { None = 0, Legacy = 1, Discord = 2, Custom = 3 }
GetGeneralPlaystyleString = function(playstyle) return "Spielstil" .. playstyle end
C_LFGListRoles = { GetRoles = function() return state.lfgRoles or {} end,
  SetRoles = function(roles) table.insert(wow.lfgCalls, { "SetRoles", roles }) state.lfgRoles = roles end }
function UnitIsGroupAssistant() return false end
-- Rollenabfrage (Blizzards RolePollButton): landet in wow.lfgCalls
function InitiateRolePoll() table.insert(wow.lfgCalls, { "InitiateRolePoll" }) return true end
-- Blizzards Gruppensuche im Vanilla-Stil (Blizzard_LFGVanilla_ParentFrame.lua): Zeigen merkt den Reiter, Umschalten
-- schließt bei gleichem oder ohne Reiter
LFGParentFrame = CreateFrame("Frame")
function LFGVanilla_ShowFrame(tab)
  LFGParentFrame:Show()
  LFGParentFrame.selectedTab = tab or LFGParentFrame.selectedTab or 1
end
function LFGVanilla_ToggleFrame(tab)
  if LFGParentFrame:IsShown() and (not tab or tab == LFGParentFrame.selectedTab) then
    HideUIPanel(LFGParentFrame)
  else
    LFGVanilla_ShowFrame(tab)
  end
end
function HideUIPanel(frame) frame:Hide() end
-- Blizzards Reiter (SharedUIPanelTemplates.lua): nur der gewählte Reiter wird gemerkt
function PanelTemplates_SetNumTabs(frame, count) frame.numTabs = count end
function PanelTemplates_SetTab(frame, id) frame.selectedTab = id end
function PanelTemplates_TabResize() end
ChatFrameUtil = ChatFrameUtil or {}
ChatFrameUtil.SendTell = function(name) socialAction("tell", name) end
-- Blizzards Tooltip-Aufbau: Retail (GameTooltip) und Classic Era (eigener Rahmen), damit Hooks darauf greifen
function LFGListUtil_SetSearchEntryTooltip(tooltip, resultID)
  tooltip:SetOwner(UIParent, "ANCHOR_RIGHT")
  tooltip:AddLine("Gruppe " .. resultID)
end
function LFGBrowseSearchEntry_Update() end
-- Classic-Stil: Rahmen mit Leader-Zeile und Pool der Mitgliedszeilen; setzt Größe wie Blizzard bei jedem Aufruf neu
local function lfgRow()
  local row = CreateFrame("Frame")
  row.Name = row:CreateFontString()
  row.Name:SetText("")
  row.Level = row:CreateFontString()
  row.Roles = {}
  return row
end
LFGBrowseSearchEntryTooltip = CreateFrame("Frame")
LFGBrowseSearchEntryTooltip.Leader = lfgRow()
do
  local active, free = {}, {}
  LFGBrowseSearchEntryTooltip.memberPool = {
    ReleaseAll = function() for _, row in ipairs(active) do row:Hide(); table.insert(free, row) end active = {} end,
    Acquire = function() local row = table.remove(free) or lfgRow(); table.insert(active, row); return row end,
    EnumerateActive = function() local i = 0; return function() i = i + 1; return active[i] end end,
  }
end
function LFGBrowseSearchEntryTooltip_UpdateAndShow(self, resultID)
  local pool = self.memberPool
  pool:ReleaseAll()
  local leader
  for index, info in ipairs((state.lfgResults or {})[resultID] or {}) do
    if index == 1 then leader = info
    else
      local row = pool:Acquire()
      row.Name:SetText(info.name); row:Show()
    end
  end
  self.Leader.Name:SetText(leader and leader.name or ""); self.Leader:SetShown(leader ~= nil)
  self:SetWidth(150); self:SetHeight(100); self:Show()
end
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
  return quest.isTrivial, quest.frequency, quest.isRepeatable, quest.isLegendary, quest.questID
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

-- Item-Mixin (Blizzard_ObjectAPI): state.unknownItems[itemID] = true = der Client kennt das Item nicht (IsItemEmpty);
-- ContinueOnItemLoad merkt den Rückruf in state.itemLoads[itemID], der Test ruft ihn nach dem Setzen des Links
Item = {
  CreateFromItemID = function(_, itemID)
    return {
      IsItemEmpty = function() return (state.unknownItems or {})[itemID] == true end,
      ContinueOnItemLoad = function(_, callback)
        state.itemLoads = state.itemLoads or {}
        state.itemLoads[itemID] = callback
      end,
    }
  end,
}

C_Item = {
  GetItemCount = function(itemID) return (state.itemCounts or {})[itemID] or 0 end,
  -- itemID oder Link; Link aus state.itemLinks (fehlt = noch nicht geladen), Verkaufspreis aus state.sellPrices
  GetItemInfo = function(itemID)
    return "Item " .. itemID, (state.itemLinks or {})[itemID], nil, nil, nil, nil, nil, nil, nil, nil, state.sellPrices[itemID]
  end,
  -- Wie im Client: nichts für unbekannte IDs, sonst itemID, Typ, Untertyp, Platz, Symbol, Klasse, Unterklasse
  GetItemInfoInstant = function(item)
    local itemID = type(item) == "string" and tonumber(item:match("item:(%d+)")) or item
    local icon = state.itemIcons[itemID]
    if not icon then return nil end
    -- Klasse/Unterklasse je itemID: state.itemClasses[itemID] = { classID, subClassID }; sonst Rüstung/Leder
    local class = (state.itemClasses or {})[itemID] or { 4, 2 }
    return itemID, "Rüstung", "Leder", (state.equipLocs or {})[itemID] or "INVTYPE_FEET", icon, class[1], class[2]
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
