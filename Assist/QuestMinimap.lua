-- Gelernte Questorte auf der Minimap (LT-258; Einstellung questMinimap unter questMap, an): dieselben Punkte wie auf der
-- Weltkarte (Abgabe-NPC abgabebereiter Quests, Zielorte offener Quests; Assist/QuestMap.lua) nach Entfernung zum Spieler,
-- außerhalb des Sichtradius blass am Rand. Platzierung, Rand und Takt: Lib/MinimapPins.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questMinimap = true,
  },
})
local QuestMap = ns.QuestMap
local MinimapPins = ns.MinimapPins

local DEFAULT_SIZE = 8

local function newPin(parent, size)
  local pin = CreateFrame("Frame", nil, parent)
  pin:SetSize(size, size)
  pin.texture = pin:CreateTexture(nil, "OVERLAY")
  pin.texture:SetAllPoints(pin)
  pin:SetScript("OnEnter", function(self) QuestMap.ShowTooltip(self, self.point) end)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return pin
end

MinimapPins.Create({
  size = DEFAULT_SIZE,
  enabled = function(db) return db.questMap and db.questMinimap end,
  edge = function() return true end,
  key = function()
    local npcRevision, logRevision = QuestMap.Revision()
    return tostring(npcRevision) .. ":" .. tostring(logRevision)
  end,
  candidates = function(instanceID)
    return MinimapPins.Collect(instanceID, QuestMap.MapIDs(), QuestMap.PointsOn)
  end,
  newPin = newPin,
  show = function(pin, candidate)
    pin.point = candidate
    ns.MapPins.Paint(pin.texture, candidate)
    pin:Show()
  end,
})
