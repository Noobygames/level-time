-- Schlafsack-Timer gibt es nur in WoW Forever: in Retail startet weder /schlafen noch das Item etwas.
local SleepTimer = addon.SleepTimer
local BAG = 211527

wow.state.itemIcons[BAG] = 133650
wow.state.itemCounts = { [BAG] = 1 }
wow.state.itemSpells = { [BAG] = { name = "Schlafsack", id = 436000 } }
wow.login({ level = 20 })
expect("Retail: nicht verfügbar", SleepTimer.IsAvailable(), false)
C_ChatInfo.PerformEmote("SLEEP")
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 436000)
expect("Retail: kein Start", SleepTimer.State(), nil)
expect("Retail: keine Anzeige", LevelTimerSleep:IsShown(), false)
expect("keine Lua-Fehler", #wow.errors, 0)
