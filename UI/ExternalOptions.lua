-- Einstellungsfenster anderer Addons (Level Time Goals): deren Seiten-Schlüssel reichen der Rechtsklick auf eine
-- Anzeige (Lib/Frames.lua, settingsPage) und der Knopf "Einstellungen" im Edit-Modus an ihr eigenes Fenster weiter
-- statt an das von Level Time.
--   ns.RegisterOptionsWindow({ pages = { [Seiten-Schlüssel] = true }, show(pageKey), toggle(pageKey) })
local _, ns = ...

local windows = {}  -- Seiten-Schlüssel -> Anmeldung

function ns.RegisterOptionsWindow(window)
  for pageKey in pairs(window.pages) do windows[pageKey] = window end
end

local showOwnPage, toggleOwnPage = ns.ShowOptionsPage, ns.ToggleOptionsPage

function ns.ShowOptionsPage(pageKey)
  local window = pageKey and windows[pageKey]
  if window then
    window.show(pageKey)
  else
    showOwnPage(pageKey)
  end
end

function ns.ToggleOptionsPage(pageKey)
  local window = pageKey and windows[pageKey]
  if window then
    window.toggle(pageKey)
  else
    toggleOwnPage(pageKey)
  end
end
