-- Klassenquests (Classic Era): Hinweis beim Level-Up im Fenster/Chat, ohne Fenster als Einblendung.
local L = addon.L
local ClassQuests = addon.ClassQuests

wow.state.class = "DRUID"
wow.state.spellNames[5487] = "Bärengestalt"
wow.login({ level = 9 })
addon.Set("hintsCollect", true)  -- Szenario prüft das Sammelfenster (Opt-In)
addon.Alerts.Clear()
addon.Hints.Clear()
local gains = { health = 90 }

local function printed(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

expectTrue("Era: verfügbar", ClassQuests.IsAvailable())
expect("Druide 10: Bärengestalt", ClassQuests.ForLevel(10).spells[1], 5487)
expect("Druide 11: nichts", ClassQuests.ForLevel(11), nil)
expect("Hinweistext", ClassQuests.Text(10), string.format(L.CLASS_QUEST_HINT, 10, "Bärengestalt"))

-- Fenster an: Chatzeile, keine Einblendung
wow.levelUp(10, nil, gains)
wow.runTimers()
expect("Chatzeile", printed(ClassQuests.Text(10)), true)
expect("Fenster sichtbar", LevelTimerLevelUp:IsShown(), true)
expect("keine Einblendung neben dem Fenster", addon.Hints.IsShown(), false)
LevelTimerLevelUp:Hide()

-- Fenster aus: Einblendung
addon.Set("levelUpWindow", false)
addon.Set("alertLevelUp", false)
wow.state.class = "SHAMAN"
wow.state.level = 19
wow.levelUp(20, nil, gains)
wow.runTimers()
expect("Einblendung ohne Fenster", addon.Hints.IsShown(), true)
expect("Wassertotem als Item-Link", printed("item:5177"), true)

-- Einstellung aus: nichts
addon.Alerts.Clear()
addon.Hints.Clear()
addon.Set("remindClassQuest", false)
wow.levelUp(30, nil, gains)
wow.runTimers()
expect("aus: keine Einblendung", addon.Hints.IsShown(), false)
expect("Fehlerfrei", #wow.errors, 0)
