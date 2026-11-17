-- LT-62: In WoW Forever liegen alle Dungeon-Einstellungen auf dem Reiter Dungeons (Dungeonquests, Eingänge, Tooltip,
-- Live-Tracker, Instanzbericht); die alten Orte zeigen sie nicht mehr.
wow.login()
local options = addon.OptionsWindow
local L = addon.L
addon.ShowOptionsPage("OPTIONS_PAGE_DUNGEON_RUNS")  -- Beschriftungen stehen erst nach dem ersten Aufbau

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
  { "DUNGEON_QUEST_ZONE_HINT_TOGGLE", "OPTIONS_PAGE_DUNGEON_QUESTS" },
  { "DUNGEON_QUEST_ACCEPT_HINT_TOGGLE", "OPTIONS_PAGE_DUNGEON_QUESTS" },
  { "INSTANCE_QUEST_CHECK_TOGGLE", "OPTIONS_PAGE_DUNGEON_QUESTS" }, { "DUNGEON_QUEST_GIVERS_TOGGLE", "OPTIONS_PAGE_DUNGEON_QUESTS" },
  { "DUNGEON_QUEST_MINIMAP_TOGGLE", "OPTIONS_PAGE_DUNGEON_QUESTS" }, { "DUNGEON_QUEST_TAGS_TOGGLE", "OPTIONS_PAGE_DUNGEON_QUESTS" },
  { "DUNGEON_ENTRANCES_TOGGLE", "OPTIONS_PAGE_DUNGEON_GUIDE" }, { "TOOLTIP_MECHANICS_TOGGLE", "OPTIONS_PAGE_DUNGEON_GUIDE" },
  { "BOSS_LOOT_TOGGLE", "OPTIONS_PAGE_DUNGEON_GUIDE" }, { "DUNGEON_RUN_TRACKER_TOGGLE", "OPTIONS_PAGE_DUNGEON_RUNS" },
  { "INSTANCE_REPORT_TOGGLE", "OPTIONS_PAGE_DUNGEON_RUNS" }, { "INSTANCE_REPORT_TEST", "OPTIONS_PAGE_DUNGEON_RUNS" },
}) do
  local places = placesOf(key[1])
  expect(key[1] .. ": genau ein Ort", #places, 1)
  expect(key[1] .. ": Reiter Dungeons", places[1], key[2])
end

-- Run-Tracker und Questhinweis öffnen per Rechtsklick die neue Seite
expect("Run-Tracker", addon.Frames.Get("dungeonRun").settingsPage, "OPTIONS_PAGE_DUNGEON_RUNS")
expect("keine Fehler", #wow.errors, 0)
