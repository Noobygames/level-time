-- Taschen-Hinweise anzeigen (Einstellung bagHints im Reiter "Komfort" > Quests, an; nur mit ns.BagData, also Classic Era
-- und Forever): Geber von Quests mit Taschen-Belohnung (Assist/BagQuests.lua), die der Charakter jetzt annehmen kann,
-- bekommen ein Taschen-Symbol über der Namensplakette, auf der Zonenkarte und auf der Minimap (Objekte haben keine
-- Plakette) und die Tooltipzeile "Tasche: Name (N Plätze)". Gegner, die eine Tasche fallen lassen, bekommen dieselbe
-- Zeile im Einheiten-Tooltip (angehängt von Assist/Tooltip.lua). Zeichnen übernehmen Lib/MapPins.lua und
-- Lib/MinimapPins.lua. NPC-ID aus UnitGUID (in Forever-Instanzen geheim: dann keine Markierung).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    bagHints = true,
  },
})
local BagQuests = ns.BagQuests

local BagQuestMarks = {}
ns.BagQuestMarks = BagQuestMarks

local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Bag_08"
local PLATE_ICON_SIZE = 18
local PLATE_GAP = 2
local MAP_ICON_SIZE = 16
local MINIMAP_ICON_SIZE = 14
local CHECK_SECONDS = 1
local LINE_COLOR = "info"  -- Theme-Farbe der Tooltipzeilen

local marks = {}  -- [Namensplakette] = Symbol-Frame
local units = {}  -- sichtbare Namensplaketten: [Einheit] = Plakette
local shownRevision

function BagQuestMarks.IsAvailable()
  return BagQuests.IsAvailable()
end

local function isEnabled()
  return ns.db and ns.db.bagHints and BagQuestMarks.IsAvailable()
end

local function addOfferLines(tooltip, offers)
  local r, g, b = ns.Theme.RGB(LINE_COLOR)
  for _, offer in ipairs(offers) do tooltip:AddLine(BagQuests.Line(offer), r, g, b) end
end

-- Tooltipzeilen für eine Einheit: annehmbare Taschenquests und Taschen-Beute (Aufruf aus Assist/Tooltip.lua)
function BagQuestMarks.AddUnitLines(tooltip, unit)
  if not isEnabled() then return end
  addOfferLines(tooltip, BagQuests.UnitOffers(unit))
  local bag = BagQuests.UnitMobBag(unit)
  if bag then addOfferLines(tooltip, { bag }) end
end

local function newMark(parent, size)
  local mark = CreateFrame("Frame", nil, parent)
  mark:SetSize(size, size)
  mark.icon = mark:CreateTexture(nil, "OVERLAY")
  mark.icon:SetAllPoints()
  mark.icon:SetTexture(ICON_TEXTURE)
  return mark
end

local function plateOf(unit)
  local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
  if not plate or (plate.IsForbidden and plate:IsForbidden()) then return nil end
  return plate
end

local function updatePlate(unit)
  local plate = units[unit]
  if not plate then return end
  if isEnabled() and #BagQuests.UnitOffers(unit) > 0 then
    if not marks[plate] then
      marks[plate] = newMark(plate, PLATE_ICON_SIZE)
      marks[plate]:SetPoint("BOTTOM", plate, "TOP", 0, PLATE_GAP)
    end
    marks[plate]:Show()
  elseif marks[plate] then
    marks[plate]:Hide()
  end
end

local function refreshAll()
  for unit in pairs(units) do updatePlate(unit) end
end

ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if not unit or ns.IsSecret(unit) then return end
  units[unit] = plateOf(unit)
  updatePlate(unit)
end)

ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  if not unit or ns.IsSecret(unit) then return end
  local plate = units[unit]
  units[unit] = nil
  if plate and marks[plate] then marks[plate]:Hide() end
end)

ns.Every(CHECK_SECONDS, function()
  if shownRevision == BagQuests.Revision() then return end
  shownRevision = BagQuests.Revision()
  refreshAll()
end, function(db) return db.bagHints end)

-- Weltkarte
local function mapPoints(uiMapID)
  local points = {}
  for _, place in ipairs(BagQuests.OffersOnMap(uiMapID)) do
    table.insert(points, { x = place.x, y = place.y, size = MAP_ICON_SIZE, texture = ICON_TEXTURE, offers = place.offers })
  end
  return points
end

local layer = ns.MapPins.Create({
  name = ns.GlobalName("BagQuestGivers"),
  label = "BagQuestGivers",
  points = mapPoints,
  revision = BagQuests.Revision,
  onEnter = function(pin, point)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    addOfferLines(GameTooltip, point.offers)
    GameTooltip:Show()
  end,
  mapIDs = BagQuests.GiverMapIDs,
})

-- Minimap
local minimap = ns.MinimapPins.Create({
  size = MINIMAP_ICON_SIZE,
  enabled = function(db) return db.bagHints and BagQuestMarks.IsAvailable() end,
  edge = function() return true end,
  key = BagQuests.Revision,
  candidates = function(instanceID)
    return ns.MinimapPins.Collect(instanceID, BagQuests.GiverMapIDs(), BagQuests.OffersOnMap)
  end,
  newPin = function(parent, size)
    local pin = newMark(parent, size)
    pin:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      addOfferLines(GameTooltip, self.offers)
      GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
  end,
  show = function(pin, candidate)
    pin.offers = candidate.offers
    pin:Show()
  end,
})
BagQuestMarks.UpdateMinimap = minimap.Update

local function apply()
  layer.SetEnabled(isEnabled())
  shownRevision = nil
  refreshAll()
end
ns.OnLogin(apply)
ns.RegisterApply(apply)
