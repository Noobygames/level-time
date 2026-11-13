-- Level Time Data Extractor: lokales Entwickler-Addon (nie veröffentlicht, siehe sources.md im Hauptordner). Sammelt
-- beim Spielen Spieldaten als Datenquelle für Level Time (Collect/*.lua) und enthält das Debug-Werkzeug von Level Time
-- (Debug/*.lua: Debug-Log, Ereignis-Proben, Prüfungen, Testbefehle, Profiler). Der Datensammler läuft auch ohne
-- Level Time; der Debug-Teil hängt sich über LevelTimerAPI (= Namespace von Level Time) an und fehlt ohne Level Time.
-- Gespeichert wird account-weit in LevelTimerExtractorDB (Daten) und LevelTimerDebugLog (Debug-Log); der Client
-- schreibt beides bei /reload und Logout nach WTF\Account\<Konto>\SavedVariables\LevelTimer_DataExtractor.lua.
-- Diese Datei: Namespace, Ereignisse, geschützte Aufrufe, Speicher und die Hilfen, die alle Sammler teilen.
local ADDON_NAME, X = ...

X.ADDON_NAME = ADDON_NAME
X.LT = LevelTimerAPI  -- nil ohne Level Time
X.SCHEMA = 1          -- Form von LevelTimerExtractorDB; bei Änderung hochzählen und alte Daten umbauen
local CHAT_PREFIX = "|cff7fbfffLevel Time Data Extractor:|r "
local GRID = 100      -- Kartenzellen je Achse: 1 % der Karte (Zone: grob 5-10 Meter)
X.MAX_CELLS = 200     -- Orte je Karte und Eintrag; danach zählen nur noch bekannte Zellen

---------------------------------------------------------------------------
-- Werte lesen
---------------------------------------------------------------------------
-- Retail und WoW Forever markieren manche Werte als "secret"; die dürfen Addons nicht auswerten
function X.IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

function X.Readable(value)
  if value == nil or X.IsSecret(value) then return nil end
  return value
end

-- Der WoW-Client reicht xpcall-Argumente durch, Standard-Lua 5.1 (Test-Stub) nicht; einmal beim Laden geprüft
local XPCALL_PASSES_ARGS = select(2, xpcall(function(value) return value end, function() end, true)) == true

-- fn(...) geschützt; Fehler gehen an den Fehler-Handler des Clients, der Aufrufer läuft weiter
function X.SafeCall(fn, ...)
  if XPCALL_PASSES_ARGS then return xpcall(fn, geterrorhandler(), ...) end
  local count, args = select("#", ...), { ... }
  return xpcall(function() return fn(unpack(args, 1, count)) end, geterrorhandler())
end

-- Funktion unter einem Pfad ("C_Map.GetBestMapForUnit") oder nil
function X.Api(path)
  local value = _G
  for part in path:gmatch("[^%.]+") do
    if type(value) ~= "table" then return nil end
    value = value[part]
  end
  return type(value) == "function" and value or nil
end

-- Aufruf über einen Pfad; nil, wenn es die Funktion nicht gibt oder sie fehlschlägt (erster Rückgabewert)
function X.Call(path, ...)
  local fn = X.Api(path)
  if not fn then return nil end
  local ok, result = pcall(fn, ...)
  return ok and X.Readable(result) or nil
end

-- "Creature-0-1-2-3-299-0000" -> "Creature", 299; Spieler und unbekannte Formen -> Art, nil
function X.ParseGuid(guid)
  guid = X.Readable(guid)
  if type(guid) ~= "string" then return nil end
  local kind = guid:match("^(%a+)%-")
  if kind == "Creature" or kind == "Vehicle" or kind == "GameObject" then
    local id = tonumber((guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")))
    return kind, id
  end
  return kind, nil
end

function X.ItemIdFromLink(link)
  link = X.Readable(link)
  return type(link) == "string" and tonumber((link:match("item:(%d+)"))) or nil
end

local function escapePattern(text)
  return (text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- Globaler Formattext ("%s dies, you gain %d experience.") als am Anfang verankertes Muster mit Fängen, dazu je Fang
-- die Argumentnummer (umgestellte Platzhalter wie "%2$d ... %1$s" in manchen Sprachen)
function X.PatternFromFormat(format)
  if type(format) ~= "string" then return nil end
  local parts, order, last = {}, {}, 1
  for start, position, kind, finish in format:gmatch("()%%(%d*)%$?([sd])()") do
    parts[#parts + 1] = escapePattern(format:sub(last, start - 1))
    parts[#parts + 1] = kind == "s" and "(.+)" or "(%d+)"
    order[#order + 1] = tonumber(position) or (#order + 1)
    last = finish
  end
  parts[#parts + 1] = escapePattern(format:sub(last))
  return "^" .. table.concat(parts), order
end

-- Fänge einer Chatzeile in Argument-Reihenfolge (nil ohne Treffer)
function X.MatchFormat(text, pattern, order)
  text = X.Readable(text)
  if type(text) ~= "string" or not pattern then return nil end
  local captures = { text:match(pattern) }
  if #captures == 0 then return nil end
  local args = {}
  for index, position in ipairs(order) do args[position] = captures[index] end
  return args
end

---------------------------------------------------------------------------
-- Ort des Spielers
---------------------------------------------------------------------------
-- Karte und Zelle (x * GRID + y, beide 0..GRID-1) oder nur die Karte (Instanzen ohne Position); nil ohne Karte
function X.Position()
  local mapID = X.Call("C_Map.GetBestMapForUnit", "player")
  if type(mapID) ~= "number" then return nil end
  local position = X.Call("C_Map.GetPlayerMapPosition", mapID, "player")
  if type(position) ~= "table" or not position.GetXY then return mapID end
  local x, y = position:GetXY()
  x, y = X.Readable(x), X.Readable(y)
  if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return mapID end
  return mapID, math.min(GRID - 1, math.floor(x * GRID)) * GRID + math.min(GRID - 1, math.floor(y * GRID))
end

-- Zellnummer zurück in Kartenanteile (Mitte der Zelle)
function X.CellToXY(cell)
  return (math.floor(cell / GRID) + 0.5) / GRID, (cell % GRID + 0.5) / GRID
end

-- record.spots[mapID][cell] += 1 an der Spielerposition; in Instanzen ohne Position record.maps[mapID] += 1
function X.AddSpot(record)
  local mapID, cell = X.Position()
  if not mapID then return end
  if not cell then
    record.maps = record.maps or {}
    record.maps[mapID] = (record.maps[mapID] or 0) + 1
    return
  end
  record.spots = record.spots or {}
  local cells = record.spots[mapID]
  if not cells then
    cells = { count = 0 }
    record.spots[mapID] = cells
  end
  if cells[cell] then
    cells[cell] = cells[cell] + 1
  elseif cells.count < X.MAX_CELLS then
    cells[cell] = 1
    cells.count = cells.count + 1
  end
end

---------------------------------------------------------------------------
-- Speicher
---------------------------------------------------------------------------
local SECTIONS = { "npcs", "objects", "quests", "items", "vendors", "trainers", "taxiNodes", "flights", "instances",
  "levels", "exploration" }

-- Tabelle eines Bereichs (nach dem Laden der SavedVariables)
function X.Section(name)
  return X.db and X.db[name]
end

-- Eintrag eines Bereichs, bei Bedarf angelegt
function X.Record(section, key)
  local records = X.db[section]
  local record = records[key]
  if not record then
    record = {}
    records[key] = record
  end
  return record
end

-- Name je Sprache (Spielernamen, NPCs, Quests, Gegenstände sind lokalisiert)
function X.SetName(record, name)
  name = X.Readable(name)
  if type(name) ~= "string" or name == "" then return end
  record.names = record.names or {}
  record.names[GetLocale()] = name
end

function X.Increment(record, key, amount)
  record[key] = (record[key] or 0) + (amount or 1)
end

local function initDatabase()
  local db = LevelTimerExtractorDB
  if type(db) ~= "table" or db.schema ~= X.SCHEMA then
    db = { schema = X.SCHEMA }
    LevelTimerExtractorDB = db
  end
  for _, section in ipairs(SECTIONS) do db[section] = db[section] or {} end
  db.builds = db.builds or {}
  local version, build, _, interface = GetBuildInfo()
  local key = tostring(version) .. "." .. tostring(build)
  local info = db.builds[key] or { first = time(), interface = interface }
  info.last = time()
  db.builds[key] = info
  X.db = db
end

function X.ResetData()
  LevelTimerExtractorDB = nil
  initDatabase()
end

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}
local loginHandlers = {}

-- fn(...) bei jedem Auftreten von event (mehrere Empfänger je Event)
function X.On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    if not pcall(frame.RegisterEvent, frame, event) then
      handlers[event] = nil  -- Event gibt es in diesem Client nicht
      return
    end
  end
  table.insert(handlers[event], fn)
end

-- fn() nach dem Login, wenn X.db bereit ist
function X.OnLogin(fn)
  table.insert(loginHandlers, fn)
end

frame:SetScript("OnEvent", function(_, event, ...)
  for _, fn in ipairs(handlers[event] or {}) do X.SafeCall(fn, ...) end
end)

X.On("PLAYER_LOGIN", function()
  initDatabase()
  for _, fn in ipairs(loginHandlers) do X.SafeCall(fn) end
end)

---------------------------------------------------------------------------
-- Chat und /lte
---------------------------------------------------------------------------
function X.Print(text)
  print(CHAT_PREFIX .. text)
end

local function count(section)
  local total = 0
  for _ in pairs(X.Section(section) or {}) do total = total + 1 end
  return total
end

local commands = {}

function commands.status()
  local L = X.L
  local log = X.DebugLog
  X.Print(string.format(L.STATUS, count("npcs"), count("quests"), count("items"), count("objects"), count("vendors"),
    count("trainers"), count("flights"), log and log.IsEnabled() and L.DEBUG_LOG_STATE_ON or L.DEBUG_LOG_STATE_OFF,
    log and log.LineCount() or 0))
end

function commands.reset(argument)
  if argument ~= "confirm" then return X.Print(X.L.RESET_HINT) end
  X.ResetData()
  X.Print(X.L.RESET_DONE)
end

function commands.log(argument)
  if not X.DebugLog then return X.Print(X.L.NO_LEVEL_TIME) end
  X.DebugLog.Command(argument)
end

function commands.check()
  if not X.DebugLog then return X.Print(X.L.NO_LEVEL_TIME) end
  X.DebugLog.CheckCommand()
end

function commands.help()
  X.Print(X.L.HELP)
end

SLASH_LEVELTIMEREXTRACTOR1 = "/lte"
SlashCmdList.LEVELTIMEREXTRACTOR = function(input)
  local name, argument = (input or ""):lower():match("^(%S*)%s*(.-)$")
  local command = commands[name ~= "" and name or "status"] or commands.help
  command(argument)
end
