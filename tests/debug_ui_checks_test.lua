-- Prüfungen und Proben der Oberflächen-Tasks (ChecksUI.lua): alle ohne Lua-Fehler mit Ergebnis, Hooks schreiben Zeilen.
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

local CHECKS = {
  "LT81.options.textFit", "LT80.options.scroll", "LT189.options.pages", "LT210.options.search", "LT163.options.profiles",
  "LT223.dropdown.state", "LT147.history.textFit", "LT165.window.hints", "LT212.frames.mouse", "LT78.alert.banner",
  "LT85.welcome.state", "LT129.tooltip.state", "LT149.tooltip.api", "LT187.blizzardFrames.mouse", "LT215.minimap.square",
  "LT217.quests.textSize", "LT219.screenBorders", "LT86.classicPlayerFrame", "LT87.dressUp", "LT89.infoCard.subject",
}

wow.login()
SlashCmdList.LEVELTIMER("debug check")
for _, name in ipairs(CHECKS) do
  local line = hasLine('"name":"' .. name .. '"')
  expectTrue("Prüfung " .. name .. " geschrieben", line ~= nil)
  expect("Prüfung " .. name .. " ohne Fehler", line and line:match('"error":"([^"]*)"'), nil)
end
expect("keine Lua-Fehler", #wow.errors, 0)

-- Proben: schreiben nur bei laufendem Log
addon.DebugLog.SetEnabled(true)
addon.Alerts.Raise("questComplete", "Testquest", "+10 XP")
expectTrue("Probe Einblendung", hasLine('"event":"ui.alert.raise"') ~= nil)
addon.ToggleOptionsPage("COMFORT_PAGE_DUNGEONS")
expectTrue("Probe Rechtsklick-Seite", hasLine('"event":"ui.optionsPage"') ~= nil)
addon.OptionsWindow.ResetPage("OPTIONS_PAGE_ALERT_LOOK")
addon.OptionsWindow.UndoReset("OPTIONS_PAGE_ALERT_LOOK")
expectTrue("Probe Standard/Rückgängig", hasLine('"event":"ui.optionsReset"') ~= nil)
addon.ApplyStatPreset(addon.STAT_PRESETS[1])
expectTrue("Probe Voreinstellung", hasLine('"event":"ui.preset"') ~= nil)
addon.BlizzardHide.SetHidden(addon.BlizzardHide.ENTRIES[1].id, true)
expectTrue("Probe Blizzard ausblenden", hasLine('"event":"ui.blizzardHide"') ~= nil)
wow.fire("PLAYER_REGEN_ENABLED")
expectTrue("Probe nach dem Kampf", hasLine('"event":"ui.blizzardHide.afterCombat"') ~= nil)
addon.Tooltip.ApplyScale(1.5)
expectTrue("Probe Tooltip-Größe", hasLine('"event":"ui.tooltip.scale"') ~= nil)
addon.SetupWizard.Show()
expectTrue("Probe Willkommenskarte", hasLine('"event":"ui.welcome"') ~= nil)
addon.InfoCard.Show()
expectTrue("Probe Infokarte", hasLine('"event":"ui.infoCard"') ~= nil)
expect("keine Lua-Fehler in den Proben", #wow.errors, 0)
