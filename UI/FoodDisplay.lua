-- Anzeige für den Essen-Timer (Zustände liefert Assist/FoodTimer.lua) als Karte (Lib/TimerDisplay.lua):
--   countdown  es wird gegessen: "Sitzen bleiben" mit Restzeit und Balken
--   done       "Satt" ist da: kurz "Satt aktiv"
-- Einstellungen: Position und Größe über Lib/Frames.lua (Edit-Modus, Vorschau mit FoodDisplay.Preview), foodSound (bei "done").
local _, ns = ...
local L = ns.L

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
  id = "food", label = "EDIT_FRAME_FOOD", soundKey = "foodSound",
  toggleKey = "foodTimer",
  available = function() return ns.FoodTimer.IsAvailable() end,
  colors = COLORS,
  titleFor = titleFor,
  previewKinds = { "countdown", "done" },
  demoSpell = function(kind) return kind == "done" and wellFedSpell() or eatingSpell() end,
  movingSpell = eatingSpell,
})
ns.FoodDisplay = FoodDisplay

local showDone = FoodDisplay.ShowDone
function FoodDisplay.ShowDone()
  showDone(wellFedSpell())
end
