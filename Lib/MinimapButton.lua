-- Runder Button am Rand der Minimap, Aufbau wie LibDBIcon (passt zu anderen Minimap-Buttons). Ziehen mit links
-- verschiebt ihn um die Minimap. Ohne Fachwissen: Position, Klicks und Tooltip liefert der Aufrufer.
local _, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local RADIUS_OFFSET = 10  -- Abstand des Buttons vom Minimap-Rand
local BUTTON_SIZE = 31
local BORDER_SIZE = 53
local ICON_SIZE = 20
local ICON_OFFSET_X, ICON_OFFSET_Y = 7, -5
local FRAME_LEVEL = 8

-- options = { name = globaler Rahmenname, icon = Texturpfad, getAngle() -> Grad, setAngle(Grad),
--             onClick(mouseButton), tooltip(GameTooltip) }
-- Ergebnis: { frame, Update() (Position neu setzen), SetShown(shown) }
function MinimapButton.New(options)
  local button = CreateFrame("Button", options.name, Minimap)
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(FRAME_LEVEL)
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:Hide()

  local overlay = button:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(BORDER_SIZE, BORDER_SIZE)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(ICON_SIZE, ICON_SIZE)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("TOPLEFT", ICON_OFFSET_X, ICON_OFFSET_Y)

  -- Eigenes Icon mit transparentem Rand, deckungsgleich mit dem runden Hintergrund
  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetTexture(options.icon)
  icon:SetPoint("TOPLEFT", ICON_OFFSET_X, ICON_OFFSET_Y)

  local self = { frame = button }

  function self.Update()
    local angle = math.rad(options.getAngle())
    local radius = Minimap:GetWidth() / 2 + RADIUS_OFFSET
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
  end

  function self.SetShown(shown)
    if shown then
      self.Update()
      button:Show()
    else
      button:Hide()
    end
  end

  -- Beim Ziehen Winkel zwischen Minimap-Mitte und Cursor berechnen
  local function onDragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    options.setAngle(math.deg(math.atan2(cy - my, cx - mx)) % 360)
    self.Update()
  end

  button:SetScript("OnDragStart", function(frame)
    frame:LockHighlight()
    frame:SetScript("OnUpdate", onDragUpdate)
    GameTooltip:Hide()
  end)
  button:SetScript("OnDragStop", function(frame)
    frame:UnlockHighlight()
    frame:SetScript("OnUpdate", nil)
  end)

  button:SetScript("OnClick", function(_, mouseButton) options.onClick(mouseButton) end)

  button:SetScript("OnEnter", function(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    options.tooltip(GameTooltip)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return self
end
