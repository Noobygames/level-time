-- Ist das Level-Up-Fenster an, kommt die Level-Up-Einblendung (Karte) nicht zusätzlich.
-- Blizzards Toast im EventToastManager wird bewusst nicht angefasst (Eingriffe dort ließen die Controller-Leiste verschwinden).
wow.login({ level = 3 })
addon.Set("hintsCollect", true)  -- Szenario prüft das Sammelfenster (Opt-In)
local gains = { health = 90, strength = 3 }

addon.Set("alertLevelUp", true)
addon.Alerts.Clear()
addon.Hints.Clear()
wow.levelUp(4, nil, gains)
wow.runTimers()
expect("Fenster ersetzt die Karte", addon.Hints.IsShown(), false)

-- Nur Popups entfallen: die Chatzeilen (Gewinne, Lehrer-Hinweis) bleiben
local function printed(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end
expect("Fenster an: Gewinnzeile im Chat bleibt", printed(addon.L.GAIN_STRENGTH), true)

-- Lehrer-Hinweis: Popup entfällt, wenn das Fenster die Fähigkeiten des Levels kennt; die Chatzeile bleibt
wow.state.interface = 11509
addon.Set("remindTrainer", true)
local class = select(2, UnitClass("player"))
LevelTimerStatsDB.trainerCache = {}
addon.Alerts.Clear()
addon.Hints.Clear()
wow.levelUp(6, nil, gains)
expect("Fähigkeiten unbekannt: Popup bleibt", addon.Hints.IsShown(), true)
LevelTimerStatsDB.trainerCache = { [class] = { ["Heilen|1"] = { name = "Heilen", rank = "", level = 8 } } }
wow.printed = {}
addon.Alerts.Clear()
addon.Hints.Clear()
wow.levelUp(8, nil, gains)
expect("Fähigkeiten bekannt: Chatzeile", printed("neue Zauber beim Lehrer"), true)
expect("Fähigkeiten bekannt: kein Popup", addon.Hints.IsShown(), false)

-- Im Kampf: Chatzeile, dass das Fenster nach dem Kampf kommt
wow.printed = {}
wow.state.inCombat = true
wow.levelUp(14, nil, gains)
wow.runTimers()
expect("Kampf: Hinweis im Chat", printed(addon.L.LEVEL_UP_AFTER_COMBAT), true)
wow.state.inCombat = false
