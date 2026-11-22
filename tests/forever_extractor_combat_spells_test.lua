-- Level Time Data Extractor (LT-52/LT-267): WoW Forever hat keinen Kampflog-Abruf (C_CombatLog.GetCurrentEventInfo
-- fehlt), die Sammlung bleibt aus und der Status meldet api = false
local X = extractor

wow.login()
wow.state.instance = { name = "Die Todesminen", type = "party", mapID = 36 }
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
local status = X.CombatSpells.Status()
expect("Status: kein Kampflog-Abruf", status.api, false)
expect("Status: nichts gezählt", status.events, 0)
expect("keine Zauber gespeichert", (LevelTimerExtractorDB.instances[36] or {}).spells, nil)
expect("keine Lua-Fehler", #wow.errors, 0)

-- LT-278: ohne Kampflog kommen Gegner-Zauber aus UNIT_SPELLCAST_* von Ziel, Namensplakette und Bossrahmen
local COOKIE = "Creature-0-1-2-3-645-0000000001"
wow.state.spellNames[5174] = "Kochen"
wow.state.units.target = { guid = COOKIE }
wow.state.units.nameplate1 = { guid = COOKIE }
wow.state.units.party1 = { guid = COOKIE }
wow.fire("UNIT_SPELLCAST_START", "target", "Cast-1", 5174)
wow.fire("UNIT_SPELLCAST_START", "nameplate1", "Cast-1", 5174)  -- derselbe Wurf über die Namensplakette
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate1", "Cast-1", 5174)
wow.fire("UNIT_SPELLCAST_CHANNEL_START", "target", "Cast-2", 5174)
wow.fire("UNIT_SPELLCAST_START", "party1", "Cast-3", 5174)  -- keine gegnerische Einheit
wow.fire("UNIT_SPELLCAST_START", "target", wow.SECRET, wow.SECRET)  -- geheime Werte
local spell = LevelTimerExtractorDB.instances[36].spells[645][5174]
expect("Zauber gezählt", spell.count, 3)
expect("Zaubername", spell.names.deDE, "Kochen")
expect("Wurf-Start", spell.events.SPELL_CAST_START, 2)
expect("Wurf-Erfolg", spell.events.SPELL_CAST_SUCCESS, 1)
expect("Status: Zauber aus UNIT_SPELLCAST", X.CombatSpells.Status().unitCasts, true)
expect("keine Lua-Fehler 2", #wow.errors, 0)

-- LT-278: Mouseover zählt, Zähler lesbar/geheim
wow.state.units.mouseover = { guid = COOKIE }
wow.fire("UNIT_SPELLCAST_START", "mouseover", "Cast-9", 5174)
local st = X.CombatSpells.Status()
expect("Mouseover gezählt", LevelTimerExtractorDB.instances[36].spells[645][5174].count, 4)
expect("Zauber-ID geheim gezählt", st.spellIDSecret, 1)
expect("Zauber-ID lesbar gezählt", st.spellIDReadable > 0, true)
