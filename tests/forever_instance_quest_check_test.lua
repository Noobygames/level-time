-- Quest-Check beim Betreten einer Instanz (WoW Forever): eine Chatzeile mit den verfügbaren Dungeonquests, die nicht
-- im Log sind. Halle der Thanen (3065), Allianz, Level 10: 96395 abgegeben, 96403 im Log, 96393 braucht Vorquest 96391.
local L = addon.L
local Check = addon.InstanceQuestCheck

local function enter(name, mapID)
  wow.state.instance = { name = name, type = "party", mapID = mapID }
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function leave()
  wow.state.instance = nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function lastLine() return wow.printed[#wow.printed] or "" end

local completed = { [96395] = true }
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
C_Map = C_Map or {}
C_Map.GetMapInfo = function(uiMapID) return { name = "Karte " .. uiMapID } end
wow.state.questLog = { { questID = 96403, title = "Wichtige Erbstücke", objectives = {} } }
wow.state.questTitles[96394] = "Die ruhelosen Toten"
wow.login({ level = 10 })
wow.fire("QUEST_LOG_UPDATE")

expectTrue("Forever: verfügbar", Check.IsAvailable())
local ids = {}
for _, quest in ipairs(Check.Missing(3065)) do table.insert(ids, quest.questID) end
expect("fehlend: ohne abgegebene, Log und offene Vorquest", table.concat(ids, ","), "96394,98423")

-- Betreten: eine Zeile mit Anzahl, Level, Titel und Startort
enter("Halle der Thanen", 3065)
local line = lastLine()
expectTrue("Kopf mit Anzahl", line:find(string.format(L.INSTANCE_QUEST_CHECK_MISSING, 2, ""), 1, true) ~= nil)
expectTrue("Titel aus dem Client mit Startort", line:find("[15] Die ruhelosen Toten (Karte 1455 (33, 48))", 1, true) ~= nil)
expectTrue("Rückfall-Name", line:find("[16] The Treaty of Understanding", 1, true) ~= nil)

-- Wiedereintritt mit derselben Liste: keine neue Zeile
leave()
local count = #wow.printed
enter("Halle der Thanen", 3065)
expect("gleiche Liste nicht wiederholen", #wow.printed, count)

-- Vorquest abgegeben: 96393 kommt dazu, neue Meldung
completed[96391] = true
leave()
enter("Halle der Thanen", 3065)
expectTrue("Vorquest erfüllt", lastLine():find(string.format(L.INSTANCE_QUEST_CHECK_MISSING, 3, ""), 1, true) ~= nil)

-- Alles angenommen: keine Meldung
wow.state.questLog = {
  { questID = 96394, title = "a", objectives = {} }, { questID = 98423, title = "b", objectives = {} },
  { questID = 96393, title = "c", objectives = {} }, { questID = 96403, title = "d", objectives = {} },
}
wow.fire("QUEST_LOG_UPDATE")
expect("alles im Log", Check.Text(3065), nil)

-- Ausschluss: Gnomeregan 2951 entfällt, sobald 4601 abgegeben ist; zu hohes Mindestlevel fällt weg
wow.state.level = 30
local function missingIn(mapID, questID)
  for _, quest in ipairs(Check.Missing(mapID)) do
    if quest.questID == questID then return true end
  end
  return false
end
expectTrue("Gnomeregan: 2951 offen", missingIn(90, 2951))
completed[4601] = true
expectTrue("ausgeschlossen", not missingIn(90, 2951))
expectTrue("Mindestlevel zu hoch", not missingIn(229, 4701))

-- Aus: keine Meldung
addon.Set("instanceQuestCheck", false)
leave()
count = #wow.printed
enter("Burg Schattenfang", 33)
expect("aus: still", #wow.printed, count)
