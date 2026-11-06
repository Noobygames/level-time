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
-- der Aufrufer läuft weiter. xpcall reicht in Lua 5.1 keine Argumente durch, daher die Closure.
-- Mit dauerhaftem Log steht der Fehler samt Aufrufstapel auch dort.
local function onError(message)
  if debugRecorder then
    record("error", tostring(message) .. (debugstack and ("\n" .. debugstack(2)) or ""))
  end
  return geterrorhandler()(message)
end

function ns.SafeCall(fn, ...)
  local args, count = { ... }, select("#", ...)
  return xpcall(function() return fn(unpack(args, 1, count)) end, onError)
end

-- Alle Callbacks einer Liste, jeder für sich geschützt: ein fehlerhaftes Modul hält die anderen
-- (z.B. beim Level-Up oder Logout) nicht auf
local function runAll(callbacks, ...)
  for _, callback in ipairs(callbacks) do
    ns.SafeCall(callback, ...)
  end
end

---------------------------------------------------------------------------
-- Einstellungen: Module registrieren Apply-Callbacks, die bei jeder Änderung
-- ihren Zustand aus ns.db neu aufbauen.
---------------------------------------------------------------------------
local applyCallbacks = {}

function ns.RegisterApply(callback)
  table.insert(applyCallbacks, callback)
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

-- Gibt false zurück, wenn der Client das Event nicht kennt (andere Spielversion).
-- Das zugehörige Feature bleibt dann still aus, statt einen Fehler zu werfen.
function ns.RegisterEvent(event, handler)
  if not eventHandlers[event] then
    if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
      return false
    end
    eventHandlers[event] = {}
  end
  table.insert(eventHandlers[event], handler)
  return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  runAll(eventHandlers[event], ...)
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
  table.insert(repeatingTasks, { interval = seconds, fn = fn, elapsed = 0 })
end

taskFrame:SetScript("OnUpdate", function(_, elapsed)
  if not ns.character then return end
  for _, task in ipairs(repeatingTasks) do
    task.elapsed = task.elapsed + elapsed
    if task.elapsed >= task.interval then
      local due = task.elapsed
      task.elapsed = 0
      ns.SafeCall(task.fn, due)
    end
  end
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
  table.insert(loginCallbacks, callback)
end

function ns.OnLogout(callback)
  table.insert(logoutCallbacks, callback)
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
  table.insert(levelCompletedCallbacks, callback)
end

function ns.OnLevelStarted(callback)
  table.insert(levelStartedCallbacks, callback)
end

ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  ns.Debug("core", "level up %s -> %s", ns.level, newLevel)
  runAll(levelCompletedCallbacks, ns.level)
  ns.level = newLevel
  runAll(levelStartedCallbacks, newLevel)
end)
