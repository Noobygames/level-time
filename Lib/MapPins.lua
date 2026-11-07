-- Punkte auf der Weltkarte (Todeskarte, Questkarte): eigener Rahmen als Kind der Kartenleinwand, eigene Texturen statt
-- Blizzards Pin-Vorlagen. Quellen (Gethe/wow-ui-source, alle vier Zweige): WorldMapFrame ist ein MapCanvas mit
-- GetMapID() und GetCanvas() (= ScrollContainer.Child, zoomt mit). Ein gedrosseltes OnUpdate des eigenen Rahmens
-- bemerkt Kartenwechsel und neue Daten (keine Hooks auf Blizzard-Funktionen); gezeichnet wird nur bei geändertem
-- Schlüssel (Karte, Datenstand, Größe).
-- MapPins.Create({ name, label, points(mapID) -> { { x, y, size, color = { r, g, b, a } oder texture } },
-- revision() -> Datenstand, onEnter(pin, point) }) -> { SetEnabled(enabled), Refresh(force) }.
-- Die Weltkarte kann später geladen werden (Blizzard_WorldMap): dann hängt sich jede eingeschaltete Karte an.
local _, ns = ...

local MapPins = {}
ns.MapPins = MapPins

local CHECK_SECONDS = 0.5
local DEFAULT_SIZE = 8

local layers = {}

local function newLayer(definition)
  local layer = { definition = definition, pins = {}, enabled = false }

  local function getPin(index)
    if layer.pins[index] then return layer.pins[index] end
    local pin = CreateFrame("Frame", nil, layer.overlay)
    pin:EnableMouse(true)
    pin.texture = pin:CreateTexture(nil, "OVERLAY")
    pin.texture:SetAllPoints(pin)
    pin:SetScript("OnEnter", function(self) definition.onEnter(self, self.point) end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    layer.pins[index] = pin
    return pin
  end

  function layer.Refresh(force)
    local overlay, map = layer.overlay, WorldMapFrame
    if not overlay or not map.GetMapID then return end
    local mapID = map:GetMapID()
    local width, height = overlay:GetWidth(), overlay:GetHeight()
    local key = table.concat({ tostring(mapID), tostring(definition.revision()), width, height }, ":")
    if not force and key == layer.shownFor then return end
    layer.shownFor = key
    local points = type(mapID) == "number" and definition.points(mapID) or {}
    for index, point in ipairs(points) do
      local pin = getPin(index)
      pin.point = point
      local size = point.size or DEFAULT_SIZE
      pin:SetSize(size, size)
      if point.texture then
        pin.texture:SetTexture(point.texture)
        pin.texture:SetVertexColor(1, 1, 1, 1)
      else
        pin.texture:SetColorTexture(unpack(point.color))
      end
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", overlay, "TOPLEFT", point.x * width, -point.y * height)
      pin:Show()
    end
    for index = #points + 1, #layer.pins do layer.pins[index]:Hide() end
  end

  local function attach()
    local map = WorldMapFrame
    if layer.overlay or type(map) ~= "table" or not map.GetCanvas then return end
    local canvas = map:GetCanvas()
    if not canvas then return end
    local overlay = CreateFrame("Frame", definition.name, canvas)
    overlay:SetAllPoints(canvas)
    overlay:SetFrameLevel((canvas:GetFrameLevel() or 1) + 10)
    layer.overlay = overlay
    local sinceCheck = CHECK_SECONDS
    ns.SetUpdateScript(overlay, definition.label, function(_, elapsed)
      sinceCheck = sinceCheck + elapsed
      if sinceCheck < CHECK_SECONDS then return end
      sinceCheck = 0
      ns.SafeCall(layer.Refresh)
    end)
    ns.Debug("map", "%s attached", definition.label)
  end

  function layer.SetEnabled(enabled)
    layer.enabled = enabled and true or false
    if layer.enabled then attach() end
    if layer.overlay then
      layer.overlay:SetShown(layer.enabled)
      layer.shownFor = nil
    end
  end

  layer.attach = attach
  return layer
end

function MapPins.Create(definition)
  local layer = newLayer(definition)
  table.insert(layers, layer)
  return layer
end

ns.RegisterEvent("ADDON_LOADED", function(name)
  if name ~= "Blizzard_WorldMap" then return end
  for _, layer in ipairs(layers) do
    if layer.enabled then layer.SetEnabled(true) end
  end
end)
