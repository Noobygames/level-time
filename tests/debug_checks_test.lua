-- /lt debug check in Retail: jede Prüfung aus DebugChecks.lua läuft ohne Lua-Fehler und schreibt ein Ergebnis;
-- Ereignis-Proben für Taint und Chatzeilen (ns.Print) landen im laufenden Log. Gleiche Prüfung für Classic Era
-- (era_debug_checks) und WoW Forever (forever_debug_checks).
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

local CHECKS = {
  "settings.all", "window.rows.level", "window.rows.session", "window.rows.instance", "window.state", "frames.addon",
  "238.moveFrames.frames", "329.cvars", "95.daily.dst", "90.xp.rates", "118.maxLevel", "194.format.units",
  "145.chatCopy.lines", "157.help", "175.level.records", "280.deaths.recent", "237.alerts.icons",
  "240.questMarks.plates", "249.trainer.cache", "253.coverage", "259.questLevels.log", "268.questItem.pick", "268.questItem.bagItems",
  "269.mapCoordinates", "270.questLogXp", "271.rested.estimate", "272.personalRecords", "274.tooltip.killsToLevel",
  "276.money.periods", "277.playHours", "278.reputation", "279.progressCurve", "282.instances", "284.splitList.lines",
  "286.bracketForecast", "287.ssf", "288.customSplits", "290.runs", "293.friendRace", "246.battleground",
  "329.social.target", "329.chat.windows", "329.chat.colors", "329.classColors", "329.characterFrame", "329.minimap",
  "357.theme", "358.frames.positions", "359.editMode",
  "364.lootRoll.api", "365.blizzardXpBar", "258.flight.estimates",
  "360.window.layout", "360.xpTooltip", "362.visibility", "371.blizzardFrames", "403.blizzardSettings", "361.readability",
}

wow.login()
SlashCmdList.LEVELTIMER("debug check")
for _, name in ipairs(CHECKS) do
  local line = hasLine('"name":"' .. name .. '"')
  expectTrue("Prüfung " .. name .. " geschrieben", line ~= nil)
  expect("Prüfung " .. name .. " ohne Fehler", line and line:match('"error":"([^"]*)"'), nil)
end
expectTrue("Zeitumstellung kommt weiter", hasLine('"stuckHours":0') ~= nil)
expect("keine Lua-Fehler", #wow.errors, 0)

-- Laufendes Log: Taint-Meldungen und Chatzeilen des Addons
SlashCmdList.LEVELTIMER("debug log")
wow.fire("ADDON_ACTION_BLOCKED", "LevelTimer", "TargetUnit()")
expectTrue("Taint-Probe", hasLine('"event":"ADDON_ACTION_BLOCKED"') ~= nil and hasLine('"TargetUnit()"') ~= nil)
addon.Print("Testzeile")
expectTrue("Chatzeile im Log", hasLine('"area":"print"') ~= nil and hasLine('"msg":"Testzeile"') ~= nil)
expect("keine Lua-Fehler im Log-Betrieb", #wow.errors, 0)

-- Entscheidungen der Module als Debug-Zeilen: im Kampf zurückgehaltene Einblendung
wow.state.inCombat = true
addon.Alerts.Show("Kampftest", addon.Alerts.WARNING_COLOR, { combat = "hold" })
expectTrue("Einblendung zurückgehalten", hasLine('"msg":"in combat: hold"') ~= nil)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
expectTrue("nach dem Kampf gezeigt", hasLine("combat over, showing 1 held") ~= nil and hasLine("shown Kampftest") ~= nil)
expect("keine Lua-Fehler am Ende", #wow.errors, 0)
