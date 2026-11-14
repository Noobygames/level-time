-- Level-Up-Fenster: erscheint nach der Verzögerung mit den Zuwächsen, wartet im Kampf, Kompaktmodus, Theme, Vorschau.
local L = addon.L
local Window = addon.LevelUpWindow

wow.login({ level = 10 })
addon.Alerts.Clear()
expect("startet versteckt", LevelTimerLevelUp:IsShown(), false)

wow.state.healthMax = 1290
wow.state.stats = { 83, 40, 95, 61 }
local gains = { health = 90, strength = 3, stamina = 5, talents = 1 }

-- Level-Up: Fenster nach der Verzögerung, Titel mit Level
wow.levelUp(11, nil, gains)
expect("wartet auf die Werte", LevelTimerLevelUp:IsShown(), false)
wow.runTimers()
expect("Fenster sichtbar", LevelTimerLevelUp:IsShown(), true)
expect("Standardtheme", addon.db.levelUpTheme, "modern")

-- Aus: kein Fenster
LevelTimerLevelUp:Hide()
addon.Set("levelUpWindow", false)
wow.levelUp(12, nil, gains)
wow.runTimers()
expect("aus: kein Fenster", LevelTimerLevelUp:IsShown(), false)
addon.Set("levelUpWindow", true)

-- Im Kampf wartet das Fenster
wow.state.inCombat = true
wow.levelUp(13, nil, gains)
wow.runTimers()
expect("Kampf: kein Fenster", LevelTimerLevelUp:IsShown(), false)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf: Fenster", LevelTimerLevelUp:IsShown(), true)

-- Standard: bleibt stehen, bis man es anklickt
expect("Auto-Schließen standardmäßig aus", addon.db.levelUpAutoClose, false)
wow.advance(30)
wow.update(0.1)
expect("bleibt ohne Auto-Schließen", LevelTimerLevelUp:IsShown(), true)

-- Mit Auto-Schließen: blendet nach der Anzeigedauer aus
addon.Set("levelUpAutoClose", true)
wow.levelUp(14, nil, gains)
wow.runTimers()
addon.Set("levelUpDuration", 3)
wow.advance(3.1)
wow.update(0.1)
expectTrue("blendet aus (Alpha sinkt)", LevelTimerLevelUp:GetAlpha() < 1)
wow.advance(1)
wow.update(0.1)
expect("weg", LevelTimerLevelUp:IsShown(), false)

-- Kompaktmodus, Theme, Vorschau
addon.Set("levelUpCompact", true)
addon.Set("levelUpTheme", "horde")
Window.Preview()
expect("Vorschau sichtbar", LevelTimerLevelUp:IsShown(), true)
addon.Set("levelUpTheme", "alliance")
addon.Set("levelUpCompact", false)

-- Edit-Modus: Beispiel bleibt stehen, Linksklick schließt es nicht
addon.EditMode.Enter()
expect("Edit-Modus: sichtbar", LevelTimerLevelUp:IsShown(), true)
wow.advance(30)
wow.update(0.1)
expect("Edit-Modus: bleibt", LevelTimerLevelUp:IsShown(), true)
LevelTimerLevelUp._scripts.OnMouseUp(LevelTimerLevelUp, "LeftButton")
expect("Edit-Modus: Klick schließt nicht", LevelTimerLevelUp:IsShown(), true)
addon.EditMode.Leave()
expect("Edit-Modus beendet", LevelTimerLevelUp:IsShown(), false)

-- Blizzards Banner: Ereignis abgemeldet, solange das Fenster es ersetzt
addon.Set("levelUpHideBlizzard", false)
addon.Set("levelUpHideBlizzard", true)
expect("Fehlerfrei", #wow.errors, 0)
