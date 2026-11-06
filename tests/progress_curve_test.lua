-- Fortschrittskurve (Roadmap 279): Level mit Bruchteil über /played, weitere Charaktere und der Splits-Vergleich.
local ProgressCurve = addon.ProgressCurve

-- Twink mit /played-Ständen ab Level 1 und einer mit nur Level-Zeiten (Addon später installiert)
LevelTimerStatsDB = LevelTimerStatsDB or { characters = {} }
LevelTimerStatsDB.characters = LevelTimerStatsDB.characters or {}
local function otherCharacter(name, class, levels, current)
  LevelTimerStatsDB.characters[name .. "-Testrealm"] = {
    schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = name, realm = "Testrealm", class = class,
    currentLevel = current, levelHistory = levels, sessionHistory = {}, killLog = {}, deathLog = {},
  }
end

wow.login({ name = "Neu", level = 3, xp = 250, xpMax = 1000, playedSeconds = 600 })
otherCharacter("Schnell", "MAGE", {
  [1] = { level = 1, seconds = 300, totalPlayed = 300 },
  [2] = { level = 2, seconds = 500, totalPlayed = 800 },
}, { level = 3, seconds = 100, counters = {} })
otherCharacter("Spaet", "WARRIOR", {
  [5] = { level = 5, seconds = 1000 },
  [6] = { level = 6, seconds = 2000 },
}, { level = 7, seconds = 50, counters = {} })

-- Punkte mit /played: Start bei 0 (Level 1), Level 2 bei 300, Level 3 bei 800, laufend 800 + 100
local points = ProgressCurve.CharacterPoints("Schnell-Testrealm")
expect("Punkte", #points, 4)
expect("Start", points[1].x, 0)
expect("Level 2 bei 300", points[2].x, 300)
expect("Level 3 bei 800", points[3].x, 800)
expect("laufend", points[4].x, 900)
expect("laufend ohne Bruchteil", points[4].y, 3)

-- Ohne /played: von 0 an mit den Level-Zeiten
points = ProgressCurve.CharacterPoints("Spaet-Testrealm")
expect("Start Level 5", points[1].y, 5)
expect("Level 7 bei 3000", points[3].x, 3000)

-- Eingeloggt: /played jetzt mit XP-Anteil
points = ProgressCurve.CharacterPoints(addon.characterKey)
local last = points[#points]
expectNear("Bruchteil", last.y, 3.25)
expect("bei /played", last.x, 100600)

-- Reihen: gewählter Charakter, andere, Vergleich (Bestzeit je Level der anderen: 1 = 300, 2 = 500)
local series = ProgressCurve.Series(addon.characterKey)
expect("gewählter zuerst", series[1].label, addon.History.DisplayName(addon.characterKey))
local reference = series[#series]
expectTrue("Vergleich gestrichelt", reference.dashed)
expect("Vergleich beginnt bei Level 1", reference.points[1].y, 1)
expect("Vergleich Level 3 nach 800", reference.points[3].x, 800)
expectNear("Klassenfarbe", series[2].color[1], 0.25)

-- Historie: Diagramm anklickbar
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Graphen", wow.click("Graphen"))
expectTrue("Diagramm Kurve", wow.click("Kurve"))
