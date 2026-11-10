-- Schiffs- und Zeppelin-Zeiten auf der Weltkarte (Einstellung transportWorldMap, Roadmap 459, nicht in Retail): an
-- jedem gelernten Anleger der gezeigten Zonenkarte steht je Strecke "Tirisfal Glades: Abfahrt in 1:23" (Texte aus
-- UI/TransportDisplay.lua). Die Beschriftungen hängen an der Leinwand der Karte (WorldMapFrame:GetCanvas(), wie
-- Blizzards Pins), Position = Anleger x/y mal Leinwandgröße; sie wandern also mit Zoom und Verschieben mit.
-- Nur Lesen und eigene Frames, kein Eingriff in Blizzards Kartenrahmen.
local _, ns = ...
local Transports = ns.Transports

ns.RegisterDefaults({
  settings = {
    transportWorldMap = true,
  },
})

local TransportWorldMap = {}
ns.TransportWorldMap = TransportWorldMap

local UPDATE_SECONDS = 1
local LABEL_OFFSET = 8       -- Pixel rechts neben dem Anleger
local LABEL_LEVEL = 50       -- über den Kartenebenen der Leinwand
local WORLD_MAP_ADDON = "Blizzard_WorldMap"

local holder
local labels = {}

local function canvas()
  return WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
end

local function shownMapID()
  local mapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
  if ns.IsSecret(mapID) or type(mapID) ~= "number" then return nil end
  return mapID
end

-- Beschriftungen für eine Karte: { { x, y, text } } (leer, wenn aus oder nichts gelernt)
function TransportWorldMap.Entries(mapID)
  local entries = {}
  if not (mapID and Transports.IsEnabled() and ns.db.transportWorldMap) then return entries end
  for name, dock in pairs(Transports.Data().docks) do
    if dock.mapID == mapID then
      local texts = ns.TransportDisplay.TextsFor(name, true)
      if #texts > 0 then
        table.insert(entries, { x = dock.x, y = dock.y, text = table.concat(texts, "\n") })
      end
    end
  end
  return entries
end

local function labelAt(index)
  if not labels[index] then
    labels[index] = holder:CreateFontString(nil, "OVERLAY", ns.Theme.Font("small", true))
    labels[index]:SetJustifyH("LEFT")
  end
  return labels[index]
end

local function isShown()
  return holder ~= nil and WorldMapFrame:IsShown()
end

local function refresh()
  if not isShown() then return end
  local area = canvas()
  local entries = TransportWorldMap.Entries(shownMapID())
  for index, entry in ipairs(entries) do
    local label = labelAt(index)
    label:ClearAllPoints()
    label:SetPoint("LEFT", area, "TOPLEFT", entry.x * area:GetWidth() + LABEL_OFFSET, -entry.y * area:GetHeight())
    ns.Widgets.SetTextIfChanged(label, entry.text)
    label:Show()
  end
  for index = #entries + 1, #labels do labels[index]:Hide() end
end

local function attach()
  if holder or not Transports.IsAvailable() then return end
  local area = canvas()
  if not area then return end
  holder = CreateFrame("Frame", nil, area)
  holder:SetAllPoints(area)
  holder:SetFrameLevel(area:GetFrameLevel() + LABEL_LEVEL)
  WorldMapFrame:HookScript("OnShow", refresh)
end

ns.OnLogin(attach)
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == WORLD_MAP_ADDON then attach() end
end)
ns.Every(UPDATE_SECONDS, refresh, isShown)
ns.RegisterApply(refresh)
