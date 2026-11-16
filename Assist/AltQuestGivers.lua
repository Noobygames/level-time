-- Twink-Questgeber auf der Weltkarte (LT-257, Einstellung altQuestGivers, aus): Ausrufezeichen an Questgebern, die ein
-- anderer eigener Charakter schon angenommen hat (Tracking/QuestNpcs.lua, accountweit gelernt; keine fremde Datenbank).
-- Gezeigt wird eine Quest nur, wenn sie
--   - dieser Charakter nicht erledigt hat: C_QuestLog.IsQuestFlaggedCompleted(questID) (QuestLogDocumentation.lua in
--     forever, classic_era und live),
--   - nicht in seinem Log steht (Lib/QuestLog.lua),
--   - zur Fraktion passt (beim Annehmen gelernte UnitFactionGroup; neutrale Quests zählen so für eine Fraktion),
--   - zum Level passt: Questlevel (beim Annehmen aus dem Questlog gelernt) zwischen Spielerlevel - LEVELS_BELOW und
--     Spielerlevel + LEVELS_ABOVE.
-- Zeichnen übernimmt Lib/MapPins.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    altQuestGivers = false,
  },
})
local L = ns.L
local QuestLog = ns.QuestLog

local AltQuestGivers = {}
ns.AltQuestGivers = AltQuestGivers

AltQuestGivers.LEVELS_BELOW = 5  -- tiefer = grau, kaum noch XP
AltQuestGivers.LEVELS_ABOVE = 2  -- höher = meist noch nicht annehmbar oder zu schwer
-- Ausrufezeichen wie Blizzards Gossip-Fenster (Blizzard_UIPanels_Game/Classic/GossipFrame.lua in classic_era,
-- Mainline/QuestFrameTemplates.xml in forever)
local ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local ICON_SIZE = 16

local stateRevision = 0
local function bump() stateRevision = stateRevision + 1 end
ns.RegisterEvent("QUEST_LOG_UPDATE", bump)
ns.OnLevelStarted(bump)

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function completed(questID)
  local isCompleted = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    and readable(C_QuestLog.IsQuestFlaggedCompleted(questID))
  return isCompleted == true
end

local function levelFits(questLevel, playerLevel)
  return type(questLevel) == "number" and questLevel >= playerLevel - AltQuestGivers.LEVELS_BELOW
    and questLevel <= playerLevel + AltQuestGivers.LEVELS_ABOVE
end

-- Annehmbar für diesen Charakter? inLog = { [questID] = true }
local function available(questID, record, inLog, playerLevel, faction)
  if not record.by or record.by == ns.characterKey then return false end
  if record.faction and record.faction ~= faction then return false end
  if not levelFits(record.level, playerLevel) then return false end
  return not inLog[questID] and not completed(questID)
end

-- Punkte auf einer Karte: { x, y, size, texture, title, npc, by }
function AltQuestGivers.PointsOn(mapID)
  local points = {}
  local inLog = {}
  for _, entry in ipairs(QuestLog.Entries()) do inLog[entry.questID] = true end
  local playerLevel = readable(UnitLevel("player")) or 1
  local faction = readable(UnitFactionGroup("player"))
  for questID, record in pairs(ns.QuestNpcs.All()) do
    local giver = record.giver
    if giver and giver.mapID == mapID and giver.x and available(questID, record, inLog, playerLevel, faction) then
      table.insert(points, { x = giver.x, y = giver.y, size = ICON_SIZE, texture = ICON, title = record.title,
        npc = giver.name, by = record.by })
    end
  end
  return points
end

local function showTooltip(pin, point)
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:AddLine(point.title or L.UNKNOWN_NAME, 1, 0.82, 0)
  if point.npc then GameTooltip:AddLine(point.npc, 1, 1, 1) end
  -- Charakter-Schlüssel "Name-Realm": Namen enthalten keinen Bindestrich
  GameTooltip:AddLine(string.format(L.ALT_QUEST_KNOWN_BY, point.by:match("^[^-]+")), 0.7, 0.7, 0.7)
  GameTooltip:Show()
end

local layer = ns.MapPins.Create({
  name = ns.GlobalName("AltQuestGivers"),
  label = "AltQuestGivers",
  points = AltQuestGivers.PointsOn,
  revision = function() return ns.QuestNpcs.Revision(), stateRevision end,
  onEnter = showTooltip,
})

ns.OnLogin(function() layer.SetEnabled(ns.db.altQuestGivers) end)
ns.RegisterApply(function(db) layer.SetEnabled(db.altQuestGivers) end)
