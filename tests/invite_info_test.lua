-- Einladungen mit Infos: Chatzeile mit Rasse, Klasse, Level (wenn Ziel) und Freund/Gilde; Dialog unberührt
local L = addon.L

local GUID = "Player-6937-00271B69"

local function invite(name, guid)
  wow.printed = {}
  -- PARTY_INVITE_REQUEST(name, isTank, isHealer, isDamage, isNativeRealm, allowMultipleRoles, inviterGUID, questSession)
  wow.fire("PARTY_INVITE_REQUEST", name, false, false, false, true, false, guid, false)
  return wow.printed[1]
end

wow.login({ level = 20 })
expect("aus: nichts", invite("Twoblade", GUID), nil)

addon.Set("inviteInfo", true)
wow.state.playerInfo = { [GUID] = { "Krieger", "WARRIOR", "Orc", "Orc", 2, "Twoblade", "Realm" } }
local line = invite("Twoblade", GUID)
expectTrue("Rasse und Klasse", line ~= nil and line:find("Orc Krieger", 1, true) ~= nil)
expectTrue("Name in Klassenfarbe", line:find("|cffc69b6dTwoblade|r", 1, true) ~= nil)
expectTrue("ohne Ziel kein Level", line:find(string.format(L.INVITE_INFO_LEVEL, 20), 1, true) == nil)

-- Einladender ist das Ziel: Level dazu
wow.state.units.target = { name = "Twoblade", guid = GUID, isPlayer = true }
line = invite("Twoblade", GUID)
expectTrue("Level", line:find(string.format(L.INVITE_INFO_LEVEL, 20) .. " Orc Krieger", 1, true) ~= nil)
wow.state.units.target = nil

-- Unbekannt und Freund
wow.state.friends = { Fremder = true }
line = invite("Fremder", "Player-1-0000BEEF")
expectTrue("unbekannt", line:find(L.INVITE_INFO_UNKNOWN, 1, true) ~= nil)
expectTrue("Freund markiert", line:find(L.INVITE_INFO_TRUSTED, 1, true) ~= nil)

-- Geheimer Name: nichts
expect("geheim: nichts", invite(wow.SECRET, GUID), nil)
expect("Dialog nicht angefasst", #wow.questActions, 0)
