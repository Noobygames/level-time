-- Level Time Data Extractor (LT-286): Gegner-Zauber und Tode aus C_DamageMeter nach Kampfende, nur mit verfügbarer API
local X = extractor

wow.login()
wow.state.instance = { name = "Die Todesminen", type = "party", mapID = 36 }
wow.fire("PLAYER_ENTERING_WORLD")

-- ohne C_DamageMeter: nichts, kein Fehler
wow.fire("PLAYER_REGEN_ENABLED")
expect("ohne API nichts gelesen", X.DamageMeter.Status().reads, 0)

local available = false
Enum = Enum or {}
Enum.DamageMeterType = { DamageTaken = 1, Deaths = 2 }
local secretSpells = false
C_DamageMeter = {
  IsDamageMeterAvailable = function() return available end,
  GetAvailableCombatSessions = function() return { { sessionID = 7 } } end,
  GetCombatSessionFromID = function(_, kind)
    if kind == Enum.DamageMeterType.Deaths then return { combatSources = { { isLocalPlayer = true }, { isLocalPlayer = false } } } end
    return { combatSources = { { sourceGUID = "Creature-0-1-2-3-645-0000000001", sourceCreatureID = 645 } } }
  end,
  GetCombatSessionSourceFromID = function()
    if secretSpells then return wow.SECRET end
    return { combatSpells = { { spellID = 5174, creatureName = "Kochen", isDeadly = true }, { spellID = wow.SECRET } } }
  end,
}

wow.fire("PLAYER_REGEN_ENABLED")
expect("nicht verfügbar: nichts gelesen", X.DamageMeter.Status().reads, 0)

available = true
wow.fire("PLAYER_REGEN_ENABLED")
local instance = LevelTimerExtractorDB.instances[36]
local spell = instance.damageTaken[645][5174]
expect("Zauber gezählt", spell.count, 1)
expect("tödlich", spell.deadly, 1)
expect("Tod gezählt", instance.deaths, 1)
expect("geheime Zauber-ID übersprungen", X.DamageMeter.Status().spells, 1)

wow.fire("PLAYER_REGEN_ENABLED")
expect("dieselbe Sitzung nur einmal", spell.count, 1)

secretSpells = true
C_DamageMeter.GetAvailableCombatSessions = function() return { { sessionID = 8 } } end
wow.fire("PLAYER_REGEN_ENABLED")
expect("geheime Sitzung ohne Fehler", X.DamageMeter.Status().secret, 1)
expect("keine Lua-Fehler", #wow.errors, 0)
