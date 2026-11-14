-- Optionen, Reiter Einblendungen: Ereignisse, Aussehen, Level-Up.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local Alerts = ns.Alerts
local addPage, finishPage, addSection, addSlider, addToggles, addButton, addChooser, addHint, addSubPage, finishSubPages, toggle, localized, requires, addFrameScaleSlider = O.addPage, O.finishPage, O.addSection, O.addSlider, O.addToggles, O.addButton, O.addChooser, O.addHint, O.addSubPage, O.finishSubPages, O.toggle, O.localized, O.requires, O.addFrameScaleSlider

-- Level-Up-Ansage: aus, Gruppe oder Gilde
local function addAnnounceChooser()
  local Summary = ns.LevelUpSummary
  addChooser({ label = "LEVEL_UP_ANNOUNCE", setting = "levelUpAnnounce", choices = {
    { value = Summary.ANNOUNCE_OFF, name = localized("ANNOUNCE_OFF") },
    { value = Summary.ANNOUNCE_PARTY, name = localized("ANNOUNCE_PARTY") },
    { value = Summary.ANNOUNCE_GUILD, name = localized("ANNOUNCE_GUILD") },
  } })
end

-- Einblendungen: welche Ereignisse, Aussehen und Position (Hinweise aus Chat & Erinnerungen nutzen dieselbe) und
-- alles zum Level-Up an einem Ort: Fenster, Einblendung, Chatzeile und Ansage (UX S11). Timer und Flüge stehen unter
-- Komfort > Timer & Flüge.
addPage("OPTIONS_TAB_ALERTS")
addSubPage("OPTIONS_PAGE_ALERT_KINDS")
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath", ns.NearDeath.IsAvailable),
  toggle("ALERT_TOGGLE_RARE_SPOTTED", "alertRareSpotted"),
  requires(toggle("ALERT_TOGGLE_RARE_FLASH", "alertRareFlash"), "alertRareSpotted"),
})
addHint("QUEST_ALERTS_HINT")  -- Quest-Einblendungen stehen bei den Quests, die zum Level-Up auf der Seite Level-Up
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
finishSubPages()
finishPage()
