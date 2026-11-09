-- Plündern (Reiter Komfort, System; je Einstellung, Standard aus):
--   fasterLoot       mit automatischem Plündern alle Beuteplätze sofort bei LOOT_READY aufnehmen, statt dass
--                    das Beutefenster sie nacheinander abarbeitet. Automatisch = CVar autoLootDefault, umgekehrt
--                    mit gedrückter Plündern-Taste (IsModifiedClick("AUTOLOOTTOGGLE")), wie in Blizzards LootFrame.
--   skipLootConfirm  Rückfragen beim Plündern ohne Dialog bestätigen: seelengebundene Beute (LOOT_BIND_CONFIRM ->
--                    ConfirmLootSlot) und Bedarf/Entzaubern beim Würfeln (CONFIRM_LOOT_ROLL,
--                    CONFIRM_DISENCHANT_ROLL -> ConfirmLootRoll), wie die Annehmen-Taste der StaticPopups.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    fasterLoot = false,
    skipLootConfirm = false,
  },
})
local Comfort = ns.Comfort

local Looting = {}
ns.Looting = Looting

local function isAutoLoot()
  local default = GetCVarBool and GetCVarBool("autoLootDefault")
  return default ~= IsModifiedClick("AUTOLOOTTOGGLE")
end

-- Von hinten nach vorn: aufgenommene Plätze verschieben die übrigen nicht
local function lootAll()
  if not ns.db.fasterLoot or not isAutoLoot() then return end
  for slot = GetNumLootItems(), 1, -1 do
    LootSlot(slot)
  end
end

local function confirmRoll(rollID, rollType)
  if not Comfort.IsActive("skipLootConfirm") then return end
  ConfirmLootRoll(rollID, rollType)
  StaticPopup_Hide("CONFIRM_LOOT_ROLL")
end

local function confirmBind(slot)
  if not Comfort.IsActive("skipLootConfirm") then return end
  ConfirmLootSlot(slot)
  StaticPopup_Hide("LOOT_BIND")
end

ns.RegisterEvent("LOOT_READY", lootAll)
ns.RegisterEvent("CONFIRM_LOOT_ROLL", confirmRoll)
ns.RegisterEvent("CONFIRM_DISENCHANT_ROLL", confirmRoll)
ns.RegisterEvent("LOOT_BIND_CONFIRM", confirmBind)
