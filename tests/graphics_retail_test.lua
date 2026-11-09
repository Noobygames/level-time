-- Grafikdetails (Roadmap 442) gibt es nur in WoW Forever: in Retail keine Unterseite, CVars unberührt.
wow.state.cvars = { groundEffectDist = "100" }
wow.login({ level = 20 })
expect("nicht verfügbar", addon.ForeverGraphics.IsAvailable(), false)
addon.Set("foreverGraphics", true)
expect("CVar unberührt", wow.state.cvars.groundEffectDist, "100")
local found = false
for _, key in ipairs(addon.OptionsWindow.PageKeys()) do
  if key == "COMFORT_PAGE_GRAPHICS_DETAIL" then found = true end
end
expect("keine Unterseite", found, false)
expect("keine Fehler", #wow.errors, 0)
