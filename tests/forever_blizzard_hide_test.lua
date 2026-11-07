-- Blizzard-Oberfläche ausblenden (Roadmap 366), WoW Forever: ObjectiveTrackerFrame vor QuestWatchFrame, Sprechender
-- Kopf und Fahrzeugsitze möglich, Uhr und Arena kommen per ADDON_LOADED nach, gespeicherte Auswahl gilt nach dem Login.
UIParent._width, UIParent._height = 1024, 768

local function blizzardFrame(name, parent)
  local frame = CreateFrame("Frame", name, parent)
  frame:EnableMouse(true)
  return frame
end

blizzardFrame("ObjectiveTrackerFrame")
blizzardFrame("QuestWatchFrame")
blizzardFrame("BuffFrame")

-- Auswahl aus einer früheren Sitzung
LevelTimerDB = { hiddenBlizzardFrames = { buffs = true, clock = true, bogus = true } }
wow.login({ level = 20 })
local BlizzardHide = addon.BlizzardHide
local get = BlizzardHide.Get

expect("Tracker = ObjectiveTrackerFrame", BlizzardHide.Frames(get("tracker"))[1], ObjectiveTrackerFrame)
expect("Sprechender Kopf in Forever", BlizzardHide.IsSupported(get("talkingHead")), true)
expect("Fahrzeugsitze in Forever", BlizzardHide.IsSupported(get("vehicleSeat")), true)
expect("Fokus in Forever", BlizzardHide.IsSupported(get("focus")), true)
expect("gespeichert: Buffs nach dem Login weg", BuffFrame:GetAlpha(), 0)
expect("unbekannte Id ohne Wirkung", BlizzardHide.IsApplied("bogus"), false)

-- Uhr lädt mit einem Blizzard-Addon nach: wird dann ausgeblendet
local clock = blizzardFrame("TimeManagerClockButton")
expect("Uhr erst sichtbar", clock:GetAlpha(), 1)
wow.fire("ADDON_LOADED", "Blizzard_TimeManager")
expect("Uhr nach ADDON_LOADED weg", clock:GetAlpha(), 0)
expect("Uhr ohne Maus", clock:IsMouseEnabled(), false)
wow.fire("ADDON_LOADED", "SomeOtherAddon")
BlizzardHide.SetHidden("clock", false)
expect("Uhr zurück", clock:GetAlpha(), 1)
expect("Uhr mit Maus", clock:IsMouseEnabled(), true)
expect("Buffs bleiben weg", BuffFrame:GetAlpha(), 0)
