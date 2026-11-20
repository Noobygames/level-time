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

-- Sprachwechsel bei offenem Fenster: Zeilentext wird neu gebildet
local rowText = Hint.Rows()[1].detail
local before = rowText:GetText()
addon.Set("language", "enUS")
expectTrue("Sprachwechsel: Zeile neu übersetzt", rowText:GetText() ~= before)
addon.Set("language", "deDE")

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

-- Bleibt stehen, bis es geschlossen wird (Standard)
expect("Auto-Schließen Standard aus", addon.db.dungeonQuestHintAutoClose, false)
wow.advance(Hint.DISPLAY_SECONDS + 5)
wow.update(0.1)
expectTrue("bleibt ohne Auto-Schließen", Hint.IsShown())
Hint.Hide()
expectTrue("Schließen-Knopf", not Hint.IsShown())

-- /lt dq: Hinweis der Zone erneut (Sturmwind), ohne Zone mit Geber der zuletzt gezeigte
SlashCmdList.LEVELTIMER("dq")
expectTrue("/lt dq: Zonenhinweis", Hint.IsShown())
Hint.Hide()
playerMap.id = 9999
SlashCmdList.LEVELTIMER("dq")
expectTrue("/lt dq: zuletzt gezeigter", Hint.IsShown())
Hint.Hide()
playerMap.id = 1453

-- Mit Auto-Schließen schließt es nach der Anzeigedauer von selbst
addon.Set("dungeonQuestHintAutoClose", true)
Hint.Show("Test", Hints.ZoneEntries(1453))
wow.advance(Hint.DISPLAY_SECONDS + 1)
wow.update(0.1)
expectTrue("schließt von selbst", not Hint.IsShown())
addon.Set("dungeonQuestHintAutoClose", false)

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

-- Klick auf eine Zeile schaltet den Kartenpunkt: mehrere gleichzeitig, erneuter Klick entfernt ihn
expect("ein Punkt", Hint.PinCount(), 1)
expectTrue("Zeile markiert", row.pinMark:IsShown())
local other
for _, candidate in ipairs(rows) do
  if candidate:IsShown() and rowEntries[candidate] and rowEntries[candidate].place and candidate ~= row then other = candidate end
end
expectTrue("zweite Zeile mit Ort", other ~= nil)
other:GetScript("OnClick")(other)
expect("zwei Punkte", Hint.PinCount(), 2)
row:GetScript("OnClick")(row)
expect("Klick entfernt", Hint.PinCount(), 1)
expectTrue("Markierung weg", not row.pinMark:IsShown())

-- Alle markieren / Alle löschen
Hint.ClearAll()
expect("alle gelöscht", Hint.PinCount(), 0)
local openedBefore = #opened
Hint.MarkAll()
local withPlace, zones = 0, {}
for _, entry in ipairs(Hints.AcceptEntries(167)) do
  if entry.place then withPlace, zones[entry.place.uiMapID] = withPlace + 1, true end
end
expect("alle mit Ort markiert", Hint.PinCount(), withPlace)
expect("Karte nur einmal geöffnet", #opened, openedBefore + 1)
if next(zones, next(zones)) == nil then expectTrue("eine Zone: Karte der Zone", zones[opened[#opened]]) end
Hint.ClearAll()

-- Punkte in zwei Zonen: alle gesetzt, Karte einmal auf der übergeordneten Karte (Kontinent)
local realMapInfo = C_Map.GetMapInfo
C_Map.GetMapInfo = function(mapID) return { mapID = mapID, parentMapID = 1415 } end
Hint.Show("Zwei Zonen", { { text = "A", place = { uiMapID = 1436, x = 0.5, y = 0.5 } },
  { text = "B", place = { uiMapID = 1453, x = 0.4, y = 0.6 } } })
openedBefore = #opened
Hint.MarkAll()
expect("zwei Zonen: zwei Punkte", Hint.PinCount(), 2)
expect("zwei Zonen: einmal geöffnet", #opened, openedBefore + 1)
expect("zwei Zonen: Kontinentkarte", opened[#opened], 1415)
C_Map.GetMapInfo = realMapInfo
Hint.ClearAll()

-- Mehr Zeilen als die Fensterhöhe: alle erreichbar (Bildlauf), kein "... weitere"
local many = {}
for index = 1, Hint.MAX_ROWS + 5 do many[index] = { text = "Quest " .. index, detail = "x" } end
Hint.Show("Viele", many)
local manyRows = Hint.Rows()
expectTrue("alle Zeilen vorhanden", #manyRows >= #many and manyRows[#many]:IsShown())


-- LT-394: Dungeon je Charakter abschalten: Zonen-Hinweis ohne seine Zeilen, kein Hinweis nach der Annahme,
-- Rechtsklick auf den Eingang zeigt ihn weiter
local DEADMINES = 36
local zoneCount = #Hints.ZoneEntries(1453)
Hints.SetHidden(DEADMINES, true)
expectTrue("gemerkt je Charakter", addon.character.hiddenDungeonQuestHints[DEADMINES] == true)
expectTrue("Zonen-Hinweis ohne Todesminen", #Hints.ZoneEntries(1453) < zoneCount)
Hint.Hide()
wow.state.questLog = { { questID = 168, title = "Rote Seide", level = 20, objectives = {} } }
wow.fire("QUEST_ACCEPTED", 2, 168)
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expectTrue("Annahme: kein Hinweis", not Hint.IsShown())
expectTrue("Eingang: trotzdem", Hints.ShowInstance(DEADMINES) and Hint.IsShown())
Hints.SetHidden(DEADMINES, false)
expect("wieder an", addon.character.hiddenDungeonQuestHints[DEADMINES], nil)
expect("Zonen-Hinweis wieder vollständig", #Hints.ZoneEntries(1453), zoneCount)
