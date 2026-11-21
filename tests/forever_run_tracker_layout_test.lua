-- LT-401: Live-Tracker zeigt wenige Bosse ausgeklappt, sehr viele eingeklappt; Porträt hat einen Rahmen
local Tracker = addon.InstanceRunTracker

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
Tracker.Refresh()
local layout = Tracker.Layout()
expect("Todesminen: 8 Einträge (7 Bosse + Rar)", layout.bosses, 8)
expect("wenige Bosse: ausgeklappt", layout.expanded, true)
expect("Reihenabstand", layout.rowSpacing, 4)
expectTrue("Porträtrahmen", layout.portraitBorder)

wow.state.instance = { name = "Geschmolzener Kern", type = "raid", difficulty = 9, mapID = 409, maxPlayers = 40 }
wow.fire("PLAYER_ENTERING_WORLD")
Tracker.Refresh()
layout = Tracker.Layout()
expectTrue("viele Bosse: mehr als die Schwelle", layout.bosses > layout.collapseAbove)
expect("viele Bosse: eingeklappt", layout.expanded, false)
