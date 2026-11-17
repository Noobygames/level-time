-- Optionen, Reiter Hinweise & Warnungen: Ereignisse, Level-Up, Lager/Essen/Schlafsack, Reisen, Erinnerungen, Warnungen,
-- Login & Rekorde, Stil & Position.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local Alerts = ns.Alerts
local addPage, finishPage, addSection, addSlider = O.addPage, O.finishPage, O.addSection, O.addSlider
local addToggles, addButton, addChooser, addHint, addSubPage = O.addToggles, O.addButton, O.addChooser, O.addHint, O.addSubPage
local finishSubPages, toggle, localized, requires = O.finishSubPages, O.toggle, O.localized, O.requires
local addFrameScaleSlider, addPreviewCycle = O.addFrameScaleSlider, O.addPreviewCycle

-- Level-Up-Ansage: aus, Gruppe oder Gilde
local function addAnnounceChooser()
  local Summary = ns.LevelUpSummary
  addChooser({ label = "LEVEL_UP_ANNOUNCE", setting = "levelUpAnnounce", choices = {
    { value = Summary.ANNOUNCE_OFF, name = localized("ANNOUNCE_OFF") },
    { value = Summary.ANNOUNCE_PARTY, name = localized("ANNOUNCE_PARTY") },
    { value = Summary.ANNOUNCE_GUILD, name = localized("ANNOUNCE_GUILD") },
  } })
end

-- Zeit-Anzeigen (Lib/TimerDisplay.lua): Größe und Vorschau; Texte <PREFIX>_SCALE, _PREVIEW. Verschieben und
-- Zurücksetzen übernimmt der Edit-Modus (Button unten)
local function addTimerDisplayControls(prefix, display, frameId)
  addFrameScaleSlider(prefix .. "_SCALE", frameId, nil, true)
  addButton(prefix .. "_PREVIEW", function() display.Preview() end)
end

addPage("OPTIONS_TAB_HINTS")
addSubPage("OPTIONS_PAGE_ALERT_KINDS")
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath", ns.NearDeath.IsAvailable),
  toggle("ALERT_TOGGLE_RARE_SPOTTED", "alertRareSpotted"),
  toggle("ALERT_TOGGLE_ELITE_SPOTTED", "alertEliteSpotted"),
  requires(toggle("ALERT_TOGGLE_RARE_FLASH", "alertRareFlash"), "alertRareSpotted"),
})
addToggles({
  toggle("ALERT_TOGGLE_QUEST_COMPLETE", "alertQuestComplete"),
  toggle("ALERT_TOGGLE_QUEST_OBJECTIVE", "alertQuestObjective"),
})
addSubPage("OPTIONS_PAGE_LEVEL_UP")
addSection("SECTION_LEVEL_UP_WINDOW")
addToggles({
  toggle("LEVEL_UP_WINDOW_TOGGLE", "levelUpWindow"),
  requires(toggle("LEVEL_UP_HIDE_BLIZZARD", "levelUpHideBlizzard"), "levelUpWindow"),
  requires(toggle("LEVEL_UP_COMPACT", "levelUpCompact"), "levelUpWindow"),
  requires(toggle("LEVEL_UP_SOUND", "levelUpSound"), "levelUpWindow"),
  requires(toggle("LEVEL_UP_AUTO_CLOSE", "levelUpAutoClose"), "levelUpWindow"),
})
local function levelUpWindowOn(db) return db.levelUpWindow end
addChooser({ label = "LEVEL_UP_THEME", setting = "levelUpTheme", enabled = levelUpWindowOn, choices = {
  { value = "modern", name = localized("THEME_MODERN") },
  { value = "alliance", name = localized("THEME_ALLIANCE") },
  { value = "horde", name = localized("THEME_HORDE") },
} })
addFrameScaleSlider("LEVEL_UP_SCALE", "levelUp", levelUpWindowOn)
addSlider({
  label = "LEVEL_UP_DURATION",
  advanced = true,
  setting = "levelUpDuration",
  min = ns.LevelUpWindow.MIN_DURATION,
  max = ns.LevelUpWindow.MAX_DURATION,
  step = 1,
  get = function(db) return db.levelUpDuration end,
  set = function(value) ns.SetDeferred("levelUpDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
  enabled = function(db) return db.levelUpWindow and db.levelUpAutoClose end,
})
addButton("LEVEL_UP_PREVIEW", function() ns.LevelUpWindow.Preview() end)
if ns.TrainerCache.IsAvailable() then addHint("LEVEL_UP_TRAINER_HINT") end

addSection("SECTION_LEVEL_UP_BANNER")
-- Die Einblendung kommt nur ohne Level-Up-Fenster (das zeigt dieselben Zuwächse, AlertTriggers.lua)
local levelUpBanner = toggle("ALERT_TOGGLE_LEVEL_UP", "alertLevelUp")
levelUpBanner.enabled = function(db) return not db.levelUpWindow end
addToggles({ levelUpBanner })
addHint("LEVEL_UP_BANNER_HINT")
addSection("SECTION_LEVEL_UP_CHAT")
addToggles({ toggle("LEVEL_UP_SUMMARY_TOGGLE", "levelUpSummary"), toggle("LEVEL_UP_GAINS_TOGGLE", "levelUpGains") })
addAnnounceChooser()
addSubPage("COMFORT_PAGE_TIMERS")
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
  toggle("REMIND_SLEEPING_BAG_TOGGLE", "remindSleepingBag", ns.BuffReminder.HasSleepingBagSystem),
})
if ns.CampFire.IsAvailable() then
  addSection("SECTION_CAMP")
  addToggles({
    toggle("CAMP_COUNTDOWN_TOGGLE", "campCountdown"),
    toggle("CAMP_HINT_TOGGLE", "campHint"),
    requires(toggle("CAMP_SOUND", "campSound"), "campCountdown"),
  })
  addSlider(requires({
    label = "CAMP_HINT_PAUSE",
    advanced = true,
    setting = "campHintPause",
    min = ns.CampFire.MIN_HINT_PAUSE,
    max = ns.CampFire.MAX_HINT_PAUSE,
    step = 1,
    get = function(db) return db.campHintPause end,
    set = function(value) ns.SetDeferred("campHintPause", value) end,
    format = function(value) return string.format(L.MINUTES, value) end,
  }, "campHint"))
  addTimerDisplayControls("CAMP", ns.CampDisplay, "camp")
end
if ns.FoodTimer.IsAvailable() then
  addSection("SECTION_FOOD")
  addToggles({
    toggle("FOOD_TIMER_TOGGLE", "foodTimer"),
    requires(toggle("FOOD_SOUND", "foodSound"), "foodTimer"),
  })
  addTimerDisplayControls("FOOD", ns.FoodDisplay, "food")
end
if ns.SleepTimer.IsAvailable() then
  addSection("SECTION_SLEEP")
  addToggles({
    toggle("SLEEP_TIMER_TOGGLE", "sleepTimer"),
    toggle("SLEEP_STACK_NOTICE", "sleepStackNotice"),
    toggle("SLEEP_TIMER_SOUND", "sleepTimerSound"),
  })
  addTimerDisplayControls("SLEEP", ns.SleepDisplay, "sleep")
end

-- Reisen: Flugzeiten (eigene Messung je Strecke wie Leatrix Plus "Show flight times"), Schiffe und Zeppeline
addSubPage("COMFORT_PAGE_TRAVEL")
addSection("SECTION_FLIGHTS")
addToggles({
  toggle("FLIGHT_TIMER_TOGGLE", "flightTimer"),
  requires(toggle("FLIGHT_SOUND", "flightSound"), "flightTimer"),
  requires(toggle("FLIGHT_TOOLTIP_TOGGLE", "flightTimeTooltip"), "flightTimer"),
})
addTimerDisplayControls("FLIGHT", ns.FlightDisplay, "flight")

-- Schiffe und Zeppeline (Roadmap 440): gelernte Abfahrtszeiten, nicht in Retail
if ns.Transports.IsAvailable() then
  addSection("SECTION_TRANSPORT")
  addToggles({
    toggle("TRANSPORT_TIMERS_TOGGLE", "transportTimers"),
    requires(toggle("TRANSPORT_MINIMAP_TOGGLE", "transportMinimap"), "transportTimers"),
    requires(toggle("TRANSPORT_WORLDMAP_TOGGLE", "transportWorldMap"), "transportTimers"),
    requires(toggle("TRANSPORT_NAMEPLATE_TOGGLE", "transportNameplate"), "transportTimers"),
    requires(toggle("TRANSPORT_TOOLTIP_TOGGLE", "transportTooltip"), "transportTimers"),
    requires(toggle("TRANSPORT_SHARE_TOGGLE", "transportShare"), "transportTimers"),
  })
  addHint("TRANSPORT_NAMEPLATE_HINT")
  addFrameScaleSlider("TRANSPORT_SCALE", "transport", nil, true)
  O.addFramePreview("TRANSPORT_PREVIEW", "transport")
end

addSubPage("OPTIONS_PAGE_REMINDERS")
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_CHARGED_TOGGLE", "remindCharged", ns.BuffReminder.HasChargedSystem),
  toggle("REMIND_TRAINER_TOGGLE", "remindTrainer", ns.TrainerReminder.IsAvailable),
  toggle("WARN_OLD_SPELL_RANKS_TOGGLE", "warnOldSpellRanks", ns.OldSpellRanks.IsAvailable),
  toggle("HINTS_AUTOCLOSE_TOGGLE", "hintsAutoClose"),
})
if ns.OldSpellRanks.IsAvailable() then
  addButton("OLD_RANKS_RESTORE", function() ns.OldSpellRanks.ClearIgnored() end, {
    text = function() return string.format(L.OLD_RANKS_RESTORE, ns.OldSpellRanks.IgnoredCount()) end,
    enabled = function() return ns.OldSpellRanks.IgnoredCount() > 0 end,
  })
end
addSlider({
  label = "HINTS_AUTOCLOSE_SECONDS",
  setting = "hintsAutoCloseSeconds",
  min = ns.Hints.MIN_AUTO_CLOSE,
  max = ns.Hints.MAX_AUTO_CLOSE,
  step = 5,
  get = function(db) return db.hintsAutoCloseSeconds end,
  set = function(value) ns.SetDeferred("hintsAutoCloseSeconds", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
  enabled = function(db) return db.hintsAutoClose end,
})
-- Wiederholung gilt für alle Buff-Erinnerungen (auch die Klassen-Buffs darunter)
addSlider({
  label = "REMINDER_INTERVAL",
  advanced = true,
  setting = "reminderInterval",
  min = ns.BuffReminder.MIN_INTERVAL,
  max = ns.BuffReminder.MAX_INTERVAL,
  step = 1,
  get = function(db) return db.reminderInterval end,
  set = function(value) ns.SetDeferred("reminderInterval", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
-- Klassen-Buffs: nur die der eigenen Klasse; Beschriftung mit den Zaubernamen in der Sprache des Clients
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
-- Pausen-Erinnerung (BreakReminder.lua)
addSection("SECTION_BREAKS")
addToggles({ toggle("REMIND_BREAK_TOGGLE", "remindBreak") })
addSlider(requires({
  label = "BREAK_MINUTES",
  advanced = true,
  setting = "breakMinutes",
  min = ns.BreakReminder.MIN_MINUTES,
  max = ns.BreakReminder.MAX_MINUTES,
  step = 15,
  get = function(db) return db.breakMinutes end,
  set = function(value) ns.SetDeferred("breakMinutes", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
}, "remindBreak"))
-- Testen: ein Hinweis je Klick (Essen, Lager, Schlafsack, Klassen-Buffs, Lehrer, Pause), wie echt
addPreviewCycle("NOTIFICATION_TEST_REMINDERS", function()
  local steps = ns.BuffReminder.PreviewSteps()
  if ns.TrainerReminder.IsAvailable() then table.insert(steps, ns.TrainerReminder.Preview) end
  table.insert(steps, ns.BreakReminder.Preview)
  return steps
end)
addSubPage("OPTIONS_PAGE_WARNINGS")
addHint("WARN_LOOK_HINT")
addToggles({
  toggle("WARN_BAGS_FULL_TOGGLE", "warnBagsFull"),
  toggle("WARN_DURABILITY_TOGGLE", "warnDurability"),
  toggle("WARN_QUEST_LOG_FULL_TOGGLE", "warnQuestLogFull"),
  toggle("WARN_AMMO_TOGGLE", "warnAmmo", ns.GearWarnings.ShowsAmmoOptions),
  toggle("WARN_REAGENTS_TOGGLE", "warnReagents", ns.Reagents.IsAvailable),
  toggle("WARN_BREATH_TOGGLE", "warnBreath"),
  toggle("WARN_WILDERNESS_LOGOUT", "warnWildernessLogout"),
  toggle("WARN_FALLING", "warnFalling"),
  toggle("EMERGENCY_TOGGLE", "emergencyHighlight", ns.Emergency.IsAvailable),
})
addSlider(requires({
  label = "WARN_BREATH_BELOW",
  advanced = true,
  setting = "breathWarnSeconds",
  min = ns.BreathWarning.MIN_SECONDS,
  max = ns.BreathWarning.MAX_SECONDS,
  step = 1,
  get = function(db) return db.breathWarnSeconds end,
  set = function(value) ns.SetDeferred("breathWarnSeconds", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
}, "warnBreath"))
-- Munition: nur für Jäger
if ns.GearWarnings.ShowsAmmoOptions() then
  addSlider(requires({
    label = "WARN_AMMO_BELOW",
    setting = "ammoLow",
    min = ns.GearWarnings.MIN_AMMO,
    max = ns.GearWarnings.MAX_AMMO,
    step = 20,
    get = function(db) return db.ammoLow end,
    set = function(value) ns.SetDeferred("ammoLow", value) end,
    format = function(value) return string.format(L.AMMO_COUNT, value) end,
  }, "warnAmmo"))
  addSlider(requires({
    label = "WARN_AMMO_CRITICAL_BELOW",
    advanced = true,
    setting = "ammoCritical",
    min = 0,
    max = ns.GearWarnings.MAX_CRITICAL_AMMO,
    step = 10,
    get = function(db) return db.ammoCritical end,
    set = function(value) ns.SetDeferred("ammoCritical", value) end,
    format = function(value) return value == 0 and L.AMMO_OFF or string.format(L.AMMO_COUNT, value) end,
  }, "warnAmmo"))
  addSlider(requires({
    label = "WARN_AMMO_REPEAT",
    advanced = true,
    setting = "ammoRepeat",
    min = 0,
    max = ns.GearWarnings.MAX_AMMO_REPEAT,
    step = 1,
    get = function(db) return db.ammoRepeat end,
    set = function(value) ns.SetDeferred("ammoRepeat", value) end,
    format = function(value) return value == 0 and L.AMMO_ONCE or string.format(L.MINUTES, value) end,
  }, "warnAmmo"))
end

-- Reagenzien: nur Klassen mit Reagenzien außerhalb von Retail (Roadmap 488)
if ns.Reagents.IsAvailable() then
  addSlider(requires({
    label = "WARN_REAGENTS_BELOW",
    setting = "reagentLow",
    min = ns.Reagents.MIN_LOW,
    max = ns.Reagents.MAX_LOW,
    step = 1,
    get = function(db) return db.reagentLow end,
    set = function(value) ns.SetDeferred("reagentLow", value) end,
    format = function(value) return tostring(value) end,
  }, "warnReagents"))
end

-- Testen: eine Warnung je Klick (Atem, Taschen, Haltbarkeit, Munition, Instanzlimit, Aggro, Hardcore, Notfall), wie echt
addPreviewCycle("NOTIFICATION_TEST_WARNINGS", function()
  local steps = { ns.BreathWarning.Preview }
  for _, step in ipairs(ns.GearWarnings.PreviewSteps()) do table.insert(steps, step) end
  table.insert(steps, ns.InstanceLimit.Preview)
  table.insert(steps, ns.AggroWarning.Preview)
  table.insert(steps, ns.HardcoreSafeguard.Preview)
  if ns.Emergency.IsAvailable() then table.insert(steps, ns.Emergency.Preview) end
  return steps
end)
addSubPage("OPTIONS_PAGE_LOGIN")
addSection("SECTION_AT_LOGIN")
addToggles({ toggle("RESTED_ALT_NOTICE_TOGGLE", "restedAltNotice"),
  toggle("SESSION_COMPARE_TOGGLE", "sessionCompareLogin") })
addSection("SECTION_PERSONAL_RECORDS")
addToggles({ toggle("ANNOUNCE_RECORDS_TOGGLE", "announceRecords") })
-- Testen: die Ausgaben dieser Seite wie beim Login, unabhängig von den Schaltern
addButton("NOTIFICATION_TEST_LOGIN", function()
  ns.SessionCompare.Preview()
  ns.PersonalRecords.PreviewAnnouncement()
  ns.RestedEstimate.PreviewAltNotice()
end)
addSubPage("OPTIONS_PAGE_ALERT_LOOK")
addChooser({ label = "ALERT_STYLE", setting = "alertStyle", choices = {
  { value = Alerts.STYLE_BANNER, name = localized("ALERT_STYLE_BANNER") },
  { value = Alerts.STYLE_TEXT, name = localized("ALERT_STYLE_TEXT") },
} })
addFrameScaleSlider("ALERT_SCALE", "alert")
addSlider({
  label = "ALERT_DURATION",
  advanced = true,
  setting = "alertDuration",
  min = Alerts.MIN_DURATION,
  max = Alerts.MAX_DURATION,
  step = 1,
  get = function(db) return db.alertDuration end,
  set = function(value) ns.SetDeferred("alertDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addToggles({ toggle("ALERT_SOUND", "alertSound") })
addButton("ALERT_PREVIEW", function() Alerts.Preview() end)
finishSubPages()
finishPage()
