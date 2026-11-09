-- Bildschirmeffekte und Wetter (Reiter Komfort, System), je Einstellung, Standard aus. Alles über CVars.lua: beim
-- Einschalten wird der Wert des Spielers gemerkt, beim Ausschalten zurückgesetzt; aus = CVar unberührt.
-- CVar-Namen und Standardwerte aus warcraft.wiki.gg (Console variables, Retail- und Classic-Liste), in allen Clients:
--   noDrunkenHaze     ffxGlow = 0 ("full screen glow effect"; der Rausch-Schleier ist dieser Vollbild-Glanz)
--   noScreenEffects   ffxDeath = 0 (grauer Bildschirm als Geist), ffxNether = 0 (Nether-Effekt, z.B. Verbannung)
--   setWeatherDensity weatherDensity und RAIDweatherDensity (Grafikstufe für Schlachtzüge) = db.weatherDensity,
--                     0 (kein Wetter) bis 3 (Classic-Standard)
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    noDrunkenHaze = false,
    noScreenEffects = false,
    setWeatherDensity = false,
    weatherDensity = 3,
  },
  ranges = {
    weatherDensity = { 0, 3 },
  },
})

local ScreenEffects = {}
ns.ScreenEffects = ScreenEffects

ScreenEffects.MIN_WEATHER = 0
ScreenEffects.MAX_WEATHER = 3

local OFF = 0

-- Einstellung -> CVars mit ihrem Wert (Funktion, wenn er aus den Einstellungen kommt)
local OVERRIDES = {
  { setting = "noDrunkenHaze", cvars = { ffxGlow = OFF } },
  { setting = "noScreenEffects", cvars = { ffxDeath = OFF, ffxNether = OFF } },
  { setting = "setWeatherDensity", cvars = {
    weatherDensity = function(db) return db.weatherDensity end,
    RAIDweatherDensity = function(db) return db.weatherDensity end,
  } },
}

ns.RegisterApply(function(db)
  for _, override in ipairs(OVERRIDES) do
    for name, value in pairs(override.cvars) do
      if db[override.setting] == true then
        ns.CVars.Override(name, type(value) == "function" and value(db) or value)
      else
        ns.CVars.Restore(name)
      end
    end
  end
end)
