-- Quest-Knöpfe nur in der Zone der Quest (WoW Forever): Questkarte aus GetQuestUiMapID über die Kartenkette,
-- gelernte Orte als Hinweis, unbekannte Quests bleiben
local QuestItem = addon.QuestItem
local QuestLog = addon.QuestLog
local item = LevelTimerQuestItemButton

local MAPS = {
  [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
  [1415] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
  [1429] = { name = "Elwynn Forest", mapType = 3, parentMapID = 1415 },
  [1436] = { name = "Westfall", mapType = 3, parentMapID = 1415 },
  [9001] = { name = "Fargodeep Mine", mapType = 5, parentMapID = 1429 },
  [9002] = { name = "Mine Floor 2", mapType = 6, parentMapID = 9001 },
}
C_Map = {
  GetBestMapForUnit = function() return wow.state.mapID end,
  GetMapInfo = function(mapID)
    local map = MAPS[mapID]
    return map and { mapID = mapID, name = map.name, mapType = map.mapType, parentMapID = map.parentMapID }
  end,
  GetMapChildrenInfo = function() return {} end,
}
local questMaps = { [80] = 1429, [81] = 1436, [82] = 0, [83] = 9002, [84] = 0 }
function GetQuestUiMapID(questID, ignoreWaypoints)
  expect("ohne Wegpunkte", ignoreWaypoints, true)
  return questMaps[questID] or 0
end

local function special(id) return { "|cffffffff|Hitem:" .. id .. "::::|h[Item]|h|r", 134000 } end
wow.state.questLog = {
  { title = "Elwynn Forest", isHeader = true },
  { title = "Elwynn", questID = 80, specialItem = special(5000) },
  { title = "Westfall", questID = 81, specialItem = special(5001) },  -- Überschrift Elwynn, Karte Westfall
  { title = "Seasonal", isHeader = true },
  { title = "Ohne Karte", questID = 82 },
  { title = "Mine", questID = 83 },
  { title = "Gelernt", questID = 84 },
}
wow.state.zone, wow.state.mapID = "Elwynn Forest", 9001
wow.login({ level = 10 })
LevelTimerStatsDB.questNpcs = { [84] = { spots = { { mapID = 1436, x = 0.5, y = 0.5 } } } }

-- Spieler in der Mine (Kleinstkarte unter Elwynn)
local here = QuestLog.Here()
expect("Zone der Mine", here.zone, 1429)
expectTrue("Kartenname Elwynn im Ort", here.names["Elwynn Forest"] == true)
expect("Quest in Elwynn", (QuestItem.ZoneOf(80)), true)
expect("Überschrift hier gewinnt über Westfall-Karte", (QuestItem.ZoneOf(81)), true)
local status, signals = QuestItem.ZoneOf(81)
expect("Karte sagt woanders", signals.map, false)
expect("ohne Karte, Kategorie: unbekannt", (QuestItem.ZoneOf(82)), nil)
expect("Stockwerk der Mine zählt zu Elwynn", (QuestItem.ZoneOf(83)), true)
expect("gelernter Ort Westfall: woanders", (QuestItem.ZoneOf(84)), false)
expectTrue("unbekannt zählt als hier", QuestItem.IsInZone(82) and not QuestItem.IsInZone(84))
expect("Gesamtstatus mit einem Hinweis hier", status, true)

-- Westfall: Elwynn-Quest weg, die Westfall-Karte zählt
wow.state.questLog[1].title = "Westfall Area"
wow.fire("QUEST_LOG_UPDATE")
wow.state.zone, wow.state.mapID = "Westfall", 1436
wow.fire("ZONE_CHANGED_NEW_AREA")
expect("Elwynn-Quest woanders", (QuestItem.ZoneOf(80)), false)
expect("Westfall-Quest hier", (QuestItem.ZoneOf(81)), true)
expect("gelernter Ort hier", (QuestItem.ZoneOf(84)), true)
addon.Set("questItemButton", true)
expect("Westfall-Item", item:GetAttribute("item"), "item:5001")

-- Kartenwechsel innerhalb der Zone (ZONE_CHANGED): neu gelesen
wow.state.zone, wow.state.mapID = "Elwynn Forest", 1429
wow.fire("ZONE_CHANGED")
expect("zurück in Elwynn", item:GetAttribute("item"), "item:5000")
expect("Fehler?", #wow.errors, 0)
