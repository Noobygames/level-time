-- Einstellungen: Reiter vorhanden und klickbar, Forever-Optionen nur in WoW Forever.
local L = addon.L

wow.login()
SlashCmdList.LEVELTIMER("config")

for _, tab in ipairs({ "SECTION_GENERAL", "STATISTICS", "OPTIONS_TAB_NOTIFICATIONS", "OPTIONS_TAB_TIMERS", "OPTIONS_TAB_COMFORT", "OPTIONS_TAB_STREAM", "OPTIONS_TAB_SPEEDRUN", "OPTIONS_TAB_PROFILES" }) do
  expectTrue("Reiter " .. tab, wow.click(L[tab]))
end

local function hasToggle(labelKey)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == L[labelKey] and frame._scripts.OnClick ~= nil
  end) ~= nil
end

-- Stub-Client ist Retail (Interface 120105): kein Camp-System
expect("Retail ist nicht Forever", addon.Client.IsForever(), false)
expectTrue("Food-Hinweis überall", hasToggle("REMIND_FOOD_TOGGLE"))
expect("Camp-Hinweis nur in Forever", hasToggle("REMIND_CAMP_TOGGLE"), false)
expect("Aufgeladen-Hinweis nur in Forever", hasToggle("REMIND_CHARGED_TOGGLE"), false)

wow.state.interface = 16001
expect("16001 ist Forever", addon.Client.IsForever(), true)

-- Auf kleinen Bildschirmen wird das Fenster nicht höher als 90 % davon; der Rest scrollt
UIParent:SetHeight(100000)
addon.ApplySettings()  -- Fensterhöhe neu (offenes Fenster)
local fullHeight = LevelTimerOptions:GetHeight()
expectTrue("Fenster hoch genug für alle Seiten", fullHeight > 360)
UIParent:SetHeight(400)
addon.ApplySettings()  -- Fensterhöhe neu (offenes Fenster)
expectTrue("Fenster begrenzt", LevelTimerOptions:GetHeight() <= 360)
UIParent:SetHeight(100000)
addon.ApplySettings()  -- Fensterhöhe neu (offenes Fenster)
expect("große Bildschirme: volle Höhe", LevelTimerOptions:GetHeight(), fullHeight)
