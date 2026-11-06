-- Dauerhaftes Debug-Log: sammelt über Sitzungen hinweg Daten für die Fehlersuche, ohne dass das Chat-Logging an sein
-- muss. Jeder Eintrag ist eine JSON-Zeile (JSON Lines) mit Zeit ("t" Uhrzeit, "gt" GetTime) und Bereich ("area"):
--   - laufendes Log (/lt debug log, bleibt über /reload an): jede ns.Debug-Zeile aller Module ("msg"), von
--     ns.SafeCall abgefangene Lua-Fehler mit Aufrufstapel, Ereignis-Proben (EVENT_PROBES: Argumente und Zustand im
--     Moment des Ereignisses), jede SNAPSHOT_SECONDS ein Zustand (Zone, Level, XP, Geld, Kampf) und beim Login
--     Client, Charakter und API-Proben;
--   - einmalige Prüfung (/lt debug check, auch bei ausgeschaltetem Log): alle CHECKS mit Ergebnis oder Fehler.
-- Addons können keine Dateien schreiben: die Zeilen liegen in der SavedVariable LevelTimerDebugLog, die der Client
-- bei /reload und Logout nach WTF\Account\<Konto>\SavedVariables\LevelTimer.lua schreibt (`make debuglog` liest sie).
-- Höchstens MAX_LINES Zeilen, die ältesten fallen weg. Zeilen vor dem Login werden gepuffert, bis feststeht, ob das
-- Log an ist. Geheime Werte erscheinen als "<secret>".
local _, ns = ...
local L = ns.L
local Client = ns.Client

local DebugLog = {}
ns.DebugLog = DebugLog

DebugLog.MAX_LINES = 4000
local TRIM_SLACK = 300         -- erst ab MAX_LINES + TRIM_SLACK kürzen, dann auf MAX_LINES (nicht bei jeder Zeile)
local PENDING_MAX = 200        -- Zeilen vor dem Login
local MAX_EVENT_ARGS = 10      -- mehr Argumente einer Ereignis-Probe werden nicht geschrieben
local MAX_STRING_LENGTH = 300  -- lange Texte (Chatzeilen, Aufrufstapel) werden gekürzt
local MAX_TABLE_DEPTH = 3      -- tiefer verschachtelte Tabellen (API-Rückgaben) werden nicht ausgeschrieben
local MAX_TABLE_ITEMS = 40
local SNAPSHOT_SECONDS = 60
local SECRET = "<secret>"
local NULL = {}                -- Platzhalter für nil in Listen (JSON null), damit Lücken die Liste nicht abschneiden

---------------------------------------------------------------------------
-- JSON: nur was das Log braucht (Text, Zahl, Wahrheitswert, Tabelle); Funktionen und Frames als Typname
---------------------------------------------------------------------------
local ESCAPES = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function jsonString(text)
  if #text > MAX_STRING_LENGTH then text = text:sub(1, MAX_STRING_LENGTH) .. "..." end
  return '"' .. text:gsub('[%c"\\]', function(char)
    return ESCAPES[char] or string.format("\\u%04x", char:byte())
  end) .. '"'
end

local function isArray(value)
  local count = 0
  for _ in pairs(value) do count = count + 1 end
  return count == #value
end

local encode

local function encodeTable(value, depth)
  if depth > MAX_TABLE_DEPTH then return '"<table>"' end
  local parts = {}
  if isArray(value) then
    for i = 1, math.min(#value, MAX_TABLE_ITEMS) do
      parts[#parts + 1] = encode(value[i], depth + 1)
    end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = tostring(key) end
  table.sort(keys)
  for i = 1, math.min(#keys, MAX_TABLE_ITEMS) do
    local key = keys[i]
    local item = value[key]
    if item == nil then item = value[tonumber(key)] end
    parts[#parts + 1] = jsonString(key) .. ":" .. encode(item, depth + 1)
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

encode = function(value, depth)
  if ns.IsSecret(value) then return jsonString(SECRET) end
  if value == NULL then return "null" end
  local kind = type(value)
  if kind == "nil" then return "null" end
  if kind == "boolean" then return tostring(value) end
  if kind == "number" then
    if value ~= value or value == math.huge or value == -math.huge then return "null" end
    return string.format("%.14g", value)
  end
  if kind == "string" then return jsonString(value) end
  if kind == "table" and not value.GetObjectType then return encodeTable(value, depth or 1) end
  return jsonString("<" .. kind .. ">")
end
DebugLog.Encode = encode

-- Die ersten count Werte als Liste; nil wird zu NULL (JSON null), damit nichts dahinter verloren geht
local function packCount(count, ...)
  local values = {}
  for i = 1, count do
    local value = select(i, ...)
    if value == nil then value = NULL end
    values[i] = value
  end
  return values
end

-- Alle Werte als Liste (Rückgaben von API-Aufrufen)
local function pack(...)
  return packCount(select("#", ...), ...)
end

---------------------------------------------------------------------------
-- Speicher
---------------------------------------------------------------------------
local store    -- LevelTimerDebugLog, ab Login
local pending = {}

local function trim(lines)
  if #lines < DebugLog.MAX_LINES + TRIM_SLACK then return lines end
  local kept = {}
  for i = #lines - DebugLog.MAX_LINES + 1, #lines do
    kept[#kept + 1] = lines[i]
  end
  return kept
end

-- entry = Tabelle mit area und weiteren Feldern; Zeit kommt dazu
local function write(entry)
  entry.t = date("%Y-%m-%d %H:%M:%S")
  entry.gt = GetTime()
  local line = encode(entry)
  if store then
    store.lines[#store.lines + 1] = line
    store.lines = trim(store.lines)
  elseif #pending < PENDING_MAX then
    pending[#pending + 1] = line
  end
end

function DebugLog.IsEnabled()
  return store ~= nil and store.enabled == true
end

function DebugLog.LineCount()
  return store and #store.lines or 0
end

function DebugLog.Lines()
  return store and store.lines or {}
end

---------------------------------------------------------------------------
-- Zustand: was bei Ereignissen und im Schnappschuss mitgeschrieben wird
---------------------------------------------------------------------------
local function safe(fn, ...)
  if not fn then return nil end
  local ok, value = pcall(fn, ...)
  if ok then return value end
  return "error: " .. tostring(value)
end

local function playerState()
  return {
    level = safe(UnitLevel, "player"),
    xp = safe(UnitXP, "player"),
    xpMax = safe(UnitXPMax, "player"),
    rested = safe(GetXPExhaustion),
    resting = safe(IsResting),
    combat = safe(UnitAffectingCombat, "player"),
    money = safe(GetMoney),
    zone = safe(GetRealZoneText),
    subzone = safe(GetSubZoneText),
    instance = pack(safe(IsInInstance)),
  }
end

---------------------------------------------------------------------------
-- Ereignis-Proben: Ereignisse, deren Argumente, Reihenfolge oder Inhalt je Client für offene Punkte im Spiel geprüft
-- werden müssen (z.B. geheime XP-Meldungen 251, UnitXPMax beim Level-Up 175, Boss-Kills 302/322, Beschwörung 256,
-- Atem 255, Beruf 297, Ruf 278/303, Einladung mit GUID 265). state = Zustand zum Zeitpunkt mitschreiben.
---------------------------------------------------------------------------
local EVENT_PROBES = {
  { event = "CHAT_MSG_COMBAT_XP_GAIN", state = true },
  { event = "PLAYER_XP_UPDATE", state = true },
  { event = "PLAYER_LEVEL_UP", state = true },
  { event = "QUEST_TURNED_IN", state = true },
  { event = "PLAYER_REGEN_DISABLED" },
  { event = "PLAYER_REGEN_ENABLED" },
  { event = "PLAYER_DEAD", state = true },
  { event = "PLAYER_ALIVE" },
  { event = "PLAYER_UNGHOST" },
  { event = "ZONE_CHANGED_NEW_AREA", state = true },
  { event = "PLAYER_ENTERING_WORLD", state = true },
  { event = "CHAT_MSG_LOOT" },
  { event = "CHAT_MSG_SKILL" },
  { event = "CHAT_MSG_COMBAT_FACTION_CHANGE" },
  { event = "CHAT_MSG_COMBAT_HONOR_GAIN" },
  { event = "CHAT_MSG_SYSTEM" },
  { event = "CHAT_MSG_MONEY" },
  { event = "PLAYER_MONEY", state = true },
  { event = "TIME_PLAYED_MSG" },
  { event = "ENCOUNTER_START" },
  { event = "ENCOUNTER_END", state = true },
  { event = "BOSS_KILL" },
  { event = "CONFIRM_SUMMON" },
  { event = "RESURRECT_REQUEST" },
  { event = "MIRROR_TIMER_START" },
  { event = "MIRROR_TIMER_STOP" },
  { event = "CINEMATIC_START" },
  { event = "PLAY_MOVIE" },
  { event = "ACHIEVEMENT_EARNED" },
  { event = "PARTY_INVITE_REQUEST" },
  { event = "TRAINER_SHOW" },
  { event = "PLAYER_CONTROL_LOST", state = true },
  { event = "PLAYER_CONTROL_GAINED", state = true },
  { event = "LOOT_READY" },
  { event = "UPDATE_FACTION" },
}

local function probeEvent(probe, ...)
  if not DebugLog.IsEnabled() then return end
  local count = math.min(select("#", ...), MAX_EVENT_ARGS)
  while count > 0 and select(count, ...) == nil do count = count - 1 end
  write({ area = "event", event = probe.event, args = packCount(count, ...),
    state = probe.state and playerState() or nil })
end

local unknownEvents = {}
for _, probe in ipairs(EVENT_PROBES) do
  if not ns.RegisterEvent(probe.event, function(...) probeEvent(probe, ...) end) then
    unknownEvents[#unknownEvents + 1] = probe.event
  end
end

---------------------------------------------------------------------------
-- API- und Text-Proben (beim Login und in /lt debug check): gibt es die Funktion, wie lautet der globale Text
---------------------------------------------------------------------------
local API_PROBES = {
  "C_SummonInfo.ConfirmSummon", "C_SummonInfo.GetSummonConfirmSummoner", "ConfirmSummon", "GetSummonConfirmSummoner",
  "AcceptResurrect", "GetMirrorTimerProgress", "GetMirrorTimerInfo", "StopCinematic", "FlashClientIcon",
  "Screenshot", "C_QuestLog.GetInfo", "GetQuestLogTitle", "GetQuestLogRewardXP", "C_QuestLog.ReadyForTurnIn",
  "C_QuestLog.IsQuestFlaggedCompleted", "IsQuestFlaggedCompleted", "C_QuestLog.UnitIsRelatedToActiveQuest",
  "C_GossipInfo.SelectAvailableQuest", "C_Reputation.GetFactionDataByID", "C_Reputation.GetFactionDataByIndex",
  "GetFactionInfo", "C_MapExplorationInfo.GetExploredMapTextures", "C_Map.GetPlayerMapPosition",
  "C_Map.GetBestMapForUnit", "C_Item.GetItemCount", "GetItemCount", "C_PartyInfo.InviteUnit", "GetPlayerInfoByGUID",
  "BuyTrainerService", "GetTrainerServiceInfo", "C_TaxiMap.GetAllTaxiNodes", "TaxiNodePosition",
  "GetAchievementInfo", "C_CurrencyInfo.GetCurrencyInfo", "C_ChatInfo.SendAddonMessage",
  "C_ChatInfo.InChatMessagingLockdown", "C_DeathRecap.GetRecapEvents", "GetGuildBankWithdrawMoney",
  "CanGuildBankRepair", "GetProfessions", "GetSkillLineInfo", "TooltipDataProcessor", "C_Secrets",
  "C_Secrets.GetPowerTypeSecrecy", "C_Secrets.ShouldAurasBeSecret", "issecretvalue",
}

local GLOBAL_STRING_PROBES = {
  "COMBATLOG_XPGAIN_FIRSTPERSON", "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED", "ERR_ZONE_EXPLORED", "ERR_ZONE_EXPLORED_XP",
  "SKILL_RANK_UP", "FACTION_STANDING_INCREASED", "FACTION_STANDING_DECREASED", "LOOT_ITEM_SELF",
  "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF", "LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF",
  "COMBATLOG_HONORGAIN", "INSTANCE_RESET_SUCCESS", "ERR_INV_FULL",
}

local function lookup(path)
  local value = _G
  for part in path:gmatch("[^%.]+") do
    if type(value) ~= "table" then return nil end
    value = value[part]
  end
  return value
end

local function writeApiProbes()
  local apis = {}
  for _, path in ipairs(API_PROBES) do apis[path] = type(lookup(path)) end
  local strings = {}
  for _, name in ipairs(GLOBAL_STRING_PROBES) do strings[name] = _G[name] or false end
  write({ area = "probe", apis = apis, strings = strings, unknownEvents = unknownEvents })
end

local function addonVersion()
  local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  return getMetadata and getMetadata("LevelTimer", "Version") or "?"
end

local function writeHeader(reason)
  write({
    area = "session", reason = reason, character = ns.characterKey, version = addonVersion(),
    build = pack(GetBuildInfo()), interface = Client.GetInterfaceVersion(), forever = Client.IsForever(),
    locale = GetLocale(), state = playerState(),
  })
  writeApiProbes()
end

---------------------------------------------------------------------------
-- Einmalige Prüfung (/lt debug check): je Eintrag ein Aufruf mit seinen Rückgabewerten, Fehler werden mitgeschrieben.
-- Für offene "im Spiel prüfen"-Punkte der Roadmap; neue Fragen ans Spiel kommen als weiterer Eintrag dazu.
---------------------------------------------------------------------------
local function firstQuestId()
  if C_QuestLog and C_QuestLog.GetInfo then
    for index = 1, (C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries() or 0) do
      local info = C_QuestLog.GetInfo(index)
      if info and not info.isHeader then return info.questID, info end
    end
  end
  return nil
end

local function mapPosition()
  local mapId = C_Map.GetBestMapForUnit("player")
  local position = mapId and C_Map.GetPlayerMapPosition(mapId, "player")
  return mapId, position and pack(position:GetXY()) or nil
end

local CHECKS = {
  { name = "secret.powerSecrecy", run = function() return C_Secrets.GetPowerTypeSecrecy(0) end },
  { name = "secret.aurasSecret", run = function() return C_Secrets.ShouldAurasBeSecret() end },
  { name = "unit.power", run = function() return UnitPower("player"), UnitPowerMax("player") end },
  { name = "unit.health", run = function() return UnitHealth("player"), UnitHealthMax("player") end },
  { name = "unit.stats", run = function() return pack(UnitStat("player", 1)), pack(UnitStat("player", 3)) end },
  { name = "unit.race", run = function() return UnitRace("player") end },
  { name = "unit.class", run = function() return UnitClass("player") end },
  { name = "unit.targetQuest", run = function()
    return UnitExists("target"), C_QuestLog.UnitIsRelatedToActiveQuest("target")
  end },
  { name = "xp.state", run = function() return UnitXP("player"), UnitXPMax("player"), GetXPExhaustion() end },
  { name = "deathRecap.withoutId", run = function() return C_DeathRecap.GetRecapEvents() end },  -- Roadmap 180
  { name = "deathRecap.hasEvents", run = function() return C_DeathRecap.HasRecapEvents() end },
  { name = "guild.repair", run = function() return CanGuildBankRepair(), GetGuildBankWithdrawMoney() end },  -- 179
  { name = "chat.lockdown", run = function() return C_ChatInfo.InChatMessagingLockdown() end },
  { name = "quest.count", run = function() return C_QuestLog.GetNumQuestLogEntries() end },
  { name = "quest.firstInfo", run = function() return select(2, firstQuestId()) end },  -- Felder für 259/270
  { name = "quest.firstRewardXp", run = function() return GetQuestLogRewardXP((firstQuestId())) end },
  { name = "quest.classicTitle", run = function() return GetQuestLogTitle(1) end },
  { name = "reputation.first", run = function() return C_Reputation.GetFactionDataByIndex(1) end },
  { name = "reputation.classic", run = function() return GetFactionInfo(1) end },
  { name = "map.position", run = mapPosition },
  { name = "map.exploredTextures", run = function()
    local textures = C_MapExplorationInfo.GetExploredMapTextures(C_Map.GetBestMapForUnit("player"))
    return textures and #textures
  end },
  { name = "instance.info", run = function() return GetInstanceInfo() end },
  { name = "item.hearthstoneCount", run = function() return C_Item.GetItemCount(6948) end },
  { name = "skill.professions", run = function() return GetProfessions() end },
  { name = "skill.classicFirst", run = function() return GetSkillLineInfo(1) end },
  { name = "mirror.timer1", run = function() return GetMirrorTimerInfo(1) end },
  { name = "summon.pending", run = function() return C_SummonInfo.GetSummonConfirmSummoner() end },
  { name = "achievement.points", run = function() return GetTotalAchievementPoints() end },
  { name = "trainer.services", run = function() return GetNumTrainerServices() end },  -- nur bei offenem Lehrer
  { name = "frame.levelUpDisplay", run = function() return LevelUpDisplay ~= nil, EventToastManagerFrame ~= nil end },
}
DebugLog.CHECKS = CHECKS

-- Alle Prüfungen ausführen und ins Log schreiben; Rückgabe: Anzahl, davon mit Fehler
function DebugLog.RunChecks()
  writeHeader("check")
  local failed = 0
  for _, check in ipairs(CHECKS) do
    local results = pack(pcall(check.run))
    local entry = { area = "check", name = check.name }
    if results[1] then
      table.remove(results, 1)
      entry.result = results
    else
      failed = failed + 1
      entry.error = tostring(results[2])
    end
    write(entry)
  end
  return #CHECKS, failed
end

---------------------------------------------------------------------------
-- An/aus
---------------------------------------------------------------------------
local function recordDebugLine(area, text)
  write({ area = area, msg = text })
end

local function attach()
  ns.SetDebugRecorder(DebugLog.IsEnabled() and recordDebugLine or nil)
end

function DebugLog.SetEnabled(enabled)
  if not store then return end
  store.enabled = enabled
  attach()
  if enabled then writeHeader("enabled") end
end

function DebugLog.Clear()
  if store then store.lines = {} end
end

-- Vor dem Login puffern; danach entscheidet die gespeicherte Einstellung
ns.SetDebugRecorder(recordDebugLine)

ns.OnLogin(function()
  LevelTimerDebugLog = LevelTimerDebugLog or {}
  local firstLogin = store == nil
  store = LevelTimerDebugLog
  store.lines = store.lines or {}
  if firstLogin and DebugLog.IsEnabled() then
    for _, line in ipairs(pending) do store.lines[#store.lines + 1] = line end
    store.lines = trim(store.lines)
  end
  pending = {}
  attach()
  if DebugLog.IsEnabled() then writeHeader("login") end
end)

ns.OnLogout(function()
  if DebugLog.IsEnabled() then write({ area = "session", reason = "logout", state = playerState() }) end
end)

ns.Every(SNAPSHOT_SECONDS, function()
  if DebugLog.IsEnabled() then write({ area = "snapshot", state = playerState() }) end
end)

-- /lt debug log [clear|status]
function DebugLog.Command(argument)
  if argument == "clear" then
    DebugLog.Clear()
    ns.Print(L.DEBUG_LOG_CLEARED)
  elseif argument == "status" then
    ns.Print(string.format(L.DEBUG_LOG_STATUS, DebugLog.IsEnabled() and L.DEBUG_LOG_STATE_ON or L.DEBUG_LOG_STATE_OFF,
      DebugLog.LineCount(), DebugLog.MAX_LINES))
  else
    DebugLog.SetEnabled(not DebugLog.IsEnabled())
    ns.Print(DebugLog.IsEnabled() and L.DEBUG_LOG_ON or L.DEBUG_LOG_OFF)
  end
end

-- /lt debug check
function DebugLog.CheckCommand()
  local count, failed = DebugLog.RunChecks()
  ns.Print(string.format(L.DEBUG_CHECK_DONE, count, failed))
end
