-- Vertraute Spieler für die Sozial-Funktionen (Social.lua): Charakter-Freunde, Battle.net-Freunde und
-- Gildenmitglieder, mit friendlyCommunities (Standard aus) auch Mitglieder der eigenen Charakter-Communities.
-- Quellen (Blizzard_APIDocumentationGenerated, Retail/Forever und Classic Era gleich):
--   C_FriendList.IsFriend(guid) und C_FriendList.GetFriendInfo(name)  Freundesliste des Charakters
--   C_BattleNet.GetAccountInfoByGUID(guid).isFriend                    Battle.net-Freund (BattleTag/RealID)
--   C_GuildInfo.MemberExistsByName(name)                               Gildenmitglied
--   C_Club.GetSubscribedClubs() / GetClubMembers(clubId) / GetMemberInfo(clubId, memberId)
--                                                                      Communities (ClubDocumentation.lua in allen
--                                                                      vier Clients). Nur clubType Character:
--                                                                      Battle.net-Communities nennen BattleTags.
-- Die Gildenliste kennt der Client erst, wenn er sie einmal geladen hat (Gildenfenster, Roster-Abfrage);
-- ganz neue Mitglieder können daher fehlen. Geheime Namen oder GUIDs gelten als unbekannt (nicht vertraut).
local _, ns = ...

local Friends = {}
ns.Friends = Friends

-- Enum.ClubType.Character (ClubDocumentation.lua, alle Clients)
local CHARACTER_CLUB = Enum and Enum.ClubType and Enum.ClubType.Character or 1

local function isCharacterFriend(name, guid)
  if not C_FriendList then return false end
  if guid and C_FriendList.IsFriend and C_FriendList.IsFriend(guid) then return true end
  return name ~= nil and C_FriendList.GetFriendInfo ~= nil and C_FriendList.GetFriendInfo(name) ~= nil
end

local function isBattleNetFriend(guid)
  if not (guid and C_BattleNet and C_BattleNet.GetAccountInfoByGUID) then return false end
  local info = C_BattleNet.GetAccountInfoByGUID(guid)
  return type(info) == "table" and info.isFriend == true
end

local function isGuildMember(name)
  if not (name and IsInGuild() and C_GuildInfo and C_GuildInfo.MemberExistsByName) then return false end
  return C_GuildInfo.MemberExistsByName(name) == true
end

---------------------------------------------------------------------------
-- Communities: Namen und GUIDs aller Mitglieder, erst bei Bedarf gelesen und bis zur nächsten Änderung gemerkt
---------------------------------------------------------------------------
local communityMembers  -- { [guid] = true, [Name] = true, [Name-Realm] = true }; nil = neu lesen

function Friends.CanUseCommunities()
  return C_Club ~= nil and C_Club.GetSubscribedClubs ~= nil and C_Club.GetClubMembers ~= nil
    and C_Club.GetMemberInfo ~= nil
end

-- Name ohne Realm, wenn der Realm der eigene ist (so melden Einladungen Spieler vom eigenen Realm)
local function shortName(name)
  local base, realm = name:match("^([^%-]+)%-(.+)$")
  if base and GetNormalizedRealmName and realm == GetNormalizedRealmName() then return base end
  return name
end

local function addMember(members, info)
  if type(info) ~= "table" or info.isSelf == true then return end
  if type(info.guid) == "string" and not ns.IsSecret(info.guid) then members[info.guid] = true end
  if type(info.name) == "string" and not ns.IsSecret(info.name) and info.name ~= "" then
    members[info.name] = true
    members[shortName(info.name)] = true
  end
end

local function readCommunities()
  local members = {}
  for _, club in ipairs(C_Club.GetSubscribedClubs() or {}) do
    if club.clubType == CHARACTER_CLUB then
      for _, memberId in ipairs(C_Club.GetClubMembers(club.clubId) or {}) do
        addMember(members, C_Club.GetMemberInfo(club.clubId, memberId))
      end
    end
  end
  return members
end

function Friends.InvalidateCommunities()
  communityMembers = nil
end

local function isCommunityMember(name, guid)
  if not (ns.db and ns.db.friendlyCommunities and Friends.CanUseCommunities()) then return false end
  if not communityMembers then
    communityMembers = readCommunities()
    ns.Debug("social", "community members read")
  end
  return (guid ~= nil and communityMembers[guid] == true) or (name ~= nil and communityMembers[name] == true)
end

-- Änderungen an Communities nur verfolgen, solange die Einstellung an ist
local clubEvents = ns.NewEventGroup()
for _, event in ipairs({ "CLUB_ADDED", "CLUB_REMOVED", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED",
  "CLUB_MEMBER_UPDATED" }) do
  clubEvents.Add(event, nil, Friends.InvalidateCommunities)
end

ns.RegisterApply(function(db)
  local active = db.friendlyCommunities == true and Friends.CanUseCommunities()
  if not active then communityMembers = nil end
  clubEvents.SetActive(active)
end)

-- true für Freunde und Gildenmitglieder (mit friendlyCommunities auch Communities); name ohne oder mit Realm,
-- guid optional
function Friends.IsTrusted(name, guid)
  if ns.IsSecret(name) or ns.IsSecret(guid) then return false end
  if name == "" then name = nil end
  if guid == "" then guid = nil end
  if not (name or guid) then return false end
  return isCharacterFriend(name, guid) or isBattleNetFriend(guid) or isGuildMember(name)
    or isCommunityMember(name, guid)
end
