-- Optionen, Reiter Dungeons: Dungeonquests, Guide & Karte, Run & Bericht, Gruppensuche, Gruppe & Heiler, Beute würfeln.
-- Abschnitte mit flavorabhängigen Daten erscheinen nur, wo es die Daten gibt (Classic Era, WoW Forever).
local _, ns = ...
local O = ns.OptionsCore
local addPage, finishPage, finishSubPages = O.addPage, O.finishPage, O.finishSubPages
local addSection, addSlider, addToggles, addChooser, addButton = O.addSection, O.addSlider, O.addToggles, O.addChooser, O.addButton
local addSubPage, toggle, localized, advanced, requires = O.addSubPage, O.toggle, O.localized, O.advanced, O.requires
local addFrameScaleSlider, percent = O.addFrameScaleSlider, O.percent

local REPORT_LOOT_MAX = 10  -- höchstens so viele Gegenstände im Instanzbericht

addPage("OPTIONS_TAB_DUNGEONS")
-- Dungeonquests: Hinweise, Questcheck, Questgeber auf Karte und Minimap, Markierung im Questlog
if ns.DungeonQuests.IsAvailable() then
  addSubPage("OPTIONS_PAGE_DUNGEON_QUESTS")
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
-- Guide & Karte: Dungeon Guide, Eingänge und Tooltip-Zusätze nur mit den Daten dazu
if ns.DungeonGuide.IsAvailable() or ns.DungeonEntrances.IsAvailable() or ns.MechanicTips.IsAvailable()
  or ns.BossLoot.IsAvailable() then
  addSubPage("OPTIONS_PAGE_DUNGEON_GUIDE")
end
-- Dungeon Guide: Trash- und Bossseiten beim Betreten (Classic Era, Forever)
if ns.DungeonGuide.IsAvailable() then
  addSection("SECTION_DUNGEON_GUIDE", { collapsible = true })
  addToggles({ toggle("DUNGEON_GUIDE_AUTO_TOGGLE", "dungeonGuideAuto") })
  addButton("DUNGEON_GUIDE_SHOW", function() ns.DungeonGuide.Open() end)
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
addSubPage("OPTIONS_PAGE_DUNGEON_RUNS")
-- Live-Tracker in der Instanz und das Run-Fenster
addSection("SECTION_DUNGEON_RUNS", { collapsible = true })
addToggles({
  toggle("DUNGEON_RUN_TRACKER_TOGGLE", "showRunTracker"),
  toggle("DUNGEON_RECAP_AUTO_OPEN_TOGGLE", "dungeonRecapAutoOpen"),
})
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
addToggles({ toggle("WARN_INSTANCE_LIMIT_TOGGLE", "warnInstanceLimit") })
-- Gruppensuche (nur WoW Forever): Tooltip-Zusatzinfos, Sprachfilter und Minikarten-Icon des eigenen Fensters
if ns.Client.IsForever() then
  addSubPage("OPTIONS_TAB_LFG")
  addSection("SECTION_LFG_TOOLTIP")
  addToggles({ toggle("LFG_TOOLTIP_TOGGLE", "lfgTooltip") })
  addSection("SECTION_LFG_LANGUAGES")
  local languageToggles = {}
  for _, code in ipairs(ns.LFGLanguages.Available()) do
    local key = "LFG_LANGUAGE_" .. code:upper()
    table.insert(languageToggles, {
      label = key, tip = "LFG_LANGUAGE_PICK_TIP",
      text = function() return ns.LFGLanguages.Name(code) end,
      enabled = function() return not ns.LFGLanguages.Defaults()[code] end,
      get = function() return ns.LFGLanguages.Selected()[code] == true end,
      set = function(checked) ns.LFGLanguages.Toggle(code, checked) end,
    })
  end
  addToggles(languageToggles)
  addButton("LFG_LANGUAGES_RESTORE", function() ns.LFGLanguages.Restore() end)
  addSection("SECTION_LFG_WINDOW")
  addToggles({ toggle("LFG_WINDOW_TOGGLE", "lfgMinimapButton", ns.LFGSearch.IsAvailable) })
end
-- Gruppe und Heiler: Ansagen im Gruppenchat, dazu die Aggro-Warnung
addSubPage("OPTIONS_PAGE_GROUP")
addToggles({
  toggle("WARN_AGGRO_TOGGLE", "warnAggro"),
  toggle("ANNOUNCE_GROUP_JOIN_TOGGLE", "announceGroupJoin"),
  toggle("LOW_MANA_TOGGLE", "announceLowMana"),
  toggle("CC_ANNOUNCE_TOGGLE", "announceControlLoss"),
  toggle("CC_OVER_TOGGLE", "announceControlOver"),
  toggle("HEALER_AGGRO_TOGGLE", "announceHealerAggro"),
})
addSlider(requires({
  label = "LOW_MANA_BELOW",
  advanced = true,
  setting = "lowManaPercent",
  min = ns.ManaCallout.MIN_PERCENT,
  max = ns.ManaCallout.MAX_PERCENT,
  step = 5,
  get = function(db) return db.lowManaPercent end,
  set = function(value) ns.SetDeferred("lowManaPercent", value) end,
  format = percent,
}, "announceLowMana"))
-- Testen: alle Ansagen nur im eigenen Chat (Instanzbericht: Dungeons > Run & Bericht) mit "Vorschau", nie an Gruppe oder Chat gesendet
addButton("NOTIFICATION_TEST_GROUP", function()
  ns.GroupJoinStats.Preview()
  ns.ManaCallout.Preview()
  ns.ControlCallout.Preview()
  ns.AggroWarning.PreviewHealer()
end)
-- Beute würfeln: Zähler, Namen, Zusammenfassung und Verlauf der Würfe
addSubPage("OPTIONS_PAGE_LOOT_ROLLS")
addSection("SECTION_LOOT_ROLLS")
addToggles({
  toggle("LOOT_ROLL_COUNTS_TOGGLE", "lootRollCounts"),
  requires(toggle("LOOT_ROLL_NAMES_TOGGLE", "lootRollNames"), "lootRollCounts"),
  toggle("LOOT_ROLL_SUMMARY_TOGGLE", "lootRollSummary"),
  advanced(toggle("LOOT_ROLL_JOURNAL_TOGGLE", "lootRollJournal")),
  toggle("LOOT_ROLL_HISTORY_TOGGLE", "lootRollHistory"),
})
addFrameScaleSlider("LOOT_ROLL_CARD_SCALE", "lootRolls", nil, true)
O.addFramePreview("LOOT_ROLL_PREVIEW", "lootRolls")
finishSubPages()
finishPage()
