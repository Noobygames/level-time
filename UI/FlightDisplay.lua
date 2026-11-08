-- Anzeige für Flüge (Zustände liefert Assist/FlightTimer.lua) als Karte (Lib/TimerDisplay.lua):
--   countdown  im Flug mit bekannter Dauer: Ziel als Titel, Restzeit und Balken; geschätzte Dauer (Gegenrichtung,
--              Strecke) mit "~" und leiser Farbe (Theme muted), gemessene normal
--   hint       im Flug, Strecke zum ersten Mal: Ziel als Titel, "Dauer wird gemessen"
--   done       gelandet: kurz "Angekommen"
-- Einstellungen: Position und Größe über Lib/Frames.lua (Edit-Modus, Vorschau mit FlightDisplay.Preview), flightSound (Landung).
local _, ns = ...
local L = ns.L

local ICON = "Interface\\Icons\\Ability_Mount_Wyvern_01"
local COLORS = {
  countdown = ns.Theme.COLORS.info,
  hint = ns.Theme.COLORS.info,
  done = ns.Theme.COLORS.success,
  estimated = ns.Theme.COLORS.muted,
}

local function titleFor(kind)
  if kind == "done" then return L.FLIGHT_DONE end
  if kind == "hint" then return L.FLIGHT_MEASURING end
  return L.FLIGHT_TITLE
end

-- Restzeit wie die übrigen Anzeigen ("4m 10s", nicht "4:10", das man als Uhrzeit liest), geschätzt als "~4m 10s"
local function formatTime(seconds, state)
  local text = ns.Format.Duration(seconds)
  if state and state.estimated then return "~" .. text end
  return text
end

local FlightDisplay = ns.TimerDisplay.Create({
  name = ns.GlobalName("Flight"),
  default = { "TOP", "TOP", 0, -160 },
  id = "flight", label = "EDIT_FRAME_FLIGHT", soundKey = "flightSound",
  toggleKey = "flightTimer", settingsPage = "OPTIONS_PAGE_FLIGHTS",
  colors = COLORS,
  titleFor = titleFor,
  formatTime = formatTime,
  previewKinds = { "countdown", "hint", "done" },
  demoSpell = function() return ICON end,
  movingSpell = function() return ICON end,
})
ns.FlightDisplay = FlightDisplay
FlightDisplay.ICON = ICON
