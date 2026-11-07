-- Anzeige für das Lagerfeuer in WoW Forever (Zustände liefert Assist/CampFire.lua) als Karte (Lib/TimerDisplay.lua):
--   countdown  Einladendes Lagerfeuer läuft: "Sitzen bleiben" mit Restzeit und Balken
--   hint       Feuer in der Nähe, aber keine Lagervorteile: Hinweis, sich hinzusetzen (pulsiert leicht)
--   done       kurz nach dem Countdown: "Lagervorteile aktiv"
-- Einstellungen: Position und Größe über Lib/Frames.lua (Edit-Modus, Vorschau mit CampDisplay.Preview), campSound (bei "done").
local _, ns = ...
local L = ns.L

local COLORS = {
  countdown = ns.Theme.COLORS.gold,
  done = ns.Theme.COLORS.success,
  hint = ns.Theme.COLORS.info,
}

local function titleFor(kind)
  if kind == "countdown" then return L.CAMP_TITLE_COUNTDOWN end
  if kind == "done" then return L.CAMP_DONE end
  return L.CAMP_HINT_TEXT
end

local function demoSpell(kind)
  if kind == "hint" then return ns.CampFire.NEARBY_SPELL_ID end
  if kind == "done" then return ns.CampFire.BENEFITS_SPELL_ID end
  return ns.CampFire.INVITING_SPELL_ID
end

local CampDisplay = ns.TimerDisplay.Create({
  name = "LevelTimerCamp",
  default = { "TOP", "TOP", 0, -230 },  -- unter den Einblendungen
  id = "camp", label = "EDIT_FRAME_CAMP", soundKey = "campSound",
  available = function() return ns.CampFire.IsAvailable() end,
  colors = COLORS,
  titleFor = titleFor,
  previewKinds = { "hint", "countdown", "done" },
  pulseKind = "hint",
  demoSpell = demoSpell,
  movingSpell = function() return ns.CampFire.INVITING_SPELL_ID end,  -- CampFire lädt nach dieser Datei
})
ns.CampDisplay = CampDisplay

-- Die Spell-ID wird erst beim Aufruf aufgelöst, weil Assist/CampFire.lua nach dieser Datei lädt
local showDone = CampDisplay.ShowDone
function CampDisplay.ShowDone()
  showDone(ns.CampFire.BENEFITS_SPELL_ID)
end
