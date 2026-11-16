-- Forever-Dungeonführer (ns.InstanceGuide): Level-Bereiche für InstanceInfo, Boss-Level im Instanz-Tooltip und
-- Dungeon-Eingänge auf der Weltkarte mit den offenen Dungeonquests des Charakters (aus ns.DungeonDB).
local L = addon.L
local Info = addon.InstanceInfo
local DungeonEntrances = addon.DungeonEntrances

-- Level-Bereiche: Wehklagen, Flügel von Düsterbruch vereint, Halle der Thanen passt zu Level 15
expectTrue("Forever liefert Level", Info.HasLevels())
expect("Wehklagen Level", Info.Get(43, 1).minLevel .. "-" .. Info.Get(43, 1).maxLevel, "15-25")
expect("Düsterbruch vereint", Info.Get(429, 1).minLevel .. "-" .. Info.Get(429, 1).maxLevel, "58-60")
local fits = {}
for _, entry in ipairs(Info.ForLevel(15)) do fits[entry.mapID] = true end
expectTrue("Level 15: Halle der Thanen", fits[3065])
expectTrue("Level 15: Wehklagen", fits[43])

-- Boss-Level im Tooltip des Laufs
expect("Boss-Level", addon.InstanceBosses.Level(3493), 16)
local lines = addon.InstanceBosses.TooltipLines({ name = "Halle", mapID = 3065, difficultyID = 1 })
expectTrue("Tooltip-Zeile mit Level", lines[2]:find("(16)", 1, true) ~= nil)

-- Eingänge: einer je Ort, Schwarzfelstiefen und -spitze teilen sich den Berg
local points = DungeonEntrances.PointsOn(1427)
expect("ein Punkt am Schwarzfels", #points, 1)
expect("zwei Instanzen am Punkt", table.concat(points[1].mapIDs, ","), "229,230")
expect("anderswo keine Eingänge", #DungeonEntrances.PointsOn(1), 0)

-- Offene Quests der Halle der Thanen (Forever-eigene Instanz in der DungeonDB): Allianz-Krieger, Quest 96395
-- abgegeben, 96403 im Log; Horde- und Klassenquests fallen weg
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return questID == 96395 end
wow.state.questLog = { { questID = 96403, title = "Wichtige Erbstücke", objectives = {} } }
wow.state.questTitles[96394] = "Die ruhelosen Toten"
wow.login({ level = 9 })
wow.fire("QUEST_LOG_UPDATE")
local open = addon.DungeonQuests.OwnQuests(3065)
local byID = {}
for _, quest in ipairs(open) do byID[quest.questID] = quest end
expect("abgegebene fehlt", byID[96395], nil)
expectTrue("im Log", byID[96403].inLog)
expect("Name aus dem Client", byID[96394].title, "Die ruhelosen Toten")
expect("Rückfall-Name aus der DungeonDB", byID[96393].title, "Old Ironforge Incursion")
expect("von Hand ergänzt", byID[98423].title, "The Treaty of Understanding")
expect("Mindestlevel", byID[96394].minLevel, 10)
expect("Startkarte", byID[96394].uiMapID, 1455)
wow.state.faction = "Horde"
expect("Horde: nur Allianz-Quests offen", #addon.DungeonQuests.OwnQuests(3065), 0)
wow.state.faction = "Alliance"

-- Weltkarte: aus = kein Rahmen; an = Symbol, Tooltip mit Name und Quests
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
local canvas = CreateFrame("Frame")
canvas:SetSize(1000, 600)
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame.GetMapID = function() return 1455 end
WorldMapFrame.OnMapChanged = function() end
expect("aus: kein Rahmen", LevelTimerDungeonEntrances, nil)
addon.Set("dungeonEntrances", true)
expectTrue("an: Rahmen auf der Leinwand", LevelTimerDungeonEntrances ~= nil)
local thanes = DungeonEntrances.PointsOn(1455)[1]
expect("Halle der Thanen in Eisenschmiede", thanes.mapIDs[1], 3065)
wow.update(1)

-- Tooltip über dem Symbol: Instanzname, offene Quests (Kopfzeile) mit Startort aus C_Map
C_Map = C_Map or {}
C_Map.GetMapInfo = function(mapID) return { name = "Karte " .. mapID } end
GetRealZoneText = function(mapID) return mapID == 3065 and "Halle der Thanen" or GetZoneText() end
-- Boss-Beute (LT-35): ein Testboss mit epischem Drop in der Halle der Thanen
addon.DungeonDB.npcs[3065] = { [990002] = { 16, 16, 3 } }
addon.DungeonDB.loot[990002] = { { 990100, 4 } }
wow.state.itemLinks = { [990100] = "|cffa335ee[Testklinge]|r" }
local pin = LevelTimerDungeonEntrances:GetChildren()
pin:GetScript("OnEnter")(pin)
-- echte Bosse der Halle (Bossliste) haben eigene Beute: der epische Drop steht zuerst
local tooltipLines, titleIndex = GameTooltip._lines, nil
for index, text in ipairs(tooltipLines) do
  if text == L.BOSS_LOOT_TITLE then titleIndex = index end
end
expectTrue("Tooltip: Beute-Überschrift", titleIndex ~= nil)
expect("Tooltip: epischer Drop", tooltipLines[(titleIndex or 0) + 1], "|cffa335ee[Testklinge]|r")
expect("Tooltip: Instanzname", GameTooltip._lines[1], "Halle der Thanen")
expect("Tooltip: offene Quests", GameTooltip._lines[3], string.format(L.DUNGEON_QUESTS_OPEN, 4))
