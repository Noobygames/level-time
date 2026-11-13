-- Läufe teilen: Export als Text, Import als eigener Lauf, Doppelte und Ungültiges abgelehnt.
local L = addon.L
local Runs = addon.Runs

wow.login({ name = "Neu", level = 12, playedSeconds = 0 })
LevelTimerStatsDB.characters["Rekord-Testrealm"] = {
  name = "Rekord", realm = "Testrealm", class = "MAGE", currentLevel = { level = 30, counters = {} },
  levelHistory = { [10] = { level = 10, seconds = 2500 }, [11] = { level = 11, seconds = 2500 } },
  sessionHistory = {}, killLog = {}, deathLog = {},
}

local text = Runs.Export(Runs.Get("Rekord-Testrealm"))
expect("eigener Charakter ist schon bekannt", Runs.Import(text), 0)

-- Alter Versuch desselben Charakters (Zeiten anders, z.B. nach Zurücksetzen): wird importiert
local oldAttempt = addon.Serializer.Encode("run", { name = "Rekord", realm = "Testrealm", times = { [10] = 9999 } })
expect("alter Versuch importiert", Runs.Import(oldAttempt), 1)
LevelTimerStatsDB.importedRuns = {}

-- In einem anderen Client: Charakter gibt es nicht, Lauf wird importiert
LevelTimerStatsDB.characters["Rekord-Testrealm"] = nil
expect("ein Lauf importiert", Runs.Import(text), 1)
expect("doppelt nicht", Runs.Import(text), 0)
local imported = Runs.Get("import:1")
expect("importierter Name", imported.name, "Rekord")
expect("importierte Zeiten", imported.times[11], 2500)
expect("als importiert markiert", imported.imported, true)

-- Als Vergleich wählbar
addon.Splits.SetReferenceRun(imported)
expect("Vergleich aus Import", addon.Splits.GetReference(10), 2500)

-- Ungültige Texte
expect("Müll", Runs.Import("hallo"), nil)
local broken = addon.Serializer.Encode("run", { name = "X", times = { [10] = "viel" } })
expect("Zeiten keine Zahlen", Runs.Import(broken), nil)
-- Unendlich: Lua 5.1 im Spiel macht aus n1e999 inf, gopher-lua lehnt den Text schon beim Lesen ab; daher zusätzlich
-- mit untergeschobenem Decode-Ergebnis geprüft. Dazu Level ohne ganze Zahl 1..MAX_LEVEL und zu große Zeiten.
local function withInfinity(run)
  return (addon.Serializer.Encode("run", run):gsub("n12345", "n1e999"))
end
local function importDecoded(run)
  local decode = addon.Serializer.Decode
  addon.Serializer.Decode = function(kind) return kind == "run" and run or nil end
  local added = Runs.Import("egal")
  addon.Serializer.Decode = decode
  return added
end
local inf = math.huge
expect("Text n1e999", Runs.Import(withInfinity({ name = "X", times = { [10] = 12345 } })), nil)
expect("Zeit unendlich", importDecoded({ name = "X", times = { [10] = inf } }), nil)
expect("Level unendlich", importDecoded({ name = "X", times = { [inf] = 5 } }), nil)
expect("Level 0", importDecoded({ name = "X", times = { [0] = 5 } }), nil)
expect("Level negativ", importDecoded({ name = "X", times = { [-3] = 5 } }), nil)
expect("Level krumm", importDecoded({ name = "X", times = { [2.5] = 5 } }), nil)
expect("Level zu hoch", importDecoded({ name = "X", times = { [Runs.MAX_LEVEL + 1] = 5 } }), nil)
expect("Zeit zu groß", importDecoded({ name = "X", times = { [10] = 1e250 } }), nil)
local before = #LevelTimerStatsDB.importedRuns
expect("erreichtes Level unendlich", importDecoded({ name = "Inf", reachedLevel = inf, times = { [10] = 77 } }), 1)
expect("erreichtes Level verworfen", LevelTimerStatsDB.importedRuns[before + 1].reachedLevel, nil)

-- Sicherung aller Läufe enthält eigene und importierte
local backup = Runs.ExportAll()
expectTrue("Sicherung", backup:find("LT1:runs:", 1, true) == 1)

-- Import über das Fenster
LevelTimerStatsDB.importedRuns = {}
SlashCmdList.LEVELTIMER("runs import")
expect("Fenster offen", LevelTimerExport:IsShown(), true)
local editBox = wow.findFrame(function(frame) return frame._scripts.OnEscapePressed ~= nil and rawget(frame, "label") == nil and frame._text == "" end)
expect("Eingabefeld hat den Fokus", editBox:HasFocus(), true)
-- Fokus verloren (z.B. Fenster gewechselt): ein Klick irgendwo in den Textbereich holt ihn zurück
editBox:ClearFocus()
local textArea = wow.findFrame(function(frame) return frame._scripts.OnMouseDown ~= nil and frame._scripts.OnMouseWheel ~= nil end)
textArea._scripts.OnMouseDown(textArea, "LeftButton")
expect("Klick in den Textbereich fokussiert", editBox:HasFocus(), true)
editBox:SetText(text)
expectTrue("Button Importieren", wow.click(L.IMPORT))
expect("über Fenster importiert", #LevelTimerStatsDB.importedRuns, 1)
expect("Fenster zu", LevelTimerExport:IsShown(), false)

-- Streamer-Datenschutz: Export ohne Realm, andere Charaktere ohne echten Namen
addon.Set("streamerPrivacy", true)
LevelTimerStatsDB.characters["Geheim-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Geheim", realm = "Testrealm", class = "MAGE",
  currentLevel = { level = 30, counters = {} }, levelHistory = { [10] = { level = 10, seconds = 100 } }, sessionHistory = {},
}
local private = Runs.Export(Runs.Get("Geheim-Testrealm"))
expectTrue("kein echter Name", not private:find("Geheim", 1, true))
expectTrue("kein Realm", not private:find("Testrealm", 1, true))
addon.Set("streamerPrivacy", false)

-- Escape-Sequenzen in importierten Namen werden entfernt
local escaped = addon.Serializer.Encode("run", { name = "|cffff0000Böse|r|Hitem:1|h", times = { [10] = 1 } })
Runs.Import(escaped)
local last = LevelTimerStatsDB.importedRuns[#LevelTimerStatsDB.importedRuns]
expect("ohne Escape-Sequenzen", last.name, "cffff0000BöserHitem:1h")
