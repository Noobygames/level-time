-- Sammelfenster für Erinnerungen (UI/HintCollector.lua): drei Hinweise in ein Fenster, Einzel- und Alle-Schließen,
-- Auto-Schließen, ersetzter Eintrag mit gleichem Schlüssel; Banner (Alerts.Show) bleiben getrennt.
local Hints = addon.Hints
local Alerts = addon.Alerts
wow.login({ level = 20 })

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
addon.Set("hintsAutoClose", false)

-- Alle schließen
Hints.Add({ text = "a" })
Hints.Add({ text = "b" })
Hints.Clear()
expectTrue("alle geschlossen", not Hints.IsShown() and #Hints.Entries() == 0)

-- Dringende Meldungen bleiben Banner
Alerts.Show("Notfall", Alerts.COLORS.nearDeath, { immediate = true })
expectTrue("Banner statt Fenster", not Hints.IsShown())
