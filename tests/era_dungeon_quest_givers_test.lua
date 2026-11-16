-- Dungeonquest-Geber (Classic Era, DungeonDB): Symbol an Plakette und Zielfenster, Tooltipzeile, Kartenpunkt.
-- Todesminen: Wilder Klippenschmied 656 bietet 167/168 (Allianz, ab 15/14), 214 braucht Vorquest 155,
-- 1740 ist nur für Hexenmeister (Klassenmaske 256).
local L = addon.L
local DQ = addon.DungeonQuests
local Givers = addon.DungeonQuestGivers

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
function GetRealZoneText(mapID) return mapID == 36 and "Die Todesminen" or ("Instanz " .. tostring(mapID)) end
wow.state.questTitles[167] = "Die Bruderschaft"
wow.state.questTitles[168] = "Gesammelte Erinnerungen"

local plates = { nameplate1 = CreateFrame("Frame") }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
TargetFrame = CreateFrame("Frame")
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then created[parent] = frame end
  return frame
end

local GIVER_GUID = "Creature-0-1-0-36-656-0001"
wow.state.class = "WARRIOR"
wow.login({ level = 13 })
wow.fire("QUEST_LOG_UPDATE")

expectTrue("Era: verfügbar", Givers.IsAvailable())
expect("Standard an", addon.db.dungeonQuestGivers, true)
expect("Instanz einer Quest", DQ.Instance(167), 36)
expect("Kurzname aus dem Namen", DQ.ShortName(36), "DT")

-- Level 13: noch nichts annehmbar
expect("zu niedrig", #DQ.GiverOffers("npc", 656), 0)
wow.state.level = 14
wow.fire("QUEST_LOG_UPDATE")
local offers = DQ.GiverOffers("npc", 656)
expect("ab 14 nur 168", #offers, 1)
expect("168", offers[1].questID, 168)
wow.state.level = 15
wow.fire("QUEST_LOG_UPDATE")
expect("ab 15 beide", #DQ.GiverOffers("npc", 656), 2)

-- Vorquest, Klasse, Fraktion, Log, abgegeben
expectTrue("Vorquest fehlt", not DQ.CanTake(214))
completed[155] = true
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Vorquest erfüllt", DQ.CanTake(214))
expectTrue("Klassenmaske: kein Hexenmeister", not DQ.CanTake(1740))
wow.state.level = 20
wow.state.class = "WARLOCK"
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Hexenmeister", DQ.CanTake(1740))
wow.state.faction = "Horde"
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Allianzquest nicht für die Horde", not DQ.CanTake(167))
wow.state.faction = "Alliance"
wow.state.questLog = { { questID = 167, title = "Die Bruderschaft", objectives = {} } }
wow.fire("QUEST_LOG_UPDATE")
expectTrue("im Log", not DQ.CanTake(167))
wow.state.questLog = {}
completed[168] = true
wow.fire("QUEST_LOG_UPDATE")
expectTrue("abgegeben", not DQ.CanTake(168))
expect("bleibt 167", DQ.GiverOffers("npc", 656)[1].questID, 167)

-- Plakette: Symbol über dem Geber, keins bei anderen NPCs
wow.state.units.nameplate1 = { name = "Wilder Klippenschmied", guid = GIVER_GUID }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local mark = created[plates.nameplate1]
expectTrue("Plakette markiert", mark ~= nil and mark:IsShown())

-- Ziel: Symbol am Zielfenster
wow.state.units.target = { name = "Wilder Klippenschmied", guid = GIVER_GUID }
wow.fire("PLAYER_TARGET_CHANGED")
local targetMark = created[TargetFrame]
expectTrue("Zielfenster markiert", targetMark ~= nil and targetMark:IsShown())

-- Tooltip: eine Zeile je Angebot mit Instanzname
local lines = {}
local tooltip = { AddLine = function(_, text) table.insert(lines, text) end }
Givers.AddUnitLines(tooltip, "target")
expect("Tooltipzeile", lines[1], string.format(L.DUNGEON_QUEST_OFFER, "Die Bruderschaft", "Die Todesminen"))

-- Karte: Geber am Ort aus der DungeonDB (Quest 167: uiMapID 1453)
local points = DQ.OffersOnMap(1453)
local found = false
for _, point in ipairs(points) do
  for _, offer in ipairs(point.offers) do if offer.questID == 167 then found = true end end
end
expectTrue("Kartenpunkt", found)

-- Angenommen: Markierung verschwindet nach der gedrosselten Prüfung
wow.state.questLog = { { questID = 167, title = "Die Bruderschaft", objectives = {} } }
wow.fire("QUEST_LOG_UPDATE")
wow.update(1.1)
expectTrue("Plakette ohne Angebot", not mark:IsShown())
expectTrue("Zielfenster ohne Angebot", not targetMark:IsShown())

-- Aus: keine Zeile
wow.state.questLog = {}
wow.fire("QUEST_LOG_UPDATE")
addon.Set("dungeonQuestGivers", false)
lines = {}
Givers.AddUnitLines(tooltip, "target")
expect("aus: keine Zeile", #lines, 0)
expectTrue("aus: Plakette leer", not mark:IsShown())
