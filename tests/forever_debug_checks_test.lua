-- /lt debug check in WoW Forever (Interface 16001): wie debug_checks, alle Prüfungen ohne Lua-Fehler mit Ergebnis.
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
  "276.money.periods", "277.playHours", "278.reputation", "279.progressCurve", "282.instances", "483.bosses", "493.instances.wing",
  "LT287.books.collected", "LT10.mechanics.mouseover", "497.dungeonEntrances", "284.splitList.lines",
  "286.bracketForecast", "287.ssf", "288.customSplits", "290.runs", "293.friendRace", "246.battleground",
  "329.social.target", "329.chat.windows", "329.chat.colors", "329.classColors", "329.characterFrame", "329.minimap",
  "357.theme", "358.frames.positions", "359.editMode",
  "364.lootRoll.api", "365.blizzardXpBar", "258.flight.estimates", "440.transport.state", "LT388.graphics.cvars",
  "360.window.layout", "360.xpTooltip", "362.visibility", "371.blizzardFrames", "403.blizzardSettings", "361.readability",
  "430.sleep.state",
  "443.threat", "445.qol", "450.mail", "453.partyQuestSync", "451.minimapBar.buttons", "character.guid", "452.swing.combatlog",
  "487.spellHistory.rank", "479.lootSparkles.skinning",
  "486.questRewards", "488.reagents", "481.minimapBar.layers", "500.collapsedBuffs", "LT352.lfg.api",
  "LT52.combatlog.guid", "LT279.kills.events", "LT267.combatlog.api", "LT259.questArrow.state", "LT254.attunements",
  "LT252.map.zoneLevels",
  "LT271.lfg.finder", "LT271.lfg.encounters", "LT271.lfg.languages", "LT272.lfg.window", "LT351.lfg.sidetab",
  "LT273.questmarks.instance",
  "LT285.damageMeter.api",
  "LT334.recap.api", "LT334.recap.state", "LT334.recap.deaths",
  "LT352.lfg.filters", "LT387.guide.anytime", "LT338.sync.groupApi", "LT393.dungeonArt.coverage", "LT395.icons.spells",
  "LT404.guide.spellLinks", "LT408.lfg.realms", "LT412.trivialTracking.api", "LT413.realm.sources",
  "LT405.recap.run", "LT407.lfg.levelOrder", "LT409.oldRanks.upgrade", "LT410.hearth.bind", "LT411.dungeonQuests.markAll",
  "LT412.trivialChain.state", "LT414.realm.splitEntries", "LT416.alerts.eliteGate", "LT416.cleanup.leftoversTitles",
  "LT401.tracker.layout",
}

wow.login()
wow.state.lfgResults = { [7] = { { name = "Thrall", level = 20, areaName = "Durotar", classFilename = "SHAMAN" } } }
SlashCmdList.LEVELTIMER("debug check")
for _, name in ipairs(CHECKS) do
  local line = hasLine('"name":"' .. name .. '"')
  expectTrue("Prüfung " .. name .. " geschrieben", line ~= nil)
  expect("Prüfung " .. name .. " ohne Fehler", line and line:match('"error":"([^"]*)"'), nil)
end
expectTrue("Zeitumstellung kommt weiter", hasLine('"stuckHours":0') ~= nil)
expect("keine Lua-Fehler", #wow.errors, 0)

-- Laufendes Log: Taint-Meldungen und Chatzeilen des Addons
addon.DebugLog.SetEnabled(true)
wow.fire("ADDON_ACTION_BLOCKED", "LevelTimer", "TargetUnit()")
expectTrue("Taint-Probe", hasLine('"event":"ADDON_ACTION_BLOCKED"') ~= nil and hasLine('"TargetUnit()"') ~= nil)
addon.Print("Testzeile")
expectTrue("Chatzeile im Log", hasLine('"area":"print"') ~= nil and hasLine('"msg":"Testzeile"') ~= nil)
expect("keine Lua-Fehler im Log-Betrieb", #wow.errors, 0)

-- Gruppensuche (LT-72): Suchergebnis und Überfahren schreiben die Felder nebenbei mit
expectTrue("Gruppensuche im Check", hasLine('"areaName":"Durotar"') ~= nil)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
expectTrue("Suchergebnis-Probe", hasLine('"event":"lfg.results"') ~= nil)
LFGBrowseSearchEntryTooltip_UpdateAndShow(LFGBrowseSearchEntryTooltip, 7)
expectTrue("Überfahren-Probe", hasLine('"event":"lfg.hover"') ~= nil and hasLine('"variant":"classic"') ~= nil)
expect("keine Lua-Fehler bei der Gruppensuche", #wow.errors, 0)

-- Ohne Kampflog-Abruf (Forever) meldet niemand COMBAT_LOG_EVENT_UNFILTERED an: das Anmelden ist dort verboten
-- (ADDON_ACTION_FORBIDDEN, LT-316)
expect("kein Kampflog-Event angemeldet", wow.findFrame(function(frame)
  return frame._events.COMBAT_LOG_EVENT_UNFILTERED ~= nil
end), nil)

-- LT-408: /lt debug lfgsearch sucht zweimal aus dem Befehl und einmal aus dem Timer, je mit einer Sprache
wow.state.lfgWindow = { categories = { [2] = "Dungeons" }, activities = { [2] = { 900 } }, filtered = {} }
wow.state.lfgLanguages = { filter = { enUS = true }, available = { "enUS", "deDE" }, defaults = { enUS = true } }
wow.lfgCalls = {}
SlashCmdList.LEVELTIMER("debug lfgsearch")
expect("Probe: zwei Suchen sofort", #wow.lfgCalls, 2)
expect("Probe: zweite Sprache", next(wow.lfgCalls[2][5]), "deDE")
wow.advance(3)
wow.runTimers()
expect("Probe: dritte Suche aus dem Timer", #wow.lfgCalls, 3)
expectTrue("Probe im Log", hasLine('"area":"lfg.searchProbe"') ~= nil)
expect("Probe ohne Fehler", #wow.errors, 0)
