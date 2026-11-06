-- Journal-Archiv (LevelTimer_Archive, Load-on-Demand): ist ein Eingang beim Login voll, wird das Archiv geladen und
-- alle Charaktere ziehen bis auf die neuesten Einträge um; kompakt gespeichert, beim Lesen vollständig zurück.
local Journal, Archive, History, Analysis = addon.Journal, addon.JournalArchive, addon.History, addon.Analysis
local ARCHIVE = Archive.ADDON
local MAIN, ALT = "Main-Realm", "Alt-Realm"

-- Einträge mit allen Feldern je Log (Link mit | wie im Client, Zahlen mit Nachkommastellen, fehlende Felder)
local LINK = "|cff0070dd|Hitem:2315::::::::20:::::|h[Dunkle Lederstiefel]|h|r"
local SAMPLES = {
  killLog = { time = 1000, kind = "pve", name = "Wolf", classification = "elite", level = 12, zone = "Wald" },
  deathLog = { time = 1001, level = 12, zone = "Wald", killer = "Wolf", spell = "Biss", environment = nil },
  questLog = { time = 1002, level = 12, zone = "Wald", questID = 783, name = "Eine Bedrohung", xp = 450, money = 75 },
  instanceLog = { time = 1003, name = "Die Todesminen", instanceType = "party", seconds = 1234.5, level = 18,
    xp = 9000, counters = { kills = 120, deaths = 1 }, zoneUID = 4242 },
  lootLog = { time = 1004, level = 12, zone = "Wald", link = LINK, name = "Dunkle Lederstiefel", quality = 3,
    quantity = 1, source = "Wolf" },
  nearDeathLog = { time = 1005, level = 12, zone = "Wald", lowestPercent = 4, killer = "Wolf", spell = nil,
    environment = "FALLING" },
}

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for k, v in pairs(value) do result[k] = copy(v) end
  return result
end

local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

-- count Einträge je Log; Kills mit fortlaufendem Namen, damit die Reihenfolge prüfbar ist
local function filledLogs(count)
  local logs = {}
  for logName, sample in pairs(SAMPLES) do
    logs[logName] = {}
    for i = 1, count do
      local entry = copy(sample)
      entry.time = sample.time + i
      if logName == "killLog" then entry.name = "Wolf " .. i end
      logs[logName][i] = entry
    end
  end
  return logs
end

local function character(name, logs)
  local data = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = name, realm = "Realm",
    class = "WARRIOR", currentLevel = { level = 20, counters = {} }, levelHistory = {}, sessionHistory = {} }
  for logName, entries in pairs(logs) do data[logName] = entries end
  return data
end

local mainCount = Archive.INBOX_MAX + 100
LevelTimerStatsDB = { characters = {
  [MAIN] = character("Main", filledLogs(mainCount)),
  [ALT] = character("Alt", filledLogs(Archive.KEEP_RECENT + 50)),
} }
wow.login({ name = "Main", realm = "Realm", level = 20 })

expect("voller Eingang lädt das Archiv beim Login", wow.addOnLoads[ARCHIVE], 1)
expect("Archiv geladen", Archive.IsLoaded(), true)
expect("Eingang behält die neuesten", #addon.character.killLog, Archive.KEEP_RECENT)
expect("Eingang: neuester bleibt", addon.character.killLog[Archive.KEEP_RECENT].name, "Wolf " .. mainCount)
expect("Twink zieht mit um", #LevelTimerStatsDB.characters[ALT].killLog, Archive.KEEP_RECENT)
expect("Archiv-Zeilen", #LevelTimerArchiveDB.characters[MAIN].logs.killLog, mainCount - Archive.KEEP_RECENT)
expect("kompakt als Text", type(LevelTimerArchiveDB.characters[MAIN].logs.killLog[1]), "string")

-- Lesen: Archiv und Eingang zusammen, älteste zuerst, alle Felder unverändert
local kills = Journal.GetEntries(MAIN, "killLog")
expect("alle Kills", #kills, mainCount)
expect("älteste zuerst", kills[1].name, "Wolf 1")
expect("neueste zuletzt", kills[mainCount].name, "Wolf " .. mainCount)
for logName, sample in pairs(SAMPLES) do
  local first = copy(sample)
  first.time = sample.time + 1
  if logName == "killLog" then first.name = "Wolf 1" end
  expectTrue("Felder erhalten: " .. logName, same(Journal.GetEntries(MAIN, logName)[1], first))
end
expect("gleiche Liste ohne Änderung", Journal.GetEntries(MAIN, "killLog"), kills)

-- Historie und Auswertung sehen die ganze Reise
expect("Historie neueste zuerst", History.GetKillLog(MAIN)[1].name, "Wolf " .. mainCount)
expect("Historie alle", #History.GetKillLog(MAIN), mainCount)
expect("Twink-Historie", #History.GetKillLog(ALT), Archive.KEEP_RECENT + 50)
expect("Instanz-Läufe vollständig", #History.GetInstanceLog(ALT), Archive.KEEP_RECENT + 50)
local revision = Journal.Revision()
Journal.AddKill(Journal.PVE, "Wolf neu")
expect("neuer Kill sichtbar", History.GetKillLog(MAIN)[1].name, "Wolf neu")
expectTrue("Stand ändert sich", Journal.Revision() ~= revision)
expectTrue("Auswertung über alles", Analysis.TopKills(MAIN) ~= nil)

-- Über Neuladen: Archiv bleibt, kleiner Eingang lädt es nicht von selbst (im Stub bleibt es geladen)
wow.logout()
wow.login({ name = "Main", realm = "Realm", level = 20 })
expect("kein zweites Laden", wow.addOnLoads[ARCHIVE], 1)
expect("nach Neuladen alle", #Journal.GetEntries(MAIN, "killLog"), mainCount + 1)

-- Gelöschter Charakter: auch sein Archiv ist weg
addon.DeleteCharacter(ALT)
expect("Archiv des Twinks gelöscht", LevelTimerArchiveDB.characters[ALT], nil)
expect("keine Fehler", #wow.errors, 0)
