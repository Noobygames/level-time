-- Charakter gelöscht und mit gleichem Namen neu erstellt: alte Daten werden zum importierten Lauf,
-- der neue Charakter beginnt leer.
wow.login({ name = "Speedy", realm = "Realm", level = 5, xp = 0, xpMax = 2800, playedSeconds = 0 })
wow.advance(600)
wow.levelUp(6, 3600)
wow.advance(700)
wow.levelUp(7, 4500)
wow.logout()

-- Neu erstellter Charakter = neue GUID
wow.login({ name = "Speedy", realm = "Realm", level = 1, xp = 0, xpMax = 400, playedSeconds = 0, guid = "Player-1-0002" })
local character = LevelTimerStatsDB.characters["Speedy-Realm"]
expect("neuer Charakter ohne alte Level", next(character.levelHistory), nil)
expect("neues Level", character.currentLevel.level, 1)
local archived = LevelTimerStatsDB.importedRuns[1]
expectTrue("alter Versuch als Lauf gesichert", archived ~= nil)
expect("Name", archived.name, "Speedy")
expectNear("Level 5", archived.times[5], 600)
expect("erreichtes Level", archived.reachedLevel, 7)
