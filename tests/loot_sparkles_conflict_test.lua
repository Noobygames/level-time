-- Beute-Glitzer neben einem Addon, das dieselben CVars steuert (ForeverLootSparkles, Lueur): nichts anfassen,
-- einmal im Chat sagen, warum. Ohne die Forever-CVar gibt es kein Quest-Gegenstand-Glitzern.
local LootSparkles = addon.LootSparkles
local L = addon.L

C_NamePlate = { GetNamePlateForUnit = function() return nil end }
UnitIsGameObject = function() return true end
SetUnitCursorTexture = function(texture)
  texture:SetTexture("Interface\\Cursor\\Mine")
  return true
end

local isLoaded = C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded = function(name) return name == "Lueur" or isLoaded(name) end

wow.state.cvars = { SoftTargetInteract = "1", SoftTargetNameplateInteract = "0", SoftTargetInteractRange = "10" }
local cvars = wow.state.cvars
LevelTimerDB = { lootSparkleOre = true, lootSparkleQuestItems = true }

wow.login({ level = 20 })
expect("Konflikt erkannt", LootSparkles.Conflict(), "Lueur")
expect("Konflikt: Soft-Targeting unberührt", cvars.SoftTargetInteract, "1")
expect("Konflikt: Plakette unberührt", cvars.SoftTargetNameplateInteract, "0")
expect("Konflikt: nichts gemerkt", LevelTimerDB.cvarOriginals, nil)
local told = 0
for _, line in ipairs(wow.printed) do
  if line:find(string.format(L.LOOT_SPARKLE_CONFLICT, "Lueur"), 1, true) then told = told + 1 end
end
expect("Konflikt: einmal im Chat", told, 1)

-- Retail/Classic: die CVar für Quest-Gegenstände gibt es nicht, also auch nichts zu setzen
expect("ohne Forever-CVar: nicht verfügbar", LootSparkles.HasQuestItemSparkle(), false)
expect("ohne Forever-CVar: nichts gesetzt", cvars.outlineModeShowLootEffectWhenDisabled, nil)
