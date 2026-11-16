-- Dungeonquest-Geber markieren (Einstellung dungeonQuestGivers im Reiter "Komfort", an; nur mit ns.DungeonDB, also
-- Classic Era und Forever): NPCs, die dem Charakter jetzt eine Dungeonquest anbieten (DungeonQuests.UnitOffers), bekommen
-- ein Dungeon-Symbol über der Namensplakette, am Zielfenster und auf der Minimap (Assist/DungeonQuestMinimap.lua) sowie je Angebot eine
-- Tooltipzeile
-- ("Dungeonquest: Titel (Instanz)", angehängt von Assist/Tooltip.lua). Schritte einer Vorquest-Kette zählen mit
-- ("Vorquest: Titel – führt zu Instanz (Schritt 2/7)"); bietet ein Geber nur solche an, ist das Symbol grau. Objekte haben weder Einheit
-- noch Plakette; sie
-- und NPCs stehen mit ihrem Ort aus der DungeonDB als Punkt auf der Zonenkarte (Lib/MapPins.lua).
-- NPC-ID aus UnitGUID (in Forever-Instanzen geheim: dann keine Markierung, Geber stehen fast alle draußen).
-- Neu bewertet wird bei neuen Plaketten, Zielwechsel und wenn sich DungeonQuests.Revision ändert (Questlog, Abgabe,
-- Level; gedrosselt geprüft).
-- shortcut: Symbol am Zielfenster fest oben links angesetzt; bei Unitframe-Addons ggf. eigene Verankerung.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestGivers = true,
  },
})
local L = ns.L
local DungeonQuests = ns.DungeonQuests

local DungeonQuestGivers = {}
ns.DungeonQuestGivers = DungeonQuestGivers

local ICON_ATLAS = "Dungeon"
local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Rune_01"  -- Rückfall, falls der Client den Atlas nicht kennt
local PLATE_ICON_SIZE = 20
local PLATE_GAP = 2
local TARGET_ICON_SIZE = 22
local MAP_ICON_SIZE = 16
local CHECK_SECONDS = 1
local MAX_TOOLTIP_LINES = 6
local OFFER_COLOR = "info"  -- Theme-Farbe der Tooltipzeilen

local marks = {}  -- [Namensplakette] = Symbol-Frame
local units = {}  -- sichtbare Namensplaketten: [Einheit] = Plakette
local targetMark
local shownRevision

function DungeonQuestGivers.IsAvailable()
  return DungeonQuests.IsAvailable()
end

local function isEnabled()
  return ns.db and ns.db.dungeonQuestGivers and DungeonQuestGivers.IsAvailable()
end

local function setIcon(texture)
  if ns.MapPins.KnownAtlas(ICON_ATLAS) then texture:SetAtlas(ICON_ATLAS) else texture:SetTexture(ICON_TEXTURE) end
end

-- Dungeon-Symbol als eigener Rahmen (auch für die Minimap, Assist/DungeonQuestMinimap.lua)
function DungeonQuestGivers.NewMark(parent, size)
  local mark = CreateFrame("Frame", nil, parent)
  mark:SetSize(size, size)
  mark.icon = mark:CreateTexture(nil, "OVERLAY")
  mark.icon:SetAllPoints()
  setIcon(mark.icon)
  return mark
end

-- Text einer Angebotszeile: "Dungeonquest: Titel (Instanz)" bzw. "Vorquest: Titel – führt zu Instanz (Schritt 2/7)"
function DungeonQuestGivers.OfferLine(offer)
  local title, instance = DungeonQuests.Title(offer.questID), ns.InstanceInfo.MapName(offer.mapID)
  if offer.step then return string.format(L.DUNGEON_QUEST_CHAIN_OFFER, title, instance, offer.step, offer.total) end
  return string.format(L.DUNGEON_QUEST_OFFER, title, instance)
end

-- Nur Vorquests im Angebot: Symbol grau statt farbig
local function onlyChainSteps(offers)
  for _, offer in ipairs(offers) do
    if not offer.step then return false end
  end
  return true
end

function DungeonQuestGivers.ShowMark(mark, offers)
  mark.icon:SetDesaturated(onlyChainSteps(offers))
  mark:Show()
end

function DungeonQuestGivers.AddOfferLines(tooltip, offers)
  local r, g, b = ns.Theme.RGB(OFFER_COLOR)
  for index, offer in ipairs(offers) do
    if index > MAX_TOOLTIP_LINES then
      tooltip:AddLine(string.format(L.DUNGEON_QUESTS_MORE, #offers - MAX_TOOLTIP_LINES), r, g, b)
      break
    end
    tooltip:AddLine(DungeonQuestGivers.OfferLine(offer), r, g, b)
  end
end

-- Tooltipzeilen für eine Einheit (Aufruf aus Assist/Tooltip.lua)
function DungeonQuestGivers.AddUnitLines(tooltip, unit)
  if not isEnabled() then return end
  DungeonQuestGivers.AddOfferLines(tooltip, DungeonQuests.UnitOffers(unit))
end

local function plateOf(unit)
  local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
  if not plate or (plate.IsForbidden and plate:IsForbidden()) then return nil end
  return plate
end

local function updatePlate(unit)
  local plate = units[unit]
  if not plate then return end
  local offers = isEnabled() and DungeonQuests.UnitOffers(unit) or {}
  if #offers > 0 then
    if not marks[plate] then
      marks[plate] = DungeonQuestGivers.NewMark(plate, PLATE_ICON_SIZE)
      marks[plate]:SetPoint("BOTTOM", plate, "TOP", 0, PLATE_GAP)
    end
    DungeonQuestGivers.ShowMark(marks[plate], offers)
  elseif marks[plate] then
    marks[plate]:Hide()
  end
end

local function updateTarget()
  if not TargetFrame then return end
  local offers = isEnabled() and DungeonQuests.UnitOffers("target") or {}
  if #offers > 0 and not targetMark then
    targetMark = DungeonQuestGivers.NewMark(TargetFrame, TARGET_ICON_SIZE)
    targetMark:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 0, 0)
  end
  if not targetMark then return end
  if #offers > 0 then DungeonQuestGivers.ShowMark(targetMark, offers) else targetMark:Hide() end
end

local function refreshAll()
  for unit in pairs(units) do updatePlate(unit) end
  updateTarget()
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

ns.RegisterEvent("PLAYER_TARGET_CHANGED", updateTarget)

ns.Every(CHECK_SECONDS, function()
  if shownRevision == DungeonQuests.Revision() then return end
  shownRevision = DungeonQuests.Revision()
  refreshAll()
end, function(db) return db.dungeonQuestGivers end)

-- Kartenpunkte: Geber mit Ort auf der gezeigten Zonenkarte
local function mapPoints(uiMapID)
  local points = {}
  for _, place in ipairs(DungeonQuests.OffersOnMap(uiMapID)) do
    table.insert(points, { x = place.x, y = place.y, size = MAP_ICON_SIZE, atlas = ICON_ATLAS, texture = ICON_TEXTURE,
      offers = place.offers })
  end
  return points
end

local function showMapTooltip(pin, point)
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  DungeonQuestGivers.AddOfferLines(GameTooltip, point.offers)
  GameTooltip:Show()
end

local layer = ns.MapPins.Create({
  name = ns.GlobalName("DungeonQuestGivers"),
  label = "DungeonQuestGivers",
  points = mapPoints,
  revision = DungeonQuests.Revision,
  onEnter = showMapTooltip,
  mapIDs = DungeonQuests.GiverMapIDs,
})

local function apply()
  layer.SetEnabled(isEnabled())
  shownRevision = nil
  refreshAll()
end
ns.OnLogin(apply)
ns.RegisterApply(apply)
