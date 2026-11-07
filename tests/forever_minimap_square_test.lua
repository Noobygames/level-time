-- Eckige Minimap in WoW Forever: ausschalten lässt Blizzard Maske und Rahmen selbst setzen (UpdateMinimapConfig)
function Minimap:SetMaskTexture(mask) self._mask = mask end
MinimapCluster = CreateFrame("Frame", "MinimapCluster")
function MinimapCluster:UpdateMinimapConfig() Minimap:SetMaskTexture("ui-hud-minimap-frame-generic-mask") end

wow.login()
addon.Set("minimapSquare", true)
expect("eckig", Minimap._mask, addon.MinimapTweaks.SQUARE_MASK)
addon.Set("minimapSquare", false)
expect("Blizzards eigene Maske", Minimap._mask, "ui-hud-minimap-frame-generic-mask")
