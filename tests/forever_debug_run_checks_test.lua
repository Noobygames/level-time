-- /lt debug check in WoW Forever: die Prüfungen und Proben für Läufe, Instanzen, Historie und Fenster (LT-73 bis LT-246)
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

local CHECKS = {
  "LT73.runs.imported", "LT145.lss.export", "LT161.history.tooltips",
  "LT171.history.tabs", "LT172.window.labels", "LT195.report.bossName", "LT200.instance.master", "LT203.loot.value",
  "LT226.runs.live", "LT227.questCheck", "LT230.bossLoot.tooltip", "LT242.bossLoot.icons", "LT243.dungeonQuests.source",
  "LT244.bossLoot.coverage", "LT245.mechanics.forever", "LT246.bossLoot.forever",
  "LT318.wings.state",
}

wow.login()
SlashCmdList.LEVELTIMER("debug check")
for _, name in ipairs(CHECKS) do
  local line = hasLine('"name":"' .. name .. '"')
  expectTrue("Prüfung " .. name .. " geschrieben", line ~= nil)
  expect("Prüfung " .. name .. " ohne Fehler", line and line:match('"error":"([^"]*)"'), nil)
end
expect("keine Lua-Fehler", #wow.errors, 0)

-- Proben schreiben nur bei laufendem Log
addon.DebugLog.SetEnabled(true)
addon.Runs.Import("kein Lauf")
expectTrue("Import-Probe", hasLine('"event":"runs.import"') ~= nil and hasLine('"length":9') ~= nil)
addon.ShowRunImport()
expectTrue("Import-Fenster-Probe", hasLine('"event":"runs.importOpen"') ~= nil)
wow.levelUp(wow.state.level + 1, 2000)
expectTrue("Prognose beim Levelstart", hasLine('"event":"forecast.levelStart"') ~= nil)
wow.fire("PLAYER_ENTERING_WORLD", false, false)
wow.runTimers()
expect("keine Lua-Fehler bei den Proben", #wow.errors, 0)
