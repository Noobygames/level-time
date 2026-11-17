-- Zielverfolgung eingeklappt lassen: Klick merkt den Zustand je Charakter, Login stellt ihn wieder her (nur
-- außerhalb des Kampfs), Einstellung aus = nichts verändern.
local TrackerCollapse = addon.TrackerCollapse
local calls = { n = 0 }
local function collapsible(name)
  local frame = CreateFrame("Frame", name, UIParent)
  frame.isCollapsed = false
  function frame:SetCollapsed(collapsed) calls.n = calls.n + 1; self.isCollapsed = collapsed end
  function frame:IsCollapsed() return self.isCollapsed end
  return frame
end
local quests = collapsible("QuestObjectiveTracker")
ObjectiveTrackerFrame = collapsible("ObjectiveTrackerFrame")
ObjectiveTrackerFrame.modules = { quests }

wow.login()
wow.runTimers()
quests:SetCollapsed(true)  -- Spieler klappt Quests ein
expect("gemerkt", addon.character.trackerCollapsed.QuestObjectiveTracker, true)

-- /reload: Blizzard klappt alles auf, wir stellen wieder her
quests.isCollapsed = false
calls.n = 0
wow.state.combatLockdown = true
TrackerCollapse.Restore()
expect("im Kampf: nichts", calls.n, 0)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf eingeklappt", quests:IsCollapsed(), true)
expect("Ganzes unverändert", ObjectiveTrackerFrame:IsCollapsed(), false)

quests:SetCollapsed(false)
expect("aufgeklappt vergessen", addon.character.trackerCollapsed.QuestObjectiveTracker, nil)

addon.character.trackerCollapsed.QuestObjectiveTracker = true
addon.Set("rememberTrackerCollapse", false)
calls.n = 0
TrackerCollapse.Restore()
expect("Einstellung aus: nichts", calls.n, 0)
expect("keine Fehler", #wow.errors, 0)
