-- LT-62: In WoW Forever liegen alle Dungeon-Einstellungen auf Komfort > Dungeons (Dungeonquests, Eingänge, Tooltip,
-- Live-Tracker, Instanzbericht); die alten Orte zeigen sie nicht mehr.
wow.login()
local options = addon.OptionsWindow
local L = addon.L
addon.ShowOptionsPage("COMFORT_PAGE_DUNGEONS")  -- Beschriftungen stehen erst nach dem ersten Aufbau

local function placesOf(labelKey)
  local places = {}
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if not entry.isPage and entry.tipKey == labelKey .. "_TIP" then
      table.insert(places, (entry.sub and entry.sub.key) or entry.tab.key)
    end
  end
  return places
end

for _, key in ipairs({
  "DUNGEON_QUEST_ZONE_HINT_TOGGLE", "DUNGEON_QUEST_ACCEPT_HINT_TOGGLE", "INSTANCE_QUEST_CHECK_TOGGLE",
  "DUNGEON_QUEST_GIVERS_TOGGLE", "DUNGEON_QUEST_MINIMAP_TOGGLE", "DUNGEON_QUEST_TAGS_TOGGLE",
  "DUNGEON_ENTRANCES_TOGGLE", "TOOLTIP_MECHANICS_TOGGLE", "BOSS_LOOT_TOGGLE",
  "DUNGEON_RUN_TRACKER_TOGGLE", "INSTANCE_REPORT_TOGGLE", "INSTANCE_REPORT_TEST",
}) do
  local places = placesOf(key)
  expect(key .. ": genau ein Ort", #places, 1)
  expect(key .. ": Komfort > Dungeons", places[1], "COMFORT_PAGE_DUNGEONS")
end

-- Run-Tracker und Questhinweis öffnen per Rechtsklick die neue Seite
expect("Run-Tracker", addon.Frames.Get("dungeonRun").settingsPage, "COMFORT_PAGE_DUNGEONS")
expect("keine Fehler", #wow.errors, 0)
