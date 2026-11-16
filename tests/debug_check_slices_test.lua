-- /lt debug check verteilt die Prüfungen auf mehrere Bilder (WoW bricht zu lange Skripte mit "script ran too long"
-- ab) und kürzt riesige Ergebnisse, statt sie ganz auszuschreiben (LT-316)
local DebugLog = addon.DebugLog
local L = extractor.L

local function lastPrint() return wow.printed[#wow.printed] end
local function lineWith(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return line end
  end
end

wow.login()
SlashCmdList.LEVELTIMER("debug log clear")

-- Riesiges Ergebnis (Beuteliste mit tausenden Einträgen): gekürzt, Größe begrenzt
local huge = {}
for i = 1, 5000 do huge["npc" .. i] = { i, { i, i + 1 }, "item" .. i } end
-- Breite hoch Tiefe: 40 x 40 x 40 Werte, weit über MAX_ENTRY_VALUES
local wide = {}
for i = 1, 40 do
  wide[i] = {}
  for j = 1, 40 do
    wide[i][j] = {}
    for k = 1, 40 do wide[i][j][k] = k end
  end
end
DebugLog.AddCheck("zz.huge", function() return huge, wide end)

-- Langsame Prüfungen: jede kostet 5 ms, zusammen weit über eine Scheibe
local slow = { ran = 0 }
local SLOW_CHECKS = 20
for i = 1, SLOW_CHECKS do
  DebugLog.AddCheck("zz.slow" .. i, function()
    slow.ran = slow.ran + 1
    wow.profileMs = wow.profileMs + 5
    return i
  end)
end
DebugLog.AddCheck("zz.broken", function() error("kaputt") end)

local donePrefix = L.DEBUG_CHECK_DONE:match("^[^%%]+")
SlashCmdList.LEVELTIMER("debug check")
expectTrue("läuft über mehrere Bilder", DebugLog.IsRunning())
expectTrue("noch nicht alle langsamen Prüfungen", slow.ran < SLOW_CHECKS)
expectTrue("noch keine Ergebniszeile", not (lastPrint() or ""):find(donePrefix, 1, true))

SlashCmdList.LEVELTIMER("debug check")
expect("zweiter Aufruf meldet laufende Prüfung", lastPrint():find(L.DEBUG_CHECK_RUNNING, 1, true) ~= nil, true)

local ticks = 0
while DebugLog.IsRunning() and ticks < 100 do
  wow.runTimers()
  ticks = ticks + 1
end
expect("fertig", DebugLog.IsRunning(), false)
expectTrue("mehrere Bilder", ticks >= 2)
expect("alle langsamen Prüfungen", slow.ran, SLOW_CHECKS)
expect("Ergebniszeile", lastPrint():find(donePrefix, 1, true) ~= nil, true)
expectTrue("Fehler einer Prüfung hält den Lauf nicht auf", lineWith('"name":"zz.broken"') and lineWith('kaputt'))
expectTrue("letzte langsame Prüfung geschrieben", lineWith('"name":"zz.slow' .. SLOW_CHECKS .. '"'))

local hugeLine = lineWith('"name":"zz.huge"')
expectTrue("riesiges Ergebnis geschrieben", hugeLine)
expectTrue("riesiges Ergebnis begrenzt", #hugeLine < 100000)
expectTrue("riesiges Ergebnis als gekürzt markiert", hugeLine:find(DebugLog.TRUNCATED, 1, true))
expect("keine Lua-Fehler", #wow.errors, 0)
