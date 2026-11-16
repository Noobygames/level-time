-- Grafikdetails (Roadmap 442) gibt es nur in WoW Forever: in Retail keine Unterseite, CVars unberührt.
wow.state.cvars = { groundEffectDist = "100" }
wow.login({ level = 20 })
expect("nicht verfügbar", addon.ForeverGraphics.IsAvailable(), false)
addon.Set("foreverGraphics", true)
expect("CVar unberührt", wow.state.cvars.groundEffectDist, "100")
-- Beyond Ultra (Schalter FOREVER_GRAPHICS) wird in Retail nicht gebaut
local found = false
for _, entry in ipairs(addon.OptionsWindow.Search(addon.L.FOREVER_GRAPHICS)) do
  if entry.tipKey == "FOREVER_GRAPHICS_TIP" then found = true end
end
expect("kein Beyond-Ultra-Schalter", found, false)
expect("keine Fehler", #wow.errors, 0)
