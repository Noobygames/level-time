-- Level Time Goals, Schema 2 (Roadmap 431): frühere eigene Bingo-Texte werden eigene Ziele; weil sie früher die
-- mitgelieferten Texte ersetzten, sind diese danach im Glücksrad aus. Alte Scheine ohne chosen laufen weiter.
local Library = streamGoal.Library
local Wheel = streamGoal.Wheel
local Bingo = streamGoal.Bingo
local Goals = streamGoal.Goals

StreamGoalDB = {
  schemaVersion = 1,
  nextId = 3,
  goals = {
    { id = 1, kind = "bingo", character = "Testchar-Testrealm", createdAt = 0, target = 1, start = 0, progress = 0,
      status = "active", params = { size = 3, cells = { 2, 0, 0, 0, 0, 0, 0, 0, 0 } } },
    { id = 2, kind = "custom", character = "Testchar-Testrealm", createdAt = 0, target = 1, start = 0, progress = 0,
      status = "active", params = { text = "Alt", counted = false }, parentId = 1, cell = true },
  },
  settings = { bingoTexts = { "Fisch fangen", "  ", "Tanzen" } },
  wheel = { goalId = 7, rerollsLeft = 1 },
}
wow.login({ level = 10, name = "Testchar" })

expect("Schema 2", StreamGoalDB.schemaVersion, 2)
expect("alte Texte weg", StreamGoalDB.settings.bingoTexts, nil)
expect("zwei eigene Ziele (leere fallen weg)", #Library.Entries(), 2)
expect("Text übernommen", Library.Entries()[1].params.text, "Fisch fangen")
expect("mitgelieferte Texte im Rad aus", Wheel.IsEnabled("p:text1"), false)
expect("andere Vorgaben an", Wheel.IsEnabled("p:kills10"), true)
expect("eigene an", Wheel.IsEnabled(streamGoal.Pool.OwnKey(Library.Entries()[1].id)), true)
expect("Stand des Rads bleibt", StreamGoalDB.wheel.rerollsLeft, 1)
expect("Befehl zeigt die Texte", Bingo.Texts()[2], "Tanzen")

-- Schein von vorher
local board = Goals.Get(1)
expect("alter Schein aktiv", board ~= nil and board.status, Goals.ACTIVE)
expect("ohne chosen", board.params.chosen, nil)

-- Zweiter Login: keine zweite Migration
wow.logout()
wow.login({ level = 10, name = "Testchar" })
expect("nicht doppelt", #Library.Entries(), 2)
