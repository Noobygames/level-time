-- Debug-Log ist nach jedem Login wieder an, auch wenn es zuvor ausgeschaltet war ("off" gilt nur bis zum /reload)
LevelTimerDebugLog = { enabled = false, lines = {} }
wow.login()
expect("nach dem Login wieder an", addon.DebugLog.IsEnabled(), true)
expectTrue("Login-Kopfzeile geschrieben", #LevelTimerDebugLog.lines > 0)
expect("keine Lua-Fehler", #wow.errors, 0)
