-- Einstellungen: jede Einstellung hat nach dem Umbau in Kategorien (Seitenleisten) noch ein Steuerelement, das auf
-- seiner Seite sichtbar wird; Unterseiten wechseln, die Fensterhöhe richtet sich nach der längsten Unterseite.
local L = addon.L
local options = addon.OptionsWindow

wow.login()
addon.Set("optionsAdvanced", true)  -- jede Einstellung: alle Optionen zeigen (neue Installationen starten einfach)
SlashCmdList.LEVELTIMER("config")

expect("leere Suche ohne Treffer", #options.Search(""), 0)

-- Eintrag zu einem Locale-Key (Tooltip <KEY>_TIP bzw. Beschriftung L[KEY])
local function findEntry(labelKey)
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if not entry.isPage and (entry.tipKey == labelKey .. "_TIP" or entry.title() == L[labelKey]) then return entry end
  end
end

---------------------------------------------------------------------------
-- Jede Seite und Unterseite lässt sich zeigen; ihre Bausteine sind dann sichtbar, die der anderen nicht
---------------------------------------------------------------------------
local pages = options.PageKeys()
expectTrue("mehrere Seiten", #pages > 20)
local tabs = {}
for _, page in ipairs(pages) do tabs[page.tab] = true end
for _, key in ipairs({ "SECTION_GENERAL", "STATISTICS", "OPTIONS_TAB_NOTIFICATIONS", "OPTIONS_TAB_ALERTS",
  "OPTIONS_TAB_COMFORT", "OPTIONS_TAB_SPEEDRUN", "OPTIONS_TAB_PROFILES" }) do
  expectTrue("Reiter " .. key, tabs[key])
end
expect("Stream ist kein Reiter mehr", tabs.OPTIONS_TAB_STREAM, nil)
expect("Timer ist kein Reiter mehr", tabs.OPTIONS_TAB_TIMERS, nil)

for _, page in ipairs(pages) do
  local key = page.sub or page.tab
  expectTrue("zeigen: " .. key, options.ShowPage(key))
  local tab, sub = options.CurrentPage()
  expect("Reiter von " .. key, tab, page.tab)
  expect("Unterseite von " .. key, sub, page.sub)
end

-- Jeder Schalter, Regler, jede Auswahl: sichtbar, sobald seine Seite gezeigt wird
local checked = 0
local function allEntries()
  -- Jede Beschriftung enthält einen Buchstaben: Suche nach jedem Buchstaben einmal, ohne Doppelte
  local seen, list = {}, {}
  for byte = string.byte("a"), string.byte("z") do
    for _, entry in ipairs(options.Search(string.char(byte))) do
      if not seen[entry] then
        seen[entry] = true
        table.insert(list, entry)
      end
    end
  end
  return list
end
for _, entry in ipairs(allEntries()) do
  if not entry.isPage and entry.left.IsVisible then
    options.ShowPage(entry.sub and entry.sub.key or entry.tab.key)
    checked = checked + 1
    expectTrue("sichtbar: " .. tostring(entry.title()), entry.left:IsVisible())
  end
end
expectTrue("viele Bausteine geprüft", checked > 200)

---------------------------------------------------------------------------
-- Alle Einstellungen von vorher haben weiter ein Steuerelement (Retail-Stub; client-abhängige stehen in OPTIONAL)
---------------------------------------------------------------------------
local EXPECTED = {
  "TEXT_LABELS", "SHOW_TIMER", "LOCK_FRAME", "SHOW_XP_BAR", "AUTO_INSTANCE_TAB", "QUEST_XP_ON_BAR",
  "XP_RATE_WITHOUT_AFK", "LEVEL_UP_SUMMARY_TOGGLE", "LEVEL_UP_GAINS_TOGGLE", "RESTED_ALT_NOTICE_TOGGLE",
  "SESSION_COMPARE_TOGGLE", "ANNOUNCE_RECORDS_TOGGLE", "REMIND_FOOD_TOGGLE", "REMIND_BREAK_TOGGLE",
  "WARN_BAGS_FULL_TOGGLE", "WARN_DURABILITY_TOGGLE", "WARN_INSTANCE_LIMIT_TOGGLE", "WARN_AGGRO_TOGGLE",
  "WARN_BREATH_TOGGLE", "LOW_MANA_TOGGLE", "CC_ANNOUNCE_TOGGLE", "CC_OVER_TOGGLE", "HEALER_AGGRO_TOGGLE",
  "QUEST_PROGRESS_TOGGLE", "WARN_QUEST_LOG_FULL_TOGGLE", "INSTANCE_REPORT_TOGGLE", "FLIGHT_TIMER_TOGGLE",
  "FLIGHT_SOUND", "FLIGHT_TOOLTIP_TOGGLE", "AUTO_REPAIR", "AUTO_SELL_JUNK", "AUTO_ACCEPT_QUESTS",
  "AUTO_ACCEPT_SHARED", "AUTO_TURN_IN", "AUTO_CHOOSE_REWARD", "SKIP_GOSSIP", "AUTO_ACCEPT_SUMMON",
  "AUTO_ACCEPT_RESURRECT", "AUTO_RELEASE_PVP", "DECLINE_TRADES", "DECLINE_GROUP_INVITES", "DECLINE_GUILD_INVITES",
  "DECLINE_DUELS", "DECLINE_SHARED_QUESTS", "ACCEPT_FRIEND_INVITES", "INVITE_INFO_TOGGLE", "INVITE_FROM_WHISPER",
  "CHAT_COPY_TOGGLE", "RESTORE_CHAT", "FILTER_DRUNK_SPAM", "FILTER_SPELL_LINKS", "HIDE_COMBAT_LOG_TAB",
  "HIDE_CHAT_BUTTONS", "CHAT_EDIT_BOX_TOP", "CHAT_ARROW_KEYS", "NO_CHAT_FADE", "HIDE_ERRORS", "HIDE_ZONE_TEXT",
  "HIDE_KEYBIND_TEXT", "HIDE_MACRO_TEXT", "RANGE_COLOR", "MOVE_FRAMES", "QUEST_LEARNING_TOGGLE", "QUEST_MAP_TOGGLE",
  "QUEST_CLEANUP_TOGGLE", "QUEST_LEFTOVERS_TOGGLE", "QUEST_LEVELS_TOGGLE", "QUEST_ITEM_TOGGLE", "QUEST_TARGET_TOGGLE",
  "QUEST_TARGET_MARKER_TOGGLE", "QUEST_ZONE_ONLY_TOGGLE", "REWARD_HINT_TOGGLE", "QUEST_EFFICIENCY_TOGGLE",
  "QUEST_ITEM_TOOLTIP_TOGGLE", "TOOLTIP_CLASS_COLORS", "TOOLTIP_TARGET_TOGGLE", "TOOLTIP_HIDE_IN_COMBAT",
  "TOOLTIP_KILLS_TO_LEVEL_TOGGLE", "MAP_COORDS_TOGGLE", "DEATH_MAP_TOGGLE", "CORPSE_ARROW_TOGGLE", "FASTER_LOOT",
  "SKIP_LOOT_CONFIRM", "LOOT_ROLL_COUNTS_TOGGLE", "LOOT_ROLL_NAMES_TOGGLE", "LOOT_ROLL_SUMMARY_TOGGLE",
  "LOOT_ROLL_JOURNAL_TOGGLE", "EASY_DELETE", "FASTER_MOVIE_SKIP", "MAX_CAMERA_ZOOM", "NO_DRUNKEN_HAZE",
  "NO_SCREEN_EFFECTS", "SET_WEATHER_DENSITY", "SILENCE_RESTED_EMOTES", "COMBAT_PLATES", "STREAMER_PRIVACY",
  "HIGHLIGHT_DEATHS", "ALERT_TOGGLE_LEVEL_UP", "ALERT_TOGGLE_RARE", "ALERT_TOGGLE_ELITE", "ALERT_TOGGLE_LOOT",
  "ALERT_TOGGLE_RARE_SPOTTED", "ALERT_TOGGLE_RARE_FLASH", "ALERT_TOGGLE_QUEST_COMPLETE",
  "ALERT_TOGGLE_QUEST_OBJECTIVE", "LEVEL_UP_WINDOW_TOGGLE", "LEVEL_UP_HIDE_BLIZZARD", "LEVEL_UP_COMPACT",
  "LEVEL_UP_SOUND", "ALERT_SOUND", "SHOW_SPLIT_LIST", "SHOW_SPLIT_TOTAL", "SHOW_SPLIT_PLAYED", "GOLD_SPLIT_NOTICE",
  "SHOW_SPLIT_FORECAST", "SHOW_CUSTOM_SPLITS", "QUEST_SPLIT_NOTICE", "FRIEND_RACE", "PB_SAME_CLASS",
  "SHOW_WORLD_RECORDS", "SHOW_RECORDS_AGE", "MILESTONE_SCREENSHOTS", "SCREENSHOT_FIRST_DUNGEON",
  "SCREENSHOT_EPIC_LOOT", "SHOW_MINIMAP", "STREAM_MODE", "STREAM_HIDE_MINIMAP",
  -- Regler, Auswahlzeilen, Zyklus-Buttons, Eingabefelder
  "ALERT_DURATION", "ALERT_STYLE", "ALERT_SCALE", "BG_OPACITY", "WINDOW_SIZE", "BREAK_MINUTES", "FADE_ALPHA",
  "IDLE_LIMIT", "INVITE_KEYWORD", "LANGUAGE", "LEVEL_UP_ANNOUNCE", "LEVEL_UP_DURATION", "LEVEL_UP_THEME",
  "LEVEL_UP_SCALE", "LOW_MANA_BELOW", "QUEST_EXCLUDE", "REMINDER_INTERVAL", "ROW_ORDER_STAT", "SPLIT_COMPARISON",
  "SPLIT_LIST_ROWS", "SPLIT_LIST_SIZE", "SPLIT_LIST_VISIBILITY", "SPLIT_TOLERANCE", "SSF_CATEGORY", "THEME",
  "THEME_ACCENT", "THEME_FONT", "THEME_FONT_SIZE", "THEME_OUTLINE", "TILE_COLUMNS", "TO_LEVEL_SAMPLES",
  "WARN_BREATH_BELOW", "WEATHER_DENSITY", "WINDOW_BACKGROUND", "WINDOW_LAYOUT", "WINDOW_VISIBILITY",
  "WORLD_RECORD_SCOPE", "XPBAR_TEXT", "XPBAR_WIDTH", "LOOT_ROLL_CARD_SCALE", "FLIGHT_SCALE", "CHOSEN_ROW_1",
  "CHOSEN_ROW_2", "CHOSEN_ROW_3", "OPTIONS_ADVANCED", "SHOW_SPLIT_HEADER", "THEME_MIN_FONT_SIZE", "THEME_BAR_TEXTURE",
  "VALUE_COLORS",
}
for _, key in ipairs(EXPECTED) do
  expectTrue("Steuerelement für " .. key, findEntry(key) ~= nil)
end
-- Jede Stat-Zeile, die der Client kann, hat ihren Schalter
for _, line in ipairs(addon.STAT_LINES) do
  if not line.available or line.available() then
    expectTrue("Stat-Schalter " .. line.label, findEntry(line.label) ~= nil)
  end
end

---------------------------------------------------------------------------
-- Neue Orte: Quest-Dinge gesammelt unter Komfort > Quests, Stream unter Allgemein, Timer und Flüge unter Komfort,
-- alles zum Level-Up unter Einblendungen > Level-Up, Ausblenden an einem Ort (UX S11/S15/S16/S20)
---------------------------------------------------------------------------
local function placeOf(labelKey)
  local entry = findEntry(labelKey)
  return entry and entry.tab.key, entry and entry.sub and entry.sub.key
end
for _, case in ipairs({
  { "AUTO_ACCEPT_QUESTS", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_QUESTS" },
  { "QUEST_EXCLUDE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_QUESTS" },
  { "QUEST_PROGRESS_TOGGLE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_QUESTS" },
  { "WARN_QUEST_LOG_FULL_TOGGLE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_QUESTS" },
  { "ALERT_TOGGLE_QUEST_COMPLETE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_QUESTS" },
  { "STREAM_MODE", "SECTION_GENERAL", "OPTIONS_TAB_STREAM" },
  { "WINDOW_VISIBILITY", "SECTION_GENERAL", "OPTIONS_PAGE_WINDOW" },
  { "WINDOW_LAYOUT", "SECTION_GENERAL", "OPTIONS_PAGE_LAYOUT" },
  { "FOOD_TIMER_TOGGLE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_TIMERS" },
  { "FLIGHT_TIMER_TOGGLE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_TRAVEL" },
  { "LEVEL_UP_SUMMARY_TOGGLE", "OPTIONS_TAB_ALERTS", "OPTIONS_PAGE_LEVEL_UP" },
  { "LEVEL_UP_ANNOUNCE", "OPTIONS_TAB_ALERTS", "OPTIONS_PAGE_LEVEL_UP" },
  { "ALERT_TOGGLE_LEVEL_UP", "OPTIONS_TAB_ALERTS", "OPTIONS_PAGE_LEVEL_UP" },
  { "LEVEL_UP_WINDOW_TOGGLE", "OPTIONS_TAB_ALERTS", "OPTIONS_PAGE_LEVEL_UP" },
  { "SESSION_COMPARE_TOGGLE", "OPTIONS_TAB_NOTIFICATIONS", "OPTIONS_PAGE_LOGIN" },
  { "BLIZZ_FRAME_CHAT_BUTTONS", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_HIDE" },  -- Blizzard-Leisten: blizzard_hide
  { "MOVE_FRAMES", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_MAPS" },
  { "FASTER_LOOT", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_LOOT" },
  { "LOOT_ROLL_COUNTS_TOGGLE", "OPTIONS_TAB_COMFORT", "COMFORT_PAGE_LOOT" },
  { "SHOW_MINIMAP", "SECTION_GENERAL", "OPTIONS_PAGE_WINDOW" },
  { "STREAM_LAYOUT", "SECTION_GENERAL", "OPTIONS_TAB_STREAM" },
  { "LOW_MANA_TOGGLE", "OPTIONS_TAB_NOTIFICATIONS", "OPTIONS_PAGE_GROUP" },
  { "REMIND_TRAINER_TOGGLE", "OPTIONS_TAB_NOTIFICATIONS", "OPTIONS_PAGE_REMINDERS" },
  { "FRIEND_RACE", "OPTIONS_TAB_SPEEDRUN", "OPTIONS_PAGE_COMPARE" },
  { "STAT_XP_RATE", "STATISTICS", "OPTIONS_PAGE_STAT_XP" },
}) do
  local tab, sub = placeOf(case[1])
  if tab or case[1] ~= "REMIND_TRAINER_TOGGLE" then  -- Lehrer-Erinnerung gibt es nicht in Retail
    expect(case[1] .. ": Reiter", tab, case[2])
    expect(case[1] .. ": Unterseite", sub, case[3])
  end
end

---------------------------------------------------------------------------
-- Unterseiten: Klick in der Seitenleiste wechselt, Wechsel springt nach oben; Fensterhöhe = längste Unterseite
---------------------------------------------------------------------------
expectTrue("Reiter Hinweise", wow.click(L.OPTIONS_TAB_NOTIFICATIONS))
expectTrue("Warnungen wählen", wow.click(L.OPTIONS_PAGE_WARNINGS))
local _, sub = options.CurrentPage()
expect("Warnungen gezeigt", sub, "OPTIONS_PAGE_WARNINGS")
local bags = findEntry("WARN_BAGS_FULL_TOGGLE")
expect("Taschen-Warnung sichtbar", bags.left:IsVisible(), true)
expect("Login-Seite verdeckt", findEntry("SESSION_COMPARE_TOGGLE").left:IsVisible(), false)
local scroll = bags.tab.scroll
scroll:SetVerticalScroll(300)
wow.click(L.OPTIONS_PAGE_GROUP)
expect("Unterseitenwechsel scrollt nach oben", scroll:GetVerticalScroll(), 62)

-- Zuletzt gezeigte Seite bleibt beim Schließen und Öffnen
SlashCmdList.LEVELTIMER("config")
SlashCmdList.LEVELTIMER("config")
local tab
tab, sub = options.CurrentPage()
expect("wieder offen: Reiter", tab, "OPTIONS_TAB_NOTIFICATIONS")
expect("wieder offen: Unterseite", sub, "OPTIONS_PAGE_GROUP")

-- Höhe: kleiner als die Summe aller Unterseiten eines Reiters (nur die längste zählt)
UIParent:SetHeight(100000)
addon.ApplySettings()
expectTrue("Fenster nicht riesig", LevelTimerOptions:GetHeight() < 900)

-- Edit-Modus "Einstellungen" springt auf die Unterseite der Anzeige
addon.ShowOptionsPage("OPTIONS_PAGE_SPLIT_LIST")
tab, sub = options.CurrentPage()
expect("Split-Liste: Reiter", tab, "OPTIONS_TAB_SPEEDRUN")
expect("Split-Liste: Unterseite", sub, "OPTIONS_PAGE_SPLIT_LIST")
for _, id in ipairs({ "main", "splitList", "alert", "levelUp", "flight", "food", "lootRolls" }) do
  local reg = addon.Frames.Get(id)
  if reg and reg.settingsPage then
    expectTrue("Seite für " .. id .. " gibt es", options.ShowPage(reg.settingsPage))
  end
end

LevelTimerOptions:Hide()
expect("keine Fehler", #wow.errors, 0)
