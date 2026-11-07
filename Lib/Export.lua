-- Export: Tabellen als CSV in einem Fenster zum Kopieren (Strg+C); Addons dürfen nicht in Dateien schreiben.
-- Dasselbe Fenster dient zum Import (Text einfügen, Button "Importieren"), z.B. für geteilte Läufe.
-- Export.New(host) baut ein eigenes Fenster (host = { name = globaler Rahmenname, L = Texte, print(message) });
-- ns.Export selbst ist das Fenster von Level Time (LevelTimerExport).
local _, ns = ...
local Widgets = ns.Widgets

local Export = {}
ns.Export = Export

local WIDTH = 520
local HEIGHT = 340
local MARGIN = 16
local TEXT_TOP = -44
local WHEEL_STEP = 40  -- Pixel pro Mausrad-Raste
local IMPORT_BUTTON_WIDTH = 110
local IMPORT_BUTTON_HEIGHT = 22

-- Feld für CSV aufbereiten: in Anführungszeichen, wenn es Trennzeichen, Anführungszeichen oder Umbrüche enthält
local function csvField(value, separator)
  local text = tostring(value or "")
  if text:find(separator, 1, true) or text:find('"', 1, true) or text:find("\n", 1, true) then
    text = '"' .. text:gsub('"', '""') .. '"'
  end
  return text
end

-- headers = { "Spalte", ... }, rows = { { "Wert", ... }, ... }
function Export.ToCsv(headers, rows, separator)
  local lines = {}
  local function addLine(fields)
    local escaped = {}
    for i, field in ipairs(fields) do
      escaped[i] = csvField(field, separator)
    end
    table.insert(lines, table.concat(escaped, separator))
  end
  addLine(headers)
  for _, row in ipairs(rows) do
    addLine(row)
  end
  return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
function Export.New(host)
  local L = host.L
  local window = {}

  local panel = Widgets.CreatePanel(host.name, 0.95)
  panel:SetSize(WIDTH, HEIGHT)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("FULLSCREEN_DIALOG")  -- über der Historie
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  panel:Hide()
  table.insert(UISpecialFrames, host.name)  -- mit ESC schließen

  Widgets.CreateCloseButton(panel)

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -14)

  local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", MARGIN, MARGIN - 4)

  local scrollFrame = CreateFrame("ScrollFrame", nil, panel)
  scrollFrame:SetPoint("TOPLEFT", MARGIN, TEXT_TOP)
  scrollFrame:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN + IMPORT_BUTTON_HEIGHT)

  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetWidth(WIDTH - 2 * MARGIN)
  editBox:SetScript("OnEscapePressed", function() panel:Hide() end)
  scrollFrame:SetScrollChild(editBox)

  -- Ein leeres mehrzeiliges Eingabefeld ist nur eine Zeile hoch: ein Klick in den freien Bereich darunter
  -- würde es nicht treffen, und Strg+V ginge ins Leere. Daher fokussiert jeder Klick in den Textbereich.
  scrollFrame:EnableMouse(true)
  scrollFrame:SetScript("OnMouseDown", function() editBox:SetFocus() end)

  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local offset = self:GetVerticalScroll() - delta * WHEEL_STEP
    self:SetVerticalScroll(math.max(0, math.min(offset, self:GetVerticalScrollRange())))
  end)

  -- Import: onImport(text) liefert eine Meldung und ob der Text übernommen wurde
  local onImport
  local importButton = Widgets.CreateButton(panel, IMPORT_BUTTON_WIDTH, IMPORT_BUTTON_HEIGHT, function()
    local message, imported = onImport(editBox:GetText())
    host.print(message)
    if imported then panel:Hide() end
  end)
  importButton:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN - 8)

  -- Text anzeigen, markieren und fokussieren, damit Strg+C sofort kopiert
  function window.Show(heading, text)
    title:SetText(heading)
    hint:SetText(L.EXPORT_HINT)
    importButton:Hide()
    editBox:SetText(text)
    panel:Show()
    editBox:SetFocus()
    editBox:HighlightText()
  end

  -- Leeres Feld zum Einfügen (Strg+V) und Button zum Übernehmen
  function window.ShowImport(heading, importText)
    onImport = importText
    title:SetText(heading)
    hint:SetText(L.IMPORT_HINT)
    importButton:SetText(L.IMPORT)
    importButton:Show()
    editBox:SetText("")
    panel:Show()
    editBox:SetFocus()
  end

  return window
end

-- Fenster von Level Time
local default = Export.New({ name = ns.GlobalName("Export"), L = ns.L, print = function(message) ns.Print(message) end })
Export.Show = default.Show
Export.ShowImport = default.ShowImport
