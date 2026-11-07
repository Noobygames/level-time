-- Communities als Freunde (friendlyCommunities): Mitglieder eigener Charakter-Communities gelten als vertraut,
-- Battle.net-Communities nicht; Änderungen an Communities werden nachgelesen
local state = wow.state
local CHARACTER, BATTLE_NET = 1, 0

local function declines()
  local n = 0
  for _, entry in ipairs(wow.questActions) do if entry[1] == "decline" then n = n + 1 end end
  return n
end

local function sharedQuest()
  wow.questActions = {}
  wow.fire("QUEST_DETAIL")
  return declines()
end

wow.login()
state.units.questnpc = { name = "Fremder", isPlayer = true, guid = "Player-1-0002" }
addon.Set("declineSharedQuests", true)
state.clubs = {
  { clubId = 7, clubType = BATTLE_NET, members = { { name = "Fremder#1234", guid = "Player-1-0002" } } },
}

expect("aus: Fremder abgelehnt", sharedQuest(), 1)
addon.Set("friendlyCommunities", true)
expect("Battle.net-Community zählt nicht", sharedQuest(), 1)

-- Neue Charakter-Community: erst nach dem Club-Ereignis bekannt (Liste wird gemerkt)
table.insert(state.clubs, { clubId = 8, clubType = CHARACTER, members = {
  { name = "Ich", guid = "Player-1-0001", isSelf = true },
  { name = "Fremder", guid = "Player-1-0002" },
} })
expect("vor dem Ereignis noch gemerkte Liste", sharedQuest(), 1)
wow.fire("CLUB_MEMBER_ADDED", 8, 2)
expect("Community-Mitglied: nicht abgelehnt", sharedQuest(), 0)

-- Treffer über den Namen ohne GUID
state.clubs[2].members[2].guid = nil
wow.fire("CLUB_MEMBER_UPDATED", 8, 2)
expect("Name reicht", sharedQuest(), 0)
expectTrue("Vertraut über Namen", addon.Friends.IsTrusted("Fremder"))

addon.Set("friendlyCommunities", false)
expect("aus: wieder abgelehnt", sharedQuest(), 1)
expect("aus: nicht vertraut", addon.Friends.IsTrusted("Fremder"), false)
