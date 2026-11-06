-- Komfort > Fenster: Klassenfarben bei Ziel und Fokus, Tooltip (Klassenfarbe, Ziel, im Kampf aus), Minimap
-- (Mausrad, Zoom-Knöpfe, Kalender). Alles umkehrbar.

-- Zielrahmen wie in Retail/Forever (ReputationColor) und Fokus wie in Classic (nameBackground); CheckFaction färbt
-- wie Blizzard mit UnitSelectionColor
local function unitFrame(name, unit, retailLayout)
  local frame = CreateFrame("Button", name)
  frame.unit = unit
  local background = frame:CreateTexture()
  if retailLayout then
    frame.TargetFrameContent = { TargetFrameContentMain = { ReputationColor = background } }
  else
    frame.nameBackground = background
  end
  function frame:CheckFaction() background:SetVertexColor(UnitSelectionColor(self.unit)) end
  return frame, background
end
local target, targetBackground = unitFrame("TargetFrame", "target", true)
local focus, focusBackground = unitFrame("FocusFrame", "focus", false)

-- Tooltip mit Datensystem: Post-Call wie TooltipDataProcessor, GetUnit liefert die Einheit
local postCalls = {}
Enum = Enum or {}
Enum.TooltipDataType = { Unit = 2 }
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
GameTooltipTextLeft1 = GameTooltip:CreateFontString()
local tooltipUnit
function GameTooltip:GetUnit() return tooltipUnit and "Name", tooltipUnit end
local tooltipLines = {}
function GameTooltip:AddLine(text, r, g, b) table.insert(tooltipLines, { text = text, color = { r, g, b } }) end
function GameTooltipTextLeft1:SetTextColor(r, g, b) self._color = { r, g, b } end
local function showTooltip(unit)
  tooltipUnit, tooltipLines = unit, {}
  rawset(GameTooltipTextLeft1, "_color", nil)
  if postCalls[Enum.TooltipDataType.Unit] then postCalls[Enum.TooltipDataType.Unit](GameTooltip) end
  GameTooltip:Show()
  local onShow = GameTooltip._scripts.OnShow  -- Show im Stub ruft keine Skripte
  if onShow then onShow(GameTooltip) end
end

-- Classic-Minimap: Zoom-Knöpfe und Blizzards Zoomfunktionen, Kalender-Knopf
MinimapZoomIn, MinimapZoomOut, GameTimeFrame = CreateFrame("Button"), CreateFrame("Button"), CreateFrame("Button")
MinimapZoomIn:EnableMouse(true)
MinimapZoomOut:EnableMouse(true)
GameTimeFrame:EnableMouse(true)
local zooms = {}
function Minimap_ZoomIn() table.insert(zooms, "in") end
function Minimap_ZoomOut() table.insert(zooms, "out") end

wow.state.units = {
  target = { name = "Gandalf", isPlayer = true, class = "MAGE", selection = { 0, 0, 1 } },
  focus = { name = "Wolf", isPlayer = false, selection = { 1, 0, 0 } },
  mouseover = { name = "Orc", isPlayer = false },
  mouseovertarget = { name = "Aragorn", isPlayer = true, class = "WARRIOR" },
}
wow.login()

-- Klassenfarben: aus = Reaktionsfarbe
target:CheckFaction()
expect("aus: Reaktionsfarbe", (targetBackground:GetVertexColor()), 0)
addon.Set("classColorFrames", true)
expectNear("Spieler in Klassenfarbe", (targetBackground:GetVertexColor()), 0.25)
target:CheckFaction()
expectNear("nach Blizzards CheckFaction wieder Klassenfarbe", (targetBackground:GetVertexColor()), 0.25)
focus:CheckFaction()
expect("NPC behält Reaktionsfarbe (Classic-Rahmen)", (focusBackground:GetVertexColor()), 1)
-- Geheime Klasse: Blizzards Farbe bleibt
wow.state.units.target.class = wow.SECRET
target:CheckFaction()
expect("geheim: Reaktionsfarbe", (targetBackground:GetVertexColor()), 0)
wow.state.units.target.class = "MAGE"
target:CheckFaction()
addon.Set("classColorFrames", false)
expect("aus: sofort Reaktionsfarbe", (targetBackground:GetVertexColor()), 0)

-- Tooltip: aus = nichts verändert
addon.Set("tooltipClassColors", true)
addon.Set("tooltipTarget", true)
showTooltip("mouseover")
expect("NPC: Name unverändert", rawget(GameTooltipTextLeft1, "_color"), nil)
expect("Zielzeile", tooltipLines[1] and tooltipLines[1].text, "Ziel: Aragorn")
expectNear("Ziel in Klassenfarbe", tooltipLines[1].color[1], 0.78)
showTooltip("target")
expectNear("Spielername in Klassenfarbe", GameTooltipTextLeft1._color[1], 0.25)
expect("ohne Ziel keine Zeile", #tooltipLines, 0)
addon.Set("tooltipTarget", false)
showTooltip("mouseover")
expect("aus: keine Zielzeile", #tooltipLines, 0)

-- Im Kampf ausblenden, Umschalt zeigt trotzdem; Tooltips ohne Einheit bleiben
addon.Set("tooltipHideInCombat", true)
wow.state.inCombat = true
showTooltip("mouseover")
expect("im Kampf versteckt", GameTooltip:IsShown(), false)
wow.state.shiftDown = true
showTooltip("mouseover")
expect("mit Umschalt sichtbar", GameTooltip:IsShown(), true)
wow.state.shiftDown = false
showTooltip(nil)
expect("ohne Einheit sichtbar", GameTooltip:IsShown(), true)
showTooltip(wow.SECRET)
expect("geheime Einheit versteckt", GameTooltip:IsShown(), false)
wow.state.inCombat = false
showTooltip("mouseover")
expect("außerhalb des Kampfs sichtbar", GameTooltip:IsShown(), true)

-- Minimap: Mausrad zoomt mit Blizzards Funktionen, aus = Mausrad wieder aus
expectTrue("Mausrad-Schalter in Classic", addon.MinimapTweaks.CanWheelZoom())
addon.Set("minimapWheelZoom", true)
expect("Mausrad an", Minimap:IsMouseWheelEnabled(), true)
Minimap._scripts.OnMouseWheel(Minimap, 1)
Minimap._scripts.OnMouseWheel(Minimap, -1)
expect("hinein", zooms[1], "in")
expect("heraus", zooms[2], "out")
addon.Set("minimapWheelZoom", false)
expect("Mausrad aus", Minimap:IsMouseWheelEnabled(), false)

addon.Set("minimapHideZoomButtons", true)
addon.Set("minimapHideCalendar", true)
expect("Zoom-Knopf unsichtbar", MinimapZoomIn:GetAlpha(), 0)
expect("Zoom-Knopf nicht klickbar", MinimapZoomOut:IsMouseEnabled(), false)
expect("Kalender unsichtbar", GameTimeFrame:GetAlpha(), 0)
addon.Set("minimapHideZoomButtons", false)
addon.Set("minimapHideCalendar", false)
expect("Zoom-Knopf zurück", MinimapZoomIn:GetAlpha(), 1)
expect("Zoom-Knopf klickbar", MinimapZoomIn:IsMouseEnabled(), true)
expect("Kalender klickbar", GameTimeFrame:IsMouseEnabled(), true)
