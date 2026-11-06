-- Dauerhaftes Debug-Log: sammelt über Sitzungen hinweg Daten für die Fehlersuche und für geplante Funktionen, ohne
-- dass das Chat-Logging an sein muss. Diese Datei ist Speicher, JSON und Befehle; was gesammelt wird (Ereignis-Proben,
-- Zustand, Schnappschüsse, API-Proben, Prüfungen), steht in DebugProbes.lua.
-- Jeder Eintrag ist eine JSON-Zeile (JSON Lines) mit Zeit ("t" Uhrzeit, "gt" GetTime) und Bereich ("area"):
--   - laufendes Log (/lt debug log, bleibt über /reload an): jede ns.Debug-Zeile aller Module ("msg"), von
--     ns.SafeCall abgefangene Lua-Fehler mit Aufrufstapel und alles aus DebugProbes.lua;
--   - einmalige Prüfung (/lt debug check, auch bei ausgeschaltetem Log): alle mit DebugLog.AddCheck gemeldeten.
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
local MAX_STRING_LENGTH = 300  -- lange Texte (Chatzeilen, Aufrufstapel) werden gekürzt
local MAX_TABLE_DEPTH = 3      -- tiefer verschachtelte Tabellen (API-Rückgaben) werden nicht ausgeschrieben
local MAX_TABLE_ITEMS = 40
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
-- Schnittstelle für die Proben (DebugProbes.lua): was gesammelt wird, steht dort
---------------------------------------------------------------------------
DebugLog.Write = write
DebugLog.Pack = pack
DebugLog.PackCount = packCount

local headerWriters = {}
-- writer(reason) schreibt nach der Kopfzeile weitere Einträge (Proben, Zustand); reason = login/enabled/check
function DebugLog.OnHeader(writer)
  headerWriters[#headerWriters + 1] = writer
end

local checks = {}
-- run() liefert die Werte, die ins Log sollen; ein Fehler wird mitgeschrieben, die übrigen Prüfungen laufen weiter
function DebugLog.AddCheck(name, run)
  checks[#checks + 1] = { name = name, run = run }
end

function DebugLog.CheckCount()
  return #checks
end

local function addonVersion()
  local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  return getMetadata and getMetadata("LevelTimer", "Version") or "?"
end

local function writeHeader(reason)
  write({
    area = "session", reason = reason, character = ns.characterKey, version = addonVersion(),
    build = pack(GetBuildInfo()), interface = Client.GetInterfaceVersion(), forever = Client.IsForever(),
    locale = GetLocale(),
  })
  for _, writer in ipairs(headerWriters) do ns.SafeCall(writer, reason) end
end

-- Alle Prüfungen ausführen und ins Log schreiben; Rückgabe: Anzahl, davon mit Fehler
function DebugLog.RunChecks()
  writeHeader("check")
  local failed = 0
  for _, check in ipairs(checks) do
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
  return #checks, failed
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
  if DebugLog.IsEnabled() then write({ area = "session", reason = "logout" }) end
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
