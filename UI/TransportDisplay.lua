-- Anzeigen der Schiffs- und Zeppelin-Zeiten (Assist/TransportTimes.lua, Roadmap 440):
--   Minimap   kleine Beschriftung (Frame LevelTimerTransport, Edit-Modus-ID "transport"), solange der Spieler an einem
--             gelernten Anleger steht: "Orgrimmar > Tirisfal Glades: Abfahrt in 1:23"
--   Plakette  über der Namensplakette des Transportmeisters je Strecke "Tirisfal Glades: Abfahrt in 1:23" (NPC-ID in
--             dock.npcIds; bekannte Zeppelinmeister ordnet Transports.DockOfMaster selbst zu, sonst /lt transport master).
--             Befreundete NPC-Namensplaketten müssen im Spiel eingeschaltet sein; die CVar ändern wir nicht.
--   Tooltip   eine Zeile im Tooltip des Transportmeisters (Post-Call wie Assist/Tooltip.lua, kein Taint)
-- Aktualisierung im Ein-Sekunden-Takt (ns.Every), Texte nur bei Änderung gesetzt.
local _, ns = ...
local L = ns.L
local Transports = ns.Transports

local TransportDisplay = {}
ns.TransportDisplay = TransportDisplay

local UPDATE_SECONDS = 1
local LABEL_WIDTH = 260
local PLATE_OFFSET = 6
local PREVIEW_LINES = { { "Orgrimmar > Tirisfal Glades", "departs", 83 }, { "Stranglethorn Vale > Orgrimmar", "unknown" } }

local frame = CreateFrame("Frame", ns.GlobalName("Transport"), UIParent)
frame:SetSize(LABEL_WIDTH, 40)
frame:Hide()
local text = frame:CreateFontString(nil, "OVERLAY", ns.Theme.Font("small", true))
text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
text:SetWidth(LABEL_WIDTH)
text:SetJustifyH("RIGHT")

local previewing = false
local plates = {}  -- Einheit -> { frame, text }

local function clock(seconds)
  seconds = math.max(0, math.floor(seconds + 0.5))
  return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function routeName(route)
  return route.from .. " > " .. route.to
end

-- Kurzer Name für die Plakette: wohin es geht (Abfahrt) bzw. woher es kommt (Ankunft)
local function shortName(route, kind)
  return kind == "arrives" and route.from or route.to
end

local function lineText(name, kind, seconds)
  if kind == "departs" then return string.format(L.TRANSPORT_DEPARTS, name, clock(seconds)) end
  if kind == "arrives" then return string.format(L.TRANSPORT_ARRIVES, name, clock(seconds)) end
  return string.format(L.TRANSPORT_UNKNOWN, name)
end

-- Textzeilen für einen Anleger (Liste von Strings); short = nur Ziel bzw. Herkunft statt "Von > Nach"
function TransportDisplay.TextsFor(dockName, short)
  local texts = {}
  for _, line in ipairs(Transports.LinesFor(dockName)) do
    local name = short and shortName(line.route, line.kind) or routeName(line.route)
    table.insert(texts, lineText(name, line.kind, line.seconds))
  end
  return texts
end

local function active()
  return Transports.IsEnabled()
end

---------------------------------------------------------------------------
-- Minimap
---------------------------------------------------------------------------
local function refreshMinimap()
  local shown = {}
  if previewing then
    for _, entry in ipairs(PREVIEW_LINES) do table.insert(shown, lineText(entry[1], entry[2], entry[3])) end
  elseif active() and ns.db.transportMinimap then
    local dockName = Transports.NearestDock(Transports.PlayerPosition())
    if dockName then shown = TransportDisplay.TextsFor(dockName) end
  end
  if #shown == 0 then
    frame:Hide()
    return
  end
  ns.Widgets.SetTextIfChanged(text, table.concat(shown, "\n"))
  frame:SetHeight(text:GetStringHeight() or 40)
  frame:Show()
end

function TransportDisplay.Shown() return frame:IsShown() end
function TransportDisplay.Text() return text._text or (text.GetText and text:GetText()) end

---------------------------------------------------------------------------
-- Namensplakette des Transportmeisters
---------------------------------------------------------------------------
local function plateOf(unit)
  return C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
end

local function dockOfUnit(unit)
  local guid = UnitGUID(unit)
  local npcId = Transports.NpcId(guid)
  return npcId and Transports.DockOfMaster(npcId)
end

local function hidePlate(unit)
  local entry = plates[unit]
  if entry then entry.frame:Hide() end
end

local function showPlate(unit)
  hidePlate(unit)
  if not (active() and ns.db.transportNameplate) then return end
  local dockName = dockOfUnit(unit)
  if not dockName then return end
  local plate = plateOf(unit)
  if not plate then return end
  local texts = TransportDisplay.TextsFor(dockName, true)
  if #texts == 0 then return end
  local entry = plates[unit]
  if not entry then
    local holder = CreateFrame("Frame", nil, plate)
    holder:SetSize(LABEL_WIDTH, 14)
    entry = { frame = holder, text = holder:CreateFontString(nil, "OVERLAY", ns.Theme.Font("small", true)) }
    entry.text:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
    plates[unit] = entry
  end
  entry.frame:SetParent(plate)
  entry.frame:ClearAllPoints()
  entry.frame:SetPoint("BOTTOM", plate, "TOP", 0, PLATE_OFFSET)
  entry.text.unit = unit
  ns.Widgets.SetTextIfChanged(entry.text, table.concat(texts, "\n"))
  entry.frame:Show()
end

local function refreshPlates()
  if not (active() and ns.db.transportNameplate) then
    for unit in pairs(plates) do hidePlate(unit) end
    return
  end
  if not (Transports.HasMasters() or Transports.NearestDock(Transports.PlayerPosition())) then return end
  for unit in pairs(ns.NamePlates.Active()) do
    local exists = UnitExists(unit)
    if not ns.IsSecret(exists) and exists then showPlate(unit) end
  end
end

-- Text über der Plakette dieser Einheit (nil = keiner), für Tests
function TransportDisplay.PlateText(unit)
  local entry = plates[unit]
  if not (entry and entry.frame:IsShown()) then return nil end
  return entry.text._text or (entry.text.GetText and entry.text:GetText())
end

ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if unit and not ns.IsSecret(unit) then showPlate(unit) end
end)
ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  if unit and not ns.IsSecret(unit) then hidePlate(unit) end
end)

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
function TransportDisplay.TooltipLines(unit)
  if not (active() and ns.db.transportTooltip) then return nil end
  local dockName = dockOfUnit(unit)
  if not dockName then return nil end
  local texts = TransportDisplay.TextsFor(dockName)
  return #texts > 0 and texts or nil
end

local function onUnitTooltip(tooltip)
  if type(tooltip) ~= "table" or type(tooltip.GetUnit) ~= "function" then return end
  local _, unit = tooltip:GetUnit()
  if ns.IsSecret(unit) or type(unit) ~= "string" then return end
  local lines = TransportDisplay.TooltipLines(unit)
  if not lines then return end
  for _, line in ipairs(lines) do tooltip:AddLine(line, ns.Theme.RGB("info")) end
end

local hooked = false
local function hookTooltip()
  if hooked or not GameTooltip then return end
  hooked = true
  local unitType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and unitType then
    TooltipDataProcessor.AddTooltipPostCall(unitType, onUnitTooltip)
  else
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
      onUnitTooltip(self)
      self:Show()  -- Größe nach der neuen Zeile anpassen
    end)
  end
end

---------------------------------------------------------------------------
-- Anbindung
---------------------------------------------------------------------------
ns.Frames.Register({
  id = "transport", frame = frame, label = "EDIT_FRAME_TRANSPORT",
  default = { "TOPRIGHT", "TOPRIGHT", -20, -230 },  -- unter der Minimap
  settingsPage = "COMFORT_PAGE_TIMERS", clickable = true,
  available = Transports.IsAvailable,
  preview = function(on)
    previewing = on and true or false
    refreshMinimap()
  end,
  hide = function()
    ns.SetBatch(function(db) db.transportMinimap = false end)
  end,
})

ns.Every(UPDATE_SECONDS, function()
  refreshMinimap()
  refreshPlates()
end, function() return Transports.IsEnabled() or frame:IsShown() end)

ns.RegisterApply(function()
  refreshMinimap()
  if not active() then
    for unit in pairs(plates) do hidePlate(unit) end
  end
end)
ns.OnLogin(hookTooltip)
