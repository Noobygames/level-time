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
local WHITE_TEXTURE = Theme.WHITE_TEXTURE
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

-- Nach einem SetText an SetTextIfChanged vorbei (z.B. Breite messen): der nächste SetTextIfChanged setzt sicher
function Widgets.ForgetText(fontString)
  shownTexts[fontString] = nil
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

-- Reiter als schlichter Text-Button; der aktive Reiter ist hervorgehoben: Farbe und Unterstrich (UX 216, damit er
-- sich nicht nur durch die Farbe unterscheidet)
local TAB_UNDERLINE_HEIGHT = 1
local TAB_UNDERLINE_INSET = 2

function Widgets.CreateTab(parent, fontObject, onClick)
  local tab = CreateFrame("Button", nil, parent)
  tab.label = tab:CreateFontString(nil, "OVERLAY", fontObject)
  tab.label:SetPoint("CENTER")
  tab:SetScript("OnClick", onClick)
  tab.underline = tab:CreateTexture(nil, "OVERLAY")
  tab.underline:SetHeight(TAB_UNDERLINE_HEIGHT)
  tab.underline:SetPoint("TOPLEFT", tab.label, "BOTTOMLEFT", 0, -TAB_UNDERLINE_INSET)
  tab.underline:SetPoint("TOPRIGHT", tab.label, "BOTTOMRIGHT", 0, -TAB_UNDERLINE_INSET)
  tab.underline:Hide()

  function tab:SetLabel(text)
    self.label:SetText(text)
    local _, fontHeight = self.label:GetFont()
    self:SetSize(self.label:GetStringWidth() + TAB_PADDING, fontHeight + 4)
  end

  function tab:SetActive(active)
    local color = active and Widgets.COLORS.highlight or INACTIVE_TAB_COLOR
    self.label:SetTextColor(unpack(color))
    local r, g, b = unpack(Widgets.COLORS.highlight)
    self.underline:SetColorTexture(r, g, b, 1)
    self.underline:SetShown(active and true or false)
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
-- Farben aus dem Theme (Tokens werden beim Preset-Wechsel an Ort und Stelle geändert), Deckkraft je Zustand
local C = Theme.COLORS
local BUTTON_COLORS = {
  normal = { background = C.buttonFace, alpha = 0.95, border = C.buttonBorder, text = C.accent },
  hover = { background = C.buttonFaceHover, alpha = 0.98, border = C.border, text = C.text },
  pressed = { background = C.buttonFacePressed, alpha = 1, border = C.border, text = C.accent },
  disabled = { background = C.buttonFaceDisabled, alpha = 0.8, border = C.buttonBorderDisabled, text = C.buttonTextDisabled },
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
    local face, border = colors.background, colors.border
    button:SetBackdropColor(face[1], face[2], face[3], colors.alpha)
    button:SetBackdropBorderColor(border[1], border[2], border[3], 1)
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
Widgets.BUTTON_TEXT_PADDING = BUTTON_TEXT_PADDING  -- auch für Breitenrechnungen anderer Module (OptionsBuilder)

-- Text setzen und den Button mindestens so breit machen, dass er hineinpasst (übersetzte Texte sind
-- unterschiedlich lang); minWidth bleibt die kleinste Breite
function Widgets.SetButtonText(button, text, minWidth)
  button:SetText(text)
  button:SetWidth(math.max(minWidth, math.ceil(button:GetTextWidth()) + BUTTON_TEXT_PADDING))
end

-- Rückfrage Ja/Nein über StaticPopup, Text aus L[textKey] in der Sprache zur Anzeigezeit (Roadmap 218).
-- Rückgabe: show(textArg, data); onAccept(data) bekommt data aus show
function Widgets.ConfirmPopup(name, textKey, onAccept)
  StaticPopupDialogs[name] = {
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(_, data) onAccept(data) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- eigener Platz, kollidiert nicht mit Blizzard-Dialogen
  }
  return function(textArg, data)
    StaticPopupDialogs[name].text = ns.L[textKey]
    StaticPopup_Show(name, textArg, nil, data)
  end
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

-- Erster sichtbarer Index einer Liste mit Grenzen: 0 bis total - visible (nie negativ)
function Widgets.ClampOffset(offset, total, visible)
  return math.max(0, math.min(offset, total - visible))
end

-- Bildlaufbereich in Pixeln (ScrollFrame) mit Mausrad und Grenzen. options = { step = Pixel je Raste,
-- top = kleinster Bildlauf (Standard 0; negativ, wenn der Inhalt ruhend verschoben steht),
-- keepInRange = true: wird der Inhalt kürzer, rückt der Bildlauf in den gültigen Bereich }.
-- area:ScrollTo(y) setzt den Bildlauf begrenzt auf top..GetVerticalScrollRange().
function Widgets.CreateScrollArea(parent, options)
  local top = options.top or 0
  local area = CreateFrame("ScrollFrame", nil, parent)

  function area:ScrollTo(y)
    self:SetVerticalScroll(math.max(top, math.min(self:GetVerticalScrollRange(), y)))
  end

  area:EnableMouseWheel(true)
  area:SetScript("OnMouseWheel", function(self, delta)
    self:ScrollTo(self:GetVerticalScroll() - delta * options.step)
  end)
  if options.keepInRange then
    area:SetScript("OnScrollRangeChanged", function(self, _, yRange)
      self:SetVerticalScroll(math.max(top, math.min(yRange, self:GetVerticalScroll())))
    end)
  end
  return area
end
