-- Dungeon-Eingänge auf der Weltkarte (Einstellung dungeonEntrances, aus; nur wo ns.InstanceGuide existiert, also
-- WoW Forever): ein Dungeon-Symbol je Eingang auf der Zonenkarte, Instanzen mit demselben Eingang teilen sich eins.
-- Tooltip je Instanz: Name, Spieler/Reset/Level (InstanceInfo.Describe) und die offenen Dungeonquests des Charakters
-- (passende Fraktion und Klasse, abgegebene fallen weg) mit Stand: im Log, ab Level X oder wo sie beginnt.
-- Zeichnen übernimmt Lib/MapPins.lua, Daten aus Assist/InstanceData/forever_guide.lua.
-- shortcut: nur auf der Zonenkarte, nicht auf Kontinentkarten; bei Bedarf über C_Map-Weltpositionen umrechnen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonEntrances = false,
  },
})
local L = ns.L

local DungeonEntrances = {}
ns.DungeonEntrances = DungeonEntrances

local ICON_ATLAS = "Dungeon"
local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Rune_01"  -- Rückfall, falls der Client den Atlas nicht kennt
local ICON_SIZE = 18
local MAX_QUEST_LINES = 12
local COORD_SCALE = 100
local FACTION_CODES = { Alliance = "A", Horde = "H" }
local TITLE_COLOR = { 1, 0.82, 0 }
local TEXT_COLOR = { 1, 1, 1 }
local IN_LOG_COLOR = { 0.25, 1, 0.25 }
local LOW_LEVEL_COLOR = { 1, 0.3, 0.3 }
local HINT_COLOR = { 0.7, 0.7, 0.7 }

-- Spalten in ns.InstanceGuide (siehe Kopf von forever_guide.lua)
local ENTRANCE_MAP, ENTRANCE_X, ENTRANCE_Y = 1, 2, 3
local QUEST_ID, QUEST_LEVEL, QUEST_MIN_LEVEL, QUEST_FACTION, QUEST_CLASS, QUEST_NAME = 1, 2, 3, 4, 5, 6
local QUEST_MAP, QUEST_X, QUEST_Y = 7, 8, 9

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

function DungeonEntrances.IsAvailable()
  return ns.InstanceGuide ~= nil
end

-- Punkte auf einer Karte: { x, y, size, atlas, texture, mapIDs = { Instanz-Karten-ID, ... } }
function DungeonEntrances.PointsOn(uiMapID)
  local points, byPlace = {}, {}
  if not ns.InstanceGuide then return points end
  for mapID, entrances in pairs(ns.InstanceGuide.entrances) do
    for _, entrance in ipairs(entrances) do
      if entrance[ENTRANCE_MAP] == uiMapID then
        local place = entrance[ENTRANCE_X] .. ":" .. entrance[ENTRANCE_Y]
        local point = byPlace[place]
        if not point then
          point = { x = entrance[ENTRANCE_X], y = entrance[ENTRANCE_Y], size = ICON_SIZE, atlas = ICON_ATLAS,
            texture = ICON_TEXTURE, mapIDs = {} }
          byPlace[place] = point
          table.insert(points, point)
        end
        table.insert(point.mapIDs, mapID)
      end
    end
  end
  for _, point in ipairs(points) do table.sort(point.mapIDs) end
  return points
end

local function questTitle(quest)
  local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and readable(C_QuestLog.GetTitleForQuestID(quest[QUEST_ID]))
  return (title and title ~= "") and title or quest[QUEST_NAME]
end

-- Offene Dungeonquests des Charakters, nach Questlevel:
-- { { questID, title, level, minLevel, inLog, uiMapID, x, y, pre, preAny, excl }, ... } (Ort fehlt, wenn unbekannt;
-- pre/preAny/excl = Vorquests alle/eine davon und sich ausschließende Quests aus dem Führer, ungeprüft)
function DungeonEntrances.OpenQuests(mapID)
  local list = {}
  local quests = ns.InstanceGuide and ns.InstanceGuide.quests[mapID]
  if not quests then return list end
  local faction = FACTION_CODES[readable(UnitFactionGroup("player"))]
  local _, class = UnitClass("player")
  for _, quest in ipairs(quests) do
    local fits = (not quest[QUEST_FACTION] or quest[QUEST_FACTION] == faction)
      and (not quest[QUEST_CLASS] or quest[QUEST_CLASS] == class)
    if fits and not ns.QuestItemTooltip.IsQuestDone(quest[QUEST_ID]) then
      table.insert(list, { questID = quest[QUEST_ID], title = questTitle(quest), level = quest[QUEST_LEVEL],
        minLevel = quest[QUEST_MIN_LEVEL], inLog = ns.QuestLog.Find(quest[QUEST_ID]) ~= nil,
        uiMapID = quest[QUEST_MAP], x = quest[QUEST_X], y = quest[QUEST_Y],
        pre = quest.pre, preAny = quest.preAny, excl = quest.excl })
    end
  end
  return list
end

-- Wo eine Quest aus OpenQuests beginnt: "Zone (74, 36)" oder nil
function DungeonEntrances.StartText(quest)
  if not quest.uiMapID then return nil end
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(quest.uiMapID)
  local zone = info and readable(info.name)
  if not zone then return nil end
  return string.format("%s (%d, %d)", zone, math.floor(quest.x * COORD_SCALE + 0.5), math.floor(quest.y * COORD_SCALE + 0.5))
end

-- Rechte Spalte und Farbe einer Questzeile
local function questStatus(quest, playerLevel)
  if quest.inLog then return L.DUNGEON_QUEST_IN_LOG, IN_LOG_COLOR end
  if playerLevel < quest.minLevel then return string.format(L.DUNGEON_QUEST_MIN_LEVEL, quest.minLevel), LOW_LEVEL_COLOR end
  return DungeonEntrances.StartText(quest) or "", TEXT_COLOR
end

local function addQuestLines(tooltip, mapID)
  local quests = DungeonEntrances.OpenQuests(mapID)
  if #quests == 0 then return end
  tooltip:AddLine(string.format(L.DUNGEON_QUESTS_OPEN, #quests), unpack(TITLE_COLOR))
  local playerLevel = UnitLevel("player") or 0
  for index, quest in ipairs(quests) do
    if index > MAX_QUEST_LINES then
      tooltip:AddLine(string.format(L.DUNGEON_QUESTS_MORE, #quests - MAX_QUEST_LINES), unpack(HINT_COLOR))
      break
    end
    local status, color = questStatus(quest, playerLevel)
    tooltip:AddDoubleLine(string.format("[%d] %s", quest.level, quest.title), status,
      TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], color[1], color[2], color[3])
  end
end

local function showTooltip(pin, point)
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  for index, mapID in ipairs(point.mapIDs) do
    if index > 1 then GameTooltip:AddLine(" ") end
    GameTooltip:AddLine(ns.InstanceInfo.MapName(mapID), unpack(TITLE_COLOR))
    local description = ns.InstanceInfo.Describe(mapID)
    if description then GameTooltip:AddLine(description, unpack(TEXT_COLOR)) end
    addQuestLines(GameTooltip, mapID)
  end
  GameTooltip:Show()
end

-- Eingänge ändern sich nicht; der Quest-Stand im Tooltip wird beim Überfahren gelesen
local layer = ns.MapPins.Create({
  name = ns.GlobalName("DungeonEntrances"),
  label = "DungeonEntrances",
  points = DungeonEntrances.PointsOn,
  revision = function() return 0 end,
  onEnter = showTooltip,
})

local function apply(db) layer.SetEnabled(db.dungeonEntrances and DungeonEntrances.IsAvailable()) end
ns.OnLogin(function() apply(ns.db) end)
ns.RegisterApply(apply)
