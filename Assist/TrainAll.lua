-- Knopf "Alles lernen" im Klassenlehrer-Fenster (Einstellung trainAllButton, Standard aus; Reiter Komfort, Automatik):
-- lernt mit einem Klick alle Fähigkeiten, die gerade "available" sind. Tooltip mit Anzahl und Kosten; ausgegraut,
-- wenn nichts zu lernen ist. Nicht in Retail (keine Lehrerliste, siehe TrainerCache.IsAvailable).
-- Das Lehrerfenster ist das Blizzard-Addon Blizzard_TrainerUI (ClassTrainerFrame, Lern-Knopf ClassTrainerTrainButton);
-- es lädt beim ersten Lehrerbesuch (ADDON_LOADED). Käufe wie Blizzards Lern-Knopf: BuyTrainerService(i) im Klick
-- (Hardware-Ereignis), von hinten nach vorn, damit gelernte Zeilen die Nummern davor nicht verschieben.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    trainAllButton = false,
  },
})
local L = ns.L

local TrainAll = {}
ns.TrainAll = TrainAll

local TRAINER_ADDON = "Blizzard_TrainerUI"
local AVAILABLE = "available"
local BUTTON_HEIGHT = 22
local BUTTON_MIN_WIDTH = 80
local BUTTON_GAP = 2

local button

-- Anzahl und Gesamtkosten der lernbaren Fähigkeiten
function TrainAll.Available()
  local count, cost = 0, 0
  for index = 1, GetNumTrainerServices() do
    if ns.TrainerCache.ServiceType(index) == AVAILABLE then
      count = count + 1
      cost = cost + (GetTrainerServiceCost(index) or 0)
    end
  end
  return count, cost
end

function TrainAll.LearnAll()
  for index = GetNumTrainerServices(), 1, -1 do
    if ns.TrainerCache.ServiceType(index) == AVAILABLE then BuyTrainerService(index) end
  end
end

local function refresh()
  if not button then return end
  button:SetShown(ns.db.trainAllButton and not (IsTradeskillTrainer and IsTradeskillTrainer()))
  local count = TrainAll.Available()
  button:SetEnabled(count > 0)
  button:SetAlpha(count > 0 and 1 or 0.5)
end

local function createButton()
  if button or not ClassTrainerFrame or not ClassTrainerTrainButton then return end
  button = ns.Widgets.CreateButton(ClassTrainerFrame, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
    ns.Debug("comfort", "train all: %s", (TrainAll.Available()))
    TrainAll.LearnAll()
  end)
  button:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -BUTTON_GAP, 0)
  ns.Widgets.SetButtonText(button, L.TRAIN_ALL, BUTTON_MIN_WIDTH)
  ns.Widgets.AttachTooltip(button, function() return L.TRAIN_ALL end, function()
    local count, cost = TrainAll.Available()
    if count == 0 then return L.TRAIN_ALL_NOTHING end
    return string.format(L.TRAIN_ALL_SUMMARY, count, ns.Format.Money(cost))
  end)
  ClassTrainerFrame:HookScript("OnShow", refresh)
  refresh()
end

ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == TRAINER_ADDON and ns.TrainerCache.IsAvailable() then createButton() end
end)
ns.RegisterEvent("TRAINER_UPDATE", refresh)
ns.RegisterApply(function()
  if ns.db.trainAllButton and ns.TrainerCache.IsAvailable() then createButton() end
  refresh()
end)
