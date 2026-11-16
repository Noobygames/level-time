-- Level Time Data Extractor (LT-52, Era mit Kampflog-Abruf): Gegner-Zauber aus dem Kampflog je Instanz und NPC, nur in Instanzen,
-- nur NPC-Quellen; geheime GUIDs und Spieler zählen nur im Status der Prüfung LT52.combatlog.guid.
local X = extractor

local COOKIE = "Creature-0-1-2-3-645-0000000001"
local function cast(subevent, sourceGUID, spellID, spellName)
  wow.state.combatLog = { wow.state.now, subevent, false, sourceGUID, "Quelle", 0, 0, "Player-1", "Ziel", 0, 0,
    spellID, spellName, 8 }
  wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
end

wow.login()
local db = LevelTimerExtractorDB

-- Draußen: nichts gespeichert
cast("SPELL_CAST_START", COOKIE, 5174, "Kochen")
expect("draußen nichts", db.instances[36], nil)

wow.state.instance = { name = "Die Todesminen", type = "party", mapID = 36 }
wow.fire("PLAYER_ENTERING_WORLD")
cast("SPELL_CAST_START", COOKIE, 5174, "Kochen")
cast("SPELL_CAST_SUCCESS", COOKIE, 5174, "Kochen")
cast("SPELL_DAMAGE", COOKIE, 6306, "Säurespritzer")
cast("SPELL_HEAL", COOKIE, 5174, "Kochen")                          -- nicht gesammeltes Event
cast("SPELL_CAST_START", "Player-1-0000ABCD", 133, "Feuerball")     -- Spieler
cast("SPELL_CAST_START", wow.SECRET, 5174, "Kochen")                -- geheime GUID
cast("SPELL_AURA_APPLIED", COOKIE, 0, "Schleim")                    -- Kampflog ohne Zauber-ID

local spells = db.instances[36].spells[645]
expect("Kochen gezählt", spells[5174].count, 2)
expect("Kochen je Event", spells[5174].events.SPELL_CAST_START, 1)
expect("Name je Sprache", spells[5174].names.deDE, "Kochen")
expect("Schaden", spells[6306].events.SPELL_DAMAGE, 1)
expect("ohne ID über den Namen", spells["name:Schleim"].count, 1)
expect("Zauber je NPC", spells.count, 3)
expect("Spieler nicht gespeichert", db.instances[36].spells[0], nil)

local status = X.CombatSpells.Status()
expect("Status: Instanz", status.instance, 36)
expect("Status: gesammelte Events", status.events, 6)
expect("Status: NPC-Quellen", status.npcSources, 4)
expect("Status: geheime GUIDs", status.secretGuids, 1)
expect("Status: andere Quellen", status.otherSources, 1)
expect("Status: ohne Zauber-ID", status.nameKeys, 1)

-- Wieder draußen: nichts mehr
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
cast("SPELL_CAST_START", COOKIE, 5174, "Kochen")
expect("draußen nicht weiter gezählt", spells[5174].count, 2)
expect("keine Lua-Fehler", #wow.errors, 0)
