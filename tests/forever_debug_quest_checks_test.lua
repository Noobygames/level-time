-- /lt debug check in WoW Forever (Interface 16001): Prüfungen und Proben für die Quest-, Karten-, Reise- und Komfort-Tasks
-- (ChecksQuests.lua).
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

local CHECKS = {
  "LT152.quests.counters", "LT154.quests.targetButton", "LT156.quests.cleanup", "LT157.quests.turnIn",
  "LT174.quests.efficiency", "LT176.quests.itemTooltip", "LT179.quests.leftovers", "LT177.map.questPoints",
  "LT231.dungeon.givers", "LT232.dungeon.tags", "LT237.map.pins", "LT238.minimap.givers", "LT235.dungeon.zone",
  "LT236.dungeon.accept", "LT185.flight.settings", "LT202.flight.legacy", "LT84.ready.state", "LT211.chat.fonts",
  "LT199.minimapBar.restore", "LT199.partyQuestSync.lines", "LT234.lootroll.icon",
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
wow.fire("RAID_TARGET_UPDATE")
expectTrue("Zielmarker-Probe", hasLine('"event":"RAID_TARGET_UPDATE"') ~= nil)
wow.fire("MERCHANT_SHOW")
expectTrue("Händler-Probe", hasLine('"event":"quests.merchantLeftovers"') ~= nil)
wow.fire("READY_CHECK", "Tester", 30)
expectTrue("Bereit-Probe", hasLine('"name":"LT84.ready.event"') ~= nil)
wow.fire("READY_CHECK_FINISHED")
wow.fire("UPDATE_BATTLEFIELD_STATUS")
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("Zonen-Probe", hasLine('"name":"LT235.dungeon.zoneEntered"') ~= nil)
addon.QuestCleanup.Abandon(999999)
expectTrue("Abbrechen-Probe", hasLine('"event":"quests.abandon"') ~= nil)
addon.MinimapBar.RestoreAll()
expectTrue("Minimap-Leisten-Probe", hasLine('"event":"minimapBar.restoreAll"') ~= nil)
expect("keine Lua-Fehler bei den Proben", #wow.errors, 0)
