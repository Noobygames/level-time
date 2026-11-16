-- Dungeon-Eingänge auf der Weltkarte (Einstellung dungeonEntrances, aus; nur wo ns.InstanceGuide existiert, also
-- WoW Forever): ein Dungeon-Symbol je Eingang auf der Zonenkarte, Instanzen mit demselben Eingang teilen sich eins.
-- Tooltip je Instanz: Name, Spieler/Reset/Level (InstanceInfo.Describe) und die offenen Dungeonquests des Charakters
-- (DungeonQuests.OwnQuests: passende Fraktion und Klasse, abgegebene fallen weg) mit Stand: im Log, ab Level X oder
-- wo sie beginnt; darunter Schlüssel- und Einstimmungsreihen (Assist/Attunements.lua) und die bekannte Boss-Beute ab
-- rar (Assist/BossLoot.lua).
-- Zeichnen übernimmt Lib/MapPins.lua, Eingänge aus Assist/InstanceData/forever_guide.lua.
-- Zeichnet ein Kartenaddon (OpenMap, Leatrix Maps) selbst Dungeon-Eingänge, bleiben unsere aus (Lib/MapCompat.lua).
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
local TITLE_COLOR = ns.Theme.COLORS.gold
local TEXT_COLOR = ns.Theme.COLORS.text
local IN_LOG_COLOR = ns.Theme.COLORS.success
local LOW_LEVEL_COLOR = ns.Theme.COLORS.bad

-- Spalten in ns.InstanceGuide.entrances (siehe Kopf von forever_guide.lua)
local ENTRANCE_MAP, ENTRANCE_X, ENTRANCE_Y = 1, 2, 3

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

-- Wo eine Quest aus DungeonQuests.OwnQuests beginnt: "Zone (74, 36)" oder nil
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
  local quests = ns.DungeonQuests.OwnQuests(mapID)
  if #quests == 0 then return end
  tooltip:AddLine(string.format(L.DUNGEON_QUESTS_OPEN, #quests), unpack(TITLE_COLOR))
  local playerLevel = UnitLevel("player") or 0
  for index, quest in ipairs(quests) do
    if index > MAX_QUEST_LINES then
      tooltip:AddLine(string.format(L.DUNGEON_QUESTS_MORE, #quests - MAX_QUEST_LINES), ns.Theme.RGB("muted"))
      break
    end
    local status, color = questStatus(quest, playerLevel)
    tooltip:AddDoubleLine(string.format("[%d] %s", quest.level, quest.title), status,
      TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], color[1], color[2], color[3])
  end
  tooltip:AddLine(L.DUNGEON_ENTRANCE_RIGHT_CLICK, ns.Theme.RGB("muted"))
end

local showTooltip
showTooltip = function(pin, point)
  -- Nachgeladene Beute-Items: Tooltip neu aufbauen, solange er noch zu diesem Symbol gehört
  local function reload()
    if GameTooltip:IsOwned(pin) then showTooltip(pin, point) end
  end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  for index, mapID in ipairs(point.mapIDs) do
    if index > 1 then GameTooltip:AddLine(" ") end
    GameTooltip:AddLine(ns.InstanceInfo.MapName(mapID), unpack(TITLE_COLOR))
    local description = ns.InstanceInfo.Describe(mapID)
    if description then GameTooltip:AddLine(description, unpack(TEXT_COLOR)) end
    addQuestLines(GameTooltip, mapID)
    ns.Attunements.AddLines(GameTooltip, mapID)
    ns.BossLoot.AddLines(GameTooltip, ns.BossLoot.ForInstance(mapID), reload)
  end
  GameTooltip:Show()
end

-- Zonenkarten mit Eingängen (einmal aufgebaut)
local entranceMapIDs
local function mapIDs()
  if entranceMapIDs then return entranceMapIDs end
  local seen = {}
  entranceMapIDs = {}
  for _, entrances in pairs(ns.InstanceGuide and ns.InstanceGuide.entrances or {}) do
    for _, entrance in ipairs(entrances) do
      local uiMapID = entrance[ENTRANCE_MAP]
      if not seen[uiMapID] then
        seen[uiMapID] = true
        table.insert(entranceMapIDs, uiMapID)
      end
    end
  end
  return entranceMapIDs
end

local NO_POINTS = {}
local function mapPoints(uiMapID)
  if ns.MapCompat.ShowsDungeonEntrances() then return NO_POINTS end
  return DungeonEntrances.PointsOn(uiMapID)
end

-- Eingänge ändern sich nicht; der Quest-Stand im Tooltip wird beim Überfahren gelesen. Datenstand = ob ein Kartenaddon
-- die Eingänge gerade selbst zeigt (OpenMap wechselt zwischen eigener und Blizzards Karte)
local layer = ns.MapPins.Create({
  name = ns.GlobalName("DungeonEntrances"),
  label = "DungeonEntrances",
  points = mapPoints,
  revision = function() return ns.MapCompat.ShowsDungeonEntrances() end,
  onEnter = showTooltip,
  onClick = function(_, point, button)  -- Rechtsklick: offene Dungeonquests der Instanz
    if button == "RightButton" and ns.DungeonQuests.IsAvailable() then ns.DungeonQuestHints.ShowInstance(point.mapIDs[1]) end
  end,
  mapIDs = mapIDs,
})

local function apply(db) layer.SetEnabled(db.dungeonEntrances and DungeonEntrances.IsAvailable()) end
ns.OnLogin(function() apply(ns.db) end)
ns.RegisterApply(apply)
