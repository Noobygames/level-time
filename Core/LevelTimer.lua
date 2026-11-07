-- Kern: Einstellungs- und Event-Verteilung, Login-, Logout- und Level-Up-Ablauf. Wird vor allen Modulen geladen.
local _, ns = ...

-- Name, den Spieler sehen (CurseForge-Projekt, Addon-Liste, Fenster, Chat). Technische Namen
-- (Ordner, .toc, SavedVariables, Frame-Namen, /lt) bleiben LevelTimer, sonst gingen Daten verloren.
ns.DISPLAY_NAME = "Level Time"

-- Schnittstelle für Schwester-Addons (z.B. StreamGoal, per "## Dependencies: LevelTimer"): der Namespace mit allen
-- Bausteinen (Card, Widgets, TableView, Alerts, Journal, Format, ...), Events, Login und Level-Up. Die Tabelle ist
-- dieselbe, die die Module füllen; sie steht beim Laden des anderen Addons vollständig bereit.
LevelTimerAPI = ns

local PREFIX = "|cfff4c95d" .. ns.DISPLAY_NAME .. ":|r "

function ns.Print(msg)
  print(PREFIX .. msg)
end

-- Erweitertes Logging für /lt debug (ns.debug, bis /reload). Technische Zeilen für die
-- Fehlersuche, daher englisch und nicht übersetzt. Werte werden zu Text, daher nur %s:
-- ns.Debug("stats", "%s +%s", counter, amount)
local DEBUG_PREFIX = "|cff888888[debug] %s:|r "

-- Werte zu Text (geheime als "<secret>") und in format einsetzen
function ns.FormatDebug(format, ...)
  local count = select("#", ...)
  local args = { ... }
  for i = 1, count do
    args[i] = ns.IsSecret(args[i]) and "<secret>" or tostring(args[i])
  end
  return string.format(format, unpack(args, 1, count))
end

local function printDebug(area, text)
  print(PREFIX .. string.format(DEBUG_PREFIX, area) .. text)
end

-- Technische Zeile immer ausgeben (Ergebnisse der /lt debug-Befehle)
function ns.DebugPrint(area, format, ...)
  printDebug(area, ns.FormatDebug(format, ...))
end

-- Empfänger der Debug-Zeilen neben dem Chat: recorder(area, text), z.B. das dauerhafte Log (DebugLog.lua); nil = keiner
local debugRecorder
function ns.SetDebugRecorder(recorder)
  debugRecorder = recorder
end

local function record(area, text)
  if debugRecorder then pcall(debugRecorder, area, text) end  -- ein defektes Log darf nichts aufhalten
end

-- Nur bei eingeschaltetem Logging (Chat mit /lt debug, dauerhaftes Log mit /lt debug log)
function ns.Debug(area, format, ...)
  if not ns.debug and not debugRecorder then return end
  local text = ns.FormatDebug(format, ...)
  if ns.debug then printDebug(area, text) end
  record(area, text)
end

-- Retail kann Werte als "secret" markieren; die dürfen Addons nicht auswerten
-- Kämpft der Spieler gerade? Anzeigen, die stören würden, warten damit bis nach dem Kampf
function ns.InCombat()
  local inCombat = UnitAffectingCombat("player")
  return not ns.IsSecret(inCombat) and inCombat == true
end

-- Alle vorhandenen Chatfenster (ChatFrame1..n). NUM_CHAT_WINDOWS gibt es nur als Deprecation-Alias (CVar
-- loadDeprecationFallbacks); Blizzards Chat-Code nutzt Constants.ChatFrameConstants.MaxChatWindows.
local DEFAULT_MAX_CHAT_WINDOWS = 10
function ns.ChatFrames()
  local constants = Constants and Constants.ChatFrameConstants
  local list = {}
  for index = 1, (constants and constants.MaxChatWindows) or NUM_CHAT_WINDOWS or DEFAULT_MAX_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. index]
    if chatFrame then table.insert(list, chatFrame) end
  end
  return list
end

function ns.IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- Ruft fn geschützt auf: ein Fehler landet beim Fehler-Handler des Clients (BugSack, Fehlerfenster),
-- der Aufrufer läuft weiter. Mit dauerhaftem Log steht der Fehler samt Aufrufstapel auch dort.
-- Läuft für jedes Event, jeden Listener und jede Aufgabe, daher ohne neue Tabelle oder Closure je Aufruf.
local function onError(message)
  if debugRecorder then
    record("error", tostring(message) .. (debugstack and ("\n" .. debugstack(2)) or ""))
  end
  return geterrorhandler()(message)
end

-- Der WoW-Client reicht xpcall-Argumente durch (alle Flavors, z.B. ExecuteFrameScript in Blizzards
-- FunctionUtil.lua); Standard-Lua 5.1 (auch der Test-Stub) nicht. Das prüft die Probe einmal beim Laden.
local XPCALL_PASSES_ARGS = (function()
  local ok, passed = xpcall(function(value) return value end, onError, true)
  return ok and passed == true
end)()

local function nativeSafeCall(fn, ...)
  return xpcall(fn, onError, ...)
end

-- Ohne Argumente in xpcall: Argument-Plätze als Upvalues und ein festes Trampolin. Das Trampolin liest Funktion
-- und Argumente, bevor es fn aufruft; ein verschachtelter Aufruf (ein Handler löst ein Event aus) überschreibt die
-- Plätze also erst, wenn der äußere sie schon gelesen hat.
local MAX_SLOTS = 20
local slots = {}
local slotFn, slotCount = nil, 0

local function trampoline()
  return slotFn(unpack(slots, 1, slotCount))
end

local function slotSafeCall(fn, ...)
  local count = select("#", ...)
  if count > MAX_SLOTS then
    local args = { ... }
    return xpcall(function() return fn(unpack(args, 1, count)) end, onError)
  end
  slots[1], slots[2], slots[3], slots[4], slots[5], slots[6], slots[7], slots[8], slots[9], slots[10],
    slots[11], slots[12], slots[13], slots[14], slots[15], slots[16], slots[17], slots[18], slots[19],
    slots[20] = ...
  slotFn, slotCount = fn, count
  return xpcall(trampoline, onError)
end

local safeCall = XPCALL_PASSES_ARGS and nativeSafeCall or slotSafeCall
ns.SafeCall = safeCall
-- Ungemessener Aufruf für den Profiler (Core/Profiler.lua), der ns.SafeCall beim Messen ersetzt
ns.RawSafeCall = safeCall

---------------------------------------------------------------------------
-- Profiler-Haken (/lt debug perf, Core/Profiler.lua). Ausgeschaltet kostet er nichts: der Kern tauscht beim
-- Einschalten die Verteiler (OnEvent, OnUpdate, ns.SafeCall) gegen gemessene Varianten aus und beim Ausschalten
-- zurück. Herkunft jedes Callbacks ("Datei.lua:Zeile") wird beim Registrieren einmal gemerkt.
---------------------------------------------------------------------------
local sources = setmetatable({}, { __mode = "k" })
local SOURCE_STACK_DEPTH = 8
local CORE_FILE = "LevelTimer.lua"

-- Erste Aufrufer-Zeile außerhalb des Kerns und der Datei skipFile (z.B. "Stats.lua" für Stats.OnIncrement)
local function callerSource(skipFile)
  if not debugstack then return "?" end
  local stack = debugstack(1, SOURCE_STACK_DEPTH, 0) or ""
  local fallback
  for file, line in stack:gmatch("([%w_]+%.lua)[^:\n]*:(%d+)") do
    local source = file .. ":" .. line
    fallback = fallback or source
    if file ~= CORE_FILE and file ~= skipFile then return source end
  end
  return fallback or "?"
end

-- Herkunft eines Callbacks für den Profiler merken; skipFile = Datei der Registrier-Funktion
function ns.RememberSource(fn, skipFile)
  if sources[fn] == nil then sources[fn] = callerSource(skipFile) end
end

function ns.SourceOf(fn)
  return sources[fn] or "?"
end

-- Skripte, die der Profiler austauscht: { frame, script, plain, profiled }; profiled(measure) liefert den Handler
local profiledScripts = {}
local measure  -- nil = Profiler aus; measure(key, fn, ...) misst einen geschützten Aufruf

local function applyScript(entry)
  entry.frame:SetScript(entry.script, measure and entry.profiled(measure) or entry.plain)
end

local function addProfiledScript(frame, script, plain, profiled)
  local entry = { frame = frame, script = script, plain = plain, profiled = profiled }
  table.insert(profiledScripts, entry)
  applyScript(entry)
end

-- OnUpdate eines Fensters setzen, das der Profiler unter label misst (z.B. "TimerWindow")
function ns.SetUpdateScript(frame, label, fn)
  local key = "onupdate " .. label
  addProfiledScript(frame, "OnUpdate", fn, function(measured)
    return function(self, elapsed) measured(key, fn, self, elapsed) end
  end)
end

-- Schlüssel je Funktion einmal bauen, damit das Messen selbst keinen Müll erzeugt
local callKeys = setmetatable({}, { __mode = "k" })
local function profiledSafeCall(fn, ...)
  local key = callKeys[fn]
  if not key then
    key = "call " .. ns.SourceOf(fn)
    callKeys[fn] = key
  end
  return measure(key, fn, ...)
end

-- measureFn(key, fn, ...) = geschützter, gemessener Aufruf; nil schaltet zurück auf die ungemessenen Verteiler
function ns.SetProfiler(measureFn)
  measure = measureFn
  ns.SafeCall = measureFn and profiledSafeCall or safeCall
  for _, entry in ipairs(profiledScripts) do applyScript(entry) end
end

function ns.IsProfiling()
  return measure ~= nil
end

-- Alle Callbacks einer Liste, jeder für sich geschützt: ein fehlerhaftes Modul hält die anderen
-- (z.B. beim Level-Up oder Logout) nicht auf
local function runAll(callbacks, ...)
  for index = 1, #callbacks do
    ns.SafeCall(callbacks[index], ...)
  end
end

-- Callback in eine Liste aufnehmen und seine Herkunft für den Profiler merken
local function addCallback(callbacks, callback)
  ns.RememberSource(callback)
  table.insert(callbacks, callback)
end

---------------------------------------------------------------------------
-- Einstellungen: Module registrieren Apply-Callbacks, die bei jeder Änderung
-- ihren Zustand aus ns.db neu aufbauen.
---------------------------------------------------------------------------
local applyCallbacks = {}

function ns.RegisterApply(callback)
  addCallback(applyCallbacks, callback)
end

function ns.ApplySettings()
  runAll(applyCallbacks, ns.db)
end

function ns.Set(key, value)
  ns.db[key] = value
  ns.ApplySettings()
end

---------------------------------------------------------------------------
-- Events: mehrere Module können dasselbe Event abonnieren.
-- Handler laufen in Registrierungsreihenfolge (= Ladereihenfolge der .toc).
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}
local eventKeys = {}  -- Profiler-Schlüssel je Event und Handler-Index: "event NAME Datei.lua:Zeile"

-- Gibt false zurück, wenn der Client das Event nicht kennt (andere Spielversion).
-- Das zugehörige Feature bleibt dann still aus, statt einen Fehler zu werfen.
function ns.RegisterEvent(event, handler)
  if not eventHandlers[event] then
    if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
      return false
    end
    eventHandlers[event] = {}
    eventKeys[event] = {}
  end
  table.insert(eventHandlers[event], handler)
  table.insert(eventKeys[event], "event " .. event .. " " .. callerSource())
  return true
end

local function onEvent(_, event, ...)
  runAll(eventHandlers[event], ...)
end

addProfiledScript(eventFrame, "OnEvent", onEvent, function(measured)
  return function(_, event, ...)
    local handlers, keys = eventHandlers[event], eventKeys[event]
    for index = 1, #handlers do
      measured(keys[index], handlers[index], ...)
    end
  end
end)

---------------------------------------------------------------------------
-- Wiederkehrende Aufgaben: fn(elapsed) etwa alle seconds Sekunden, erst nach dem Login (vorher
-- gibt es weder ns.db noch ns.character). elapsed = tatsächlich vergangene Zeit seit dem letzten Lauf.
-- Ein gemeinsamer Frame statt eines OnUpdate-Frames je Modul. Jede Aufgabe läuft geschützt
-- (ns.SafeCall), die übrigen laufen bei einem Fehler weiter.
---------------------------------------------------------------------------
local repeatingTasks = {}
local taskFrame = CreateFrame("Frame")

function ns.Every(seconds, fn)
  table.insert(repeatingTasks, { interval = seconds, fn = fn, elapsed = 0, key = "task " .. callerSource() })
end

-- run(task, due) führt eine fällige Aufgabe aus (ungemessen oder gemessen)
local function tickTasks(elapsed, run)
  if not ns.character then return end
  for _, task in ipairs(repeatingTasks) do
    task.elapsed = task.elapsed + elapsed
    if task.elapsed >= task.interval then
      local due = task.elapsed
      task.elapsed = 0
      run(task, due)
    end
  end
end

local function runTask(task, due)
  ns.SafeCall(task.fn, due)
end

addProfiledScript(taskFrame, "OnUpdate", function(_, elapsed) tickTasks(elapsed, runTask) end, function(measured)
  local function runMeasured(task, due) measured(task.key, task.fn, due) end
  return function(_, elapsed) tickTasks(elapsed, runMeasured) end
end)

---------------------------------------------------------------------------
-- Login/Logout. Nach dem Login stehen bereit:
--   ns.db            Einstellungen (Account)
--   ns.characterKey  "Name-Realm" des eingeloggten Charakters
--   ns.character     Statistiken des eingeloggten Charakters
--   ns.level         aktuelles Level
-- Logout kommt auch bei /reload; danach schreibt der Client die SavedVariables.
---------------------------------------------------------------------------
local loginCallbacks = {}
local logoutCallbacks = {}

function ns.OnLogin(callback)
  addCallback(loginCallbacks, callback)
end

function ns.OnLogout(callback)
  addCallback(logoutCallbacks, callback)
end

local function startTracking()
  ns.db, ns.characterKey, ns.character = ns.Database.Load()
  ns.level = UnitLevel("player")
  ns.Debug("core", "login %s level %s", ns.characterKey, ns.level)
  runAll(loginCallbacks)
  ns.ApplySettings()
end

ns.RegisterEvent("PLAYER_LOGIN", startTracking)

-- Statistiken eines Charakters löschen. Beim eingeloggten Charakter beginnt die Aufzeichnung
-- sofort neu (wie bei einem frischen Login); alle Module initialisieren sich über OnLogin.
function ns.DeleteCharacter(characterKey)
  ns.Database.DeleteCharacter(characterKey)
  if characterKey == ns.characterKey then
    startTracking()
  end
end

ns.RegisterEvent("PLAYER_LOGOUT", function()
  ns.Debug("core", "logout")
  runAll(logoutCallbacks)
end)

---------------------------------------------------------------------------
-- Level-Up in zwei Phasen, damit die Reihenfolge nicht von der Ladereihenfolge abhängt:
-- 1. OnLevelCompleted(oldLevel): Werte des alten Levels sind noch vollständig (z.B. Historie sichern)
-- 2. OnLevelStarted(newLevel): Zähler für das neue Level zurücksetzen
---------------------------------------------------------------------------
local levelCompletedCallbacks = {}
local levelStartedCallbacks = {}

function ns.OnLevelCompleted(callback)
  addCallback(levelCompletedCallbacks, callback)
end

function ns.OnLevelStarted(callback)
  addCallback(levelStartedCallbacks, callback)
end

ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  ns.Debug("core", "level up %s -> %s", ns.level, newLevel)
  runAll(levelCompletedCallbacks, ns.level)
  ns.level = newLevel
  runAll(levelStartedCallbacks, newLevel)
end)
