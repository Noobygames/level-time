-- Eckige Minimap (minimapSquare): Maske eckig, runder Rahmen unsichtbar, GetMinimapShape, Blizzards neue Maske wird
-- überschrieben; aus = runde Standardmaske, Rahmen zurück
function Minimap:SetMaskTexture(mask) self._mask = mask end
MinimapCompassTexture = Minimap:CreateTexture()
MinimapCompassTexture:SetAlpha(1)
GetMinimapShape = nil

wow.login()
expect("aus: Maske unberührt", rawget(Minimap, "_mask"), nil)

addon.Set("minimapSquare", true)
expect("eckige Maske", Minimap._mask, addon.MinimapTweaks.SQUARE_MASK)
expect("runder Rahmen unsichtbar", MinimapCompassTexture:GetAlpha(), 0)
expect("Form für andere Addons", GetMinimapShape(), "SQUARE")
Minimap:SetMaskTexture("blizzard-round")
expect("Blizzards Maske überschrieben", Minimap._mask, addon.MinimapTweaks.SQUARE_MASK)

addon.Set("minimapSquare", false)
expect("runde Standardmaske", Minimap._mask, addon.MinimapTweaks.ROUND_MASKS.retail)
expect("Rahmen zurück", MinimapCompassTexture:GetAlpha(), 1)
expect("Form wieder rund", GetMinimapShape(), "ROUND")
Minimap:SetMaskTexture("blizzard-round")
expect("aus: Blizzard darf", Minimap._mask, "blizzard-round")
