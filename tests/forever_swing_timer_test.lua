-- Schwungbalken (Roadmap 452), WoW Forever ohne eigene Kampflog-Schläge: Haupthand ab PLAYER_ENTER_COMBAT im Takt
local SwingTimer = addon.SwingTimer

wow.state.attackSpeed = { 2 }
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
expect("keine Lua-Fehler", #wow.errors, 0)
