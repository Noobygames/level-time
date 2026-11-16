-- Routen-Checkliste (LT-262): bester anderer Lauf, Quest-Reihenfolge, Abhaken, nächste drei Schritte, Fenster, /lt route.
local RouteReplay = addon.RouteReplay

wow.login({ level = 10 })
expect("ohne anderen Charakter keine Route", RouteReplay.Get(), nil)

local function twin(name, level, seconds, quests)
  LevelTimerStatsDB.characters[name .. "-Testrealm"] = {
    schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = name, realm = "Testrealm",
    currentLevel = { level = level }, levelHistory = { [level - 1] = { level = level - 1, seconds = seconds } },
    questLog = quests,
  }
end
local function quest(id) return { time = id, questID = id, name = "Quest " .. id, level = 5 + id } end
twin("Schwach", 20, 100, { quest(1) })
twin("Stark", 30, 500, { quest(1), quest(2), quest(2), quest(3), quest(4), quest(5) })
addon.Runs.Invalidate()

local route = RouteReplay.Get()
expect("höchstes Level gewinnt", route.run.name, "Stark")
expect("jede Quest einmal", #route.steps, 5)
expect("Reihenfolge", route.steps[3].questID, 3)

-- Quest 1 beim eingeloggten Charakter abgegeben: abgehakt; die nächsten drei offenen golden
addon.character.questLog[1] = quest(1)
addon.QuestItemTooltip.IsQuestDone = function(questID) return questID == 1 end
route = RouteReplay.Get()
expect("abgehakt", route.steps[1].status, "done")
expect("Fortschritt", route.done, 1)
expect("erster nächster", route.steps[2].status, "next")
expect("dritter nächster", route.steps[4].status, "next")
expect("danach offen", route.steps[5].status, "open")

-- Fenster per /lt route
SlashCmdList.LEVELTIMER("route")
expect("Einstellung an", addon.db.routeReplay, true)
expectTrue("Fenster sichtbar", LevelTimerRouteReplay:IsShown())
SlashCmdList.LEVELTIMER("route")
expect("Fenster aus", LevelTimerRouteReplay:IsShown(), false)

expect("keine Fehler", #wow.errors, 0)
