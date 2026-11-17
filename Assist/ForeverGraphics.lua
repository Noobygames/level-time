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
local SHARPEN_ON = 1

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
  { label = "GRAPHICS_WEATHER", setting = "graphicsWeather", cvar = "weatherDensity",
    min = 0, max = 3, step = 1, default = 3, recommended = 3 },
  { label = "GRAPHICS_RIPPLES", setting = "graphicsRipples", cvar = "rippleDetail",
    min = 0, max = 3, step = 1, default = 2, recommended = 3 },
  { label = "GRAPHICS_SUNSHAFTS", setting = "graphicsSunshafts", cvar = "sunshafts",
    min = 0, max = 3, step = 1, default = 2, recommended = 3 },
}
-- HDR (nur mit HDR-Monitor und Windows-HDR): Schalter + Regler; die Regler wirken nur bei eingeschaltetem HDR
-- und setzen die useHDR*-Begleiter mit (companion), damit der Client den Wert beachtet.
ForeverGraphics.HDR = { label = "GRAPHICS_HDR", setting = "graphicsHdr", cvar = "HDROutput", default = false }
ForeverGraphics.HDR_SLIDERS = {
  { label = "GRAPHICS_HDR_PEAK", setting = "graphicsHdrPeak", cvar = "HDRPeakBrightness", companion = "useHDRPeakBrightness",
    min = 100, max = 2000, step = 50, default = 400, recommended = 400 },
  { label = "GRAPHICS_HDR_WHITE", setting = "graphicsHdrWhite", cvar = "HDRBrightness", companion = "useHDRBrightness",
    min = 50, max = 1000, step = 10, default = 203, recommended = 203 },
  { label = "GRAPHICS_HDR_FACTOR", setting = "graphicsHdrFactor", cvar = "HDRFactor",
    min = 1, max = 2, step = 0.1, default = 2, recommended = 1.3, format = "%.1f" },
}
ForeverGraphics.PAUSE = { label = "GRAPHICS_PAUSE_INSTANCES", setting = "graphicsPauseInstances", default = false }
ForeverGraphics.SHARPEN = { label = "GRAPHICS_SHARPEN", setting = "graphicsSharpen", default = false,
  recommended = true }

local defaults = {
  foreverGraphics = false,
  [ForeverGraphics.SHARPEN.setting] = ForeverGraphics.SHARPEN.default,
  [ForeverGraphics.HDR.setting] = ForeverGraphics.HDR.default,
  [ForeverGraphics.PAUSE.setting] = ForeverGraphics.PAUSE.default,
}
local ranges = {}
for _, list in ipairs({ ForeverGraphics.SLIDERS, ForeverGraphics.HDR_SLIDERS }) do
  for _, slider in ipairs(list) do
    defaults[slider.setting] = slider.default
    ranges[slider.setting] = { slider.min, slider.max }
  end
end
ns.Database.RegisterDefaults({ settings = defaults, ranges = ranges })

function ForeverGraphics.IsAvailable()
  return ns.Client.IsForever()
end

-- Pause in Instanzen: Bildrate vor Grafikdetails (Dungeon, Raid, Schlachtfeld, Arena)
local function isPaused(db)
  return db[ForeverGraphics.PAUSE.setting] == true and IsInInstance() == true
end

-- CVar -> gewünschter Wert aus den Einstellungen. Nachschärfen und HDR wirken auch ohne Hauptschalter und Pause
-- (kosten kaum Bildrate); eingeschaltet setzen sie die CVar, ausgeschaltet bleibt der Wert des Spielers.
-- Die Sichtweite-Regler nur mit Hauptschalter und außerhalb der Pause.
local function wantedValues(db)
  local values = {}
  if db[ForeverGraphics.SHARPEN.setting] then values[SHARPEN_CVAR] = SHARPEN_ON end
  if db.foreverGraphics == true and not isPaused(db) then
    for _, slider in ipairs(ForeverGraphics.SLIDERS) do values[slider.cvar] = db[slider.setting] end
  end
  if db[ForeverGraphics.HDR.setting] then
    values[ForeverGraphics.HDR.cvar] = 1
    for _, slider in ipairs(ForeverGraphics.HDR_SLIDERS) do
      values[slider.cvar] = db[slider.setting]
      if slider.companion then values[slider.companion] = 1 end
    end
  end
  return values
end

-- Alle CVars, die diese Seite anfasst (zum Zurücksetzen, wenn aus, pausiert oder HDR aus)
local function allCVarNames()
  local names = { SHARPEN_CVAR, ForeverGraphics.HDR.cvar }
  for _, slider in ipairs(ForeverGraphics.SLIDERS) do names[#names + 1] = slider.cvar end
  for _, slider in ipairs(ForeverGraphics.HDR_SLIDERS) do
    names[#names + 1] = slider.cvar
    if slider.companion then names[#names + 1] = slider.companion end
  end
  return names
end

-- Alle Regler und das Nachschärfen auf die empfohlenen Werte, Hauptschalter an
function ForeverGraphics.ApplyRecommended()
  for _, slider in ipairs(ForeverGraphics.SLIDERS) do ns.db[slider.setting] = slider.recommended end
  ns.db[ForeverGraphics.SHARPEN.setting] = ForeverGraphics.SHARPEN.recommended
  -- HDR-Regler bekommen nur ihre Vorschläge; HDR selbst bleibt Entscheidung des Spielers (braucht HDR-Monitor)
  for _, slider in ipairs(ForeverGraphics.HDR_SLIDERS) do ns.db[slider.setting] = slider.recommended end
  ns.db.foreverGraphics = true
  ns.ApplySettings()
end

-- CVar-Namen aller Einstellungen (für Debug-Checks)
function ForeverGraphics.CVarNames()
  return allCVarNames()
end

ns.RegisterApply(function(db)
  if not ForeverGraphics.IsAvailable() then return end
  local wanted = wantedValues(db)
  for _, name in ipairs(allCVarNames()) do
    if wanted[name] ~= nil then
      ns.CVars.Override(name, wanted[name])
    else
      ns.CVars.Restore(name)
    end
  end
end)

-- Instanz betreten oder verlassen: Pause neu bewerten
ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
  if ForeverGraphics.IsAvailable() and ns.db.graphicsPauseInstances then ns.ApplySettings() end
end)
