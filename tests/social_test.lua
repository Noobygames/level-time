-- Sozial-Komfort: geteilte Quests ablehnen (gewinnt gegen autoAcceptShared), Freundschaftsanfragen blocken,
-- Einladungen von Freunden/Gilde annehmen (declineGroupInvites lässt sie durch), Einladen per Flüster-Stichwort
local L = addon.L
local state = wow.state

local function lastQuestAction() return wow.questActions[#wow.questActions] end
local function lastSocial() return wow.socialActions[#wow.socialActions] or {} end
local function count(list, kind)
  local n = 0
  for _, entry in ipairs(list) do if entry[1] == kind then n = n + 1 end end
  return n
end

wow.login({ inGuild = true })

---------------------------------------------------------------------------
-- Geteilte Quests
---------------------------------------------------------------------------
state.units.questnpc = { name = "Fremder", isPlayer = true, guid = "Player-1-0002" }
addon.Set("autoAcceptShared", true)
wow.fire("QUEST_DETAIL")
expect("ohne Ablehnen: geteilte Quest angenommen", lastQuestAction()[1], "accept")

addon.Set("declineSharedQuests", true)
wow.questActions = {}
wow.fire("QUEST_DETAIL")
expect("Fremder: abgelehnt", count(wow.questActions, "decline"), 1)
expect("Fremder: nicht zusätzlich angenommen", count(wow.questActions, "accept"), 0)
expectTrue("Chatzeile", wow.printed[#wow.printed]:find(string.format(L.DECLINED_SHARED_QUEST, "Fremder"), 1, true) ~= nil)

-- Freund (über GUID), Battle.net-Freund und Gildenmitglied: angenommen wie bisher
for _, trusted in ipairs({
  { label = "Freund", setup = function() state.friends["Player-1-0002"] = true end },
  { label = "Battle.net-Freund", setup = function() state.bnetFriends["Player-1-0002"] = true end },
  { label = "Gilde", setup = function() state.guildMembers.Fremder = true end },
}) do
  state.friends, state.bnetFriends, state.guildMembers = {}, {}, {}
  trusted.setup()
  wow.questActions = {}
  wow.fire("QUEST_DETAIL")
  expect(trusted.label .. ": nicht abgelehnt", count(wow.questActions, "decline"), 0)
  expect(trusted.label .. ": angenommen", count(wow.questActions, "accept"), 1)
end
state.friends, state.bnetFriends, state.guildMembers = {}, {}, {}

-- Quest-NPC (kein Spieler): nie abgelehnt
state.units.questnpc = { name = "Marschall", isPlayer = false }
wow.questActions = {}
wow.fire("QUEST_DETAIL")
expect("NPC-Quest bleibt", count(wow.questActions, "decline"), 0)
state.units.questnpc = nil

-- Eskorte eines Fremden: Dialog zu, nicht bestätigt
wow.questActions = {}
wow.fire("QUEST_ACCEPT_CONFIRM", "Fremder", "Eskorte")
expect("Eskorte nicht bestätigt", count(wow.questActions, "confirm"), 0)
expect("Eskorten-Dialog zu", count(wow.questActions, "hidePopup"), 1)
-- Eskorte eines Gildenmitglieds: bestätigt
state.guildMembers.Gildi = true
wow.questActions = {}
wow.fire("QUEST_ACCEPT_CONFIRM", "Gildi", "Eskorte")
expect("Eskorte der Gilde bestätigt", count(wow.questActions, "confirm"), 1)
-- Geheimer Name (Retail/Forever): niemand handelt
wow.questActions = {}
wow.fire("QUEST_ACCEPT_CONFIRM", wow.SECRET, "Eskorte")
expect("geheim: nichts", #wow.questActions, 0)

---------------------------------------------------------------------------
-- Freundschaftsanfragen
---------------------------------------------------------------------------
state.friendInvites = { { inviteID = 7, accountName = "Spammer" }, { inviteID = 8, accountName = "Noch einer" } }
wow.fire("BN_FRIEND_INVITE_ADDED")
expect("aus: nichts abgelehnt", count(wow.socialActions, "declineFriend"), 0)
addon.Set("blockFriendRequests", true)  -- beim Einschalten werden wartende Anfragen abgelehnt
expect("wartende Anfragen abgelehnt", count(wow.socialActions, "declineFriend"), 2)
expect("Liste leer", #state.friendInvites, 0)
state.friendInvites = { { inviteID = 9, accountName = "Neu" } }
wow.fire("BN_FRIEND_INVITE_ADDED")
expect("neue Anfrage abgelehnt", lastSocial()[2], 9)
expectTrue("Chatzeile Anfrage", wow.printed[#wow.printed]:find(string.format(L.DECLINED_FRIEND_REQUEST, "Neu"), 1, true) ~= nil)

---------------------------------------------------------------------------
-- Gruppeneinladungen: Vertraute annehmen, andere weiter ablehnen
---------------------------------------------------------------------------
local function invite(name, guid, roles)
  wow.declined, wow.socialActions, wow.questActions = {}, {}, {}
  wow.fire("PARTY_INVITE_REQUEST", name, roles or false, false, false, true, false, guid, false)
end

state.friends.Kumpel = true
invite("Kumpel", "Player-1-0003")
expect("aus: nicht angenommen", count(wow.socialActions, "acceptGroup"), 0)

addon.Set("acceptFriendInvites", true)
addon.Set("declineGroupInvites", true)
local dialog = CreateFrame("Frame")
wow.visiblePopups.PARTY_INVITE = dialog
invite("Kumpel", "Player-1-0003")
expect("Freund angenommen", count(wow.socialActions, "acceptGroup"), 1)
expect("Freund nicht abgelehnt", #wow.declined, 0)
expect("Dialog als angenommen markiert", rawget(dialog, "inviteAccepted"), 1)
expect("Dialog zu", count(wow.questActions, "hidePopup"), 1)
wow.visiblePopups.PARTY_INVITE = nil

invite("Fremder", "Player-1-0002")
expect("Fremder abgelehnt", wow.declined[1], "DeclineGroup")
expect("Fremder nicht angenommen", count(wow.socialActions, "acceptGroup"), 0)

-- Rollenwahl bleibt manuell, wird aber auch nicht abgelehnt
invite("Kumpel", "Player-1-0003", true)
expect("Rollenwahl: nicht angenommen", count(wow.socialActions, "acceptGroup"), 0)
expect("Rollenwahl: nicht abgelehnt", #wow.declined, 0)

-- Annahme würde Warteschlangen verlassen: manuell
WillAcceptInviteRemoveQueues = function() return true end
invite("Kumpel", "Player-1-0003")
expect("Warteschlange: nicht angenommen", count(wow.socialActions, "acceptGroup"), 0)
WillAcceptInviteRemoveQueues = nil

-- Ohne acceptFriendInvites lehnt declineGroupInvites auch Freunde ab (wie bisher)
addon.Set("acceptFriendInvites", false)
invite("Kumpel", "Player-1-0003")
expect("nur Ablehnen: Freund abgelehnt", wow.declined[1], "DeclineGroup")
addon.Set("declineGroupInvites", false)

---------------------------------------------------------------------------
-- Einladen per Flüster-Stichwort
---------------------------------------------------------------------------
local function whisper(text, sender)
  wow.socialActions = {}
  wow.fire("CHAT_MSG_WHISPER", text, sender, "", "", sender, "", 0, 0, "", 0, 1, "Player-1-0004")
end

whisper("inv", "Bittsteller")
expect("aus: niemand eingeladen", #wow.socialActions, 0)
addon.Set("inviteFromWhisper", true)
whisper(" INV ", "Bittsteller")
expect("Stichwort (Groß/Klein, Leerzeichen egal)", lastSocial()[2], "Bittsteller")
expectTrue("Chatzeile Einladung", wow.printed[#wow.printed]:find(string.format(L.WHISPER_INVITED, "Bittsteller"), 1, true) ~= nil)
whisper("kannst du mich inv?", "Bittsteller")
expect("nur das genaue Stichwort", #wow.socialActions, 0)
addon.Set("inviteKeyword", "gruppe")
whisper("gruppe", "Bittsteller")
expect("eigenes Stichwort", lastSocial()[1], "invite")
addon.Set("inviteKeyword", "inv")

-- Chat-Sperre (Retail/Forever) und geheime Texte: nichts
state.chatLockdown = true
whisper("inv", "Bittsteller")
expect("Chat-Sperre: nichts", #wow.socialActions, 0)
state.chatLockdown = false
whisper(wow.SECRET, "Bittsteller")
expect("geheimer Text: nichts", #wow.socialActions, 0)

-- In einer Gruppe nur als Leiter
state.inGroup = true
whisper("inv", "Bittsteller")
expect("kein Leiter: nichts", #wow.socialActions, 0)
state.groupLeader = true
whisper("inv", "Bittsteller")
expect("Leiter: eingeladen", lastSocial()[1], "invite")
state.inGroup, state.groupLeader = false, false

-- Battle.net-Flüstern: Spielkonto im selben Spiel einladen
state.bnetAccounts[42] = { gameAccountInfo = { gameAccountID = 4242, isOnline = true, clientProgram = "WoW" } }
state.bnetAccounts[43] = { gameAccountInfo = { gameAccountID = 4343, isOnline = true, clientProgram = "App" } }
local function bnetWhisper(text, accountID)
  wow.socialActions = {}
  wow.fire("CHAT_MSG_BN_WHISPER", text, "Kumpel", "", "", "", "", 0, 0, "", 0, 1, "", accountID)
end
bnetWhisper("inv", 42)
expect("Battle.net-Freund eingeladen", lastSocial()[2], 4242)
bnetWhisper("inv", 43)
expect("Battle.net-App: nicht einladbar", #wow.socialActions, 0)

-- Stichwort ist eine Einstellung mit Text, Profil-Import prüft den Typ
expect("Stichwort aus Import", addon.Database.SanitizeSettings({ inviteKeyword = "los" }).inviteKeyword, "los")
expect("falscher Typ fliegt raus", addon.Database.SanitizeSettings({ inviteKeyword = 5 }).inviteKeyword, nil)
expect("keine Fehler", #wow.errors, 0)
