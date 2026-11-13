-- Schwungbalken (Roadmap 452), WoW Forever ohne eigene Kampflog-Schläge: Haupthand ab PLAYER_ENTER_COMBAT im Takt
local SwingTimer = addon.SwingTimer

wow.state.attackSpeed = { 2 }
wow.state.cvars = { showSwingTimer = "1" }
wow.login({ level = 20 })
expect("Forever: verfügbar", SwingTimer.IsAvailable(), true)
addon.Set("swingTimer", true)

wow.fire("PLAYER_ENTER_COMBAT")
expectNear("Ersatz: Haupthand startet", (SwingTimer.Remaining(SwingTimer.MAIN)), 2, 0.001)
expect("ohne Nebenhand nichts", SwingTimer.Remaining(SwingTimer.OFF), nil)

-- Schwung fällig: läuft im Kampf weiter
local frame = SwingTimer.Frame()
wow.advance(2.5)
frame._scripts.OnUpdate(frame, 0.1)
expectNear("Ersatz: nächster Schwung", (SwingTimer.Remaining(SwingTimer.MAIN)), 2, 0.001)

-- Angriff aus: Schwung endet
wow.fire("PLAYER_LEAVE_COMBAT")
wow.advance(2.5)
frame._scripts.OnUpdate(frame, 0.1)
expect("nach dem Kampf: kein Schwung", SwingTimer.Remaining(SwingTimer.MAIN), nil)
expect("Anzeige weg", frame:IsShown(), false)

-- Blizzards eigene Schwungbalken (Roadmap 489, CVar showSwingTimer): aus, solange gewünscht; danach zurück
addon.Set("swingTimerHideBlizzard", true)
expect("Blizzard-Balken aus", wow.state.cvars.showSwingTimer, "0")
addon.Set("swingTimerHideBlizzard", false)
expect("Blizzard-Balken zurück", wow.state.cvars.showSwingTimer, "1")
addon.Set("swingTimerHideBlizzard", true)
addon.Set("swingTimer", false)
expect("Schwungbalken aus: Blizzard-Balken zurück", wow.state.cvars.showSwingTimer, "1")
expect("keine Lua-Fehler", #wow.errors, 0)
