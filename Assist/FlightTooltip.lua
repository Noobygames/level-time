-- Flugzeit im Tooltip der Flugkarte (Einstellung flightTimeTooltip, wirkt nur mit eingeschaltetem flightTimer):
-- "Flugzeit 2:21 (dein Flug)", "(Level-Time-Daten)" oder "~2:20 (geschätzt)". Nur Post-Hooks, kein Taint:
--   TaxiFrame (Era/TBC immer, Retail/Forever bei UIMapSystem.Taxi): hooksecurefunc("TaxiNodeOnButtonEnter"), der
--     Knopf trägt den Slot als ID; Blizzard ruft die globale Funktion aus dem OnEnter der Vorlage auf.
--   FlightMap (Retail/Forever, Blizzard_FlightMap lädt bei Bedarf): hooksecurefunc auf
--     FlightMap_FlightPointPinMixin.OnMouseEnter, sobald das Addon geladen ist und bevor Pins entstehen (die Vorlage
--     kopiert den Mixin beim Erzeugen); Slot = pin.taxiNodeData.slotIndex.
-- Beide Blizzard-Funktionen rufen am Ende GameTooltip:Show(); die Zeile kommt danach, darum noch einmal Show().
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    flightTimeTooltip = true,
  },
})
local L = ns.L

local FlightTooltip = {}
ns.FlightTooltip = FlightTooltip

local FLIGHT_MAP_ADDON = "Blizzard_FlightMap"

local function formatTime(seconds)
  seconds = math.floor(seconds + 0.5)
  return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Tooltip-Zeile für einen Slot der offenen Karte (nil = nichts anzeigen)
function FlightTooltip.Line(slot)
  if not (ns.db.flightTimer and ns.db.flightTimeTooltip) then return nil end
  if ns.IsSecret(slot) then return nil end
  local nodeType = TaxiNodeGetType(slot)
  if ns.IsSecret(nodeType) or nodeType ~= ns.FlightMap.REACHABLE then return nil end
  local known = ns.FlightTimer.Lookup(slot)
  if not known then return nil end
  local time = formatTime(known.seconds)
  if known.estimated then return string.format(L.FLIGHT_TOOLTIP_ESTIMATE, time), true end
  if known.source == ns.FlightTimes.DATA then return string.format(L.FLIGHT_TOOLTIP_DATA, time), false end
  return string.format(L.FLIGHT_TOOLTIP_MEASURED, time), false
end

local function addLine(slot)
  if not slot then return end
  local text, estimated = FlightTooltip.Line(slot)
  if not text then return end
  GameTooltip:AddLine(text, ns.Theme.RGB(estimated and "muted" or "info"))
  GameTooltip:Show()
end

local function hookTaxiFrame()
  if not (hooksecurefunc and TaxiNodeOnButtonEnter) then return false end
  hooksecurefunc("TaxiNodeOnButtonEnter", function(button) addLine(button and button:GetID()) end)
  return true
end

local flightMapHooked = false
local function hookFlightMap()
  if flightMapHooked or not (hooksecurefunc and FlightMap_FlightPointPinMixin) then return end
  flightMapHooked = true
  hooksecurefunc(FlightMap_FlightPointPinMixin, "OnMouseEnter", function(pin)
    local data = pin and pin.taxiNodeData
    addLine(data and data.slotIndex)
  end)
end

local taxiFrameHooked = hookTaxiFrame()
hookFlightMap()
ns.RegisterEvent("ADDON_LOADED", function(name)
  if not taxiFrameHooked then taxiFrameHooked = hookTaxiFrame() end
  if name == FLIGHT_MAP_ADDON then hookFlightMap() end
end)
