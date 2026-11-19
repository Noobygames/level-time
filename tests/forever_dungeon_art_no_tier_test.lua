-- Dungeonbilder (LT-393): Kompendium nie geöffnet = EJ_GetCurrentTier() 0; EJ_SelectTier(0) wirft im Client einen
-- Fehler und darf beim Wiederherstellen nicht gerufen werden.
local DungeonArt = addon.DungeonArt
local journal = { tier = 0 }  -- Tabelle statt Locals (gopher-lua)
function EJ_GetNumTiers() return 1 end
function EJ_GetCurrentTier() return journal.tier end
function EJ_SelectTier(tier)
  if tier < 1 then error("Usage: EJ_SelectTier(index) Invalid index " .. tier) end
  journal.tier = tier
end
function EJ_GetInstanceByIndex(index)
  if index > 1 then return nil end
  return 1, "Todesminen", "", "bg", "button36", "lore36", nil, 0, "", false, 36
end

wow.login()
expect("Bild trotz Erweiterung 0", (DungeonArt.ForMap(36, 416, 96) or {}).texture, "lore36")
