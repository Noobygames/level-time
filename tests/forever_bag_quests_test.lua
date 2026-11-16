-- Taschen-Hinweise (WoW Forever): Geber von Taschen-Quests an Plakette, Karte und Tooltip, Gegner mit Taschen-Beute.
-- Quest 58 (Nachtwache, Allianz, ab 18, Vorquest 57) gibt Geber 264 (Sturmwind-Kommandantin); Fedfennel (472) lässt
-- die Gnoll-Haut-Tasche fallen.
local L = addon.L
local Bags = addon.BagQuests
local Marks = addon.BagQuestMarks

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end

local plates = { nameplate1 = CreateFrame("Frame") }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then created[parent] = frame end
  return frame
end

local GIVER_GUID = "Creature-0-1-0-1431-264-0001"
local MOB_GUID = "Creature-0-1-0-12-472-0001"
wow.state.faction = "Alliance"
wow.login({ level = 17 })
wow.fire("QUEST_LOG_UPDATE")

expectTrue("verfügbar", Bags.IsAvailable())
expect("Standard an", addon.db.bagHints, true)

-- Level, Vorquest, Fraktion, Log, abgegeben
expectTrue("zu niedrig", not Bags.CanTake(58))
wow.state.level = 18
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Vorquest fehlt", not Bags.CanTake(58))
completed[57] = true
wow.fire("QUEST_LOG_UPDATE")
expectTrue("annehmbar", Bags.CanTake(58))
expect("Geber 264 bietet 58", Bags.NpcOffers(264)[1].item, 1729)
wow.state.faction = "Horde"
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Allianzquest nicht für die Horde", not Bags.CanTake(58))
wow.state.faction = "Alliance"
wow.fire("QUEST_LOG_UPDATE")
expectTrue("wieder annehmbar", Bags.CanTake(58))

-- Plakette
wow.state.units.nameplate1 = { name = "Kommandantin", guid = GIVER_GUID }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local mark = created[plates.nameplate1]
expectTrue("Plakette markiert", mark ~= nil and mark:IsShown())

-- Tooltip: Quest-Geber und Gegner mit Beute
local lines = {}
local tooltip = { AddLine = function(_, text) table.insert(lines, text) end }
wow.state.units.target = { name = "Kommandantin", guid = GIVER_GUID }
Marks.AddUnitLines(tooltip, "target")
expect("Tooltipzeile Quest", lines[1], string.format(L.BAG_HINT_LINE, "Gunnysack of the Night Watch", 10))
lines = {}
wow.state.units.target = { name = "Fedfennel", guid = MOB_GUID }
Marks.AddUnitLines(tooltip, "target")
expect("Tooltipzeile Gegner", lines[1], string.format(L.BAG_HINT_LINE, "Gnoll Hide Sack", 8))

-- Karte: Geber auf der Zonenkarte (1431 Dämmerwald) und Objekt-Geber (Quest 140 in Westfall 1436 erst nach Vorquest)
expect("Kartenpunkt", #Bags.OffersOnMap(1431), 1)
expect("Objekt-Geber noch nicht", #Bags.OffersOnMap(1439), 0)
wow.state.level = 10
completed[139] = true
wow.fire("QUEST_LOG_UPDATE")
expect("Objekt-Geber auf der Karte", #Bags.OffersOnMap(1436), 2)

-- Angenommen: Markierung verschwindet nach der gedrosselten Prüfung
wow.state.level = 18
wow.fire("QUEST_LOG_UPDATE")
wow.update(1.1)
expectTrue("Plakette wieder markiert", mark:IsShown())
wow.state.questLog = { { questID = 58, title = "Die Nachtwache", objectives = {} } }
wow.fire("QUEST_LOG_UPDATE")
wow.update(1.1)
expectTrue("Plakette ohne Angebot", not mark:IsShown())
expect("im Log: kein Angebot", #Bags.NpcOffers(264), 0)

-- Aus: keine Zeile, keine Markierung
wow.state.questLog = {}
wow.fire("QUEST_LOG_UPDATE")
addon.Set("bagHints", false)
lines = {}
Marks.AddUnitLines(tooltip, "target")
expect("aus: keine Zeile", #lines, 0)
