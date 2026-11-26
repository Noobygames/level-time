-- Sammelfenster für Erinnerungen (UI/HintCollector.lua): drei Hinweise in ein Fenster, Einzel- und Alle-Schließen,
-- Auto-Schließen, ersetzter Eintrag mit gleichem Schlüssel; Banner (Alerts.Show) bleiben getrennt.
local Hints = addon.Hints
local Alerts = addon.Alerts
wow.login({ level = 20 })

expect("Sammeln Standard aus (Opt-In)", addon.db.hintsCollect, false)
Alerts.Notify({ title = "Lehrer", text = "einzeln", icon = Alerts.ICONS.trainer }, Alerts.REMINDER_COLOR, Alerts.COLLECT)
expectTrue("ohne Sammeln: Karte statt Fenster", LevelTimerNotice:IsShown() and not Hints.IsShown())
Alerts.Notify({ title = "Ränge", text = "Tabelle", rows = { { spellID = 1, name = "X", columns = {} } } },
  Alerts.REMINDER_COLOR, Alerts.COLLECT)
expectTrue("Tabelle immer im Fenster", Hints.IsShown())
Hints.Clear()
LevelTimerNotice:Hide()
addon.Set("hintsCollect", true)
expect("Auto-Schließen Standard an", addon.db.hintsAutoClose, true)
expect("Standarddauer 10 s", addon.db.hintsAutoCloseSeconds, 10)
addon.Set("hintsAutoClose", false)
expectTrue("anfangs kein Fenster", not Hints.IsShown())

Alerts.Notify({ { title = "Essen", text = "Kein Essen", icon = Alerts.ICONS.food },
  { title = "Lagerfeuer", text = "Kein Lagerfeuer", icon = Alerts.ICONS.camp } }, Alerts.WARNING_COLOR, Alerts.COLLECT)
Alerts.Notify({ title = "Lehrer", text = "Lehrer besuchen", icon = Alerts.ICONS.trainer }, Alerts.REMINDER_COLOR,
  Alerts.COLLECT)
expect("drei Hinweise, ein Fenster", #Hints.Entries(), 3)
expectTrue("Fenster sichtbar", Hints.IsShown())
expectTrue("kein Banner", not LevelTimerNotice:IsShown())

-- Gleicher Text ersetzt statt zu verdoppeln
Alerts.Notify({ title = "Lehrer", text = "Lehrer besuchen", icon = Alerts.ICONS.trainer }, Alerts.REMINDER_COLOR,
  Alerts.COLLECT)
expect("Wiederholung ersetzt", #Hints.Entries(), 3)

-- Einzeln schließen
local rows = Hints.Rows()
rows[1].dismiss:GetScript("OnClick")(rows[1].dismiss)
expect("einer weniger", #Hints.Entries(), 2)
expectTrue("Fenster bleibt", Hints.IsShown())

-- Bleibt stehen, auch nach langer Zeit (Auto-Schließen aus)
wow.advance(100)
wow.update(0.1)
expectTrue("bleibt ohne Automatik", Hints.IsShown())

-- Mit Auto-Schließen nach der Anzeigedauer
addon.Set("hintsAutoClose", true)
addon.Set("hintsAutoCloseSeconds", 20)
Hints.Add({ text = "neu", title = "Neu" })
wow.advance(15)
wow.update(0.1)
expectTrue("noch offen vor 20 s", Hints.IsShown())
wow.advance(6)
wow.update(0.1)
expectTrue("schließt von selbst", not Hints.IsShown())
expect("leer", #Hints.Entries(), 0)

-- Unter der Maus: keine Zeit läuft, nach dem Verlassen beginnt die volle Wartezeit neu
local panel = _G[addon.GlobalName("Hints")]
Hints.Add({ text = "maus", title = "Maus" })
wow.advance(20.2)  -- mitten im Ausblenden
wow.update(0.1)
panel.IsMouseOver = function() return true end
wow.advance(100)
wow.update(0.1)
expectTrue("unter der Maus offen", Hints.IsShown())
expect("unter der Maus voll sichtbar", panel:GetAlpha(), 1)
panel.IsMouseOver = function() return false end
wow.advance(15)
wow.update(0.1)
expectTrue("nach dem Verlassen volle Wartezeit", Hints.IsShown())
wow.advance(6)
wow.update(0.1)
expectTrue("danach schließt es", not Hints.IsShown())
-- Umsehen mit gedrückter Maustaste: versteckter Zeiger über dem Fenster hält die Zeit nicht an
Hints.Add({ text = "blick", title = "Blick" })
panel.IsMouseOver = function() return true end
IsMouselooking = function() return true end
wow.advance(21)
wow.update(0.1)
expectTrue("schließt trotz Zeiger beim Umsehen", not Hints.IsShown())
IsMouselooking = nil
panel.IsMouseOver = nil
addon.Set("hintsAutoClose", false)

-- Alle schließen
Hints.Add({ text = "a" })
Hints.Add({ text = "b" })
Hints.Clear()
expectTrue("alle geschlossen", not Hints.IsShown() and #Hints.Entries() == 0)

-- Dringende Meldungen bleiben Banner
Alerts.Show("Notfall", Alerts.COLORS.nearDeath, { immediate = true })
expectTrue("Banner statt Fenster", not Hints.IsShown())

-- Rechtsklick auf eine Hinweiszeile: "nicht mehr anzeigen" blendet den Schlüssel accountweit aus, auch als Karte
local menu
local openMenu = addon.Dropdown.Open
addon.Dropdown.Open = function(anchor, options)
  menu = options
  return openMenu(anchor, options)
end
addon.Set("hintsCollect", true)
Alerts.Notify({ title = "Essen", text = "Kein Essen", key = "remindFood" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
local hintRows = Hints.Rows()
hintRows[1]:GetScript("OnClick")(hintRows[1], "RightButton")
expect("Menütext", menu and menu.entries[1].text, addon.L.HINT_HIDE_MENU)
menu.onPick("hide")
addon.Dropdown.Close()
expectTrue("ausgeblendet", Hints.IsHidden("remindFood"))
expect("aus dem Fenster", #Hints.Entries(), 0)
Alerts.Notify({ title = "Essen", text = "Kein Essen", key = "remindFood" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
expect("kommt nicht wieder", #Hints.Entries(), 0)
addon.Set("hintsCollect", false)
LevelTimerNotice:Hide()
Alerts.Notify({ title = "Essen", text = "Kein Essen", key = "remindFood" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
expectTrue("auch keine Karte", not LevelTimerNotice:IsShown())
expect("zählt", Hints.HiddenCount(), 1)
Hints.ClearHidden()
addon.Set("hintsCollect", true)
Alerts.Notify({ title = "Essen", text = "Kein Essen", key = "remindFood" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
expect("nach Zurücksetzen wieder da", #Hints.Entries(), 1)
Hints.Clear()
-- Ohne Sammeln (Standard) als Karte: DismissKey beendet die laufende und streicht wartende, Rechtsklick blendet aus
addon.Set("hintsCollect", false)
Alerts.Clear()
Alerts.Notify({ text = "Kein Essen", key = "food" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
Alerts.Notify({ text = "Kein Lager", key = "camp" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
expectTrue("Karte sichtbar", LevelTimerNotice:IsShown())
Alerts.DismissKey("camp")
Alerts.DismissKey("food")
wow.update(0.1)
expectTrue("Buff wieder da: Karte weg, wartende gestrichen", not LevelTimerNotice:IsShown())
Alerts.Notify({ text = "Kein Lager", key = "camp" }, Alerts.WARNING_COLOR, Alerts.COLLECT)
LevelTimerNotice:GetScript("OnMouseUp")(LevelTimerNotice, "RightButton")
expect("Karte: Menütext", menu and menu.entries[1].text, addon.L.HINT_HIDE_MENU)
menu.onPick("hide")
addon.Dropdown.Close()
wow.update(0.1)
expectTrue("Karte: ausgeblendet", Hints.IsHidden("camp") and not LevelTimerNotice:IsShown())
Hints.ClearHidden()
menu = nil
Alerts.Notify({ text = "Dringend", key = "urgent" }, Alerts.WARNING_COLOR)
LevelTimerNotice:GetScript("OnMouseUp")(LevelTimerNotice, "RightButton")
expect("dringende Karte ohne Menü", menu, nil)
Alerts.Clear()
addon.Set("hintsCollect", true)
-- Alt+Z: UIParent verschwindet, OnHide kommt bei weiter gesetztem Shown-Flag; die Hinweise bleiben. Esc leert sie
Alerts.Notify({ text = "Bleibt", key = "stay" }, Alerts.REMINDER_COLOR, Alerts.COLLECT)
LevelTimerHints:GetScript("OnHide")(LevelTimerHints)
expect("Alt+Z: Hinweis bleibt", #Hints.Entries(), 1)
LevelTimerHints:Hide()
expect("Esc: gelesen", #Hints.Entries(), 0)
-- hideKey: mehrere Zeilen gleicher Art (eigene keys) werden zusammen und auch mit neuem Text ausgeblendet
Alerts.Notify({ text = "Geber A", key = "giver:1", hideKey = "giver" }, Alerts.REMINDER_COLOR, Alerts.COLLECT)
Alerts.Notify({ text = "Geber B", key = "giver:2", hideKey = "giver" }, Alerts.REMINDER_COLOR, Alerts.COLLECT)
expect("zwei Zeilen gleicher Art", #Hints.Entries(), 2)
hintRows = Hints.Rows()
hintRows[1]:GetScript("OnClick")(hintRows[1], "RightButton")
menu.onPick("hide")
addon.Dropdown.Close()
expectTrue("Art ausgeblendet", Hints.IsHidden("giver"))
Alerts.Notify({ text = "Geber C", key = "giver:3", hideKey = "giver" }, Alerts.REMINDER_COLOR, Alerts.COLLECT)
expectTrue("neuer Text derselben Art kommt nicht", Hints.Entries()[#Hints.Entries()] == nil
  or Hints.Entries()[#Hints.Entries()].text ~= "Geber C")
Hints.ClearHidden()
Hints.Clear()
addon.Dropdown.Open = openMenu
