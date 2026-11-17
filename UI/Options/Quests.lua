-- Optionen, Reiter Quests: Automatik, Lernen & Karte, Questlog, Anzeige, Kill-Markierung, Klassenquests.
local _, ns = ...
local O = ns.OptionsCore
local builder, addSection, addSlider, addToggles, addSubPage = O.builder, O.addSection, O.addSlider, O.addToggles, O.addSubPage
local addPage, finishPage, finishSubPages = O.addPage, O.finishPage, O.finishSubPages
local toggle, advanced, requires, percent, toPercent = O.toggle, O.advanced, O.requires, O.percent, O.toPercent

local QUEST_EXCLUDE_WIDTH = 200  -- Eingabefeld für die eigene Sperrliste der Quest-Automatik

-- Quests: Quest-Automatik, Lernen und Karte, Questlog, Anzeige, Markierungen an Gegnern (Dungeonquests: Dungeons.lua)
addPage("OPTIONS_TAB_QUESTS")
addSubPage("OPTIONS_PAGE_QUEST_AUTOMATION")
addSection("SECTION_QUEST_AUTOMATION", { collapsible = true })
addToggles({
  toggle("AUTO_ACCEPT_QUESTS", "autoAcceptQuests"),
  toggle("AUTO_ACCEPT_SHARED", "autoAcceptShared"),
  toggle("AUTO_TURN_IN", "autoTurnIn"),
  requires(toggle("AUTO_CHOOSE_REWARD", "autoChooseReward"), "autoTurnIn"),
  toggle("SKIP_GOSSIP", "skipGossip"),
  toggle("COMFORT_DIALOG_KEYS", "dialogKeys"),
})
builder.AddTextInput({
  label = "QUEST_EXCLUDE",
  advanced = true,
  setting = "questExclude",
  width = QUEST_EXCLUDE_WIDTH,
  get = function(db) return db.questExclude end,
  set = function(text) ns.Set("questExclude", strtrim(text)) end,
})
addSubPage("OPTIONS_PAGE_QUEST_LEARNING")
addSection("SECTION_QUEST_LEARNING", { collapsible = true })
addToggles({
  toggle("QUEST_LEARNING_TOGGLE", "questLearning"),
  toggle("LIBRARY_BOOKS_TOGGLE", "libraryBooks"),
  toggle("QUEST_MAP_TOGGLE", "questMap"),
  requires(toggle("QUEST_MINIMAP_TOGGLE", "questMinimap"), "questMap"),
  toggle("QUEST_ARROW_TOGGLE", "questArrow"),
  toggle("ALT_QUEST_GIVERS_TOGGLE", "altQuestGivers"),
  toggle("BAG_HINTS_TOGGLE", "bagHints", ns.BagQuestMarks.IsAvailable),
})
addSubPage("OPTIONS_PAGE_QUEST_LOG")
addSection("SECTION_QUEST_NOTICES", { collapsible = true })
addToggles({
  toggle("QUEST_PROGRESS_TOGGLE", "announceQuestProgress"),
  toggle("PARTY_QUEST_SYNC_TOGGLE", "partyQuestSync"),
})
addSection("SECTION_QUEST_LOG", { collapsible = true })
addToggles({ toggle("QUEST_CLEANUP_TOGGLE", "questCleanupButton"), toggle("QUEST_LEFTOVERS_TOGGLE", "questLeftovers") })
-- Anzeige: Questlevel, Quest-Buttons, Tooltips und Markierungen an Gegnern und NPCs
addSubPage("COMFORT_PAGE_QUEST_DISPLAY")
addSection("SECTION_QUEST_DISPLAY")
addToggles({
  toggle("QUEST_LEVELS_TOGGLE", "questLevels"),
  toggle("QUEST_LOG_REWARDS_TOGGLE", "questLogRewards"),
  toggle("QUEST_ITEM_TOGGLE", "questItemButton"),
  toggle("QUEST_TARGET_TOGGLE", "questTargetButton"),
  advanced(requires(toggle("QUEST_TARGET_MARKER_TOGGLE", "questTargetMarker"), "questTargetButton")),
  advanced(requires(toggle("QUEST_ZONE_ONLY_TOGGLE", "questButtonsZoneOnly"), "questItemButton", "questTargetButton")),
  toggle("QUEST_TRACKER_TOGGLE", "questTracker", ns.QuestTracker.IsAvailable),
  toggle("REWARD_HINT_TOGGLE", "rewardHint"),
  toggle("QUEST_EFFICIENCY_TOGGLE", "questEfficiencyTooltip"),
  toggle("QUEST_ITEM_TOOLTIP_TOGGLE", "questItemTooltip"),
  toggle("BAG_QUEST_MARKS_TOGGLE", "bagQuestItemMarks"),
})
O.addFramePreview("QUEST_ITEM_PREVIEW", "questItem")
if ns.QuestTextSize.IsAvailable() then
  addToggles({ advanced(toggle("QUEST_TEXT_RESIZE", "questTextResize")) })
  addSlider({
    label = "QUEST_TEXT_SIZE",
    advanced = true,
    min = ns.QuestTextSize.MIN,
    max = ns.QuestTextSize.MAX,
    step = 1,
    get = function(db) return db.questTextSize end,
    set = function(value) ns.SetDeferred("questTextSize", value) end,
    format = function(value) return tostring(value) end,
    enabled = function(db) return db.questTextResize end,
  })
end
if ns.QuestMarks.IsAvailable() then
  addSubPage("OPTIONS_PAGE_QUEST_MARKS")
  addSection("SECTION_QUEST_MARKS")
  addToggles({ toggle("QUEST_MARKS_TOGGLE", "questMarks"),
    requires(toggle("QUEST_MARK_PROGRESS_TOGGLE", "questMarkProgress"), "questMarks"),
    requires(toggle("QUEST_TARGETS_TAKE_TOGGLE", "questTargetsTake", ns.QuestTargets.IsAvailable), "questMarks"),
    requires(toggle("QUEST_TARGETS_PARTY_TOGGLE", "questTargetsParty", ns.QuestTargets.IsAvailable), "questMarks") })
  addSlider(requires({
    label = "QUEST_MARK_SCALE",
    advanced = true,
    setting = "questMarkScale",
    min = toPercent(ns.QuestMarks.MIN_SCALE),
    max = toPercent(ns.QuestMarks.MAX_SCALE),
    step = 5,
    get = function(db) return toPercent(db.questMarkScale) end,
    set = function(value) ns.SetDeferred("questMarkScale", value / 100) end,
    format = percent,
  }, "questMarks"))
end
-- Klassenquests: Erinnerung an die nächste Klassenquest, nur wo es die Daten gibt
if ns.ClassQuests.IsAvailable() then
  addSubPage("OPTIONS_PAGE_CLASS_QUESTS")
  addToggles({ toggle("REMIND_CLASS_QUEST_TOGGLE", "remindClassQuest") })
end
finishSubPages()
finishPage()
