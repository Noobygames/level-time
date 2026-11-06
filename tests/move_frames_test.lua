-- Fenster verschieben: Standardfenster per Ziehen bewegen, Position merken und beim Öffnen wiederherstellen.
local L = addon.L

local moved, stopped = 0, 0
local function blizzardFrame(name)
  local frame = CreateFrame("Frame", name)
  frame.StartMoving = function() moved = moved + 1 end
  frame.StopMovingOrSizing = function() stopped = stopped + 1 end
  frame.GetPoint = function() return "TOPLEFT", UIParent, "TOPLEFT", 120, -80 end
  return frame
end
local character = blizzardFrame("CharacterFrame")

wow.login({ level = 10 })
expect("aus: nichts eingehängt", character._scripts.OnDragStart, nil)

addon.Set("moveFrames", true)
expectTrue("an: Ziehen eingehängt", character._scripts.OnDragStart ~= nil)

-- Ziehen speichert die Position
character._scripts.OnDragStart(character)
expect("Verschieben gestartet", moved, 1)
character._scripts.OnDragStop(character)
expect("Verschieben beendet", stopped, 1)
local saved = LevelTimerDB.movedFrames.CharacterFrame
expect("Position gespeichert: Anker", saved[1], "TOPLEFT")
expect("Position gespeichert: x", saved[3], 120)
expect("Position gespeichert: y", saved[4], -80)

-- Öffnen stellt die Position wieder her, auch nachdem das Spiel das Fenster selbst angeordnet hat
character:ClearAllPoints()
character:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
character._scripts.OnShow(character)
local last = character._points[#character._points]
expect("Wiederherstellung: x", last[4], 120)
character:ClearAllPoints()
character:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
wow.runTimers()
expect("nach der Anordnung des Spiels erneut", character._points[#character._points][4], 120)

-- Im Kampf wird nichts angefasst; ein nie begonnenes Ziehen wird nicht gespeichert
LevelTimerDB.movedFrames = nil
wow.state.combatLockdown = true
moved = 0
character._scripts.OnDragStart(character)
expect("Kampf: kein Verschieben", moved, 0)
wow.state.combatLockdown = false
character._scripts.OnDragStop(character)
expect("kein Ziehen: nichts gespeichert", LevelTimerDB.movedFrames, nil)

-- Später geladene Blizzard-Fenster kommen über ADDON_LOADED dazu
local talents = blizzardFrame("PlayerTalentFrame")
wow.fire("ADDON_LOADED", "Blizzard_TalentUI")
expectTrue("spät geladenes Fenster eingehängt", talents._scripts.OnDragStart ~= nil)

-- Ausgeschaltet: Ziehen tut nichts mehr
addon.Set("moveFrames", false)
moved = 0
character._scripts.OnDragStart(character)
expect("aus: kein Verschieben", moved, 0)

-- Zurücksetzen
addon.Set("moveFrames", true)
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Komfort", wow.click(L.OPTIONS_TAB_COMFORT))
expectTrue("Button Zurücksetzen", wow.click(L.MOVE_FRAMES_RESET))
expect("Positionen vergessen", LevelTimerDB.movedFrames, nil)

-- Ungültige Positionen aus einem Import werden verworfen
local clean = addon.Database.SanitizeSettings({ movedFrames = { CharacterFrame = "kaputt" } })
expect("ungültige Position verworfen", next(clean.movedFrames), nil)
clean = addon.Database.SanitizeSettings({ movedFrames = { A = "kaputt", B = { "TOP", "TOP", 1, 2 } } })
expect("gültige Position bleibt", clean.movedFrames.B[3], 1)
expect("kaputte entfernt", clean.movedFrames.A, nil)
