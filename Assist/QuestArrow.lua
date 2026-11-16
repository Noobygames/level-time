-- Questpfeil (LT-259, Einstellung questArrow, aus): für die fokussierte Quest (Assist/QuestFocus.lua) zeigt ein Pfeil
-- unter der Bildschirmmitte oben Richtung und Entfernung zum Ziel. Abgabebereit = gelernter Abgabe-NPC, sonst der
-- nächste gelernte Zielort (Orte aus Tracking/QuestNpcs.lua wie die Questkarte). Am Ziel (REACHED_YARDS) und ohne Position
-- (Instanz, geheime Werte) kein Pfeil. Rechnung und Anzeige: Lib/MapDirection.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questArrow = false,
  },
})

local QuestArrow = {}
ns.QuestArrow = QuestArrow

local OFFSET_Y = -200       -- unter dem Leichenpfeil (-120)
local REACHED_YARDS = 10

local frame

-- Orte, zu denen der Pfeil zeigen kann: { { mapID, x, y }, ... }
local function targets(questID)
  local record = ns.QuestNpcs.Get(questID)
  local entry = ns.QuestLog.Find(questID)
  if not (record and entry) then return {} end
  if entry.ready then return { record.turnIn } end
  return record.spots or {}
end

-- Drehung und Entfernung zum nächsten Ort der fokussierten Quest; nil = nichts zu zeigen (auch am Ziel)
function QuestArrow.Direction()
  local questID = ns.QuestFocus.Get()
  if not questID then return nil end
  local bestRotation, bestDistance
  for _, place in ipairs(targets(questID)) do
    local rotation, distance = ns.MapDirection.Toward(place.mapID, place.x, place.y)
    if rotation and (not bestRotation or (distance and (not bestDistance or distance < bestDistance))) then
      bestRotation, bestDistance = rotation, distance
    end
  end
  if bestDistance and bestDistance <= REACHED_YARDS then return nil end
  return bestRotation, bestDistance
end

function QuestArrow.Refresh()
  local show = ns.db and ns.db.questArrow and ns.QuestFocus.Get() ~= nil
  if show and not frame then
    frame = ns.MapDirection.CreateArrow({ name = ns.GlobalName("QuestArrow"), label = "QuestArrow", offsetY = OFFSET_Y,
      direction = QuestArrow.Direction })
  end
  if not frame then return end
  frame:SetShown(show and true or false)
  if show then frame.Update() end
end

ns.QuestFocus.OnChange(QuestArrow.Refresh)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", QuestArrow.Refresh)
ns.RegisterApply(QuestArrow.Refresh)
