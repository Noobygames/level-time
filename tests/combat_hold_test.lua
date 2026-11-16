-- Im Kampf: Level-Up-Einblendung wartet bis nach dem Kampf, Taschen- und Lagerfeuer-Hinweise kommen danach von selbst.
local L = addon.L

local function shownTitle()
  if LevelTimerNotice:IsShown() then return LevelTimerNotice.title:GetText() end
  local entries = addon.Hints.Entries()  -- Erinnerungen landen im Hinweisfenster
  return entries[#entries] and entries[#entries].title or nil
end

wow.login({ level = 10 })
addon.Set("alertLevelUp", true)
addon.Set("levelUpWindow", false)  -- sonst ersetzt das Fenster die Karte
addon.Alerts.Clear()

-- Level-Up im Kampf: nichts zu sehen, nach dem Kampf erscheint es
wow.state.inCombat = true
wow.levelUp(11)
expect("Kampf: keine Einblendung", shownTitle(), nil)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf: Level-Up", shownTitle(), string.format(L.ALERT_LEVEL_UP, 11))

-- Taschen voll im Kampf: keine Karte, auch nicht als erledigt vermerkt; nach dem Kampf kommt sie
addon.Alerts.Clear()
addon.Set("warnBagsFull", true)
wow.state.freeSlots = { [0] = { 1, 0 } }  -- ein freier Platz: Taschen fast voll
local GearWarnings = addon.GearWarnings
wow.state.inCombat = true
GearWarnings.Check()
expect("Kampf: keine Taschenwarnung", shownTitle(), nil)
wow.state.inCombat = false
GearWarnings.Check()
expect("nach dem Kampf: Taschenwarnung", shownTitle(), L.NOTICE_BAGS)
