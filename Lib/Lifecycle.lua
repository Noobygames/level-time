-- Allgemeiner Kern: Chat- und Debug-Ausgabe, geschützte Aufrufe, Profiler-Haken, Einstellungs-Verteilung (Apply,
-- ns.Set), Events, wiederkehrende Aufgaben, Login und Logout. Ohne Fachwissen: was beim Login geladen wird und der
-- Level-Up-Ablauf stehen in Core/LevelTimer.lua. Wird vor allen Modulen außer Datenbank und Sprachen geladen.
local _, ns = ...

-- Präfix der Chatzeilen; setzt das Addon mit ns.SetChatName (Level Time: "Level Time:")
local PREFIX = ""

function ns.SetChatName(name)
  PREFIX = "|cfff4c95d" .. name .. ":|r "
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

-- Chatzeile mit Präfix; mit laufendem Debug-Log steht sie dort auch (Bereich "print"), damit sich gemeldete
-- Ergebnisse (Hinweise, Ablehnungen, Zusammenfassungen) ohne Bildschirmfoto auswerten lassen
function ns.Print(msg)
  print(PREFIX .. msg)
  record("print", msg)
end

-- Läuft gerade irgendein Logging (Chat mit /lt debug oder dauerhaftes Log)? Für Aufrufer, die vor ns.Debug teure
-- Vorarbeit leisten (Listen, Sortieren, berechnete Werte)
function ns.DebugActive()
  return ns.debug == true or debugRecorder ~= nil
end
ns.IsDebugging = ns.DebugActive

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
-- Dateien des Kerns: Registrier-Funktionen stehen hier und in Core/LevelTimer.lua (Level-Up, Login)
local CORE_FILES = { ["Lifecycle.lua"] = true, ["LevelTimer.lua"] = true }

-- Erste Aufrufer-Zeile außerhalb des Kerns und der Datei skipFile (z.B. "Stats.lua" für Stats.OnIncrement)
local function callerSource(skipFile)
  if not debugstack then return "?" end
  local stack = debugstack(1, SOURCE_STACK_DEPTH, 0) or ""
  local fallback
  for file, line in stack:gmatch("([%w_]+%.lua)[^:\n]*:(%d+)") do
    local source = file .. ":" .. line
    fallback = fallback or source
    if not CORE_FILES[file] and file ~= skipFile then return source end
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

-- OnEvent eines eigenen Frames (sehr häufige Events direkt, ohne Verteiler), gemessen unter "event " .. label
function ns.SetEventScript(frame, label, fn)
  local key = "event " .. label
  addProfiledScript(frame, "OnEvent", fn, function(measured)
    return function(self, event, ...) measured(key, fn, self, event, ...) end
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
ns.RunCallbacks = runAll

-- Callback in eine Liste aufnehmen und seine Herkunft für den Profiler merken
local function addCallback(callbacks, callback)
  ns.RememberSource(callback)
  table.insert(callbacks, callback)
end
ns.AddCallback = addCallback

---------------------------------------------------------------------------
-- Einstellungen: Module registrieren Apply-Callbacks, die bei jeder Änderung
-- ihren Zustand aus ns.db neu aufbauen.
---------------------------------------------------------------------------
local applyCallbacks = {}

function ns.RegisterApply(callback)
  addCallback(applyCallbacks, callback)
end

-- Verzögerter Apply (ns.SetDeferred): ein unsichtbarer Rahmen, dessen OnUpdate nur läuft, solange er gezeigt wird
local deferredApplyFrame = CreateFrame("Frame")
deferredApplyFrame:Hide()

function ns.ApplySettings()
  deferredApplyFrame:Hide()  -- ein noch ausstehender verzögerter Apply ist damit erledigt
  runAll(applyCallbacks, ns.db)
  ns.RefreshTasks()
end

ns.SetUpdateScript(deferredApplyFrame, "DeferredApply", function()
  ns.ApplySettings()
end)

-- Gleicher Wert ändert nichts: kein Apply (alle Module bauen dabei ihren Zustand neu auf). Tabellen (Positionen)
-- werden oft an Ort und Stelle geändert und wieder übergeben, für sie gilt das nicht.
local function unchanged(key, value)
  return type(value) ~= "table" and ns.db[key] == value
end

function ns.Set(key, value)
  if unchanged(key, value) then return end
  ns.db[key] = value
  ns.ApplySettings()
end

-- Mehrere Einstellungen auf einmal: change(db) ändert ns.db (auch auf nil), danach ein Apply für alle
function ns.SetBatch(change)
  change(ns.db)
  ns.ApplySettings()
end

-- Wie ns.Set, der Apply läuft aber erst im nächsten Frame, einmal für alle Änderungen bis dahin (Regler ziehen:
-- OnValueChanged kommt je Pixel). Der Wert steht sofort in ns.db.
function ns.SetDeferred(key, value)
  if unchanged(key, value) then return end
  ns.db[key] = value
  deferredApplyFrame:Show()
end

-- Ein Apply im nächsten Frame, wenn ein Modul ns.db selbst geändert hat (z.B. Frames.SetScale beim Mausrad)
function ns.RequestApply()
  deferredApplyFrame:Show()
end

---------------------------------------------------------------------------
-- Events: mehrere Module können dasselbe Event abonnieren.
-- Handler laufen in Registrierungsreihenfolge (= Ladereihenfolge der .toc).
-- Eine Handler-Liste = { handlers = { ... }, keys = { ... } } (Profiler-Schlüssel je Handler). Abmelden baut eine
-- neue Liste, damit eine gerade laufende Verteilung ihre alte Liste unverändert zu Ende läuft.
---------------------------------------------------------------------------
local function newHandlerList()
  return { handlers = {}, keys = {} }
end

local function addHandler(list, event, handler, source)
  table.insert(list.handlers, handler)
  table.insert(list.keys, "event " .. event .. " " .. source)
end

-- Kopie ohne den ersten Eintrag von handler; nil, wenn handler nicht in der Liste steht
local function withoutHandler(list, handler)
  local rest, found = newHandlerList(), false
  for index, existing in ipairs(list.handlers) do
    if existing == handler and not found then
      found = true
    else
      table.insert(rest.handlers, existing)
      table.insert(rest.keys, list.keys[index])
    end
  end
  return found and rest or nil
end

local function dispatch(list, ...)
  if list then runAll(list.handlers, ...) end
end

local function dispatchMeasured(measured, list, ...)
  if not list then return end
  local handlers, keys = list.handlers, list.keys
  for index = 1, #handlers do
    measured(keys[index], handlers[index], ...)
  end
end

local eventFrame = CreateFrame("Frame")
local eventLists = {}  -- event -> Handler-Liste

local function registerEvent(event, handler, source)
  if not eventLists[event] then
    if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
      return false
    end
    eventLists[event] = newHandlerList()
  end
  addHandler(eventLists[event], event, handler, source)
  return true
end

-- Gibt false zurück, wenn der Client das Event nicht kennt (andere Spielversion).
-- Das zugehörige Feature bleibt dann still aus, statt einen Fehler zu werfen.
function ns.RegisterEvent(event, handler)
  return registerEvent(event, handler, callerSource())
end

addProfiledScript(eventFrame, "OnEvent", function(_, event, ...)
  dispatch(eventLists[event], ...)
end, function(measured)
  return function(_, event, ...) dispatchMeasured(measured, eventLists[event], ...) end
end)

---------------------------------------------------------------------------
-- Unit-Events nur für bestimmte Einheiten: ns.RegisterUnitEvent("UNIT_AURA", "player", fn). Der Client meldet
-- sie dann nur noch für diese Einheiten (Frame:RegisterUnitEvent, laut Blizzards SimpleFrameAPIDocumentation in
-- allen Flavors, bis zu zwei Einheiten) statt für Gruppe, Ziel und jede Namensplakette. Für UNIT_HEALTH, UNIT_AURA,
-- UNIT_SPELLCAST_*, UNIT_POWER_* usw. immer diesen Weg nehmen, wenn nur der Spieler (oder wenige Einheiten) zählt.
-- Ein Frame je Event und Einheiten. Fehlt RegisterUnitEvent, filtert der Frame selbst nach dem ersten Argument.
-- Handler bekommen dieselben Argumente wie bei ns.RegisterEvent (unit zuerst).
---------------------------------------------------------------------------
local unitEvents = {}  -- "EVENT unit1 unit2" -> { frame, event, unit1, unit2, filter, list }

local function unitsOf(units)
  if type(units) == "table" then return units[1], units[2] end
  return units, nil
end

-- Event am Frame anmelden; false = Client kennt das Event nicht
local function subscribeUnitEvent(entry)
  local frame = entry.frame
  if type(frame.RegisterUnitEvent) == "function" then
    local ok, registered
    if entry.unit2 then
      ok, registered = pcall(frame.RegisterUnitEvent, frame, entry.event, entry.unit1, entry.unit2)
    else
      ok, registered = pcall(frame.RegisterUnitEvent, frame, entry.event, entry.unit1)
    end
    return ok and registered ~= false
  end
  entry.filter = true
  return pcall(frame.RegisterEvent, frame, entry.event)
end

local function newUnitEvent(event, unit1, unit2)
  local entry = { frame = CreateFrame("Frame"), event = event, unit1 = unit1, unit2 = unit2 }
  local function wanted(unit)
    return not entry.filter or unit == entry.unit1 or (entry.unit2 ~= nil and unit == entry.unit2)
  end
  addProfiledScript(entry.frame, "OnEvent", function(_, _, unit, ...)
    if wanted(unit) then dispatch(entry.list, unit, ...) end
  end, function(measured)
    return function(_, _, unit, ...)
      if wanted(unit) then dispatchMeasured(measured, entry.list, unit, ...) end
    end
  end)
  return entry
end

local function registerUnitEvent(event, units, handler, source)
  local unit1, unit2 = unitsOf(units)
  local key = event .. " " .. unit1 .. " " .. (unit2 or "")
  local entry = unitEvents[key]
  if not entry then
    entry = newUnitEvent(event, unit1, unit2)
    unitEvents[key] = entry
  end
  if not entry.list then
    if not subscribeUnitEvent(entry) then return false end
    entry.list = newHandlerList()
  end
  addHandler(entry.list, event, handler, source)
  return true
end

-- units = "player" oder { "player", "pet" }; false, wenn der Client das Event nicht kennt
function ns.RegisterUnitEvent(event, units, handler)
  return registerUnitEvent(event, units, handler, callerSource())
end

-- Handler wieder abmelden (normales oder Unit-Event); ist keiner mehr übrig, meldet der Frame das Event ab.
-- Rückgabe: true, wenn der Handler registriert war.
function ns.UnregisterEvent(event, handler)
  local removed = false
  local list = eventLists[event]
  local rest = list and withoutHandler(list, handler)
  if rest then
    removed = true
    if #rest.handlers == 0 then
      eventFrame:UnregisterEvent(event)
      eventLists[event] = nil
    else
      eventLists[event] = rest
    end
  end
  for _, entry in pairs(unitEvents) do
    rest = entry.event == event and entry.list and withoutHandler(entry.list, handler)
    if rest then
      removed = true
      if #rest.handlers == 0 then
        entry.frame:UnregisterEvent(event)
        entry.list = nil
      else
        entry.list = rest
      end
    end
  end
  return removed
end

-- Handler, die gemeinsam an- und abgemeldet werden (z.B. nur solange eine Einstellung an ist oder das Debug-Log
-- läuft): group.Add(event, units, handler) mit units = nil für normale Events; group.SetActive(active) liefert beim
-- Anmelden die Events, die der Client nicht kennt.
function ns.NewEventGroup()
  local group, entries, active = {}, {}, false

  local function subscribe(entry)
    if entry.units then return registerUnitEvent(entry.event, entry.units, entry.handler, entry.source) end
    return registerEvent(entry.event, entry.handler, entry.source)
  end

  function group.Add(event, units, handler)
    local entry = { event = event, units = units, handler = handler, source = callerSource() }
    table.insert(entries, entry)
    if active then subscribe(entry) end
  end

  function group.SetActive(wanted)
    wanted = wanted and true or false
    local unknown = {}
    if wanted == active then return unknown end
    active = wanted
    for _, entry in ipairs(entries) do
      if not active then
        ns.UnregisterEvent(entry.event, entry.handler)
      elseif not subscribe(entry) then
        table.insert(unknown, entry.event)
      end
    end
    return unknown
  end

  function group.IsActive()
    return active
  end

  return group
end

---------------------------------------------------------------------------
-- Wiederkehrende Aufgaben: fn(elapsed) etwa alle seconds Sekunden, erst nach dem Login (ns.RunLogin; vorher
-- gibt es weder Einstellungen noch Daten des Charakters). elapsed = tatsächlich vergangene Zeit seit dem letzten Lauf.
-- Ein gemeinsamer Frame statt eines OnUpdate-Frames je Modul. Jede Aufgabe läuft geschützt
-- (ns.SafeCall), die übrigen laufen bei einem Fehler weiter.
-- enabled(db) (optional) sagt, ob die Aufgabe gerade etwas zu tun hat (z.B. Einstellung an). Ausgewertet wird es
-- nicht je Bild, sondern nach jedem ns.ApplySettings und bei ns.RefreshTasks() (für Zustände ohne Einstellung,
-- z.B. das Debug-Log). Ausgeschaltete Aufgaben kosten nichts; beim Einschalten beginnt ihr elapsed bei 0. Nur für
-- Aufgaben, die bei false sowieso sofort zurückkehren würden, damit sich nichts ändert.
---------------------------------------------------------------------------
local repeatingTasks = {}
local taskFrame = CreateFrame("Frame")
local loggedIn = false  -- ns.RunLogin lief (Aufgaben warten bis dahin)

function ns.Every(seconds, fn, enabled)
  table.insert(repeatingTasks, {
    interval = seconds, fn = fn, elapsed = 0, key = "task " .. callerSource(), enabled = enabled,
    active = enabled == nil,
  })
end

-- enabled-Prädikate neu auswerten; ein fehlerhaftes Prädikat lässt die Aufgabe laufen (wie ohne Prädikat)
function ns.RefreshTasks()
  if not ns.db then return end
  for _, task in ipairs(repeatingTasks) do
    if task.enabled then
      local ok, wanted = ns.SafeCall(task.enabled, ns.db)
      local active = not ok or wanted and true or false
      if active and not task.active then task.elapsed = 0 end
      task.active = active
    end
  end
end

-- run(task, due) führt eine fällige Aufgabe aus (ungemessen oder gemessen)
local function tickTasks(elapsed, run)
  if not loggedIn then return end
  for _, task in ipairs(repeatingTasks) do
    if task.active then task.elapsed = task.elapsed + elapsed end
    if task.active and task.elapsed >= task.interval then
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
-- Login/Logout: Module melden sich mit ns.OnLogin/ns.OnLogout an; das Addon startet den Login mit
-- ns.RunLogin(prepare) (prepare stellt Einstellungen und Daten bereit). Logout kommt auch bei /reload; danach schreibt
-- der Client die SavedVariables.
---------------------------------------------------------------------------
local loginCallbacks = {}
local logoutCallbacks = {}

function ns.OnLogin(callback)
  addCallback(loginCallbacks, callback)
end

function ns.OnLogout(callback)
  addCallback(logoutCallbacks, callback)
end

-- prepare() lädt Einstellungen und Daten (ns.db, ...), dann laufen alle Login-Callbacks und ein Apply. Darf erneut
-- laufen (z.B. nach dem Löschen der Daten des eingeloggten Charakters).
function ns.RunLogin(prepare)
  prepare()
  loggedIn = true
  runAll(loginCallbacks)
  ns.ApplySettings()
end

ns.RegisterEvent("PLAYER_LOGOUT", function()
  ns.Debug("core", "logout")
  runAll(logoutCallbacks)
end)
