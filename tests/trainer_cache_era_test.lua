-- Lehrer-Cache in Classic Era/TBC: andere Reihenfolge der Rückgabewerte von GetTrainerServiceInfo, Level und Symbol einzeln.
local Cache = addon.TrainerCache

wow.state.interface = 11509
wow.login({ level = 10 })
expect("Era: verfügbar", Cache.IsAvailable(), true)

wow.state.trainer.services = {
  { name = "Krieger", serviceType = "header", texture = nil, reqLevel = 0, subText = "" },
  { name = "Heldenhafter Stoß", serviceType = "available", texture = "Interface\Icons\Ability_Rogue_Ambush", reqLevel = 12, subText = "Rang 2" },
  { name = "Spaltung", serviceType = "unavailable", texture = "Interface\Icons\Ability_Warrior_Cleave", reqLevel = 20, subText = "" },
}
wow.fire("TRAINER_SHOW")
expect("zwei gemerkt", Cache.Count(), 2)
local entry = Cache.ForLevel(12)[1]
expect("Name", entry.name, "Heldenhafter Stoß")
expect("Rang", entry.rank, "Rang 2")
expect("Level", entry.level, 12)
expect("Symbol", entry.icon, "Interface\Icons\Ability_Rogue_Ambush")

-- Retail: keine Lehrerliste
wow.state.interface = 120105
expect("Retail: nicht verfügbar", Cache.IsAvailable(), false)
