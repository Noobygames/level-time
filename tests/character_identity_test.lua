-- Charakter-Erkennung über die GUID: Level-Squish setzt nichts zurück, neu erstellter Charakter schon;
-- CVar-Originale bleiben in jedem Fall erhalten. Defekter Eintrag bricht den Login nicht ab.
local KEY = "Testchar-Testrealm"

LevelTimerStatsDB = { characters = { [KEY] = { schemaVersion = 1, counters = "kaputt", cvarOriginals = { a = "1" } } } }
wow.login({ level = 60, guid = "Player-1-AAAA" })
expectTrue("Login trotz defektem Eintrag", addon.db ~= nil)
expect("Charakter neu migriert", addon.character.schemaVersion, addon.Database.CHARACTER_SCHEMA_VERSION)
expect("defekt: CVar-Original bleibt", addon.character.cvarOriginals.a, "1")
expectTrue("Fehler gemeldet", #wow.errors > 0)
wow.errors = {}
expect("GUID gespeichert", addon.character.guid, "Player-1-AAAA")

addon.character.marker = true
wow.logout()
wow.login({ level = 10 })
expect("Level-Squish: Daten bleiben", LevelTimerStatsDB.characters[KEY].marker, true)

wow.logout()
LevelTimerStatsDB.characters[KEY].cvarOriginals = { a = "1" }
wow.login({ level = 10, guid = "Player-1-BBBB" })
local character = LevelTimerStatsDB.characters[KEY]
expect("andere GUID: Daten neu", character.marker, nil)
expect("andere GUID: CVar-Original bleibt", character.cvarOriginals.a, "1")
expect("neue GUID gespeichert", character.guid, "Player-1-BBBB")

addon.DeleteCharacter(KEY)
expect("Löschen: CVar-Original bleibt", addon.character.cvarOriginals.a, "1")
