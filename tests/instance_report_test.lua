-- Instanz-Bericht an die Gruppe (Roadmap 282) und Tageslimit 30 Instanzen in 24 Stunden (Classic).
local Stats = addon.Stats
local L = addon.L
local InstanceLimit = addon.InstanceLimit

local function enter(name)
  wow.state.instance = name and { name = name, type = "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end
local function sent() return wow.sentChat end

wow.sentChat = {}
wow.state.clock = os.time({ year = 2026, month = 10, day = 2, hour = 12 })
wow.login({ level = 20, xp = 0, xpMax = 10000, money = 0 })
wow.state.inGroup = true

-- /lt report ohne Lauf: Hinweis
SlashCmdList.LEVELTIMER("report")
expect("ohne Lauf: Hinweis", wow.printed[#wow.printed]:find(L.INSTANCE_REPORT_NONE, 1, true) ~= nil, true)

-- /lt report im Dungeon: sofort an die Gruppe, auch mit ausgeschalteter Einstellung und unter einer Minute
enter("Die Todesminen")
wow.advance(10)
SlashCmdList.LEVELTIMER("report")
expect("von Hand: gesendet", #sent(), 1)
expectTrue("von Hand: Instanzname", sent()[1].message:find("Die Todesminen", 1, true) ~= nil)
enter(nil)
wow.sentChat = {}

-- Aus: kein Bericht
enter("Die Todesminen")
wow.advance(120)
enter(nil)
expect("aus: nichts gesendet", #sent(), 0)

-- An: XP, Kills, XP je Kill und Geld des Laufs
addon.Set("announceInstanceReport", true)
enter("Die Todesminen")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Defias", 300))
wow.state.xp = 300
wow.fire("PLAYER_XP_UPDATE", "player")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Defias", 300))
wow.state.xp = 600
wow.fire("PLAYER_XP_UPDATE", "player")
wow.fire("LOOT_OPENED")
wow.state.money = 23005
wow.fire("PLAYER_MONEY")
wow.fire("LOOT_CLOSED")
wow.advance(600)
enter(nil)
expect("ein Bericht", #sent(), 1)
local runSeconds = addon.Instances.GetRunSeconds(addon.Instances.GetCurrentRun())
local expected = string.format(L.INSTANCE_REPORT, "Die Todesminen", table.concat({
  addon.Format.Duration(runSeconds),
  string.format(L.INSTANCE_REPORT_XP, "600"),
  string.format(L.INSTANCE_REPORT_XP_RATE, addon.Format.Number(math.floor(600 / runSeconds * 3600))),
  string.format(L.INSTANCE_REPORT_KILLS, 2) .. string.format(L.INSTANCE_REPORT_PER_KILL, "300"),
  addon.Format.PlainMoney(23005) }, ", "))
expect("Text", sent()[1] and sent()[1].message, "Level Time: " .. expected)
expect("Gruppenchat", sent()[1] and sent()[1].chatType, "PARTY")

-- Wieder rein und raus ohne Änderung: kein zweiter Bericht
enter("Die Todesminen")
enter(nil)
expect("nicht doppelt", #sent(), 1)

-- Allein, als Geist, gesperrter Chat: nichts
wow.state.inGroup = false
enter("Burg Schattenfang")
wow.advance(120)
enter(nil)
expect("allein nichts", #sent(), 1)
wow.state.inGroup = true
enter("Burg Schattenfang")
wow.state.chatLockdown = true
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Wolf", 50))
enter(nil)
expect("gesperrt nichts", #sent(), 1)
wow.state.chatLockdown = false

-- Kurzer Lauf (unter einer Minute) nicht
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Burg Schattenfang"))
enter("Burg Schattenfang")
wow.advance(30)
enter(nil)
expect("kurz nichts", #sent(), 1)

-- Tageslimit: Classic 30 in 24 Stunden, Retail keines
expect("Retail ohne Tageslimit", InstanceLimit.GetDailyLimit(), nil)
wow.state.interface = 11509
expect("Classic 30", InstanceLimit.GetDailyLimit(), 30)
local entries = LevelTimerStatsDB.instanceEntries[addon.character.realm]
for i = 1, 26 do
  table.insert(entries, 1, { time = time() - 13 * 3600 - i, name = "Alt " .. i, character = "Alt-Testrealm" })
end
expect("24 Stunden gleitend", InstanceLimit.GetDayCount(), 29)
addon.Set("warnInstanceLimit", true)
addon.Alerts.Clear()
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Burg Schattenfang"))
enter("Burg Schattenfang")
local warned = false
for _, line in ipairs(wow.printed) do
  if line:find(string.format(L.INSTANCE_DAILY_LIMIT_WARNING, 30, 30), 1, true) then warned = true end
end
expectTrue("Warnung 30/30", warned)
local today
for _, line in ipairs(addon.STAT_LINES) do
  if line.setting == "showInstancesToday" then today = line.rows[1].value() end
end
expect("Zeile mit 24 Stunden", today, string.format(L.INSTANCES_TODAY_DAILY, 4, 30, 30))
