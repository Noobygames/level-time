-- Meilenstein-Screenshots: alle 5 Level, Max-Level, erster Dungeon, epische Beute; alles aus ohne Einstellung.
wow.login({ name = "Neu", level = 4, maxLevel = 12, playedSeconds = 0 })
wow.levelUp(5)
wow.runTimers()
expect("aus: kein Screenshot", wow.screenshots, 0)

addon.Set("milestoneScreenshots", true)
wow.levelUp(6)
wow.runTimers()
expect("Level 6 kein Meilenstein", wow.screenshots, 0)
for level = 7, 10 do wow.levelUp(level) end
wow.runTimers()
expect("Level 10", wow.screenshots, 1)
wow.levelUp(11)
wow.levelUp(12)
wow.runTimers()
expect("Max-Level", wow.screenshots, 2)

-- Erster Dungeon, nur einmal je Charakter
addon.Set("screenshotFirstDungeon", true)
wow.state.instance = { name = "Todesminen", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
wow.runTimers()
expect("erster Dungeon", wow.screenshots, 3)
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Burg Schattenfang", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
wow.runTimers()
expect("nur der erste", wow.screenshots, 3)

-- Epische Beute
addon.Set("screenshotEpicLoot", true)
addon.Journal.AddLoot({ link = "[Blau]", name = "Blau", quality = 3, quantity = 1 })
wow.runTimers()
expect("rar: keiner", wow.screenshots, 3)
addon.Journal.AddLoot({ link = "[Episch]", name = "Episch", quality = 4, quantity = 1 })
wow.runTimers()
expect("episch", wow.screenshots, 4)
