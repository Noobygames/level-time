-- Dungeonbilder aus dem Dungeonkompendium (LT-393): Lore-Bild je Instanz-Karten-ID, sonst Kachelbild, Erweiterung
-- danach wiederhergestellt, ohne Kompendium-API nichts.
local DungeonArt = addon.DungeonArt
local journal = { tier = 2, selects = 0 }  -- Tabelle statt Locals (gopher-lua)
local TIERS = {
  [1] = { party = { { 1, "Todesminen", 36, "lore36", "button36" }, { 2, "Verlies", 34, nil, "button34" } } },
  [2] = { party = {}, raid = { { 3, "Geschmolzener Kern", 409, "lore409", "button409" } } },
}
function EJ_GetNumTiers() return #TIERS end
function EJ_GetCurrentTier() return journal.tier end
function EJ_SelectTier(tier) journal.tier, journal.selects = tier, journal.selects + 1 end
function EJ_GetInstanceByIndex(index, isRaid)
  local entry = (TIERS[journal.tier][isRaid and "raid" or "party"] or {})[index]
  if not entry then return nil end
  return entry[1], entry[2], "", "bg", entry[5], entry[4], nil, 0, "", false, entry[3]
end

wow.login()
local art = DungeonArt.ForMap(36, 416, 96)
expect("Lore-Bild", art and art.texture, "lore36")
expect("volle sichtbare Breite", art and art.right, 0.76171875)
expectTrue("mittiger Streifen", art and art.top > 0 and art.bottom < 0.65625 and art.bottom > art.top)
expect("ohne Lore das Kachelbild", (DungeonArt.ForMap(34, 416, 96) or {}).texture, "button34")
expect("Schlachtzug aus späterer Erweiterung", (DungeonArt.ForMap(409, 416, 96) or {}).texture, "lore409")
expect("unbekannte Instanz", DungeonArt.ForMap(999, 416, 96), nil)
expect("vorherige Erweiterung wieder gewählt", journal.tier, 2)
local selects = journal.selects
DungeonArt.ForMap(36, 416, 96)
expect("nur einmal gesammelt", journal.selects, selects)
expect("Anzahl", (DungeonArt.Count()), 3)
