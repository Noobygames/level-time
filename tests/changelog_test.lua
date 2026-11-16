-- Changelog (UI/Changelog.lua): merkt sich die zuletzt gestartete Version, zeigt nach einem Update die ungesehenen
-- Tage, "Nicht mehr automatisch anzeigen" schaltet das ab, /lt changelog zeigt immer die letzten 14 Tage.
local Changelog = addon.Changelog
local newest = addon.CHANGELOG[1].date

-- Allererster Start: Willkommenskarte statt Changelog, Version und Stand werden gemerkt
wow.login({ addOnVersion = "v1.0.0" })
expect("erster Start ohne Changelog", Changelog.IsShown(), false)
expect("Version gemerkt", LevelTimerStatsDB.changelog.version, "v1.0.0")
expect("neuester Tag als gesehen", LevelTimerStatsDB.changelog.seen, newest)

-- Gleiche Version, neuer Start: nichts
wow.login()
expect("gleiche Version ohne Changelog", Changelog.IsShown(), false)

-- Update mit ungesehenen Tagen: Fenster mit genau diesen Tagen
LevelTimerStatsDB.changelog.seen = "2000-01-01"
wow.login({ addOnVersion = "v1.1.0" })
expect("nach Update gezeigt", Changelog.IsShown(), true)
expectTrue("Datum im Text", Changelog.Text():find(newest, 1, true) ~= nil)
expectTrue("Zeile mit Art", Changelog.Text():find(addon.L.CHANGELOG_NEW .. ":", 1, true) ~= nil)
expect("neue Version gemerkt", LevelTimerStatsDB.changelog.version, "v1.1.0")

-- "Nicht mehr automatisch anzeigen"
local check = Changelog.HideCheck()
check:SetChecked(true)
check._scripts.OnClick(check)
expect("Einstellung aus", addon.db.changelogAutoShow, false)
Changelog.HideCheck():GetParent():Hide()
LevelTimerStatsDB.changelog.seen = "2000-01-01"
wow.login({ addOnVersion = "v1.2.0" })
expect("abgeschaltet: kein Fenster", Changelog.IsShown(), false)

-- Immer abrufbar: letzte 14 Tage, ohne Update in der Zeit wenigstens der neueste Tag
SlashCmdList.LEVELTIMER("changelog")
expect("per Befehl gezeigt", Changelog.IsShown(), true)
expect("14 Tage nach dem neuesten Tag", #Changelog.Recent(time({ year = 2099, month = 1, day = 1 })), 1)
expect("keine Lua-Fehler", #wow.errors, 0)
