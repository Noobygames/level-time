-- Layout "bar" (Info-Leiste, /lt bar): Reiter, Zeit und Zeilen an der Mittellinie einer Zeile aneinandergereiht,
-- jeder Eintrag am rechten Rand des vorigen; Bezeichnungen in Kurzform. Der XP-Balken liegt darunter über die ganze
-- Breite. Breitere Texte verlängern nur die Leiste, die Anker bleiben.
local _, ns = ...
local Layouts = ns.WindowLayouts
local WindowModel = ns.WindowModel
local Theme = ns.Theme

local PADDING_X = 10     -- Rand links und rechts
local ITEM_GAP = 14      -- Abstand zwischen zwei Einträgen
local LABEL_GAP = 4      -- Abstand zwischen Bezeichnung und Wert
local setText = ns.WindowElements.SetText
local fontSize = Layouts.FontSize

local layout = { label = "LAYOUT_BAR", source = WindowModel.VISIBLE }

function layout.Build(el, model)
  el:SetRowFonts(Theme.Font("label"), Theme.Font("small"))
  el.time:SetFontObject(Theme.Font("number"))
  el.time:SetJustifyH("LEFT")
  Layouts.FixTimeWidth(el.time, el.dayDigits)
  local lineHeight = fontSize(el.time)
  local centerY = -(Layouts.PADDING_Y + lineHeight / 2)
  local previous

  local function chain(element, gap)
    element:ClearAllPoints()
    if previous then
      element:SetPoint("LEFT", previous, "RIGHT", gap, 0)
    else
      element:SetPoint("LEFT", el.window, "TOPLEFT", PADDING_X, centerY)
    end
    element:Show()
    previous = element
  end

  for index, tab in ipairs(el.tabs) do chain(tab, index > 1 and ITEM_GAP or nil) end
  chain(el.time, ITEM_GAP)
  for index in ipairs(model.rows) do
    local row = el:Row(index)
    row.value:SetJustifyH("LEFT")
    chain(row.label, ITEM_GAP)
    chain(row.value, LABEL_GAP)
    el:SetHoverData(row.hover, model.rows[index])
  end
  el:HideRowsFrom(#model.rows + 1)

  local y = Layouts.PlaceXpBar(el, model, Layouts.PADDING_Y + lineHeight + Layouts.TABLE_GAP, PADDING_X)
  return y - Layouts.TABLE_GAP + Layouts.PADDING_Y
end

function layout.Render(el, model)
  local changed = el:RenderTabs(model)
  changed = setText(el.time, model.time.text) or changed
  for index, data in ipairs(model.rows) do
    local row = el.rows[index]
    changed = setText(row.label, data.shortLabel) or changed
    changed = setText(row.value, data.value) or changed
  end
  return changed
end

-- Summe aller Einträge der Zeile
function layout.Measure(el, model)
  local width = 2 * PADDING_X + el.time:GetWidth()
  for _, tab in ipairs(el.tabs) do width = width + tab:GetWidth() + ITEM_GAP end
  for index in ipairs(model.rows) do
    local row = el.rows[index]
    width = width + ITEM_GAP + row.label:GetStringWidth() + LABEL_GAP + row.value:GetStringWidth()
  end
  return width
end

Layouts.Register("bar", layout)
