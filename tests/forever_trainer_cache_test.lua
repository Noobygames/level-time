-- Lehrer-Cache (WoW Forever): Fähigkeiten pro Level merken, im Level-Up-Fenster zeigen.
local Cache = addon.TrainerCache

wow.login({ level = 10 })
expect("verfügbar", Cache.IsAvailable(), true)
expect("leer", Cache.Count(), 0)

wow.state.trainer.services = {
  { name = "Warrior", serviceType = "header", texture = nil, reqLevel = 0, subText = "" },
  { name = "Heldenhafter Stoß", serviceType = "available", texture = "Interface\\Icons\\Ability_Rogue_Ambush", reqLevel = 12,
    subText = "Rang 2" },
  { name = "Zerschmettern", serviceType = "unavailable", texture = "Interface\\Icons\\Ability_Warrior_Sunder", reqLevel = 12,
    subText = "" },
  { name = "Spaltung", serviceType = "unavailable", texture = "Interface\\Icons\\Ability_Warrior_Cleave", reqLevel = 20, subText = "" },
}
wow.fire("TRAINER_SHOW")
expect("drei gemerkt, Überschrift nicht", Cache.Count(), 3)
local twelve = Cache.ForLevel(12)
expect("zwei auf Level 12", #twelve, 2)
expect("sortiert nach Name", twelve[1].name, "Heldenhafter Stoß")
expect("Symbol gemerkt", twelve[1].icon, "Interface\\Icons\\Ability_Rogue_Ambush")
expect("anderes Level", #Cache.ForLevel(20), 1)
expect("kein Treffer", #Cache.ForLevel(14), 0)

-- Erneuter Besuch ergänzt, ersetzt nicht
wow.fire("TRAINER_UPDATE")
expect("keine Doppelten", Cache.Count(), 3)

-- Berufslehrer werden ignoriert
wow.state.trainer.tradeskill = true
wow.state.trainer.services = { { name = "Schmieden", serviceType = "available", texture = "x", reqLevel = 5, subText = "" } }
wow.fire("TRAINER_SHOW")
expect("Berufslehrer ignoriert", Cache.Count(), 3)
wow.state.trainer.tradeskill = false

-- Level-Up auf 12: Fenster mit zwei Fähigkeiten
wow.state.healthMax = 1290
wow.levelUp(12, nil, { health = 90 })
wow.runTimers()
expect("Fenster sichtbar", LevelTimerLevelUp:IsShown(), true)
expect("Fehlerfrei", #wow.errors, 0)
