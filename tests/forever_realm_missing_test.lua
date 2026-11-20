-- WoW Forever ab Build 71037: GetRealmName liefert "". Der Charakter landet über die GUID wieder in seinem
-- gespeicherten Eintrag "Name-Realm", nicht in einem neuen "Name-"; ein schon entstandener "Name-"-Eintrag bleibt
-- unangetastet (keine Daten löschen). Neuer Charakter ohne gespeicherten Realm: Schlüssel "Name-".
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
expect("verwaister Eintrag bleibt", LevelTimerStatsDB.characters["Testchar-"].marker, "verwaist")
expect("Realm für andere Module", addon.Database.RealmName(), "CAMWOW EU4 Realm 3 PvE")

-- Realm kommt zurück: derselbe Eintrag
wow.logout()
wow.state.realm = "CAMWOW EU4 Realm 3 PvE"
wow.login({ level = 45, guid = GUID })
expect("mit Realm derselbe Eintrag", addon.characterKey, KEY)

-- Anderer Charakter (andere GUID) ohne gespeicherten Realm
wow.logout()
wow.state.realm = ""
wow.login({ level = 1, guid = "Player-6937-NEU" })
expect("neuer Charakter ohne Realm", addon.characterKey, "Testchar-")
expect("andere GUID: Daten neu", addon.character.marker, nil)
expect("keine Lua-Fehler", #wow.errors, 0)
