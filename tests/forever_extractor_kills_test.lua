-- Level Time Data Extractor (LT-279): WoW Forever hat keinen Kampflog, Kills kommen aus PARTY_KILL
local X = extractor
local WOLF = "Creature-0-1-2-3-299-0000000001"

wow.login({ level = 60 })
local db = LevelTimerExtractorDB
wow.fire("PARTY_KILL", "Player-1-0000ABCD", WOLF)
expect("Kill ohne Name gezählt", db.npcs[299].kills, 1)
expect("kein Name bekannt", db.npcs[299].names, nil)

wow.state.units.target = { guid = WOLF, name = "Wolf", level = 5, healthMax = 120 }
wow.fire("PLAYER_TARGET_CHANGED")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Wolf", 45))
expect("XP-Zeile direkt danach zählt nicht doppelt", db.npcs[299].kills, 1)
wow.advance(10)
wow.fire("PARTY_KILL", "Player-1-0000ABCD", WOLF)  -- gleiche GUID: schon gezählt
expect("gleiche GUID nicht doppelt", db.npcs[299].kills, 1)
wow.fire("PARTY_KILL", "Player-1-0000ABCD", "Creature-0-1-2-3-299-0000000009")
expect("zweiter Kill", db.npcs[299].kills, 2)

wow.fire("PARTY_KILL", "Player-1-0000ABCD", wow.SECRET)
wow.fire("PARTY_KILL", "Player-1-0000ABCD", "Player-1-0000FFFF")
wow.fire("UNIT_DIED", WOLF)
local status = X.Units.KillStatus()
expect("Status aktiv", status.active, true)
expect("PARTY_KILL-Ereignisse", status.partyKills, 5)
expect("gezählte NPCs", status.npcKills, 2)
expect("geheime GUIDs", status.secretGuids, 1)
expect("UNIT_DIED", status.unitDied, 1)
expect("ohne Name", status.unnamed, 1)
-- geheime GUID: toter Gegner über Ziel-Token, je GUID nur einmal
local BEAR = "Creature-0-1-2-3-411-0000000002"
wow.state.units.target = { guid = BEAR, name = "Bär", level = 5, healthMax = 90, dead = true }
wow.fire("PARTY_KILL", "Player-1-0000ABCD", wow.SECRET)
wow.fire("PARTY_KILL", "Player-1-0000ABCD", wow.SECRET)
expect("Kill über Token gezählt", db.npcs[411].kills, 1)
expect("Token-Zähler", X.Units.KillStatus().unitToken, 1)
expect("ohne tote Einheit übersprungen", X.Units.KillStatus().secretSkipped, 2)
expect("keine Lua-Fehler", #wow.errors, 0)
