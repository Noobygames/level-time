-- Grafikdetails für WoW Forever (Roadmap 442, Reiter Komfort > Beyond Ultra, Hauptschalter foreverGraphics, Standard
-- aus): Sichtweite von Gras, Objekten und Gelände, Spiegelungen und Nachschärfen über CVars, die das Grafikmenü von
-- Forever nicht anbietet. Alles über CVars.lua: beim Einschalten wird der Wert des Spielers gemerkt, beim Ausschalten
-- zurückgesetzt; aus = CVar unberührt. Unbekannte CVars übergeht CVars.Override.
-- CVar-Namen und Client-Standards aus warcraft.wiki.gg (Console variables); die Bereiche sind praktische Grenzen für
-- die Regler, der Client kann andere haben. Empfohlen = größte Sichtweite ohne extreme Werte (Entwurf des Besitzers).
-- Je Regler eine Einstellung (Standard = Client-Standard), "Empfohlene Werte" setzt alle auf recommended.
local _, ns = ...

local ForeverGraphics = {}
ns.ForeverGraphics = ForeverGraphics

local SHARPEN_CVAR = "ResampleAlwaysSharpen"
local SHARPEN_ON, SHARPEN_OFF = 1, 0

-- Regler: Einstellung, CVar, Bereich, Schrittweite, Client-Standard, empfohlener Wert
ForeverGraphics.SLIDERS = {
  { label = "GRAPHICS_GROUND_DENSITY", setting = "graphicsGroundDensity", cvar = "groundEffectDensity",
    min = 16, max = 256, step = 1, default = 16, recommended = 256 },
  { label = "GRAPHICS_GROUND_DISTANCE", setting = "graphicsGroundDistance", cvar = "groundEffectDist",
    min = 40, max = 500, step = 5, default = 70, recommended = 500 },
  { label = "GRAPHICS_GROUND_FADE", setting = "graphicsGroundFade", cvar = "groundEffectFade",
    min = 0, max = 500, step = 5, default = 70, recommended = 370 },
  { label = "GRAPHICS_OBJECT_FADE", setting = "graphicsObjectFade", cvar = "lodObjectFadeScale",
    min = 50, max = 300, step = 5, default = 100, recommended = 200 },
  -- kleiner = mehr kleine Objekte in der Ferne (kostet Bildrate)
  { label = "GRAPHICS_OBJECT_CULL", setting = "graphicsObjectCull", cvar = "lodObjectCullSize",
    min = 1, max = 100, step = 1, default = 15, recommended = 8 },
  { label = "GRAPHICS_TERRAIN_DISTANCE", setting = "graphicsTerrainDistance", cvar = "terrainLodDist",
    min = 100, max = 2000, step = 10, default = 400, recommended = 1000 },
  { label = "GRAPHICS_REFLECTIONS", setting = "graphicsReflections", cvar = "reflectionMode",
    min = 0, max = 3, step = 1, default = 3, recommended = 3 },
}
ForeverGraphics.SHARPEN = { label = "GRAPHICS_SHARPEN", setting = "graphicsSharpen", default = false,
  recommended = true }

local defaults = { foreverGraphics = false, [ForeverGraphics.SHARPEN.setting] = ForeverGraphics.SHARPEN.default }
local ranges = {}
for _, slider in ipairs(ForeverGraphics.SLIDERS) do
  defaults[slider.setting] = slider.default
  ranges[slider.setting] = { slider.min, slider.max }
end
ns.Database.RegisterDefaults({ settings = defaults, ranges = ranges })

function ForeverGraphics.IsAvailable()
  return ns.Client.IsForever()
end

-- CVar -> gewünschter Wert aus den Einstellungen
local function wantedValues(db)
  local values = { [SHARPEN_CVAR] = db[ForeverGraphics.SHARPEN.setting] and SHARPEN_ON or SHARPEN_OFF }
  for _, slider in ipairs(ForeverGraphics.SLIDERS) do values[slider.cvar] = db[slider.setting] end
  return values
end

-- Alle Regler und das Nachschärfen auf die empfohlenen Werte, Hauptschalter an
function ForeverGraphics.ApplyRecommended()
  for _, slider in ipairs(ForeverGraphics.SLIDERS) do ns.db[slider.setting] = slider.recommended end
  ns.db[ForeverGraphics.SHARPEN.setting] = ForeverGraphics.SHARPEN.recommended
  ns.db.foreverGraphics = true
  ns.ApplySettings()
end

-- CVar-Namen aller Einstellungen (für Debug-Checks)
function ForeverGraphics.CVarNames()
  local names = { SHARPEN_CVAR }
  for _, slider in ipairs(ForeverGraphics.SLIDERS) do names[#names + 1] = slider.cvar end
  return names
end

ns.RegisterApply(function(db)
  if not ForeverGraphics.IsAvailable() then return end
  local active = db.foreverGraphics == true
  for name, value in pairs(wantedValues(db)) do
    if active then
      ns.CVars.Override(name, value)
    else
      ns.CVars.Restore(name)
    end
  end
end)
