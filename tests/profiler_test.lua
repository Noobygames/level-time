-- /lt debug perf: misst Events, Aufgaben, Listener und Fenster-OnUpdate nur, solange er an ist.
wow.login({ level = 10, playedSeconds = 600 })

local Profiler = addon.Profiler
expect("aus nach dem Login", Profiler.IsEnabled(), false)
local plainSafeCall = addon.SafeCall
local timerWindow = LevelTimerFrame
local plainOnUpdate = timerWindow and timerWindow._scripts.OnUpdate

-- Ein teurer Event-Handler: 5 ms je Aufruf
addon.RegisterEvent("PLAYER_REGEN_ENABLED", function() wow.profileMs = wow.profileMs + 5 end)
wow.fire("PLAYER_REGEN_ENABLED")
expect("aus: nichts gemessen", #Profiler.Results(), 0)

SlashCmdList.LEVELTIMER("debug perf on")
expect("an", Profiler.IsEnabled(), true)
expectTrue("SafeCall getauscht", addon.SafeCall ~= plainSafeCall)
if plainOnUpdate then expectTrue("Fenster-OnUpdate getauscht", timerWindow._scripts.OnUpdate ~= plainOnUpdate) end

wow.fire("PLAYER_REGEN_ENABLED")
wow.fire("PLAYER_REGEN_ENABLED")
local found
for _, item in ipairs(Profiler.Results()) do
  if item.key:find("event PLAYER_REGEN_ENABLED profiler_test.lua", 1, true) then found = item end
end
expectTrue("Handler mit Herkunft gemessen", found)
if found then
  expect("zwei Aufrufe", found.count, 2)
  expectNear("Summe", found.ms, 10)
  expectNear("Maximum", found.max, 5)
end

-- Aufgaben, Zähler-Listener und Fenster laufen auch über den Profiler
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
wow.update(1)
local kinds = {}
for _, item in ipairs(Profiler.Results()) do kinds[item.key:match("^(%S+)")] = true end
expectTrue("Aufgaben gemessen", kinds.task)
expectTrue("Listener gemessen", kinds.call)
expectTrue("Fenster gemessen", kinds.onupdate)

-- Fehler bleiben Fehler (Handler des Clients), die übrigen Handler laufen weiter
local after
addon.RegisterEvent("PLAYER_REGEN_DISABLED", function() error("kaputt") end)
addon.RegisterEvent("PLAYER_REGEN_DISABLED", function() after = true end)
wow.fire("PLAYER_REGEN_DISABLED")
expect("Fehler gemeldet", #wow.errors, 1)
expect("nächster Handler läuft", after, true)
wow.errors = {}

-- Bericht: Chat und Debug-Log
SlashCmdList.LEVELTIMER("debug log")
local before = #wow.printed
SlashCmdList.LEVELTIMER("debug perf report 3")
local reportLines = 0
for i = before + 1, #wow.printed do
  if wow.printed[i]:find("[debug] perf:", 1, true) then reportLines = reportLines + 1 end
end
expect("Kopfzeile + 3 Einträge", reportLines, 4)
local logged = 0
for _, line in ipairs(addon.DebugLog.Lines()) do
  if line:find('"area":"perf"', 1, true) then logged = logged + 1 end
end
expectTrue("ins Debug-Log geschrieben", logged > 3)
SlashCmdList.LEVELTIMER("debug log")

SlashCmdList.LEVELTIMER("debug perf reset")
expect("zurückgesetzt", #Profiler.Results(), 0)

SlashCmdList.LEVELTIMER("debug perf off")
expect("aus", Profiler.IsEnabled(), false)
expect("SafeCall zurück", addon.SafeCall, plainSafeCall)
if plainOnUpdate then expect("Fenster-OnUpdate zurück", timerWindow._scripts.OnUpdate, plainOnUpdate) end
wow.fire("PLAYER_REGEN_ENABLED")
expect("aus: nichts mehr gemessen", #Profiler.Results(), 0)
