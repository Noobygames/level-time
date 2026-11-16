-- Gemeinsame UI-Bausteine, damit alle Fenster gleich aussehen und sich gleich verhalten.
local addonName, ns = ...

local Widgets = {}
ns.Widgets = Widgets

-- Eigenes Addon-Icon (Media/Icon.tga, erzeugt mit "make artwork"); auch als IconTexture in der .toc
Widgets.ICON = "Interface\\AddOns\\" .. addonName .. "\\Media\\Icon"

-- Symbol eines Zaubers (C_Spell.GetSpellTexture, ältere Clients GetSpellTexture); nil ohne Treffer oder bei geheimer ID
function Widgets.SpellTexture(spellID)
  if not spellID or ns.IsSecret(spellID) then return nil end
  local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
  if not texture and GetSpellTexture then texture = GetSpellTexture(spellID) end
  return texture
end

-- Client-Symbol auf eine Textur setzen: source = Atlasname oder Pfad (Interface\Icons\...); size 16/20/24.
-- Unbekannter Atlas (nicht in jedem Client vorhanden) oder leere Quelle: Textur versteckt, false zurück (Fallback ohne Icon).
-- Ein Icon steht nie allein: immer neben Text oder mit Tooltip.
function Widgets.SetIcon(texture, source, size)
  local ok = type(source) == "string" and source ~= ""
  if ok and not source:find("[\\/]") then
    ok = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(source) and true or false
    if ok then texture:SetAtlas(source) end
  elseif ok then
    texture:SetTexture(source)
  end
  if size then texture:SetSize(size, size) end
  texture:SetShown(ok)
  return ok
end

-- Rangzahl eines Zaubers als Text aus C_Spell.GetSpellSubtext (Era, Retail, Forever laut SpellDocumentation; ältere
-- Clients GetSpellSubtext), in Classic "Rang 3". Retail-Untertexte ("Volksfähigkeit", "Passiv") haben keine Zahl: nil.
function Widgets.SpellRank(spellID)
  local getSubtext = C_Spell and C_Spell.GetSpellSubtext or GetSpellSubtext
  if type(getSubtext) ~= "function" then return nil end
  local ok, subtext = pcall(getSubtext, spellID)
  if not ok or ns.IsSecret(subtext) or type(subtext) ~= "string" then return nil end
  return (subtext:match("%d+"))
end

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
Widgets.CHECKBOX_LABEL_GAP = 2  -- Abstand Kästchen zu Beschriftung (UI/Options rechnet damit)
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

-- Item-Links in den Texten eines Frames: Tooltip beim Überfahren, Shift-Klick wie überall (Frame:SetHyperlinksEnabled,
-- SimpleFrameAPI in allen Zweigen). onLeave(frame) optional statt Tooltip ausblenden.
function Widgets.EnableItemLinks(frame, onLeave)
  if not frame.SetHyperlinksEnabled then return end
  frame:SetHyperlinksEnabled(true)
  frame:SetScript("OnHyperlinkEnter", function(self, link)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
  end)
  frame:SetScript("OnHyperlinkLeave", onLeave or function() GameTooltip:Hide() end)
  frame:SetScript("OnHyperlinkClick", function(_, link, text, button)
    if HandleModifiedItemClick and HandleModifiedItemClick(text) then return end
    if SetItemRef then SetItemRef(link, text, button) end
  end)
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
    if button.primary and colors == BUTTON_COLORS.normal then border = C.gold end
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

  -- Primärvariante: goldener Rand im Ruhezustand (ein Primärbutton je Fenster, rechts unten)
  function button:SetPrimary(on)
    self.primary = on and true or false
    paint()
  end
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
-- Rückgabe: show(textArg, data, textArg2); onAccept(data) bekommt data aus show, textArg2 = zweiter Platzhalter
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
  return function(textArg, data, textArg2)
    StaticPopupDialogs[name].text = ns.L[textKey]
    StaticPopup_Show(name, textArg, textArg2, data)
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

---------------------------------------------------------------------------
-- Bausteine nach docs/clickdummy/DESIGN.md; alle Farben aus Theme.COLORS (per Name), keine eigenen Werte
---------------------------------------------------------------------------
local HEADER_HEIGHT = 40
local HEADER_PADDING = 16
local CHIP_HEIGHT = 28
local ROW_HEIGHT = 32
local STATUS_DOT_SIZE = 8
local BAR_HEIGHTS = { small = 6, medium = 12, large = 24 }
Widgets.BAR_HEIGHTS = BAR_HEIGHTS

local function setTextureColor(texture, colorName, alpha)
  local r, g, b = Theme.RGB(colorName)
  texture:SetColorTexture(r, g, b, alpha or 1)
end

-- Fensterkopf (Höhe 40): Titel links in Gold (header.title), rechts der Schließen-Knopf (header.close, 24 x 24),
-- links davon der Platz für Aktionen (header.actions, Frame; der Aufrufer hängt Buttons mit SetPoint("RIGHT") an),
-- unten der Trenner. opts.onClose ersetzt das Verstecken von parent beim Schließen.
function Widgets.CreateWindowHeader(parent, title, opts)
  opts = opts or {}
  local header = CreateFrame("Frame", nil, parent)
  header:SetHeight(HEADER_HEIGHT)
  header:SetPoint("TOPLEFT")
  header:SetPoint("TOPRIGHT")
  header.title = header:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
  header.title:SetPoint("LEFT", HEADER_PADDING, 0)
  header.title:SetText(title or "")
  header.close = Widgets.CreateCloseButton(header)
  header.close:ClearAllPoints()
  header.close:SetPoint("RIGHT", -8, 0)
  header.close:SetScript("OnClick", opts.onClose or function() parent:Hide() end)
  header.actions = CreateFrame("Frame", nil, header)
  header.actions:SetPoint("TOPRIGHT", header.close, "TOPLEFT", -8, 0)
  header.actions:SetPoint("BOTTOMRIGHT", header.close, "BOTTOMLEFT", -8, 0)
  header.actions:SetWidth(1)
  header.divider = header:CreateTexture(nil, "ARTWORK")
  header.divider:SetHeight(1)
  header.divider:SetPoint("BOTTOMLEFT")
  header.divider:SetPoint("BOTTOMRIGHT")
  setTextureColor(header.divider, "divider")
  function header:SetTitle(text) self.title:SetText(text) end
  -- Icon links vor dem Titel (Widgets.SetIcon); ohne Treffer bleibt der Titel an seinem Platz
  function header:SetIcon(source)
    self.titleIcon = rawget(self, "titleIcon") or self:CreateTexture(nil, "ARTWORK")
    self.titleIcon:SetPoint("LEFT", HEADER_PADDING, 0)
    local shown = Widgets.SetIcon(self.titleIcon, source, 20)
    self.title:ClearAllPoints()
    self.title:SetPoint("LEFT", HEADER_PADDING + (shown and 26 or 0), 0)
  end
  return header
end

-- Chip (Filter an / aus): chip:SetOn(bool), chip:IsOn(); Klick kippt den Zustand und ruft onToggle(on).
-- Die Breite folgt dem Text (chip:SetText).
function Widgets.CreateChip(parent, label, onToggle)
  local chip = CreateFrame("Button", nil, parent, "BackdropTemplate")
  chip:SetHeight(CHIP_HEIGHT)
  chip:SetBackdrop(BUTTON_BACKDROP)
  chip.label = chip:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
  chip.label:SetPoint("CENTER")
  chip.on, chip.hovered = false, false
  local function paint()
    local face = chip.on and C.rowSelected or (chip.hovered and C.buttonFaceHover or C.buttonFace)
    local border = chip.on and C.gold or C.buttonBorder
    chip:SetBackdropColor(face[1], face[2], face[3], 0.95)
    chip:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    chip.label:SetTextColor(unpack(chip.on and C.gold or C.text))
  end
  function chip:SetOn(on)
    self.on = on and true or false
    paint()
  end
  function chip:IsOn() return self.on end
  function chip:SetText(text)
    self.label:SetText(text)
    self:SetWidth(math.ceil(self.label:GetStringWidth()) + BUTTON_TEXT_PADDING)
  end
  chip:HookScript("OnEnter", function() chip.hovered = true; paint() end)
  chip:HookScript("OnLeave", function() chip.hovered = false; paint() end)
  chip:SetScript("OnClick", function()
    chip:SetOn(not chip.on)
    if onToggle then onToggle(chip.on) end
  end)
  chip:SetText(label or "")
  paint()
  return chip
end

-- Listenzeile (Höhe 32 oder height) mit Hover- und Auswahlgrund; row.text links; row:SetSelected(bool),
-- row:IsSelected(). Den Klick setzt der Aufrufer (SetScript("OnClick")).
function Widgets.CreateListRow(parent, height)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(height or ROW_HEIGHT)
  row.background = row:CreateTexture(nil, "BACKGROUND")
  row.background:SetAllPoints()
  row.text = row:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  row.text:SetPoint("LEFT", 8, 0)
  row.text:SetPoint("RIGHT", -8, 0)
  row.text:SetJustifyH("LEFT")
  row.selected, row.hovered = false, false
  local function paint()
    if row.selected then
      setTextureColor(row.background, "rowSelected")
    elseif row.hovered then
      setTextureColor(row.background, "buttonFaceHover", 0.6)
    else
      row.background:SetColorTexture(0, 0, 0, 0)
    end
  end
  function row:SetSelected(selected)
    self.selected = selected and true or false
    paint()
  end
  function row:IsSelected() return self.selected end
  row:HookScript("OnEnter", function() row.hovered = true; paint() end)
  row:HookScript("OnLeave", function() row.hovered = false; paint() end)
  paint()
  return row
end

-- Label-Wert-Zeile: Label links (Farbe labelText), Wert rechts hell; line:SetValues(label, value[, colorName])
function Widgets.CreateLabelValue(parent)
  local line = CreateFrame("Frame", nil, parent)
  line:SetHeight(ROW_HEIGHT)
  line.label = line:CreateFontString(nil, "OVERLAY", Theme.Font("label"))
  line.label:SetPoint("LEFT")
  line.label:SetTextColor(Theme.RGB("labelText"))
  line.value = line:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  line.value:SetPoint("RIGHT")
  line.value:SetJustifyH("RIGHT")
  line.value:SetTextColor(Theme.RGB("text"))
  function line:SetValues(label, value, colorName)
    self.label:SetText(label)
    self.value:SetText(value)
    self.value:SetTextColor(Theme.RGB(colorName or "text"))
  end
  return line
end

-- Statuspunkt (8 px) in einer Statusfarbe (good/bad/warning/info/muted ...); dot:SetStatus(colorName).
-- Farbe nie allein: neben Text verwenden (CreateBadge)
function Widgets.CreateStatusDot(parent, colorName)
  local dot = parent:CreateTexture(nil, "OVERLAY")
  dot:SetSize(STATUS_DOT_SIZE, STATUS_DOT_SIZE)
  function dot:SetStatus(name) setTextureColor(self, name) end
  dot:SetStatus(colorName or "muted")
  return dot
end

-- Badge: Statuspunkt plus Text; badge:SetStatus(colorName, text)
function Widgets.CreateBadge(parent, text, colorName)
  local badge = CreateFrame("Frame", nil, parent)
  badge:SetHeight(CHIP_HEIGHT)
  badge.dot = Widgets.CreateStatusDot(badge, colorName)
  badge.dot:SetPoint("LEFT")
  badge.text = badge:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
  badge.text:SetPoint("LEFT", badge.dot, "RIGHT", 4, 0)
  function badge:SetStatus(name, newText)
    self.dot:SetStatus(name)
    if newText then self.text:SetText(newText) end
    self:SetWidth(STATUS_DOT_SIZE + 4 + math.ceil(self.text:GetStringWidth()))
  end
  badge:SetStatus(colorName or "muted", text or "")
  return badge
end

-- Fortschrittsbalken in drei Höhen (size "small" 6, "medium" 12, "large" 24; Standard medium);
-- bar:SetProgress(0..1, colorName), bar:GetProgress()
function Widgets.CreateProgressBar(parent, size)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetHeight(BAR_HEIGHTS[size or "medium"] or BAR_HEIGHTS.medium)
  bar:SetMinMaxValues(0, 1)
  bar.background = bar:CreateTexture(nil, "BACKGROUND")
  bar.background:SetAllPoints()
  setTextureColor(bar.background, "buttonFace")
  bar.fill = bar:CreateTexture(nil, "ARTWORK")
  bar:SetStatusBarTexture(bar.fill)
  bar.progress = 0
  function bar:SetProgress(fraction, colorName)
    self.progress = math.max(0, math.min(1, fraction or 0))
    self:SetValue(self.progress)
    Theme.SetBarTexture(self.fill, Theme.RGB(colorName or "accent"))
  end
  function bar:GetProgress() return self.progress end
  bar:SetProgress(0)
  return bar
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
