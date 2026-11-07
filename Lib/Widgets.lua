-- Gemeinsame UI-Bausteine, damit alle Fenster gleich aussehen und sich gleich verhalten.
local addonName, ns = ...

local Widgets = {}
ns.Widgets = Widgets

-- Eigenes Addon-Icon (Media/Icon.tga, erzeugt mit "make artwork"); auch als IconTexture in der .toc
Widgets.ICON = "Interface\\AddOns\\" .. addonName .. "\\Media\\Icon"

-- Kurznamen für Farben aus Theme.lua (dieselben Tabellen, folgen also dem gewählten Preset)
local Theme = ns.Theme
Widgets.COLORS = {
  background = Theme.COLORS.background,
  border = Theme.COLORS.border,
  highlight = Theme.COLORS.accent,
  muted = Theme.COLORS.muted,  -- Hinweise: lesbar, aber leiser als normaler Text
}

local SLIDER_BACKDROP = {
  bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
  edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 3, right = 3, top = 6, bottom = 6 },
}

local INACTIVE_TAB_COLOR = Theme.COLORS.inactive
local TAB_PADDING = 8
local SECTION_HEADER_HEIGHT = 18
local CLOSE_BUTTON_SIZE = 24
local SCROLLBAR_WIDTH = 8
local SCROLLBAR_THUMB_HEIGHT = 30
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"
Widgets.WHITE_TEXTURE = WHITE_TEXTURE  -- einfarbige Fläche für Hintergründe und Balken

local CHECKBOX_SIZE = 26
Widgets.CHECKBOX_LABEL_GAP = 2  -- Abstand Kästchen zu Beschriftung (Options.lua rechnet damit)
local SLIDER_HEIGHT = 17
local SLIDER_LABEL_HEIGHT = 18

-- Verschiebbares Fenster im Addon-Stil (Ziehen muss der Aufrufer per OnDragStart regeln)
-- Text nur setzen, wenn er sich geändert hat (Anzeigen, die mehrmals pro Sekunde aktualisieren); true = geändert,
-- dann z.B. Breite neu messen. Nur für FontStrings, deren Text ausschließlich hierüber gesetzt wird, sonst stimmt der
-- gemerkte Text nicht mehr. Gemerkt in einer schwachen Tabelle (nicht am Frame, Blizzard-Frames bleiben unberührt).
local shownTexts = setmetatable({}, { __mode = "k" })
function Widgets.SetTextIfChanged(fontString, text)
  if shownTexts[fontString] == text then return false end
  shownTexts[fontString] = text
  fontString:SetText(text)
  return true
end

function Widgets.CreatePanel(name, backgroundAlpha)
  local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
  Theme.RegisterPanel(panel, backgroundAlpha)  -- Grund und Rand im Stil des Themes, auch nach einem Wechsel
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  return panel
end

-- Skaliert einen Frame und hält dabei seine linke obere Ecke auf dem Bildschirm fest.
-- Ankerabstände werden in der Skalierung des Frames gemessen und müssen umgerechnet werden.
function Widgets.SetScaleKeepingTopLeft(frame, scale)
  local oldScale = frame:GetScale()
  local left, top = frame:GetLeft(), frame:GetTop()
  frame:SetScale(scale)
  if left and top then
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * oldScale / scale, top * oldScale / scale)
  end
end

-- Feste Deckkraft eines Fensters im Stil des Themes (z.B. Zusammenfassung ohne Chroma-Grund)
function Widgets.SetDefaultBackground(panel, alpha)
  Theme.RegisterPanel(panel, alpha)
end

-- Tooltip bei Mauskontakt. title() und text() liefern die Texte in der aktuellen Sprache;
-- liefert text() nil, erscheint kein Tooltip. HookScript, damit vorhandene Handler bleiben.
function Widgets.AttachTooltip(frame, title, text)
  frame:HookScript("OnEnter", function(self)
    local body = text()
    if not body then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title(), unpack(Widgets.COLORS.highlight))
    GameTooltip:AddLine(body, 1, 1, 1, true)  -- true = umbrechen
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Checkbox mit eigenem Label, da die Template-Textfelder je nach Client anders heißen
function Widgets.CreateCheckbox(parent, onToggle)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  checkbox.label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", Widgets.CHECKBOX_LABEL_GAP, 0)
  checkbox:SetScript("OnClick", function(self)
    onToggle(self:GetChecked() and true or false)
  end)
  return checkbox
end

-- Slider mit Label (links) und Wertanzeige (rechts). Selbst gebaut, weil
-- OptionsSliderTemplate nicht in allen Clients existiert.
-- Rückgabe ist ein Container; Breite bestimmt der Aufrufer über seine Anker.
function Widgets.CreateSlider(parent, minValue, maxValue, step, onChange)
  local container = CreateFrame("Frame", nil, parent)
  container:SetHeight(SLIDER_LABEL_HEIGHT + SLIDER_HEIGHT)

  container.label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  container.label:SetPoint("TOPLEFT")
  container.valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  container.valueText:SetPoint("TOPRIGHT")

  local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
  slider:SetOrientation("HORIZONTAL")
  slider:SetPoint("BOTTOMLEFT")
  slider:SetPoint("BOTTOMRIGHT")
  slider:SetHeight(SLIDER_HEIGHT)
  slider:SetHitRectInsets(0, 0, -6, -6)
  slider:SetBackdrop(SLIDER_BACKDROP)
  slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  container.slider = slider  -- z.B. für einen Tooltip

  local silent = false
  slider:SetScript("OnValueChanged", function(_, value)
    if silent then return end
    onChange(math.floor(value / step + 0.5) * step)
  end)

  -- Wert setzen, ohne onChange auszulösen (für Anzeige-Updates)
  function container:SetValueSilently(value, displayText)
    silent = true
    slider:SetValue(value)
    silent = false
    self.valueText:SetText(displayText or value)
  end

  return container
end

-- Reiter als schlichter Text-Button; der aktive Reiter ist hervorgehoben
function Widgets.CreateTab(parent, fontObject, onClick)
  local tab = CreateFrame("Button", nil, parent)
  tab.label = tab:CreateFontString(nil, "OVERLAY", fontObject)
  tab.label:SetPoint("CENTER")
  tab:SetScript("OnClick", onClick)

  function tab:SetLabel(text)
    self.label:SetText(text)
    local _, fontHeight = self.label:GetFont()
    self:SetSize(self.label:GetStringWidth() + TAB_PADDING, fontHeight + 4)
  end

  function tab:SetActive(active)
    local color = active and Widgets.COLORS.highlight or INACTIVE_TAB_COLOR
    self.label:SetTextColor(unpack(color))
  end

  return tab
end

-- Flacher Button im Addon-Stil: dunkler Grund mit feinem goldenen Rand; bei Mauskontakt heller Rand und
-- helle Schrift, beim Drücken dunkler. Eigener Text (SetText/GetText/GetTextWidth wie bei Blizzards Button).
local BUTTON_BACKDROP = {
  bgFile = WHITE_TEXTURE,
  edgeFile = WHITE_TEXTURE,
  edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
local BUTTON_COLORS = {
  normal = { background = { 0.11, 0.12, 0.2, 0.95 }, border = { 0.5, 0.38, 0.14, 1 }, text = Widgets.COLORS.highlight },
  hover = { background = { 0.18, 0.19, 0.3, 0.98 }, border = Widgets.COLORS.border, text = { 1, 1, 1 } },
  pressed = { background = { 0.06, 0.07, 0.12, 1 }, border = Widgets.COLORS.border, text = Widgets.COLORS.highlight },
  disabled = { background = { 0.08, 0.08, 0.1, 0.8 }, border = { 0.3, 0.3, 0.3, 1 }, text = { 0.5, 0.5, 0.5 } },
}

function Widgets.CreateButton(parent, width, height, onClick)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(width, height)
  button:SetBackdrop(BUTTON_BACKDROP)
  button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.label:SetPoint("CENTER")

  local hovered, pressed = false, false
  local function paint()
    local colors = BUTTON_COLORS.normal
    if button:IsEnabled() == false then
      colors = BUTTON_COLORS.disabled
    elseif pressed then
      colors = BUTTON_COLORS.pressed
    elseif hovered then
      colors = BUTTON_COLORS.hover
    end
    button:SetBackdropColor(unpack(colors.background))
    button:SetBackdropBorderColor(unpack(colors.border))
    button.label:SetTextColor(unpack(colors.text))
  end
  button:HookScript("OnEnter", function() hovered = true; paint() end)
  button:HookScript("OnLeave", function() hovered, pressed = false, false; paint() end)
  button:HookScript("OnMouseDown", function() pressed = true; paint() end)
  button:HookScript("OnMouseUp", function() pressed = false; paint() end)
  button:HookScript("OnEnable", paint)
  button:HookScript("OnDisable", paint)
  paint()

  function button:SetText(text) self.label:SetText(text) end
  function button:GetText() return self.label:GetText() end
  function button:GetTextWidth() return self.label:GetStringWidth() end
  button:SetScript("OnClick", onClick)
  return button
end

---------------------------------------------------------------------------
-- Verschiebbare Anzeige: speichert die Position, kennt einen Verschiebemodus (Ziehen, Rechtsklick beendet)
-- config = { default = { Punkt, Bezugspunkt, x, y }, get() -> gespeicherte Position oder nil, set(Position oder nil) }
-- Rückgabe: { Restore, Sync, SetScale, SetMoving, IsMoving, Reset }
---------------------------------------------------------------------------
local activeMover  -- der Mover im Verschiebemodus; es gibt höchstens einen

-- Beendet den Verschiebemodus (z.B. beim Schließen der Einstellungen), damit keine Beispielanzeige stehen bleibt
function Widgets.EndMoving()
  if activeMover then activeMover.SetMoving(false) end
end

function Widgets.CreateMover(frame, config)
  local mover = {}
  local moving = false
  local applied  -- zuletzt angewendete Position (Tabelle); ein Profilwechsel liefert eine andere

  function mover.Restore()
    applied = config.get()
    local pos = applied or config.default
    frame:ClearAllPoints()
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
  end

  -- Nur wenn sich die Position seit dem letzten Anwenden geändert hat (z.B. anderes Profil)
  function mover.Sync()
    if config.get() ~= applied then mover.Restore() end
  end

  -- Ankerabstände gelten in der Skalierung des Rahmens: ändert sich die Größe bei stehender Position, umrechnen,
  -- damit er stehen bleibt. Nicht bei der ersten Anwendung nach dem Laden (die gespeicherten Abstände gelten schon
  -- in dieser Größe) und nicht bei einem Profilwechsel (neue Position, neue Größe zusammen gespeichert).
  local scaleApplied = false
  function mover.SetScale(scale)
    local old = frame:GetScale()
    frame:SetScale(scale)
    local pos = config.get()
    if scaleApplied and pos and pos == applied and math.abs(old - scale) > 0.001 then
      pos[3] = pos[3] * old / scale
      pos[4] = pos[4] * old / scale
      mover.Restore()
    end
    scaleApplied = true
  end

  function mover.IsMoving() return moving end

  function mover.SetMoving(enabled)
    moving = enabled and true or false
    if moving then
      if activeMover and activeMover ~= mover then activeMover.SetMoving(false) end
      activeMover = mover
    elseif activeMover == mover then
      activeMover = nil
    end
    frame:EnableMouse(moving)
    if config.onMovingChanged then config.onMovingChanged(moving) end
  end

  function mover.Reset()
    config.set(nil)
    mover.Restore()
  end

  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if moving then self:StartMoving() end
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    local pos = { point, relativePoint, x, y }
    config.set(pos)
    applied = pos
  end)
  frame:SetScript("OnMouseUp", function(_, mouseButton)
    if moving and mouseButton == "RightButton" then mover.SetMoving(false) end
  end)
  return mover
end

---------------------------------------------------------------------------
-- Ziehgriff unten rechts: der Abstand der Maus zum Start bestimmt die neue Skalierung des Frames
-- (linke obere Ecke bleibt stehen). clamp(scale) begrenzt, onDone(scale) speichert beim Loslassen.
-- Sichtbar nur bei Mauskontakt mit dem Frame oder während des Ziehens (grip:UpdateAlpha im OnUpdate).
---------------------------------------------------------------------------
local GRIP_SIZE = 14

local function cursorPosition()
  local x, y = GetCursorPosition()
  local uiScale = UIParent:GetEffectiveScale()
  return x / uiScale, y / uiScale
end

function Widgets.CreateResizeGrip(frame, clamp, onDone)
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(GRIP_SIZE, GRIP_SIZE)
  grip:SetPoint("BOTTOMRIGHT", -3, 3)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

  local start  -- beim Drücken: Mausposition, Größe auf dem Bildschirm, Skalierung

  -- Mittel aus horizontaler und vertikaler Vergrößerung, damit diagonales Ziehen natürlich wirkt
  local function onUpdate()
    local x, y = cursorPosition()
    local widthFactor = (start.width + x - start.x) / start.width
    local heightFactor = (start.height + start.y - y) / start.height
    Widgets.SetScaleKeepingTopLeft(frame, clamp(start.scale * (widthFactor + heightFactor) / 2))
  end

  grip:SetScript("OnMouseDown", function(self)
    local x, y = cursorPosition()
    local scale = frame:GetScale()
    start = { x = x, y = y, width = frame:GetWidth() * scale, height = frame:GetHeight() * scale, scale = scale }
    self:SetScript("OnUpdate", onUpdate)
  end)

  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    start = nil
    onDone(frame:GetScale())
  end)

  function grip:UpdateAlpha()
    self:SetAlpha((frame:IsMouseOver() or start) and 1 or 0)
  end

  return grip
end

local BUTTON_TEXT_PADDING = 24  -- Rand links und rechts zusammen

-- Text setzen und den Button mindestens so breit machen, dass er hineinpasst (übersetzte Texte sind
-- unterschiedlich lang); minWidth bleibt die kleinste Breite
function Widgets.SetButtonText(button, text, minWidth)
  button:SetText(text)
  button:SetWidth(math.max(minWidth, math.ceil(button:GetTextWidth()) + BUTTON_TEXT_PADDING))
end

-- Abschnitts-Überschrift: Text mit feiner Linie bis zum rechten Rand
function Widgets.CreateSectionHeader(parent)
  local header = CreateFrame("Frame", nil, parent)
  header:SetHeight(SECTION_HEADER_HEIGHT)

  header.label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  header.label:SetPoint("LEFT")

  local line = header:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("LEFT", header.label, "RIGHT", 6, 0)
  line:SetPoint("RIGHT")
  local r, g, b = unpack(Widgets.COLORS.border)
  line:SetColorTexture(r, g, b, 0.6)

  function header:SetText(text)
    self.label:SetText(text)
  end

  return header
end

-- Schließen-Knopf oben rechts, kleiner als die Vorlage, damit er nicht über den Rand ragt
function Widgets.CreateCloseButton(panel)
  local button = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  button:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
  button:SetPoint("TOPRIGHT", -4, -4)
  return button
end

-- Schmale senkrechte Bildlaufleiste im Addon-Stil (die Vorlage sieht je nach Client anders aus).
-- onScroll(offset) wird nur bei Benutzereingabe aufgerufen, Werte sind ganze Zeilen.
function Widgets.CreateScrollBar(parent, onScroll)
  local bar = CreateFrame("Slider", nil, parent, "BackdropTemplate")
  bar:SetOrientation("VERTICAL")
  bar:SetWidth(SCROLLBAR_WIDTH)
  bar:SetBackdrop({ bgFile = WHITE_TEXTURE })
  bar:SetBackdropColor(1, 1, 1, 0.08)

  local thumb = bar:CreateTexture(nil, "OVERLAY")
  local r, g, b = unpack(Widgets.COLORS.border)
  thumb:SetColorTexture(r, g, b, 0.9)
  thumb:SetSize(SCROLLBAR_WIDTH, SCROLLBAR_THUMB_HEIGHT)
  bar:SetThumbTexture(thumb)

  bar:SetMinMaxValues(0, 0)
  bar:SetValueStep(1)
  if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end

  local silent = false
  bar:SetScript("OnValueChanged", function(_, value)
    if not silent then onScroll(math.floor(value + 0.5)) end
  end)

  -- Bereich 0..maxOffset; ohne etwas zu scrollen wird die Leiste ausgeblendet
  function bar:SetRange(maxOffset)
    silent = true
    self:SetMinMaxValues(0, maxOffset)
    silent = false
    self:SetShown(maxOffset > 0)
  end

  function bar:SetOffsetSilently(offset)
    silent = true
    self:SetValue(offset)
    silent = false
  end

  return bar
end
