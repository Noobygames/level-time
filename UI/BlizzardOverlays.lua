-- Flächen über Blizzards Oberflächen-Elementen im Edit-Modus (Roadmap 366): jedes Element aus Assist/BlizzardHide.lua,
-- das es gerade gibt und das zu sehen ist (oder das wir ausgeblendet haben), bekommt eine dünn umrandete, beschriftete
-- Fläche in der leisen Farbe (anders als die Akzent-Flächen unserer eigenen Anzeigen) mit einem Haken "Ausblenden".
-- Ausgeblendete Elemente zeigen eine abgedunkelte Platzhalter-Fläche, damit man sie wieder einschalten kann.
-- Verschoben wird hier nichts. Flächen entstehen erst beim ersten Betreten, beim Verlassen werden alle versteckt;
-- außerhalb des Modus läuft nichts. Schalter "Blizzard-Elemente zeigen" in der Leiste (Einstellung editBlizzardFrames).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local EditMode = ns.EditMode
local BlizzardHide = ns.BlizzardHide

local BlizzardOverlays = {}
ns.BlizzardOverlays = BlizzardOverlays

local FILL_ALPHA = 0.12
local HIDDEN_FILL_ALPHA = 0.45
local LINE_ALPHA = 0.8
local HIDDEN_LINE_ALPHA = 0.4
local INSET = 2
local STRATA = "FULLSCREEN"  -- unter den Flächen unserer Anzeigen (FULLSCREEN_DIALOG)
local BASE_LEVEL = 10

local overlays = {}  -- Id -> Fläche
local shown = false

-- Frame, über dem die Fläche liegt: erster sichtbarer (oder ausgeblendeter) mit bekannter Lage
local function anchorOf(entry, hidden)
  for _, frame in ipairs(BlizzardHide.Frames(entry)) do
    local visible = type(frame.IsVisible) == "function" and frame:IsVisible()
    if (visible or hidden) and type(frame.GetLeft) == "function" and frame:GetLeft() ~= nil then return frame end
  end
end

local function paint(overlay)
  local entry = overlay.entry
  local hidden = BlizzardHide.IsHidden(entry.id)
  local r, g, b = Theme.RGB("muted")
  if hidden then
    overlay.fill:SetColorTexture(0, 0, 0, HIDDEN_FILL_ALPHA)
  else
    overlay.fill:SetColorTexture(r, g, b, FILL_ALPHA)
  end
  for _, line in pairs(overlay.lines) do line:SetColorTexture(r, g, b, hidden and HIDDEN_LINE_ALPHA or LINE_ALPHA) end
  local label = BlizzardHide.Label(entry)
  overlay.label:SetText(hidden and string.format(L.EDIT_MODE_BLIZZARD_HIDDEN, label) or label)
  overlay.label:SetTextColor(r, g, b, 1)
  overlay.check:SetChecked(hidden)
  overlay.check.label:SetText(L.EDIT_MODE_BLIZZARD_HIDE)
end

local function createOverlay(entry)
  local overlay = CreateFrame("Frame", "LevelTimerBlizzardEdit_" .. entry.id, UIParent)
  overlay.entry = entry
  overlay:SetFrameStrata(STRATA)
  overlay:EnableMouse(true)  -- im Modus keine Klicks auf das Element darunter
  overlay.fill = overlay:CreateTexture(nil, "BACKGROUND")
  overlay.fill:SetAllPoints()
  overlay.lines = {}
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local line = overlay:CreateTexture(nil, "BORDER")
    if side == "TOP" or side == "BOTTOM" then
      line:SetPoint(side .. "LEFT")
      line:SetPoint(side .. "RIGHT")
      line:SetHeight(1)
    else
      line:SetPoint("TOP" .. side)
      line:SetPoint("BOTTOM" .. side)
      line:SetWidth(1)
    end
    overlay.lines[side] = line
  end
  overlay.check = Widgets.CreateCheckbox(overlay, function(checked)
    BlizzardHide.SetHidden(entry.id, checked)
  end)
  overlay.check:SetPoint("TOPLEFT", INSET, -INSET)
  Widgets.AttachTooltip(overlay.check, function() return BlizzardHide.Label(entry) end,
    function() return L.BLIZZARD_FRAME_TIP end)
  overlay.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  overlay.label:SetPoint("BOTTOMLEFT", INSET, INSET)
  overlay:Hide()
  overlays[entry.id] = overlay
  return overlay
end

local function area(frame)
  return (frame:GetWidth() or 0) * (frame:GetHeight() or 0) * (frame:GetScale() or 1)
end

-- Flächen neu setzen: kleinere Elemente liegen über größeren (Uhr über der Minimap), damit ihr Haken erreichbar ist
function BlizzardOverlays.Refresh()
  local placed = {}
  for _, entry in ipairs(BlizzardHide.ENTRIES) do
    local overlay = overlays[entry.id]
    local anchor = anchorOf(entry, BlizzardHide.IsHidden(entry.id))
    if anchor then
      overlay = overlay or createOverlay(entry)
      overlay:ClearAllPoints()
      overlay:SetAllPoints(anchor)
      paint(overlay)
      overlay:Show()
      table.insert(placed, { overlay = overlay, area = area(anchor) })
    elseif overlay then
      overlay:Hide()
    end
  end
  table.sort(placed, function(a, b) return a.area > b.area end)
  for index, item in ipairs(placed) do item.overlay:SetFrameLevel(BASE_LEVEL + index) end
  shown = true
  ns.Debug("edit", "blizzard overlays: %s shown", #placed)
end

function BlizzardOverlays.HideAll()
  for _, overlay in pairs(overlays) do overlay:Hide() end
  shown = false
end

function BlizzardOverlays.Overlay(id)
  return overlays[id]
end

local function update()
  if EditMode.IsActive() and ns.db.editBlizzardFrames then
    BlizzardOverlays.Refresh()
  elseif shown then
    BlizzardOverlays.HideAll()
  end
end

EditMode.OnEnter(update)
EditMode.OnLeave(BlizzardOverlays.HideAll)

-- Einstellung geändert (Haken, Optionen, Sprache, Theme): offene Flächen neu setzen
ns.RegisterApply(function()
  if EditMode.IsActive() or shown then update() end
end)

EditMode.AddToolbarCheck({
  label = "EDIT_MODE_SHOW_BLIZZARD",
  tip = "EDIT_MODE_SHOW_BLIZZARD_TIP",
  get = function(db) return db.editBlizzardFrames end,
  set = function(checked) ns.Set("editBlizzardFrames", checked) end,
})
