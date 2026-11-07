-- Edit-Modus (/lt edit): Betreten und Verlassen, Beispielinhalt, Ziehen mit Einrasten, Mausrad, Pfeiltasten,
-- Menü per Rechtsklick, Raster, Esc, Kampf beendet, Blizzards Bearbeitungsmodus.
local L = addon.L
local EditMode = addon.EditMode
local Frames = addon.Frames
UIParent._width, UIParent._height = 1024, 768

-- Blizzards Bearbeitungsmodus (Retail/Forever): nur nachhaken
EditModeManagerFrame = { EnterEditMode = function() end, ExitEditMode = function() end }
wow.login({ level = 20 })
local db = LevelTimerDB

-- Ausgeschaltete Anzeigen erscheinen im Modus trotzdem, mit Fläche und Beschriftung
addon.Set("showTimer", false)
expect("Fenster aus", LevelTimerFrame:IsShown(), false)
SlashCmdList.LEVELTIMER("edit")
expect("aktiv", EditMode.IsActive(), true)
expect("Fenster im Modus sichtbar", LevelTimerFrame:IsShown(), true)
expect("Split-Liste im Modus sichtbar", LevelTimerSplits:IsShown(), true)
expect("Flug-Anzeige zeigt Beispiel", LevelTimerFlight:IsShown(), true)
local overlay = EditMode.Overlay("main")
expect("Fläche über dem Fenster", overlay:IsShown(), true)
expectTrue("Fläche beschriftet", overlay.label:GetText():find(L.EDIT_FRAME_MAIN, 1, true) == 1)
expect("Leiste oben", LevelTimerEditMode:IsShown(), true)
expect("Raster an", LevelTimerEditGrid:IsShown(), true)
expect("keine Fläche fürs Lagerfeuer außerhalb von Forever", EditMode.Overlay("camp"), nil)
addon.ApplySettings()  -- ein Apply im Modus versteckt nichts
expect("Fenster bleibt", LevelTimerFrame:IsShown(), true)

-- Mausrad skaliert in Schritten, beschriftet mit Prozent
overlay._scripts.OnMouseWheel(overlay, 2)
expectNear("Mausrad: größer", Frames.GetScale("main"), 1.1)
expectTrue("Prozent in der Beschriftung", overlay.label:GetText():find("110%", 1, true) ~= nil)
overlay._scripts.OnMouseWheel(overlay, -2)

-- Einrasten (reine Rechnung): Kante nahe einer Linie springt auf sie, weit weg bleibt alles
local dx, dy = EditMode.Snap({ left = 103, right = 203, top = 400, bottom = 300 }, { x = { 100 }, y = { 512 } }, 8)
expect("links rastet ein", dx, -3)
expect("zu weit: kein Versatz", dy, 0)
dx = EditMode.Snap({ left = 0, right = 100, top = 10, bottom = 0 }, { x = { 54 } }, 8)
expect("Mitte rastet ein", dx, 4)
dx = EditMode.Snap({ left = 0, right = 100, top = 10, bottom = 0 }, { x = { 97, 101 } }, 8)
expect("nächste Linie gewinnt", dx, 1)

-- Ziehen: Fläche zieht den Rahmen, Loslassen rastet ein und speichert mit dem eigenen Ankerpunkt
-- Nur Raster und Bildschirmmitte als Linien: die anderen Flächen aus (im Stub stehen alle Rahmen bei 100/500)
for _, reg in ipairs(Frames.All()) do
  if reg.id ~= "flight" then EditMode.Overlay(reg.id):Hide() end
end
local flight = LevelTimerFlight
flight.GetLeft = function() return 395 end
flight.GetTop = function() return 600 end
flight._width, flight._height = 200, 64
local flightOverlay = EditMode.Overlay("flight")
flightOverlay._scripts.OnDragStart(flightOverlay)
flightOverlay._scripts.OnDragStop(flightOverlay)
local entry = db.frames.flight
expect("Anker bleibt TOP", entry.point, "TOP")
expect("Bezugspunkt TOP", entry.relPoint, "TOP")
-- Rechteck 395..595 x 600..536: links 395 -> Raster 384 (11, zu weit), Mitte 495 -> 480 (15), rechts 595 -> 608 (13):
-- kein Einrasten; oben 600 -> Raster 608 (8, Raster ab der Bildschirmmitte 384 in 32er-Schritten): rastet ein
expect("x ohne Einrasten (TOP-Anker: Mitte gegen Bildschirmmitte)", entry.x, 495 - 512)
expect("y rastet am Raster ein", entry.y, 608 - 768)

-- Shift beim Loslassen: frei, ohne Einrasten
wow.state.shiftDown = true
flightOverlay._scripts.OnDragStop(flightOverlay)
wow.state.shiftDown = false
expect("frei: y unverändert", db.frames.flight.y, 600 - 768)

-- Pfeiltasten schieben die zuletzt angeklickte Anzeige (1 px, mit Shift 10 px); andere Tasten gehen weiter
flightOverlay._scripts.OnMouseDown(flightOverlay, "LeftButton")
local toolbar = LevelTimerEditMode
local propagate = {}
toolbar.SetPropagateKeyboardInput = function(_, value) table.insert(propagate, value) end
toolbar._scripts.OnKeyDown(toolbar, "RIGHT")
expect("1 px nach rechts", db.frames.flight.x, 495 - 512 + 1)
expect("Pfeil nicht weitergegeben", propagate[#propagate], false)
wow.state.shiftDown = true
toolbar._scripts.OnKeyDown(toolbar, "UP")
wow.state.shiftDown = false
expect("10 px nach oben", db.frames.flight.y, 600 - 768 + 10)
toolbar._scripts.OnKeyDown(toolbar, "W")
expect("andere Taste weitergegeben", propagate[#propagate], true)
flight.GetLeft, flight.GetTop = nil, nil

-- Rechtsklick: Menü mit Größe, Zurücksetzen, Ausblenden, Einstellungen
flightOverlay._scripts.OnMouseUp(flightOverlay, "RightButton")
local popup = LevelTimerEditPopup
expect("Menü offen", popup:IsShown(), true)
expect("Menü für die Anzeige", EditMode.PopupReg().id, "flight")
popup.slider.slider._scripts.OnValueChanged(popup.slider.slider, 150)
expectNear("Regler im Menü", Frames.GetScale("flight"), 1.5)
expectTrue("Zurücksetzen", wow.click(L.EDIT_MODE_RESET, true))
expect("Menü: zurückgesetzt", db.frames.flight, nil)
addon.Set("flightTimer", true)
expectTrue("Ausblenden", wow.click(L.EDIT_MODE_HIDE, true))
expect("Ausblenden schaltet die Anzeige ab", db.flightTimer, false)
expect("Fläche weg", flightOverlay:IsShown(), false)

-- Raster umschalten
expectTrue("Raster-Knopf", wow.click(L.EDIT_MODE_GRID, true))
expect("Raster aus", LevelTimerEditGrid:IsShown(), false)
expect("Einstellung gemerkt", db.editGrid, false)

-- Esc beendet; Anzeigen zeigen wieder ihren echten Zustand
toolbar._scripts.OnKeyDown(toolbar, "ESCAPE")
expect("Esc beendet", EditMode.IsActive(), false)
expect("Fenster wieder aus", LevelTimerFrame:IsShown(), false)
expect("Fläche weg", overlay:IsShown(), false)
expect("Flug-Beispiel weg", LevelTimerFlight:IsShown(), false)
expect("Leiste weg", toolbar:IsShown(), false)
addon.Set("showTimer", true)

-- "Einstellungen" im Menü springt auf den Reiter der Anzeige
EditMode.Enter()
EditMode.ShowPopup("splitList")
expectTrue("Einstellungen", wow.click(L.EDIT_MODE_SETTINGS, true))
expect("Modus beendet", EditMode.IsActive(), false)
expect("Einstellungen offen", LevelTimerOptions:IsShown(), true)
addon.ToggleOptions()

-- Kampf: Betreten verweigert, laufender Modus endet bei PLAYER_REGEN_DISABLED
EditMode.Enter()
wow.state.combatLockdown = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("Kampf beendet den Modus", EditMode.IsActive(), false)
expectTrue("Meldung", wow.printed[#wow.printed]:find(L.EDIT_MODE_COMBAT_LEFT, 1, true) ~= nil)
expect("im Kampf kein Betreten", EditMode.Enter(), false)
wow.state.combatLockdown = false

-- Minimap: Shift-Rechtsklick schaltet den Modus
local minimapButton = LevelTimerMinimapButton
wow.state.shiftDown = true
minimapButton._scripts.OnClick(minimapButton, "RightButton")
wow.state.shiftDown = false
expect("Minimap: an", EditMode.IsActive(), true)
EditMode.Toggle()
expect("Umschalten: aus", EditMode.IsActive(), false)

-- Blizzards Bearbeitungsmodus schaltet mit (Einstellung editModeWithBlizzard)
EditModeManagerFrame:EnterEditMode()
expect("mit Blizzard an", EditMode.IsActive(), true)
EditModeManagerFrame:ExitEditMode()
expect("mit Blizzard aus", EditMode.IsActive(), false)
addon.Set("editModeWithBlizzard", false)
EditModeManagerFrame:EnterEditMode()
expect("ohne Einstellung: bleibt aus", EditMode.IsActive(), false)

-- Außerhalb des Modus keine Arbeit: keine Fläche und kein Raster
expect("Raster aus", LevelTimerEditGrid:IsShown(), false)
expect("Fehlerfrei", #wow.errors, 0)
