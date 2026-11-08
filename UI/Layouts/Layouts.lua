-- Layouts des Hauptfensters (Einstellung windowLayout). Ein Layout ordnet die Elemente (UI/WindowElements.lua) für
-- ein Modell (UI/WindowModel.lua) an:
--   Layouts.Register(id, {
--     label = Locale-Key für die Auswahl,
--     source = WindowModel.VISIBLE (eingeschaltete Zeilen) oder WindowModel.CHOSEN (compactRows),
--     alwaysXpBar = true: Balken auch ohne showXpBar (Layout "xpbar"),
--     background = false: ohne Grund und Rand (Chroma-Farbe bleibt),
--     Build(el, model, db) -> Höhe: Anker, Schriften, Sichtbarkeit; nur bei geänderter Struktur (Apply, andere
--       Zeilen, Level-Up), nie je Takt,
--     Render(el, model, db) -> true, wenn sich ein Text geändert hat (über Elements.SetText),
--     Measure(el, model, db) -> benötigte Breite (das Fenster wächst bis zur nächsten Struktur nur),
--   })
-- Alle Maße gelten bei Skalierung 1. Diese Datei enthält dazu die Bausteine der Layouts und die Familie der
-- Zeilen-Layouts (Tabelle, kompakt, nur Text).
local _, ns = ...
local Theme = ns.Theme
local WindowModel = ns.WindowModel
local Elements = ns.WindowElements

local Layouts = {
  DEFAULT = "table",
  ORDER = {},
  PADDING_X = 20,
  PADDING_Y = 8,
  LINE_GAP = 3,
  TABLE_GAP = 4,     -- Abstand zwischen Zeit, Balken und Zeilen
  TAB_GAP = 10,
  COLUMN_GAP = 16,   -- Mindestabstand zwischen Bezeichnung und Wert
  INLINE_GAP = 6,    -- Layout "text": Wert direkt hinter der Bezeichnung
  TAB_EXTRA_HEIGHT = 4,
}
ns.WindowLayouts = Layouts

local registry = {}

function Layouts.Register(id, layout)
  layout.id = id
  registry[id] = layout
  table.insert(Layouts.ORDER, id)
end

-- Layout zur Einstellung; unbekannte Werte (z.B. aus einem Import) fallen auf die Tabelle zurück
function Layouts.Get(id)
  return registry[id] or registry[Layouts.DEFAULT]
end

---------------------------------------------------------------------------
-- Bausteine
---------------------------------------------------------------------------
local fontSize = Elements.FontSize
local setText = Elements.SetText
Layouts.FontSize = fontSize

-- Feste Breite der Zeit, damit nichts springt, wenn sich Ziffern ändern; dayDigits wächst ab 100 Tagen
local WIDEST_TIME_SUFFIX = "d 00h 00m 00s"
local TIME_WIDTH_SLACK = 2

function Layouts.FixTimeWidth(fontString, dayDigits)
  fontString:SetText(string.rep("0", dayDigits) .. WIDEST_TIME_SUFFIX)
  fontString:SetWidth(math.ceil(fontString:GetStringWidth()) + TIME_WIDTH_SLACK)
  ns.Widgets.ForgetText(fontString)  -- der nächste Render setzt die Zeit wieder
end

-- Drei Reiter um die Mitte (Session), Level links und Instanz rechts davon; gibt die Höhe der Zeile zurück
function Layouts.PlaceTabsCentered(el, y)
  local level, session, instance = el.tabs[1], el.tabs[2], el.tabs[3]
  session:ClearAllPoints()
  session:SetPoint("TOP", el.window, "TOP", 0, -y)
  level:ClearAllPoints()
  level:SetPoint("TOPRIGHT", session, "TOPLEFT", -Layouts.TAB_GAP, 0)
  instance:ClearAllPoints()
  instance:SetPoint("TOPLEFT", session, "TOPRIGHT", Layouts.TAB_GAP, 0)
  for _, tab in ipairs(el.tabs) do tab:Show() end
  return fontSize(level.label) + Layouts.TAB_EXTRA_HEIGHT + Layouts.LINE_GAP
end

function Layouts.CenteredTabsWidth(el)
  local side = math.max(el.tabs[1]:GetWidth(), el.tabs[3]:GetWidth())
  return el.tabs[2]:GetWidth() + 2 * (side + Layouts.TAB_GAP) + 2 * Layouts.PADDING_X
end

-- XP-Balken bei Höhe y über die Breite (inset links und rechts); gibt die Höhe darunter zurück
function Layouts.PlaceXpBar(el, model, y, inset)
  local bar = el.xpBar
  if not model.xpBar.shown then
    bar:SetShown(false)
    return y
  end
  bar:SetHeight(Elements.XP_BAR_HEIGHT)
  bar:Place(y, inset)
  bar:SetShown(true, model.xpBar.quests ~= nil)
  return y + Elements.XP_BAR_HEIGHT + Layouts.TABLE_GAP
end

-- "XP/h 42k   ETA 18m": gewählte Zeilen mit Kurzlabel in einer Zeile (Uhr, schmaler Balken)
local ROW_JOIN = "   "
function Layouts.JoinRows(model)
  local parts = {}
  for index, row in ipairs(model.rows) do parts[index] = row.shortLabel .. " " .. row.value end
  return table.concat(parts, ROW_JOIN)
end

---------------------------------------------------------------------------
-- Zeilen-Layouts: Zeit oben, darunter Zeilen (Bezeichnung links, Wert rechts oder direkt dahinter)
--   options = { label, source, tabs, xpBar, inline, outlined, short, minWidth, background, labels(db),
--               scopeLine (ohne Reiter: kleine Zeile mit dem Bereich über der Zeit, "Level 25"/"Session"; UX W7) }
---------------------------------------------------------------------------
function Layouts.Stack(options)
  local layout = { label = options.label, source = options.source, background = options.background }
  local function labelsShown(db) return not options.labels or options.labels(db) end
  -- Bereichszeile nur, wo Bezeichnungen gezeigt werden (Layout "text" ohne Bezeichnungen bleibt reine Zahl)
  local function scopeShown(db) return options.scopeLine and labelsShown(db) end

  function layout.Build(el, model, db)
    local outlined = options.outlined
    el:SetRowFonts(Theme.Font("label", outlined), Theme.Font("small", outlined))
    el.time:SetFontObject(Theme.Font("number", outlined))
    el.time:SetJustifyH(options.inline and "LEFT" or "CENTER")
    Layouts.FixTimeWidth(el.time, el.dayDigits)

    local y = Layouts.PADDING_Y
    if options.tabs then y = y + Layouts.PlaceTabsCentered(el, y) end
    if scopeShown(db) then
      el.sub:SetFontObject(Theme.Font("small", outlined))
      el.sub:SetJustifyH(options.inline and "LEFT" or "CENTER")
      el.sub:ClearAllPoints()
      if options.inline then
        el.sub:SetPoint("TOPLEFT", el.window, "TOPLEFT", Layouts.PADDING_X, -y)
      else
        el.sub:SetPoint("TOP", el.window, "TOP", 0, -y)
      end
      el.sub:Show()
      y = y + fontSize(el.sub) + Layouts.LINE_GAP
    else
      el.sub:Hide()
    end
    el.time:ClearAllPoints()
    if options.inline then
      el.time:SetPoint("TOPLEFT", el.window, "TOPLEFT", Layouts.PADDING_X, -y)
    else
      el.time:SetPoint("TOP", el.window, "TOP", 0, -y)
    end
    el.time:Show()
    y = y + fontSize(el.time) + Layouts.TABLE_GAP
    if options.xpBar then
      y = Layouts.PlaceXpBar(el, model, y, Layouts.PADDING_X)
    else
      el.xpBar:SetShown(false)
    end

    local labels = labelsShown(db)
    for index in ipairs(model.rows) do
      local row = el:Row(index)
      row.label:ClearAllPoints()
      row.label:SetPoint("TOPLEFT", el.window, "TOPLEFT", Layouts.PADDING_X, -y)
      row.label:SetShown(labels)
      row.value:ClearAllPoints()
      if options.inline then
        if labels then
          row.value:SetPoint("LEFT", row.label, "RIGHT", Layouts.INLINE_GAP, 0)
        else
          row.value:SetPoint("TOPLEFT", el.window, "TOPLEFT", Layouts.PADDING_X, -y)
        end
        row.value:SetJustifyH("LEFT")
      else
        row.value:SetPoint("TOPRIGHT", el.window, "TOPRIGHT", -Layouts.PADDING_X, -y)
        row.value:SetJustifyH("RIGHT")
      end
      row.value:Show()
      el:SetHoverData(row.hover, model.rows[index])
      y = y + fontSize(row.label) + Layouts.LINE_GAP
    end
    el:HideRowsFrom(#model.rows + 1)
    return y + Layouts.PADDING_Y
  end

  function layout.Render(el, model, db)
    local changed = options.tabs and el:RenderTabs(model) or false
    if scopeShown(db) then changed = setText(el.sub, model.scopeText or "") or changed end
    changed = setText(el.time, model.time.text) or changed
    for index, data in ipairs(model.rows) do
      local row = el.rows[index]
      changed = setText(row.label, options.short and data.shortLabel or data.label) or changed
      changed = setText(row.value, data.value) or changed
    end
    return changed
  end

  function layout.Measure(el, model, db)
    local padding = 2 * Layouts.PADDING_X
    local width = math.max(options.minWidth or 0, el.time:GetWidth() + padding)
    if options.tabs then width = math.max(width, Layouts.CenteredTabsWidth(el)) end
    if scopeShown(db) then width = math.max(width, el.sub:GetStringWidth() + padding) end
    local labels = labelsShown(db)
    local gap = options.inline and Layouts.INLINE_GAP or Layouts.COLUMN_GAP
    for index in ipairs(model.rows) do
      local row = el.rows[index]
      local labelWidth = labels and (row.label:GetStringWidth() + gap) or 0
      width = math.max(width, labelWidth + row.value:GetStringWidth() + padding)
    end
    return width
  end

  return layout
end

local MIN_WIDTH = 160

-- Tabelle wie bisher: Reiter, Zeit, XP-Balken, eingeschaltete Zeilen
Layouts.Register("table", Layouts.Stack({
  label = "LAYOUT_TABLE", source = WindowModel.VISIBLE, tabs = true, xpBar = true, minWidth = MIN_WIDTH,
}))

-- Kompakt: Bereich, Zeit, XP-Balken und bis zu drei gewählte Werte (compactRows), ohne Reiter
Layouts.Register("compact", Layouts.Stack({
  label = "LAYOUT_COMPACT", source = WindowModel.CHOSEN, xpBar = true, minWidth = MIN_WIDTH, scopeLine = true,
}))

-- Nur Text (OBS): ohne Grund und Rand, Schrift mit Kontur, Bezeichnungen (Kurzform) abschaltbar (textLabels)
Layouts.Register("text", Layouts.Stack({
  label = "LAYOUT_TEXT", source = WindowModel.VISIBLE, inline = true, outlined = true, short = true,
  background = false, labels = function(db) return db.textLabels end, scopeLine = true,
}))

