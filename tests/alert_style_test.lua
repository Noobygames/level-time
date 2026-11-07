-- Aussehen und Position der Einblendungen: Stil, Größe, Dauer, Ton, Edit-Modus.
local Frames = addon.Frames
local EditMode = addon.EditMode
local L = addon.L
local Alerts = addon.Alerts
local alert = LevelTimerAlert

wow.login({ level = 10 })
local played = {}
function PlaySound(id) table.insert(played, id) end

-- Standard: Banner, Größe 100 %, 3 s
expect("Stil Banner", LevelTimerDB.alertStyle, "banner")
expect("Größe", alert:GetScale(), 1)
Alerts.ShowSample("levelUp")
expect("Banner ist eine Karte", LevelTimerNotice:IsShown(), true)
expect("Karte: Titel", LevelTimerNotice.title:GetText(), string.format(L.ALERT_LEVEL_UP, 11))
expect("Banner ohne Text-Rahmen", alert:IsShown(), false)
expect("kein Ton im Standard", #played, 0)
addon.Set("alertStyle", "text")

-- Größe und Stil wirken sofort
Frames.SetScale("alert", 1.5)
expect("Größe 150 %", alert:GetScale(), 1.5)
Alerts.ShowSample("levelUp")
expectTrue("Text-Stil zeigt Schrift", alert:IsShown() and not LevelTimerNotice:IsShown())

-- Ton
addon.Set("alertSound", true)
Alerts.ShowSample("rare")
expect("Ton gespielt", #played, 1)
addon.Set("alertSound", false)

-- Dauer: bei 6 s nach 4 s noch voll sichtbar, bei 1 s nach 4 s weg
addon.Set("alertDuration", 6)
Alerts.ShowSample("levelUp")
wow.advance(4)
alert._scripts.OnUpdate(alert, 0.1)
expect("lange Dauer: noch voll", alert:GetAlpha(), 1)
addon.Set("alertDuration", 1)
Alerts.ShowSample("levelUp")
wow.advance(4)
alert._scripts.OnUpdate(alert, 0.1)
expect("kurze Dauer: weg", alert:IsShown(), false)

-- Edit-Modus: Beispiel bleibt stehen, neue Einblendungen ersetzen es nicht, Ziehen speichert die Position
EditMode.Enter()
expect("Edit-Modus an", Alerts.IsEditing(), true)
local overlay = EditMode.Overlay("alert")
expect("zeigt Hinweis", alert.text:GetText(), L.ALERT_MOVE_HINT)
wow.advance(60)
alert._scripts.OnUpdate(alert, 0.1)
expect("bleibt sichtbar", alert:IsShown(), true)
Alerts.ShowSample("levelUp")
expect("Hinweis bleibt", alert.text:GetText(), L.ALERT_MOVE_HINT)
overlay._scripts.OnDragStart(overlay)
overlay._scripts.OnDragStop(overlay)
expectTrue("Position gespeichert", LevelTimerDB.frames.alert.point ~= nil)
EditMode.Leave()
expect("Verlassen beendet", Alerts.IsEditing(), false)
-- Was währenddessen kam (Level-Up-Beispiel), erscheint jetzt statt verloren zu gehen
expect("Wartende erscheint danach", alert.text:GetText(), string.format(L.ALERT_LEVEL_UP, 11))
Alerts.Clear()
expect("danach versteckt", alert:IsShown(), false)

-- Verschiebemodus im Banner-Stil: die Karte ist das sichtbare Beispiel, der unsichtbare Rahmen trägt die Ziehgriffe
addon.Set("alertStyle", "banner")
EditMode.Enter()
expect("Banner: Karte steht", LevelTimerNotice:IsShown(), true)
expect("Banner: Karte sichtbar", LevelTimerNotice:GetAlpha(), 1)
expectTrue("Banner: Ziehfläche da", alert:IsShown())
expect("Banner: Ziehfläche unsichtbar", alert:GetAlpha(), 0)
expectTrue("Banner: Fläche über dem Rahmen", EditMode.Overlay("alert"):IsShown())
EditMode.Leave()
expect("Banner: beendet", Alerts.IsEditing(), false)
Alerts.Clear()
addon.Set("alertStyle", "text")

-- Zurücksetzen
Frames.Reset("alert")
expect("Position zurückgesetzt", LevelTimerDB.frames.alert, nil)

-- Gespeicherte Position kommt aus den Einstellungen; Müll im Profil wird verworfen (alte Schlüssel ziehen um)
local clean = addon.Database.SanitizeSettings({ alertPos = { "TOP", "TOP", 5, -10 }, alertScale = "groß" })
expect("gültige Position bleibt", clean.frames.alert.x, 5)
expect("falscher Typ fliegt raus", clean.frames.alert.scale, nil)
expect("alter Schlüssel weg", clean.alertPos, nil)
expect("ungültige Position fliegt raus", addon.Database.SanitizeSettings({ alertPos = { 1, 2 } }).frames, nil)

-- Optionen: Reiter und Buttons vorhanden
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Einblendungen", wow.click(L.OPTIONS_TAB_ALERTS))
expectTrue("Button Vorschau", wow.click(L.ALERT_PREVIEW, true))
expect("Vorschau zeigt Level-Up", alert:IsShown(), true)
expectTrue("Button Layout bearbeiten", wow.click(L.EDIT_MODE))
expect("Button startet den Edit-Modus", Alerts.IsEditing(), true)
expect("Einstellungen dabei zu", LevelTimerOptions:IsShown(), false)
EditMode.Leave()
expect("Edit-Modus aus", Alerts.IsEditing(), false)

-- Warteschlange: eine zweite Einblendung wartet hinter der laufenden und erscheint danach
Alerts.Clear()
addon.Set("alertDuration", 3)
Alerts.Show("Erste", { 1, 1, 1 })
Alerts.Show("Zweite", { 1, 1, 1 })
Alerts.Show("Dritte", { 1, 1, 1 })
expect("laufende bleibt", alert.text:GetText(), "Erste")
wow.advance(1.5 + 1.1)  -- verkürzte Anzeigedauer, solange andere warten
alert._scripts.OnUpdate(alert, 0.1)
expect("danach die nächste", alert.text:GetText(), "Zweite")
wow.advance(1.5 + 1.1)
alert._scripts.OnUpdate(alert, 0.1)
expect("dann die dritte", alert.text:GetText(), "Dritte")
wow.advance(3 + 1.1)
alert._scripts.OnUpdate(alert, 0.1)
expect("am Ende weg", alert:IsShown(), false)

-- Mehr als vier Wartende: die älteste fällt weg
Alerts.Show("A", { 1, 1, 1 })
for i = 1, 6 do Alerts.Show("W" .. i, { 1, 1, 1 }) end
wow.advance(10)
alert._scripts.OnUpdate(alert, 0.1)
expect("W1 und W2 verworfen", alert.text:GetText(), "W3")
Alerts.Clear()

-- Lange Texte brechen um: Breite bleibt begrenzt
Alerts.Show(string.rep("x", 200), { 1, 1, 1 })
expectTrue("Breite begrenzt", alert.text:GetWidth() <= 520)
Alerts.Clear()

-- Ton nur bei Ereignissen, nicht bei Hinweisen
addon.Set("alertSound", true)
local before = #played
Alerts.Notify("Hinweis", { 1, 1, 1 })
expect("Hinweis ohne Ton", #played, before)

-- Größenänderung lässt die gespeicherte Einblendung visuell stehen (Abstände in der Skalierung des Rahmens)
LevelTimerDB.frames.alert = { point = "TOP", relPoint = "TOP", x = 100, y = -200 }
addon.ApplySettings()  -- neue Tabelle: dorthin
Frames.SetScale("alert", 1)
Frames.SetScale("alert", 2)
expect("Abstand x umgerechnet", LevelTimerDB.frames.alert.x, 50)
expect("Abstand y umgerechnet", LevelTimerDB.frames.alert.y, -100)

-- Hinweise (Notify) erscheinen als Karte mit Symbol, Titel und Text, an derselben Stelle wie das Banner
local noticeFrame = LevelTimerNotice
Alerts.Clear()
Alerts.Notify({ title = "Titel", text = "Text", icon = Alerts.ICONS.bags }, { 1, 0.6, 0.2 })
expect("Karte statt Banner", noticeFrame:IsShown(), true)
expect("Banner aus", alert:IsShown(), false)
expect("Titel", noticeFrame.title:GetText(), "Titel")
expect("Text", noticeFrame.body:GetText(), "Text")
-- ohne Titel ist der Text der Titel
Alerts.Clear()
Alerts.Notify("Nur Text", { 1, 0.6, 0.2 })
expect("ohne Titel", noticeFrame.title:GetText(), "Nur Text")
expect("ohne Titel kein Text darunter", noticeFrame.body:GetText(), "")
-- Karte folgt Größe und blendet wie das Banner aus
Frames.SetScale("alert", 1.5)
expect("Karte skaliert mit", noticeFrame:GetScale(), 1.5)
Frames.SetScale("alert", 1)
addon.Set("alertDuration", 3)
Alerts.Clear()
Alerts.Notify({ title = "T", text = "X" }, { 1, 1, 1 })
wow.advance(3 + 1.1)
noticeFrame._scripts.OnUpdate(noticeFrame, 0.1)
expect("Karte verschwindet nach der Dauer", noticeFrame:IsShown(), false)
-- Banner und Karten teilen die Warteschlange: Karte, dann Ereignis
Alerts.Notify({ title = "T", text = "Karte" }, { 1, 1, 1 })
Alerts.Show("Ereignis", { 1, 1, 1 })
wow.advance(1.5 + 1.1)
noticeFrame._scripts.OnUpdate(noticeFrame, 0.1)
expect("danach das Banner", alert.text:GetText(), "Ereignis")
expect("Karte ist weg", noticeFrame:IsShown(), false)
Alerts.Clear()
-- Vorschau: die sechste Art ist eine Hinweis-Karte
for _ = 1, 6 do
  Alerts.Preview()
  if noticeFrame:IsShown() then break end
end
expect("Vorschau zeigt irgendwann die Karte", noticeFrame.title:GetText(), L.NOTICE_BAGS)
Alerts.Clear()

-- Roadmap 164: Beispiele verwerfen keine wartenden echten Einblendungen
Alerts.Clear()
addon.Set("alertStyle", "text")
Alerts.Show("Echt 1", { 1, 1, 1 })
Alerts.Show("Echt 2", { 1, 1, 1 })
Alerts.ShowSample("rare")
expect("Beispiel sofort sichtbar", alert.text:GetText(), string.format(L.ALERT_RARE_KILL, "Hogger"))
addon.Set("alertDuration", 1)
local seen = {}
for _ = 1, 10 do
  wow.advance(2.5)
  alert._scripts.OnUpdate(alert, 0.1)
  if alert:IsShown() then seen[#seen + 1] = alert.text:GetText() end
end
expect("unterbrochene kommt zuerst zurück", seen[1], "Echt 1")
expect("dann die wartende", seen[2], "Echt 2")
expect("danach nichts mehr", #seen, 2)
Alerts.Clear()
