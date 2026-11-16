-- Optionen, Reiter Komfort: Unterseite Dungeons. Alles rund um Dungeons an einem Ort (Dungeonquests, Karte,
-- Tooltip, Live-Tracker und Run-Fenster, Instanzbericht); liegt in der .toc zwischen ComfortQuests und ComfortWorld.
-- Abschnitte mit flavorabhängigen Daten erscheinen nur, wo es die Daten gibt (Classic Era, WoW Forever).
local _, ns = ...
local O = ns.OptionsCore
local addSection, addSlider, addToggles, addChooser, addButton = O.addSection, O.addSlider, O.addToggles, O.addChooser, O.addButton
local addSubPage, toggle, localized, advanced, requires = O.addSubPage, O.toggle, O.localized, O.advanced, O.requires
local addFrameScaleSlider = O.addFrameScaleSlider

local REPORT_LOOT_MAX = 10  -- höchstens so viele Gegenstände im Instanzbericht

addSubPage("COMFORT_PAGE_DUNGEONS")
-- Dungeonquests: Hinweise, Questcheck, Questgeber auf Karte und Minimap, Markierung im Questlog
if ns.DungeonQuests.IsAvailable() then
  addSection("SECTION_DUNGEON_QUESTS", { collapsible = true })
  addToggles({
    toggle("DUNGEON_QUEST_ZONE_HINT_TOGGLE", "dungeonQuestZoneHint"),
    toggle("DUNGEON_QUEST_ACCEPT_HINT_TOGGLE", "dungeonQuestAcceptHint"),
    toggle("DUNGEON_QUEST_HINT_AUTOCLOSE_TOGGLE", "dungeonQuestHintAutoClose"),
    toggle("INSTANCE_QUEST_CHECK_TOGGLE", "instanceQuestCheck", ns.InstanceQuestCheck.IsAvailable),
    toggle("DUNGEON_QUEST_GIVERS_TOGGLE", "dungeonQuestGivers", ns.DungeonQuestGivers.IsAvailable),
    requires(toggle("DUNGEON_QUEST_MINIMAP_TOGGLE", "dungeonQuestMinimap", ns.DungeonQuestMinimap.IsAvailable),
      "dungeonQuestGivers"),
    advanced(requires(toggle("DUNGEON_QUEST_MINIMAP_EDGE_TOGGLE", "dungeonQuestMinimapEdge",
      ns.DungeonQuestMinimap.IsAvailable), "dungeonQuestMinimap")),
    toggle("DUNGEON_QUEST_TAGS_TOGGLE", "dungeonQuestTags", ns.DungeonQuestTags.IsAvailable),
  })
  addButton("DUNGEON_QUEST_HINT_SHOW", function() ns.DungeonQuestHints.Show() end)
end
-- Karte: Dungeon-Eingänge nur mit gepflegten Eingangsdaten (WoW Forever)
if ns.DungeonEntrances.IsAvailable() then
  addSection("SECTION_DUNGEON_MAP", { collapsible = true })
  addToggles({ toggle("DUNGEON_ENTRANCES_TOGGLE", "dungeonEntrances") })
end
-- Tooltip: Fähigkeiten-Tipps und Bossbeute nur mit den Daten dazu (Classic Era, Forever)
if ns.MechanicTips.IsAvailable() or ns.BossLoot.IsAvailable() then
  addSection("SECTION_TOOLTIP", { collapsible = true })
  addToggles({
    toggle("TOOLTIP_MECHANICS_TOGGLE", "tooltipMechanics", ns.MechanicTips.IsAvailable),
    toggle("BOSS_LOOT_TOGGLE", "bossLoot", ns.BossLoot.IsAvailable),
  })
end
-- Live-Tracker in der Instanz und das Run-Fenster
addSection("SECTION_DUNGEON_RUNS", { collapsible = true })
addToggles({ toggle("DUNGEON_RUN_TRACKER_TOGGLE", "showRunTracker") })
addFrameScaleSlider("DUNGEON_RUN_TRACKER_SCALE", "dungeonRun", function(db) return db.showRunTracker end)
O.addFramePreview("DUNGEON_RUN_TRACKER_PREVIEW", "dungeonRun")
addButton("DUNGEON_RUNS_OPEN", function() ns.InstanceRunWindow.Show() end)
-- Instanzbericht und Reset-Ansage im Gruppenchat; "Testen" schreibt nur in den eigenen Chat
addSection("SECTION_INSTANCE_REPORT", { collapsible = true })
addToggles({
  toggle("INSTANCE_REPORT_TOGGLE", "announceInstanceReport"),
  toggle("INSTANCE_REPORT_LOOT_TOGGLE", "instanceReportLoot"),
  toggle("ANNOUNCE_INSTANCE_RESET", "announceInstanceReset"),
})
addChooser(requires({
  label = "INSTANCE_REPORT_LOOT_QUALITY",
  advanced = true,
  setting = "instanceReportLootQuality",
  choices = {
    { value = 3, name = localized("INSTANCE_REPORT_LOOT_RARE") },
    { value = 4, name = localized("INSTANCE_REPORT_LOOT_EPIC") },
  },
}, "instanceReportLoot"))
addSlider(requires({
  label = "INSTANCE_REPORT_LOOT_MAX",
  advanced = true,
  setting = "instanceReportLootMax",
  min = 1,
  max = REPORT_LOOT_MAX,
  step = 1,
  get = function(db) return db.instanceReportLootMax end,
  set = function(value) ns.SetDeferred("instanceReportLootMax", value) end,
  format = function(value) return tostring(value) end,
}, "instanceReportLoot"))
addButton("INSTANCE_REPORT_TEST", function()
  ns.InstanceReport.Preview()
  ns.InstanceResetAnnounce.Preview()
end)
