-- Stat-Gruppen und Voreinstellungen.
wow.login({ level = 10 })

-- Jede Stat-Zeile gehört zu einer bekannten Gruppe, jede Gruppe hat Zeilen
local known = {}
for _, group in ipairs(addon.STAT_GROUPS) do known[group] = 0 end
for _, line in ipairs(addon.STAT_LINES) do
  expectTrue("Gruppe bekannt: " .. line.setting, known[line.group] ~= nil)
  known[line.group] = (known[line.group] or 0) + 1
end
for group, count in pairs(known) do expectTrue("Gruppe nicht leer: " .. group, count > 0) end

-- Voreinstellung: genau die genannten Zeilen sind an
local preset = addon.STAT_PRESETS[1]
addon.ApplyStatPreset(preset)
local on = {}
for _, setting in ipairs(preset.settings) do on[setting] = true end
for _, line in ipairs(addon.STAT_LINES) do
  expect("Minimal: " .. line.setting, LevelTimerDB[line.setting], on[line.setting] or false)
end
addon.ApplyStatPreset(addon.STAT_PRESETS[3])
expect("Dungeon zeigt Instanz-Zeile", LevelTimerDB.showInstanceRun, true)
expect("Dungeon blendet Geld aus", LevelTimerDB.showMoney, false)

-- Button in den Einstellungen
SlashCmdList.LEVELTIMER("config")
wow.click(addon.L.STATISTICS)
expectTrue("Button Leveln", wow.click(addon.L.PRESET_LEVELING))
expect("Leveln: Quests an", LevelTimerDB.showQuests, true)
expect("Leveln: Instanz-Zeile aus", LevelTimerDB.showInstanceRun, false)

-- Rückmeldung im Chat
addon.ApplyStatPreset(addon.STAT_PRESETS[2])
expectTrue("Voreinstellung gemeldet", wow.printed[#wow.printed]:find(addon.L.PRESET_LEVELING, 1, true) ~= nil)
SlashCmdList.LEVELTIMER("reset")
expectTrue("Reset gemeldet", wow.printed[#wow.printed]:find(addon.L.RESET_DONE, 1, true) ~= nil)

-- Roadmap 199: Rückgängig stellt den Stand vor der letzten Voreinstellung wieder her, auch nach /reload
addon.Set("showMoney", true)
addon.Set("showRested", true)
addon.ApplyStatPreset(addon.STAT_PRESETS[1])
expect("Minimal blendet Geld aus", LevelTimerDB.showMoney, false)
wow.logout()
wow.login({ level = 10 })
SlashCmdList.LEVELTIMER("config")
wow.click(addon.L.STATISTICS)
expectTrue("Button Rückgängig", wow.clickOption("PRESET_UNDO"))  -- "Rückgängig" gibt es auch unter der Seitenleiste
expect("Geld wieder an", LevelTimerDB.showMoney, true)
expect("Erholung wieder an", LevelTimerDB.showRested, true)
expect("Zwischenstand verworfen", LevelTimerDB.presetBackup, nil)
expectTrue("gemeldet", wow.printed[#wow.printed]:find(addon.L.PRESET_UNDONE, 1, true) ~= nil)
expect("zweimal geht nicht", addon.UndoStatPreset(), false)
expectTrue("Meldung ohne Stand", wow.printed[#wow.printed]:find(addon.L.PRESET_NOTHING_TO_UNDO, 1, true) ~= nil)
-- Import: kaputter Zwischenstand fällt weg
local clean = addon.Database.SanitizeSettings({ presetBackup = { showMoney = true, [1] = true, showDeaths = "ja" } })
expect("nur gültige Einträge", clean.presetBackup and clean.presetBackup.showMoney, true)
expect("Text verworfen", clean.presetBackup and clean.presetBackup.showDeaths, nil)
