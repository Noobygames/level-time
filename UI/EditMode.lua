-- Edit-Modus (/lt edit, Button "Layout bearbeiten" in den Einstellungen, Shift+Rechtsklick auf den Minimap-Knopf):
-- alle angemeldeten Anzeigen (Lib/Frames.lua) zeigen Beispielinhalt und eine beschriftete Fläche darüber.
--   Ziehen verschiebt (rastet am Raster, an der Bildschirmmitte und an den Kanten anderer Anzeigen ein; Shift beim
--   Loslassen = frei), Mausrad skaliert, Pfeiltasten schieben die zuletzt angeklickte Anzeige um 1 px (Shift: 10 px),
--   Rechtsklick öffnet ein kleines Menü (Größe, Zurücksetzen, Ausblenden, Einstellungen). Esc oder "Fertig" beendet.
-- Nicht im Kampf: geschützte Rahmen (Quest-Item-Leiste) und Tastatur-Weitergabe sind dann gesperrt, daher beendet
-- PLAYER_REGEN_DISABLED den Modus. Retail/Forever: Einstellung editModeWithBlizzard schaltet ihn zusammen mit
-- Blizzards Bearbeitungsmodus (Nachhaken an EditModeManagerFrame:EnterEditMode/ExitEditMode, kein Eingriff).
-- Außerhalb des Modus läuft hier nichts (keine OnUpdate-Skripte, Raster und Flächen werden erst beim Betreten gebaut).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Frames = ns.Frames

local EditMode = {}
ns.EditMode = EditMode

EditMode.GRID_SIZE = 32
EditMode.SNAP_DISTANCE = 8
EditMode.NUDGE = 1
EditMode.NUDGE_FAST = 10
EditMode.WHEEL_STEP = 0.05
local OVERLAY_ALPHA = 0.25
local OVERLAY_SELECTED_ALPHA = 0.4
local GRID_ALPHA = 0.12
local GRID_CENTER_ALPHA = 0.35
local TOOLBAR_PADDING = 12
local TOOLBAR_BUTTON_WIDTH = 90
local BUTTON_HEIGHT = 22
local BUTTON_GAP = 6
local POPUP_WIDTH = 220
local POPUP_PADDING = 10
local PERCENT = 100
local ARROWS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

local active = false
local selected     -- zuletzt angeklickte Anzeige (Pfeiltasten)
local overlays = {}  -- id -> Fläche

function EditMode.IsActive()
  return active
end

---------------------------------------------------------------------------
-- Geometrie (in Einheiten von UIParent)
---------------------------------------------------------------------------

-- Rechteck einer Anzeige: { left, right, top, bottom }
function EditMode.RectOf(frame)
  local scale = frame:GetScale()
  local left, top = frame:GetLeft(), frame:GetTop()
  if not left or not top then return nil end
  left, top = left * scale, top * scale
  return { left = left, right = left + frame:GetWidth() * scale, top = top, bottom = top - frame:GetHeight() * scale }
end

local function horizontalOf(point, low, high)
  if point:find("LEFT") then return low end
  if point:find("RIGHT") then return high end
  return (low + high) / 2
end

local function verticalOf(point, low, high)
  if point:find("BOTTOM") then return low end
  if point:find("TOP") then return high end
  return (low + high) / 2
end

-- Ankerabstände für Punkt point (gegen denselben Punkt von UIParent), damit die Anzeige ihren gewohnten Anker
-- behält (z.B. Einblendungen wachsen weiter von der Mitte aus)
function EditMode.AnchorFor(point, rect, scale)
  local x = horizontalOf(point, rect.left, rect.right) - horizontalOf(point, 0, UIParent:GetWidth())
  local y = verticalOf(point, rect.bottom, rect.top) - verticalOf(point, 0, UIParent:GetHeight())
  return x / scale, y / scale
end

-- Kleinster Versatz, der eine Kante (oder die Mitte) des Rechtecks auf eine der Linien legt, höchstens distance;
-- lines = { x = { ... }, y = { ... } } (beide optional). Rückgabe dx, dy (0 = kein Einrasten)
function EditMode.Snap(rect, lines, distance)
  local function best(edges, candidates)
    local shift, gap = 0, distance + 1
    for _, edge in ipairs(edges) do
      for _, line in ipairs(candidates) do
        local delta = line - edge
        if math.abs(delta) < gap then shift, gap = delta, math.abs(delta) end
      end
    end
    return gap <= distance and shift or 0
  end
  local dx = best({ rect.left, (rect.left + rect.right) / 2, rect.right }, lines.x or {})
  local dy = best({ rect.top, (rect.top + rect.bottom) / 2, rect.bottom }, lines.y or {})
  return dx, dy
end

-- Rasterlinien laufen von der Bildschirmmitte aus; nächste Linie zu einem Wert
local function nearestGridLine(value, center)
  local size = EditMode.GRID_SIZE
  return center + math.floor((value - center) / size + 0.5) * size
end

-- Linien zum Einrasten: Bildschirmmitte, Kanten und Mitten der anderen Anzeigen, Raster (wenn eingeblendet)
local function snapLines(moving, rect)
  local width, height = UIParent:GetWidth(), UIParent:GetHeight()
  local lines = { x = { width / 2 }, y = { height / 2 } }
  for _, reg in ipairs(Frames.All()) do
    local overlay = overlays[reg.id]
    if reg ~= moving and overlay and overlay:IsShown() then
      local other = EditMode.RectOf(reg.frame)
      if other then
        for _, x in ipairs({ other.left, other.right, (other.left + other.right) / 2 }) do table.insert(lines.x, x) end
        for _, y in ipairs({ other.top, other.bottom, (other.top + other.bottom) / 2 }) do table.insert(lines.y, y) end
      end
    end
  end
  if ns.db.editGrid then
    for _, x in ipairs({ rect.left, (rect.left + rect.right) / 2, rect.right }) do
      table.insert(lines.x, nearestGridLine(x, width / 2))
    end
    for _, y in ipairs({ rect.top, (rect.top + rect.bottom) / 2, rect.bottom }) do
      table.insert(lines.y, nearestGridLine(y, height / 2))
    end
  end
  return lines
end

-- Anzeige um dx, dy (UIParent-Einheiten) versetzt speichern, mit ihrem bisherigen Ankerpunkt
local function placeShifted(reg, dx, dy)
  local rect = EditMode.RectOf(reg.frame)
  if not rect then return end
  rect.left, rect.right, rect.top, rect.bottom = rect.left + dx, rect.right + dx, rect.top + dy, rect.bottom + dy
  local point = Frames.GetPosition(reg.id)
  local x, y = EditMode.AnchorFor(point, rect, reg.frame:GetScale())
  Frames.SetPosition(reg.id, point, point, x, y)
end

-- Nach dem Ziehen: einrasten (außer mit Shift) und speichern
function EditMode.Drop(id, free)
  local reg = Frames.Get(id)
  local rect = EditMode.RectOf(reg.frame)
  if not rect then return end
  local dx, dy = 0, 0
  if not free then dx, dy = EditMode.Snap(rect, snapLines(reg, rect), EditMode.SNAP_DISTANCE) end
  ns.Debug("edit", "%s dropped, snap %s %s, free %s", id, dx, dy, free)
  placeShifted(reg, dx, dy)
end

function EditMode.Nudge(id, dx, dy)
  placeShifted(Frames.Get(id), dx, dy)
end

---------------------------------------------------------------------------
-- Flächen über den Anzeigen
---------------------------------------------------------------------------
local popup  -- unten angelegt

local function overlayText(reg)
  return string.format("%s  %d%%", L[reg.label], math.floor(Frames.GetScale(reg.id) * PERCENT + 0.5))
end

local function paintOverlay(overlay)
  local r, g, b = Theme.RGB("accent")
  local alpha = overlay.reg == selected and OVERLAY_SELECTED_ALPHA or OVERLAY_ALPHA
  overlay.fill:SetColorTexture(r, g, b, alpha)
  for _, line in pairs(overlay.lines) do line:SetColorTexture(r, g, b, 1) end
  overlay.label:SetText(overlayText(overlay.reg))
end

local function select(reg)
  local previous = selected
  selected = reg
  if previous and overlays[previous.id] then paintOverlay(overlays[previous.id]) end
  if reg and overlays[reg.id] then paintOverlay(overlays[reg.id]) end
end

local function canChange(reg)
  return not (reg.protected and InCombatLockdown())
end

local function createOverlay(reg)
  local overlay = CreateFrame("Frame", "LevelTimerEdit_" .. reg.id, UIParent)
  overlay.reg = reg
  overlay:SetFrameStrata("FULLSCREEN_DIALOG")
  overlay:SetAllPoints(reg.frame)
  overlay:EnableMouse(true)
  overlay:EnableMouseWheel(true)
  overlay:RegisterForDrag("LeftButton")
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
  overlay.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  overlay.label:SetPoint("CENTER")

  overlay:SetScript("OnMouseDown", function() select(reg) end)
  overlay:SetScript("OnDragStart", function()
    if not canChange(reg) then return end
    popup:Hide()
    reg.frame:StartMoving()
  end)
  overlay:SetScript("OnDragStop", function()
    reg.frame:StopMovingOrSizing()
    if canChange(reg) then EditMode.Drop(reg.id, IsShiftKeyDown()) end
  end)
  overlay:SetScript("OnMouseUp", function(_, mouseButton)
    if mouseButton == "RightButton" then EditMode.ShowPopup(reg.id) end
  end)
  overlay:SetScript("OnMouseWheel", function(_, delta)
    if not canChange(reg) then return end
    Frames.SetScale(reg.id, Frames.GetScale(reg.id) + delta * EditMode.WHEEL_STEP)
    paintOverlay(overlay)
  end)
  overlays[reg.id] = overlay
  return overlay
end

function EditMode.Overlay(id)
  return overlays[id]
end

---------------------------------------------------------------------------
-- Raster (Linien aus Texturen, einmal je Bildschirmgröße gebaut)
---------------------------------------------------------------------------
local grid
local gridBuiltFor

local function buildGrid()
  local width, height = UIParent:GetWidth(), UIParent:GetHeight()
  local key = width .. "x" .. height
  if gridBuiltFor == key then return end
  gridBuiltFor = key
  if not grid then
    grid = CreateFrame("Frame", "LevelTimerEditGrid", UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata("BACKGROUND")
    grid.lines = {}
  end
  for _, line in ipairs(grid.lines) do line:Hide() end
  local used = 0
  local function line(vertical, offset, alpha)
    used = used + 1
    local texture = grid.lines[used] or grid:CreateTexture(nil, "BACKGROUND")
    grid.lines[used] = texture
    texture:ClearAllPoints()
    if vertical then
      texture:SetPoint("TOPLEFT", grid, "TOPLEFT", offset, 0)
      texture:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", offset, 0)
      texture:SetWidth(1)
    else
      texture:SetPoint("TOPLEFT", grid, "BOTTOMLEFT", 0, offset)
      texture:SetPoint("TOPRIGHT", grid, "BOTTOMRIGHT", 0, offset)
      texture:SetHeight(1)
    end
    texture:SetColorTexture(1, 1, 1, alpha)
    texture:Show()
  end
  local size = EditMode.GRID_SIZE
  for _, axis in ipairs({ { true, width }, { false, height } }) do
    local center = axis[2] / 2
    line(axis[1], center, GRID_CENTER_ALPHA)
    local steps = math.floor(center / size)
    for step = 1, steps do
      line(axis[1], center + step * size, GRID_ALPHA)
      line(axis[1], center - step * size, GRID_ALPHA)
    end
  end
end

local function updateGrid()
  if active and ns.db.editGrid then
    buildGrid()
    grid:Show()
  elseif grid then
    grid:Hide()
  end
end

---------------------------------------------------------------------------
-- Leiste oben: Titel, Hinweis, Raster, Alle zurücksetzen, Fertig; nimmt die Tastatur (Pfeile, Esc)
---------------------------------------------------------------------------
local toolbar = Widgets.CreatePanel("LevelTimerEditMode", 0.95)
toolbar:SetFrameStrata("FULLSCREEN_DIALOG")
toolbar:SetPoint("TOP", UIParent, "TOP", 0, -40)
toolbar:SetScript("OnDragStart", toolbar.StartMoving)
toolbar:SetScript("OnDragStop", toolbar.StopMovingOrSizing)
toolbar:Hide()
table.insert(UISpecialFrames, "LevelTimerEditMode")  -- Esc schließt auch ohne Tastatur-Fokus (Rückfall)
toolbar.title = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
toolbar.title:SetPoint("TOP", 0, -TOOLBAR_PADDING)
toolbar.hint = toolbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toolbar.hint:SetPoint("TOP", toolbar.title, "BOTTOM", 0, -4)

local toolbarButtons = {}
local function toolbarButton(labelKey, onClick)
  local button = Widgets.CreateButton(toolbar, TOOLBAR_BUTTON_WIDTH, BUTTON_HEIGHT, onClick)
  button.labelKey = labelKey
  table.insert(toolbarButtons, button)
  return button
end

local gridButton = toolbarButton("EDIT_MODE_GRID", function()
  ns.db.editGrid = not ns.db.editGrid
  updateGrid()
end)
Widgets.AttachTooltip(gridButton, function() return L.EDIT_MODE_GRID end, function() return L.EDIT_MODE_GRID_TIP end)
toolbarButton("EDIT_MODE_RESET_ALL", function()
  Frames.ResetAll()
  for _, overlay in pairs(overlays) do paintOverlay(overlay) end
end)
toolbarButton("EDIT_MODE_DONE", function() EditMode.Leave() end)

local function layoutToolbar()
  toolbar.title:SetText(L.EDIT_MODE_TITLE)
  toolbar.hint:SetText(L.EDIT_MODE_HINT)
  local width = 0
  for _, button in ipairs(toolbarButtons) do
    Widgets.SetButtonText(button, L[button.labelKey], TOOLBAR_BUTTON_WIDTH)
    width = width + button:GetWidth()
  end
  width = width + BUTTON_GAP * (#toolbarButtons - 1)
  local previous
  for _, button in ipairs(toolbarButtons) do
    button:ClearAllPoints()
    if previous then
      button:SetPoint("LEFT", previous, "RIGHT", BUTTON_GAP, 0)
    else
      button:SetPoint("BOTTOMLEFT", toolbar, "BOTTOM", -width / 2, TOOLBAR_PADDING)
    end
    previous = button
  end
  local textWidth = math.max(toolbar.title:GetStringWidth() or 0, toolbar.hint:GetStringWidth() or 0)
  toolbar:SetSize(math.max(width, textWidth) + 2 * TOOLBAR_PADDING, 3 * TOOLBAR_PADDING + 2 * 14 + BUTTON_HEIGHT)
end

-- Tastatur: Pfeile und Esc nimmt die Leiste selbst, alles andere geht weiter ans Spiel (Laufen bleibt möglich).
-- SetPropagateKeyboardInput ist seit 10.1.5 im Kampf gesperrt; der Modus endet vorher (PLAYER_REGEN_DISABLED).
toolbar:SetScript("OnKeyDown", function(self, key)
  if InCombatLockdown() then return end
  local arrow = ARROWS[key]
  local handled = key == "ESCAPE" or (arrow ~= nil and selected ~= nil)
  self:SetPropagateKeyboardInput(not handled)
  if key == "ESCAPE" then
    EditMode.Leave()
  elseif handled then
    local step = IsShiftKeyDown() and EditMode.NUDGE_FAST or EditMode.NUDGE
    EditMode.Nudge(selected.id, arrow[1] * step, arrow[2] * step)
  end
end)
toolbar:SetScript("OnHide", function() if active then EditMode.Leave() end end)

---------------------------------------------------------------------------
-- Menü einer Anzeige (Rechtsklick): Größe, Zurücksetzen, Ausblenden, Einstellungen
---------------------------------------------------------------------------
popup = Widgets.CreatePanel("LevelTimerEditPopup", 0.95)
popup:SetFrameStrata("TOOLTIP")
popup:SetWidth(POPUP_WIDTH)
popup:Hide()
popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
popup.title:SetPoint("TOPLEFT", POPUP_PADDING, -POPUP_PADDING)

local popupReg
popup.slider = Widgets.CreateSlider(popup, Frames.MIN_SCALE * PERCENT, Frames.MAX_SCALE * PERCENT, 5, function(value)
  if not popupReg or not canChange(popupReg) then return end
  Frames.SetScale(popupReg.id, value / PERCENT)
  popup.slider.valueText:SetText(value .. "%")
  if overlays[popupReg.id] then paintOverlay(overlays[popupReg.id]) end
end)
popup.slider:SetPoint("TOPLEFT", popup.title, "BOTTOMLEFT", 0, -8)
popup.slider:SetPoint("RIGHT", popup, "RIGHT", -POPUP_PADDING, 0)

local popupButtons = {}
local function popupButton(labelKey, onClick)
  local button = Widgets.CreateButton(popup, POPUP_WIDTH - 2 * POPUP_PADDING, BUTTON_HEIGHT, onClick)
  button.labelKey = labelKey
  local previous = popupButtons[#popupButtons]
  if previous then
    button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -BUTTON_GAP)
  else
    button:SetPoint("TOPLEFT", popup.slider, "BOTTOMLEFT", 0, -10)
  end
  table.insert(popupButtons, button)
  return button
end

popupButton("EDIT_MODE_RESET", function()
  if not canChange(popupReg) then return end
  Frames.Reset(popupReg.id)
  EditMode.ShowPopup(popupReg.id)
end)
popup.hideButton = popupButton("EDIT_MODE_HIDE", function()
  local reg = popupReg
  popup:Hide()
  reg.hide()
  if reg.preview then reg.preview(false) end
  if overlays[reg.id] then overlays[reg.id]:Hide() end
end)
popup.settingsButton = popupButton("EDIT_MODE_SETTINGS", function()
  local page = popupReg.settingsPage
  EditMode.Leave()
  ns.ShowOptionsPage(page)
end)
popupButton("EDIT_MODE_CLOSE", function() popup:Hide() end)

function EditMode.ShowPopup(id)
  local reg = Frames.Get(id)
  popupReg = reg
  select(reg)
  popup.title:SetText(L[reg.label])
  popup.slider.label:SetText(L.EDIT_MODE_SCALE)
  local percent = math.floor(Frames.GetScale(id) * PERCENT + 0.5)
  popup.slider:SetValueSilently(percent, percent .. "%")
  for _, button in ipairs(popupButtons) do button:SetText(L[button.labelKey]) end
  popup.hideButton:SetEnabled(reg.hide ~= nil)
  popup.settingsButton:SetEnabled(reg.settingsPage ~= nil)
  local height = 2 * POPUP_PADDING + 14 + 8 + popup.slider:GetHeight() + 10
    + #popupButtons * (BUTTON_HEIGHT + BUTTON_GAP)
  popup:SetHeight(height)
  popup:ClearAllPoints()
  popup:SetPoint("TOP", overlays[id] or reg.frame, "BOTTOM", 0, -4)
  popup:Show()
end

function EditMode.PopupReg()
  return popup:IsShown() and popupReg or nil
end

---------------------------------------------------------------------------
-- Betreten und Verlassen
---------------------------------------------------------------------------
function EditMode.Enter()
  if active then return true end
  if InCombatLockdown() then
    ns.Print(L.EDIT_MODE_COMBAT)
    return false
  end
  active = true
  ns.Debug("edit", "enter")
  for _, reg in ipairs(Frames.All()) do
    if reg.preview then reg.preview(true) end
    local overlay = overlays[reg.id] or createOverlay(reg)
    paintOverlay(overlay)
    overlay:Show()
  end
  layoutToolbar()
  toolbar:Show()
  toolbar:EnableKeyboard(true)
  updateGrid()
  return true
end

function EditMode.Leave()
  if not active then return end
  active = false
  ns.Debug("edit", "leave")
  selected = nil
  popup:Hide()
  for _, overlay in pairs(overlays) do overlay:Hide() end
  for _, reg in ipairs(Frames.All()) do
    if reg.preview then reg.preview(false) end
  end
  if not InCombatLockdown() then toolbar:EnableKeyboard(false) end
  toolbar:Hide()
  updateGrid()
  ns.ApplySettings()  -- Anzeigen zeigen wieder ihren echten Zustand
end

function EditMode.Toggle()
  if active then EditMode.Leave() else EditMode.Enter() end
end

-- Kampf: Modus sofort beenden (geschützte Rahmen, gesperrte Tastatur-Weitergabe)
ns.RegisterEvent("PLAYER_REGEN_DISABLED", function()
  if not active then return end
  EditMode.Leave()
  ns.Print(L.EDIT_MODE_COMBAT_LEFT)
end)

ns.OnLogout(function() if active then EditMode.Leave() end end)

-- Blizzards Bearbeitungsmodus (Retail, WoW Forever): nur nachhaken, nichts an Blizzards Rahmen ändern
ns.OnLogin(function()
  local manager = EditModeManagerFrame
  if EditMode.blizzardHooked or not manager or not manager.EnterEditMode or not manager.ExitEditMode then return end
  EditMode.blizzardHooked = true
  hooksecurefunc(manager, "EnterEditMode", function()
    if ns.db.editModeWithBlizzard then EditMode.Enter() end
  end)
  hooksecurefunc(manager, "ExitEditMode", function()
    if ns.db.editModeWithBlizzard then EditMode.Leave() end
  end)
end)

-- Sprache oder Akzent gewechselt: offene Flächen und Leiste neu beschriften
ns.RegisterApply(function()
  if not active then return end
  layoutToolbar()
  for _, overlay in pairs(overlays) do
    if overlay:IsShown() then paintOverlay(overlay) end
  end
end)
