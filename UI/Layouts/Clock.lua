-- Layout "clock" (große Uhr, für Streams): nur die Spielzeit groß, darunter eine Zeile mit den gewählten Werten
-- (compactRows, Kurzlabels) oder ohne Auswahl dem Bereich ("Level 23"); XP-Balken darunter, wenn eingeschaltet.
local _, ns = ...
local Layouts = ns.WindowLayouts
local WindowModel = ns.WindowModel
local Theme = ns.Theme

local PADDING_X = 14
local MIN_WIDTH = 120
local SUB_GAP = 2
local setText = ns.WindowElements.SetText
local fontSize = Layouts.FontSize

local layout = { label = "LAYOUT_CLOCK", source = WindowModel.CHOSEN }

local function subText(model)
  if #model.rows == 0 then return model.scopeText or "" end
  return Layouts.JoinRows(model)
end

function layout.Build(el, model)
  Layouts.FixTimeWidth(el.big, el.dayDigits)
  el.big:SetJustifyH("CENTER")
  el.big:ClearAllPoints()
  el.big:SetPoint("TOP", el.window, "TOP", 0, -Layouts.PADDING_Y)
  el.big:Show()
  local y = Layouts.PADDING_Y + fontSize(el.big) + SUB_GAP
  el.sub:SetFontObject(Theme.Font("label"))
  el.sub:ClearAllPoints()
  el.sub:SetPoint("TOP", el.window, "TOP", 0, -y)
  el.sub:Show()
  y = y + fontSize(el.sub) + Layouts.TABLE_GAP
  y = Layouts.PlaceXpBar(el, model, y, PADDING_X)
  return y - Layouts.TABLE_GAP + Layouts.PADDING_Y
end

function layout.Render(el, model)
  local changed = setText(el.big, model.time.text)
  return setText(el.sub, subText(model)) or changed
end

function layout.Measure(el)
  return math.max(MIN_WIDTH, el.big:GetWidth(), el.sub:GetStringWidth()) + 2 * PADDING_X
end

Layouts.Register("clock", layout)
