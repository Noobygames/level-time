local _, ns = ...
local L = ns.L

local RADIUS_OFFSET = 10  -- Abstand des Buttons vom Minimap-Rand

-- Aufbau wie LibDBIcon, damit der Button zu anderen Minimap-Buttons passt
local button = CreateFrame("Button", "LevelTimerMinimapButton", Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:Hide()

local overlay = button:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

local background = button:CreateTexture(nil, "BACKGROUND")
background:SetSize(20, 20)
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
background:SetPoint("TOPLEFT", 7, -5)

-- Eigenes Icon mit transparentem Rand, deckungsgleich mit dem runden Hintergrund
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20)
icon:SetTexture(ns.Widgets.ICON)
icon:SetPoint("TOPLEFT", 7, -5)

local function updatePosition()
  local angle = math.rad(ns.db.minimap.angle)
  local radius = Minimap:GetWidth() / 2 + RADIUS_OFFSET
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- Beim Ziehen Winkel zwischen Minimap-Mitte und Cursor berechnen
local function onDragUpdate()
  local mx, my = Minimap:GetCenter()
  local scale = Minimap:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  cx, cy = cx / scale, cy / scale
  ns.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
  updatePosition()
end

button:SetScript("OnDragStart", function(self)
  self:LockHighlight()
  self:SetScript("OnUpdate", onDragUpdate)
  GameTooltip:Hide()
end)
button:SetScript("OnDragStop", function(self)
  self:UnlockHighlight()
  self:SetScript("OnUpdate", nil)
end)

button:SetScript("OnClick", function(_, mouseButton)
  if mouseButton == "RightButton" and IsShiftKeyDown() then
    ns.EditMode.Toggle()
  elseif mouseButton == "RightButton" then
    ns.Set("showTimer", not ns.db.showTimer)
  elseif IsShiftKeyDown() then
    ns.ToggleHistory()
  else
    ns.ToggleOptions()
  end
end)

button:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine(ns.DISPLAY_NAME)
  GameTooltip:AddLine(L.TOOLTIP_LEFT, 1, 1, 1)
  GameTooltip:AddLine(L.TOOLTIP_SHIFT_LEFT, 1, 1, 1)
  GameTooltip:AddLine(L.TOOLTIP_RIGHT, 1, 1, 1)
  GameTooltip:AddLine(L.TOOLTIP_SHIFT_RIGHT, 1, 1, 1)
  GameTooltip:AddLine(L.TOOLTIP_DRAG, 1, 1, 1)
  GameTooltip:Show()
end)
button:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

function ns.SetMinimapHidden(hidden)
  ns.db.minimap.hide = hidden
  ns.ApplySettings()
  if hidden then ns.Print(L.MINIMAP_HIDDEN) end
end

ns.RegisterApply(function(db)
  if db.minimap.hide then
    button:Hide()
  else
    updatePosition()
    button:Show()
  end
end)

-- Retail: Eintrag im Addon-Compartment (siehe AddonCompartmentFunc in der .toc)
function LevelTimer_OnAddonCompartmentClick()
  ns.ToggleOptions()
end
