-- Schwungbalken (Roadmap 452): in Retail nicht verfügbar (Kampflog geheim), keine Einstellung
wow.login({ level = 20 })
expect("Retail: nicht verfügbar", addon.SwingTimer.IsAvailable(), false)
expect("Retail: Einstellung nicht in den Optionen", #addon.OptionsWindow.Search(addon.L.SWING_TIMER), 0)
addon.Set("swingTimer", true)
wow.fire("PLAYER_ENTER_COMBAT")
expect("Retail: kein Schwung", addon.SwingTimer.Remaining(addon.SwingTimer.MAIN), nil)
expect("keine Lua-Fehler", #wow.errors, 0)
