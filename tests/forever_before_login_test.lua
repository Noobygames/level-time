-- Ereignisse vor PLAYER_LOGIN (Einloggen, /reload in Gruppe oder Dungeon): ns.db/ns.character fehlen noch,
-- die Handler dürfen keinen Lua-Fehler werfen
local Stats = addon.Stats

wow.state.friendInvites = { { inviteID = 1, accountName = "Fremder" } }
wow.state.inGroup = true
wow.state.units.party1 = { level = 40 }
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36 }

wow.fire("BN_FRIEND_INVITE_LIST_INITIALIZED")
wow.fire("GROUP_ROSTER_UPDATE")
wow.fire("UPDATE_INSTANCE_INFO")
wow.fire("PLAYER_DIFFICULTY_CHANGED")
Stats.Increment(Stats.PVE_KILLS)
expect("keine Fehler vor dem Login", #wow.errors, 0)

wow.login({ level = 20 })
expect("keine Fehler nach dem Login", #wow.errors, 0)
