-- Bildschirmränder (Reiter Komfort, Oberfläche; screenBorders, Standard aus): schwarze Balken oben, unten und an den
-- Seiten (screenBorderTop/Bottom/Sides, UI-Einheiten), über der Spielwelt und unter der Oberfläche: eigener Rahmen an
-- UIParent in der Schicht BACKGROUND, Maus aus. Die Spielwelt (WorldFrame) wird nicht verkleinert: das wäre ein
-- geschützter Eingriff und bliebe bei einem Fehler bis /reload falsch. Keine Blizzard-Frames berührt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    screenBorders = false,
    screenBorderTop = 0,
    screenBorderBottom = 0,
    screenBorderSides = 0,
  },
})

local ScreenBorders = {}
ns.ScreenBorders = ScreenBorders

ScreenBorders.MAX_SIZE = 300
ScreenBorders.STEP = 5
local COLOR = { 0, 0, 0, 1 }

local frame, edges

local function create()
  frame = CreateFrame("Frame", ns.GlobalName("ScreenBorders"), UIParent)
  frame:SetAllPoints(UIParent)
  frame:SetFrameStrata("BACKGROUND")
  frame:SetFrameLevel(0)
  frame:EnableMouse(false)
  edges = {}
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetColorTexture(unpack(COLOR))
    edges[side] = texture
  end
  edges.top:SetPoint("TOPLEFT")
  edges.top:SetPoint("TOPRIGHT")
  edges.bottom:SetPoint("BOTTOMLEFT")
  edges.bottom:SetPoint("BOTTOMRIGHT")
  edges.left:SetPoint("TOPLEFT")
  edges.left:SetPoint("BOTTOMLEFT")
  edges.right:SetPoint("TOPRIGHT")
  edges.right:SetPoint("BOTTOMRIGHT")
end

local function clamp(value)
  return math.max(0, math.min(ScreenBorders.MAX_SIZE, tonumber(value) or 0))
end

-- Breite 0 blendet eine Kante aus (eine Textur mit Höhe 0 zeigt der Client sonst als 1 px)
local function setEdge(texture, size, horizontal)
  texture:SetShown(size > 0)
  if horizontal then texture:SetHeight(math.max(size, 1)) else texture:SetWidth(math.max(size, 1)) end
end

function ScreenBorders.Frame()
  return frame
end

function ScreenBorders.Edges()
  return edges
end

ns.RegisterApply(function(db)
  if not db.screenBorders then
    if frame then frame:Hide() end
    return
  end
  if not frame then create() end
  local sides = clamp(db.screenBorderSides)
  setEdge(edges.top, clamp(db.screenBorderTop), true)
  setEdge(edges.bottom, clamp(db.screenBorderBottom), true)
  setEdge(edges.left, sides, false)
  setEdge(edges.right, sides, false)
  frame:Show()
end)
