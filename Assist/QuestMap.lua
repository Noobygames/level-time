-- Gelernte Questorte auf der Weltkarte (Roadmap 350, Einstellung questMap, aus): für Quests im eigenen Log
-- abgabebereit = Fragezeichen am gelernten Abgabe-NPC, offen = gelbe Punkte, wo ihre Ziele bisher vorankamen
-- (Tracking/QuestNpcs.lua, accountweit gelernt). Tooltip mit Quest, NPC und Belohnung (XP, Geld; Roadmap 486). Zeichnen übernimmt
-- Lib/MapPins.lua. Rechtsklick auf einen Punkt fokussiert die Quest, Punkte anderer Quests werden blass (Assist/QuestFocus.lua).
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
ns.QuestFocus.OnChange(function() logRevision = logRevision + 1 end)

-- Questlog einmal je Stand lesen: PointsOn läuft je Karte, MapIDs dazu (C_QuestLog.GetInfo erzeugt je Eintrag eine
-- Tabelle); nicht verändern
local entries, entriesRevision
local function questEntries()
  if entriesRevision ~= logRevision then entries, entriesRevision = QuestLog.Entries(), logRevision end
  return entries
end

-- Punkte auf einer Karte: { x, y, size, texture oder color, title, questID, npc, ready }
function QuestMap.PointsOn(mapID)
  local points = {}
  for _, entry in ipairs(questEntries()) do
    local record = ns.QuestNpcs.Get(entry.questID)
    if record then
      local alpha = ns.QuestFocus.AlphaFor(entry.questID)
      local turnIn = record.turnIn
      if entry.ready and turnIn and turnIn.mapID == mapID then
        table.insert(points, { x = turnIn.x, y = turnIn.y, size = TURN_IN_SIZE, texture = TURN_IN_ICON,
          title = entry.title, questID = entry.questID, npc = turnIn.name, ready = true, alpha = alpha })
      elseif not entry.ready then
        for _, spot in ipairs(record.spots or {}) do
          if spot.mapID == mapID then
            table.insert(points, { x = spot.x, y = spot.y, size = SPOT_SIZE, color = SPOT_COLOR, title = entry.title,
              questID = entry.questID, alpha = alpha })
          end
        end
      end
    end
  end
  return points
end

-- Karten mit Punkten (für die Minimap, Assist/QuestMinimap.lua)
function QuestMap.MapIDs()
  local seen, list = {}, {}
  for _, entry in ipairs(questEntries()) do
    local record = ns.QuestNpcs.Get(entry.questID)
    local places = record and (entry.ready and { record.turnIn } or record.spots) or {}
    for _, place in ipairs(places) do
      if place.mapID and not seen[place.mapID] then
        seen[place.mapID] = true
        table.insert(list, place.mapID)
      end
    end
  end
  return list
end

-- Datenstand der Punkte (zwei Werte)
function QuestMap.Revision()
  return ns.QuestNpcs.Revision(), logRevision
end

local function showTooltip(pin, point)
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:AddLine(point.title or L.UNKNOWN_NAME, 1, 0.82, 0)
  if point.ready then
    GameTooltip:AddLine(string.format(L.QUEST_MAP_TURN_IN, point.npc or L.UNKNOWN_NAME), 1, 1, 1)
  else
    GameTooltip:AddLine(L.QUEST_MAP_OBJECTIVE, 1, 1, 1)
  end
  ns.QuestTooltip.AddRewardLine(GameTooltip, point.questID)
  GameTooltip:AddLine(string.format(L.QUEST_FOCUS_RIGHT_CLICK, ns.QuestFocus.ActionText(point.questID)), 0.6, 0.6, 0.6)
  GameTooltip:Show()
end
QuestMap.ShowTooltip = showTooltip

local layer = ns.MapPins.Create({
  name = ns.GlobalName("QuestMap"),
  label = "QuestMap",
  points = QuestMap.PointsOn,
  revision = QuestMap.Revision,
  onEnter = showTooltip,
  onClick = function(pin, point, button)
    if button ~= "RightButton" then return end
    ns.QuestFocus.Toggle(point.questID)
    showTooltip(pin, point)
  end,
})

ns.OnLogin(function() layer.SetEnabled(ns.db.questMap) end)
ns.RegisterApply(function(db) layer.SetEnabled(db.questMap) end)
