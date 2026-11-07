-- Roadmap 175: Kommt PLAYER_XP_UPDATE mit dem neuen Bedarf vor PLAYER_LEVEL_UP, speichert die Historie trotzdem
-- den XP-Bedarf des abgeschlossenen Levels.
wow.login({ level = 10, xp = 0, xpMax = 1000, playedSeconds = 0 })
wow.fire("TIME_PLAYED_MSG", 5000, 0)
wow.state.xp = 900
wow.fire("PLAYER_XP_UPDATE", "player")
wow.advance(600)

-- Erst die XP (schon neues Level: 50 von 1500), dann das Level-Up
wow.state.xp, wow.state.xpMax = 50, 1500
wow.fire("PLAYER_XP_UPDATE", "player")
wow.levelUp(11, 1500)

local record = addon.character.levelHistory[10]
expect("XP des alten Levels", record.xp, 1000)
expect("Bedarf des neuen Levels bekannt", addon.Experience.XpMaxOf(11), 1500)

-- Übliche Reihenfolge (Level-Up zuerst) bleibt richtig
wow.advance(600)
wow.levelUp(12, 2000)
wow.fire("PLAYER_XP_UPDATE", "player")
expect("übliche Reihenfolge", addon.character.levelHistory[11].xp, 1500)
