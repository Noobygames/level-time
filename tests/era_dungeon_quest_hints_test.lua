-- Dungeonquest-Hinweise (Classic Era, DungeonDB): Fenster beim Betreten einer Zone mit Gebern.
-- Wilder Klippenschmied 656 steht auf Karte 1453 (70, 41) und bietet 167/168 (Allianz, ab 15/14).
local L = addon.L
local Hint = addon.DungeonQuestHint
local Hints = addon.DungeonQuestHints

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
function GetRealZoneText(mapID) return mapID == 36 and "Die Todesminen" or ("Instanz " .. tostring(mapID)) end
wow.state.questTitles[167] = "Die Bruderschaft"
wow.state.questTitles[168] = "Gesammelte Erinnerungen"

local MAPS = {
  [1415] = { name = "Östliche Königreiche", mapType = 2 },
  [1453] = { name = "Sturmwind", mapType = 3, parentMapID = 1415 },
  [9999] = { name = "Testzone", mapType = 3, parentMapID = 1415 },
}
local playerMap = { id = 9999 }
C_Map = {
  GetBestMapForUnit = function() return playerMap.id end,
  GetMapInfo = function(mapID) return MAPS[mapID] end,
}

wow.state.class = "WARRIOR"
wow.login({ level = 15 })
wow.fire("QUEST_LOG_UPDATE")
expect("Standard an", addon.db.dungeonQuestZoneHint, true)

-- Zone ohne Geber: kein Fenster
wow.fire("PLAYER_ENTERING_WORLD")
expectTrue("ohne Geber: kein Fenster", not Hint.IsShown())

-- Ausgeschaltet: nichts
playerMap.id = 1453
addon.Set("dungeonQuestZoneHint", false)
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("aus", not Hint.IsShown())

-- Sturmwind: zwei Angebote, Titel mit Zonenname, Zeile mit Instanz, Geber und Ort
addon.Set("dungeonQuestZoneHint", true)
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("Sturmwind: Fenster", Hint.IsShown())
local entries = Hints.ZoneEntries(1453)
expectTrue("mindestens 167 und 168", #entries >= 2)
local texts = {}
for _, entry in ipairs(entries) do texts[entry.text] = entry end
local first = texts[string.format(L.DUNGEON_QUEST_HINT_ROW, "Die Bruderschaft", "Die Todesminen")]
expectTrue("Zeile mit Instanz", first ~= nil)
expect("Geber und Ort", first and first.detail,
  string.format(L.DUNGEON_QUEST_HINT_DETAIL, L.DUNGEON_QUEST_GIVER_NPC, "Sturmwind (70, 41)"))

-- Name aus dem Kreaturen-Cache des Clients (versteckter Tooltip mit unit-Link) ersetzt "Questgeber"
local scanTitle = CreateFrame("Frame")
scanTitle.GetText = function() return "Wilder Klippenschmied" end
_G[addon.GlobalName("NpcNameScanTooltip") .. "TextLeft1"] = scanTitle
expect("Name aus dem Client", Hints.GiverName(168), "Wilder Klippenschmied")
-- Offenes Fenster zieht den Namen nach (war beim Öffnen noch "Questgeber")
wow.update(1.1)
local shownRows, shownEntries = Hint.Rows()
local refreshed
for _, candidate in ipairs(shownRows) do
  if shownEntries[candidate] and shownEntries[candidate].questID == 168 then refreshed = candidate.detail:GetText() end
end
expect("Fenster zieht Namen nach", refreshed,
  string.format(L.DUNGEON_QUEST_HINT_DETAIL, "Wilder Klippenschmied", "Sturmwind (70, 41)"))
expect("NpcNames: keine ID", addon.NpcNames.Get(nil), nil)
_G[addon.GlobalName("NpcNameScanTooltip") .. "TextLeft1"] = nil

-- Gelernter Gebername ersetzt "Questgeber"
LevelTimerStatsDB.questNpcs = { [167] = { giver = { name = "Wilder Klippenschmied" }, spots = {} } }
expect("gelernter Name", Hints.GiverName(167), "Wilder Klippenschmied")

-- Schließt nach der Anzeigedauer von selbst
wow.advance(Hint.DISPLAY_SECONDS + 1)
wow.update(0.1)
expectTrue("schließt von selbst", not Hint.IsShown())

-- Einmal je Zone und Sitzung
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("nicht zweimal", not Hint.IsShown())

-- Annahme: übrige Quests der Todesminen, jetzt annehmbare zuerst, später verfügbare leiser
expect("Annahme-Hinweis Standard an", addon.db.dungeonQuestAcceptHint, true)
local opened = {}
function OpenWorldMap(mapID) table.insert(opened, mapID) end
wow.update(1)  -- erster Stand des Questlogs
wow.state.questLog = { { questID = 167, title = "Die Bruderschaft", level = 20, objectives = {} } }
wow.fire("QUEST_ACCEPTED", 1, 167)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expectTrue("Annahme: Fenster", Hint.IsShown())
local accepted = Hints.AcceptEntries(167)
local byQuest, mutedCount = {}, 0
for _, entry in ipairs(accepted) do
  byQuest[entry.questID] = entry
  if entry.muted then mutedCount = mutedCount + 1 end
end
expectTrue("angenommene fehlt", byQuest[167] == nil)
expectTrue("168 jetzt annehmbar", byQuest[168] ~= nil and not byQuest[168].muted)
expectTrue("annehmbare zuerst", not accepted[1].muted)
expectTrue("später verfügbare dabei", mutedCount > 0)
expectTrue("214 wartet auf Vorquest", byQuest[214] ~= nil and byQuest[214].muted)
expect("keine Dungeonquest: nichts", Hints.AcceptEntries(999999), nil)

-- Klick auf eine Zeile: Kartenpunkt und Karte auf der Zone
local row
local rows, rowEntries = Hint.Rows()
for _, candidate in ipairs(rows) do
  if rowEntries[candidate] and rowEntries[candidate].questID == 168 then row = candidate end
end
expectTrue("Zeile 168", row ~= nil)
if row then row:GetScript("OnClick")(row) end
expect("Kartenpunkt", Hint.Waypoint() and Hint.Waypoint().uiMapID, 1453)
expect("Karte geöffnet", opened[1], 1453)

