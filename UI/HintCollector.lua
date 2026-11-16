-- Sammelfenster für Erinnerungen (Buffs, Lehrer, Taschen, alte Zauberränge, ...): Hinweise, die kurz nacheinander
-- kommen, stehen als Liste in EINEM Fenster statt als mehrere Banner nacheinander (Alerts.Notify mit
-- options.collect). Je Zeile Symbol und Text, ein X schließt sie, "Alle schließen" im Kopf. Das Fenster bleibt, bis es
-- geschlossen wird; nur mit hintsAutoClose schließt es nach AUTO_CLOSE_SECONDS (unter der Maus bleibt es stehen).
-- Dringende Meldungen (Aggro, Atemnot, Rare/Elite, Notfall) bleiben sofortige Banner (UI/Alerts.lua).
-- Hints.Add(entry): entry = { text, title, icon/texture (Alerts.ICONS), key, rows, header }. Gleicher key (Standard:
-- der Text) ersetzt die Zeile statt sie zu verdoppeln. rows = { { spellID, name, columns = { ... } } } hängt eine
-- Tabelle mit ausgerichteten Spalten unter die Zeile (Zaubersymbol mit Zaubertooltip, Name, Spalten); header =
-- { Name-Kopf, Spaltenkopf, ... } ist ihre Kopfzeile.
-- Position über Lib/Frames.lua (Edit-Modus mit Beispielinhalt).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme

ns.RegisterDefaults({
  settings = {
    hintsAutoClose = false,  -- aus: Fenster bleibt, bis es geschlossen wird
  },
})

local Hints = { AUTO_CLOSE_SECONDS = 30, MAX_ENTRIES = 12 }
ns.Hints = Hints

local DEFAULT_POSITION = { "TOP", "TOP", 0, -220 }
local PADDING = 12
local MIN_WIDTH = 280
local HEADER_HEIGHT = 40   -- Widgets.CreateWindowHeader
local ROW_HEIGHT = 28
local ICON_SIZE = 20
local ICON_INSET = 8
local TEXT_GAP = 6
local COLUMN_GAP = 16
local DISMISS_SIZE = 18
local TEXT_MAX_WIDTH = 360
local FADE_OUT = 0.7
local BACKGROUND_ALPHA = 0.92
local CLOSE_ALL_WIDTH = 110

local panel = Widgets.CreatePanel(ns.GlobalName("Hints"), BACKGROUND_ALPHA)
panel:Hide()
local header = Widgets.CreateWindowHeader(panel, L.HINTS_TITLE, { onClose = function() Hints.Clear() end })
local closeAll = Widgets.CreateButton(header.actions, CLOSE_ALL_WIDTH, 22, function() Hints.Clear() end)
closeAll:SetPoint("RIGHT")
closeAll:SetText(L.HINTS_CLOSE_ALL)
header.actions:SetWidth(CLOSE_ALL_WIDTH)

local entries = {}  -- Hinweise in Reihenfolge des Eintreffens
local rows = {}     -- Zeilenpool; row.entry = Hinweis, row.detail = Tabellenzeile
local shownAt
local editing = false

local function iconOf(entry)
  if entry.texture then return entry.texture end
  if type(entry.icon) == "number" then return Widgets.SpellTexture(entry.icon) end
  return entry.icon
end

local function getRow(index)
  if rows[index] then return rows[index] end
  local row = Widgets.CreateListRow(panel, ROW_HEIGHT)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(ICON_SIZE, ICON_SIZE)
  row.icon:SetPoint("LEFT", ICON_INSET, 0)
  row.text:ClearAllPoints()
  row.text:SetPoint("LEFT", row.icon, "RIGHT", TEXT_GAP, 0)
  row.columns = {}
  row.dismiss = Widgets.CreateButton(row, DISMISS_SIZE, DISMISS_SIZE, function() Hints.Dismiss(row.entry) end)
  row.dismiss:SetPoint("RIGHT", -ICON_INSET, 0)
  row.dismiss:SetText("X")
  Widgets.AttachTooltip(row.dismiss, function() return ns.DISPLAY_NAME end, function() return L.HINTS_DISMISS_TIP end)
  -- Zaubertabelle: Mausover zeigt den Zaubertooltip
  row:HookScript("OnEnter", function(self)
    if not (self.detail and self.detail.spellID) then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.detail.spellID)
    GameTooltip:Show()
  end)
  row:HookScript("OnLeave", function(self)
    if self.detail then GameTooltip:Hide() end
  end)
  rows[index] = row
  return row
end

local function getColumn(row, index)
  if not row.columns[index] then
    row.columns[index] = row:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
    row.columns[index]:SetJustifyH("LEFT")
  end
  return row.columns[index]
end

local function lineText(entry)
  if not entry.title then return entry.text end
  if entry.rows then return entry.title end
  return entry.title .. ": " .. entry.text
end

local measure = panel:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
local function widthOf(text)
  measure:SetText(text)
  return math.min(TEXT_MAX_WIDTH, measure:GetStringWidth() or 0)
end

-- Zeilen aus den Einträgen: Hinweiszeile, dann (mit rows) Kopfzeile und je Zauber eine Zeile der Tabelle
local function buildLines()
  local lines = {}  -- { text, texture, entry, detail, columns, muted, isTable }
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = { text = lineText(entry), texture = iconOf(entry), entry = entry }
    if entry.rows then
      local head = entry.header or {}
      lines[#lines + 1] = { text = head[1] or "", columns = { unpack(head, 2) }, muted = true, isTable = true,
        entry = entry }
      for _, detail in ipairs(entry.rows) do
        lines[#lines + 1] = { text = detail.name, texture = Widgets.SpellTexture(detail.spellID),
          columns = detail.columns, detail = detail, isTable = true, entry = entry }
      end
    end
  end
  return lines
end

local function paintRow(row, line, y, nameWidth, columnWidths)
  row.entry, row.detail = line.entry, line.detail
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", PADDING, y)
  row:SetPoint("RIGHT", -PADDING, 0)
  local color = line.muted and "muted" or "text"
  row.text:SetText(line.text)
  row.text:SetTextColor(Theme.RGB(color))
  row.text:SetWidth(line.isTable and nameWidth or widthOf(line.text))
  if line.texture then row.icon:SetTexture(line.texture) end
  row.icon:SetShown(line.texture ~= nil)
  row.dismiss:SetShown(not line.isTable)
  local x = ICON_INSET + ICON_SIZE + TEXT_GAP + nameWidth + COLUMN_GAP
  local columns = line.columns or {}
  for index, value in ipairs(columns) do
    local column = getColumn(row, index)
    column:ClearAllPoints()
    column:SetPoint("LEFT", x, 0)
    column:SetText(value)
    column:SetTextColor(Theme.RGB(color))
    column:Show()
    x = x + columnWidths[index] + COLUMN_GAP
  end
  for index = #columns + 1, #row.columns do row.columns[index]:Hide() end
  row:Show()
end

-- Fenster aus den Einträgen neu aufbauen; Tabellen teilen sich eine Namensspalte und gleich breite Spalten
local function layout()
  local lines = buildLines()
  local nameWidth, columnWidths, hasTable = 0, {}, false
  for _, line in ipairs(lines) do
    if line.isTable then
      hasTable = true
      nameWidth = math.max(nameWidth, widthOf(line.text))
      for index, value in ipairs(line.columns) do columnWidths[index] = math.max(columnWidths[index] or 0, widthOf(value)) end
    end
  end
  local width = ICON_INSET + ICON_SIZE + TEXT_GAP + nameWidth
  if hasTable then
    for _, columnWidth in ipairs(columnWidths) do width = width + COLUMN_GAP + columnWidth end
  end
  for _, line in ipairs(lines) do
    if not line.isTable then
      width = math.max(width, ICON_INSET + ICON_SIZE + 2 * TEXT_GAP + widthOf(line.text) + DISMISS_SIZE + ICON_INSET)
    end
  end
  for index, line in ipairs(lines) do
    paintRow(getRow(index), line, -HEADER_HEIGHT - (index - 1) * ROW_HEIGHT, nameWidth, columnWidths)
  end
  for index = #lines + 1, #rows do
    rows[index].entry, rows[index].detail = nil, nil
    rows[index]:Hide()
  end
  panel:SetSize(math.max(MIN_WIDTH, width + 2 * PADDING), PADDING + HEADER_HEIGHT + #lines * ROW_HEIGHT)
end

local function hide()
  editing = false
  panel:Hide()
end

function Hints.Clear()
  entries = {}
  layout()
  hide()
end

function Hints.Dismiss(entry)
  for index, shown in ipairs(entries) do
    if shown == entry then
      table.remove(entries, index)
      break
    end
  end
  if #entries == 0 then Hints.Clear() else layout() end
end

-- Hinweis aufnehmen (Fenster öffnet sich oder wächst); gleicher key ersetzt den alten Eintrag
function Hints.Add(entry)
  entry.key = entry.key or entry.text
  for index, shown in ipairs(entries) do
    if shown.key == entry.key then
      table.remove(entries, index)
      break
    end
  end
  if #entries >= Hints.MAX_ENTRIES then table.remove(entries, 1) end
  table.insert(entries, entry)
  editing = false
  layout()
  shownAt = GetTime()
  panel:SetAlpha(1)
  panel:Show()
  ns.Debug("hints", "added %s, %s in window", entry.key, #entries)
end

function Hints.IsShown() return panel:IsShown() end
function Hints.Entries() return entries end
function Hints.Rows() return rows end

ns.SetUpdateScript(panel, "Hints", function(self)
  if editing or not shownAt or not (ns.db and ns.db.hintsAutoClose) then return end
  local age = GetTime() - shownAt
  local hold = Hints.AUTO_CLOSE_SECONDS
  if self:IsMouseOver() and age > hold then  -- unter der Maus bleibt es stehen
    shownAt = GetTime() - hold
    age = hold
  end
  if age >= hold + FADE_OUT then
    Hints.Clear()
  elseif age > hold then
    self:SetAlpha(1 - (age - hold) / FADE_OUT)
  end
end)

-- Edit-Modus: Beispielinhalt bleibt stehen, bis der Modus endet; echte Hinweise erscheinen danach wieder
local function setEditing(enabled)
  if enabled then
    local saved = entries
    entries = { { text = L.HINTS_SAMPLE, title = L.NOTICE_TRAINER, icon = ns.Alerts.ICONS.trainer, key = "sample" } }
    layout()
    entries = saved
    editing = true
    panel:SetAlpha(1)
    panel:Show()
  elseif editing then
    layout()
    if #entries == 0 then hide() else editing = false end
  end
end

ns.Frames.Register({
  id = "hints", frame = panel, label = "EDIT_FRAME_HINTS", default = DEFAULT_POSITION,
  settingsPage = "OPTIONS_PAGE_REMINDERS", preview = setEditing, dragWhenUnlocked = true,
})
