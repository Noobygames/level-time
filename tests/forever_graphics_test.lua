-- Grafikdetails (Roadmap 442, nur WoW Forever): aus = CVars unberührt, an = Werte der Regler, Regler wirken sofort,
-- empfohlene Werte, aus = Originale zurück, Unterseite mit Button.
wow.state.cvars = {
  groundEffectDensity = "64", groundEffectDist = "100", groundEffectFade = "70", lodObjectFadeScale = "100",
  lodObjectCullSize = "15", terrainLodDist = "500", reflectionMode = "1", ResampleAlwaysSharpen = "0",
}
local cvars = wow.state.cvars

wow.login({ level = 20 })
local ForeverGraphics = addon.ForeverGraphics
expectTrue("verfügbar in Forever", ForeverGraphics.IsAvailable())
expect("Standard aus", addon.db.foreverGraphics, false)
expect("Standard Gras-Sichtweite = Client-Standard", addon.db.graphicsGroundDistance, 70)

-- Aus: nichts geändert
addon.Set("graphicsGroundDistance", 300)
expect("aus: Regler ändert nichts", cvars.groundEffectDist, "100")
expect("aus: nichts gemerkt", LevelTimerDB.cvarOriginals, nil)

-- An: alle Werte aus den Einstellungen
addon.Set("foreverGraphics", true)
expect("Gras-Sichtweite gesetzt", cvars.groundEffectDist, "300")
expect("Gras-Dichte auf Standard", cvars.groundEffectDensity, "16")
expect("Spiegelungen", cvars.reflectionMode, "3")
expect("Nachschärfen aus", cvars.ResampleAlwaysSharpen, "0")
addon.Set("graphicsTerrainDistance", 1500)
expect("Regler wirkt sofort", cvars.terrainLodDist, "1500")
addon.Set("graphicsSharpen", true)
expect("Nachschärfen an", cvars.ResampleAlwaysSharpen, "1")

-- Empfohlene Werte
addon.Set("foreverGraphics", false)
ForeverGraphics.ApplyRecommended()
expect("empfohlen: Schalter an", addon.db.foreverGraphics, true)
for _, slider in ipairs(ForeverGraphics.SLIDERS) do
  expect("empfohlen: " .. slider.cvar, cvars[slider.cvar], tostring(slider.recommended))
end
expect("empfohlen: Nachschärfen", cvars.ResampleAlwaysSharpen, "1")

-- Aus: Originale des Spielers zurück
addon.Set("foreverGraphics", false)
expect("Original Gras-Dichte", cvars.groundEffectDensity, "64")
expect("Original Gelände", cvars.terrainLodDist, "500")
expect("Original Spiegelungen", cvars.reflectionMode, "1")
expect("Original Nachschärfen", cvars.ResampleAlwaysSharpen, "0")
expect("nichts mehr gemerkt", LevelTimerDB.cvarOriginals, nil)

-- Unterseite in den Einstellungen mit Reglern und Button
addon.OptionsWindow.ShowPage("COMFORT_PAGE_GRAPHICS_DETAIL")
wow.clickOption("GRAPHICS_RECOMMENDED")
expect("Button setzt empfohlene Werte", cvars.groundEffectDist, "500")

expect("keine Fehler", #wow.errors, 0)
