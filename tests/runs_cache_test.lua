-- Roadmap 353: Läufe werden nur bei Änderungen neu gebaut. Jeder Auslöser (Level-Up, Import, Favorit, Löschen,
-- Einstellungen, neuer Charakter, Login) liefert den neuen Stand; dazwischen dieselben Läufe ohne neue Sortierung
-- der Level-Historie. Import erkennt Doppelte über eine Menge; Anzeigenamen mit Datenschutz über einen Index.
local Runs = addon.Runs
local History = addon.History
local RunCheck = addon.RunCheck

local function otherCharacter(name, levelHistory)
  LevelTimerStatsDB.characters[name .. "-Testrealm"] = {
    schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = name, realm = "Testrealm", class = "MAGE",
    currentLevel = { level = 30, counters = {} }, levelHistory = levelHistory, sessionHistory = {},
    killLog = {}, deathLog = {},
  }
end
wow.login({ name = "Neu", level = 5, playedSeconds = 0 })
otherCharacter("Schnell", { [5] = { level = 5, seconds = 500 }, [6] = { level = 6, seconds = 600 } })
wow.fire("TIME_PLAYED_MSG", 1000, 100)

-- Lesen zählen: GetLevelRecords sortiert die Level-Historie (der teure Teil)
local builds = { count = 0 }
local getLevelRecords = History.GetLevelRecords
History.GetLevelRecords = function(...)
  builds.count = builds.count + 1
  return getLevelRecords(...)
end
local function rebuilt(action)
  local before = builds.count
  action()
  Runs.GetAll()
  return builds.count > before
end

local first = Runs.GetAll()
expect("zwei Läufe", #first, 2)
expect("gleiche Liste ohne Änderung", Runs.GetAll(), first)
expect("ohne Änderung kein Neubau", rebuilt(function() end), false)
expect("Get über Index", Runs.Get("Schnell-Testrealm").times[6], 600)
expect("FindByName", Runs.FindByName("schnell").id, "Schnell-Testrealm")
expect("unbekannte ID", Runs.Get("gibt-es-nicht"), nil)

-- Auslöser
expectTrue("Level-Up baut neu", rebuilt(function()
  wow.advance(300)
  wow.fire("TIME_PLAYED_MSG", 1300, 300)
  wow.levelUp(6)
end))
expect("eigene Zeit nach Level-Up", Runs.Get(addon.characterKey).times[5], 300)
expectTrue("Einstellung baut neu", rebuilt(function() addon.Set("streamerPrivacy", true) end))
addon.Set("streamerPrivacy", false)
expectTrue("neuer Charakter baut neu", rebuilt(function()
  otherCharacter("Dritter", { [5] = { level = 5, seconds = 900 } })
end))
expect("drei Läufe", #Runs.GetAll(), 3)
local text = addon.Serializer.Encode("run", { name = "Fremd", realm = "Anders", times = { [5] = 450 } })
expectTrue("Import baut neu", rebuilt(function() expect("importiert", Runs.Import(text), 1) end))
expect("Import gefunden", Runs.Get("import:1").name, "Fremd")
expect("doppelt nicht", Runs.Import(text), 0)
local both = addon.Serializer.Encode("runs", {
  { name = "Zwilling", times = { [5] = 1 } }, { name = "Zwilling", times = { [5] = 1 } },
  { name = "Zwilling", times = { [5] = 2 } },
})
expect("Doppelte im selben Text einmal", Runs.Import(both), 2)
Runs.ToggleFavorite("Schnell-Testrealm")
expect("Favorit sofort", Runs.Get("Schnell-Testrealm").favorite, true)
expectTrue("Löschen baut neu", rebuilt(function() addon.DeleteCharacter("Dritter-Testrealm") end))
expect("gelöscht", Runs.Get("Dritter-Testrealm"), nil)

-- Billige Felder bleiben live: Kategorie und Prüfcode ohne Neubau
addon.character.runCategory = "group"
expect("Kategorie live", Runs.Get(addon.characterKey).category, "group")

-- Prüfstatus je Lauf gemerkt, solange Code und Zeiten gleich sind
local computed = { count = 0 }
local compute = RunCheck.Compute
RunCheck.Compute = function(...)
  computed.count = computed.count + 1
  return compute(...)
end
local own = Runs.Get(addon.characterKey)
expect("eigener Lauf ok", RunCheck.Verify(own), RunCheck.OK)
local afterFirst = computed.count
RunCheck.Verify(own)
RunCheck.StatusText(own)
expect("Prüfstatus gemerkt", computed.count, afterFirst)
RunCheck.Compute = compute
History.GetLevelRecords = getLevelRecords

-- Anzeigenamen mit Datenschutz: Platz in der Charakterliste, nach neuem Charakter neu nummeriert
addon.Set("streamerPrivacy", true)
expect("eingeloggt ohne Nummer", History.DisplayName(addon.characterKey), "Neu")
expect("zweiter Platz", History.DisplayName("Schnell-Testrealm"), string.format(addon.L.HIDDEN_CHARACTER, 2))
otherCharacter("Aaron", { [5] = { level = 5, seconds = 700 } })
expect("neu einsortiert", History.DisplayName("Schnell-Testrealm"), string.format(addon.L.HIDDEN_CHARACTER, 3))
expect("neuer Charakter vorn", History.DisplayName("Aaron-Testrealm"), string.format(addon.L.HIDDEN_CHARACTER, 2))
expect("Liste gleich", History.GetCharacterKeys(), History.GetCharacterKeys())
addon.Set("streamerPrivacy", false)
