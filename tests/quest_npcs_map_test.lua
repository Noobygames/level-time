-- Quest-NPCs und Orte lernen, Questkarte (Roadmap 350): Annahme- und Abgabe-NPC mit Ort, Zielorte beim Anstieg,
-- Punkte für Quests im eigenen Log auf der Weltkarte, NPC-Spalte der Abgabe-Übersicht.
local QuestNpcs = addon.QuestNpcs
local QuestMap = addon.QuestMap

local shownMap = 1429
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
local canvas = CreateFrame("Frame")
canvas:SetSize(1000, 600)
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame.GetMapID = function() return shownMap end
local playerPosition = { 0.4, 0.6 }
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function()
    return { GetXY = function() return playerPosition[1], playerPosition[2] end }
  end,
}

local boars = { text = "Eber: 0/5", finished = false, type = "monster" }
wow.state.questLog = { { questID = 60, title = "Eberjagd", objectives = { boars } } }

wow.login({ level = 10 })
addon.Set("questLearning", true)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)

-- Annahme beim NPC: Name, NPC-ID, Ort
wow.state.units.npc = { name = "Farmer Saldean", guid = "Creature-0-1-0-1-233-0000ABCD" }
wow.state.questID = 60
wow.fire("QUEST_DETAIL")
local record = QuestNpcs.Get(60)
expect("Geber", record.giver.name, "Farmer Saldean")
expect("NPC-ID", record.giver.npcId, 233)
expectNear("Ort x", record.giver.x, 0.4)

-- Zielorte: nahe Punkte nur einmal
boars.text = "Eber: 1/5"
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
playerPosition = { 0.405, 0.6 }
boars.text = "Eber: 2/5"
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
playerPosition = { 0.5, 0.7 }
boars.text = "Eber: 3/5"
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expect("zwei Zielorte", #record.spots, 2)

-- Karte: offene Quest = Zielpunkte
expect("Punkte der offenen Quest", #QuestMap.PointsOn(1429), 2)
expect("andere Karte leer", #QuestMap.PointsOn(1411), 0)

-- Abgabe-Dialog bei einem anderen NPC; fertige Quest = Fragezeichen am Abgabe-NPC
wow.state.units.npc = { name = "Gryan", guid = "Creature-0-1-0-1-234-0000ABCE" }
wow.fire("QUEST_COMPLETE")
wow.state.questLog[1].isComplete = 1
local points = QuestMap.PointsOn(1429)
expect("fertig: ein Punkt", #points, 1)
expect("am Abgabe-NPC", points[1].npc, "Gryan")
expect("Abgabe-Übersicht kennt den NPC", QuestNpcs.TurnInName(60), "Gryan")

-- Karte an: Rahmen auf der Leinwand
addon.Set("questMap", true)
expectTrue("Rahmen", LevelTimerQuestMap ~= nil and LevelTimerQuestMap._parent == canvas)
wow.update(1)
addon.Set("questMap", false)
expectTrue("aus: versteckt", not LevelTimerQuestMap:IsShown())

-- Ohne Lernen: nichts gespeichert
addon.Set("questLearning", false)
wow.state.questID = 61
wow.fire("QUEST_DETAIL")
expect("aus: nichts", QuestNpcs.Get(61), nil)
expect("Fehler?", #wow.errors, 0)
