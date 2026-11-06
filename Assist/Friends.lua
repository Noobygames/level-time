-- Vertraute Spieler für die Sozial-Funktionen (Social.lua): Charakter-Freunde, Battle.net-Freunde und
-- Gildenmitglieder. Communities zählen nicht (ihre Mitgliederlisten sind je Client verschieden).
-- Quellen (Blizzard_APIDocumentationGenerated, Retail/Forever und Classic Era gleich):
--   C_FriendList.IsFriend(guid) und C_FriendList.GetFriendInfo(name)  Freundesliste des Charakters
--   C_BattleNet.GetAccountInfoByGUID(guid).isFriend                    Battle.net-Freund (BattleTag/RealID)
--   C_GuildInfo.MemberExistsByName(name)                               Gildenmitglied
-- Die Gildenliste kennt der Client erst, wenn er sie einmal geladen hat (Gildenfenster, Roster-Abfrage);
-- ganz neue Mitglieder können daher fehlen. Geheime Namen oder GUIDs gelten als unbekannt (nicht vertraut).
local _, ns = ...

local Friends = {}
ns.Friends = Friends

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

-- true für Freunde und Gildenmitglieder; name ohne oder mit Realm, guid optional
function Friends.IsTrusted(name, guid)
  if ns.IsSecret(name) or ns.IsSecret(guid) then return false end
  if name == "" then name = nil end
  if guid == "" then guid = nil end
  if not (name or guid) then return false end
  return isCharacterFriend(name, guid) or isBattleNetFriend(guid) or isGuildMember(name)
end
