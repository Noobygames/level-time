-- Einstellungsfenster mit Reitern: Allgemein (Fenster, Sprache), Statistiken, Hinweise, Einblendungen, Komfort, Stream, Speedrun, Profile.
-- Darunter auf allen Reitern: Neue Session, Zusammenfassung, Historie.
-- Nur der Inhalt; Aufbau, Tooltips, Breite und Aktualisierung übernimmt Lib/OptionsBuilder.lua.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local TimerWindow = ns.TimerWindow
local Alerts = ns.Alerts
local Builder = ns.OptionsBuilder

local MAX_PROFILE_ROWS = 6     -- so viele Profile listet der Reiter "Profile"
local ROW_PROFILE = 20
local PROFILE_NAME_WIDTH = 160
local PROFILE_SAVE_WIDTH = 120
local DELETE_PROFILE_POPUP = "LEVELTIMER_DELETE_PROFILE"
local QUEST_EXCLUDE_WIDTH = 200  -- Eingabefeld für die eigene Sperrliste der Quest-Automatik

local builder = Builder.New({
  name = "LevelTimerOptions",
  alpha = 0.95,
  title = function() return ns.DISPLAY_NAME .. " - " .. L.SETTINGS end,
})
local addPage, finishPage, addSection, addSlider = builder.AddPage, builder.FinishPage, builder.AddSection, builder.AddSlider
local addToggles, addButton, addFooterButton = builder.AddToggles, builder.AddButton, builder.AddFooterButton
local addChooser, addHint = builder.AddChooser, builder.AddHint
local toggle, localized = Builder.Toggle, Builder.Localized

-- Sprachnamen stehen immer in der eigenen Sprache
local function addLanguageChooser()
  local choices = {}
  for i, language in ipairs(ns.languages) do
    choices[i] = { value = language.code, name = function() return language.name end }
  end
  addChooser({ label = "LANGUAGE", setting = "language", choices = choices })
end

-- Vergleich der Splits; ein fester Charakter wird per /lt compare Name gewählt
local function addSplitComparisonChooser()
  local Splits = ns.Splits
  addChooser({ label = "SPLIT_COMPARISON", setting = "splitComparison", choices = {
    { value = Splits.BEST, name = localized("COMPARE_CHOICE_BEST") },
    { value = Splits.PERSONAL_BEST, name = localized("COMPARE_CHOICE_PB") },
    { value = Splits.RUN, name = localized("COMPARE_CHOICE_RUN") },
  } })
end

-- Speedrun-Rekorde: schnellster Lauf insgesamt oder der eigenen Klasse
local function addWorldRecordScopeChooser()
  local WorldRecords = ns.WorldRecords
  addChooser({ label = "WORLD_RECORD_SCOPE", setting = "worldRecordScope", choices = {
    { value = WorldRecords.CLASS, name = localized("WORLD_RECORD_OWN_CLASS") },
    { value = WorldRecords.OVERALL, name = localized("WORLD_RECORD_ALL_CLASSES") },
  } })
end

-- Level-Up-Ansage: aus, Gruppe oder Gilde
local function addAnnounceChooser()
  local Summary = ns.LevelUpSummary
  addChooser({ label = "LEVEL_UP_ANNOUNCE", setting = "levelUpAnnounce", choices = {
    { value = Summary.ANNOUNCE_OFF, name = localized("ANNOUNCE_OFF") },
    { value = Summary.ANNOUNCE_PARTY, name = localized("ANNOUNCE_PARTY") },
    { value = Summary.ANNOUNCE_GUILD, name = localized("ANNOUNCE_GUILD") },
  } })
end

-- Hintergrund des Fensters: Standard oder Chroma-Farbe für Streams
local function addBackgroundChooser()
  addChooser({ label = "WINDOW_BACKGROUND", setting = "windowBackground", choices = {
    { value = TimerWindow.BACKGROUND_DEFAULT, name = localized("BACKGROUND_DEFAULT") },
    { value = "green", name = localized("BACKGROUND_GREEN") },
    { value = "magenta", name = localized("BACKGROUND_MAGENTA") },
  } })
end

-- Profile: Liste (Klick wechselt, Rechtsklick löscht), Name + Speichern, Export und Import
StaticPopupDialogs[DELETE_PROFILE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, name)
    ns.Profiles.Delete(name)
    ns.ApplySettings()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- Liste der Profile: MAX_PROFILE_ROWS Zeilen; mehr Profile per Mausrad oder Scrollleiste erreichbar
local function addProfileList()
  local Profiles = ns.Profiles
  local page = builder.Page()
  local listOffset = 0
  local scrollBar

  local function maxOffset()
    return math.max(0, #Profiles.GetNames() - MAX_PROFILE_ROWS)
  end

  local function scrollTo(offset)
    listOffset = math.max(0, math.min(maxOffset(), offset))
    builder.Refresh(ns.db)
  end

  scrollBar = Widgets.CreateScrollBar(page, scrollTo)
  scrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -Builder.MARGIN, builder.RowY())
  scrollBar:SetHeight(MAX_PROFILE_ROWS * ROW_PROFILE)
  builder.OnRefresh(function()
    listOffset = math.min(listOffset, maxOffset())
    scrollBar:SetRange(maxOffset())
    scrollBar:SetOffsetSilently(listOffset)
  end)

  for index = 1, MAX_PROFILE_ROWS do
    local tab = Widgets.CreateTab(builder.Page(), "GameFontHighlight", function(self, mouseButton)
      local name = self.profileName
      if mouseButton == "RightButton" then
        StaticPopupDialogs[DELETE_PROFILE_POPUP].text = L.PROFILE_DELETE_CONFIRM
        StaticPopup_Show(DELETE_PROFILE_POPUP, Profiles.DisplayName(name), nil, name)
      else
        Profiles.Switch(name)
      end
    end)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab:EnableMouseWheel(true)
    tab:SetScript("OnMouseWheel", function(_, delta) scrollTo(listOffset - delta) end)
    builder.AddRow(tab, ROW_PROFILE)
    builder.AddTooltip(tab, "PROFILE_LIST_TIP", function() return Profiles.DisplayName(tab.profileName) end)
    builder.OnRefresh(function()
      local name = Profiles.GetNames()[listOffset + index]
      tab.profileName = name
      tab:SetShown(name ~= nil)
      if name then
        tab:SetLabel(Profiles.DisplayName(name))
        tab:SetActive(name == Profiles.GetActive())
      end
    end)
  end
end

-- Import-Fenster für Profile (auch /lt profile import); das neue Profil wird nicht sofort aktiv
function ns.ShowProfileImport()
  ns.Export.ShowImport(L.PROFILE_IMPORT, function(text)
    local name = ns.Profiles.Import(text)
    if not name then return L.PROFILE_IMPORT_INVALID, false end
    ns.ApplySettings()
    return string.format(L.PROFILE_IMPORTED, name), true
  end)
end

local OVERWRITE_PROFILE_POPUP = "LEVELTIMER_OVERWRITE_PROFILE"

local function addProfileSaver()
  local page = builder.Page()
  local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  nameBox:SetSize(PROFILE_NAME_WIDTH, Builder.BUTTON_HEIGHT)
  nameBox:SetAutoFocus(false)
  nameBox:SetPoint("TOPLEFT", Builder.MARGIN + 6, builder.RowY())  -- Vorlage zeichnet ihren Rand links außerhalb
  local function save(name)
    if ns.Profiles.SaveAs(name) then
      ns.Print(string.format(L.PROFILE_SAVED, name))
      nameBox:SetText("")
      ns.ApplySettings()
    end
  end
  StaticPopupDialogs[OVERWRITE_PROFILE_POPUP] = {
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(_, name) save(name) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  local saveButton = Widgets.CreateButton(page, PROFILE_SAVE_WIDTH, Builder.BUTTON_HEIGHT, function()
    local name = strtrim(nameBox:GetText())
    if name == "" then
      ns.Print(L.PROFILE_NAME_EMPTY)
    elseif ns.Profiles.Exists(name) then
      StaticPopupDialogs[OVERWRITE_PROFILE_POPUP].text = L.PROFILE_OVERWRITE_CONFIRM  -- aktuelle Sprache
      StaticPopup_Show(OVERWRITE_PROFILE_POPUP, name, nil, name)
    else
      save(name)
    end
  end)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", Builder.CHOOSER_TAB_GAP, 0)
  builder.AddTooltip(saveButton, "PROFILE_SAVE_TIP", localized("PROFILE_SAVE"))
  nameBox:SetScript("OnEnterPressed", function() saveButton:Click() end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  builder.Advance(Builder.ROW_BUTTON)
  builder.OnRefresh(function() Widgets.SetButtonText(saveButton, L.PROFILE_SAVE, PROFILE_SAVE_WIDTH) end)
end

local function percent(value)
  return value .. "%"
end

local function toPercent(fraction)
  return math.floor(fraction * 100 + 0.5)
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Allgemein: Fenster und grundlegende Einstellungen
addPage("SECTION_GENERAL")
addSection("SECTION_WINDOW")
addSlider({
  label = "WINDOW_SIZE",
  min = toPercent(TimerWindow.MIN_SCALE),
  max = toPercent(TimerWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(db.scale) end,
  set = function(value) ns.Set("scale", value / 100) end,
  format = percent,
})
addSlider({
  label = "BG_OPACITY",
  min = 0,
  max = 100,
  step = 5,
  get = function(db) return toPercent(db.bgAlpha) end,
  set = function(value) ns.Set("bgAlpha", value / 100) end,
  format = percent,
})
addToggles({
  toggle("SHOW_TIMER", "showTimer"),
  toggle("LOCK_FRAME", "locked"),
  toggle("SHOW_XP_BAR", "showXpBar"),
  toggle("COMPACT_MODE", "compactMode"),
  toggle("HORIZONTAL_LAYOUT", "horizontalLayout"),
  toggle("AUTO_INSTANCE_TAB", "autoInstanceTab"),
})
addButton("RESET_WINDOW", function() TimerWindow.ResetLayout() end)
addHint("OPTIONS_HINT")
addSection("SECTION_LANGUAGE")
addLanguageChooser()
addToggles({
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end },
})
finishPage()

-- Statistiken: ein Schalter je Stat-Zeile, direkt aus ns.STAT_LINES
addPage("STATISTICS")
addSection("SECTION_STAT_PRESETS")
local presetButtons = {}
for i, preset in ipairs(ns.STAT_PRESETS) do
  presetButtons[i] = { label = preset.label, onClick = function() ns.ApplyStatPreset(preset) end }
end
builder.AddButtonRow(presetButtons)
for _, group in ipairs(ns.STAT_GROUPS) do
  addSection(group)
  local statToggles = {}
  for _, line in ipairs(ns.STAT_LINES) do
    if line.group == group then table.insert(statToggles, toggle(line.label, line.setting, line.available)) end
  end
  addToggles(statToggles)
  if group == "STAT_GROUP_INSTANCE" then
    addButton("INSTANCE_RESET", function() ns.ConfirmInstanceReset() end)
  end
end
addSection("SECTION_CALCULATION")
addToggles({ toggle("XP_RATE_WITHOUT_AFK", "xpRateWithoutAfk") })
finishPage()

-- Hinweise: Level-Up im Chat und Erinnerungen an Buffs
addPage("OPTIONS_TAB_NOTIFICATIONS")
addSection("SECTION_LEVEL_UP")
addToggles({ toggle("LEVEL_UP_SUMMARY_TOGGLE", "levelUpSummary"), toggle("LEVEL_UP_GAINS_TOGGLE", "levelUpGains") })
addAnnounceChooser()
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
  toggle("REMIND_CHARGED_TOGGLE", "remindCharged", ns.BuffReminder.HasChargedSystem),
})
-- Klassen-Hinweise: nur die der eigenen Klasse; Beschriftung mit den Zaubernamen in der Sprache des Clients
local classReminders = ns.ClassBuffs.ForPlayerClass()
if #classReminders > 0 then
  addSection("SECTION_CLASS_REMINDERS")
  local classToggles = {}
  for _, reminder in ipairs(classReminders) do
    local classToggle = toggle("REMIND_CLASS_TOGGLE", reminder.setting)
    classToggle.text = function() return ns.ClassBuffs.Label(reminder) end
    classToggle.tip = ns.ClassBuffs.TipKey(reminder)
    table.insert(classToggles, classToggle)
  end
  addToggles(classToggles)
end
addSlider({
  label = "REMINDER_INTERVAL",
  min = ns.BuffReminder.MIN_INTERVAL,
  max = ns.BuffReminder.MAX_INTERVAL,
  step = 1,
  get = function(db) return db.reminderInterval end,
  set = function(value) ns.Set("reminderInterval", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
-- Pausen-Erinnerung (BreakReminder.lua)
addToggles({ toggle("REMIND_BREAK_TOGGLE", "remindBreak") })
addSlider({
  label = "BREAK_MINUTES",
  min = ns.BreakReminder.MIN_MINUTES,
  max = ns.BreakReminder.MAX_MINUTES,
  step = 15,
  get = function(db) return db.breakMinutes end,
  set = function(value) ns.Set("breakMinutes", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
addSection("SECTION_WARNINGS")
addHint("WARN_LOOK_HINT")
addToggles({
  toggle("WARN_BAGS_FULL_TOGGLE", "warnBagsFull"),
  toggle("WARN_DURABILITY_TOGGLE", "warnDurability"),
  toggle("REMIND_TRAINER_TOGGLE", "remindTrainer", ns.TrainerReminder.IsAvailable),
  toggle("WARN_AMMO_TOGGLE", "warnAmmo", ns.GearWarnings.ShowsAmmoOptions),
  toggle("WARN_INSTANCE_LIMIT_TOGGLE", "warnInstanceLimit"),
  toggle("WARN_AGGRO_TOGGLE", "warnAggro"),
  toggle("WARN_BREATH_TOGGLE", "warnBreath"),
  toggle("LOW_MANA_TOGGLE", "announceLowMana"),
  toggle("CC_ANNOUNCE_TOGGLE", "announceControlLoss"),
  toggle("CC_OVER_TOGGLE", "announceControlOver"),
  toggle("HEALER_AGGRO_TOGGLE", "announceHealerAggro"),
})
addSlider({
  label = "WARN_BREATH_BELOW",
  min = ns.BreathWarning.MIN_SECONDS,
  max = ns.BreathWarning.MAX_SECONDS,
  step = 1,
  get = function(db) return db.breathWarnSeconds end,
  set = function(value) ns.Set("breathWarnSeconds", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addSlider({
  label = "LOW_MANA_BELOW",
  min = ns.ManaCallout.MIN_PERCENT,
  max = ns.ManaCallout.MAX_PERCENT,
  step = 5,
  get = function(db) return db.lowManaPercent end,
  set = function(value) ns.Set("lowManaPercent", value) end,
  format = percent,
})
-- Munition: nur für Jäger
if ns.GearWarnings.ShowsAmmoOptions() then
  addSlider({
    label = "WARN_AMMO_BELOW",
    min = ns.GearWarnings.MIN_AMMO,
    max = ns.GearWarnings.MAX_AMMO,
    step = 20,
    get = function(db) return db.ammoLow end,
    set = function(value) ns.Set("ammoLow", value) end,
    format = function(value) return string.format(L.AMMO_COUNT, value) end,
  })
  addSlider({
    label = "WARN_AMMO_CRITICAL_BELOW",
    min = 0,
    max = ns.GearWarnings.MAX_CRITICAL_AMMO,
    step = 10,
    get = function(db) return db.ammoCritical end,
    set = function(value) ns.Set("ammoCritical", value) end,
    format = function(value) return value == 0 and L.AMMO_OFF or string.format(L.AMMO_COUNT, value) end,
  })
  addSlider({
    label = "WARN_AMMO_REPEAT",
    min = 0,
    max = ns.GearWarnings.MAX_AMMO_REPEAT,
    step = 1,
    get = function(db) return db.ammoRepeat end,
    set = function(value) ns.Set("ammoRepeat", value) end,
    format = function(value) return value == 0 and L.AMMO_ONCE or string.format(L.MINUTES, value) end,
  })
end
finishPage()

-- Timer: Lagerfeuer (nur WoW Forever), Essen und Flüge (überall, daher gibt es den Reiter immer)
do
  addPage("OPTIONS_TAB_TIMERS")
  -- Größe, Vorschau, Verschieben und Zurücksetzen einer Zeit-Anzeige (Lib/TimerDisplay.lua); Texte <PREFIX>_SCALE, _PREVIEW, _MOVE, _RESET_POSITION
  local function addTimerDisplayControls(prefix, display, scaleSetting)
    addSlider({
      label = prefix .. "_SCALE",
      min = toPercent(display.MIN_SCALE),
      max = toPercent(display.MAX_SCALE),
      step = 5,
      get = function(db) return toPercent(db[scaleSetting]) end,
      set = function(value) ns.Set(scaleSetting, value / 100) end,
      format = percent,
    })
    builder.AddButtonRow({
      { label = prefix .. "_PREVIEW", onClick = function() display.Preview() end },
      { label = prefix .. "_MOVE", onClick = function() display.SetMoving(not display.IsMoving()) end },
      { label = prefix .. "_RESET_POSITION", onClick = function() display.ResetPosition() end },
    })
  end


  -- Lagerfeuer-Anzeige: nur in WoW Forever (dort gibt es den Lagerfeuer-Buff)
  if ns.CampFire.IsAvailable() then
    addSection("SECTION_CAMP")
    addToggles({
      toggle("CAMP_COUNTDOWN_TOGGLE", "campCountdown"),
      toggle("CAMP_HINT_TOGGLE", "campHint"),
      toggle("CAMP_SOUND", "campSound"),
    })
    addSlider({
      label = "CAMP_HINT_PAUSE",
      min = ns.CampFire.MIN_HINT_PAUSE,
      max = ns.CampFire.MAX_HINT_PAUSE,
      step = 1,
      get = function(db) return db.campHintPause end,
      set = function(value) ns.Set("campHintPause", value) end,
      format = function(value) return string.format(L.MINUTES, value) end,
    })
    addTimerDisplayControls("CAMP", ns.CampDisplay, "campScale")
  end

  -- Essen-Timer: überall, wo der Client die Buffs "Essen" und "Satt" kennt
  if ns.FoodTimer.IsAvailable() then
    addSection("SECTION_FOOD")
    addToggles({
      toggle("FOOD_TIMER_TOGGLE", "foodTimer"),
      toggle("FOOD_SOUND", "foodSound"),
    })
    addTimerDisplayControls("FOOD", ns.FoodDisplay, "foodScale")
  end

  -- Flugzeiten: eigene Messung je Strecke (wie Leatrix Plus "Show flight times", ohne mitgelieferte Daten)
  addSection("SECTION_FLIGHT")
  addToggles({
    toggle("FLIGHT_TIMER_TOGGLE", "flightTimer"),
    toggle("FLIGHT_SOUND", "flightSound"),
  })
  addTimerDisplayControls("FLIGHT", ns.FlightDisplay, "flightScale")
  finishPage()
end

-- Komfort: Seitenleiste mit Kategorien wie bei Leatrix Plus (Automatik, Sozial, Chat, Oberfläche, System)
addPage("OPTIONS_TAB_COMFORT")
addHint("COMFORT_HINT")
local addSubPage, finishSubPages = builder.AddSubPage, builder.FinishSubPages
addSubPage("COMFORT_PAGE_AUTOMATION")
addSection("SECTION_MERCHANT")
addToggles({
  toggle("AUTO_REPAIR", "autoRepair"),
  toggle("AUTO_REPAIR_GUILD", "autoRepairGuild", ns.Client.HasGuildBank),
  toggle("AUTO_SELL_JUNK", "autoSellJunk"),
  toggle("TRAIN_ALL_TOGGLE", "trainAllButton", ns.TrainerCache.IsAvailable),
})
addSection("SECTION_QUESTS")
addToggles({
  toggle("AUTO_ACCEPT_QUESTS", "autoAcceptQuests"),
  toggle("AUTO_ACCEPT_SHARED", "autoAcceptShared"),
  toggle("AUTO_TURN_IN", "autoTurnIn"),
  toggle("AUTO_CHOOSE_REWARD", "autoChooseReward"),
  toggle("SKIP_GOSSIP", "skipGossip"),
})
builder.AddTextInput({
  label = "QUEST_EXCLUDE",
  width = QUEST_EXCLUDE_WIDTH,
  get = function(db) return db.questExclude end,
  set = function(text) ns.Set("questExclude", strtrim(text)) end,
})
addSection("SECTION_CHARACTER")
addToggles({
  toggle("AUTO_ACCEPT_SUMMON", "autoAcceptSummon"),
  toggle("AUTO_ACCEPT_RESURRECT", "autoAcceptResurrect"),
  toggle("AUTO_RELEASE_PVP", "autoReleasePvP"),
})
addSubPage("COMFORT_PAGE_SOCIAL")
addSection("SECTION_DECLINE")
addToggles({
  toggle("DECLINE_TRADES", "declineTrades"),
  toggle("DECLINE_GROUP_INVITES", "declineGroupInvites"),
  toggle("DECLINE_GUILD_INVITES", "declineGuildInvites"),
  toggle("DECLINE_DUELS", "declineDuels"),
  toggle("DECLINE_SHARED_QUESTS", "declineSharedQuests"),
  toggle("BLOCK_FRIEND_REQUESTS", "blockFriendRequests", ns.Social.CanBlockFriendRequests),
})
-- Einladungen: Vertraute = Freunde und Gilde (Friends.lua); declineGroupInvites lehnt sie dann nicht ab
addSection("SECTION_INVITES")
addToggles({
  toggle("ACCEPT_FRIEND_INVITES", "acceptFriendInvites"),
  toggle("INVITE_FROM_WHISPER", "inviteFromWhisper"),
})
builder.AddTextInput({
  label = "INVITE_KEYWORD",
  get = function(db) return db.inviteKeyword end,
  set = function(text) ns.Set("inviteKeyword", strtrim(text)) end,
})
addSubPage("COMFORT_PAGE_CHAT")
addSection("SECTION_CHAT")
addToggles({
  toggle("CHAT_COPY_TOGGLE", "chatCopyButton"),
  toggle("RESTORE_CHAT", "restoreChat"),
  toggle("FILTER_DRUNK_SPAM", "filterDrunkSpam"),
  toggle("FILTER_SPELL_LINKS", "filterSpellLinks"),
  toggle("UNIVERSAL_GROUP_COLOR", "universalGroupColor", ns.ChatColors.IsAvailable),
})
addSection("SECTION_CHAT_WINDOWS")
addToggles({
  toggle("HIDE_COMBAT_LOG_TAB", "hideCombatLogTab"),
  toggle("HIDE_CHAT_BUTTONS", "hideChatButtons"),
  toggle("CHAT_EDIT_BOX_TOP", "chatEditBoxTop"),
  toggle("CHAT_ARROW_KEYS", "chatArrowKeys"),
  toggle("NO_CHAT_FADE", "noChatFade"),
})
addSubPage("COMFORT_PAGE_INTERFACE")
addSection("SECTION_SCREEN_TEXT")
addToggles({
  toggle("HIDE_ERRORS", "hideErrors"),
  toggle("HIDE_ZONE_TEXT", "hideZoneText"),
})
addSection("SECTION_ACTION_BARS")
addToggles({
  toggle("HIDE_KEYBIND_TEXT", "hideKeybindText"),
  toggle("HIDE_MACRO_TEXT", "hideMacroText"),
  toggle("RANGE_COLOR", "rangeColor"),
})
-- Nur Schalter für Frames, die es im Client gibt (z.B. Boss-Banner und Ereignis-Einblendungen nicht in Classic)
local HideFrames = ns.HideFrames
addSection("SECTION_HIDE_FRAMES")
addToggles({
  toggle("HIDE_BOSS_BANNER", "hideBossBanner", HideFrames.HasBossBanner),
  toggle("HIDE_EVENT_TOASTS", "hideEventToasts", HideFrames.HasEventToasts),
  toggle("HIDE_ALERTS", "hideAlerts", HideFrames.HasAlerts),
  toggle("HIDE_STANCE_BAR", "hideStanceBar", HideFrames.HasStanceBar),
  toggle("HIDE_REST_ANIMATION", "hideRestAnimation", HideFrames.HasRestAnimation),
  toggle("HIDE_PORTRAIT_NUMBERS", "hidePortraitNumbers", HideFrames.HasPortraitNumbers),
})
addSection("SECTION_WINDOWS")
addToggles({ toggle("MOVE_FRAMES", "moveFrames") })
addButton("MOVE_FRAMES_RESET", function() ns.MoveFrames.Reset() end)
if ns.QuestMarks.IsAvailable() then
  addSection("SECTION_QUEST_MARKS")
  addToggles({ toggle("QUEST_MARKS_TOGGLE", "questMarks") })
  addSlider({
    label = "QUEST_MARK_SCALE",
    min = toPercent(ns.QuestMarks.MIN_SCALE),
    max = toPercent(ns.QuestMarks.MAX_SCALE),
    step = 5,
    get = function(db) return toPercent(db.questMarkScale) end,
    set = function(value) ns.Set("questMarkScale", value / 100) end,
    format = percent,
  })
end
addSubPage("COMFORT_PAGE_FRAMES")
addSection("SECTION_CHARACTER_FRAME")
addToggles({
  toggle("CHARACTER_DURABILITY", "characterDurability", ns.CharacterFrameExtras.IsAvailable),
  toggle("CHARACTER_VOLUME", "characterVolume", ns.CharacterFrameExtras.IsAvailable),
})
addSection("SECTION_UNIT_FRAMES")
addToggles({ toggle("CLASS_COLOR_FRAMES", "classColorFrames", ns.ClassColors.IsAvailable) })
addSection("SECTION_TOOLTIP")
addToggles({
  toggle("TOOLTIP_CLASS_COLORS", "tooltipClassColors"),
  toggle("TOOLTIP_TARGET_TOGGLE", "tooltipTarget"),
  toggle("TOOLTIP_HIDE_IN_COMBAT", "tooltipHideInCombat"),
})
-- Minimap: Mausrad und Zoom-Knöpfe nur in Classic (Retail/Forever haben beides schon anders gelöst)
local MinimapTweaks = ns.MinimapTweaks
addSection("SECTION_MINIMAP")
addToggles({
  toggle("MINIMAP_WHEEL_ZOOM", "minimapWheelZoom", MinimapTweaks.CanWheelZoom),
  toggle("MINIMAP_HIDE_ZOOM_BUTTONS", "minimapHideZoomButtons", MinimapTweaks.HasZoomButtons),
  toggle("MINIMAP_HIDE_CALENDAR", "minimapHideCalendar", MinimapTweaks.HasCalendarButton),
})
addSubPage("COMFORT_PAGE_SYSTEM")
addSection("SECTION_LOOT")
addToggles({
  toggle("FASTER_LOOT", "fasterLoot"),
  toggle("SKIP_LOOT_CONFIRM", "skipLootConfirm"),
})
addSection("SECTION_DIALOGS")
addToggles({
  toggle("EASY_DELETE", "easyDelete"),
  toggle("FASTER_MOVIE_SKIP", "fasterMovieSkip"),
})
addSection("SECTION_CAMERA")
addToggles({ toggle("MAX_CAMERA_ZOOM", "maxCameraZoom") })
addSection("SECTION_GRAPHICS")
addToggles({
  toggle("NO_DRUNKEN_HAZE", "noDrunkenHaze"),
  toggle("NO_SCREEN_EFFECTS", "noScreenEffects"),
  toggle("SET_WEATHER_DENSITY", "setWeatherDensity"),
})
addSlider({
  label = "WEATHER_DENSITY",
  min = ns.ScreenEffects.MIN_WEATHER,
  max = ns.ScreenEffects.MAX_WEATHER,
  step = 1,
  get = function(db) return db.weatherDensity end,
  set = function(value) ns.Set("weatherDensity", value) end,
  format = function(value) return tostring(value) end,
})
-- Stummschalten nur, wo MuteSoundFile existiert
local muteToggles = { toggle("SILENCE_RESTED_EMOTES", "silenceRestedEmotes") }
for _, group in ipairs(ns.Sounds.MUTE_GROUPS) do
  table.insert(muteToggles, toggle(group.label, group.setting, ns.Sounds.CanMute))
end
addSection("SECTION_SOUND")
addToggles(muteToggles)
addSection("SECTION_COMBAT_GROUP")
addToggles({
  toggle("COMBAT_PLATES", "combatPlates"),
  toggle("NO_RAID_RESTRICTIONS", "noRaidRestrictions", ns.RaidRestrictions.IsAvailable),
})
if ns.AddonListSort.IsAvailable() then
  addSection("SECTION_ADDON_LIST")
  addToggles({ toggle("SORT_ADDON_LIST", "sortAddonList") })
end
finishSubPages()
finishPage()

-- Stream: alles, was nur für Streams gedacht ist (Speedrun hat einen eigenen Reiter)
addPage("OPTIONS_TAB_STREAM")
addSection("SECTION_STREAM")
addToggles({
  { label = "STREAM_MODE", get = function() return ns.StreamMode.IsEnabled() end,
    set = function(checked) ns.StreamMode.SetEnabled(checked) end },
  toggle("STREAMER_PRIVACY", "streamerPrivacy"),
  toggle("HIGHLIGHT_DEATHS", "highlightDeaths"),
})
addBackgroundChooser()
finishPage()

-- Einblendungen: welche Arten, Aussehen und Position (Hinweise aus dem Reiter Hinweise nutzen dieselbe)
addPage("OPTIONS_TAB_ALERTS")
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_LEVEL_UP", "alertLevelUp"),
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath", ns.NearDeath.IsAvailable),
})
addSection("SECTION_LEVEL_UP_WINDOW")
addToggles({
  toggle("LEVEL_UP_WINDOW_TOGGLE", "levelUpWindow"),
  toggle("LEVEL_UP_HIDE_BLIZZARD", "levelUpHideBlizzard"),
  toggle("LEVEL_UP_COMPACT", "levelUpCompact"),
  toggle("LEVEL_UP_SOUND", "levelUpSound"),
})
addChooser({ label = "LEVEL_UP_THEME", setting = "levelUpTheme", choices = {
  { value = "modern", name = localized("THEME_MODERN") },
  { value = "alliance", name = localized("THEME_ALLIANCE") },
  { value = "horde", name = localized("THEME_HORDE") },
} })
addSlider({
  label = "LEVEL_UP_SCALE",
  min = toPercent(ns.LevelUpWindow.MIN_SCALE),
  max = toPercent(ns.LevelUpWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(db.levelUpScale) end,
  set = function(value) ns.Set("levelUpScale", value / 100) end,
  format = percent,
})
addSlider({
  label = "LEVEL_UP_DURATION",
  min = ns.LevelUpWindow.MIN_DURATION,
  max = ns.LevelUpWindow.MAX_DURATION,
  step = 1,
  get = function(db) return db.levelUpDuration end,
  set = function(value) ns.Set("levelUpDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
builder.AddButtonRow({
  { label = "LEVEL_UP_PREVIEW", onClick = function() ns.LevelUpWindow.Preview() end },
  { label = "LEVEL_UP_MOVE", onClick = function() ns.LevelUpWindow.SetMoving(not ns.LevelUpWindow.IsMoving()) end },
  { label = "LEVEL_UP_RESET_POSITION", onClick = function() ns.LevelUpWindow.ResetPosition() end },
})
if ns.TrainerCache.IsAvailable() then addHint("LEVEL_UP_TRAINER_HINT") end
addSection("SECTION_ALERT_LOOK")
addChooser({ label = "ALERT_STYLE", setting = "alertStyle", choices = {
  { value = Alerts.STYLE_BANNER, name = localized("ALERT_STYLE_BANNER") },
  { value = Alerts.STYLE_TEXT, name = localized("ALERT_STYLE_TEXT") },
} })
addSlider({
  label = "ALERT_SCALE",
  min = toPercent(Alerts.MIN_SCALE),
  max = toPercent(Alerts.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(db.alertScale) end,
  set = function(value) ns.Set("alertScale", value / 100) end,
  format = percent,
})
addSlider({
  label = "ALERT_DURATION",
  min = Alerts.MIN_DURATION,
  max = Alerts.MAX_DURATION,
  step = 1,
  get = function(db) return db.alertDuration end,
  set = function(value) ns.Set("alertDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addToggles({ toggle("ALERT_SOUND", "alertSound") })
addButton("ALERT_PREVIEW", function() Alerts.Preview() end)
addButton("ALERT_MOVE", function() Alerts.SetMoving(not Alerts.IsMoving()) end)
addButton("ALERT_RESET_POSITION", function() Alerts.ResetPosition() end)
finishPage()

-- Speedrun: Splits, Split-Liste und Speedrun-Rekorde
addPage("OPTIONS_TAB_SPEEDRUN")
addSection("SECTION_SPLIT_LIST")
addToggles({
  toggle("SHOW_SPLIT_LIST", "showSplitList"),
  toggle("SHOW_SPLIT_TOTAL", "splitListShowTotal"),
  toggle("SHOW_SPLIT_PLAYED", "splitListShowPlayed"),
})
addSplitComparisonChooser()
addSlider({
  label = "SPLIT_LIST_SIZE",
  min = toPercent(TimerWindow.MIN_SCALE),
  max = toPercent(TimerWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(ns.SplitList.GetScale(db)) end,
  set = function(value) ns.Set("splitListScale", value / 100) end,
  format = percent,
})
addSlider({
  label = "SPLIT_LIST_ROWS",
  min = ns.SplitList.MIN_ROWS,
  max = ns.SplitList.MAX_ROWS,
  step = 1,
  get = function(db) return db.splitListRows end,
  set = function(value) ns.Set("splitListRows", value) end,
  format = tostring,
})
addSection("SECTION_WORLD_RECORDS")
local recordToggles = {
  toggle("SHOW_WORLD_RECORDS", "showWorldRecords"),
  toggle("SHOW_RECORDS_AGE", "showRecordsAge"),
}
-- Ein Schalter je Abschnitt der Rekord-Daten (1-10, 1-20, ...)
for _, label in ipairs(ns.WorldRecords.GetBracketLabels()) do
  table.insert(recordToggles, {
    text = function() return string.format(L.WORLD_RECORD_ROW, label) end,
    tip = "RECORD_BRACKET_TIP",
    get = function(db) return db.recordBrackets[label] ~= false end,
    set = function(checked)
      ns.db.recordBrackets[label] = checked
      ns.ApplySettings()
    end,
  })
end
addToggles(recordToggles)
addWorldRecordScopeChooser()
finishPage()

-- Profile: Einstellungen benannt speichern, je Charakter wählen, als Text teilen
addPage("OPTIONS_TAB_PROFILES")
addSection("SECTION_PROFILES")
addProfileList()
addProfileSaver()
addButton("PROFILE_EXPORT", function()
  local Profiles = ns.Profiles
  ns.Export.Show(Profiles.DisplayName(Profiles.GetActive()), Profiles.Export(Profiles.GetActive()))
end)
addButton("PROFILE_IMPORT", function() ns.ShowProfileImport() end)
addHint("PROFILE_HINT")
finishPage()

addFooterButton("HISTORY", function() ns.ToggleHistory() end)
addFooterButton("RECAP_TITLE", function() ns.ToggleRecap() end)
addFooterButton("NEW_SESSION", function() ns.StartNewSession() end)

builder.Finish()
ns.RegisterApply(builder.Refresh)

function ns.ToggleOptions()
  if not ns.db then return end
  local panel = builder.panel
  if panel:IsShown() then
    panel:Hide()
  else
    builder.Refresh(ns.db)
    panel:Show()
  end
end
