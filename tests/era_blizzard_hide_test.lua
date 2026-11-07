-- Blizzard-Oberfläche ausblenden (Roadmap 366), Classic Era: Fokus, Arena, Fahrzeug und Sprechender Kopf gibt es nicht
-- (keine Schalter), Questverfolgung = QuestWatchFrame, Leistengrafik = Endkappen der MainActionBar plus die alte
-- MainMenuBar (Classic nutzt sie als Grafik), Gebietsname auch über MinimapZoneTextButton.
UIParent._width, UIParent._height = 1024, 768

local function blizzardFrame(name, parent)
  local frame = CreateFrame("Frame", name, parent)
  frame:EnableMouse(true)
  return frame
end

blizzardFrame("FocusFrame")  -- gibt es auch in Era als Frame, ohne Fokus-Einheit
blizzardFrame("QuestWatchFrame")
blizzardFrame("WatchFrame")
local mainBar = blizzardFrame("MainActionBar")
mainBar.EndCaps = blizzardFrame(nil, mainBar)
local artBar = blizzardFrame("MainMenuBar")
blizzardFrame("MinimapCluster")
blizzardFrame("MinimapZoneTextButton")
blizzardFrame("PetActionBar")
for index = 1, 10 do blizzardFrame("PetActionButton" .. index) end

wow.login({ level = 20 })
local BlizzardHide = addon.BlizzardHide
local get = BlizzardHide.Get

expect("Fokus nicht in Era", BlizzardHide.IsSupported(get("focus")), false)
expect("Fokus-Frame wird nicht benutzt", BlizzardHide.IsAvailable(get("focus")), false)
expect("keine Arena in Era", BlizzardHide.IsSupported(get("arena")), false)
expect("kein Sprechender Kopf", BlizzardHide.IsSupported(get("talkingHead")), false)
expect("keine Fahrzeugsitze", BlizzardHide.IsSupported(get("vehicleSeat")), false)
expect("Tracker = QuestWatchFrame", BlizzardHide.Frames(get("tracker"))[1], QuestWatchFrame)
expect("Gebietsname (Classic-Name)", BlizzardHide.Frames(get("zoneText"))[1], MinimapZoneTextButton)

-- Optionen: Schalter nur für Elemente, die es im Client geben kann
local texts = {}
for _, toggle in ipairs(BlizzardHide.Toggles()) do
  if toggle.available() then texts[toggle.text()] = true end
end
expect("kein Schalter Fokus", texts[addon.L.BLIZZ_FRAME_FOCUS], nil)
expect("Schalter Questverfolgung", texts[addon.L.BLIZZ_FRAME_TRACKER], true)

-- Leistengrafik: Endkappen und alte MainMenuBar, die Leiste selbst bleibt
local art = BlizzardHide.Frames(get("barArt"))
expect("zwei Grafik-Frames", #art, 2)
BlizzardHide.SetHidden("barArt", true)
expect("Endkappen weg", mainBar.EndCaps:GetAlpha(), 0)
expect("alte MainMenuBar weg", artBar:GetAlpha(), 0)
expect("Aktionsleiste bleibt", mainBar:GetAlpha(), 1)
BlizzardHide.SetHidden("barArt", false)
expect("Endkappen zurück", mainBar.EndCaps:GetAlpha(), 1)

-- Begleiterleiste: Knöpfe ohne Maus, geschützt
BlizzardHide.SetHidden("petBar", true)
expect("Begleiterleiste weg", PetActionBar:GetAlpha(), 0)
expect("Begleiterknopf ohne Maus", PetActionButton10:IsMouseEnabled(), false)
BlizzardHide.SetHidden("petBar", false)
expect("Begleiterknopf mit Maus", PetActionButton10:IsMouseEnabled(), true)
