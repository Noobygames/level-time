-- Optionen, Reiter Chat & Erinnerungen: Login, Erinnerungen, Warnungen, Gruppe und Heiler.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local addButton, addPreviewCycle = O.addButton, O.addPreviewCycle
local addPage, finishPage, addSection, addSlider, addToggles, addChooser, addHint, addSubPage, finishSubPages, toggle, localized, requires, percent = O.addPage, O.finishPage, O.addSection, O.addSlider, O.addToggles, O.addChooser, O.addHint, O.addSubPage, O.finishSubPages, O.toggle, O.localized, O.requires, O.percent

-- Chat & Erinnerungen: Login und Rekorde, Erinnerungen, Warnungen, Gruppe und Heiler (Quest-Hinweise stehen unter
-- Komfort > Quests, alles zum Level-Up unter Einblendungen > Level-Up)
addPage("OPTIONS_TAB_NOTIFICATIONS")
addSubPage("OPTIONS_PAGE_LOGIN")
addHint("LEVEL_UP_MOVED_HINT")  -- alles zum Level-Up steht gesammelt unter Einblendungen > Level-Up
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

addSubPage("OPTIONS_PAGE_REMINDERS")
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
  toggle("REMIND_SLEEPING_BAG_TOGGLE", "remindSleepingBag", ns.BuffReminder.HasSleepingBagSystem),
  toggle("REMIND_CHARGED_TOGGLE", "remindCharged", ns.BuffReminder.HasChargedSystem),
  toggle("REMIND_TRAINER_TOGGLE", "remindTrainer", ns.TrainerReminder.IsAvailable),
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
  toggle("WARN_AMMO_TOGGLE", "warnAmmo", ns.GearWarnings.ShowsAmmoOptions),
  toggle("WARN_REAGENTS_TOGGLE", "warnReagents", ns.Reagents.IsAvailable),
  toggle("WARN_INSTANCE_LIMIT_TOGGLE", "warnInstanceLimit"),
  toggle("WARN_AGGRO_TOGGLE", "warnAggro"),
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

-- Gruppe und Heiler: Ansagen im Gruppenchat
addSubPage("OPTIONS_PAGE_GROUP")
addToggles({
  toggle("ANNOUNCE_GROUP_JOIN_TOGGLE", "announceGroupJoin"),
  toggle("LOW_MANA_TOGGLE", "announceLowMana"),
  toggle("CC_ANNOUNCE_TOGGLE", "announceControlLoss"),
  toggle("CC_OVER_TOGGLE", "announceControlOver"),
  toggle("HEALER_AGGRO_TOGGLE", "announceHealerAggro"),
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
  max = 10,
  step = 1,
  get = function(db) return db.instanceReportLootMax end,
  set = function(value) ns.SetDeferred("instanceReportLootMax", value) end,
  format = function(value) return tostring(value) end,
}, "instanceReportLoot"))
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
-- Testen: alle Ansagen und der Instanzbericht nur im eigenen Chat mit "Vorschau", nie an Gruppe oder Chat gesendet
addButton("NOTIFICATION_TEST_GROUP", function()
  ns.GroupJoinStats.Preview()
  ns.ManaCallout.Preview()
  ns.ControlCallout.Preview()
  ns.AggroWarning.PreviewHealer()
  ns.InstanceReport.Preview()
  ns.InstanceResetAnnounce.Preview()
end)
finishSubPages()
finishPage()
