-- Persönliche Rekorde mit Ansage (Roadmap 272): beste 60 Minuten, Session-XP/h, größter Gewinn, Instanz-Lauf, schnellstes Level.
local Records = addon.PersonalRecords
local L = addon.L

local function gain(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function announced(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

-- Anderer Charakter hatte Level 10 in 600 s (Bestzeit)
LevelTimerStatsDB = { characters = {
  ["Alt-Testrealm"] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Alt", realm = "Testrealm",
    currentLevel = { level = 30 }, levelHistory = { [10] = { level = 10, seconds = 600, xp = 1000, counters = {} } } },
} }
wow.login({ level = 10, xp = 0, xpMax = 100000, playedSeconds = 0 })
addon.Set("announceRecords", true)

-- Erster Wert: gespeichert, aber keine Meldung (es gab keinen alten)
gain(500)
expect("größter Gewinn gespeichert", Records.Get(Records.BIGGEST_GAIN).value, 500)
expect("Halter", Records.Get(Records.BIGGEST_GAIN).characterKey, addon.characterKey)
expect("keine Meldung beim ersten Wert", announced(L.RECORD_TITLE), false)

-- Kleinerer Gewinn: kein Rekord; größerer: Meldung
gain(200)
expect("kleiner bleibt", Records.Get(Records.BIGGEST_GAIN).value, 500)
addon.Alerts.Clear()
gain(800)
expect("neuer Rekord", Records.Get(Records.BIGGEST_GAIN).value, 800)
expectTrue("Meldung", announced(string.format(L.RECORD_BROKEN, L.RECORD_BIGGEST_GAIN, "800", "500")))
expectTrue("Karte", LevelTimerNotice.title ~= nil)

-- Beste 60 Minuten: gleitend über den 5-min-Verlauf
expect("60 Minuten bisher", Records.Get(Records.BEST_HOUR).value, 1500)
wow.advance(3700)  -- alles Bisherige liegt über eine Stunde zurück
gain(100)
expect("altes Fenster bleibt Rekord", Records.Get(Records.BEST_HOUR).value, 1500)
gain(1500)
expect("neues Fenster", Records.Get(Records.BEST_HOUR).value, 1600)
local before = #wow.printed
gain(100)
expect("steigt weiter", Records.Get(Records.BEST_HOUR).value, 1700)
local hourLines = 0
for i = before + 1, #wow.printed do
  if wow.printed[i]:find(L.RECORD_BEST_HOUR, 1, true) then hourLines = hourLines + 1 end
end
expect("laufender Wert nur einmal je Session gemeldet", hourLines, 0)

-- Session-XP/h erst ab 30 Minuten
expect("Session-XP/h erst bei der Prüfung", Records.Get(Records.BEST_SESSION_RATE), nil)
wow.update(61)
expectTrue("Session-XP/h gespeichert", Records.Get(Records.BEST_SESSION_RATE).value > 0)

-- Instanz-Lauf: Rate aus dem Journal-Eintrag, kurze Läufe nicht
addon.Journal.AddInstanceRun({ startedAt = time(), name = "Kurz", instanceType = "party", seconds = 60, level = 10,
  stats = { xpGained = 9000 } })
expect("kurzer Lauf zählt nicht", Records.Get(Records.BEST_INSTANCE_RATE), nil)
addon.Journal.AddInstanceRun({ startedAt = time(), name = "Todesminen", instanceType = "party", seconds = 1800, level = 10,
  stats = { xpGained = 9000 } })
expect("Lauf-Rate", Records.Get(Records.BEST_INSTANCE_RATE).value, 18000)

-- Schnellstes Level: 500 s statt 600 s
wow.fire("TIME_PLAYED_MSG", 100000, 500)
wow.state.xp = 100000
wow.fire("PLAYER_XP_UPDATE", "player")
wow.levelUp(11, 120000)
expectTrue("schnellstes Level gemeldet",
  announced(string.format(L.RECORD_FASTEST_LEVEL, 10, addon.Format.Duration(500), addon.Format.Duration(600))))

-- Zeilen der Historie
local rows = Records.GetRows()
expect("vier Rekord-Arten", #rows, 4)
expect("Wert formatiert", rows[3].value, "96.8k")

-- Meldung aus: gespeichert, nicht gemeldet
addon.Set("announceRecords", false)
local count = #wow.printed
gain(300000)
expect("ohne Meldung gespeichert", Records.Get(Records.BIGGEST_GAIN).value, 300000)
expect("keine Chatzeile", #wow.printed, count)
