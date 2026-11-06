-- Minimap anpassen (Reiter Komfort, Fenster; je Einstellung, Standard aus), bewusst zurückhaltend und umkehrbar:
--   minimapWheelZoom        Mausrad zoomt die Minimap (Blizzards Minimap_ZoomIn/Minimap_ZoomOut, damit die Zoom-
--                           Knöpfe ihren Zustand behalten). Nur wo die Minimap kein eigenes Mausrad hat (Classic);
--                           Retail/Forever zoomen schon selbst (MinimapMixin:OnMouseWheel).
--   minimapHideZoomButtons  Zoom-Knöpfe MinimapZoomIn/MinimapZoomOut (Classic) unsichtbar und nicht klickbar (Alpha 0,
--                           Maus aus). Retail/Forever zeigen sie nur beim Überfahren, dort fehlt der Schalter.
--   minimapHideCalendar     Kalender- bzw. Tageszeit-Knopf an der Minimap (GameTimeFrame) unsichtbar und nicht klickbar.
-- Die Minimap ist kein geschützter Frame; Blizzards Skripte werden nicht ersetzt (HookScript, nur wenn keins da ist).
local _, ns = ...

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

ns.RegisterApply(function(db)
  applyWheel(db.minimapWheelZoom)
  for _, button in ipairs(MinimapTweaks.ZoomButtons()) do
    setHidden(button, db.minimapHideZoomButtons, HIDDEN, false)
  end
  setHidden(GameTimeFrame, db.minimapHideCalendar, HIDDEN, false)
end)
