-- Optionen, Reiter Komfort (2/3): Quests und Quest-Anzeige.
local _, ns = ...
local O = ns.OptionsCore
local builder, addSection, addSlider, addToggles, addSubPage, toggle, advanced, requires, percent, toPercent = O.builder, O.addSection, O.addSlider, O.addToggles, O.addSubPage, O.toggle, O.advanced, O.requires, O.percent, O.toPercent

local QUEST_EXCLUDE_WIDTH = 200  -- Eingabefeld für die eigene Sperrliste der Quest-Automatik

-- Quests: Automatik, Hinweise, Markierungen, Anzeigen und Helfer rund um den Questlog (alles zu Quests an einem Ort)
addSubPage("COMFORT_PAGE_QUESTS")
addSection("COMFORT_PAGE_AUTOMATION", { collapsible = true })
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
addSection("SECTION_QUEST_NOTICES", { collapsible = true })
addToggles({
  toggle("QUEST_PROGRESS_TOGGLE", "announceQuestProgress"),
  toggle("PARTY_QUEST_SYNC_TOGGLE", "partyQuestSync"),
  toggle("WARN_QUEST_LOG_FULL_TOGGLE", "warnQuestLogFull"),
  toggle("ALERT_TOGGLE_QUEST_COMPLETE", "alertQuestComplete"),
  toggle("ALERT_TOGGLE_QUEST_OBJECTIVE", "alertQuestObjective"),
})
addSection("SECTION_QUEST_LEARNING", { collapsible = true })
addToggles({ toggle("QUEST_LEARNING_TOGGLE", "questLearning"), toggle("QUEST_MAP_TOGGLE", "questMap") })
addSection("SECTION_QUEST_LOG", { collapsible = true })
addToggles({ toggle("QUEST_CLEANUP_TOGGLE", "questCleanupButton"), toggle("QUEST_LEFTOVERS_TOGGLE", "questLeftovers") })
-- Quest-Anzeige: Questlevel, Quest-Buttons, Tooltips und Markierungen an Gegnern und NPCs
addSubPage("COMFORT_PAGE_QUEST_DISPLAY")
addSection("SECTION_QUEST_DISPLAY")
addToggles({
  toggle("QUEST_LEVELS_TOGGLE", "questLevels"),
  toggle("QUEST_ITEM_TOGGLE", "questItemButton"),
  toggle("QUEST_TARGET_TOGGLE", "questTargetButton"),
  advanced(requires(toggle("QUEST_TARGET_MARKER_TOGGLE", "questTargetMarker"), "questTargetButton")),
  advanced(requires(toggle("QUEST_ZONE_ONLY_TOGGLE", "questButtonsZoneOnly"), "questItemButton", "questTargetButton")),
  toggle("REWARD_HINT_TOGGLE", "rewardHint"),
  toggle("QUEST_EFFICIENCY_TOGGLE", "questEfficiencyTooltip"),
  toggle("QUEST_ITEM_TOOLTIP_TOGGLE", "questItemTooltip"),
})
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
  addSection("SECTION_QUEST_MARKS")
  addToggles({ toggle("QUEST_MARKS_TOGGLE", "questMarks"),
    requires(toggle("QUEST_MARK_PROGRESS_TOGGLE", "questMarkProgress"), "questMarks") })
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
