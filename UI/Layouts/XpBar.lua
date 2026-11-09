-- Layout "xpbar" (nur XP-Balken, wie eine Statusleiste): ein schmaler Balken über die Breite xpbarWidth mit drei
-- Textfeldern darauf: links Level und Fortschritt, Mitte die Spielzeit, rechts die gewählten Werte (compactRows).
-- Einstellung xpbarText: Texte immer, nur bei Mauskontakt oder nie. Auch ohne showXpBar und auf Max-Level sichtbar
-- (dann leer).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    xpbarText = "always",
    xpbarWidth = 400,
  },
  ranges = {
    xpbarWidth = { 200, 1200 },
  },
})
local Layouts = ns.WindowLayouts
local WindowModel = ns.WindowModel
local Format = ns.Format

local XpBarLayout = {
  ALWAYS = "always",
  MOUSEOVER = "mouseover",
  NEVER = "never",
  MIN_WIDTH = 200,
  MAX_WIDTH = 1200,
}
XpBarLayout.MODES = { XpBarLayout.ALWAYS, XpBarLayout.MOUSEOVER, XpBarLayout.NEVER }
Layouts.XpBar = XpBarLayout

local FIELD_INSET = 6
local FIELD_GAP = 12    -- Mindestabstand zwischen den Textfeldern (links/Mitte/rechts)
local TEXT_PADDING = 4  -- Balken höher als die Schrift
local EMPTY = { shown = true, xp = 0, max = 1, rested = 0 }
local setText = ns.WindowElements.SetText
local fontSize = Layouts.FontSize

local layout = { label = "LAYOUT_XPBAR", source = WindowModel.CHOSEN, alwaysXpBar = true }

local function textsShown(el, db)
  local mode = db.xpbarText
  if mode == XpBarLayout.NEVER then return false end
  if mode == XpBarLayout.MOUSEOVER then return el.hovered == true end
  return true
end

function layout.Build(el, model, db)
  local bar = el.xpBar
  local height = fontSize(el.fields[1]) + 2 * TEXT_PADDING
  bar:SetHeight(height)
  bar:Place(0, 0)
  bar:SetShown(true, model.xpBar.quests ~= nil)
  local shown = textsShown(el, db)
  for index, field in ipairs(el.fields) do
    field:ClearAllPoints()
    if index == 1 then
      field:SetPoint("LEFT", el.window, "LEFT", FIELD_INSET, 0)
    elseif index == 2 then
      field:SetPoint("CENTER", el.window, "CENTER", 0, 0)
    else
      field:SetPoint("RIGHT", el.window, "RIGHT", -FIELD_INSET, 0)
    end
    field:SetShown(shown)
  end
  return height
end

local function progressText(model)
  local bar = model.xpBar
  if not bar.shown then return model.tabs[1].text end
  return model.tabs[1].text .. "  " .. Format.PercentPrecise(bar.xp, bar.max)
end

function layout.Render(el, model, db)
  local shown = textsShown(el, db)
  local changed = false
  for _, field in ipairs(el.fields) do
    if field:IsShown() ~= shown then
      field:SetShown(shown)
      changed = true
    end
  end
  changed = setText(el.fields[1], progressText(model)) or changed
  changed = setText(el.fields[2], model.time.text) or changed
  return setText(el.fields[3], Layouts.JoinRows(model)) or changed
end

-- Breite aus der Einstellung (wie eine Statusleiste), aber nie schmaler als die drei Texte nebeneinander (UX W20):
-- die Mitte steht zentriert, also braucht jede Seite Platz für den breiteren Randtext. Auch bei "nur bei
-- Mauskontakt", damit der Balken beim Überfahren nicht springt
function layout.Measure(el, _, db)
  local width = math.max(XpBarLayout.MIN_WIDTH, math.min(XpBarLayout.MAX_WIDTH, db.xpbarWidth))
  if db.xpbarText == XpBarLayout.NEVER then return width end
  local left = el.fields[1]:GetStringWidth() or 0
  local middle = el.fields[2]:GetStringWidth() or 0
  local right = el.fields[3]:GetStringWidth() or 0
  local needed = math.ceil(middle + 2 * (math.max(left, right) + FIELD_INSET + FIELD_GAP))
  return math.min(XpBarLayout.MAX_WIDTH, math.max(width, needed))
end

-- Leerer Balken auf Max-Level und ohne Daten
function layout.BarValues(model)
  return model.xpBar.shown and model.xpBar or EMPTY
end

Layouts.Register("xpbar", layout)
