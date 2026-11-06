-- Kamera (Reiter Komfort, System): maxCameraZoom (Standard aus) erlaubt weiter herauszuzoomen, über die CVar
-- cameraDistanceMaxZoomFactor (Blizzards Regler im Interface reicht nur bis DEFAULT_ZOOM_FACTOR). Nur beim Umschalten
-- gesetzt: ausgeschaltet zurück auf den Standard, sonst bleibt die CVar so, wie der Spieler sie hat.
local _, ns = ...

local Camera = {}
ns.Camera = Camera

local ZOOM_CVAR = "cameraDistanceMaxZoomFactor"
Camera.MAX_ZOOM_FACTOR = 2.6
Camera.DEFAULT_ZOOM_FACTOR = 1.9

local applied  -- zuletzt gesetzter Zustand (nil = noch nie)

ns.RegisterApply(function()
  local wanted = ns.db.maxCameraZoom == true
  if wanted == applied or (applied == nil and not wanted) then return end
  applied = wanted
  SetCVar(ZOOM_CVAR, wanted and Camera.MAX_ZOOM_FACTOR or Camera.DEFAULT_ZOOM_FACTOR)
  ns.Debug("comfort", "camera zoom factor %s", GetCVar(ZOOM_CVAR))
end)
