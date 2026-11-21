-- Prüfungen und Ereignis-Proben für die offenen Punkte in ManualToCheck.md: was dort sonst ein Mensch im Spiel
-- ablesen müsste (Werte, Zustände, Einstellungen, Entscheidungen der Module), steht nach /lt debug check bzw. mit
-- laufendem /lt debug log im Debug-Log. Die Entscheidungen selbst schreiben die Module mit ns.Debug, Chatzeilen
-- (ns.Print) stehen als Bereich "print" darin. Lädt nach allen Modulen; die Prüfungen lesen nur, ändern nichts und
-- rufen keine geschützten Funktionen.
-- Namen: "<Roadmap>.<Bereich>.<Was>" (Nummer = Roadmap-Punkt), allgemeine ohne Nummer. ManualToCheck.md nennt je
-- Punkt die Namen, die ihn beantworten.
local _, X = ...
local ns = X.LT  -- Namespace von Level Time (LevelTimerAPI); ohne Level Time gibt es keinen Debug-Teil
if not ns then return end
local DebugLog = X.DebugLog
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

-- CVar-Änderungen fremder Hand (Roadmap 397): eigene stehen schon als ns.Debug("comfort", "cvar ...") im Log,
-- dieselbe CVar mit demselben Wert innerhalb von CVAR_REPEAT_SECONDS nur einmal
local CVAR_REPEAT_SECONDS = 5
local lastCVar = {}  -- [Name] = { value, at }

local function foreignCVarChange(name, value)
  if ns.CVars.IsWriting() then return false end
  if type(name) ~= "string" or ns.IsSecret(name) or ns.IsSecret(value) then return true end
  local now, last = GetTime(), lastCVar[name]
  if last and last.value == value and now - last.at < CVAR_REPEAT_SECONDS then return false end
  if last then
    last.value, last.at = value, now
  else
    lastCVar[name] = { value = value, at = now }
  end
  return true
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
  { event = "CVAR_UPDATE", filter = foreignCVarChange },
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
  local names = {}
  for _, suffix in ipairs({ "Frame", "Alert", "Notice", "Camp", "Food", "Flight", "Splits", "LevelUp", "QuestItemBar",
    "Recap", "MinimapButton", "MapCoordinates", "Emergency", "DeathMap", "Options", "History",
    "ObsSignal", "SpellHistory", "TargetRange", "TargetThreat" }) do
    names[#names + 1] = ns.GlobalName(suffix)
  end
  return framesByName(names)
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
  "threatShowNumeric", "countdownForCooldowns",
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
  local function count(text)
    local lines = 0
    for _ in text:gmatch("[^\n]+") do lines = lines + 1 end
    return lines
  end
  return { lines = count(ns.L.HELP), allLines = count(ns.L.HELP_ALL),
    introShown = LevelTimerStatsDB and LevelTimerStatsDB.introShown }
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

-- 268: Kandidaten für den Quest-Item-Knopf (mit Zone je Quest und Ort des Spielers), Wahl, Zielname
check("268.questItem.pick", function()
  local pick = ns.QuestItem.Pick()
  local candidates = ns.QuestItem.Candidates()
  for _, candidate in ipairs(candidates) do
    local inZone, signals = ns.QuestItem.ZoneOf(candidate.questID)
    candidate.inZone, candidate.zoneSignals = inZone, signals
    candidate.questMap = ns.QuestLog.QuestMap(candidate.questID)
  end
  local here = ns.QuestItem.Here()
  local names = {}
  for name in pairs(here.names) do names[#names + 1] = name end
  table.sort(names)
  return { candidates = candidates, pick = pick and { itemId = pick.itemId, questID = pick.questID },
    zoneOnly = ns.db.questButtonsZoneOnly, here = { mapID = here.mapID, zone = here.zone, names = names },
    targets = ns.QuestItem.TargetNames(), canTarget = ns.QuestItem.CanTarget(),
    buttons = framesByName({ ns.GlobalName("QuestItemButton"), ns.GlobalName("QuestTargetButton") }) }
end)

-- 268: benutzbare Taschengegenstände mit den Rohfeldern von C_Container.GetContainerItemQuestInfo (laut Doku
-- isQuestItem, questID, isActive in allen Zweigen; ob Forever questID/isActive für Quest-Gegenstände füllt, ist offen)
-- und den Taschen-Kandidaten des Quest-Item-Knopfs mit ihrer Quelle
check("268.questItem.bagItems", function()
  local bagCandidates = {}
  for _, candidate in ipairs(ns.QuestItem.Candidates()) do
    if candidate.source ~= "special" then
      bagCandidates[#bagCandidates + 1] = { questID = candidate.questID, itemId = candidate.itemId,
        source = candidate.source }
    end
  end
  return { api = api("C_Container.GetContainerItemQuestInfo") ~= nil,
    itemSpell = api("C_Item.GetItemSpell") ~= nil or api("GetItemSpell") ~= nil,
    usable = chunked(ns.QuestBagItems.Inspect()), candidates = bagCandidates,
    startItems = ns.character.questStartItems or false }
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
    wheel = method(_G.Minimap, "IsMouseWheelEnabled"),
    buttonBar = ns.db.minimapButtonBar,
    collectedButtons = ns.MinimapBar and #ns.MinimapBar.Collected() or 0,
    barExpanded = ns.MinimapBar and ns.MinimapBar.IsExpanded() or false }
end)

-- 451: Minimap-Knopfleiste, Zustand je gesammeltem Knopf (Klickbarkeit, Deckkraft, Ebenen der Unterframes)
check("451.minimapBar.buttons", function()
  local bar = ns.MinimapBar and ns.MinimapBar.BarFrame()
  local buttons = {}
  for _, button in ipairs(ns.MinimapBar and ns.MinimapBar.Collected() or {}) do
    local children = {}
    local ok, list = pcall(function() return { button:GetChildren() } end)
    for _, sub in ipairs(ok and list or {}) do
      children[#children + 1] = { name = frameName(sub), level = method(sub, "GetFrameLevel"),
        strata = method(sub, "GetFrameStrata"), mouse = method(sub, "IsMouseEnabled") }
    end
    local state = frameState(button)
    state.name = frameName(button)
    state.objectType = method(button, "GetObjectType")
    state.effectiveAlpha = method(button, "GetEffectiveAlpha")
    state.mouse = method(button, "IsMouseEnabled")
    state.mouseClick = method(button, "IsMouseClickEnabled")
    state.enabled = method(button, "IsEnabled")
    state.strata = method(button, "GetFrameStrata")
    state.level = method(button, "GetFrameLevel")
    state.parent = frameName(method(button, "GetParent"))
    state.libDBIcon = type(state.name) == "string" and state.name:find("^LibDBIcon10_") ~= nil
    state.fadeOutPlaying = type(button.fadeOut) == "table" and method(button.fadeOut, "IsPlaying") or nil
    state.children = children
    buttons[#buttons + 1] = state
  end
  return { bar = bar and { level = method(bar, "GetFrameLevel"), strata = method(bar, "GetFrameStrata"),
    shown = method(bar, "IsShown"), mouse = method(bar, "IsMouseEnabled") }, buttons = buttons }
end)

-- 481: Ebenen und Anker der gesammelten Knöpfe (feste Ebene wie LibDBIcon, Zusatzanker an der Minimap)
check("481.minimapBar.layers", function()
  local bar = ns.MinimapBar and ns.MinimapBar.BarFrame()
  local buttons = {}
  for _, button in ipairs(ns.MinimapBar and ns.MinimapBar.Collected() or {}) do
    local points = {}
    for i = 1, method(button, "GetNumPoints") or 0 do
      local ok, point, relativeTo = pcall(button.GetPoint, button, i)
      points[#points + 1] = ok and { point, frameName(relativeTo) } or "error"
    end
    buttons[#buttons + 1] = {
      name = frameName(button), level = method(button, "GetFrameLevel"), strata = method(button, "GetFrameStrata"),
      fixedLevel = method(button, "HasFixedFrameLevel"), fixedStrata = method(button, "HasFixedFrameStrata"),
      aboveBar = bar ~= nil and (method(button, "GetFrameLevel") or 0) > (method(bar, "GetFrameLevel") or 0),
      parentIsBar = bar ~= nil and method(button, "GetParent") == bar, points = points,
      dragScript = method(button, "GetScript", "OnDragStart") ~= nil,
    }
  end
  return { barLevel = bar and method(bar, "GetFrameLevel"), barStrata = bar and method(bar, "GetFrameStrata"),
    buttons = buttons }
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

-- 459: Weltposition der Spielerposition über C_Map.GetWorldPosFromMapPos (Kontinent, x, y) gegen UnitPosition
-- (liefert y, x, Kontinent): zeigt, in welcher Achsen-Reihenfolge der Client die Weltposition liefert
local function worldPositionProbe(position)
  if not position then return { position = false } end
  local probe = { mapID = position.mapID, mapX = position.x, mapY = position.y,
    api = type(C_Map and C_Map.GetWorldPosFromMapPos), vector = type(_G.CreateVector2D) }
  if C_Map and C_Map.GetWorldPosFromMapPos and _G.CreateVector2D then
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, position.mapID,
      _G.CreateVector2D(position.x, position.y))
    probe.ok, probe.continent = ok, ok and continent or tostring(continent)
    if ok and world and world.GetXY then probe.worldX, probe.worldY = world:GetXY() end
  end
  probe.data = { ns.MapCoords.MapToWorldData(position.mapID, position.x, position.y) } -- 461: erzeugte Daten zum Vergleich
  if _G.UnitPosition then probe.unitPosition = { pcall(_G.UnitPosition, "player") } end
  return probe
end

-- 440: Schiffe und Zeppeline: Strecken, Phasen, Anleger, Position und Zustand der Fahrt-Erkennung
check("440.transport.state", function()
  local data = ns.Transports.Data()
  local position = ns.Transports.PlayerPosition()
  local routes, docks = {}, {}
  for key, route in pairs(data.routes) do
    routes[key] = { kind = route.kind, syncAt = route.syncAt, period = route.period, rideTime = route.rideTime,
      samples = #route.samples, sharedAt = route.sharedAt, next = ns.Transports.SecondsToDeparture(route) }
  end
  for name, dock in pairs(data.docks) do docks[name] = { mapID = dock.mapID, x = dock.x, y = dock.y, npcIds = dock.npcIds } end
  local ride = ns.Transports.Ride()
  return { available = ns.Transports.IsAvailable(), enabled = ns.Transports.IsEnabled(), now = ns.Transports.Now(),
    routes = routes, docks = docks, position = position, nearestDock = (ns.Transports.NearestDock(position)),
    ride = ride and { from = ride.from.name, leftAt = ride.leftAt, moving = ride.moving, still = ride.still } or nil,
    moving = _G.IsPlayerMoving and _G.IsPlayerMoving() or nil,
    api = { getServerTime = type(_G.GetServerTime), isPlayerMoving = type(_G.IsPlayerMoving),
      namePlate = type(C_NamePlate and C_NamePlate.GetNamePlateForUnit), mapInfo = type(C_Map and C_Map.GetMapInfo) },
    unitFrame = Probe.unitInfo("target"), targetTitle = ns.Transports.UnitTitle("target"),
    targetIsMaster = ns.Transports.IsMasterTitle(ns.Transports.UnitTitle("target")), paths = ns.TransportPaths.Summary(),
    worldPosition = worldPositionProbe(position) }
end)

-- 442/LT-388: Grafikdetails und Beyond Ultra (WoW Forever): je CVar aktueller Wert, Client-Standard und gemerktes
-- Original; exists = false heißt, der Client kennt die CVar nicht (weatherDensity, rippleDetail, sunshafts, HDR*?).
-- paused = Pause in Instanzen greift gerade (Einstellung an und in einer Instanz).
check("LT388.graphics.cvars", function()
  local cvars, missing = {}, {}
  for _, name in ipairs(ns.ForeverGraphics.CVarNames()) do
    local default = Probe.call("C_CVar.GetCVarDefault", name)
    cvars[name] = { value = Probe.call("C_CVar.GetCVar", name), default = default, exists = default ~= nil,
      overridden = ns.CVars.IsOverridden(name) }
    if default == nil then missing[#missing + 1] = name end
  end
  local pause = ns.db[ns.ForeverGraphics.PAUSE.setting]
  return { available = ns.ForeverGraphics.IsAvailable(), enabled = ns.db.foreverGraphics, hdr = ns.db.graphicsHdr,
    paused = pause == true and IsInInstance() == true, missing = table.concat(missing, ","), cvars = cvars }
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

-- 371: Blizzard-Oberfläche ausblenden: je Eintrag gefunden?, Frame-Name und Zustand, ausgeblendet (Einstellung) und von
-- uns angewendet, geschützt; dazu die Minimap (ob die Karte selbst Alpha 0 des Rahmens folgt, sieht man nur im Spiel)
check("371.blizzardFrames", function()
  local BlizzardHide = ns.BlizzardHide
  local entries = {}
  for _, entry in ipairs(BlizzardHide.ENTRIES) do
    local frames = BlizzardHide.Frames(entry)
    local first = frames[1]
    local state = first and frameState(first) or {}
    state.id, state.supported, state.found = entry.id, BlizzardHide.IsSupported(entry), #frames
    state.name, state.mouse = first and frameName(first), first and method(first, "IsMouseEnabled")
    state.protected = first and method(first, "IsProtected")
    state.hidden, state.applied = BlizzardHide.IsHidden(entry.id), BlizzardHide.IsApplied(entry.id)
    state.setting, state.markedProtected = entry.setting, entry.protected == true
    table.insert(entries, state)
  end
  return { pending = BlizzardHide.IsPending(), combat = call("InCombatLockdown"),
    editOverlays = ns.db.editBlizzardFrames, minimapAlpha = method(_G.Minimap, "GetAlpha"),
    minimapEffectiveAlpha = method(_G.Minimap, "GetEffectiveAlpha"), entries = chunked(entries) }
end)

-- 403: Eintrag im Blizzard-Einstellungsmenü: welche Schnittstelle der Client hat, ob die Kategorie steht (ID), Strata
-- von SettingsPanel gegen unser Fenster (unser DIALOG muss darüber liegen)
check("403.blizzardSettings", function()
  local category = ns.BlizzardSettings.category
  local settings = _G.Settings
  local hasSettings = type(settings) == "table"
  return {
    settings = hasSettings,
    canvasApi = hasSettings and type(settings.RegisterCanvasLayoutCategory) == "function",
    legacyApi = type(_G.InterfaceOptions_AddCategory) == "function",
    registered = category ~= nil,
    categoryId = type(category) == "table" and method(category, "GetID") or nil,
    canvasShown = method(ns.BlizzardSettings.canvas, "IsVisible"),
    panelStrata = method(_G.SettingsPanel, "GetFrameStrata"),
    optionsStrata = method(_G.LevelTimerOptions, "GetFrameStrata"),
  }
end)

-- 361: Lesbarkeit und Balken: Untergrenze, kleinste zulässige Größe, effektive kleinste Schrift je Anzeige, gewählte
-- Balkentextur samt Pfad und ob die eigene TGA lädt (GetTexture nach SetTexture), Zahl der LibSharedMedia-Balken
check("361.readability", function()
  local Theme = ns.Theme
  local _, small = method(_G[Theme.Font("small")], "GetFont")
  local displays = {}
  for _, reg in ipairs(ns.Frames.All()) do
    local scale = method(reg.frame, "GetEffectiveScale")
    table.insert(displays, { id = reg.id, scale = ns.Frames.GetScale(reg.id),
      effectiveSmall = small and scale and math.floor(small * scale * 10 + 0.5) / 10 })
  end
  local fill = ns.TimerWindow.Elements().xpBar.fill
  return { minFont = ns.db.themeMinFontSize, minScale = Theme.MinReadableScale(), small = small,
    displays = chunked(displays), bar = ns.db.themeBarTexture, barPath = Theme.BarTexturePath(ns.db.themeBarTexture),
    xpFillTexture = method(fill, "GetTexture"), barChoices = #Theme.BarTextureChoices(), valueColors = ns.db.valueColors,
    averageLevelXpRate = ns.Forecast.AverageLevelXpRate() }
end)

-- 430: Schlafsack-Timer (WoW Forever). Prüfung: Item in der Tasche, Zauber des Items, "Gut erholt" mit allen Feldern
-- (stapelt er über applications?), Zustand des Timers. Proben, solange ein Startsignal frisch ist oder der Timer
-- läuft: gewirkte Zauber (welcher ist der Schlafsack?) und jede Buff-Änderung samt Spell-IDs aller Buffs (hat das
-- Schlafen eine eigene Aura?). Das Emote selbst schreibt SleepTimer per ns.Debug ("sleep").
local function wellRestedInfo()
  local aura = ns.Auras.FindBySpellId(ns.SleepTimer.WELL_RESTED_SPELL_ID)
  if not aura then return aura end  -- false = keiner, nil = nicht lesbar
  return { name = aura.name, applications = aura.applications, charges = aura.charges,
    maxCharges = aura.maxCharges, duration = aura.duration, expirationTime = aura.expirationTime,
    remaining = ns.Auras.RemainingSeconds(aura), now = GetTime() }
end

local function buffSpellIds()
  local ids = {}
  ns.Auras.ForEachBuff(function(aura)
    ids[#ids + 1] = aura.spellId
  end)
  return table.concat(ids, ",")
end

check("430.sleep.state", function()
  local SleepTimer = ns.SleepTimer
  local state = SleepTimer.State()
  return {
    available = SleepTimer.IsAvailable(), setting = ns.db.sleepTimer, ownsBag = SleepTimer.OwnsBag(),
    bagCount = ns.BuffReminder.SleepingBagCount(), itemSpell = call("C_Item.GetItemSpell", SleepTimer.ITEM_ID),
    itemSpellId = SleepTimer.ItemSpellId(), wellRested = wellRestedInfo(), stacks = SleepTimer.Stacks(),
    performEmote = api("C_ChatInfo.PerformEmote") ~= nil, doEmote = api("DoEmote") ~= nil,
    jumpHook = api("JumpOrAscendStart") ~= nil, sitHook = api("SitStandOrDescendStart") ~= nil,
    moving = call("IsPlayerMoving"),
    timer = state and { phase = state.phase, signal = state.signal, stacks = state.stacks,
      duration = state.duration, elapsed = GetTime() - state.startedAt } or false,
    rolledOut = SleepTimer.RolledOut(),
    shown = ns.SleepDisplay.ShownKind(),
  }
end)

local sleepProbes = ns.NewEventGroup()
local sleepAuraVersion
sleepProbes.Add("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spellId)
  if not ns.SleepTimer.Probing() then return end
  write({ area = "event", event = "UNIT_SPELLCAST_SUCCEEDED", name = "430.sleep.cast",
    extra = { spellId = spellId, itemSpellId = ns.SleepTimer.ItemSpellId() } })
end)
sleepProbes.Add("UNIT_AURA", "player", function()
  if not ns.SleepTimer.Probing() then return end
  ns.Auras.Snapshot()
  local version = ns.Auras.Version()
  if version == sleepAuraVersion then return end
  sleepAuraVersion = version
  write({ area = "event", event = "UNIT_AURA", name = "430.sleep.auras",
    extra = { wellRested = wellRestedInfo(), buffs = buffSpellIds() } })
end)

if ns.SleepTimer.IsAvailable() then
  DebugLog.OnStateChanged(function(enabled) sleepProbes.SetActive(enabled) end)
end

-- 443: Bedrohungsanzeige (CVar, Blizzards TargetFrame-Anzeige, eigenes Abzeichen LevelTimerTargetThreat, Zielwerte)
check("443.threat", function()
  local status, pct, tanking, value = ns.ThreatDisplay.TargetThreat()
  local badge = ns.ThreatDisplay.BadgeFrame()
  local modern = _G.TargetFrame and _G.TargetFrame.threatNumericIndicator
  local classic = _G.TargetFrameNumericalThreat
  return {
    setting = ns.db.threatShowNumeric,
    cvar = call("C_CVar.GetCVar", "threatShowNumeric") or call("GetCVar", "threatShowNumeric"),
    targetStatus = status,
    targetPercent = pct,
    targetTanking = tanking,
    targetValue = value,
    badgeShown = badge and badge:IsShown() or false,
    badgeText = ns.ThreatDisplay.BadgeText(),
    glowShown = ns.ThreatDisplay.IsGlowShown(),
    blizzardModernShown = modern and modern.IsShown and modern:IsShown() or false,
    blizzardClassicShown = classic and classic.IsShown and classic:IsShown() or false,
  }
end)

-- 445-449: Komfort-Helfer (DialogKey, Abklingzeit-Zahlen, Ziel-Reichweite, Instanz-Reset-Ansage, Hardcore-Schutz)
check("445.qol", function()
  return {
    dialogKeys = ns.db.dialogKeys,
    dialogOpen = ns.DialogKey and ns.DialogKey.GetDialogOpen() or nil,
    cooldownNumbers = ns.db.cooldownNumbers,
    cooldownCVar = call("C_CVar.GetCVar", "countdownForCooldowns") or call("GetCVar", "countdownForCooldowns"),
    showTargetRange = ns.db.showTargetRange,
    targetRange = ns.TargetRange and ns.TargetRange.Estimate("target") or nil,
    announceInstanceReset = ns.db.announceInstanceReset,
    warnWildernessLogout = ns.db.warnWildernessLogout,
    warnFalling = ns.db.warnFalling,
  }
end)

-- 450: Level Time Post / Postal Light (Mail.lua)
check("450.mail", function()
  return {
    setting = ns.db.mailAssist,
    isOpening = ns.Mail and ns.Mail.IsOpening and ns.Mail.IsOpening() or false,
    openAllButtonShown = _G.LevelTimerMailOpenAllButton and _G.LevelTimerMailOpenAllButton:IsShown() or false,
    altButtonShown = _G.LevelTimerMailAltButton and _G.LevelTimerMailAltButton:IsShown() or false,
    -- 480: UnitName-Rückgaben und gespeicherter Nachname (WoW Forever: Vor- und Nachname)
    unitName = { UnitName("player") },
    surname = ns.character and ns.character.surname,
    -- Empfänger, die der Twink-Knopf der Reihe nach einträgt (ohne Sichtprüfung am Briefkasten)
    altRecipients = (function()
      local names = {}
      for _, alt in ipairs(ns.Mail and ns.Mail.GetKnownAlts() or {}) do names[#names + 1] = alt.name end
      return names
    end)(),
  }
end)

-- 453: Gruppen-Questabgleich (PartyQuestSync.lua)
check("453.partyQuestSync", function()
  local sync = ns.PartyQuestSync
  return {
    setting = ns.db.partyQuestSync,
    peers = sync and sync.GetPeerCount and sync.GetPeerCount() or 0,
    queued = sync and sync.GetQueueLength and sync.GetQueueLength() or 0,
  }
end)

-- Bleibt die GUID nach Fraktionswechsel/Charakter-Umzug gleich? Sonst hält Database.lua den Charakter für neu
-- erstellt und seine Daten beginnen neu (Prüfung nach so einem Wechsel)
check("character.guid", function()
  local guid = UnitGUID("player")
  if ns.IsSecret(guid) then guid = "<secret>" end
  local stored = ns.character and ns.character.guid
  return { current = guid, stored = stored, same = stored == guid }
end)

-- 452: Liefert das Kampflog eigene Schläge (SWING_*)? Sonst nutzt der Schwungbalken den Ersatztakt ab Kampfbeginn
check("452.swing.combatlog", function()
  local status = ns.SwingTimer.Status()
  local mainSpeed, offSpeed  -- "A and f()" liefert nur den ersten Rückgabewert
  if UnitAttackSpeed then mainSpeed, offSpeed = UnitAttackSpeed("player") end
  local rangedSpeed = UnitRangedDamage and UnitRangedDamage("player")
  local function shown(value) return ns.IsSecret(value) and "<secret>" or value end
  return { available = ns.SwingTimer.IsAvailable(), enabled = ns.db.swingTimer,
    combatLogApi = ns.Client.CombatLogEventInfo ~= nil, swingSource = status.swingSource,
    autoAttacking = status.autoAttacking, mainSpeed = shown(mainSpeed), offSpeed = shown(offSpeed),
    rangedSpeed = shown(rangedSpeed) }
end)

-- LT-267: Kampflog-Abruf in WoW Forever 1.60.1 laut Doku weg (forever CombatLogDocumentation.lua); feuert
-- COMBAT_LOG_EVENT_UNFILTERED trotzdem, ist das Kampflog gesperrt, und welche Quelle nutzt jede Funktion?
-- Ohne Abruf ist schon das Anmelden des Events verboten (Forever: ADDON_ACTION_FORBIDDEN, BugGrabber 2026-11-16).
local combatLogEvents = { count = ns.Client.CombatLogEventInfo and 0 or "forbidden" }
if ns.Client.CombatLogEventInfo then
  X.On("COMBAT_LOG_EVENT_UNFILTERED", function() combatLogEvents.count = combatLogEvents.count + 1 end)
end
check("LT267.combatlog.api", function()
  local restricted
  if C_CombatLog and C_CombatLog.IsCombatLogRestricted then
    local ok, value = pcall(C_CombatLog.IsCombatLogRestricted)
    restricted = not ok and "error" or ns.IsSecret(value) and "<secret>" or value
  end
  return { cCombatLogGetCurrentEventInfo = (C_CombatLog and C_CombatLog.GetCurrentEventInfo) ~= nil,
    globalCombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo ~= nil, restricted = restricted,
    cleuEvents = combatLogEvents.count,
    deathCause = ns.Client.CombatLogEventInfo and "combatlog" or ns.DeathRecap.IsAvailable() and "deathrecap" or "none",
    bossDeaths = ns.InstanceBosses.DeathSource(),
    swing = ns.SwingTimer.Status().swingSource or (C_SwingTimer and "player_swing pending" or "fallback"),
    extractorSpells = X.CombatSpells.Status().api }
end)

-- 486: XP und Geld je Quest im Log (Lib/QuestLog.lua): beachtet GetQuestLogRewardMoney(questID) die ID (Era)?
-- Verschiedene Beträge je Quest = ja; überall der Betrag der zuletzt angesehenen Quest (selectedMoney) = nein
check("486.questRewards", function()
  local quests = {}
  for index, entry in ipairs(ns.QuestLog.Entries()) do
    if index > RECENT_ENTRIES then break end
    table.insert(quests, { questID = entry.questID, xp = ns.QuestLog.RewardXp(entry.questID),
      money = ns.QuestLog.RewardMoney(entry.questID) })
  end
  return {
    setting = ns.db.questLogRewards,
    quests = quests,
    selectedMoney = call("GetQuestLogRewardMoney"),
    classicHook = type(QuestLogTitleButton_OnEnter) == "function",
    mainlineHook = type(QuestLogQuests_Update) == "function",
  }
end)

-- 497: Dungeon-Eingänge (DungeonEntrances.lua, WoW Forever): kennt der Client den Atlas "Dungeon", wie viele
-- Eingänge liegen auf der offenen bzw. aktuellen Zonenkarte, offene Dungeonquests je Instanz dort
check("497.dungeonEntrances", function()
  local mapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
  local entrances = {}
  for _, point in ipairs(type(mapID) == "number" and ns.DungeonEntrances.PointsOn(mapID) or {}) do
    for _, instance in ipairs(point.mapIDs) do
      table.insert(entrances, { mapID = instance, x = point.x, y = point.y,
        openQuests = #ns.DungeonQuests.OwnQuests(instance) })
    end
  end
  return {
    setting = ns.db.dungeonEntrances,
    available = ns.DungeonEntrances.IsAvailable(),
    atlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Dungeon") ~= nil,
    mapID = mapID,
    entrances = entrances,
  }
end)

-- 488: Reagenzien (Reagents.lua): Name und Bestand je Item der eigenen Klasse und welche Zauber bekannt sind
-- (stimmen die Classic-IDs in WoW Forever?)
check("488.reagents", function()
  local items = {}
  for _, need in ipairs(ns.Reagents.CLASSES[select(2, UnitClass("player"))] or {}) do
    for _, option in ipairs(need) do
      local known = {}
      for _, spell in ipairs(option.spells) do known[#known + 1] = call("IsPlayerSpell", spell) end
      table.insert(items, { item = option.item, name = ns.Items.GetName(option.item),
        count = call("C_Item.GetItemCount", option.item), known = known })
    end
  end
  return { setting = ns.db.warnReagents, available = ns.Reagents.IsAvailable(), items = items,
    low = ns.Reagents.LowText() }
end)

---------------------------------------------------------------------------
-- Prüfungen einzelner Module (lagen früher in den Modulen selbst; lesen nur deren öffentliche Funktionen)
---------------------------------------------------------------------------
local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

-- Erster Rückgabewert von api(path)(...), geschützt; Fehler, geheime oder fehlende Werte = nil
local function read(path, ...)
  local fn = api(path)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  return ok and readable(value) or nil
end

local function readXY(vector)
  if type(vector) ~= "table" or ns.IsSecret(vector) or not vector.GetXY then return nil end
  local x, y = vector:GetXY()
  return readable(x), readable(y)
end

-- /lt debug check (als Geist): Karte, Positionen, Blickrichtung und Ergebnis des Leichenpfeils
check("deaths.corpseArrow", function()
  local CorpseArrow = ns.CorpseArrow
  local mapID = read("C_Map.GetBestMapForUnit", "player")
  local info = { ghost = CorpseArrow.IsGhost(), mapID = mapID,
    hasWorldPos = api("C_Map.GetWorldPosFromMapPos") ~= nil, hasFacing = GetPlayerFacing ~= nil }
  if type(mapID) == "number" and api("C_DeathInfo.GetCorpseMapPosition") then
    info.corpseX, info.corpseY = readXY(C_DeathInfo.GetCorpseMapPosition(mapID))
    info.world = { ns.MapCoords.MapToWorld(mapID, info.corpseX or 0, info.corpseY or 0) }
  end
  info.facing = GetPlayerFacing and readable(GetPlayerFacing())
  info.rotation, info.distance = CorpseArrow.Direction()
  return info
end)

-- /lt debug check: welche Items und Zauber der Notfall-Liste der Client kennt (Namen in der Client-Sprache)
check("emergency.actions", function()
  local items, spells = {}, {}
  for _, itemId in ipairs(ns.Emergency.ITEMS) do
    items[#items + 1] = { id = itemId, name = read("C_Item.GetItemInfo", itemId) }
  end
  for _, spellId in ipairs(ns.Emergency.SPELLS) do
    spells[#spells + 1] = { id = spellId, name = read("C_Spell.GetSpellName", spellId) or read("GetSpellInfo", spellId) }
  end
  return { items = items, spells = spells }
end)

-- /lt debug check (vor einem Erz, Kraut oder einer Leiche stehen): was der Client über das Ziel verrät, roh
-- (Datei-ID, Pfad oder Atlas des Zeigers sind nicht dokumentiert) und eingeordnet; dazu die beteiligten CVars
check("lootSparkles.target", function()
  local LootTarget = ns.LootTarget
  local unit = LootTarget.UNIT
  local info = { available = LootTarget.IsAvailable(), cvars = {} }
  info.style = ns.LootSparkle and ns.LootSparkle.CurrentStyle and ns.LootSparkle.CurrentStyle() or nil
  for _, name in ipairs({ "SoftTargetInteract", "SoftTargetIconGameObject", "SoftTargetInteractRange",
    "SoftTargetInteractArc", "SoftTargetInteractOnlyInRange", "SoftTargetNameplateInteract",
    "outlineModeShowLootEffectWhenDisabled", "graphicsOutlineMode" }) do
    info.cvars[name] = ns.CVars.Get(name) or "<missing>"
  end
  if not info.available then return info end
  info.exists, info.isObject = read("UnitExists", unit), read("UnitIsGameObject", unit)
  info.name, info.dead = read("UnitName", unit), read("UnitIsDead", unit)
  info.inRange = read("UnitIsInInteractRange", unit)
  info.related = read("C_QuestLog.UnitIsRelatedToActiveQuest", unit)
  info.cursorKind, info.cursorBlocked, info.cursorTexture, info.cursorAtlas = LootTarget.ReadCursor(unit)
  info.kind, info.blocked = LootTarget.Classify(unit)
  info.plate = read("C_NamePlate.GetNamePlateForUnit", unit) ~= nil
  return info
end)

-- /lt debug check (als Kürschner vor einer leergeplünderten, häutbaren Leiche): zeigt der Tooltip des
-- Interaktionsziels die Kürschner-Zeile, was meldet CanLootUnit danach, ist Kürschnern erkannt?
check("479.lootSparkles.skinning", function()
  local LootTarget = ns.LootTarget
  local unit = LootTarget.UNIT
  local info = { dead = read("UnitIsDead", unit), name = read("UnitName", unit),
    lines = LootTarget.TooltipTexts(unit), skinningTrained = LootTarget.IsGatheringTrained(LootTarget.SKIN),
    skinnableText = UNIT_SKINNABLE_LEATHER }
  local guid = read("UnitGUID", unit)
  if guid and type(CanLootUnit) == "function" then
    local ok, hasLoot, canLoot = pcall(CanLootUnit, guid)
    info.hasLoot, info.canLoot = ok and readable(hasLoot), ok and readable(canLoot)
  end
  info.kind = LootTarget.Classify(unit)
  return info
end)

-- 493: Woran erkennt man beim Betreten den Flügel (Scharlachrotes Kloster, Düsterbruch: gleicher Name, gleiche Karten-ID)?
-- uiMapID und Zonentexte je Flügel; Rückfall wären Trash-Namen je Flügel: sind Namen von Namensplaketten und Ziel in
-- Forever-Instanzen lesbar (secret = nein)? Je Flügel direkt nach dem Betreten mit Gegnern in Sicht prüfen
check("493.instances.wing", function()
  local function visible(value) return ns.IsSecret(value) and "secret" or value end
  local function callVisible(fn, ...) return fn and visible(fn(...)) end
  local function nameOf(unit)
    local exists = UnitExists(unit)
    if ns.IsSecret(exists) or not exists then return nil end
    return visible(UnitName(unit))
  end
  local plates = {}
  for unit in pairs(ns.NamePlates.Active()) do plates[#plates + 1] = nameOf(unit) end
  local _, _, difficultyID, _, _, _, _, mapID = GetInstanceInfo()
  return {
    plates = plates, target = nameOf("target"), mouseover = nameOf("mouseover"),
    instance = ns.InstanceCopy.GetInsideName(), mapID = visible(mapID),
    difficultyID = visible(difficultyID),
    uiMapID = C_Map and callVisible(C_Map.GetBestMapForUnit, "player"),
    zone = callVisible(GetRealZoneText), subZone = callVisible(GetSubZoneText), minimapZone = callVisible(GetMinimapZoneText),
  }
end)

-- Offene Frage: kommen ENCOUNTER_END bzw. UNIT_DIED bei Dungeon-Bossen je Client, passen Liste und Namen?
check("483.bosses", function()
  local InstanceBosses = ns.InstanceBosses
  local run = ns.Instances.GetCurrentRun()
  local list = run and InstanceBosses.List(run.mapID, run.difficultyID)
  local names = {}
  for index, id in ipairs(list or {}) do names[index] = id .. "=" .. tostring(InstanceBosses.Name(id)) end
  return {
    data = ns.BossData and ns.BossData.build or false, locale = GetLocale(),
    run = run and { name = run.name, mapID = run.mapID, difficultyID = run.difficultyID, bosses = run.bosses,
      progress = InstanceBosses.ProgressText(run) },
    list = table.concat(names, ", "), last = InstanceBosses.LastEvent(),
    -- Tooltip der Historienzeile (484) als Text: Symbolpfad zeigt besiegt/lebt ohne Sichtprüfung
    tooltip = run and InstanceBosses.TooltipLines(run) or false,
  }
end)

-- /lt debug check (vor einem Questgegner mit Ziel): rohe Tooltipzeilen (Typ, Text, completed) und die Deutung
check("quests.unitTooltip", function()
  local QuestTooltip = ns.QuestTooltip
  local unit = "target"
  local info = { hasTooltipInfo = QuestTooltip.HasTooltipInfo(), name = readable(UnitName(unit)), lines = {} }
  if info.hasTooltipInfo then
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if ok and type(data) == "table" and type(data.lines) == "table" then
      for _, line in ipairs(data.lines) do
        table.insert(info.lines, { type = readable(line.type), text = readable(line.leftText),
          completed = readable(line.completed) })
      end
    end
  end
  QuestTooltip.Forget()
  info.parsed = QuestTooltip.Objectives(unit)
  info.progress = QuestTooltip.ProgressText(unit)
  return info
end)

-- /lt debug check: wie viele Quests, Ziele und Namen gelernt sind und was gerade offen ist
check("quests.learned", function()
  local quests, objectives, names = 0, 0, 0
  for _, learned in pairs(LevelTimerStatsDB and LevelTimerStatsDB.questMobs or {}) do
    quests = quests + 1
    for _, data in pairs(learned) do
      objectives = objectives + 1
      for _ in pairs(data.mobs) do names = names + 1 end
    end
  end
  return { quests = quests, objectives = objectives, mobNames = names, openMobs = ns.QuestMobs.OpenMobNames(),
    pending = ns.QuestMobs.PendingCount(),
    related = C_QuestLog ~= nil and C_QuestLog.UnitIsRelatedToActiveQuest ~= nil }
end)

-- /lt debug check (nach ein paar Zaubern): roher Untertext und gelesener Rang der letzten Zauber
check("487.spellHistory.rank", function()
  local getSubtext = api("C_Spell.GetSpellSubtext") or api("GetSpellSubtext")
  local list = {}
  for _, entry in ipairs(ns.SpellHistory.Recent()) do
    local ok, subtext = pcall(getSubtext, entry.spellID)
    table.insert(list, { spellID = entry.spellID, subtext = ok and readable(subtext) or nil, rank = entry.rank })
  end
  return { hasSubtext = type(getSubtext) == "function", spells = list }
end)

-- Gewählte Buffs bei eingeklappter Buffleiste (Roadmap 500): Einklapp-Zustand je Client, passende Buffs mit
-- Ladungen und Restzeit, und ob Blizzards Cooldown-Manager in diesem Client verfügbar ist
check("500.collapsedBuffs", function()
  local CollapsedBuffs = ns.CollapsedBuffs
  local buffFrame = type(BuffFrame) == "table" and BuffFrame or nil
  local button = buffFrame and buffFrame.CollapseAndExpandButton
  local matches = {}
  local aurasReadable = ns.Auras.ForEachBuff(function(aura)
    if CollapsedBuffs.Matches(aura) then
      table.insert(matches, { name = readable(aura.name), spellId = readable(aura.spellId),
        applications = readable(aura.applications), remaining = ns.Auras.RemainingSeconds(aura) })
    end
  end)
  return {
    setting = ns.db.collapsedBuffs, list = ns.db.collapsedBuffsList, collapsed = CollapsedBuffs.IsBarCollapsed(),
    hasIsExpanded = buffFrame ~= nil and buffFrame.IsExpanded ~= nil,
    buttonEnabled = button and safe(button.IsEnabled, button) or false,
    consolidateBuffs = ns.CVars.Get("consolidateBuffs") or "<missing>",
    cooldownViewer = call("C_CooldownViewer.IsCooldownViewerAvailable"),
    aurasReadable = aurasReadable == true, matches = matches, shown = CollapsedBuffs.ShownCount(),
    -- LT-349 im Kampf: gibt Blizzard die Schilde einzeln frei? (true/false = lesbar, nil = geheim)
    restricted = ns.Auras.Restricted(), bySpellId = (function()
      local result = {}
      for _, spellId in ipairs({ 324, 408510, 52127, 974 }) do
        local aura = ns.Auras.PlayerAuraBySpellId(spellId)
        result[tostring(spellId)] = aura == nil and "secret" or (aura and "active" or "none")
      end
      return result
    end)(),
  }
end)

-- LT-10/LT-11 (/lt debug check, Maus über einem Dungeon-Gegner, in und außerhalb von Instanzen): ist die GUID lesbar
-- (sonst keine Mechanik-Zeilen), welche NPC-ID, wie viele Mechaniken kennt der Datensatz?
check("LT10.mechanics.mouseover", function()
  local unit = "mouseover"
  local guid = api("UnitGUID") and UnitGUID(unit)
  local npcID = ns.MechanicTips.NpcOf(unit)
  local mechanics = ns.MechanicTips.ForNpc(npcID)
  local _, instanceType = GetInstanceInfo()
  return { exists = read("UnitExists", unit), name = read("UnitName", unit), guidSecret = ns.IsSecret(guid),
    npcID = npcID, mechanics = mechanics and #mechanics or 0, available = ns.MechanicTips.IsAvailable(),
    instanceType = readable(instanceType) }
end)

-- LT-52 (/lt debug check nach ein paar Kämpfen in einem Dungeon): sind die Quell-GUIDs im Kampflog lesbar
-- (npcSources > 0) oder geheim (secretGuids), liefert es Zauber-IDs (nameKeys = Zauber ohne ID)?
-- Ohne Kampflog (Forever, unitCasts = true, LT-278) zählt es UNIT_SPELLCAST_* von Ziel/Namensplakette/Boss.
check("LT52.combatlog.guid", function()
  local result = X.CombatSpells.Status()
  result.forever = ns.Client.IsForever()
  result.lastGuid = plain(result.lastGuid)
  return result
end)

-- LT-279 (/lt debug check nach ein paar Kills in Forever): feuert PARTY_KILL, ist die GUID lesbar (secretGuids),
-- wie oft fehlt der Name (unnamed), kommt UNIT_DIED an? active = false: Client hat Kampflog, Zählung läuft dort anders.
check("LT279.kills.events", function() return X.Units.KillStatus() end)

-- LT-259/LT-260 (/lt debug check mit fokussierter Quest, draußen und in einer Instanz): Fokus, Kontextmenü-API,
-- Blickrichtung und Ergebnis des Questpfeils (rotation/distance nil = kein Pfeil)
check("LT259.questArrow.state", function()
  local info = { focus = ns.QuestFocus.Get(), hasModifyMenu = Menu ~= nil and Menu.ModifyMenu ~= nil,
    hasEraLogClick = QuestLogTitleButton_OnClick ~= nil, mapID = ns.MapDirection.PlayerMap(),
    facing = GetPlayerFacing and readable(GetPlayerFacing()) }
  info.rotation, info.distance = ns.QuestArrow.Direction()
  return info
end)

-- LT-254 (/lt debug check, am besten mit einem Charakter, der eine Reihe begonnen hat): kennt der Client die Quests
-- der Schlüssel- und Einstimmungsreihen (unknown = ohne Titel aus C_QuestLog.GetTitleForQuestID, nur Forever/Retail),
-- und stimmt der erkannte Stand (done)?
check("LT254.attunements", function()
  local result, titleOf = { forever = ns.Client.IsForever() }, C_QuestLog and C_QuestLog.GetTitleForQuestID
  for _, mapID in ipairs({ 229, 230, 289 }) do
    for _, attunement in ipairs(ns.Attunements.At(mapID)) do
      local unknown = {}
      for _, step in ipairs(attunement.steps) do
        if titleOf and not readable(titleOf(step.questID)) then unknown[#unknown + 1] = step.questID end
      end
      result[tostring(attunement.mapID)] = { steps = #attunement.steps, done = attunement.done,
        unknown = table.concat(unknown, ",") }
    end
  end
  return result
end)

-- LT-285 (/lt debug check, einmal nach einem Kampf außer Kampf): C_DamageMeter als Quelle für Gegner-Zauber (DamageTaken)
-- und Todesursache (Deaths), LT-286. Fehlende API = "absent"; geheime Werte werden als "secret" gemeldet.
local DAMAGE_METER_SAMPLE = 3   -- so viele Quellen/Zauber je Sitzung vollständig

-- Feld einer Tabelle als lesbarer Wert, "secret" oder "none"
local function fieldOrSecret(tbl, key)
  if type(tbl) ~= "table" then return "none" end
  local value = tbl[key]
  if ns.IsSecret(value) then return "secret" end
  return value == nil and "none" or value
end

local function damageMeterSession(fn, ...)
  local ok, value = pcall(fn, ...)
  if not ok then return nil, "error" end
  if ns.IsSecret(value) then return nil, "secret" end
  return type(value) == "table" and value or nil, value == nil and "nil" or "ok"
end

-- Die ersten Quellen einer DamageTaken-/Deaths-Sitzung: Feldwerte (oder "secret") und Zauberanzahl
local function damageMeterSources(sessionID, meterType, withSpells)
  local session, state = damageMeterSession(C_DamageMeter.GetCombatSessionFromID, sessionID, meterType)
  local out = { state = state }
  local sources = session and session.combatSources
  if type(sources) ~= "table" or ns.IsSecret(sources) then return out end
  out.sources = #sources
  out.sample = {}
  for index = 1, math.min(#sources, DAMAGE_METER_SAMPLE) do
    local source = sources[index]
    local entry = { name = fieldOrSecret(source, "name"), sourceGUID = fieldOrSecret(source, "sourceGUID"),
      sourceCreatureID = fieldOrSecret(source, "sourceCreatureID"), deathRecapID = fieldOrSecret(source, "deathRecapID"),
      deathTimeSeconds = fieldOrSecret(source, "deathTimeSeconds") }
    if withSpells and type(source) == "table" then
      local detail = damageMeterSession(C_DamageMeter.GetCombatSessionSourceFromID, sessionID, meterType,
        readable(source.sourceGUID), readable(source.sourceCreatureID))
      local spells = detail and detail.combatSpells
      if type(spells) == "table" and not ns.IsSecret(spells) then
        entry.spells = #spells
        entry.spell1 = spells[1] and { spellID = fieldOrSecret(spells[1], "spellID"),
          creatureName = fieldOrSecret(spells[1], "creatureName"), isDeadly = fieldOrSecret(spells[1], "isDeadly"),
          overkillAmount = fieldOrSecret(spells[1], "overkillAmount") } or "none"
      else entry.spells = "none" end
    end
    out.sample[index] = entry
  end
  return out
end

check("LT285.damageMeter.api", function()
  if type(C_DamageMeter) ~= "table" then return { api = "absent" } end
  local result = { inCombat = read("InCombatLockdown") and true or false,
    cvar = read("GetCVar", "damageMeterEnabled") or "none", collector = X.DamageMeter.Status() }
  if type(C_DamageMeter.IsDamageMeterAvailable) == "function" then
    local ok, available, reason = pcall(C_DamageMeter.IsDamageMeterAvailable)
    result.available = not ok and "error" or plain(available)
    result.failureReason = ok and plain(reason) or nil
  else result.available = "absent" end
  if type(C_DamageMeter.GetAvailableCombatSessions) ~= "function" then
    result.sessions = "absent"
    return result
  end
  local sessions = damageMeterSession(C_DamageMeter.GetAvailableCombatSessions)
  result.sessions = {}
  for _, session in ipairs(sessions or {}) do
    table.insert(result.sessions, { id = fieldOrSecret(session, "sessionID"), name = fieldOrSecret(session, "name"),
      duration = fieldOrSecret(session, "durationSeconds") })
  end
  local last = sessions and sessions[#sessions]
  local sessionID = last and readable(last.sessionID)
  if not sessionID or type(C_DamageMeter.GetCombatSessionFromID) ~= "function" then return result end
  local types = Enum and Enum.DamageMeterType
  if not types then result.types = "absent" return result end
  result.checkedSession = sessionID
  result.damageTaken = damageMeterSources(sessionID, types.DamageTaken,
    type(C_DamageMeter.GetCombatSessionSourceFromID) == "function")
  result.deaths = damageMeterSources(sessionID, types.Deaths, false)
  return result
end)

---------------------------------------------------------------------------
-- LT-72/LT-352 Gruppensuche (WoW Forever): welche Gruppensuche hat der Client, welche Felder liefert C_LFGList wirklich?
-- Sammelt nebenbei: bei jedem Suchergebnis (Event lfg.results) und beim Überfahren einer Gruppe (lfg.hover) alle
-- Felder der Gruppe und ihrer Mitglieder (Rollen, Klassen für die Filter von LT-352); dazu /lt debug check "LT352.lfg.api".
---------------------------------------------------------------------------
local LFG_SAMPLE_RESULTS = 3   -- so viele Gruppen je Suchergebnis vollständig
local LFG_SAMPLE_MEMBERS = 5   -- so viele Mitglieder je Gruppe vollständig
local LFG_UI = { "LFGListUtil_SetSearchEntryTooltip", "LFGBrowseSearchEntryTooltip_UpdateAndShow",
  "LFGListFrame", "LFGBrowseFrame", "LFGParentFrame", "PVEFrame", "GroupFinderFrame", "LFGBrowseSearchEntryTooltip" }
local LFG_API = { "GetSearchResults", "GetFilteredSearchResults", "GetSearchResultInfo", "GetSearchResultPlayerInfo",
  "GetSearchResultLeaderInfo", "GetSearchResultMemberInfo", "GetSearchResultMemberCounts",
  "GetSearchResultEncounterInfo", "GetSearchResultFriends", "GetActivityInfoTable", "GetApplicants" }

-- Alle lesbaren Felder einer Tabelle; Untertabellen nur als Feldliste, geheime Werte als "secret"
local function fieldsOf(value)
  if type(value) ~= "table" then return value end
  if ns.IsSecret(value) then return "secret" end
  local fields = {}
  for key, field in pairs(value) do
    if ns.IsSecret(field) then fields[tostring(key)] = "secret"
    elseif type(field) == "table" then
      local keys = {}
      for subKey, subField in pairs(field) do keys[#keys + 1] = tostring(subKey) .. "=" .. plain(subField) end
      table.sort(keys)
      fields[tostring(key)] = table.concat(keys, ","):sub(1, 200)
    else fields[tostring(key)] = field end
  end
  return fields
end

local function lfgResult(resultID)
  if resultID == nil or ns.IsSecret(resultID) then return { resultID = "secret" } end
  local info = call("C_LFGList.GetSearchResultInfo", resultID)
  local entry = { resultID = resultID, info = fieldsOf(info), leader = fieldsOf(call("C_LFGList.GetSearchResultLeaderInfo", resultID)),
    memberCounts = fieldsOf(call("C_LFGList.GetSearchResultMemberCounts", resultID)),
    encounters = fieldsOf(call("C_LFGList.GetSearchResultEncounterInfo", resultID)),
    friends = fieldsOf(call("C_LFGList.GetSearchResultFriends", resultID)), members = {} }
  local count = type(info) == "table" and not ns.IsSecret(info) and readable(info.numMembers) or 0
  for index = 1, math.min(count, LFG_SAMPLE_MEMBERS) do
    entry.members[index] = fieldsOf(call("C_LFGList.GetSearchResultPlayerInfo", resultID, index))
  end
  return entry
end

-- GetSearchResults() -> totalResultsFound, results; call packt beide Rückgaben in eine Liste
local function lfgResultIDs()
  local packed = call("C_LFGList.GetSearchResults")
  local results = type(packed) == "table" and packed[2]
  return type(results) == "table" and not ns.IsSecret(results) and results or {}
end

check("LT352.lfg.api", function()
  local ui, functions = {}, {}
  for _, name in ipairs(LFG_UI) do ui[name] = api(name) ~= nil end
  for _, name in ipairs(LFG_API) do functions[name] = api("C_LFGList." .. name) ~= nil end
  local ids = lfgResultIDs()
  return { forever = ns.Client.IsForever(), ui = ui, api = functions, results = #ids,
    first = ids[1] and lfgResult(ids[1]) or nil }
end)

ns.RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED", function()
  if not DebugLog.IsEnabled() then return end
  local ids, sample = lfgResultIDs(), {}
  for index = 1, math.min(#ids, LFG_SAMPLE_RESULTS) do sample[index] = safe(lfgResult, ids[index]) end
  write({ area = "event", event = "lfg.results", extra = { count = #ids, sample = sample } })
end)

-- Überfahren einer Gruppe: einmal je Gruppe, solange keine andere überfahren wurde
local lastHovered
local function lfgHover(variant, resultID)
  if not DebugLog.IsEnabled() or resultID == lastHovered then return end
  lastHovered = resultID
  write({ area = "event", event = "lfg.hover", extra = { variant = variant, result = safe(lfgResult, resultID) } })
end

local lfgHooked = {}
local function hookLfg()
  if not lfgHooked.retail and api("LFGListUtil_SetSearchEntryTooltip") then
    lfgHooked.retail = true
    hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(_, resultID) lfgHover("retail", resultID) end)
  end
  if not lfgHooked.classic and api("LFGBrowseSearchEntryTooltip_UpdateAndShow") then
    lfgHooked.classic = true
    hooksecurefunc("LFGBrowseSearchEntryTooltip_UpdateAndShow", function(_, resultID) lfgHover("classic", resultID) end)
  end
end
hookLfg()
ns.RegisterEvent("ADDON_LOADED", hookLfg)

-- LT-271: Tooltip-Block und Sprachfilter der Gruppensuche. Welche Gruppensuche lädt Forever (woran hängen die Hooks)?
check("LT271.lfg.finder", function()
  local loaded = {}
  for _, addon in ipairs({ "Blizzard_GroupFinder", "Blizzard_GroupFinder_VanillaStyle", "Blizzard_LookingForGroupUI" }) do
    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(addon)
    loaded[addon] = isLoaded == true
  end
  local ui = {}
  for _, name in ipairs(LFG_UI) do ui[name] = api(name) ~= nil end
  return { forever = ns.Client.IsForever(), loaded = loaded, ui = ui, tooltipEnabled = ns.LFGTooltip.IsEnabled() == true,
    dataAvailable = ns.LFGData.IsAvailable() }
end)

-- Was liefert GetSearchResultEncounterInfo (Namen? IDs?) und lassen sich die Namen den Bossen der Instanz zuordnen?
check("LT271.lfg.encounters", function()
  local out = {}
  for index, resultID in ipairs(lfgResultIDs()) do
    if index > LFG_SAMPLE_RESULTS then break end
    local info = call("C_LFGList.GetSearchResultInfo", resultID)
    local activityIDs = type(info) == "table" and not ns.IsSecret(info) and readable(info.activityIDs) or {}
    local activity = call("C_LFGList.GetActivityInfoTable", activityIDs[1] or (type(info) == "table" and info.activityID))
    local mapID = type(activity) == "table" and readable(activity.mapID)
    local names, matched = ns.LFGData.KilledBosses(resultID), {}
    for npcID in pairs(mapID and ns.LFGData.KilledBossNpcs(mapID, names) or {}) do matched[#matched + 1] = npcID end
    table.sort(matched)
    out[tostring(resultID)] = { raw = fieldsOf(call("C_LFGList.GetSearchResultEncounterInfo", resultID)), activities = #activityIDs,
      mapID = mapID, activityName = type(activity) == "table" and readable(activity.fullName), names = table.concat(names, ","),
      bossesOfMap = mapID and #(ns.InstanceBosses.List(mapID) or {}) or 0, matchedNpcs = table.concat(matched, ",") }
  end
  return out
end)

-- Ergebnis des Sprachfilters: verfügbare, Standard- und aktive Sprachen, gemerkter Filter, Region
check("LT271.lfg.languages", function()
  local function list(value)
    local keys = {}
    for key, entry in pairs(type(value) == "table" and not ns.IsSecret(value) and value or {}) do
      keys[#keys + 1] = type(key) == "number" and tostring(entry) or (key .. "=" .. plain(entry))
    end
    table.sort(keys)
    return table.concat(keys, ",")
  end
  return { available = list(call("C_LFGList.GetAvailableLanguageSearchFilter")), enabled = list(call("C_LFGList.GetLanguageSearchFilter")),
    defaults = list(call("C_LFGList.GetDefaultLanguageSearchFilter")), setting = ns.db.lfgLanguages and "custom" or "blizzard",
    backup = plain(ns.db.lfgLanguageBackup), region = call("GetCurrentRegionName"), canChange = call("LFGListCanChangeLanguages") }
end)

-- LT-272: Eigenes Gruppensuche-Fenster. Welche Funktionen von Blizzards Fenster gibt es, ist es offen, existieren
-- die APIs, die das Fenster braucht, und wie sehen Kategorien/Aktivitäten/Rollen aus?
check("LT272.lfg.window", function()
  local functions = {}
  for _, name in ipairs({ "LFGVanilla_ShowFrame", "LFGVanilla_ToggleFrame", "ToggleGroupFinderFrame", "LFGParentFrame_SearchActiveEntry",
    "ChatFrame_SendTell", "HideUIPanel" }) do functions[name] = api(name) ~= nil end
  local apis = {}
  for _, name in ipairs({ "Search", "GetAvailableCategories", "GetLfgCategoryInfo", "GetAvailableActivities", "GetFilteredSearchResults",
    "HasActiveEntryInfo", "GetActiveEntryInfo", "CreateListing", "UpdateListing", "RemoveListing", "GetDefaultLanguageSearchFilter" }) do
    apis[name] = api("C_LFGList." .. name) ~= nil
  end
  local categories = {}
  for _, category in ipairs(ns.LFGSearch.IsAvailable() and ns.LFGSearch.Categories() or {}) do
    categories[#categories + 1] = category.id .. "=" .. category.name .. "(" .. #ns.LFGSearch.Activities(category.id) .. ")"
  end
  local roles = call("C_LFGListRoles.GetRoles")
  -- LT-305: Blizzard-Optik des Fensters: Vorlagen vorhanden (Titel, Schließen, Menüaufbau), Spielstil- und Voicechat-Werte
  local panel = ns.LFGWindow and ns.LFGWindow.panel
  local look = { panelTitle = panel ~= nil and type(panel.SetTitle) == "function",
    closeButton = panel ~= nil and type(panel.CloseButton) == "table",
    dropdownMenu = panel ~= nil and ns.LFGWindow.Parts().categoryDropdown ~= nil
      and type(ns.LFGWindow.Parts().categoryDropdown.SetupMenu) == "function",
    playstyles = Enum and Enum.LFGEntryGeneralPlaystyle ~= nil, voiceModes = Enum and Enum.LFGEntryVoiceMode ~= nil,
    playstyleText = GetGeneralPlaystyleString ~= nil }
  -- LT-309: Einstiege statt Ersetzen (Minikarten-Icon, Knopf an Blizzards Fenster)
  return { minimapButton = ns.db.lfgMinimapButton == true, look = look,
    blizzardTab = ns.LFGWindow ~= nil and ns.LFGWindow.blizzardTab ~= nil,
    functions = functions, api = apis, categories = table.concat(categories, ","),
    roles = fieldsOf(roles), parentShown = LFGParentFrame and LFGParentFrame:IsShown() or false,
    windowShown = ns.LFGWindow and ns.LFGWindow.IsShown() or false, chatTell = ChatFrameUtil and ChatFrameUtil.SendTell ~= nil }
end)

-- LT-351: Seitenreiter an Blizzards Gruppensuche. Gibt es Blizzards Vorlage und den Reiter "Wer", ist LFG Forever
-- da, woran hängt unser Reiter, und bleibt Blizzards Fenster nach unseren Klicks ungetaintet (Taint-Quelle leer)?
check("LT351.lfg.sidetab", function()
  local tab = ns.LFGWindow and ns.LFGWindow.blizzardTab
  local anchor = tab and select(2, tab:GetPoint(1))
  local parent = LFGParentFrame
  local secure, taintedBy
  if parent and issecurevariable then secure, taintedBy = issecurevariable(parent, "selectedTab") end
  return { template = C_XMLUtil ~= nil and C_XMLUtil.GetTemplateInfo ~= nil
      and C_XMLUtil.GetTemplateInfo("LargeSideTabButtonTemplate") ~= nil,
    whoTab = parent ~= nil and parent.WhoListingTab ~= nil, lfgForever = _G.LFGForeverBlizzardTab ~= nil,
    tab = tab ~= nil, anchor = (anchor ~= nil and anchor == _G.LFGForeverBlizzardTab and "LFGForever")
      or (parent ~= nil and anchor ~= nil and anchor == parent.WhoListingTab and "WhoListingTab") or tostring(anchor),
    selectedTabSecure = secure, taintedBy = taintedBy, combat = InCombatLockdown(),
    ownSideTabs = ns.LFGWindow and ns.LFGWindow.sideTabs and #ns.LFGWindow.sideTabs or 0 }
end)

-- LT-352: Filter der eigenen Gruppensuche. Gespeicherte Filter (nach /reload noch da?), Rollenabfrage (Funktion da, als
-- Leiter/Assistent erlaubt?), Tastenbelegung, Klassennamen und Spielstile, die der Client für die Filteransicht liefert
check("LT352.lfg.filters", function()
  local classes = {}
  for _, class in ipairs(ns.LFGFilters.CLASSES) do
    classes[class] = type(LOCALIZED_CLASS_NAMES_MALE) == "table" and LOCALIZED_CLASS_NAMES_MALE[class] or false
  end
  local saved = ns.db.lfgFilters
  return { saved = type(saved) == "table" and saved or false,
    active = type(saved) == "table" and ns.LFGFilters.ActiveCount(saved) or 0,
    rolePoll = api("InitiateRolePoll") ~= nil, inGroup = read("IsInGroup"),
    leader = read("UnitIsGroupLeader", "player"), assistant = read("UnitIsGroupAssistant", "player"),
    binding = read("GetBindingKey", "LEVELTIMER_LFG_WINDOW") or false, classes = classes,
    playstyles = Enum ~= nil and Enum.LFGEntryGeneralPlaystyle ~= nil,
    activeEntry = ns.LFGSearch.ActiveEntry() ~= nil, windowShown = ns.LFGWindow and ns.LFGWindow.IsShown() or false }
end)

-- LT-387: Dungeon-Guide jederzeit. Welche Dungeons stehen in der Auswahl (Namen in der Client-Sprache? unnamed =
-- Karten ohne Namen, noRange = ohne Levelbereich, stehen am Ende), Vorauswahl nach Level und was das Fenster zeigt
local GUIDE_SAMPLE = 5
check("LT387.guide.anytime", function()
  local list, sample, unnamed, noRange = ns.DungeonGuide.Dungeons(), {}, 0, 0
  for index, dungeon in ipairs(list) do
    if not dungeon.name or dungeon.name == "" then unnamed = unnamed + 1 end
    local ranged = dungeon.minLevel ~= math.huge
    if not ranged then noRange = noRange + 1 end
    if index <= GUIDE_SAMPLE or index == #list then
      sample[#sample + 1] = { index = index, mapID = dungeon.mapID, name = dungeon.name,
        range = ranged and (dungeon.minLevel .. "-" .. dungeon.maxLevel) or "?" }
    end
  end
  local suggested = ns.DungeonGuide.SuggestedMapID()
  local pageIndex, pages, name, mapID = ns.DungeonGuideWindow.Current()
  return { available = ns.DungeonGuide.IsAvailable(), level = read("UnitLevel", "player"), count = #list, unnamed = unnamed,
    noRange = noRange, sample = sample, suggested = suggested,
    suggestedName = suggested and ns.InstanceInfo.MapName(suggested) or false, auto = ns.db.dungeonGuideAuto,
    shown = ns.DungeonGuideWindow.IsShown(), page = pageIndex, pages = type(pages) == "table" and #pages or 0,
    shownName = name, shownMapID = mapID }
end)

-- LT-393: Liefert das Dungeonkompendium Bilder für die Guide-Dungeons? found/missing = Guide-Dungeons mit/ohne Bild
-- (missing mit Namen, höchstens SAMPLE), journal = Kompendium-API vorhanden, total = alle gefundenen Instanzbilder
local ART_SAMPLE = 10
check("LT393.dungeonArt.coverage", function()
  local total, journal = ns.DungeonArt.Count()
  local found, missing = 0, {}
  for _, dungeon in ipairs(ns.DungeonGuide.Dungeons()) do
    if ns.DungeonArt.ForMap(dungeon.mapID, 416, 96) then
      found = found + 1
    elseif #missing < ART_SAMPLE then
      missing[#missing + 1] = dungeon.mapID .. " " .. tostring(dungeon.name)
    end
  end
  return { journal = journal, total = total, found = found, missing = missing }
end)

-- LT-395: Symbole aus Zauber-IDs (UI/Options/Icons.lua, Mechanik-Typen): kennt der Client jeden Zauber und sein
-- Symbol? missing = Schlüssel ohne Symbol (bleiben in den Einstellungen ohne Icon)
check("LT395.icons.spells", function()
  local missing, count = {}, 0
  for key, source in pairs(ns.OptionsIcons) do
    if type(source) == "number" then
      count = count + 1
      if not ns.Widgets.SpellTexture(source) then missing[#missing + 1] = key .. " " .. source end
    end
  end
  table.sort(missing)
  return { spells = count, missing = missing }
end)

-- LT-404: Zauber-Links im Dungeon Guide verlinken den ersten **Namen** einer Mechanik-Zeile mit deren Zauber-ID. Passt
-- der Clientname der ID zum Namen im Text (Text in Client-Sprache)? unknown = ID ohne Namen im Client, mismatch =
-- Beispiele "ID Client | Text" (höchstens SPELL_LINK_SAMPLE), mismatches = Anzahl aller Abweichungen,
-- unknownIDs = Beispiel-IDs ohne Clientnamen (höchstens UNKNOWN_ID_SAMPLE)
local SPELL_LINK_SAMPLE = 80
local UNKNOWN_ID_SAMPLE = 40  -- Beispiele für unknownIDs
check("LT404.guide.spellLinks", function()
  if not ns.Mechanics then return { available = false } end
  local textIndex = GetLocale() == "deDE" and 3 or 4
  local linked, unknown, mismatch, mismatches, unknownIDs = 0, 0, {}, 0, {}
  for _, list in pairs(ns.Mechanics) do
    for _, mechanic in ipairs(list) do
      local marked = mechanic[1] > 0 and mechanic[textIndex]:match("%*%*(.-)%*%*")
      if marked then
        linked = linked + 1
        local name = C_Spell.GetSpellName(mechanic[1])
        if not name or ns.IsSecret(name) then
          unknown = unknown + 1
          if #unknownIDs < UNKNOWN_ID_SAMPLE then unknownIDs[#unknownIDs + 1] = mechanic[1] end
        elseif name:lower() ~= marked:lower() then
          mismatches = mismatches + 1
          if #mismatch < SPELL_LINK_SAMPLE then mismatch[#mismatch + 1] = mechanic[1] .. " " .. name .. " | " .. marked end
        end
      end
    end
  end
  return { available = true, linked = linked, unknown = unknown, unknownIDs = unknownIDs, mismatches = mismatches,
    mismatch = mismatch }
end)

-- LT-408: Sprache je Gruppe über den Realm? Stehen Realms in den Leader-Namen der aktuellen Suchergebnisse (nach
-- einer Suche ausführen), und welche? realms = Realm -> Anzahl Leader (höchstens REALM_SAMPLE), own = eigener Realm
local REALM_SAMPLE = 15
check("LT408.lfg.realms", function()
  local lfg = C_LFGList
  if not (lfg and lfg.GetFilteredSearchResults and lfg.GetSearchResultInfo) then return { available = false } end
  local _, ids = lfg.GetFilteredSearchResults()
  local total, withRealm, realms, distinct = 0, 0, {}, 0
  for _, resultID in ipairs(ids or {}) do
    local info = lfg.GetSearchResultInfo(resultID)
    local leader = type(info) == "table" and info.leaderName
    if leader and not ns.IsSecret(leader) then
      total = total + 1
      local realm = leader:match("%-(.+)$")
      if realm then
        withRealm = withRealm + 1
        if not realms[realm] and distinct < REALM_SAMPLE then realms[realm], distinct = 0, distinct + 1 end
        if realms[realm] then realms[realm] = realms[realm] + 1 end
      end
    end
  end
  return { available = true, leaders = total, withRealm = withRealm, realms = realms,
    own = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName() }
end)

-- LT-413: Forever (Build 71037) liefert einen leeren Realmnamen. Welche Quelle kennt den Realm noch? used = Realm,
-- den Level Time nutzt (Client oder gespeicherter Eintrag mit derselben GUID)
check("LT413.realm.sources", function()
  local fullName = api("UnitFullName")
  local ok, _, fullRealm = false, nil, nil
  if type(fullName) == "function" then ok, _, fullRealm = pcall(fullName, "player") end
  return { realmName = read("GetRealmName"), normalized = read("GetNormalizedRealmName"),
    fullRealm = ok and readable(fullRealm) or nil, realmID = read("GetRealmID"), guid = read("UnitGUID", "player"),
    used = ns.Database.RealmName(), key = ns.characterKey }
end)

-- LT-335..338: Gruppen-Sync nur mit Gruppe/Gilde/Freunden. Gibt es die Gruppen-APIs (sonst bleiben Abgänger in der
-- Peer-Liste), und erkennt UnitInParty/UnitInRaid die Absender im Format "Name-Realm" (inParty je Peer)?
local SYNC_PEERS = 5
check("LT338.sync.groupApi", function()
  local functions = {}
  for _, name in ipairs({ "UnitInParty", "UnitInRaid", "IsInGroup", "IsInRaid", "IsInGuild", "C_FriendList.IsFriend" }) do
    functions[name] = api(name) ~= nil
  end
  local peers = {}
  for name in pairs(ns.PartyQuestSync.GetPeers()) do
    if #peers >= SYNC_PEERS then break end
    peers[#peers + 1] = { name = name, inParty = read("UnitInParty", name), inRaid = read("UnitInRaid", name) }
  end
  return { functions = functions, inGroup = read("IsInGroup"), inGuild = read("IsInGuild"), setting = ns.db.partyQuestSync,
    peerCount = ns.PartyQuestSync.GetPeerCount(), queue = ns.PartyQuestSync.GetQueueLength(), peers = peers }
end)

-- Helfer für die Prüfungen nach Bereich (ChecksUI.lua, ChecksQuests.lua, ChecksRuns.lua, laden danach)
-- LT-321 (/lt debug check nach einem Forever-Dungeon): welche Quelle hat welchen Boss gezählt (id:Quelle), und kamen
-- ENCOUNTER_START/ENCOUNTER_END/BOSS_KILL überhaupt an (Zähler dieser Sitzung)?
check("LT321.bossKills.sources", function()
  local sources = ns.InstanceBosses.Sources()
  return { counted = table.concat(sources.counted, ","), encounterStart = sources.encounterStart,
    encounterEnd = sources.encounterEnd, bossKill = sources.bossKill, deathSource = ns.InstanceBosses.DeathSource() }
end)

DebugLog.Helpers = {
  plain = plain, chunked = chunked, method = method, frameName = frameName, pointOf = pointOf, frameState = frameState,
  framesByName = framesByName, recentEntries = recentEntries, readable = readable, read = read, readXY = readXY,
  fieldsOf = fieldsOf,
}

-- LT-405/406: Recap während des Laufs. Gibt es einen offenen Lauf (isCurrent), baut der Recap daraus Spieler und Gegner?
-- Einstellungen der Setup-Assistent-Schalter für Guide und Recap
check("LT405.recap.run", function()
  if not (ns.DungeonRecapWindow and ns.InstanceRecap) then return { available = false } end
  local log = ns.History.GetInstanceLog(ns.characterKey)
  local record = log[1]
  local result = { available = true, runs = #log, current = record and record.isCurrent or false,
    windowShown = ns.DungeonRecapWindow.IsShown(),
    settings = { recapAutoOpen = ns.db.dungeonRecapAutoOpen, guideAuto = ns.db.dungeonGuideAuto,
      runTracker = ns.db.showRunTracker } }
  if record then
    result.players, result.mobs = #ns.InstanceRecap.Players(record), #ns.InstanceRecap.Mobs(record)
    result.completed = ns.InstanceRuns.IsCompleted(record)
  end
  return result
end)

-- LT-407: Gruppensuche-Dungeons nach Level aufsteigend (Mindestlevel, dann Höchstlevel; ohne Mindestlevel am Ende)?
-- unsorted = Beispiele "Name min-max" an Stellen, wo die Reihenfolge bricht; levels = erste Einträge
check("LT407.lfg.levelOrder", function()
  if not (ns.LFGSearch and ns.LFGSearch.IsAvailable()) then return { available = false } end
  local result = { available = true, categories = {} }
  for _, category in ipairs(ns.LFGSearch.Categories()) do
    local list = ns.LFGSearch.Activities(category.id)
    local unsorted, levels, noMin = {}, {}, 0
    for index, activity in ipairs(list) do
      if activity.minLevel == 0 then noMin = noMin + 1 end
      if #levels < 6 then levels[#levels + 1] = activity.name .. " " .. activity.minLevel .. "-" .. activity.maxLevel end
      local previous = list[index - 1]
      if previous and previous.minLevel > 0 and activity.minLevel > 0 and activity.minLevel < previous.minLevel
          and #unsorted < 5 then
        unsorted[#unsorted + 1] = activity.name .. " " .. activity.minLevel .. "-" .. activity.maxLevel
      end
    end
    result.categories[#result.categories + 1] = { id = category.id, name = category.name, count = #list,
      noMinLevel = noMin, unsorted = unsorted, levels = levels }
  end
  return result
end)

-- LT-409: alte Zauberränge auf den Leisten. Gibt es die Aufrufe fürs Tauschen (C_Spell.PickupSpell, PlaceAction), und
-- was findet Find (je Zauber: Rang auf der Leiste/im Buch, Ziel-ID, Plätze)? Tauscht nichts.
check("LT409.oldRanks.upgrade", function()
  if not (ns.OldSpellRanks and ns.OldSpellRanks.IsAvailable()) then return { available = false } end
  local spells = {}
  local found = ns.OldSpellRanks.Find()
  for index = 1, math.min(#found, 8) do
    local spell = found[index]
    local slot = ns.OldSpellRanks.NextSlot(spell)
    spells[index] = { id = spell.spellID, name = spell.name, barRank = spell.barRank, bookRank = spell.bookRank,
      upgradeID = spell.upgradeID, slots = #spell.slots, nextSlot = slot,
      button = slot and ns.ActionBars.ButtonForSlot(slot) ~= nil or false }
  end
  return { available = true, count = #found, spells = spells, ignored = ns.OldSpellRanks.IgnoredCount(),
    api = { pickupSpell = type(C_Spell.PickupSpell), placeAction = type(PlaceAction), clearCursor = type(ClearCursor),
      getActionInfo = type(GetActionInfo) }, buttons = #ns.ActionBars.Buttons(),
    highlighted = ns.ActionBars.HighlightedSlot() }
end)

-- LT-410: Ruhestein-Hinweis beim Betreten von Gasthaus/Hauptstadt: ist der Bindeort lesbar, meldet IsResting den Zustand
check("LT410.hearth.bind", function()
  local location = GetBindLocation and GetBindLocation()
  return { setting = ns.db.remindHearth, bindLocation = readable(location), resting = IsResting and IsResting() or nil,
    module = ns.HearthReminder ~= nil }
end)

-- LT-411: Dungeonquests "alle markieren": Zustand des Hinweisfensters (Einträge mit Ort, deren Zonen mit Elternkarte,
-- gesetzte Kartenpunkte)
check("LT411.dungeonQuests.markAll", function()
  local hint = ns.DungeonQuestHint
  if not hint then return { available = false } end
  local rows, entries = hint.Rows()
  local zones, withPlace = {}, 0
  for _, entry in pairs(entries or {}) do
    if entry.place then
      withPlace = withPlace + 1
      local id = entry.place.uiMapID
      if id and zones[id] == nil then
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        zones[id] = info and { name = info.name, parent = info.parentMapID } or false
      end
    end
  end
  return { available = true, shown = hint.IsShown(), rows = #(rows or {}), withPlace = withPlace, zones = zones,
    pins = hint.PinCount(), getMapInfo = type(C_Map and C_Map.GetMapInfo) }
end)

-- LT-414: Doppel-Eintrag "Name-" ohne Realm. split = beiseitegelegte Einträge (nach GUID), emptyRealm = noch in der
-- Charakterliste stehende Schlüssel mit leerem Realm, own = Schlüssel und Realm des eingeloggten Charakters
check("LT414.realm.splitEntries", function()
  local stats = _G.LevelTimerStatsDB
  if not stats then return { available = false } end
  local split, emptyRealm = {}, {}
  for guid, entry in pairs(stats.splitCharacters or {}) do
    if #split < 5 then split[#split + 1] = { guid = guid, level = type(entry) == "table" and entry.level or nil } end
  end
  for key in pairs(stats.characters or {}) do
    if key:match("%-$") and #emptyRealm < 5 then emptyRealm[#emptyRealm + 1] = key end
  end
  return { available = true, split = split, emptyRealm = emptyRealm, own = ns.characterKey,
    ownRealm = ns.character and ns.character.realm }
end)

-- Elite-Einblendung: nur allein und je Gegnerart höchstens alle 5 Minuten. Zustand, auf den der Code prüft
check("LT416.alerts.eliteGate", function()
  local inInstance, kind = IsInInstance()
  return { setting = ns.db.alertEliteKill, inGroup = IsInGroup(), instanceType = inInstance and kind or nil,
    wouldShow = ns.db.alertEliteKill and not IsInGroup() and not (inInstance and (kind == "party" or kind == "raid")) }
end)

-- Debug-Log-Aufräumen: Handwerkswaren sind keine Questreste (class 7 darf nicht vorkommen), Dungeonquest-Titel der
-- aktuellen Instanz in Spielsprache (untitled = Platzhalter "#id")
check("LT416.cleanup.leftoversTitles", function()
  local result = { available = true, leftovers = {}, untitled = {} }
  if ns.QuestLeftovers then
    for _, entry in ipairs(ns.QuestLeftovers.InBags()) do
      if #result.leftovers < 8 then
        result.leftovers[#result.leftovers + 1] = { id = entry.itemID, name = entry.name,
          class = C_Item and C_Item.GetItemInfoInstant and select(6, C_Item.GetItemInfoInstant(entry.itemID)) }
      end
    end
  end
  local mapID = select(8, GetInstanceInfo())
  if mapID and ns.DungeonQuests and ns.DungeonQuests.IsAvailable() then
    for _, quest in ipairs(ns.DungeonQuests.OwnQuests(mapID)) do
      if quest.title:match("^#") and #result.untitled < 8 then result.untitled[#result.untitled + 1] = quest.questID end
    end
  end
  return result
end)

-- LT-349: Wasserschild-Anzeige nur bei eingeklappter Buffleiste; was sieht sie gerade?
check("LT349.waterShield.display", function()
  local CollapsedBuffs = ns.CollapsedBuffs
  local point, relativeTo = CollapsedBuffs.Frame():GetPoint(1)
  local shield
  local aurasReadable = ns.Auras.ForEachBuff(function(aura)
    if not shield and CollapsedBuffs.Matches(aura) then
      shield = { name = readable(aura.name), applications = readable(aura.applications),
        countText = readable(CollapsedBuffs.DisplayCount(aura)) }
    end
  end)
  return {
    barCollapsed = CollapsedBuffs.IsBarCollapsed(), aurasReadable = aurasReadable == true, aura = shield or "none",
    restricted = ns.Auras.Restricted(), shown = CollapsedBuffs.ShownCount(),
    anchor = point and { point = point, to = relativeTo and relativeTo.GetName and relativeTo:GetName() or "?" } or "none",
  }
end)
