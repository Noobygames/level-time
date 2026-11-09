-- Gelernte Questorte auf der Weltkarte (Roadmap 350, Einstellung questMap, aus): für Quests im eigenen Log
-- abgabebereit = Fragezeichen am gelernten Abgabe-NPC, offen = gelbe Punkte, wo ihre Ziele bisher vorankamen
-- (Tracking/QuestNpcs.lua, accountweit gelernt). Tooltip mit Quest und NPC. Zeichnen übernimmt Lib/MapPins.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questMap = false,
  },
})
local L = ns.L
local QuestLog = ns.QuestLog

local QuestMap = {}
ns.QuestMap = QuestMap

local TURN_IN_ICON = "Interface\\GossipFrame\\ActiveQuestIcon"
local TURN_IN_SIZE = 16
local SPOT_SIZE = 6
local SPOT_COLOR = { 1, 0.82, 0, 0.9 }

local logRevision = 0
ns.RegisterEvent("QUEST_LOG_UPDATE", function() logRevision = logRevision + 1 end)

-- Punkte auf einer Karte: { x, y, size, texture oder color, title, npc, ready }
function QuestMap.PointsOn(mapID)
  local points = {}
  for _, entry in ipairs(QuestLog.Entries()) do
    local record = ns.QuestNpcs.Get(entry.questID)
    if record then
      local turnIn = record.turnIn
      if entry.ready and turnIn and turnIn.mapID == mapID then
        table.insert(points, { x = turnIn.x, y = turnIn.y, size = TURN_IN_SIZE, texture = TURN_IN_ICON,
          title = entry.title, npc = turnIn.name, ready = true })
      elseif not entry.ready then
        for _, spot in ipairs(record.spots or {}) do
          if spot.mapID == mapID then
            table.insert(points, { x = spot.x, y = spot.y, size = SPOT_SIZE, color = SPOT_COLOR, title = entry.title })
          end
        end
      end
    end
  end
  return points
end

local function showTooltip(pin, point)
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:AddLine(point.title or L.UNKNOWN_NAME, 1, 0.82, 0)
  if point.ready then
    GameTooltip:AddLine(string.format(L.QUEST_MAP_TURN_IN, point.npc or L.UNKNOWN_NAME), 1, 1, 1)
  else
    GameTooltip:AddLine(L.QUEST_MAP_OBJECTIVE, 1, 1, 1)
  end
  GameTooltip:Show()
end

local layer = ns.MapPins.Create({
  name = ns.GlobalName("QuestMap"),
  label = "QuestMap",
  points = QuestMap.PointsOn,
  revision = function() return ns.QuestNpcs.Revision(), logRevision end,
  onEnter = showTooltip,
})

ns.OnLogin(function() layer.SetEnabled(ns.db.questMap) end)
ns.RegisterApply(function(db) layer.SetEnabled(db.questMap) end)
