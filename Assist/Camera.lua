-- Kamera (Reiter Komfort, System): maxCameraZoom (Standard aus) erlaubt weiter herauszuzoomen, über die CVar
-- cameraDistanceMaxZoomFactor (Blizzards Regler im Interface reicht nur bis DEFAULT_ZOOM_FACTOR). Umkehrbar über
-- CVars.lua: ausgeschaltet kommt der Wert des Spielers zurück; solange die Einstellung aus ist, bleibt die CVar
-- unberührt.
local _, ns = ...

local Camera = {}
ns.Camera = Camera

local ZOOM_CVAR = "cameraDistanceMaxZoomFactor"
Camera.MAX_ZOOM_FACTOR = 2.6
Camera.DEFAULT_ZOOM_FACTOR = 1.9

ns.RegisterApply(function()
  if ns.db.maxCameraZoom == true then
    -- Frühere Versionen merkten kein Original: steht die CVar schon auf unserem Wert, gilt der Standard als Original
    ns.CVars.Override(ZOOM_CVAR, Camera.MAX_ZOOM_FACTOR, ns.CVars.ACCOUNT, Camera.DEFAULT_ZOOM_FACTOR)
  else
    ns.CVars.Restore(ZOOM_CVAR)
  end
end)
