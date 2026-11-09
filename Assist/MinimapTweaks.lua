-- Minimap anpassen (Reiter Komfort, Fenster; je Einstellung, Standard aus), bewusst zurückhaltend und umkehrbar:
--   minimapWheelZoom        Mausrad zoomt die Minimap (Blizzards Minimap_ZoomIn/Minimap_ZoomOut, damit die Zoom-
--                           Knöpfe ihren Zustand behalten). Nur wo die Minimap kein eigenes Mausrad hat (Classic);
--                           Retail/Forever zoomen schon selbst (MinimapMixin:OnMouseWheel).
--   minimapHideZoomButtons  Zoom-Knöpfe MinimapZoomIn/MinimapZoomOut (Classic) unsichtbar und nicht klickbar (Alpha 0,
--                           Maus aus). Retail/Forever zeigen sie nur beim Überfahren, dort fehlt der Schalter.
--   minimapHideCalendar     Kalender- bzw. Tageszeit-Knopf an der Minimap (GameTimeFrame) unsichtbar und nicht klickbar.
--   minimapSquare           Eckige Minimap: Maske Interface\ChatFrame\ChatFrameBackground (Minimap:SetMaskTexture, alle
--                           Clients), runde Ränder (MinimapBorder, MinimapBorderTop, MinimapCompassTexture,
--                           MinimapCompassTextureUnderlay) per Alpha 0; GetMinimapShape() meldet "SQUARE" für andere
--                           Addons (nur wenn kein anderes Addon die Funktion definiert). Setzt Blizzard die Maske neu
--                           (Forever beim Drehen der Minimap), zieht ein Post-Hook nach. Zurück: Forever ruft Blizzards
--                           MinimapCluster:UpdateMinimapConfig() (setzt Maske und Rahmen selbst), sonst die runde
--                           Standardmaske des Clients (ROUND_MASKS; der Client hat kein GetMaskTexture).
--                           Größe ist übersprungen: alle vier Clients haben dafür die Edit-Mode-Einstellung "Größe".
-- Die Minimap ist kein geschützter Frame; Blizzards Skripte werden nicht ersetzt (HookScript, nur wenn keins da ist).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    minimapWheelZoom = false,
    minimapHideZoomButtons = false,
    minimapHideCalendar = false,
    minimapSquare = false,
  },
})

local MinimapTweaks = {}
ns.MinimapTweaks = MinimapTweaks

local HIDDEN = 0

-- Unsichtbar und nicht klickbar, umkehrbar
local setHidden = ns.Overrides.New(
  function(frame) return frame:GetAlpha(), frame:IsMouseEnabled() end,
  function(frame, alpha, mouse)
    frame:SetAlpha(alpha)
    frame:EnableMouse(mouse)
  end)

local setWheel = ns.Overrides.New(
  function(frame) return frame:IsMouseWheelEnabled() end,
  function(frame, enabled) frame:EnableMouseWheel(enabled) end)

function MinimapTweaks.ZoomButtons()
  local list = {}
  if MinimapZoomIn then table.insert(list, MinimapZoomIn) end
  if MinimapZoomOut then table.insert(list, MinimapZoomOut) end
  return list
end

-- Nur ohne eigenes Mausrad der Minimap (beim Laden geprüft, bevor wir selbst eins anhängen)
local nativeWheel = Minimap and Minimap.GetScript and Minimap:GetScript("OnMouseWheel") ~= nil

function MinimapTweaks.CanWheelZoom()
  return Minimap ~= nil and not nativeWheel and Minimap_ZoomIn ~= nil and Minimap_ZoomOut ~= nil
end

function MinimapTweaks.HasZoomButtons() return #MinimapTweaks.ZoomButtons() > 0 end
function MinimapTweaks.HasCalendarButton() return GameTimeFrame ~= nil end

local wheelHooked = false

local function onWheel(_, delta)
  if not ns.db.minimapWheelZoom then return end
  if delta > 0 then Minimap_ZoomIn() else Minimap_ZoomOut() end
end

local function applyWheel(enabled)
  if not MinimapTweaks.CanWheelZoom() then return end
  if enabled and not wheelHooked then
    wheelHooked = true
    Minimap:HookScript("OnMouseWheel", onWheel)
  end
  setWheel(Minimap, enabled, true)
end

---------------------------------------------------------------------------
-- Eckige Minimap
---------------------------------------------------------------------------
MinimapTweaks.SQUARE_MASK = "Interface\\ChatFrame\\ChatFrameBackground"
-- Runde Standardmaske ohne eigene Blizzard-Funktion zum Zurücksetzen (Pfade wie in verbreiteten Minimap-Addons,
-- im Spiel zu prüfen)
MinimapTweaks.ROUND_MASKS = { retail = "Interface\\Masks\\CircleMaskScalable", classic = "Textures\\MinimapMask" }
MinimapTweaks.BORDER_NAMES = { "MinimapBorder", "MinimapBorderTop", "MinimapCompassTexture",
  "MinimapCompassTextureUnderlay" }

local setAlpha = ns.Overrides.Alpha()
local squareActive, writingMask, maskHooked = false, false, false

local function setMask(mask)
  writingMask = true
  Minimap:SetMaskTexture(mask)
  writingMask = false
end

function MinimapTweaks.CanSquare()
  return Minimap ~= nil and Minimap.SetMaskTexture ~= nil
end

function MinimapTweaks.IsSquare()
  return squareActive
end

local function restoreRound()
  local cluster = MinimapCluster
  if ns.Client.IsForever() and cluster and cluster.UpdateMinimapConfig then
    cluster:UpdateMinimapConfig()
  else
    setMask(ns.Client.IsRetail() and MinimapTweaks.ROUND_MASKS.retail or MinimapTweaks.ROUND_MASKS.classic)
  end
end

-- Andere Addons (Minimap-Knöpfe) fragen die Form über diese globale Funktion ab
local function provideShape()
  if GetMinimapShape == nil then
    GetMinimapShape = function() return squareActive and "SQUARE" or "ROUND" end
  end
end

local function applySquare(enabled)
  if not MinimapTweaks.CanSquare() then return end
  if enabled and not maskHooked then
    maskHooked = true
    hooksecurefunc(Minimap, "SetMaskTexture", function()
      if squareActive and not writingMask then setMask(MinimapTweaks.SQUARE_MASK) end
    end)
  end
  if enabled then provideShape() end
  for _, name in ipairs(MinimapTweaks.BORDER_NAMES) do setAlpha(_G[name], enabled, HIDDEN) end
  if enabled then
    squareActive = true
    setMask(MinimapTweaks.SQUARE_MASK)
  elseif squareActive then
    squareActive = false
    restoreRound()
    ns.Debug("comfort", "minimap mask restored")
  end
end

ns.RegisterApply(function(db)
  applySquare(db.minimapSquare)
  applyWheel(db.minimapWheelZoom)
  for _, button in ipairs(MinimapTweaks.ZoomButtons()) do
    setHidden(button, db.minimapHideZoomButtons, HIDDEN, false)
  end
  setHidden(GameTimeFrame, db.minimapHideCalendar, HIDDEN, false)
end)
