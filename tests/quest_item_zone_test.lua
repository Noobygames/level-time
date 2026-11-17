-- Quest-Knöpfe nur in der Zone der Quest (Retail): Überschriften, Unterzone, fehlende Kartendaten, Einstellung aus
local QuestItem = addon.QuestItem
local QuestLog = addon.QuestLog
local item = LevelTimerQuestItemButton

-- Ohne C_Map: nur Ortsnamen; eine fremde Überschrift ist dann unbekannt (bleibt)
wow.state.questLog = {
  { title = "Stormwind City", isHeader = true },
  { title = "Hafen", questID = 90, specialItem = { "|cffffffff|Hitem:5000::::|h[Seil]|h|r", 134000 } },
  { title = "Duskwood", isHeader = true },
  { title = "Wald", questID = 91, specialItem = { "|cffffffff|Hitem:6000::::|h[Laterne]|h|r", 134001 } },
}
wow.state.zone = "Elwynn Forest"
wow.login({ level = 10 })
expect("ohne Karte: fremde Überschrift unbekannt", (QuestItem.ZoneOf(90)), nil)
addon.Set("questItemButton", true)
expect("unbekannt: erste Quest", item:GetAttribute("item"), "item:5000")

-- Unterzone als Überschrift (GetSubZoneText)
function GetSubZoneText() return wow.state.subZone end
wow.state.subZone = "Duskwood"
wow.fire("ZONE_CHANGED_INDOORS")
expect("Unterzone passt", (QuestItem.ZoneOf(91)), true)

-- Mit Kartendaten: bekannte Zonennamen machen fremde Überschriften zu "woanders"
local MAPS = {
  [946] = { name = "Cosmic", mapType = 0, parentMapID = 0 },
  [13] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 946 },
  [37] = { name = "Elwynn Forest", mapType = 3, parentMapID = 13 },
  [84] = { name = "Stormwind City", mapType = 3, parentMapID = 13 },
  [47] = { name = "Duskwood", mapType = 3, parentMapID = 13 },
}
C_Map = {
  GetBestMapForUnit = function() return wow.state.mapID end,
  GetMapInfo = function(mapID)
    local map = MAPS[mapID]
    return map and { mapID = mapID, name = map.name, mapType = map.mapType, parentMapID = map.parentMapID }
  end,
  GetMapChildrenInfo = function(root, mapType, all)
    expectTrue("alle Nachfahren der Wurzel", root == 946 and mapType == nil and all == true)
    local list = {}
    for mapID in pairs(MAPS) do
      if mapID ~= root then table.insert(list, C_Map.GetMapInfo(mapID)) end
    end
    return list
  end,
}
wow.state.subZone, wow.state.mapID = "Goldshire", 37
wow.fire("PLAYER_ENTERING_WORLD")
expect("Stormwind woanders", (QuestItem.ZoneOf(90)), false)
expect("Duskwood woanders", (QuestItem.ZoneOf(91)), false)
expectTrue("keine Quest der Zone: versteckt", not item:IsShown())
expect("Kontinent ist keine Zone", QuestLog.ZoneMapOf(13), nil)

-- Einstellung aus: alte Auswahl
addon.Set("questButtonsZoneOnly", false)
expect("aus: erste Quest", item:GetAttribute("item"), "item:5000")
expectTrue("aus: sichtbar", item:IsShown())
expect("Fehler?", #wow.errors, 0)

-- Leistung: QUEST_LOG_UPDATE ohne Änderung liest den Questlog einmal je Takt, entscheidet die Zonen nicht neu und
-- schreibt keine Debug-Zeilen; erst eine geänderte Überschrift entscheidet (und loggt) die Quest neu
addon.Set("questButtonsZoneOnly", true)
wow.update(1)
local lines = { count = 0 }
addon.SetDebugRecorder(function(area, text)
  if area == "questitem" and text:find("^quest ") then lines.count = lines.count + 1 end
end)
local scans = { count = 0 }
local entries = QuestLog.Entries
QuestLog.Entries = function() scans.count = scans.count + 1 return entries() end
for _ = 1, 10 do
  wow.fire("QUEST_LOG_UPDATE")
  wow.update(1)
end
expect("unverändert: keine Debug-Zeilen", lines.count, 0)
expect("ein Questlog-Durchlauf je Takt", scans.count, 10)
wow.state.questLog[3].title = "Elwynn Forest"
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expect("neue Überschrift: neu entschieden", (QuestItem.ZoneOf(91)), true)
expect("geändertes Ergebnis geloggt", lines.count, 1)
QuestLog.Entries = entries
addon.SetDebugRecorder(nil)
expect("Fehler (Leistung)?", #wow.errors, 0)
