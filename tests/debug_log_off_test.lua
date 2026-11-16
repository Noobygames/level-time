-- Debug-Log bleibt aus, wenn der Spieler es ausgeschaltet hat, meldet das aber bei jedem Login einmal im Chat
local L = extractor.L
LevelTimerDebugLog = { enabled = false, lines = {} }
wow.login()
expect("bleibt aus", addon.DebugLog.IsEnabled(), false)
local reminded = false
for _, line in ipairs(wow.printed) do
  if line:find(L.DEBUG_LOG_OFF_REMINDER, 1, true) then reminded = true end
end
expectTrue("Hinweis beim Login", reminded)
expect("keine Lua-Fehler", #wow.errors, 0)
