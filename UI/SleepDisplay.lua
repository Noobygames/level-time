-- Anzeige für den Schlafsack-Timer in WoW Forever (Zustände liefert Assist/SleepTimer.lua) als Karte
-- (Lib/TimerDisplay.lua):
--   countdown  im Schlafsack: "Im Schlafsack ausruhen" (mit Stapeln von "Gut erholt") samt Restzeit und Balken
--   done       Zeit um: kurz "Fertig ausgeruht"
--   cancelled  vorher aufgestanden, bewegt oder im Kampf: kurz "Ausruhen abgebrochen"
-- Einstellungen: Position und Größe über Lib/Frames.lua (Edit-Modus, Vorschau mit SleepDisplay.Preview),
-- sleepTimerSound (bei "done").
local _, ns = ...
local L = ns.L

local COLORS = {
  countdown = ns.Theme.COLORS.gold,
  done = ns.Theme.COLORS.success,
  cancelled = ns.Theme.COLORS.warning,
}

local function titleFor(kind)
  if kind == "done" then return L.SLEEP_DONE end
  if kind == "cancelled" then return L.SLEEP_CANCELLED end
  return L.SLEEP_TITLE
end

-- Spell-ID aus SleepTimer (lädt nach dieser Datei), daher erst beim Aufruf aufgelöst
local function wellRestedSpell() return ns.SleepTimer.WELL_RESTED_SPELL_ID end

local SleepDisplay = ns.TimerDisplay.Create({
  name = ns.GlobalName("Sleep"),
  default = { "TOP", "TOP", 0, -370 },  -- unter dem Essen-Timer
  id = "sleep", label = "EDIT_FRAME_SLEEP", soundKey = "sleepTimerSound",
  toggleKey = "sleepTimer",
  available = function() return ns.SleepTimer.IsAvailable() end,
  colors = COLORS,
  titleFor = titleFor,
  previewKinds = { "countdown", "done", "cancelled" },
  demoSpell = wellRestedSpell,
  movingSpell = wellRestedSpell,
})
ns.SleepDisplay = SleepDisplay

local showDone = SleepDisplay.ShowDone
function SleepDisplay.ShowDone(title)
  showDone(wellRestedSpell(), title)
end

function SleepDisplay.ShowCancelled()
  SleepDisplay.ShowEnd("cancelled", wellRestedSpell(), L.SLEEP_CANCELLED)
end
