-- Alte Speicherstände (pro Charakter, Schema 1/2) werden beim Login in die
-- account-weite Datei übernommen und migriert. Einstellungen bleiben erhalten.
local Stats = addon.Stats

LevelTimerCharDB = {  -- Schema 1: flach, nur PvE-Kills als "kills"
  level = 10,
  kills = 4,
  history = { [9] = { level = 9, seconds = 3000, xp = 900, counters = { pveKills = 30 } } },
}
LevelTimerDB = { locked = true, showKills = false, showDeaths = true, fontSize = 24, showCountToLevel = true,
  profiles = { Alt = { showCountToLevel = false } } }

wow.login({ level = 10 })

local character = LevelTimerStatsDB.characters["Testchar-Testrealm"]
expectTrue("Charakter unter Name-Realm angelegt", character ~= nil)
expect("alte Datei geleert", LevelTimerCharDB, nil)
expect("Schema-Version aktuell", character.schemaVersion, addon.Database.CHARACTER_SCHEMA_VERSION)
expect("Name gespeichert", character.name, "Testchar")
expect("Klasse gespeichert", character.class, "WARRIOR")

expect("kills wird zu pveKills", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 4)
expect("Level übernommen", character.currentLevel.level, 10)
expect("Historie übernommen", character.levelHistory[9].counters.pveKills, 30)
expect("alte Felder entfernt", character.kills or character.level or character.history, nil)
expect("neuer Zähler bekommt Default", Stats.Get(Stats.LEVEL, Stats.XP_GAINED), 0)
expectTrue("Session gestartet", character.currentSession.startedAt ~= nil)

expect("Einstellung bleibt", LevelTimerDB.locked, true)
expect("alter Schlüssel scale entfernt", LevelTimerDB.scale, nil)
expect("Kills aus -> PvE aus", LevelTimerDB.showPveKills, false)
expect("Kills aus -> PvP aus", LevelTimerDB.showPvpKills, false)
expect("alter Kills-Schalter entfernt", LevelTimerDB.showKills, nil)
expect("Tode an -> Kills pro Tod an", LevelTimerDB.showKillsPerDeath, true)
expect("Kills/Quests bis Level-Up: Kills übernimmt", LevelTimerDB.showKillsToLevel, true)
expect("Kills/Quests bis Level-Up: Quests übernimmt", LevelTimerDB.showQuestsToLevel, true)
expect("alter Schalter entfernt", LevelTimerDB.showCountToLevel, nil)
expect("auch im Profil", LevelTimerDB.profiles.Alt.showQuestsToLevel, false)
expect("neue Einstellung bekommt Default", LevelTimerDB.windowScope, "level")
expect("Schriftgröße wird zu Fenstergröße", LevelTimerDB.frames.main.scale, 1.5)
expect("alte Schriftgröße entfernt", LevelTimerDB.fontSize, nil)

-- Zweiter Login darf nicht erneut migrieren
character.currentLevel.counters.pveKills = 20
wow.logout()
wow.login()
expect("keine Doppelmigration", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 20)

-- Schema 5: vorhandenes Journal wird in Tageswerte übernommen
wow.logout()
LevelTimerStatsDB.characters["Alt-Testrealm"] = {
  schemaVersion = 4,
  killLog = { { time = os.time({ year = 2026, month = 9, day = 1, hour = 10 }), name = "Wolf" } },
  deathLog = { { time = os.time({ year = 2026, month = 9, day = 1, hour = 11 }) } },
}
wow.login({ name = "Alt" })
local day = addon.character.dailyStats["2026-09-01"]
expectTrue("Tageswert angelegt", day ~= nil)
expect("Kill übernommen", day and day.kills, 1)
expect("Tod übernommen", day and day.deaths, 1)

-- Daten einer neueren Version (Downgrade): Schema-Version bleibt, nichts läuft doppelt
LevelTimerStatsDB.characters["Zukunft-Realm"] = { schemaVersion = 99, name = "Zukunft", realm = "Realm",
  currentLevel = { level = 3, counters = {} }, dailyStats = { ["2026-01-01"] = { seconds = 60, kills = 1, deaths = 0, xp = 0 } } }
wow.logout()
wow.login()
expect("neuere Version nicht gesenkt", LevelTimerStatsDB.characters["Zukunft-Realm"].schemaVersion, 99)
expect("Tageswerte unverändert", LevelTimerStatsDB.characters["Zukunft-Realm"].dailyStats["2026-01-01"].kills, 1)
