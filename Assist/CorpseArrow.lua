-- Leichenpfeil (Roadmap 351, Einstellung corpseArrow, aus): als Geist zeigt ein Pfeil oben in der Bildschirmmitte
-- die Richtung zur eigenen Leiche, darunter die Entfernung. Nur zwischen Freilassen und Wiederbeleben
-- (PLAYER_ALIVE/PLAYER_UNGHOST/PLAYER_DEAD/PLAYER_ENTERING_WORLD, UnitIsGhost("player")).
-- Quelle (DeathInfoDocumentation; Zweige classic_era, forever, live): C_DeathInfo.GetCorpseMapPosition(uiMapID) = Leiche
-- auf der Karte des Spielers (Vector2D, nil auf anderen Karten). Richtung, Entfernung und Pfeil: Lib/MapDirection.lua.
-- In Instanzen (oder bei geheimen Werten) gibt es keine Position: dann ist nichts zu sehen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    corpseArrow = false,
  },
})

local CorpseArrow = {}
ns.CorpseArrow = CorpseArrow

local OFFSET_Y = -120

local frame

function CorpseArrow.IsGhost()
  local ghost = UnitIsGhost and UnitIsGhost("player")
  return not ns.IsSecret(ghost) and ghost == true
end

-- Drehung des Pfeils (Bogenmaß, gegen den Uhrzeigersinn, 0 = geradeaus) und Entfernung in Yards; nil = unbekannt
function CorpseArrow.Direction()
  if not (C_DeathInfo and C_DeathInfo.GetCorpseMapPosition) then return nil end
  local mapID = ns.MapDirection.PlayerMap()
  if not mapID then return nil end
  local x, y = ns.MapDirection.XY(C_DeathInfo.GetCorpseMapPosition(mapID))
  if not x then return nil end
  return ns.MapDirection.Toward(mapID, x, y)
end

function CorpseArrow.Refresh()
  local show = ns.db and ns.db.corpseArrow and CorpseArrow.IsGhost()
  if show and not frame then
    frame = ns.MapDirection.CreateArrow({ name = ns.GlobalName("CorpseArrow"), label = "CorpseArrow", offsetY = OFFSET_Y,
      direction = CorpseArrow.Direction })
  end
  if not frame then return end
  frame:SetShown(show and true or false)
  if show then frame.Update() end
end

for _, event in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_ENTERING_WORLD" }) do
  ns.RegisterEvent(event, CorpseArrow.Refresh)
end
ns.RegisterApply(CorpseArrow.Refresh)
