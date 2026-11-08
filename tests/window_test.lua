-- Fenster: Größe per Einstellung und Ziehgriff, Grenzen, Zurücksetzen, Rechtsklick.
local window = LevelTimerFrame
local grip = wow.findFrame(function(frame)
  return frame._normalTexture:find("SizeGrabber", 1, true) ~= nil
end)
expectTrue("Ziehgriff vorhanden", grip ~= nil)

wow.login()
expect("Standardgröße", window:GetScale(), 1)

-- Regler in den Einstellungen skaliert das ganze Fenster (Lib/Frames.lua, frames.main.scale)
local Frames = addon.Frames
Frames.SetScale("main", 1.5)
expect("Größe aus Einstellung", window:GetScale(), 1.5)
expectTrue("Position nach Skalierung gespeichert", LevelTimerDB.frames.main.point ~= nil)

Frames.SetScale("main", 5)
expect("obere Grenze", window:GetScale(), Frames.MAX_SCALE)
Frames.SetScale("main", 0.1)
expect("untere Grenze", window:GetScale(), Frames.MIN_SCALE)

-- Ziehgriff: Ecke um die halbe Fenstergröße nach rechts unten ziehen = 1,5-fach
Frames.SetScale("main", 1)
local width, height = window:GetWidth(), window:GetHeight()
wow.state.cursorX, wow.state.cursorY = 300, 300
grip._scripts.OnMouseDown(grip, "LeftButton")
wow.state.cursorX, wow.state.cursorY = 300 + width / 2, 300 - height / 2
grip._scripts.OnUpdate(grip, 0.1)
grip._scripts.OnMouseUp(grip, "LeftButton")
expectNear("Größe nach Ziehen", window:GetScale(), 1.5)
expectNear("gezogene Größe gespeichert", LevelTimerDB.frames.main.scale, 1.5)

-- Fixiertes Fenster: kein Ziehgriff, kein Ziehen
addon.Set("locked", true)
expect("Ziehgriff bei fixiertem Fenster versteckt", grip:IsShown(), false)
local moved = { count = 0 }
window.StartMoving = function() moved.count = moved.count + 1 end
window._scripts.OnDragStart(window)
expect("fixiert: kein Ziehen", moved.count, 0)
addon.Set("locked", false)
expect("Ziehgriff wieder da", grip:IsShown(), true)
window._scripts.OnDragStart(window)
expect("frei: Ziehen", moved.count, 1)
window.StartMoving = nil

-- Zurücksetzen
SlashCmdList.LEVELTIMER("reset")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)  -- Rückfrage bestätigen
expect("Eintrag zurückgesetzt", LevelTimerDB.frames.main, nil)
expect("Fenster zurückgesetzt", window:GetScale(), 1)

-- Rechtsklick öffnet die Einstellungen
window._scripts.OnMouseUp(window, "RightButton")
expect("Einstellungen offen", LevelTimerOptions:IsShown(), true)
window._scripts.OnMouseUp(window, "LeftButton")
expect("Linksklick öffnet nichts", LevelTimerOptions:IsShown(), true)

-- XP-Balken: braucht Platz im Fenster, nur beim Leveln
wow.state.xp, wow.state.xpMax, wow.state.rested = 250, 1000, 200
addon.Set("showXpBar", true)
local withBar = window:GetHeight()
addon.Set("showXpBar", false)
local withoutBar = window:GetHeight()
expectTrue("Balken vergrößert das Fenster", withBar > withoutBar)
addon.Set("showXpBar", true)
wow.levelUp(60)
expect("Max-Level erreicht: Balken weg ohne neues Anwenden", window:GetHeight(), withoutBar)

-- Layout Kompakt (/lt compact): ohne Reiter und ohne weitere Zeilen deutlich kleiner
wow.state.level, addon.level = 30, 30
addon.Set("windowLayout", "table")
local fullHeight = window:GetHeight()
local sessionTab = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == "Session"
end)
SlashCmdList.LEVELTIMER("compact")
expect("Kompakt an", LevelTimerDB.windowLayout, "compact")
expectTrue("kompakt ist kleiner", window:GetHeight() < fullHeight)
expect("Reiter versteckt", sessionTab:IsShown(), false)
SlashCmdList.LEVELTIMER("compact")
expect("Kompakt aus", LevelTimerDB.windowLayout, "table")
expect("Reiter wieder da", sessionTab:IsShown(), true)

-- Layout Leiste (/lt bar): eine Zeile, also breiter und flacher als das Fenster
local verticalWidth, verticalHeight = window:GetWidth(), window:GetHeight()
SlashCmdList.LEVELTIMER("bar")
expect("Leiste an", LevelTimerDB.windowLayout, "bar")
expectTrue("Leiste ist breiter", window:GetWidth() > verticalWidth)
expectTrue("Leiste ist flacher", window:GetHeight() < verticalHeight)
expect("Reiter in der Leiste", sessionTab:IsShown(), true)

-- Ohne XP-Balken nur noch eine Textzeile hoch
local barHeight = window:GetHeight()
addon.Set("showXpBar", false)
expectTrue("Leiste ohne Balken flacher", window:GetHeight() < barHeight)
addon.Set("showXpBar", true)

-- Abschalten stellt das Fenster wieder her
SlashCmdList.LEVELTIMER("bar")
expect("Leiste aus", LevelTimerDB.windowLayout, "table")
expect("Breite wie vorher", window:GetWidth(), verticalWidth)
expect("Höhe wie vorher", window:GetHeight(), verticalHeight)

-- Stream-Ansicht: Chroma-Hintergrund vollfarbig ohne Rahmen, Standard mit Deckkraft und Rahmen
addon.Set("bgAlpha", 0.5)
expect("Standard: Deckkraft", window._backdropColor[4], 0.5)
expectTrue("Standard: Rahmen sichtbar", window._borderColor[4] ~= 0)
expectTrue("Auswahl Grün", wow.click(addon.L.BACKGROUND_GREEN, true))  -- "Grün" gibt es auch als Akzent (Allgemein)
expect("Einstellung Grün", LevelTimerDB.windowBackground, "green")
expect("Grün: voll deckend", window._backdropColor[4], 1)
expect("Grün: Farbe", window._backdropColor[2], 1)
expect("Grün: kein Rahmen", window._borderColor[4], 0)
expectTrue("Auswahl Magenta", wow.click(addon.L.BACKGROUND_MAGENTA))
expect("Magenta: Rot", window._backdropColor[1], 1)
expect("Magenta: Blau", window._backdropColor[3], 1)
expectTrue("Auswahl Standard", wow.click(addon.L.BACKGROUND_DEFAULT))
expect("zurück: Deckkraft", window._backdropColor[4], 0.5)
expectTrue("zurück: Rahmen", window._borderColor[4] ~= 0)

-- 100 Tage und mehr auf einem Level: die Zeitanzeige wird breiter statt abgeschnitten
wow.fire("TIME_PLAYED_MSG", 200 * 86400, 120 * 86400)
wow.update(1)
local clock = wow.findFrame(function(frame) return frame._text and frame._text:match("^120" .. addon.L.UNIT_DAY_SHORT .. " ") end)
expectTrue("Zeit mit 120 Tagen angezeigt", clock ~= nil)
expectTrue("Platz für drei Tagesziffern", clock and clock:GetWidth() >= clock:GetStringWidth())
