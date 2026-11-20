-- WoW Forever ab Build 71037: GetRealmName liefert "". Der Charakter landet über die GUID wieder in seinem
-- gespeicherten Eintrag "Name-Realm", nicht in einem neuen "Name-"; ein schon entstandener "Name-"-Eintrag desselben
-- Charakters kommt aus der Liste unter splitCharacters (nichts gelöscht). Neuer Charakter ohne Realm: "Name-".
local GUID = "Player-6937-00064C3C"
local KEY = "Testchar-CAMWOW EU4 Realm 3 PvE"

LevelTimerStatsDB = { characters = {
  [KEY] = { guid = GUID, name = "Testchar", realm = "CAMWOW EU4 Realm 3 PvE", marker = "alt" },
  ["Testchar-"] = { guid = GUID, name = "Testchar", realm = "", marker = "verwaist" },
} }
wow.state.realm = ""
wow.login({ level = 45, guid = GUID })
expect("gespeicherter Eintrag", addon.characterKey, KEY)
expect("Daten des Eintrags", addon.character.marker, "alt")
expect("Realm bleibt gespeichert", addon.character.realm, "CAMWOW EU4 Realm 3 PvE")
expect("Doppel-Eintrag aus der Liste", LevelTimerStatsDB.characters["Testchar-"], nil)
expect("Doppel-Eintrag aufgehoben", LevelTimerStatsDB.splitCharacters[GUID].marker, "verwaist")
expect("Realm für andere Module", addon.Database.RealmName(), "CAMWOW EU4 Realm 3 PvE")

-- Realm kommt zurück: derselbe Eintrag
wow.logout()
wow.state.realm = "CAMWOW EU4 Realm 3 PvE"
wow.login({ level = 45, guid = GUID })
expect("mit Realm derselbe Eintrag", addon.characterKey, KEY)

-- Gleichnamiger Charakter auf einem anderen Realm, alter Eintrag ohne GUID: der einzige Name ohne GUID passt.
-- Ein "Name-"-Eintrag eines anderen Charakters (andere GUID) bleibt in der Liste
wow.logout()
LevelTimerStatsDB.characters["Testchar-"] = { guid = "Player-6937-ANDERER", name = "Testchar", realm = "", marker = "verwaist" }
LevelTimerStatsDB.characters["Testchar-Realm 1"] = { name = "Testchar", realm = "Realm 1", marker = "realm1" }
wow.state.realm = ""
wow.login({ level = 20, guid = "Player-6937-REALM1" })
expect("Eintrag ohne GUID gefunden", addon.characterKey, "Testchar-Realm 1")
expect("Daten von Realm 1", addon.character.marker, "realm1")
expect("verwaister Eintrag unberührt", LevelTimerStatsDB.characters["Testchar-"].marker, "verwaist")

-- Ganz neuer Charakter mit demselben Namen (kein Eintrag ohne GUID mehr): eigener Schlüssel, Orphan bleibt
wow.logout()
wow.login({ level = 1, guid = "Player-6937-NEU" })
expect("Kollision: eigener Schlüssel", addon.characterKey, "Testchar-Player-6937-NEU")
expect("andere GUID: Daten neu", addon.character.marker, nil)
expect("verwaister Eintrag bleibt erhalten", LevelTimerStatsDB.characters["Testchar-"].marker, "verwaist")

-- Neuer Name ohne jeden Eintrag: "Name-"
wow.logout()
wow.state.name = "Neuling"
wow.login({ level = 1, guid = "Player-6937-NEU2" })
expect("neuer Charakter ohne Realm", addon.characterKey, "Neuling-")
expect("keine Lua-Fehler", #wow.errors, 0)
