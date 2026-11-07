-- Todeskarte (Roadmap 280, Einstellung deathMap, Standard aus): Punkte der eigenen Tode (Journal deathLog mit mapID,
-- x, y aus DeathPlace.lua) auf der angezeigten Weltkarte, Tooltip mit Ursache, Level, Zeitpunkt und letzten Worten.
-- Zeichnen und Anhängen an die Weltkarte übernimmt Lib/MapPins.lua.
local _, ns = ...
local L = ns.L

local DeathMap = {}
ns.DeathMap = DeathMap

local PIN_SIZE = 8
local PIN_COLOR = { 0.9, 0.1, 0.1, 0.9 }

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

local function points(mapID)
  local list = {}
  for index, entry in ipairs(DeathMap.DeathsOn(mapID)) do
    list[index] = { x = entry.x, y = entry.y, size = PIN_SIZE, color = PIN_COLOR, entry = entry }
  end
  return list
end

local function showTooltip(pin, point)
  local entry = point.entry
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:AddLine(ns.History.DeathCauseText(entry), 1, 0.3, 0.3)
  GameTooltip:AddLine(string.format(L.DEATH_MAP_DETAILS, entry.level or "?", date(L.DATE_TIME_FORMAT, entry.time)),
    1, 1, 1)
  if entry.lastWords then
    GameTooltip:AddLine(string.format(L.DEATH_MAP_LAST_WORDS, entry.lastWords), 0.8, 0.8, 0.8, true)
  end
  GameTooltip:Show()
end

local layer = ns.MapPins.Create({
  name = "LevelTimerDeathMap",
  label = "DeathMap",
  points = points,
  revision = ns.Journal.Revision,
  onEnter = showTooltip,
})

function DeathMap.Refresh(force)
  layer.Refresh(force)
end

ns.OnLogin(function() layer.SetEnabled(ns.db.deathMap) end)
ns.RegisterApply(function(db) layer.SetEnabled(db.deathMap) end)
