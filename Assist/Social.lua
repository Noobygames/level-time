-- Sozial-Komfort (Reiter Komfort, Sozial; je Einstellung, Standard aus). Vertraut = Freund oder Gilde (Friends.lua).
--   declineSharedQuests  Von Mitspielern geteilte Quests ablehnen, außer von Vertrauten: QUEST_DETAIL mit einem
--                        Spieler als "questnpc" -> DeclineQuest (wie die Ablehnen-Taste des QuestFrame);
--                        Eskorten (QUEST_ACCEPT_CONFIRM, Name des Starters) -> Dialog QUEST_ACCEPT schließen (er hat
--                        kein OnCancel, Nein schließt ihn nur). Gewinnt gegen autoAcceptShared: QuestAutomation fragt
--                        Social.DeclinesSharedQuest, damit nie beide handeln.
--   blockFriendRequests  Battle.net-Freundschaftsanfragen (BattleTag/RealID) ablehnen: BN_FRIEND_INVITE_ADDED und
--                        _LIST_INITIALIZED, Liste BNGetNumFriendInvites, Info C_BattleNet.GetFriendInviteInfo (Retail/
--                        Forever) bzw. BNGetFriendInviteInfo (Classic), BNDeclineFriendInvite(inviteID) wie der
--                        Ablehnen-Eintrag im FriendsFrame. Ohne diese Funktionen fehlt der Schalter (available).
--   acceptFriendInvites  Gruppeneinladungen von Vertrauten annehmen: PARTY_INVITE_REQUEST(name, ..., inviterGUID) ->
--                        AcceptGroup, Dialog PARTY_INVITE mit inviteAccepted schließen (sein OnHide lehnt sonst ab).
--                        Bleibt manuell: Einladungen mit Rollenwahl (LFGInvitePopup), Gruppensynchronisation und
--                        wenn die Annahme Warteschlangen verlassen würde (WillAcceptInviteRemoveQueues).
--                        Zusammen mit declineGroupInvites (Declines.lua): Vertraute werden nie abgelehnt
--                        (Social.TrustsInviter), alle anderen schon.
--   inviteFromWhisper    Wer das Stichwort inviteKeyword (Standard "inv") flüstert, wird eingeladen: CHAT_MSG_WHISPER
--                        (Text, Absender, ..., GUID) -> C_PartyInfo.InviteUnit (Classic: InviteUnit);
--                        CHAT_MSG_BN_WHISPER (13. Argument = Battle.net-Konto) -> C_BattleNet.InviteFriend
--                        (BNInviteFriend) für das WoW-Spielkonto im selben Spiel. Nur ohne Gruppe oder als
--                        Leiter/Assistent. In Retail/Forever sind Flüstertexte in der Chat-Sperre
--                        (C_ChatInfo.InChatMessagingLockdown) geheim: dann nichts.
-- Wie Declines.lua ohne Comfort.IsActive: die Anfrage kommt vom anderen Spieler, Umschalt wäre Zufall.
local _, ns = ...
local L = ns.L
local Friends = ns.Friends

local Social = {}
ns.Social = Social

local QUEST_ACCEPT_POPUP = "QUEST_ACCEPT"
local PARTY_INVITE_POPUP = "PARTY_INVITE"
local QUEST_GIVER = "questnpc"
local WOW_CLIENT = BNET_CLIENT_WOW or "WoW"  -- clientProgram eines WoW-Spielkontos
local INVITE_ACCEPTED = 1                    -- Blizzards Merker im PARTY_INVITE-Dialog

---------------------------------------------------------------------------
-- Geteilte Quests
---------------------------------------------------------------------------

-- true, wenn eine von diesem Spieler geteilte Quest abgelehnt wird (auch für QuestAutomation)
function Social.DeclinesSharedQuest(name, guid)
  return ns.db ~= nil and ns.db.declineSharedQuests == true and not Friends.IsTrusted(name, guid)
end

local function sharer()
  if not (UnitExists(QUEST_GIVER) and UnitIsPlayer(QUEST_GIVER)) then return nil end
  return UnitName(QUEST_GIVER), UnitGUID(QUEST_GIVER)
end

ns.RegisterEvent("QUEST_DETAIL", function()
  local name, guid = sharer()
  if not name or ns.IsSecret(name) or not Social.DeclinesSharedQuest(name, guid) then return end
  ns.Debug("social", "declining quest shared by %s", name)
  DeclineQuest()
  ns.Print(string.format(L.DECLINED_SHARED_QUEST, name))
end)

ns.RegisterEvent("QUEST_ACCEPT_CONFIRM", function(name)
  if ns.IsSecret(name) or not Social.DeclinesSharedQuest(name) then return end
  ns.Debug("social", "declining escort from %s", name)
  StaticPopup_Hide(QUEST_ACCEPT_POPUP)
  ns.Print(string.format(L.DECLINED_SHARED_QUEST, name or L.UNKNOWN_NAME))
end)

---------------------------------------------------------------------------
-- Freundschaftsanfragen
---------------------------------------------------------------------------

function Social.CanBlockFriendRequests()
  return BNGetNumFriendInvites ~= nil and BNDeclineFriendInvite ~= nil
    and ((C_BattleNet and C_BattleNet.GetFriendInviteInfo) or BNGetFriendInviteInfo) ~= nil
end

local function friendInvite(index)
  if C_BattleNet and C_BattleNet.GetFriendInviteInfo then
    local info = C_BattleNet.GetFriendInviteInfo(index)
    if info then return info.inviteID, info.accountName end
    return nil
  end
  return BNGetFriendInviteInfo(index)
end

-- Alle offenen Anfragen ablehnen; rückwärts, weil die Liste beim Ablehnen schrumpft
local function declineFriendRequests()
  if not ns.db.blockFriendRequests or not Social.CanBlockFriendRequests() then return end
  for index = BNGetNumFriendInvites() or 0, 1, -1 do
    local inviteID, accountName = friendInvite(index)
    if inviteID then
      ns.Debug("social", "declining friend request %s", inviteID)
      BNDeclineFriendInvite(inviteID)
      ns.Print(string.format(L.DECLINED_FRIEND_REQUEST, accountName or L.UNKNOWN_NAME))
    end
  end
end

ns.RegisterEvent("BN_FRIEND_INVITE_ADDED", declineFriendRequests)
ns.RegisterEvent("BN_FRIEND_INVITE_LIST_INITIALIZED", declineFriendRequests)
ns.RegisterApply(function(db)
  if db.blockFriendRequests then declineFriendRequests() end  -- beim Einschalten schon wartende Anfragen
end)

---------------------------------------------------------------------------
-- Gruppeneinladungen von Vertrauten
---------------------------------------------------------------------------

-- true, wenn Einladungen dieses Spielers angenommen statt abgelehnt werden (auch für Declines.lua)
function Social.TrustsInviter(name, guid)
  return ns.db ~= nil and ns.db.acceptFriendInvites == true and Friends.IsTrusted(name, guid)
end

local function closeInvitePopup()
  local dialog = StaticPopup_FindVisible and StaticPopup_FindVisible(PARTY_INVITE_POPUP)
  if dialog then dialog.inviteAccepted = INVITE_ACCEPTED end
  StaticPopup_Hide(PARTY_INVITE_POPUP)
end

ns.RegisterEvent("PARTY_INVITE_REQUEST", function(name, isTank, isHealer, isDamage, _, _, inviterGUID, questSessionActive)
  if not Social.TrustsInviter(name, inviterGUID) then return end
  if isTank or isHealer or isDamage or questSessionActive then
    ns.Debug("social", "invite from %s needs roles or party sync, left to the player", name)
    return
  end
  if WillAcceptInviteRemoveQueues and WillAcceptInviteRemoveQueues() then
    ns.Debug("social", "invite from %s would leave queues, left to the player", name)
    return
  end
  ns.Debug("social", "accepting invite from %s", name)
  AcceptGroup()
  closeInvitePopup()
  ns.Print(string.format(L.ACCEPTED_GROUP_INVITE, name))
end)

---------------------------------------------------------------------------
-- Einladen per Flüster-Stichwort
---------------------------------------------------------------------------

function Social.IsInviteKeyword(text)
  local keyword = ns.db.inviteKeyword
  if type(text) ~= "string" or type(keyword) ~= "string" then return false end
  keyword = strtrim(keyword)
  return keyword ~= "" and strtrim(text):lower() == keyword:lower()
end

-- Einladen dürfen: ohne Gruppe, sonst als Leiter oder Assistent
local function canInvite()
  if not IsInGroup() then return true end
  return UnitIsGroupLeader("player") or (UnitIsGroupAssistant ~= nil and UnitIsGroupAssistant("player"))
end

local function wantsInvite(text, sender)
  if not ns.db.inviteFromWhisper then return false end
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return false end
  if ns.IsSecret(text) or ns.IsSecret(sender) or not Social.IsInviteKeyword(text) then return false end
  if not canInvite() then
    ns.Debug("social", "whisper invite from %s skipped: not leader", sender)
    return false
  end
  return true
end

local function inviteCharacter(name)
  if C_PartyInfo and C_PartyInfo.InviteUnit then
    C_PartyInfo.InviteUnit(name)
  else
    InviteUnit(name)
  end
end

-- WoW-Spielkonto eines Battle.net-Freunds im selben Spiel (gleiche WoW-Version); nil, wenn nicht einladbar
local function battleNetGameAccount(bnetAccountID)
  if not (bnetAccountID and C_BattleNet and C_BattleNet.GetAccountInfoByID) then return nil end
  local info = C_BattleNet.GetAccountInfoByID(bnetAccountID)
  local game = info and info.gameAccountInfo
  if not (game and game.isOnline and game.clientProgram == WOW_CLIENT and game.gameAccountID) then return nil end
  if game.wowProjectID and WOW_PROJECT_ID and game.wowProjectID ~= WOW_PROJECT_ID then return nil end
  return game.gameAccountID
end

local function inviteBattleNetFriend(gameAccountID)
  if C_BattleNet and C_BattleNet.InviteFriend then
    C_BattleNet.InviteFriend(gameAccountID)
  else
    BNInviteFriend(gameAccountID)
  end
end

ns.RegisterEvent("CHAT_MSG_WHISPER", function(text, sender)
  if not wantsInvite(text, sender) then return end
  ns.Debug("social", "inviting %s (whisper keyword)", sender)
  inviteCharacter(sender)
  ns.Print(string.format(L.WHISPER_INVITED, sender))
end)

ns.RegisterEvent("CHAT_MSG_BN_WHISPER", function(text, sender, ...)
  if not wantsInvite(text, sender) then return end
  local bnetAccountID = select(11, ...)  -- 13. Argument des Events
  local gameAccountID = not ns.IsSecret(bnetAccountID) and battleNetGameAccount(bnetAccountID)
  if not gameAccountID then
    ns.Debug("social", "battle.net whisper invite skipped: no game account")
    return
  end
  ns.Debug("social", "inviting battle.net friend %s", gameAccountID)
  inviteBattleNetFriend(gameAccountID)
  ns.Print(string.format(L.WHISPER_INVITED, sender))
end)
