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

-- Zusammenführen (LT-414): Zähler addieren, Journale nach Zeit einsortieren, Doppel-Eintrag verschwindet
wow.logout()
LevelTimerStatsDB.splitCharacters = nil
LevelTimerStatsDB.characters = {
  [KEY] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, guid = GUID, name = "Testchar", realm = "CAMWOW EU4 Realm 3 PvE",
    currentLevel = { level = 45, seconds = 100, xp = 10, counters = { pveKills = 5 } },
    killLog = { { time = 10, name = "a" }, { time = 30, name = "c" } },
    zoneStats = { Elwynn = { seconds = 50, kills = 2 } } },
  ["Testchar-"] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, guid = GUID, name = "Testchar", realm = "",
    currentLevel = { level = 45, seconds = 40, xp = 4, counters = { pveKills = 3 } },
    levelHistory = { [44] = { level = 44, seconds = 60, xp = 6, counters = { pveKills = 2 } } },
    killLog = { { time = 20, name = "b" }, { time = 40, name = "d" } },
    zoneStats = { Elwynn = { seconds = 5, kills = 1 }, Durotar = { seconds = 7, kills = 0 } } },
}
wow.state.realm = ""
wow.state.name = "Testchar"
wow.login({ level = 45, guid = GUID })
local orphans = addon.SplitEntry.List()
expect("ein aufgehobener Eintrag", #orphans, 1)
expect("Spielzeit des Eintrags", orphans[1].seconds, 100)
local before = addon.Journal.EditRevision("killLog")
expectTrue("zusammengeführt", addon.SplitEntry.Merge(KEY))
expect("Zähler addiert", addon.character.currentLevel.counters.pveKills, 8)
expect("Spielzeit addiert", addon.character.currentLevel.seconds, 140)
expect("abgeschlossenes Level übernommen", addon.character.levelHistory[44].seconds, 60)
expect("Zonen addiert", addon.character.zoneStats.Elwynn.seconds, 55)
expect("neue Zone übernommen", addon.character.zoneStats.Durotar.seconds, 7)
local names = {}
for _, entry in ipairs(addon.character.killLog) do names[#names + 1] = entry.name end
expect("Journal nach Zeit", table.concat(names), "abcd")
expectTrue("Journal-Stand erhöht", addon.Journal.EditRevision("killLog") > before)
expect("Doppel-Eintrag weg", LevelTimerStatsDB.splitCharacters[GUID], nil)
expect("nichts mehr zu tun", #addon.SplitEntry.List(), 0)
expect("zweites Mal nichts", addon.SplitEntry.Merge(KEY), false)
