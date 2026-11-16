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

-- LT-267: PLAYER_SWING (nur Forever) liefert Hand und Dauer; danach kein Ersatztakt mehr
wow.fire("PLAYER_SWING", 2.4, 0)
expectNear("PLAYER_SWING: Haupthand mit Client-Dauer", (SwingTimer.Remaining(SwingTimer.MAIN)), 2.4, 0.001)
wow.fire("PLAYER_SWING", 1.5, 1)
expectNear("PLAYER_SWING: Nebenhand", (SwingTimer.Remaining(SwingTimer.OFF)), 1.5, 0.001)
wow.fire("PLAYER_SWING", 3, 2)
expectNear("PLAYER_SWING: Fernkampf", (SwingTimer.Remaining(SwingTimer.RANGED)), 3, 0.001)
wow.fire("PLAYER_SWING", 2, wow.SECRET)
expect("Quelle der Schläge", SwingTimer.Status().swingSource, "player_swing")
wow.fire("PLAYER_ENTER_COMBAT")
wow.advance(3.5)
frame._scripts.OnUpdate(frame, 0.1)
expect("mit PLAYER_SWING kein Ersatztakt", SwingTimer.Remaining(SwingTimer.MAIN), nil)
wow.fire("PLAYER_LEAVE_COMBAT")

-- Blizzards eigene Schwungbalken (Roadmap 489, CVar showSwingTimer): aus, solange gewünscht; danach zurück
addon.Set("swingTimerHideBlizzard", true)
expect("Blizzard-Balken aus", wow.state.cvars.showSwingTimer, "0")
addon.Set("swingTimerHideBlizzard", false)
expect("Blizzard-Balken zurück", wow.state.cvars.showSwingTimer, "1")
addon.Set("swingTimerHideBlizzard", true)
addon.Set("swingTimer", false)
expect("Schwungbalken aus: Blizzard-Balken zurück", wow.state.cvars.showSwingTimer, "1")
expect("keine Lua-Fehler", #wow.errors, 0)
