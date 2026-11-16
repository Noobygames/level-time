-- Twink-Questgeber auf der Weltkarte (LT-257): Quests, die ein anderer eigener Charakter angenommen hat, als
-- Ausrufezeichen am gelernten Geber; Filter eigener Charakter, Level, Fraktion, erledigt, im Log.
-- Auch von era_alt_quest_givers_test.lua geladen.
local AltQuestGivers = addon.AltQuestGivers
local QuestNpcs = addon.QuestNpcs

WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
local canvas = CreateFrame("Frame")
canvas:SetSize(1000, 600)
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame.GetMapID = function() return 1429 end
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function() return { GetXY = function() return 0.4, 0.6 end } end,
}
local completed = {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end

-- Hauptcharakter nimmt Quest 60 (Level 12) bei Farmer Saldean an
wow.state.questLog = {}
wow.login({ level = 20 })
addon.Set("questLearning", true)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
wow.state.units.npc = { name = "Farmer Saldean", guid = "Creature-0-1-0-1-233-0000ABCD" }
wow.state.questID = 60
wow.fire("QUEST_DETAIL")
wow.state.questLog = { { questID = 60, title = "Eberjagd", level = 12, objectives = {} } }
wow.fire("QUEST_ACCEPTED", 60)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
local record = QuestNpcs.Get(60)
expect("gelernt von", record.by, "Testchar-Testrealm")
expect("Questlevel", record.level, 12)
expect("Titel", record.title, "Eberjagd")
expect("Fraktion", record.faction, "Alliance")
expect("eigener Charakter: kein Punkt", #AltQuestGivers.PointsOn(1429), 0)

-- Twink ohne die Quest im Log
wow.logout()
wow.state.questLog = {}
wow.login({ name = "Twink", level = 10 })
local points = AltQuestGivers.PointsOn(1429)
expect("Twink: ein Punkt", #points, 1)
expect("Titel im Tooltip", points[1].title, "Eberjagd")
expect("bekannt von", points[1].by, "Testchar-Testrealm")
expect("Geber", points[1].npc, "Farmer Saldean")
expectNear("am Geber", points[1].x, 0.4)
expect("andere Karte leer", #AltQuestGivers.PointsOn(1411), 0)

-- Level: Questlevel zwischen Spielerlevel - 5 und Spielerlevel + 2
wow.state.level = 9
expect("Quest 3 Level drüber", #AltQuestGivers.PointsOn(1429), 0)
wow.state.level = 18
expect("Quest 6 Level drunter", #AltQuestGivers.PointsOn(1429), 0)
wow.state.level = 17
expect("Quest 5 Level drunter", #AltQuestGivers.PointsOn(1429), 1)

wow.state.faction = "Horde"
expect("andere Fraktion", #AltQuestGivers.PointsOn(1429), 0)
wow.state.faction = "Alliance"

completed[60] = true
expect("erledigt", #AltQuestGivers.PointsOn(1429), 0)
completed[60] = nil

wow.state.questLog = { { questID = 60, title = "Eberjagd", level = 12, objectives = {} } }
expect("im Log", #AltQuestGivers.PointsOn(1429), 0)
wow.state.questLog = {}

-- Einstellung: Rahmen auf der Kartenleinwand
expect("Standard aus", addon.db.altQuestGivers, false)
addon.Set("altQuestGivers", true)
expectTrue("Rahmen", LevelTimerAltQuestGivers ~= nil and LevelTimerAltQuestGivers._parent == canvas)
wow.update(1)
addon.Set("altQuestGivers", false)
expectTrue("aus: versteckt", not LevelTimerAltQuestGivers:IsShown())
expect("Fehler?", #wow.errors, 0)
