-- Roadmap 403: Eintrag im Blizzard-Einstellungsmenü (Settings.RegisterCanvasLayoutCategory + RegisterAddOnCategory),
-- Seite mit Text und Button, der das eigene Fenster öffnet; SettingsPanel wird nicht angefasst.
local L = addon.L

expect("eine Kategorie angemeldet", #wow.settingsCategories, 1)
local category = wow.settingsCategories[1]
expect("Name", category.name, addon.DISPLAY_NAME)
expect("Seite ist unser Canvas", category.frame, addon.BlizzardSettings.canvas)

wow.login()
local canvas = addon.BlizzardSettings.canvas
canvas:Hide()
canvas:Show()  -- Blizzard zeigt die Seite
expect("Button-Text in der Sprache", addon.BlizzardSettings.openButton:GetText(), L.BLIZZARD_SETTINGS_OPEN)

expect("Fenster noch zu", LevelTimerOptions:IsShown(), false)
expectTrue("Button klicken", wow.click(L.BLIZZARD_SETTINGS_OPEN))
expect("eigenes Fenster offen", LevelTimerOptions:IsShown(), true)

-- Sprachwechsel: beim nächsten Zeigen neu
addon.Set("language", "enUS")
canvas:Hide()
canvas:Show()
expect("englisch", addon.BlizzardSettings.openButton:GetText(), "Open Level Time settings")

expect("keine Fehler", #wow.errors, 0)
