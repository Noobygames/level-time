-- Twink-Übersicht (Roadmap 321): Reihenfolge „Wer ist dran?“, Gold, /played, zuletzt gesehen, lange nicht gespielt.
local Alts = addon.Alts
local DAY = 24 * 3600
local now = wow.state.clock
local version = addon.Database.CHARACTER_SCHEMA_VERSION

local function snapshot(rested, ageDays)
  return { time = now - ageDays * DAY, rested = rested, xpMax = 10000, resting = true, full = 1.5 }
end

LevelTimerStatsDB = { characters = {
  -- volles Ruhe-XP, gerade erst gespielt
  ["Voll-Testrealm"] = { schemaVersion = version, name = "Voll", realm = "Testrealm", currentLevel = { level = 20 },
    money = 12345, played = 7200, lastSeen = now - 2 * DAY, restSnapshot = snapshot(15000, 0) },
  -- gleich voll, aber länger nicht gespielt: kommt davor
  ["Alt-Testrealm"] = { schemaVersion = version, name = "Alt", realm = "Testrealm", currentLevel = { level = 30 },
    lastSeen = now - 40 * DAY, restSnapshot = snapshot(15000, 40) },
  -- ohne Schätzung (Höchststufe), alte Daten ohne lastSeen: Ende der letzten Session
  ["Max-Testrealm"] = { schemaVersion = version, name = "Max", realm = "Testrealm", currentLevel = { level = 60 },
    sessionHistory = { { endedAt = now - 5 * DAY } } },
} }

wow.login({ level = 10, xp = 0, xpMax = 1000, rested = 100, playedSeconds = 600, money = 500 })

local records = Alts.GetRecords()
local order = {}
for i, record in ipairs(records) do order[i] = record.key end
expect("Wer ist dran?", table.concat(order, ","),
  "Alt-Testrealm,Voll-Testrealm," .. addon.characterKey .. ",Max-Testrealm")

local byKey = {}
for _, record in ipairs(records) do byKey[record.key] = record end
expect("Gold gespeichert", byKey["Voll-Testrealm"].money, 12345)
expect("/played gespeichert", byKey["Voll-Testrealm"].played, 7200)
expect("eingeloggt: live /played", byKey[addon.characterKey].played, addon.PlayedTime.GetTotalSeconds())
expect("lastSeen aus letzter Session", Alts.DaysAway(byKey["Max-Testrealm"]), 5)
expect("eingeloggt: 0 Tage", Alts.DaysAway(byKey[addon.characterKey]), 0)
expectTrue("lange nicht gespielt", Alts.IsLongAway(byKey["Alt-Testrealm"]))
expectTrue("kürzlich gespielt", not Alts.IsLongAway(byKey["Voll-Testrealm"]))
expect("Anzahl lange nicht gespielt", Alts.LongAwayCount(records), 1)

-- Reiter im Historie-Fenster rendert ohne Fehler
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Twinks", wow.click(addon.L.HISTORY_TAB_ALTS))
expectTrue("gilt für alle Charaktere", addon.HistoryWindow.IsAllCharacters())

-- Logout merkt sich /played und Uhrzeit
wow.logout()
expectTrue("/played beim Logout", addon.character.played ~= nil and addon.character.played >= 600)
expect("zuletzt gesehen beim Logout", addon.character.lastSeen, time())
