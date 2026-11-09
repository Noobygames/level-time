-- Roadmap 86: Standardwerte je Modul (Database.RegisterDefaults)
local Database = addon.Database
local expect = expect
local expectTrue = expectTrue

wow.login()

-- Standardwerte aus verschiedenen Modulen sind registriert und abrufbar
expect("Theme Default", Database.SettingDefault("theme"), "classic")
expect("Frames Default", Database.SettingDefault("locked"), false)
expect("TimerWindow Default", Database.SettingDefault("bgAlpha"), 0.8)
expect("KillCounter Default", Database.SettingDefault("showPveKills"), true)
expect("Alerts Default", Database.SettingDefault("alertDuration"), 3)
expect("Core Default", Database.SettingDefault("language"), addon.DefaultLanguage())

-- Neue Zähler enthalten alle angemeldeten Zähler mit Standard 0
local counters = Database.NewCounters()
expect("PVE Kills Counter", counters.pveKills, 0)
expect("Deaths Counter", counters.deaths, 0)
expect("Quests Counter", counters.quests, 0)
expect("Items Looted Counter", counters.itemsLooted, 0)
expect("Combat Seconds Counter", counters.combatSeconds, 0)
expect("Reputation Counter", counters.reputation, 0)
expect("Money Earned Counter", counters.moneyEarned, 0)

-- Doppelte Anmeldungen werfen einen Fehler
local ok, err = pcall(Database.RegisterDefaults, {
  settings = { theme = "flat" },
})
expectTrue("doppelter Setting-Schlüssel wirft Fehler", not ok)

local okRange, errRange = pcall(Database.RegisterDefaults, {
  ranges = { themeFontSize = { -2, 4 } },
})
expectTrue("doppelter Range-Schlüssel wirft Fehler", not okRange)

local okCounter, errCounter = pcall(Database.RegisterDefaults, {
  counters = { pveKills = 10 },
})
expectTrue("doppelter Counter-Schlüssel wirft Fehler", not okCounter)

-- Sanitize begrenzt Zahlen gemäß angemeldetem Range
local sanitized = Database.SanitizeSettings({
  alertDuration = 999,
  themeFontSize = -100,
})
expect("alertDuration nach oben begrenzt", sanitized.alertDuration, 10)
expect("themeFontSize nach unten begrenzt", sanitized.themeFontSize, -4)
