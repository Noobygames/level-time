-- LT-290: Erinnerung an Prüfungen mit Situation: Auslöser -> offen -> bestätigt -> weg; neuer Build -> wieder offen
-- (/lt debug check bestätigt nicht von selbst)
local extractor = wow.loadExtractor()
wow.login()
local Reminders = extractor.CheckReminders
expectTrue("Erinnerung geladen", Reminders ~= nil)

local function names(list)
  local result = {}
  for _, check in ipairs(list) do result[#result + 1] = check.name end
  return table.concat(result, ",")
end
local function panelShown() return _G.LevelTimerCheckReminder ~= nil and _G.LevelTimerCheckReminder:IsShown() end

expect("ohne Auslöser nichts gezeigt", panelShown(), false)

-- Instanz betreten: die Prüfungen dieser Situation werden offen
wow.state.instance = { type = "party", name = "Test" }
wow.fire("PLAYER_ENTERING_WORLD")
expectTrue("Fenster nach Instanz", panelShown())
expectTrue("Instanz-Prüfung offen", names(Reminders.Pending("instance")):find("LT274.map.dungeonart", 1, true) ~= nil)

-- /lt debug check bestätigt nicht
SlashCmdList.LEVELTIMER("debug check")
expectTrue("nach check noch offen", panelShown())

-- Einzeln bestätigen, dann alle
Reminders.Confirm("LT274.map.dungeonart")
expect("eine bestätigt, andere offen", names(Reminders.Pending("instance")), "LT273.questmarks.instance")
Reminders.Confirm(nil)
expect("alles bestätigt", names(Reminders.Pending("instance")), "")
expect("Fenster weg", panelShown(), false)

-- Neuer Build: wieder offen
local realBuildInfo = GetBuildInfo
GetBuildInfo = function() return "1.60.2", "99999", "2026-12-01", 16001 end
wow.fire("PLAYER_ENTERING_WORLD")
expectTrue("neuer Build wieder offen", panelShown())
Reminders.Confirm(nil)
GetBuildInfo = realBuildInfo

-- Bosskill zählt erst nach dem Kampf
wow.fire("ENCOUNTER_END", 1, "Boss", 1, 5, 1)
expect("vor Kampfende nichts", panelShown(), false)
wow.fire("PLAYER_REGEN_ENABLED")
expectTrue("Bosskill nach Kampf", panelShown())
expect("Schadensmesser offen", names(Reminders.Pending("bossKill")), "LT285.damageMeter.api")

-- Offene Situation übersteht /reload
wow.logout()
wow.login()
expectTrue("nach Reload noch gezeigt", panelShown())
expect("keine Lua-Fehler", #wow.errors, 0)
