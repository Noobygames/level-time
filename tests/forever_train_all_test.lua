-- Knopf "Alles lernen" im Lehrerfenster (WoW Forever: Art der Zeile an zweiter Stelle von GetTrainerServiceInfo)
local L = addon.L

wow.login({ level = 20 })
wow.state.trainer.services = {
  { name = "Heilende Woge", serviceType = "available", reqLevel = 20, subText = "Rang 4", cost = 1800 },
  { name = "Frostschock", serviceType = "unavailable", reqLevel = 22, subText = "Rang 2", cost = 2200 },
  { name = "Blitzschlag", serviceType = "available", reqLevel = 20, subText = "Rang 5", cost = 1500 },
  { name = "Erdschock", serviceType = "used", reqLevel = 4, subText = "Rang 1", cost = 0 },
}

-- Lehrerfenster lädt beim ersten Besuch
ClassTrainerFrame = CreateFrame("Frame", "ClassTrainerFrame")
ClassTrainerTrainButton = CreateFrame("Button", "ClassTrainerTrainButton", ClassTrainerFrame)
wow.fire("ADDON_LOADED", "Blizzard_TrainerUI")

local function trainAllButton()
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == L.TRAIN_ALL
  end)
end

expectTrue("Knopf angelegt", trainAllButton() ~= nil)
expect("aus: versteckt", trainAllButton():IsShown(), false)
addon.Set("trainAllButton", true)
expect("an: sichtbar", trainAllButton():IsShown(), true)

local count, cost = addon.TrainAll.Available()
expect("zwei lernbar", count, 2)
expect("Kosten", cost, 3300)

trainAllButton()._scripts.OnClick(trainAllButton())
expect("zwei gelernt", #wow.trained, 2)
expect("von hinten", wow.trained[1], 3)
expect("dann vorn", wow.trained[2], 1)
expect("keine Fehler", #wow.errors, 0)
