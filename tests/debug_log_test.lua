-- Dauerhaftes Debug-Log (im lokalen Data Extractor, nach Neuinstallation an): /lt debug log schreibt Debug-Zeilen, abgefangene Fehler, Ereignis-Proben und Schnappschüsse
-- als JSON-Zeilen in LevelTimerDebugLog, bleibt über Neuladen an und kürzt auf MAX_LINES; /lt debug check schreibt
-- alle Prüfungen einmal, auch bei ausgeschaltetem Log.
local DebugLog = addon.DebugLog
local L = extractor.L

local function lastPrint() return wow.printed[#wow.printed] end
local function hasLine(text)
  for _, line in ipairs(LevelTimerDebugLog.lines) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

wow.login()
expect("an nach Neuinstallation", DebugLog.IsEnabled(), true)
SlashCmdList.LEVELTIMER("debug log off")
SlashCmdList.LEVELTIMER("debug log clear")
expect("ausgeschaltet", DebugLog.IsEnabled(), false)
addon.Debug("test", "nicht geschrieben")
expect("aus: nichts geschrieben", DebugLog.LineCount(), 0)

-- JSON: Escapes, Zahlen, Listen mit Lücken, Objekte mit sortierten Schlüsseln, geheime Werte
expect("JSON Text", DebugLog.Encode('a"b\\c\nd'), '"a\\"b\\\\c\\nd"')
expect("JSON Objekt", DebugLog.Encode({ b = 1, a = true }), '{"a":true,"b":1}')
expect("JSON Liste", DebugLog.Encode({ 1, 2.5, "x" }), '[1,2.5,"x"]')
expect("JSON geheim", DebugLog.Encode(wow.SECRET), '"<secret>"')
expect("JSON unendlich", DebugLog.Encode(math.huge), "null")
-- Check-Ergebnisse (Eintrag > result > Liste > Struktur > Felder) kommen vollständig an
expect("JSON tief", DebugLog.Encode({ result = { { reminder = { spells = { { id = 1 } } } } } }),
  '{"result":[{"reminder":{"spells":[{"id":1}]}}]}')

-- Prüfung schreibt auch bei ausgeschaltetem Log, Fehler einer Prüfung halten die anderen nicht auf
SlashCmdList.LEVELTIMER("debug check")
expect("Prüfung gemeldet", lastPrint():find(L.DEBUG_CHECK_DONE:match("^[^%%]+"), 1, true) ~= nil, true)
expect("Prüfung mit Ergebnis", hasLine('"area":"check"') and hasLine('"name":"xp.state","result":[0,'), true)
expect("Prüfung mit Fehler", hasLine('"error":'), true)
expect("API-Probe", hasLine('"C_ChatInfo.InChatMessagingLockdown":"function"') and hasLine('"C_QuestLog.GetInfo":"nil"'), true)
expect("Text-Probe", hasLine('"COMBATLOG_XPGAIN_FIRSTPERSON":"%s stirbt'), true)
expect("keine Lua-Fehler", #wow.errors, 0)
SlashCmdList.LEVELTIMER("debug log clear")

SlashCmdList.LEVELTIMER("debug log")
expect("an", DebugLog.IsEnabled(), true)
expect("Meldung an", lastPrint():find(L.DEBUG_LOG_ON, 1, true) ~= nil, true)
expect("Kopfzeile", hasLine('"area":"session"') and hasLine('"reason":"enabled"'), true)

-- Debug-Zeilen ohne Chat-Logging, geheime Werte nur als Platzhalter
addon.Debug("test", "wert %s, geheim %s", 42, wow.SECRET)
expect("Debug-Zeile", hasLine('"area":"test","gt":'), true)
expect("Debug-Text", hasLine('"msg":"wert 42, geheim <secret>"'), true)
expect("nicht im Chat", lastPrint():find("wert 42", 1, true), nil)

-- Ereignis-Probe mit Argumenten (nil in der Mitte bleibt null) und Zustand
wow.fire("CHAT_MSG_SKILL", "Eure Fertigkeit in Kochkunst hat sich auf 5 erhöht.", nil, "x")
expect("Ereignis-Probe", hasLine('"args":["Eure Fertigkeit in Kochkunst hat sich auf 5 erhöht.",null,"x"]'), true)
wow.fire("PLAYER_XP_UPDATE", "player")
expect("Ereignis mit Zustand", hasLine('"event":"PLAYER_XP_UPDATE","gt":') and hasLine('"state":{"combat":false'), true)

-- Zusatzdaten zu Ereignissen (Ziel beim Zielwechsel)
wow.fire("PLAYER_TARGET_CHANGED")
expect("Ereignis mit Zusatzdaten", hasLine('"event":"PLAYER_TARGET_CHANGED","extra":{'), true)

-- Schnappschuss jede Minute, mit gezählten Zaubern des Spielers (fremde Einheiten zählen nicht)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 19705)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-2", 19705)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "target", "cast-3", 133)
wow.update(61)
expect("Schnappschuss", hasLine('"area":"snapshot","casts":{"19705":2}'), true)

-- Kampf-Probe: beim Kampfbeginn und alle 5 s im Kampf, geheime Werte als Platzhalter
wow.state.inCombat = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("Kampf-Probe", hasLine('"area":"combat"') and hasLine('"reason":"PLAYER_REGEN_DISABLED"'), true)
wow.update(5)
expect("Kampf-Probe im Takt", hasLine('"reason":"tick"'), true)
wow.state.inCombat = false

-- Abgefangener Fehler landet im Log (und beim Fehler-Handler des Clients)
addon.SafeCall(function() error("kaputt") end)
expect("Fehler im Log", hasLine('"area":"error"') and hasLine("kaputt"), true)
expect("Fehler beim Client", #wow.errors, 1)
wow.errors = {}

-- Über Neuladen an
wow.logout()
expect("Logout-Zeile", hasLine('"reason":"logout"'), true)
wow.login()
expect("bleibt an", DebugLog.IsEnabled(), true)
expect("Login-Zeile", hasLine('"reason":"login"'), true)

-- Status, Kürzen, Leeren
SlashCmdList.LEVELTIMER("debug log status")
expect("Status", lastPrint():find(string.format(L.DEBUG_LOG_STATUS, L.DEBUG_LOG_STATE_ON, DebugLog.LineCount(),
  DebugLog.MAX_LINES), 1, true) ~= nil, true)
for i = 1, DebugLog.MAX_LINES + 1100 do addon.Debug("fill", "%s", i) end
expect("gekürzt", DebugLog.LineCount() <= DebugLog.MAX_LINES + 1000, true)
expect("neueste bleibt", hasLine('"msg":"' .. (DebugLog.MAX_LINES + 1100) .. '"'), true)
SlashCmdList.LEVELTIMER("debug log clear")
expect("geleert", DebugLog.LineCount(), 0)

SlashCmdList.LEVELTIMER("debug log off")
expect("aus", DebugLog.IsEnabled(), false)
addon.Debug("test", "danach")
expect("aus: nichts mehr", DebugLog.LineCount(), 0)
