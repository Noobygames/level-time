-- Schiffe und Zeppeline (Roadmap 440): in Retail nicht verfügbar, auch mit eingeschaltetem Schalter wird nichts gelernt
C_Map = {
  GetBestMapForUnit = function() return 1454 end,
  GetMapInfo = function() return { name = "Orgrimmar" } end,
  GetPlayerMapPosition = function() return { GetXY = function() return 0.5, 0.5 end } end,
}
wow.login({ level = 20 })
addon.Set("transportTimers", true)
expect("Retail: nicht verfügbar", addon.Transports.IsAvailable(), false)
expect("Retail: nicht aktiv", addon.Transports.IsEnabled(), false)
wow.update(1)
wow.update(1)
expect("Retail: keine Strecken", next(addon.Transports.Data().routes), nil)
expect("Retail: nichts angezeigt", addon.TransportDisplay.Shown(), false)
expect("keine Fehler", #wow.errors, 0)
