-- Anzeige für Flüge (Zustände liefert Assist/FlightTimer.lua) als Karte (Lib/TimerDisplay.lua):
--   countdown  im Flug mit bekannter Dauer: Ziel als Titel, Restzeit und Balken
--   hint       im Flug, Strecke zum ersten Mal: Ziel als Titel, "Dauer wird gemessen"
--   done       gelandet: kurz "Angekommen"
-- Einstellungen: flightScale, flightPos (verschiebbar, Vorschau mit FlightDisplay.Preview), flightSound (Landung).
local _, ns = ...
local L = ns.L

local MIN_SCALE = 0.5
local MAX_SCALE = 2
local ICON = "Interface\\Icons\\Ability_Mount_Wyvern_01"
local COLORS = {
  countdown = ns.Theme.COLORS.info,
  hint = ns.Theme.COLORS.info,
  done = ns.Theme.COLORS.success,
}

local function titleFor(kind)
  if kind == "done" then return L.FLIGHT_DONE end
  if kind == "hint" then return L.FLIGHT_MEASURING end
  return L.FLIGHT_TITLE
end

-- Restzeit als "4:10" (Flüge dauern Minuten)
local function formatTime(seconds)
  return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local FlightDisplay = ns.TimerDisplay.Create({
  name = "LevelTimerFlight",
  default = { "TOP", "TOP", 0, -160 },
  scaleKey = "flightScale", posKey = "flightPos", soundKey = "flightSound",
  minScale = MIN_SCALE, maxScale = MAX_SCALE,
  colors = COLORS,
  titleFor = titleFor,
  formatTime = formatTime,
  previewKinds = { "countdown", "hint", "done" },
  demoSpell = function() return ICON end,
  movingSpell = function() return ICON end,
})
ns.FlightDisplay = FlightDisplay
FlightDisplay.MIN_SCALE, FlightDisplay.MAX_SCALE = MIN_SCALE, MAX_SCALE
FlightDisplay.ICON = ICON
