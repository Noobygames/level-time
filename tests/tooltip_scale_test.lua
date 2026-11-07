-- Tooltip-Größe (tooltipScale): Spiel-Tooltips skaliert, 1 = Blizzard, zurück auf den vorherigen Wert
ItemRefTooltip = CreateFrame("GameTooltip", "ItemRefTooltip")
GameTooltip:SetScale(1)
ItemRefTooltip:SetScale(0.9)  -- eigener Wert des Clients bleibt das Original

wow.login()
expect("Standard: unverändert", GameTooltip:GetScale(), 1)
addon.Set("tooltipScale", 1.5)
expectNear("größer", GameTooltip:GetScale(), 1.5)
expectNear("auch Link-Tooltip", ItemRefTooltip:GetScale(), 1.5)
addon.Set("tooltipScale", 9)
expectNear("begrenzt", GameTooltip:GetScale(), addon.Tooltip.MAX_SCALE)
addon.Set("tooltipScale", 1)
expectNear("zurück", GameTooltip:GetScale(), 1)
expectNear("Link-Tooltip zurück auf sein Original", ItemRefTooltip:GetScale(), 0.9)
