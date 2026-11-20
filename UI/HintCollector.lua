-- Sammelfenster für Erinnerungen (Buffs, Lehrer, Taschen, alte Zauberränge, ...): Hinweise, die kurz nacheinander
-- kommen, stehen als Liste in EINEM Fenster statt als mehrere Banner nacheinander (Alerts.Notify mit
-- options.collect). Je Zeile Symbol und Text, ein X schließt sie, "Alle schließen" im Kopf. Das Fenster bleibt, bis es
-- geschlossen wird; mit hintsAutoClose (Standard an) schließt es nach hintsAutoCloseSeconds (Standard 10), unter der Maus bleibt es.
-- Dringende Meldungen (Aggro, Atemnot, Rare/Elite, Notfall) bleiben sofortige Banner (UI/Alerts.lua).
-- Hints.Add(entry): entry = { text, title, icon/texture (Alerts.ICONS), key, rows, header }. Gleicher key (Standard:
-- der Text) ersetzt die Zeile statt sie zu verdoppeln. rows = { { spellID, name, columns = { ... } } } hängt eine
-- Tabelle mit ausgerichteten Spalten unter die Zeile (Zaubersymbol mit Zaubertooltip, Name, Spalten); header =
-- { Name-Kopf, Spaltenkopf, ... } ist ihre Kopfzeile. Eine Tabellenzeile mit onDismiss hat rechts einen eigenen
-- Schließen-Knopf: er ruft onDismiss() und nimmt die Zeile heraus (ohne Zeilen fällt der ganze Eintrag weg).
-- action = { tip, run, onEnter, onLeave } setzt links daneben einen grünen Pfeil-hoch-Knopf (z.B. Zauberrang upgraden,
-- LT-409): Überfahren ruft onEnter/onLeave (optional), Klick ruft run(); gibt es true zurück, verschwindet die Zeile
-- (ohne onDismiss).
-- text und title dürfen Funktionen sein: sie werden bei jedem Aufbau des Fensters ausgewertet, so folgt der Text einem
-- Sprachwechsel (Alerts.Resolve). Position über Lib/Frames.lua (Edit-Modus mit Beispielinhalt).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme

ns.RegisterDefaults({
  settings = {
    hintsAutoClose = true,  -- aus: Fenster bleibt, bis es geschlossen wird
    hintsAutoCloseSeconds = 10,
  },
  ranges = {
    hintsAutoCloseSeconds = { 5, 120 },
  },
})

local Hints = { MIN_AUTO_CLOSE = 5, MAX_AUTO_CLOSE = 120, MAX_ENTRIES = 12 }
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
local DISMISS_SIZE = 24  -- wie der Schließen-Knopf im Fensterkopf (DESIGN.md)
local ACTION_ICON = "Interface\\Buttons\\Arrow-Up-Up"  -- Pfeil hoch, grün eingefärbt (Theme good)
local ROW_PADDING = 8    -- Luft über und unter dem Text einer Zeile
local TEXT_MAX_WIDTH = 360
local FADE_OUT = 0.7
local BACKGROUND_ALPHA = 0.92
local CLOSE_ALL_WIDTH = 110

local panel = Widgets.CreatePanel(ns.GlobalName("Hints"), BACKGROUND_ALPHA)
panel:Hide()
local header = Widgets.CreateWindowHeader(panel, "", { onClose = function() Hints.Clear() end })
header:SetIcon("Interface\\Icons\\INV_Misc_NotePicture1c")  -- Hinweis
local closeAll = Widgets.CreateButton(header.actions, CLOSE_ALL_WIDTH, 22, function() Hints.Clear() end)
closeAll:SetPoint("RIGHT")
-- Feste Texte erst nach dem Login und bei jedem Sprachwechsel (beim Laden gilt noch die Client-Sprache)
ns.RegisterApply(function()
  header:SetTitle(L.HINTS_TITLE)
  closeAll:SetText(L.HINTS_CLOSE_ALL)
  closeAll:SetWidth(math.max(CLOSE_ALL_WIDTH, closeAll:GetTextWidth() + 16))
  header.actions:SetWidth(closeAll:GetWidth())
end)

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
  row.dismiss = Widgets.CreateCloseButton(row)
  row.dismiss:ClearAllPoints()
  row.dismiss:SetPoint("RIGHT", -ICON_INSET / 2, 0)
  row.dismiss:SetScript("OnClick", function() Hints.DismissLine(row) end)
  row.action = CreateFrame("Button", nil, row)
  row.action:SetSize(DISMISS_SIZE, DISMISS_SIZE)
  row.action:SetPoint("RIGHT", row.dismiss, "LEFT", 0, 0)
  row.action.icon = row.action:CreateTexture(nil, "ARTWORK")
  row.action.icon:SetAllPoints()
  row.action.icon:SetTexture(ACTION_ICON)
  row.action:SetHighlightTexture(ACTION_ICON, "ADD")
  local function rowAction() return row.detail and row.detail.action end
  row.action:SetScript("OnClick", function()
    if rowAction() and rowAction().run() then Hints.RemoveLine(row) end
  end)
  row.action:HookScript("OnEnter", function() if rowAction() and rowAction().onEnter then rowAction().onEnter() end end)
  row.action:HookScript("OnLeave", function() if rowAction() and rowAction().onLeave then rowAction().onLeave() end end)
  Widgets.AttachTooltip(row.action, function() return ns.DISPLAY_NAME end, function()
    return row.detail and row.detail.action and row.detail.action.tip
  end)
  Widgets.AttachTooltip(row.dismiss, function() return ns.DISPLAY_NAME end, function()
    return type(row.detail) == "table" and L.HINTS_DISMISS_RANK_TIP or L.HINTS_DISMISS_TIP
  end)
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
  local text, title = ns.Alerts.Resolve(entry.text), ns.Alerts.Resolve(entry.title)
  if not title then return text end
  if entry.rows then return title end
  return title .. ": " .. text
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

-- Zeichnet eine Zeile bei y und gibt ihre Höhe zurück (wächst mit dem umgebrochenen Text)
local function paintRow(row, line, y, nameWidth, columnWidths)
  row.entry, row.detail = line.entry, line.detail
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", PADDING, y)
  row:SetPoint("RIGHT", -PADDING, 0)
  local color = line.muted and "muted" or "text"
  row.text:SetText(line.text)
  row.text:SetTextColor(Theme.RGB(color))
  row.text:SetWidth(line.isTable and nameWidth or widthOf(line.text))
  local height = math.max(ROW_HEIGHT, (row.text:GetStringHeight() or 0) + ROW_PADDING)
  row:SetHeight(height)
  if line.texture then row.icon:SetTexture(line.texture) end
  row.icon:SetShown(line.texture ~= nil)
  row.dismiss:SetShown(not line.isTable or (line.detail ~= nil and line.detail.onDismiss ~= nil))
  row.action:SetShown(line.detail ~= nil and line.detail.action ~= nil)
  row.action.icon:SetVertexColor(Theme.RGB("good"))  -- hier statt beim Anlegen: folgt dem Theme
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
  return height
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
    for _, line in ipairs(lines) do
      if line.detail and line.detail.onDismiss then
        width = width + TEXT_GAP + DISMISS_SIZE
        break
      end
    end
    for _, line in ipairs(lines) do
      if line.detail and line.detail.action then
        width = width + DISMISS_SIZE
        break
      end
    end
  end
  for _, line in ipairs(lines) do
    if not line.isTable then
      width = math.max(width, ICON_INSET + ICON_SIZE + 2 * TEXT_GAP + widthOf(line.text) + DISMISS_SIZE + ICON_INSET)
    end
  end
  local y = -HEADER_HEIGHT
  for index, line in ipairs(lines) do
    y = y - paintRow(getRow(index), line, y, nameWidth, columnWidths)
  end
  for index = #lines + 1, #rows do
    rows[index].entry, rows[index].detail = nil, nil
    rows[index]:Hide()
  end
  panel:SetSize(math.max(MIN_WIDTH, width + 2 * PADDING, header:MinWidth()), PADDING - y)
end

-- Sprachwechsel bei offenem Fenster: Zeilen neu bilden
ns.RegisterApply(function()
  if panel:IsShown() and not editing then layout() end
end)

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

-- Eintrag mit diesem key herausnehmen, falls er noch im Fenster steht (z.B. Buff wieder da)
function Hints.DismissKey(key)
  for _, shown in ipairs(entries) do
    if shown.key == key then return Hints.Dismiss(shown) end
  end
end

-- X einer Zeile: bei einer Tabellenzeile mit onDismiss nur diese Zeile, sonst der ganze Eintrag
-- Tabellenzeile herausnehmen; ohne Zeilen fällt der ganze Eintrag weg
function Hints.RemoveLine(row)
  local entry, detail = row.entry, row.detail
  for index, shown in ipairs(entry.rows) do
    if shown == detail then
      table.remove(entry.rows, index)
      break
    end
  end
  if #entry.rows == 0 then Hints.Dismiss(entry) else layout() end
end

function Hints.DismissLine(row)
  local detail = row.detail
  if type(detail) ~= "table" or not detail.onDismiss then return Hints.Dismiss(row.entry) end
  detail.onDismiss()
  Hints.RemoveLine(row)
end

-- Hinweis aufnehmen (Fenster öffnet sich oder wächst); gleicher key ersetzt den alten Eintrag
function Hints.Add(entry)
  entry.key = entry.key or ns.Alerts.Resolve(entry.text)
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
  local hold = ns.db.hintsAutoCloseSeconds
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
