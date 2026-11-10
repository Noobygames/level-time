-- Auswahlliste mit Suche (Roadmap 477): eigenes Widget aus Frames, Buttons und einem EditBox, damit sie in allen Clients
-- (Retail, Classic Era, Anniversary, WoW Forever) gleich aussieht und sich gleich verhält (kein UIDropDownMenu/MenuUtil).
-- Es gibt genau eine Liste, die beim Öffnen an den auslösenden Knopf gehängt wird; die Zeilen sind ein fester Pool
-- (nur die sichtbaren, Mausrad und Pfeiltasten verschieben den Ausschnitt), es gibt weder OnUpdate noch ScrollFrame.
--   Dropdown.Open(anchor, { entries = { { key, text, group = Überschrift, font = Schriftpfad } }, current = key,
--     onPick(key) })
-- Ab SEARCH_MIN_ENTRIES Einträgen steht oben ein Suchfeld: Tippen filtert, Enter wählt den Treffer unter der
-- Markierung (zuerst der erste), Pfeil hoch/runter bewegt sie über die Einträge (Überschriften werden übersprungen).
-- Schließen: Auswahl, Esc im Suchfeld, Klick daneben (durchsichtige Fläche unter der Liste) oder Verbergen des Knopfs.
local _, ns = ...
local Theme = ns.Theme

local Dropdown = {}
ns.Dropdown = Dropdown

Dropdown.SEARCH_MIN_ENTRIES = 8
local MAX_ROWS = 10           -- so viele Zeilen sind höchstens zugleich zu sehen, der Rest scrollt
local ROW_HEIGHT = 20
local PADDING = 6
local SEARCH_HEIGHT = 22
local MIN_WIDTH = 120
local MAX_WIDTH = 360
local TEXT_PADDING = 28       -- Rand der Zeilen links/rechts plus Platz für die Bildlaufleiste
local SCROLLBAR_WIDTH = 4
local WHEEL_STEP = 3          -- Zeilen je Mausrad-Raste
local POPUP_STRATA = "FULLSCREEN_DIALOG"
local POPUP_LEVEL = 20
local HOVER_ALPHA = 0.25
local FONT_SIZE = 12
local SCREEN_MARGIN = 8       -- so viel Platz bleibt zum Bildschirmrand

-- Akzente für die Suche: "é" findet "e" (und umgekehrt), Groß-/Kleinschreibung egal
local ACCENTS = {
  ["ä"] = "a", ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["å"] = "a",
  ["ë"] = "e", ["è"] = "e", ["é"] = "e", ["ê"] = "e",
  ["ï"] = "i", ["ì"] = "i", ["í"] = "i", ["î"] = "i",
  ["ö"] = "o", ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o",
  ["ü"] = "u", ["ù"] = "u", ["ú"] = "u", ["û"] = "u",
  ["ç"] = "c", ["ñ"] = "n", ["ß"] = "ss",
  ["Ä"] = "a", ["Ö"] = "o", ["Ü"] = "u", ["É"] = "e", ["È"] = "e", ["À"] = "a", ["Ç"] = "c", ["Ñ"] = "n",
}

local function normalize(text)
  text = tostring(text or "")
  for accented, plain in pairs(ACCENTS) do text = text:gsub(accented, plain) end
  return text:lower()
end
Dropdown.Normalize = normalize

local popup, catcher, search, scrollbar, thumb, measure
local rows = {}
local spec                  -- laufende Auswahl: entries, current, onPick, anchor
local visible = {}          -- gefilterte Zeilen: { header = Text } oder { entry, selected }
local offset = 0            -- Index der ersten sichtbaren Zeile in visible
local highlighted           -- Index in visible der markierten Zeile (nur Einträge)
local isSearchable = false
local hookedAnchors = setmetatable({}, { __mode = "k" })  -- Knöpfe mit OnHide-Haken

local function rowCount()
  return math.min(MAX_ROWS, #visible)
end

local function isEntry(index)
  return visible[index] ~= nil and visible[index].entry ~= nil
end

local function colors()
  return Theme.COLORS
end

local function setRowFont(row, font)
  if font then
    local ok, applied = pcall(row.label.SetFont, row.label, font, FONT_SIZE, "")
    if ok and applied ~= false then return end
  end
  row.label:SetFontObject("GameFontHighlight")
end

local function paintRows()
  local palette = colors()
  for position = 1, MAX_ROWS do
    local row = rows[position]
    local item = visible[offset + position]
    if row then
      if not item or position > rowCount() then
        row:Hide()
      else
        row:Show()
        row.index = offset + position
        if item.header then
          row.label:SetFontObject("GameFontNormalSmall")
          row.label:SetText(item.header)
          row.label:SetTextColor(unpack(palette.muted))
          row.highlight:Hide()
          row:EnableMouse(false)
        else
          setRowFont(row, item.entry.font)
          row.label:SetText(item.entry.text)
          local color = item.selected and palette.accent or palette.text
          row.label:SetTextColor(color[1], color[2], color[3])
          row.highlight:SetShown(row.index == highlighted)
          row:EnableMouse(true)
        end
      end
    end
  end
  -- Bildlaufleiste: nur, wenn mehr Zeilen da sind als sichtbar
  local total = #visible
  local show = total > MAX_ROWS
  scrollbar:SetShown(show)
  if show then
    local height = scrollbar:GetHeight()
    local thumbHeight = math.max(8, height * MAX_ROWS / total)
    thumb:SetHeight(thumbHeight)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", scrollbar, "TOP", 0, -(height - thumbHeight) * offset / (total - MAX_ROWS))
  end
end

-- Zeile so scrollen, dass sie zu sehen ist
local function reveal(index)
  if index < offset + 1 then offset = index - 1 end
  if index > offset + MAX_ROWS then offset = index - MAX_ROWS end
  offset = math.max(0, math.min(offset, math.max(0, #visible - MAX_ROWS)))
end

local function move(step)
  local index = highlighted or 0
  repeat
    index = index + step
  until index < 1 or index > #visible or isEntry(index)
  if isEntry(index) then
    highlighted = index
    reveal(index)
    paintRows()
  end
end

local function firstEntryIndex()
  for index = 1, #visible do
    if isEntry(index) then return index end
  end
end

-- Zeilen aus den Einträgen und dem Suchtext; Gruppenüberschrift nur, wenn ein Eintrag der Gruppe passt
local function filter(query)
  query = normalize(query):gsub("^%s+", ""):gsub("%s+$", "")
  visible = {}
  local lastGroup
  for _, entry in ipairs(spec.entries) do
    if query == "" or entry.search:find(query, 1, true) then
      if entry.group and entry.group ~= lastGroup then table.insert(visible, { header = entry.group }) end
      lastGroup = entry.group
      table.insert(visible, { entry = entry, selected = entry.key == spec.current })
    end
  end
  if #visible == 0 then table.insert(visible, { header = spec.emptyText or "" }) end
end

function Dropdown.Close()
  if not popup or not popup:IsShown() then return end
  popup:Hide()
  catcher:Hide()
  search:ClearFocus()
  spec = nil
end

local function pick(index)
  local item = visible[index]
  if not spec or not item or not item.entry then return end
  local onPick, key = spec.onPick, item.entry.key
  Dropdown.Close()
  onPick(key)
end

local function createRow(position)
  local row = CreateFrame("Button", nil, popup)
  row:SetHeight(ROW_HEIGHT)
  row.highlight = row:CreateTexture(nil, "BACKGROUND")
  row.highlight:SetAllPoints()
  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.label:SetPoint("LEFT", 6, 0)
  row.label:SetPoint("RIGHT", -2, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)
  row:SetScript("OnClick", function(self) pick(self.index) end)
  row:SetScript("OnEnter", function(self)
    if isEntry(self.index) and highlighted ~= self.index then
      highlighted = self.index
      paintRows()
    end
  end)
  rows[position] = row
  return row
end

local function create()
  catcher = CreateFrame("Frame", nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:SetFrameStrata(POPUP_STRATA)
  catcher:SetFrameLevel(POPUP_LEVEL - 1)
  catcher:EnableMouse(true)
  catcher:EnableMouseWheel(true)
  catcher:SetScript("OnMouseDown", Dropdown.Close)
  catcher:SetScript("OnMouseWheel", function() end)  -- das Optionsfenster dahinter scrollt nicht mit
  catcher:Hide()

  popup = CreateFrame("Frame", "LevelTimerDropdown", UIParent, "BackdropTemplate")
  popup:SetFrameStrata(POPUP_STRATA)
  popup:SetFrameLevel(POPUP_LEVEL)
  popup:SetClampedToScreen(true)
  popup:EnableMouse(true)
  popup:EnableMouseWheel(true)
  Theme.RegisterPanel(popup, 1)
  popup:Hide()
  popup:SetScript("OnMouseWheel", function(_, delta)
    offset = math.max(0, math.min(offset - delta * WHEEL_STEP, math.max(0, #visible - MAX_ROWS)))
    paintRows()
  end)

  search = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
  search:SetAutoFocus(false)
  search:SetHeight(SEARCH_HEIGHT)
  search:SetScript("OnTextChanged", function(self, userInput)
    if not userInput or not spec then return end
    if isSearchable then
      filter(self:GetText())
      highlighted = firstEntryIndex()
      offset = 0
      paintRows()
    else
      self:SetText("")  -- ohne Suchfeld nimmt der unsichtbare Fokus nur Tasten für Pfeile, Enter und Esc
    end
  end)
  search:SetScript("OnEnterPressed", function() if highlighted then pick(highlighted) end end)
  search:SetScript("OnEscapePressed", Dropdown.Close)
  search:SetScript("OnArrowPressed", function(_, key)
    if key == "UP" then move(-1) elseif key == "DOWN" then move(1) end
  end)

  scrollbar = popup:CreateTexture(nil, "ARTWORK")
  scrollbar:SetWidth(SCROLLBAR_WIDTH)
  scrollbar:SetColorTexture(1, 1, 1, 0.12)
  thumb = popup:CreateTexture(nil, "OVERLAY")
  thumb:SetWidth(SCROLLBAR_WIDTH)
  thumb:SetColorTexture(1, 1, 1, 0.45)

  measure = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  measure:Hide()
  for position = 1, MAX_ROWS do createRow(position) end
end

-- Breite: breitester Text (Schrift der Zeilen), mindestens so breit wie der Knopf
local function widthFor(anchor)
  local widest = 0
  for _, entry in ipairs(spec.entries) do
    measure:SetText(entry.text)
    widest = math.max(widest, measure:GetStringWidth())
  end
  local width = math.max(MIN_WIDTH, anchor:GetWidth() or 0, widest + TEXT_PADDING)
  return math.min(width, math.max(MAX_WIDTH, anchor:GetWidth() or 0))
end

-- Unter dem Knopf, bei zu wenig Platz darüber
local function place(anchor, height)
  popup:ClearAllPoints()
  local bottom = anchor:GetBottom()
  local scale = anchor:GetEffectiveScale() or 1
  local below = bottom and bottom * scale - SCREEN_MARGIN
  if below and below < height * popup:GetEffectiveScale() then
    popup:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
  else
    popup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  end
end

function Dropdown.Open(anchor, options)
  if not popup then create() end
  Dropdown.Close()
  spec = {
    entries = {}, current = options.current, onPick = options.onPick, anchor = anchor,
    emptyText = options.emptyText,
  }
  for i, entry in ipairs(options.entries) do
    spec.entries[i] = { key = entry.key, text = entry.text, group = entry.group, font = entry.font,
      search = normalize(entry.text) }
  end
  isSearchable = #spec.entries >= Dropdown.SEARCH_MIN_ENTRIES
  filter("")
  highlighted = nil
  for index, item in ipairs(visible) do
    if item.selected then highlighted = index end
  end
  highlighted = highlighted or firstEntryIndex()
  offset = 0
  if highlighted then reveal(highlighted) end

  local top = isSearchable and SEARCH_HEIGHT + PADDING or 0
  local height = PADDING * 2 + top + rowCount() * ROW_HEIGHT
  popup:SetSize(widthFor(anchor), height)
  popup:SetScale(anchor:GetEffectiveScale() / UIParent:GetEffectiveScale())
  place(anchor, height)

  search:ClearAllPoints()
  if isSearchable then
    search:SetPoint("TOPLEFT", popup, "TOPLEFT", PADDING + 6, -PADDING)
    search:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -PADDING, -PADDING)
    search:SetAlpha(1)
  else
    search:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, 0)
    search:SetSize(1, 1)
    search:SetAlpha(0)
  end
  search:SetText("")
  for position = 1, MAX_ROWS do
    rows[position]:ClearAllPoints()
    rows[position]:SetPoint("TOPLEFT", popup, "TOPLEFT", PADDING, -(PADDING + top + (position - 1) * ROW_HEIGHT))
    rows[position]:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -PADDING - SCROLLBAR_WIDTH - 2,
      -(PADDING + top + (position - 1) * ROW_HEIGHT))
    local color = colors().accent
    rows[position].highlight:SetColorTexture(color[1], color[2], color[3], HOVER_ALPHA)
  end
  scrollbar:ClearAllPoints()
  scrollbar:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -PADDING + 2, -(PADDING + top))
  scrollbar:SetHeight(MAX_ROWS * ROW_HEIGHT)

  catcher:Show()
  popup:Show()
  paintRows()
  search:SetFocus()
  -- Knopf verschwindet (Fenster zu, Seite gewechselt): Liste mit ihm schließen
  if not hookedAnchors[anchor] then
    hookedAnchors[anchor] = true
    anchor:HookScript("OnHide", function(self)
      if spec and spec.anchor == self then Dropdown.Close() end
    end)
  end
end

function Dropdown.IsOpen()
  return popup ~= nil and popup:IsShown() == true
end

-- Für Tests und Prüfungen: sichtbare Zeilen { text, header, selected, highlighted } und das Suchfeld
function Dropdown.State()
  local list = {}
  for index, item in ipairs(visible) do
    list[index] = {
      text = item.header or item.entry.text, header = item.header ~= nil, key = item.entry and item.entry.key,
      selected = item.selected == true, highlighted = index == highlighted,
    }
  end
  return { open = Dropdown.IsOpen(), rows = list, search = search, catcher = catcher, searchable = isSearchable }
end
