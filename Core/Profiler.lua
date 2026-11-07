-- CPU-Messung für /lt debug perf: misst jeden Event-Handler, jede ns.Every-Aufgabe, jeden über ns.SafeCall
-- verteilten Callback (Zähler-, XP-, Journal-Listener, Login, Apply, ...) und die OnUpdate-Skripte der Fenster
-- (ns.SetUpdateScript). Je Schlüssel Summe und Maximum in Millisekunden (debugprofilestop), Aufrufe und der
-- Zuwachs von collectgarbage("count") in KB (grob: ein Garbage-Collector-Lauf mitten im Aufruf senkt den Wert,
-- dann zählt 0). Zeiten sind inklusiv: misst ein Handler einen weiteren Callback mit, steht dessen Zeit in beiden.
-- Aus kostet nichts: der Kern tauscht die Verteiler nur bei eingeschaltetem Profiler aus (ns.SetProfiler).
-- Bis /reload, wie ns.debug. Bericht im Chat (ns.DebugPrint) und bei eingeschaltetem Debug-Log auch dort.
local _, ns = ...

local Profiler = {}
ns.Profiler = Profiler

Profiler.DEFAULT_TOP = 15

local results = {}     -- Schlüssel -> { ms, count, max, kb }
local startedAt        -- GetTime() beim Einschalten oder Zurücksetzen
local startMemory      -- collectgarbage("count") zum selben Zeitpunkt
local clock            -- debugprofilestop
local memory           -- function() -> KB oder nil, wenn der Client collectgarbage("count") nicht erlaubt

local function readMemory()
  local ok, kb = pcall(collectgarbage, "count")
  if ok and type(kb) == "number" then return kb end
end

local function finish(key, started, memoryBefore, ...)
  local ms = clock() - started
  local entry = results[key]
  if not entry then
    entry = { ms = 0, count = 0, max = 0, kb = 0 }
    results[key] = entry
  end
  entry.ms = entry.ms + ms
  entry.count = entry.count + 1
  if ms > entry.max then entry.max = ms end
  if memoryBefore then
    local grown = collectgarbage("count") - memoryBefore
    if grown > 0 then entry.kb = entry.kb + grown end
  end
  return ...
end

-- Geschützter, gemessener Aufruf; gibt wie ns.SafeCall die Ergebnisse von xpcall zurück
local function measure(key, fn, ...)
  local memoryBefore = memory and collectgarbage("count")
  local started = clock()
  return finish(key, started, memoryBefore, ns.RawSafeCall(fn, ...))
end

function Profiler.IsAvailable()
  return debugprofilestop ~= nil
end

function Profiler.IsEnabled()
  return ns.IsProfiling()
end

function Profiler.Reset()
  results = {}
  startedAt = GetTime()
  startMemory = memory and readMemory()
end

function Profiler.SetEnabled(enabled)
  if enabled == Profiler.IsEnabled() then return end
  if enabled then
    clock = debugprofilestop
    memory = readMemory() ~= nil
    Profiler.Reset()
    ns.SetProfiler(measure)
  else
    ns.SetProfiler(nil)
  end
end

-- Einträge nach Gesamtzeit absteigend: { key, ms, count, max, kb }
function Profiler.Results()
  local list = {}
  for key, entry in pairs(results) do
    list[#list + 1] = { key = key, ms = entry.ms, count = entry.count, max = entry.max, kb = entry.kb }
  end
  table.sort(list, function(a, b)
    if a.ms ~= b.ms then return a.ms > b.ms end
    return a.key < b.key
  end)
  return list
end

local function round(value, digits)
  return string.format("%." .. digits .. "f", value)
end

-- Gemessene Sekunden und Speicherzuwachs (KB) seit dem Einschalten oder Zurücksetzen
function Profiler.Summary()
  local seconds = startedAt and (GetTime() - startedAt) or 0
  local now = startMemory and readMemory()
  return seconds, now and (now - startMemory) or nil
end

local function logResults(list)
  if not (ns.DebugLog and ns.DebugLog.IsEnabled()) then return end
  local seconds, grown = Profiler.Summary()
  ns.DebugLog.Write({ area = "perf", seconds = seconds, kb = grown, keys = #list })
  for _, item in ipairs(list) do
    ns.DebugLog.Write({ area = "perf", key = item.key, ms = item.ms, count = item.count, max = item.max, kb = item.kb })
  end
end

-- Top n nach Gesamtzeit in den Chat und, falls an, ins Debug-Log (dort alle Einträge)
function Profiler.Report(top)
  top = top or Profiler.DEFAULT_TOP
  local list = Profiler.Results()
  local seconds, grown = Profiler.Summary()
  ns.DebugPrint("perf", "%s s measured, %s keys, memory %s KB", round(seconds, 1), #list,
    grown and round(grown, 1) or "?")
  for index = 1, math.min(top, #list) do
    local item = list[index]
    ns.DebugPrint("perf", "%s: %s ms, %s calls, %s ms avg, %s ms max, %s KB", item.key, round(item.ms, 2),
      item.count, round(item.ms / item.count, 3), round(item.max, 2), round(item.kb, 1))
  end
  logResults(list)
end

-- Beim Logout (/reload) landet der Stand im Debug-Log, falls beides läuft
ns.OnLogout(function()
  if Profiler.IsEnabled() then logResults(Profiler.Results()) end
end)

-- /lt debug perf [on|off|report [n]|reset]; ohne Argument an/aus
function Profiler.Command(argument)
  local action, rest = (argument or ""):match("^(%S*)%s*(.-)$")
  if not Profiler.IsAvailable() then
    ns.DebugPrint("perf", "debugprofilestop is not available in this client")
    return
  end
  if action == "report" then
    Profiler.Report(tonumber(rest))
  elseif action == "reset" then
    Profiler.Reset()
    ns.DebugPrint("perf", "reset")
  else
    local enabled
    if action == "on" then enabled = true
    elseif action == "off" then enabled = false
    else enabled = not Profiler.IsEnabled() end
    Profiler.SetEnabled(enabled)
    ns.DebugPrint("perf", "profiler %s", enabled and "on" or "off")
  end
end
