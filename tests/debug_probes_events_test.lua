-- Debug-Proben (Core/DebugProbes.lua) hängen nur bei eingeschaltetem Debug-Log an Events und Aufgaben;
-- ausgeschaltet kosten sie nichts. /lt debug check findet unbekannte Events auch bei ausgeschaltetem Log.
local PROBE_ONLY_EVENT = "UNIT_THREAT_SITUATION_UPDATE"  -- nur die Proben hören darauf

local function registered(event)
  return wow.findFrame(function(frame) return frame._events[event] == true end) ~= nil
end

local function probeTaskRan()
  for _, item in ipairs(addon.Profiler.Results()) do
    if item.key:find("^task DebugProbes%.lua") then return true end
  end
  return false
end

wow.login()
expect("Log aus: Proben-Event nicht angemeldet", registered(PROBE_ONLY_EVENT), false)
addon.Profiler.SetEnabled(true)
wow.update(61)
expect("Log aus: Proben-Aufgaben laufen nicht", probeTaskRan(), false)

SlashCmdList.LEVELTIMER("debug log")
expect("Log an: angemeldet", registered(PROBE_ONLY_EVENT), true)
wow.update(61)
expect("Log an: Proben-Aufgaben laufen", probeTaskRan(), true)
local before = #addon.DebugLog.Lines()
wow.fire(PROBE_ONLY_EVENT, "player")
expectTrue("Log an: Probe schreibt", #addon.DebugLog.Lines() > before)
-- Roadmap 378: gleiche Bedrohung nur einmal, nur die Bedrohungslage (kein voller Kampf-Schnappschuss)
before = #addon.DebugLog.Lines()
for _ = 1, 5 do wow.fire(PROBE_ONLY_EVENT, "player") end
expect("gleiche Bedrohung: nicht noch einmal", #addon.DebugLog.Lines(), before)
-- CVar-Änderungen: dieselbe fremde Änderung kurz hintereinander nur einmal
before = #addon.DebugLog.Lines()
for _ = 1, 3 do wow.fire("CVAR_UPDATE", "cameraDistanceMaxZoomFactor", "2.6") end
expect("fremde CVar: eine Zeile", #addon.DebugLog.Lines(), before + 1)
expect("eigene Änderung läuft nicht", addon.CVars.IsWriting(), false)

SlashCmdList.LEVELTIMER("debug log")
expect("Log wieder aus: abgemeldet", registered(PROBE_ONLY_EVENT), false)
addon.Profiler.Reset()
wow.update(61)
expect("Log wieder aus: Aufgaben still", probeTaskRan(), false)
addon.Profiler.SetEnabled(false)

-- Prüfbefehl bei ausgeschaltetem Log: Kopfzeile mit Proben, danach bleibt alles abgemeldet
SlashCmdList.LEVELTIMER("debug check")
local probeLine
for _, line in ipairs(addon.DebugLog.Lines()) do
  if line:find('"area":"probe"', 1, true) and line:find('"apis"', 1, true) then probeLine = line end
end
expectTrue("Prüfung schreibt die Proben-Zeile", probeLine)
expect("nach der Prüfung abgemeldet", registered(PROBE_ONLY_EVENT), false)
