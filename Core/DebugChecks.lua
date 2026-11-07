-- Prüfungen und Ereignis-Proben für die offenen Punkte in ManualToCheck.md: was dort sonst ein Mensch im Spiel
-- ablesen müsste (Werte, Zustände, Einstellungen, Entscheidungen der Module), steht nach /lt debug check bzw. mit
-- laufendem /lt debug log im Debug-Log. Die Entscheidungen selbst schreiben die Module mit ns.Debug, Chatzeilen
-- (ns.Print) stehen als Bereich "print" darin. Lädt nach allen Modulen; die Prüfungen lesen nur, ändern nichts und
-- rufen keine geschützten Funktionen.
-- Namen: "<Roadmap>.<Bereich>.<Was>" (Nummer = Roadmap-Punkt), allgemeine ohne Nummer. ManualToCheck.md nennt je
-- Punkt die Namen, die ihn beantworten.
local _, ns = ...
local DebugLog = ns.DebugLog
local Probe = DebugLog.Probe
local call, safe, api = Probe.call, Probe.safe, Probe.api
local write, packCount = DebugLog.Write, DebugLog.PackCount
local Stats = ns.Stats

local MAX_ITEMS = DebugLog.MAX_TABLE_ITEMS  -- mehr Einträge je Liste schreibt das Log nicht; längere werden geteilt
local RECENT_ENTRIES = 3                     -- letzte Journal-Einträge je Prüfung
local NAMEPLATES = 40
local SAMPLE_DURATION = 2 * 86400 + 3 * 3600 + 4 * 60 + 5  -- 2 Tage 3 h 4 min 5 s (Einheiten je Sprache, 194)
local LONG_DURATION = 123 * 86400 + 4 * 3600                -- über 100 Tage (139)
local SAMPLE_COPPER = 23005                                  -- 2 Gold 30 Silber 5 Kupfer (194)
local DST_CHECK_DAYS = { { 2026, 10, 25 }, { 2026, 3, 29 }, { 2027, 3, 28 }, { 2027, 10, 31 } }  -- Zeitumstellung (95)
local HOURS_PER_DAY_CHECKED = 48
local SECONDS_PER_HOUR = 3600
local CUSTOM_SPLIT_BINDING = "LEVELTIMER_CUSTOM_SPLIT"  -- Bindings.xml (288)
local QUEST_LOG_SAMPLE = 10

---------------------------------------------------------------------------
-- Helfer
---------------------------------------------------------------------------
-- Liste in Stücke zu MAX_ITEMS (das Log kürzt längere Listen)
local function chunked(list)
  local chunks = {}
  for index, item in ipairs(list) do
    if (index - 1) % MAX_ITEMS == 0 then chunks[#chunks + 1] = {} end
    table.insert(chunks[#chunks], item)
  end
  return chunks
end

-- Wert als kurzer Text (Tabellen als JSON)
local function plain(value)
  if ns.IsSecret(value) then return "<secret>" end
  if type(value) == "table" then return DebugLog.Encode(value) end
  return tostring(value)
end

-- object:name(...) geschützt; nil, wenn es die Methode nicht gibt
local function method(object, name, ...)
  if type(object) ~= "table" or type(object[name]) ~= "function" then return nil end
  return safe(object[name], object, ...)
end

local function frameName(frame)
  return type(frame) == "table" and ns.Overrides.NameOf(frame) or frame
end

-- Erster Ankerpunkt mit dem Namen des Bezugsrahmens
local function pointOf(frame)
  if type(frame) ~= "table" or type(frame.GetPoint) ~= "function" then return nil end
  local ok, point, relativeTo, relativePoint, x, y = pcall(frame.GetPoint, frame, 1)
  if not ok then return "error: " .. tostring(point) end
  return { point, frameName(relativeTo), relativePoint, x, y }
end

local function frameState(frame)
  if type(frame) ~= "table" then return false end
  return {
    shown = method(frame, "IsShown"), visible = method(frame, "IsVisible"), alpha = method(frame, "GetAlpha"),
    scale = method(frame, "GetScale"), width = method(frame, "GetWidth"), height = method(frame, "GetHeight"),
    point = pointOf(frame),
  }
end

local function framesByName(names)
  local result = {}
  for _, name in ipairs(names) do
    local frame = _G[name]
    if frame ~= nil then result[name] = frameState(frame) end
  end
  return result
end

-- Letzte count Einträge eines Journal-Eingangs (character.<log>, neueste zuletzt), neueste zuerst. Liest nur den
-- Eingang, damit die Prüfung das nachladbare Archiv nicht lädt.
local function recentEntries(logName, count)
  local inbox = ns.character and ns.character[logName] or {}
  local entries = {}
  for index = #inbox, math.max(1, #inbox - (count or RECENT_ENTRIES) + 1), -1 do
    entries[#entries + 1] = inbox[index]
  end
  return entries
end

-- Wie TimerWindow: XP-Balken nur mit Einstellung und solange der Charakter levelt
local function xpBarShown()
  return ns.db.showXpBar and ns.Experience.IsLeveling() or false
end

local function characterKeys()
  return ns.History.GetCharacterKeys()
end

---------------------------------------------------------------------------
-- Ereignis-Proben, die DebugProbes.lua noch nicht hat (Taint, CVars, Fenster schließen, eigene Gruppen-Nachrichten)
---------------------------------------------------------------------------
local function durability()
  return ns.GearWarnings.GetOverallDurability()
end

local function afkState()
  return { afk = call("UnitIsAFK", "player"), dnd = call("UnitIsDND", "player") }
end

local function battlegroundWinner()
  return { winner = call("GetBattlefieldWinner"), activeMatchWinner = call("C_PvP.GetActiveMatchWinner"),
    faction = (call("UnitFactionGroup", "player")), instance = call("GetInstanceInfo") }
end

-- Eigene Nachricht im Gruppen-/Gildenchat (kam die Ansage beim Server an?); sender ist "Name" oder "Name-Realm"
local function isOwnMessage(_, sender)
  if type(sender) ~= "string" or ns.IsSecret(sender) then return false end
  local own = UnitName("player")
  return not ns.IsSecret(own) and (sender == own or sender:match("^([^-]+)") == own)
end

local function forPlayer(unit)
  return unit == "player"
end

-- Beute-Würfe (364): was Client und Historie zu einem Wurf liefern (Würfel-ID gleich der Historie? geheim?)
local function lootRollStart(rollID)
  return { link = call("GetLootRollItemLink", rollID), info = call("GetLootRollItemInfo", rollID),
    timeLeft = call("GetLootRollTimeLeft", rollID), active = call("GetActiveLootRollIDs") }
end

local function legacyRollChanged(itemIndex, playerIndex)
  return { item = call("C_LootHistory.GetItem", itemIndex),
    player = call("C_LootHistory.GetPlayerInfo", itemIndex, playerIndex) }
end

local function lootDrop(encounterID, lootListID)
  local drop = call("C_LootHistory.GetSortedInfoForDrop", encounterID, lootListID)
  if type(drop) ~= "table" or ns.IsSecret(drop) then return { drop = drop } end
  local rolls = {}
  for index, info in ipairs(type(drop.rollInfos) == "table" and drop.rollInfos or {}) do
    if index > MAX_ITEMS then break end
    rolls[index] = { info.playerName, info.playerClass, info.state, info.roll, info.isWinner, info.isSelf }
  end
  local winner = type(drop.winner) == "table" and { drop.winner.playerName, drop.winner.roll } or drop.winner
  return { link = drop.itemHyperlink, lootListID = drop.lootListID, lootListKey = drop.lootListKey,
    allPassed = drop.allPassed, isTied = drop.isTied, winner = winner, rolls = rolls }
end

local EVENT_PROBES = {
  -- Beute-Würfe (364)
  { event = "START_LOOT_ROLL", extra = lootRollStart },
  { event = "CANCEL_LOOT_ROLL" },
  { event = "CANCEL_ALL_LOOT_ROLLS" },
  { event = "LOOT_ROLLS_COMPLETE" },
  { event = "LOOT_HISTORY_ROLL_CHANGED", extra = legacyRollChanged },
  { event = "LOOT_HISTORY_ROLL_COMPLETE" },
  { event = "LOOT_HISTORY_FULL_UPDATE", extra = function() return call("C_LootHistory.GetNumItems") end },
  { event = "LOOT_HISTORY_UPDATE_DROP", extra = lootDrop },
  { event = "LOOT_HISTORY_UPDATE_ENCOUNTER" },
  -- Taint und gesperrte Aktionen (alle Punkte mit „kein Aktion blockiert“): Addon-Name und Funktion
  { event = "ADDON_ACTION_BLOCKED", state = true },
  { event = "ADDON_ACTION_FORBIDDEN", state = true },
  { event = "MACRO_ACTION_BLOCKED" },
  { event = "MACRO_ACTION_FORBIDDEN" },
  -- CVars, die wir oder der Spieler ändern (329 Schritt 5, 330)
  { event = "CVAR_UPDATE" },
  -- Einnahmen und Ausgaben nach Fenster (276): Reihenfolge Schließen gegen PLAYER_MONEY
  { event = "LOOT_OPENED" },
  { event = "LOOT_CLOSED" },
  { event = "MERCHANT_CLOSED" },
  { event = "MAIL_CLOSED" },
  { event = "TRADE_CLOSED" },
  { event = "TAXIMAP_CLOSED" },
  { event = "QUEST_FINISHED" },
  { event = "UPDATE_INVENTORY_DURABILITY", extra = durability },  -- 329 Schritt 2d (Haltbarkeit)
  -- AFK und Leerlauf (263, 283)
  { event = "PLAYER_FLAGS_CHANGED", filter = forPlayer, extra = afkState },
  -- Gruppe, Freunde, Inspizieren (291, 293, 329 Schritt 3a)
  { event = "GROUP_JOINED" },
  { event = "GROUP_LEFT" },
  { event = "INSPECT_READY" },
  { event = "BN_FRIEND_INVITE_ADDED" },
  -- Schlachtfeld-Ergebnis (246, Level Time Goals)
  { event = "PVP_MATCH_COMPLETE", extra = battlegroundWinner },
  -- Screenshots (294), Beute-Glitzer-Ziel (330)
  { event = "SCREENSHOT_FAILED" },
  { event = "PLAYER_SOFT_INTERACT_CHANGED" },
  -- Eigene Ansagen im Chat (264, 282, Level-Up-Ansage)
  { event = "CHAT_MSG_PARTY", filter = isOwnMessage },
  { event = "CHAT_MSG_PARTY_LEADER", filter = isOwnMessage },
  { event = "CHAT_MSG_INSTANCE_CHAT", filter = isOwnMessage },
  { event = "CHAT_MSG_INSTANCE_CHAT_LEADER", filter = isOwnMessage },
  { event = "CHAT_MSG_RAID", filter = isOwnMessage },
  { event = "CHAT_MSG_RAID_LEADER", filter = isOwnMessage },
  { event = "CHAT_MSG_GUILD", filter = isOwnMessage },
}

local function probeEvent(probe, ...)
  if not DebugLog.IsEnabled() then return end
  if probe.filter and not probe.filter(...) then return end
  local count = math.min(select("#", ...), Probe.MAX_EVENT_ARGS)
  while count > 0 and select(count, ...) == nil do count = count - 1 end
  local entry = { area = "event", event = probe.event, args = packCount(count, ...) }
  if probe.state then entry.state = Probe.playerState() end
  if probe.extra then entry.extra = safe(probe.extra, ...) end
  write(entry)
end

for _, probe in ipairs(EVENT_PROBES) do
  ns.RegisterEvent(probe.event, function(...) probeEvent(probe, ...) end)
end

-- Classic-Schlachtfelder melden den Sieger nur über UPDATE_BATTLEFIELD_SCORE (kommt alle paar Sekunden): nur
-- schreiben, wenn sich der Sieger ändert
local lastWinner
ns.RegisterEvent("UPDATE_BATTLEFIELD_SCORE", function()
  if not DebugLog.IsEnabled() then return end
  local winner = call("GetBattlefieldWinner")
  if winner == lastWinner then return end
  lastWinner = winner
  write({ area = "event", event = "UPDATE_BATTLEFIELD_SCORE", extra = battlegroundWinner() })
end)

---------------------------------------------------------------------------
-- Allgemeine Prüfungen: Einstellungen, Fensterzeilen, Frames, CVars
---------------------------------------------------------------------------
local check = DebugLog.AddCheck

-- Alle Einstellungen als "Schlüssel=Wert" (welche Schalter waren beim Test an?)
check("settings.all", function()
  local keys = {}
  for key in pairs(ns.db) do keys[#keys + 1] = tostring(key) end
  table.sort(keys)
  local lines = {}
  for _, key in ipairs(keys) do lines[#lines + 1] = key .. "=" .. plain(ns.db[key]) end
  return chunked(lines)
end)

-- Was das Zeitfenster je Bereich zeigt: "Schalter*: Zeile=Wert | ..." (* = sichtbar). Antwortet auf alle Punkte
-- "Zeile zeigt ..." (150, 151, 270, 273, 276, 278, 283, 149)
local function windowRows(scope)
  local lines = {}
  for _, stat in ipairs(ns.STAT_LINES) do
    if not stat.available or stat.available() then
      local parts = {}
      for _, row in ipairs(stat.rows) do
        local ok, value = pcall(row.value, scope)
        parts[#parts + 1] = tostring(ns.L[row.label]) .. "=" .. (ok and plain(value) or "error: " .. tostring(value))
      end
      local shown = ns.IsStatShown(stat, ns.db) and "*" or ""
      lines[#lines + 1] = stat.setting .. shown .. ": " .. table.concat(parts, " | ")
    end
  end
  return chunked(lines)
end
check("window.rows.level", function() return windowRows(Stats.LEVEL) end)
check("window.rows.session", function() return windowRows(Stats.SESSION) end)
check("window.rows.instance", function() return windowRows(Stats.INSTANCE) end)

-- Zeitfenster: Reiter, XP-Balken, offener Instanz-Lauf (118, 149, 161)
check("window.state", function()
  local frame = _G.LevelTimerFrame
  local run = ns.Instances.GetCurrentRun()
  return {
    frame = frameState(frame), xpBar = xpBarShown(),
    scope = ns.db.windowScope, leveling = ns.Experience.IsLeveling(), instanceOpen = Stats.IsOpen(Stats.INSTANCE),
    run = run and { name = run.name, seconds = ns.Instances.GetRunSeconds(run), summary = { ns.Instances.Summarize(run) },
      running = ns.Instances.IsRunning() },
  }
end)

-- Eigene Fenster und Anzeigen: Sichtbarkeit, Größe, Position (Position nach /reload, Wandern beim Skalieren)
check("frames.addon", function()
  return framesByName({ "LevelTimerFrame", "LevelTimerAlert", "LevelTimerNotice", "LevelTimerCamp", "LevelTimerFood",
    "LevelTimerFlight", "LevelTimerSplits", "LevelTimerLevelUp", "LevelTimerQuestItemBar", "LevelTimerRecap",
    "LevelTimerMinimapButton", "LevelTimerMapCoordinates", "LevelTimerEmergency", "LevelTimerDeathMap",
    "LevelTimerOptions", "LevelTimerHistory" })
end)

-- 238/266: Blizzard-Fenster, die "Fenster verschieben" kennt (Position, Größe nach Öffnen und /reload)
check("238.moveFrames.frames", function()
  return { frames = framesByName(ns.MoveFrames.FRAME_NAMES), positions = ns.db.movedFrames,
    scales = ns.db.movedFrameScales }
end)

-- CVars der Komfort-Einstellungen mit Standardwerten und gemerkten Originalen (329 Schritt 5, 330, 2d)
local CVARS = {
  "autoLootDefault", "cameraDistanceMaxZoomFactor", "ffxGlow", "ffxDeath", "ffxNether", "weatherDensity",
  "RAIDweatherDensity", "nameplateShowEnemies", "nameplateShowFriends", "Sound_EnableEmoteSounds",
  "Sound_MasterVolume", "Sound_EnableAllSound", "SoftTargetInteract", "SoftTargetIconGameObject",
  "SoftTargetIconInteract", "SoftTargetNameplateInteract", "SoftTargetInteractRange", "SoftTargetIconLoot",
  "scriptErrors", "loadDeprecationFallbacks", "chatStyle", "chatMouseScroll",
}
check("329.cvars", function()
  local values, defaults = {}, {}
  for _, name in ipairs(CVARS) do
    values[name] = call("C_CVar.GetCVar", name) or call("GetCVar", name)
    defaults[name] = call("C_CVar.GetCVarDefault", name)
  end
  return { values = values, defaults = defaults, originals = LevelTimerDB and LevelTimerDB.cvarOriginals,
    characterOriginals = ns.character and ns.character.cvarOriginals, lowLevelRaid = call("GetAllowLowLevelRaid"),
    lowLevelRaidOriginal = ns.character and ns.character.lowLevelRaidOriginal }
end)

---------------------------------------------------------------------------
-- Prüfungen je Roadmap-Punkt
---------------------------------------------------------------------------
-- 95: Zeitumstellung. Nächste Mitternacht über den Kalender muss an jedem Tag rund um die Umstellung weiter
-- kommen (sonst hing Daily.BookPlayTime); mit der echten Zeitzone des Clients
check("95.daily.dst", function()
  local results = {}
  for _, day in ipairs(DST_CHECK_DAYS) do
    local start = time({ year = day[1], month = day[2], day = day[3], hour = 0 })
    local stuck = 0
    for hour = 0, HOURS_PER_DAY_CHECKED - 1 do
      local timestamp = start + hour * SECONDS_PER_HOUR
      if ns.Daily.AddDays(timestamp, 1) <= timestamp then stuck = stuck + 1 end
    end
    results[#results + 1] = { day = ns.Daily.DayKey(start), dayLength = ns.Daily.AddDays(start, 1) - start,
      stuckHours = stuck }
  end
  return results
end)

-- 90/150/151: XP/h des laufenden Levels und der Session in Fenster, Level-Tabelle, Graph und Vergleich
check("90.xp.rates", function()
  local key = ns.characterKey
  local levelRecord = ns.History.GetLevelRecords(key)[1]
  local sessionRecord = ns.History.GetSessionRecords(key)[1]
  local chart = ns.Analysis.XpRatePerLevel(key)
  local compare
  for _, record in ipairs(ns.History.GetCharacterComparison()) do
    if record.key == key then compare = record.xpRate end
  end
  return {
    xpRateWithoutAfk = ns.db.xpRateWithoutAfk, idleMinutes = ns.db.idleMinutes,
    window = { level = ns.Experience.GetRatePerHour(Stats.LEVEL), session = ns.Experience.GetRatePerHour(Stats.SESSION),
      instance = ns.Experience.GetRatePerHour(Stats.INSTANCE) },
    xpGained = { level = Stats.GetXp(Stats.LEVEL), session = Stats.GetXp(Stats.SESSION), instance = Stats.GetXp(Stats.INSTANCE) },
    levelTable = ns.Experience.RecordRate(levelRecord), sessionTable = ns.Experience.RecordRate(sessionRecord),
    chartCurrent = chart[#chart] and chart[#chart].value, compareOverall = compare,
  }
end)

-- 118: Levelcap der Erweiterung (Retail): XP-Balken und XP/h nur beim Leveln
check("118.maxLevel", function()
  return { level = call("UnitLevel", "player"), xpMax = call("UnitXPMax", "player"),
    atEffectiveMax = call("GameRulesUtil.IsPlayerAtEffectiveMaxLevel"),
    maxForExpansion = call("GetMaxLevelForPlayerExpansion"), maxPlayerLevel = call("GetMaxPlayerLevel"),
    leveling = ns.Experience.IsLeveling(), xpBar = xpBarShown() }
end)

-- 139/194: Zeit- und Geldtexte in der eingestellten Sprache, auch über 100 Tage
check("194.format.units", function()
  local levelSeconds = Stats.GetSeconds(Stats.LEVEL)  -- nil, bis /played geantwortet hat
  return { language = ns.db.language, duration = ns.Format.Duration(SAMPLE_DURATION),
    long = ns.Format.Duration(LONG_DURATION), clock = ns.Format.Clock(LONG_DURATION),
    plainMoney = ns.Format.PlainMoney(SAMPLE_COPPER), levelTime = levelSeconds and ns.Format.Duration(levelSeconds) }
end)

-- 145: Zeilen des ersten Chatfensters, wie das Kopierfenster sie bekommt (älteste zuerst, ohne Farbcodes)
check("145.chatCopy.lines", function()
  local lines, hidden = ns.ChatCopy.Lines(_G.ChatFrame1)
  local colorCodes = 0
  for _, line in ipairs(lines) do
    if line:find("|c", 1, true) or line:find("|H", 1, true) then colorCodes = colorCodes + 1 end
  end
  return { count = #lines, hidden = hidden, withCodes = colorCodes, first = lines[1], last = lines[#lines] }
end)

-- 157: Hilfe-Zeilen und Willkommenshinweis
check("157.help", function()
  local lines = {}
  for line in ns.L.HELP:gmatch("[^\n]+") do lines[#lines + 1] = line end
  return { lines = #lines, introShown = LevelTimerStatsDB and LevelTimerStatsDB.introShown }
end)

-- 175: Level-Einträge (XP = Bedarf des alten Levels?) gegen die XP-Tabelle
check("175.level.records", function()
  local records = {}
  for _, record in ipairs(ns.History.GetLevelRecords(ns.characterKey)) do
    if #records >= RECENT_ENTRIES + 1 then break end
    records[#records + 1] = { level = record.level, xp = record.xp, seconds = record.seconds, current = record.isCurrent,
      partial = record.partial, table = record.level and ns.XpTable.XpBetween(record.level, record.level + 1) }
  end
  return records
end)

-- 180/280: letzte Tode mit Ursache, Ort und letzten Worten
check("280.deaths.recent", function() return recentEntries("deathLog") end)

-- 237/244: Symbole der Hinweise; nil = der Client kennt die Textur nicht (grünes Quadrat)
check("237.alerts.icons", function()
  local icons = {}
  for name, icon in pairs(ns.Alerts.ICONS) do
    if type(icon) == "number" then
      icons[name] = { spell = icon, texture = call("C_Spell.GetSpellTexture", icon) or call("GetSpellTexture", icon) }
    else
      icons[name] = { path = icon, fileId = call("GetFileIDFromPath", icon) }
    end
  end
  return { style = ns.db.alertStyle, icons = icons, fileIdApi = type(api("GetFileIDFromPath")) }
end)

-- 240: Questziel-Markierung je Namensplakette
check("240.questMarks.plates", function()
  local plates = {}
  for index = 1, NAMEPLATES do
    local unit = "nameplate" .. index
    if call("UnitExists", unit) == true then
      plates[#plates + 1] = { name = call("UnitName", unit), related = call("C_QuestLog.UnitIsRelatedToActiveQuest", unit),
        plate = frameState(call("C_NamePlate.GetNamePlateForUnit", unit)) }
    end
  end
  return { enabled = ns.db.questMarks, available = ns.QuestMarks.IsAvailable(), plates = plates }
end)

-- 249: gemerkte Lehrer-Fähigkeiten für die nächsten Level
check("249.trainer.cache", function()
  return { available = ns.TrainerCache.IsAvailable(), count = ns.TrainerCache.Count(),
    nextLevel = ns.TrainerCache.ForLevel(ns.level + 1), afterNext = ns.TrainerCache.ForLevel(ns.level + 2) }
end)

-- 253: Erfassungsquote je Charakter
check("253.coverage", function()
  local result = {}
  for _, key in ipairs(characterKeys()) do
    local fraction = ns.Coverage.Get(key)
    result[key] = { fraction = fraction, text = ns.Coverage.Text(fraction),
      partial = ns.History.GetCharacter(key).currentLevel.partial }
  end
  return result
end)

-- 259: Quest-Level im Questlog, wie das Präfix aussähe
check("259.questLevels.log", function()
  local entries = {}
  for _, entry in ipairs(ns.QuestLog.Entries()) do
    if #entries >= QUEST_LOG_SAMPLE then break end
    entries[#entries + 1] = { id = entry.questID, level = entry.level, group = entry.group, ready = entry.ready,
      text = ns.QuestLevels.Prefix(entry.title or "", entry.level, entry.group) }
  end
  return { enabled = ns.db.questLevels, entries = entries }
end)

-- 268: Kandidaten für den Quest-Item-Knopf, Wahl, Zielname
check("268.questItem.pick", function()
  local pick = ns.QuestItem.Pick()
  return { candidates = ns.QuestItem.Candidates(), pick = pick and { itemId = pick.itemId, questID = pick.questID },
    targets = ns.QuestItem.TargetNames(), canTarget = ns.QuestItem.CanTarget(),
    buttons = framesByName({ "LevelTimerQuestItemButton", "LevelTimerQuestTargetButton" }) }
end)

-- 269: Koordinatentext der Weltkarte und Spielerposition
check("269.mapCoordinates", function()
  local map = _G.WorldMapFrame
  return { player = ns.MapCoordinates.PlayerText(nil), map = type(map) == "table" and safe(ns.MapCoordinates.Text, map),
    mapId = method(map, "GetMapID") }
end)

-- 270: Quest-XP im Questlog (fertig/offen) und was nach der Abgabe noch fehlt
check("270.questLogXp", function()
  return { sums = { ns.QuestLogXp.Get() }, missingAfterTurnIn = ns.QuestLogXp.MissingAfterTurnIn() }
end)

-- 271: geschätzte Ruhe-XP je Charakter (Stand beim Logout, Schätzung jetzt)
check("271.rested.estimate", function()
  local result = {}
  for _, key in ipairs(characterKeys()) do
    result[key] = { estimate = { ns.RestedEstimate.Get(key) }, snapshot = ns.History.GetCharacter(key).restSnapshot }
  end
  return result
end)

-- 272: persönliche Rekorde
check("272.personalRecords", function()
  local rows = {}
  for _, row in ipairs(ns.PersonalRecords.GetRows()) do
    rows[#rows + 1] = { label = row.label, value = row.value, character = row.characterKey, level = row.level, at = row.at }
  end
  return rows
end)

-- 274: Kills bis Level-Up für das Ziel (Tooltip-Zeile)
check("274.tooltip.killsToLevel", function()
  return { target = Probe.unitInfo("target"), kills = { ns.MobXp.KillsToLevel("target") },
    line = { ns.Tooltip.KillsLine("target") } }
end)

-- 276: Einnahmen und Ausgaben je Zeitraum, Gold aller Charaktere
check("276.money.periods", function()
  return { periods = ns.Money.GetPeriodRecords(ns.characterKey), totalGold = ns.Money.TotalGold(),
    money = call("GetMoney") }
end)

-- 277: Spielstunden der Woche (Summe, belegte Kacheln)
check("277.playHours", function()
  local grid = ns.PlayHours.Grid(ns.characterKey)
  local cells = {}
  for day, hours in pairs(grid.cells) do
    for hour, cell in pairs(hours) do
      if cell.seconds > 0 then cells[#cells + 1] = day .. "-" .. hour .. "=" .. cell.seconds .. "s/" .. cell.xp .. "xp" end
    end
  end
  return { total = grid.total, max = grid.maxSeconds, now = ns.PlayHours.Slot(time()), cells = chunked(cells) }
end)

-- 278: Ruf je Fraktion
check("278.reputation", function() return ns.character.reputationGains end)

-- 279: Linien der Fortschrittskurve (Anzahl Punkte, letzter Punkt)
check("279.progressCurve", function()
  local series = {}
  for _, line in ipairs(ns.ProgressCurve.Series(ns.characterKey)) do
    series[#series + 1] = { label = line.label, points = #line.points, last = line.points[#line.points],
      dashed = line.dashed }
  end
  return series
end)

-- 282/92/124: Instanzen: offener Lauf, letzte Läufe, Limits laut Addon
check("282.instances", function()
  local run = ns.Instances.GetCurrentRun()
  return {
    current = run and { name = run.name, key = run.key, seconds = ns.Instances.GetRunSeconds(run),
      summary = { ns.Instances.Summarize(run) }, unconfirmed = run.unconfirmed ~= nil },
    recent = recentEntries("instanceLog"),
    limit = { hour = ns.InstanceLimit.GetHourCount(), limit = ns.InstanceLimit.GetLimit(),
      today = ns.InstanceLimit.GetTodayCount(), day = ns.InstanceLimit.GetDayCount(),
      dailyLimit = ns.InstanceLimit.GetDailyLimit(), nextFree = ns.InstanceLimit.GetSecondsUntilNextFree() },
    visits = ns.character.instanceVisits,
  }
end)

-- 284-289, 293: Zeilen der Split-Liste mit Farbcodes (Gold lila, Toleranz gelb), Fußzeilen, Prognose, SSF
check("284.splitList.lines", function()
  local lines = {}
  for _, line in ipairs(ns.SplitList.BuildLines()) do
    lines[#lines + 1] = { level = line.level, seconds = line.seconds, delta = line.delta, text = line.deltaText,
      gold = line.gold, friend = line.friendText }
  end
  return { lines = lines, footer = ns.SplitList.BuildFooterLines(), comparison = ns.db.splitComparison,
    reference = ns.Splits.GetReferenceName and ns.Splits.GetReferenceName(), tolerance = ns.db.splitTolerancePercent }
end)

check("286.bracketForecast", function() return ns.BracketForecast.Get() end)

check("287.ssf", function()
  local category = ns.SsfRules.GetCategory()
  return { category = category, restedBars = category and ns.SsfRules.RestedBars(category),
    logouts = ns.SsfRules.GetLogouts(), lines = ns.SsfRules.BuildLines() }
end)

check("288.customSplits", function()
  return { splits = ns.CustomSplits.GetAll(), template = ns.CustomSplits.GetTemplate(),
    binding = { call("GetBindingKey", CUSTOM_SPLIT_BINDING) }, bindingFunction = type(_G.LevelTimer_CustomSplit) }
end)

-- 290/291: Läufe mit Prüfcode-Status, Kategorie und Erfassungsquote
check("290.runs", function()
  local runs = {}
  for _, run in ipairs(ns.Runs.GetAll()) do
    runs[#runs + 1] = { id = run.id, imported = run.imported, check = ns.RunCheck.Verify(run),
      category = run.category, coverage = run.coverage, reached = run.reachedLevel }
  end
  return chunked(runs)
end)

-- 293: zuletzt gehörter Freund im Rennen
check("293.friendRace", function()
  local name, run = ns.FriendRace.Current()
  local levels = 0
  for _ in pairs(run and run.times or {}) do levels = levels + 1 end
  return { friend = name, levels = levels, enabled = ns.db.friendRace }
end)

-- 246: Schlachtfeld-Sieger (Level Time Goals zählt einen Sieg einmal)
check("246.battleground", function()
  return { result = battlegroundWinner(), counted = StreamGoalDB and StreamGoalDB.bgResultCounted }
end)

-- 329 Schritt 3a/265: Freund, Gilde, vertrauenswürdig für das Ziel
check("329.social.target", function()
  local name, guid = call("UnitName", "target"), call("UnitGUID", "target")
  if type(name) ~= "string" then return { target = false } end
  return { name = name, friend = call("C_FriendList.IsFriend", guid), guild = call("C_GuildInfo.MemberExistsByName", name),
    trusted = safe(ns.Friends.IsTrusted, name, guid), info = safe(ns.InviteInfo.Describe, name, guid) }
end)

-- 364: Beute-Würfe: welche Quelle (Historie alt/neu, Chat), welche Formate der Client kennt (roh), Blizzards
-- Würfelfenster und die verfolgten Würfe mit Zählung
check("364.lootRoll.api", function()
  local LootRolls = ns.LootRolls
  local formats, missing = {}, {}
  for _, name in ipairs(LootRolls.FORMAT_NAMES) do
    local format = _G[name]
    if format == nil then missing[#missing + 1] = name else formats[#formats + 1] = name .. "=" .. plain(format) end
  end
  local frames = {}
  for index = 1, 10 do
    local frame = _G["GroupLootFrame" .. index]
    if type(frame) ~= "table" then break end
    frames[index] = { state = frameState(frame), rollID = plain(frame.rollID) }
  end
  local tracked = {}
  for _, roll in ipairs(LootRolls.All()) do
    tracked[#tracked + 1] = { id = roll.id, link = roll.link, counts = LootRolls.Counts(roll), closed = roll.closed,
      fromHistory = roll.fromHistory, historyId = roll.historyId, dropKey = roll.dropKey }
  end
  return { source = LootRolls.HistorySource(), wanted = LootRolls.IsWanted(ns.db) and true or false,
    apis = { legacy = api("C_LootHistory.GetItem") ~= nil, drops = api("C_LootHistory.GetSortedInfoForDrop") ~= nil,
      activeIds = call("GetActiveLootRollIDs"), container = frameState(_G.GroupLootContainer) },
    missing = missing, formats = chunked(formats), frames = frames, tracked = tracked }
end)

-- 329 Schritt 3b: Chatfenster (Kampflog-Reiter, Knöpfe, Eingabezeile, Ausblenden)
check("329.chat.windows", function()
  local frames = {}
  for _, chatFrame in ipairs(ns.ChatFrames()) do
    local name = frameName(chatFrame)
    local tab = _G[name .. "Tab"]
    frames[#frames + 1] = { name = name, shown = method(chatFrame, "IsShown"), fading = method(chatFrame, "GetFading"),
      tab = frameState(tab), editBox = pointOf(_G[name .. "EditBox"]),
      buttonFrame = frameState(_G[name .. "ButtonFrame"]) }
  end
  return { frames = frames, buttons = framesByName({ "ChatFrameMenuButton", "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton", "QuickJoinToastButton", "FriendsMicroButton" }) }
end)

-- 329 Schritt 3b/5: Chatfarben (eine Gruppenfarbe)
check("329.chat.colors", function()
  local colors = {}
  for _, chatType in ipairs({ "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT",
    "INSTANCE_CHAT_LEADER" }) do
    local info = ChatTypeInfo and ChatTypeInfo[chatType]
    colors[chatType] = info and { info.r, info.g, info.b } or false
  end
  return { colors = colors, originals = ns.character.chatColorOriginals }
end)

-- 329 Schritt 4: Namenshintergrund von Ziel und Fokus (Klassenfarbe), Klasse der Einheit
check("329.classColors", function()
  local result = {}
  for _, frame in ipairs(ns.ClassColors.Frames()) do
    local unit = frame.unit
    result[frameName(frame)] = { unit = unit, color = { method(ns.ClassColors.NameBackground(frame), "GetVertexColor") },
      class = unit and { call("UnitClass", unit) }, player = unit and call("UnitIsPlayer", unit) }
  end
  return result
end)

-- 329 Schritt 2d/4: Haltbarkeit (eigene Summe gegen Anzeige), Lautstärke
check("329.characterFrame", function()
  local value, slider = ns.CharacterFrameExtras.Widgets()
  return { durability = ns.GearWarnings.GetOverallDurability(), lowest = ns.GearWarnings.GetLowestDurability(),
    shownText = method(value, "GetText"), shown = method(value, "IsShown"),
    slider = slider and { shown = method(slider, "IsShown"), value = method(slider, "GetValue") },
    volume = call("C_CVar.GetCVar", "Sound_MasterVolume") or call("GetCVar", "Sound_MasterVolume") }
end)

-- 329 Schritt 4: Minimap-Knöpfe und Mausrad
check("329.minimap", function()
  local zoom = {}
  for _, button in ipairs(ns.MinimapTweaks.ZoomButtons()) do zoom[frameName(button)] = frameState(button) end
  return { zoom = zoom, calendar = frameState(_G.GameTimeFrame), canWheelZoom = ns.MinimapTweaks.CanWheelZoom(),
    wheel = method(_G.Minimap, "IsMouseWheelEnabled") }
end)

-- 357: Theme, Font-Objekte je Rolle (Schrift, Größe, Flags nach dem Anwenden), LibSharedMedia geladen
check("357.theme", function()
  local fonts = {}
  for _, role in ipairs({ "title", "body", "label", "small", "number", "huge" }) do
    fonts[role] = { method(_G[ns.Theme.Font(role)], "GetFont") }
  end
  return { theme = ns.db.theme, accent = ns.db.themeAccent, font = ns.db.themeFont,
    fontPath = ns.Theme.FontPath(ns.db.themeFont), offset = ns.db.themeFontSize, outline = ns.db.themeOutline,
    fonts = fonts, fontChoices = #ns.Theme.FontChoices(), accentColor = ns.Theme.Hex("accent"),
    sharedMedia = (LibStub and LibStub("LibSharedMedia-3.0", true)) ~= nil }
end)

-- 358: angemeldete Anzeigen: gespeicherter Eintrag gegen Anker und Größe des Rahmens
check("358.frames.positions", function()
  local result = {}
  for _, reg in ipairs(ns.Frames.All()) do
    result[reg.id] = { saved = ns.db.frames and ns.db.frames[reg.id], scale = ns.Frames.GetScale(reg.id),
      frame = frameState(reg.frame) }
  end
  return { locked = ns.db.locked, frames = result }
end)

-- 359: Edit-Modus und Blizzards Bearbeitungsmodus (gibt es ihn, ist er eingehängt)
check("359.editMode", function()
  local manager = _G.EditModeManagerFrame
  return { active = ns.EditMode.IsActive(), grid = ns.db.editGrid, withBlizzard = ns.db.editModeWithBlizzard,
    blizzard = type(manager) == "table", enter = type(manager) == "table" and type(manager.EnterEditMode) == "function",
    hooked = ns.EditMode.blizzardHooked == true, combat = call("InCombatLockdown") }
end)

-- 365: Blizzards Erfahrungs- und Rufleiste: gefundene Behälter und Leisten mit Zustand (Alpha, Maus, Rahmen)
check("365.blizzardXpBar", function()
  local HideFrames = ns.HideFrames
  local function bars(kind)
    local list = {}
    for _, bar in ipairs(HideFrames.StatusBars(kind)) do
      local state = frameState(bar)
      state.name, state.mouse = frameName(bar), method(bar, "IsMouseEnabled")
      table.insert(list, state)
    end
    return list
  end
  local containers = {}
  for _, container in ipairs(HideFrames.StatusBarContainers()) do
    local state = frameState(container)
    local art = HideFrames.ContainerArt(container)
    state.name, state.shownBar, state.art = frameName(container), HideFrames.ShownBarIndex(container), #art
    state.artAlpha = art[1] and method(art[1], "GetAlpha")
    table.insert(containers, state)
  end
  return { hideXp = ns.db.hideBlizzardXpBar, hideRep = ns.db.hideBlizzardRepBar,
    manager = type(_G.StatusTrackingBarManager) == "table", experienceIndex = HideFrames.BarIndex("experience"),
    reputationIndex = HideFrames.BarIndex("reputation"), containers = containers, xp = bars("experience"),
    rep = bars("reputation"), legacyXp = frameState(_G.MainMenuExpBar),
    maxLevelBar = frameState(_G.MainMenuBarMaxLevelBar), combat = call("InCombatLockdown") }
end)

-- 258/370: Flugzeiten-Schätzung: eigene Strecken, Faktoren und Messungen je Karte, mitgelieferte Faktoren; dazu was
-- die Flug-API gerade liefert (bei offener Karte: GetTaxiMapID, ob C_TaxiMap nodeIDs je Slot kennt; offen für Era/TBC)
check("258.flight.estimates", function()
  local summary = ns.FlightTimes.Summary()
  local mapID = call("GetTaxiMapID")
  local nodes = type(mapID) == "number" and mapID ~= 0 and call("C_TaxiMap.GetAllTaxiNodes", mapID)
  local first = type(nodes) == "table" and nodes[1]
  summary.api = { taxiMapID = mapID, numNodes = call("NumTaxiNodes"),
    taxiMapNodes = type(nodes) == "table" and #nodes or nil,
    firstNode = type(first) == "table" and { nodeID = first.nodeID, slotIndex = first.slotIndex, name = first.name }
      or nil,
    tooltipHook = type(_G.TaxiNodeOnButtonEnter) == "function", flightMapMixin = type(_G.FlightMap_FlightPointPinMixin) }
  summary.shipped = ns.FlightTimesData ~= nil and ns.FlightTimesData[ns.Client.Flavor()] ~= nil
  return summary
end)

-- 360: Layout des Hauptfensters: Zeilen des Modells, Maße und je sichtbarem Text die gemessene Breite gegen die
-- Fensterbreite (abgeschnitten = IsTruncated, wo es das gibt); Schrift der Rolle mit Kontur
local function fontStringState(fontString)
  return { text = plain(method(fontString, "GetText")), width = method(fontString, "GetStringWidth"),
    truncated = method(fontString, "IsTruncated"), font = { method(fontString, "GetFont") } }
end

check("360.window.layout", function()
  local elements, model = ns.TimerWindow.Elements(), ns.TimerWindow.Model()
  local texts = {}
  for _, fontString in ipairs({ elements.time, elements.big, elements.sub }) do
    if method(fontString, "IsShown") then texts[#texts + 1] = fontStringState(fontString) end
  end
  for _, row in ipairs(elements.rows) do
    if method(row.value, "IsShown") then
      texts[#texts + 1] = { label = fontStringState(row.label), value = fontStringState(row.value) }
    end
  end
  for _, field in ipairs(elements.fields) do
    if method(field, "IsShown") then texts[#texts + 1] = fontStringState(field) end
  end
  local rows = {}
  for index, row in ipairs(model.rows) do rows[index] = row.key end
  return { layout = ns.TimerWindow.ActiveLayout(), setting = ns.db.windowLayout, rows = rows,
    order = ns.db.rowOrder, chosen = ns.db.compactRows, frame = frameState(_G.LevelTimerFrame),
    renders = ns.TimerWindow.RenderCount(), texts = chunked(texts),
    outlined = { method(_G[ns.Theme.Font("small", true)], "GetFont") } }
end)

-- XP-Tooltip (Wunsch zu 360): Zeilen wie beim Überfahren des Balkens und die Rohwerte dahinter
check("360.xpTooltip", function()
  return { content = ns.XpTooltip.Build(), xp = call("UnitXP", "player"), xpMax = call("UnitXPMax", "player"),
    rested = call("GetXPExhaustion"), questReady = ns.QuestLogXp.Get() }
end)

-- 362: Sichtbarkeitsregeln: Einstellung, Zustand der Regeln (Kampf, Instanz, Leveln) und was die Rahmen zeigen
check("362.visibility", function()
  return { window = ns.db.windowVisibility, splitList = ns.db.splitListVisibility, fade = ns.db.fadeAlpha,
    combat = call("UnitAffectingCombat", "player"), lockdown = call("InCombatLockdown"),
    instance = { call("IsInInstance") }, leveling = ns.Experience.IsLeveling(),
    mouseOver = method(_G.LevelTimerFrame, "IsMouseOver"),
    main = frameState(_G.LevelTimerFrame), splits = frameState(_G.LevelTimerSplits) }
end)
