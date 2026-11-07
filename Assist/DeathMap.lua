-- Todeskarte (Roadmap 280, Einstellung deathMap, Standard aus): Punkte der eigenen Tode (Journal deathLog mit mapID,
-- x, y aus DeathPlace.lua) auf der angezeigten Weltkarte, Tooltip mit Ursache, Level, Zeitpunkt und letzten Worten.
-- Quellen (Gethe/wow-ui-source, alle vier Zweige): WorldMapFrame ist ein MapCanvas mit GetMapID() und GetCanvas()
-- (= ScrollContainer.Child, zoomt mit). Eigener Rahmen als Kind der Leinwand, eigene Texturen statt Blizzards
-- Pin-Vorlagen; ein OnUpdate des eigenen Rahmens bemerkt Kartenwechsel (keine Hooks auf Blizzard-Funktionen).
local _, ns = ...
local L = ns.L

local DeathMap = {}
ns.DeathMap = DeathMap

local PIN_SIZE = 8
local PIN_COLOR = { 0.9, 0.1, 0.1, 0.9 }
local CHECK_SECONDS = 0.5

local overlay
local pins = {}
local shownFor  -- Karte, Journal-Stand und Größe der zuletzt gezeichneten Punkte

-- Tode des eingeloggten Charakters auf dieser Karte
function DeathMap.DeathsOn(mapID)
  local deaths = {}
  for _, entry in ipairs(ns.Journal.GetEntries(ns.characterKey, "deathLog")) do
    if entry.mapID == mapID and type(entry.x) == "number" and type(entry.y) == "number" then
      deaths[#deaths + 1] = entry
    end
  end
  return deaths
end

local function showTooltip(pin)
  local entry = pin.entry
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:AddLine(ns.History.DeathCauseText(entry), 1, 0.3, 0.3)
  GameTooltip:AddLine(string.format(L.DEATH_MAP_DETAILS, entry.level or "?", date(L.DATE_TIME_FORMAT, entry.time)),
    1, 1, 1)
  if entry.lastWords then
    GameTooltip:AddLine(string.format(L.DEATH_MAP_LAST_WORDS, entry.lastWords), 0.8, 0.8, 0.8, true)
  end
  GameTooltip:Show()
end

local function getPin(index)
  if pins[index] then return pins[index] end
  local pin = CreateFrame("Frame", nil, overlay)
  pin:SetSize(PIN_SIZE, PIN_SIZE)
  pin:EnableMouse(true)
  pin.texture = pin:CreateTexture(nil, "OVERLAY")
  pin.texture:SetAllPoints(pin)
  pin.texture:SetColorTexture(unpack(PIN_COLOR))
  pin:SetScript("OnEnter", showTooltip)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  pins[index] = pin
  return pin
end

function DeathMap.Refresh(force)
  local map = WorldMapFrame
  if not overlay or not map.GetMapID then return end
  local mapID = map:GetMapID()
  local width, height = overlay:GetWidth(), overlay:GetHeight()
  local key = table.concat({ tostring(mapID), ns.Journal.Revision(), width, height }, ":")
  if not force and key == shownFor then return end
  shownFor = key
  local deaths = type(mapID) == "number" and DeathMap.DeathsOn(mapID) or {}
  for index, entry in ipairs(deaths) do
    local pin = getPin(index)
    pin.entry = entry
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", overlay, "TOPLEFT", entry.x * width, -entry.y * height)
    pin:Show()
  end
  for index = #deaths + 1, #pins do pins[index]:Hide() end
end

local function create()
  local map = WorldMapFrame
  if overlay or type(map) ~= "table" or not map.GetCanvas then return end
  local canvas = map:GetCanvas()
  if not canvas then return end
  overlay = CreateFrame("Frame", "LevelTimerDeathMap", canvas)
  overlay:SetAllPoints(canvas)
  overlay:SetFrameLevel((canvas:GetFrameLevel() or 1) + 10)
  local sinceCheck = CHECK_SECONDS
  ns.SetUpdateScript(overlay, "DeathMap", function(_, elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < CHECK_SECONDS then return end
    sinceCheck = 0
    ns.SafeCall(DeathMap.Refresh)
  end)
  overlay:SetShown(ns.db and ns.db.deathMap or false)
  ns.Debug("deaths", "death map attached")
end

ns.OnLogin(function()
  if ns.db.deathMap then create() end
end)
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == "Blizzard_WorldMap" and ns.db and ns.db.deathMap then create() end
end)
ns.RegisterApply(function(db)
  if db.deathMap then create() end
  if overlay then
    overlay:SetShown(db.deathMap)
    shownFor = nil
  end
end)
