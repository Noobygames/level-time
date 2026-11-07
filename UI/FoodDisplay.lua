-- Anzeige für den Essen-Timer (Zustände liefert Assist/FoodTimer.lua) als Karte (Lib/TimerDisplay.lua):
--   countdown  es wird gegessen: "Sitzen bleiben" mit Restzeit und Balken
--   done       "Satt" ist da: kurz "Satt aktiv"
-- Einstellungen: foodScale, foodPos (verschiebbar, Vorschau mit FoodDisplay.Preview), foodSound (bei "done").
local _, ns = ...
local L = ns.L

local MIN_SCALE = 0.5  -- Grenzen des Reglers in den Einstellungen
local MAX_SCALE = 2
local COLORS = {
  countdown = ns.Theme.COLORS.gold,
  done = ns.Theme.COLORS.success,
}

local function titleFor(kind)
  if kind == "done" then return L.FOOD_DONE end
  return L.FOOD_TITLE_COUNTDOWN
end

-- Spell-IDs aus FoodTimer (lädt nach dieser Datei), daher erst beim Aufruf aufgelöst
local function eatingSpell() return ns.FoodTimer.EATING_SPELL_ID end
local function wellFedSpell() return ns.FoodTimer.WELL_FED_SPELL_ID end

local FoodDisplay = ns.TimerDisplay.Create({
  name = "LevelTimerFood",
  default = { "TOP", "TOP", 0, -300 },  -- unter der Lagerfeuer-Anzeige
  scaleKey = "foodScale", posKey = "foodPos", soundKey = "foodSound",
  minScale = MIN_SCALE, maxScale = MAX_SCALE,
  colors = COLORS,
  titleFor = titleFor,
  previewKinds = { "countdown", "done" },
  demoSpell = function(kind) return kind == "done" and wellFedSpell() or eatingSpell() end,
  movingSpell = eatingSpell,
})
ns.FoodDisplay = FoodDisplay
FoodDisplay.MIN_SCALE, FoodDisplay.MAX_SCALE = MIN_SCALE, MAX_SCALE

local showDone = FoodDisplay.ShowDone
function FoodDisplay.ShowDone()
  showDone(wellFedSpell())
end
