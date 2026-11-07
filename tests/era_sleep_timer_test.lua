-- Schlafsack-Timer gibt es nur in WoW Forever: in Classic Era startet /schlafen nichts, keine Einstellung.
local SleepTimer = addon.SleepTimer
local BAG = 211527

wow.state.itemIcons[BAG] = 133650
wow.state.itemCounts = { [BAG] = 1 }
wow.login({ level = 20 })
expect("Era: nicht verfügbar", SleepTimer.IsAvailable(), false)
SleepTimer.Start("emote")
expect("Era: kein Start", SleepTimer.State(), nil)
expect("Era: keine Anzeige", LevelTimerSleep:IsShown(), false)
expect("Era: Einstellung nicht in den Optionen", #addon.OptionsWindow.Search(addon.L.SLEEP_TIMER_TOGGLE), 0)
expect("keine Lua-Fehler", #wow.errors, 0)
