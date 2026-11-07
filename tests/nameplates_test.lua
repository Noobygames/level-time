-- Sichtbare Namensplaketten (Lib/NamePlates.lua): Menge aus NAME_PLATE_UNIT_ADDED/REMOVED, neu aufgebaut beim
-- Betreten der Welt; der Aggro-Hinweis prüft nur sie statt 40 Plätze.
local NamePlates = addon.NamePlates
wow.login({ level = 20 })

expect("vorberechnet", NamePlates.UNITS[7], "nameplate7")
expect("Ziel vorberechnet", NamePlates.TARGET_OF.nameplate7, "nameplate7target")
expect("zunächst keine", next(NamePlates.Active()), nil)

wow.state.units.nameplate3 = { name = "Hyäne", hostile = true, combat = true, tanking = true }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
expect("hinzugefügt", NamePlates.Active().nameplate3, true)

-- Aggro über die Plakette: Gegner hat den Spieler als Ziel
local me = { name = "Nerzal" }
wow.state.units.player = me
wow.state.units.nameplate3target = me
expect("Aggro über sichtbare Plakette", addon.AggroWarning.HasAggro(), true)

wow.fire("NAME_PLATE_UNIT_REMOVED", "nameplate3")
expect("entfernt", NamePlates.Active().nameplate3, nil)
expect("unsichtbare Plakette zählt nicht", addon.AggroWarning.HasAggro(), false)

-- Nach /reload kommen keine ADDED-Events für schon sichtbare Plaketten: Aufbau aus den Plätzen
wow.fire("PLAYER_ENTERING_WORLD", false, true)
expect("aus den Plätzen aufgebaut", NamePlates.Active().nameplate3, true)
expect("Aggro wieder erkannt", addon.AggroWarning.HasAggro(), true)
