-- Anzeigefenster: Reiter "Level | Session | Instanz", Spielzeit im gewählten Bereich, XP-Balken und Stat-Zeilen.
-- Nur Rahmen, Takt, Klicks und das Zusammenstecken: die Daten liefert UI/WindowModel.lua, die Anordnung das Layout aus
-- der Einstellung windowLayout (UI/Layouts/: table, bar, compact, text, clock, xpbar, tiles).
-- Ablauf: Struktur (welche Zeilen, Anker, Höhe) nur nach Apply, Level-Up, XP an/aus oder einer neuen Tagesstelle der
-- Zeit; je Takt (UPDATE_INTERVAL) nur Werte lesen und geänderte Texte setzen, die Breite wächst nur bei geändertem Text.
-- Größe: Ziehgriff unten rechts (erscheint bei Mauskontakt), Regler oder Edit-Modus (frames.main.scale) skaliert das
-- ganze Fenster. Rechtsklick öffnet die Einstellungen. Sichtbarkeit: windowVisibility (UI/DisplayVisibility.lua).
-- Stream-Ansicht: Einstellung "windowBackground" färbt den Hintergrund grün oder magenta ohne Rahmen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    bgAlpha = 0.8,
    windowBackground = "default",
    showTimer = true,
    showXpBar = true,
    autoInstanceTab = false,
  },
  ranges = {
    bgAlpha = { 0, 1 },
  },
})
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Stats = ns.Stats
local Layouts = ns.WindowLayouts

local TimerWindow = {}
ns.TimerWindow = TimerWindow

local UPDATE_INTERVAL = 0.25          -- Sekunden zwischen zwei Anzeige-Updates
local MIN_DAY_DIGITS = 2
local SECONDS_PER_DAY = 86400
local DEFAULT_POSITION = { "TOP", "TOP", 0, -120 }
local SETTINGS_PAGE = "OPTIONS_PAGE_WINDOW"  -- Rechtsklick auf Fenster und Reiter (Lib/Frames.lua)
-- Einstellung "windowBackground": Standard oder einfarbig zum Freistellen in OBS (Chroma-Key, Theme.lua)
TimerWindow.BACKGROUND_DEFAULT = Theme.BACKGROUND_DEFAULT
TimerWindow.CHROMA_COLORS = Theme.CHROMA

local window = Widgets.CreatePanel(ns.GlobalName("Frame"), 0.8)
window:Hide()  -- erst nach Login anzeigen, wenn Daten und Einstellungen bereitstehen

-- Rechtsklick öffnet auf jedem Reiter wie auf dem Fenster die Einstellungen
local function openSettings() ns.ToggleOptionsPage(SETTINGS_PAGE) end

-- Reiter wählen den Bereich (Einstellung windowScope): Linksklick wählt ihn, Rechtsklick öffnet die Einstellungen,
-- Shift+Rechtsklick ruft onShiftRightClick (optional; sonst ebenfalls die Einstellungen)
local function createScopeTab(scope, onShiftRightClick)
  local tab = Widgets.CreateTab(window, Theme.Font("label"), function(_, mouseButton)
    if mouseButton ~= "RightButton" then
      ns.Set("windowScope", scope)
    elseif onShiftRightClick and IsShiftKeyDown() then
      onShiftRightClick()
    else
      openSettings()
    end
  end)
  tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  return tab
end

local levelTab = createScopeTab(Stats.LEVEL)
local sessionTab = createScopeTab(Stats.SESSION)
-- Shift+Rechtsklick auf den Instanz-Reiter (oder Button/Befehl): Daten des Laufs zurücksetzen, nach Rückfrage
local instanceTab = createScopeTab(Stats.INSTANCE, function() ns.Instances.ConfirmReset() end)
Widgets.AttachTooltip(instanceTab, function() return L.TAB_INSTANCE end, function() return L.TAB_INSTANCE_TIP end)

Widgets.AttachTooltip(levelTab, function() return string.format(L.TAB_LEVEL, ns.level) end, function() return L.TAB_LEVEL_TIP end)
Widgets.AttachTooltip(sessionTab, function() return L.TAB_SESSION end, function() return L.TAB_SESSION_TIP end)

local elements = ns.WindowElements.New(window, { levelTab, sessionTab, instanceTab })
elements.dayDigits = MIN_DAY_DIGITS  -- Ziffern der Tage, für die die Zeit Platz hat; wächst bei 100 Tagen und mehr
local model = ns.WindowModel.New()

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------
local layout           -- aktives Layout
local builtStructure   -- model.structure beim letzten Aufbau
local needsBuild = true
local renders = 0      -- Takte, in denen sich ein Text geändert hat (Tests: kein Neuzeichnen ohne Änderung)

local function digitsOfDays(seconds)
  return #tostring(math.floor((seconds or 0) / SECONDS_PER_DAY))
end

local function barValues()
  return layout.BarValues and layout.BarValues(model) or model.xpBar
end

-- Anker, Höhe und Breite neu (Layoutwechsel, andere Zeilen, Apply)
local function build(db)
  local wanted = Layouts.Get(db.windowLayout)
  if wanted ~= layout then
    elements:HideAll()
    layout = wanted
  end
  local height = layout.Build(elements, model, db)
  layout.Render(elements, model, db)
  window:SetSize(layout.Measure(elements, model, db), height)
  builtStructure, needsBuild = model.structure, false
end

-- Ein Takt: Werte lesen; bei neuer Struktur neu aufbauen, sonst nur geänderte Texte setzen
local function refresh()
  local db = ns.db
  if not db then return end
  ns.TickCache.Run(function()
    local wanted = Layouts.Get(db.windowLayout)
    model:Build(db, wanted.source, wanted.alwaysXpBar)
    if digitsOfDays(model.time.seconds) > elements.dayDigits then
      elements.dayDigits = digitsOfDays(model.time.seconds)
      needsBuild = true
    end
    if needsBuild or wanted ~= layout or model.structure ~= builtStructure then
      build(db)
      renders = renders + 1
    elseif layout.Render(elements, model, db) then
      renders = renders + 1
      local width = layout.Measure(elements, model, db)
      if width > window:GetWidth() then window:SetWidth(width) end
    end
    elements.xpBar:Update(barValues())
  end)
end

-- Struktur neu bilden und gleich zeichnen
local function rebuild()
  model:Invalidate()
  needsBuild = true
  refresh()
end

-- Tests: Zahl der Takte mit geändertem Text, Modell und aktives Layout
function TimerWindow.RenderCount()
  return renders
end

function TimerWindow.Model()
  return model
end

function TimerWindow.Elements()
  return elements
end

function TimerWindow.ActiveLayout()
  return layout and layout.id
end

---------------------------------------------------------------------------
-- Position und Größe (Lib/Frames.lua): ziehbar, solange "Fixieren" aus ist; Größe hält die linke obere Ecke fest
---------------------------------------------------------------------------
-- Sichtbarkeit: showTimer und die Regel windowVisibility; im Edit-Modus immer (auch ausgeschaltet)
local visibility = ns.DisplayVisibility.Attach({
  frame = window, setting = "windowVisibility",
  enabled = function() return ns.db.showTimer end,
  children = { levelTab, sessionTab, instanceTab, elements.xpBar.hover },
  onHover = function(hovered)
    elements.hovered = hovered  -- Layout "xpbar": Texte bei Mauskontakt
    if ns.db and window:IsShown() then refresh() end
  end,
})
-- Mausflächen der Zeilen und Kacheln entstehen erst mit dem ersten Layout
elements.watchHover = function(frame) visibility:WatchHover(frame) end

ns.Frames.Register({
  id = "main", frame = window, label = "EDIT_FRAME_MAIN", default = DEFAULT_POSITION,
  keepTopLeft = true, dragWhenUnlocked = true, settingsPage = SETTINGS_PAGE,
  actionsTip = true, resizable = true,  -- Tooltip über Hintergrund und Zeit: Rechtsklick, Ziehen, Griff, /lt edit (UX W22)
  preview = function(on)
    visibility:SetEditing(on)
  end,
  hide = function() ns.Set("showTimer", false) end,
})

-- Ziehgriff unten rechts ändert die Größe; er hat schon um die linke obere Ecke skaliert
local grip = Widgets.CreateResizeGrip(window, ns.Frames.ClampScale, function(scale)
  ns.Frames.SavePosition("main")
  ns.Frames.SetScale("main", scale)
end)

---------------------------------------------------------------------------
-- Ablauf
---------------------------------------------------------------------------
-- Werte lesen (Roadmap 399): einmal je angezeigter Sekunde (die Zeit zeigt Sekunden) und sofort nach Ereignissen,
-- die Werte ändern (Zähler, XP, Geld, Kampf, Zone); dazwischen prüft der Takt nur zwei Zahlen
local sinceUpdate = 0
local refreshedSecond
local dirty = true

local function markDirty()
  dirty = true
end
TimerWindow.MarkDirty = markDirty
Stats.OnIncrement(markDirty)
for _, event in ipairs({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_MONEY", "TIME_PLAYED_MSG",
  "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
  "QUEST_LOG_UPDATE", "PLAYER_FLAGS_CHANGED" }) do
  ns.RegisterEvent(event, markDirty)
end

ns.SetUpdateScript(window, "TimerWindow", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  local second = math.floor(GetTime())
  if dirty or second ~= refreshedSecond then
    dirty, refreshedSecond = false, second
    refresh()
  end
  -- Ziehgriff nur zeigen, wenn die Maus über dem Fenster ist (oder gerade gezogen wird)
  grip:UpdateAlpha()
end)

-- Ob gelevelt wird (XP-Balken, Zeilen), ändert sich auch ohne Einstellung: Max-Level erreicht oder
-- XP beim Erfahrungsverwalter ab-/angeschaltet
local function relayout()
  if ns.db then rebuild() end
end
ns.OnLevelStarted(relayout)
ns.RegisterEvent("ENABLE_XP_GAIN", relayout)
ns.RegisterEvent("DISABLE_XP_GAIN", relayout)

ns.RegisterApply(function(db)
  local wanted = Layouts.Get(db.windowLayout)
  -- Layout "text": ohne Grund und Rand (eine Chroma-Farbe bleibt für OBS)
  Theme.ApplyBackground(window, db, wanted.background == false and 0 or nil)
  elements:ResetCache()
  rebuild()
  for _, fontString in ipairs({ elements.time, elements.big }) do
    fontString:SetTextColor(Theme.RGB("accent"))  -- Akzentfarbe kann gewechselt haben
  end
  elements.xpBar:ApplyTexture()  -- Akzentfarbe und Balkentextur können gewechselt haben

  grip:SetShown(not db.locked)
  visibility:Update()
end)
