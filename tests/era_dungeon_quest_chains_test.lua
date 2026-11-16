-- Vorquest-Ketten zu Dungeonquests (Classic Era, DungeonDB): Todesminen-Quest 166 am Ende einer Kette aus 7 Schritten,
-- 65 (Schritt 1, NPC 234 in Westfall) und 132 (Schritt 2, braucht 65). Geber-Zeile, Symbol, Kurzname mit Schritt im
-- Questlog und Tooltipzeile "Führt zu ...".
local L = addon.L
local DQ = addon.DungeonQuests
local Givers = addon.DungeonQuestGivers
local Tags = addon.DungeonQuestTags

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
function GetRealZoneText(mapID) return mapID == 36 and "Die Todesminen" or ("Instanz " .. tostring(mapID)) end
wow.state.questTitles[65] = "Der Weg nach Westfall"

local plates = { nameplate1 = CreateFrame("Frame") }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then created[parent] = frame end
  return frame
end

local GIVER_GUID = "Creature-0-1-0-0-234-0001"
wow.state.class = "WARRIOR"
wow.login({ level = 14 })
wow.fire("QUEST_LOG_UPDATE")

local mapID, target, step, total = DQ.Chain(65)
expect("Kette: Instanz", mapID, 36)
expect("Kette: Ziel", target, 166)
expect("Kette: Schritt", step .. "/" .. total, "1/7")

-- Geber: Schritt 1 angeboten, Schritt 2 noch nicht (Vorquest fehlt)
local offer = DQ.Offer(65)
expectTrue("Schritt 1 angeboten", offer ~= nil and offer.step == 1 and offer.total == 7)
expect("Schritt 2 noch nicht", DQ.Offer(132), nil)
local lines = {}
local tooltip = { AddLine = function(_, text) table.insert(lines, text) end }
wow.state.units.mouseover = { name = "Gryan Starkmantel", guid = GIVER_GUID }
Givers.AddUnitLines(tooltip, "mouseover")
expect("Geber-Zeile mit Schritt", lines[1],
  string.format(L.DUNGEON_QUEST_CHAIN_OFFER, "Der Weg nach Westfall", "Die Todesminen", 1, 7))

-- Plakette: auch Vorquest-Geber bekommen das Symbol (grau)
wow.state.units.nameplate1 = { name = "Gryan Starkmantel", guid = GIVER_GUID }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local mark = created[plates.nameplate1]
expectTrue("Plakette markiert", mark ~= nil and mark:IsShown())

-- Schritt 1 abgegeben: Schritt 2 wird annehmbar
completed[65] = true
wow.fire("QUEST_LOG_UPDATE")
local second = DQ.Offer(132)
expectTrue("Schritt 2 annehmbar", second ~= nil and second.step == 2)

-- Questlog/Tooltip: Kurzname mit Schritt, Zeile "Führt zu"
expectTrue("Tag mit Schritt", Tags.Tag(132):find("[DT 2/7]", 1, true) ~= nil)
expect("Tooltipzeile", Tags.TooltipLine(132), string.format(L.DUNGEON_QUEST_CHAIN_LINE, "Die Todesminen", 2, 7))
expect("Dungeonquest selbst ohne Schritt", Tags.TooltipLine(166), string.format(L.DUNGEON_QUEST_LINE, "Die Todesminen"))

-- Kettenschritt mehrerer Instanzen: Schritt 1 von 2609 führt nach 36 und über questChainAlt nach 90 (Schurkenquest)
wow.state.class = "ROGUE"
local chains = DQ.Chains(2360)
expect("Mehrere Ketten", #chains, 2)
expect("Zweite Kette: Instanz", chains[2][1], 90)
local function hasQuest(instanceMap)
  for _, entry in ipairs(DQ.InstanceQuests(instanceMap)) do
    if entry.questID == 2360 then return entry end
  end
end
expectTrue("Schritt in Instanz 36 gelistet", hasQuest(36) ~= nil)
expectTrue("Schritt in Instanz 90 gelistet", hasQuest(90) ~= nil)
expect("Tooltipzeile nennt beide Instanzen", select(2, Tags.TooltipLine(2360):gsub("\n", "")), 1)
