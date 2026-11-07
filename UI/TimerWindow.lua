-- Anzeigefenster: Reiter "Level | Session | Instanz", Spielzeit im gewählten Bereich, XP-Balken und darunter
-- eine Tabelle der eingeschalteten Stats (Bezeichnung links, Wert rechts).
-- Einstellung "horizontalLayout": dieselben Elemente nebeneinander in einer Zeile (Info-Leiste),
-- der XP-Balken darunter über die ganze Breite.
-- Größe: Ziehgriff unten rechts (erscheint bei Mauskontakt) oder Einstellung "scale" skaliert das ganze Fenster.
-- Rechtsklick öffnet die Einstellungen.
-- Stream-Ansicht: Einstellung "windowBackground" färbt den Hintergrund grün oder magenta ohne Rahmen.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats

local TimerWindow = {
  MIN_SCALE = 0.5,
  MAX_SCALE = 2,
}
ns.TimerWindow = TimerWindow

local UPDATE_INTERVAL = 0.25          -- Sekunden zwischen zwei Anzeige-Updates
local PADDING_X = 20
local PADDING_Y = 8
local LINE_GAP = 3
local NO_VALUE = "-"                -- Zeilen ohne Bereich (Instanz-Reiter ohne Lauf)
local TAB_GAP = 10                    -- Abstand zwischen den Reitern
local MIN_WIDTH = 160
local COLUMN_GAP = 16                 -- Mindestabstand zwischen Bezeichnung und Wert
local TABLE_GAP = 4                   -- Abstand zwischen Zeitanzeige und Tabelle
local WIDEST_TIME_SUFFIX = "d 00h 00m 00s" -- breiteste Zeit (nach den Tagesziffern), für die Fensterbreite
local MIN_DAY_DIGITS = 2
local SECONDS_PER_DAY = 86400
local TIME_WIDTH_SLACK = 2            -- Reserve, damit die Zeit nicht wegen Rundung abgeschnitten wird
local DEFAULT_POSITION = { "TOP", "TOP", 0, -120 }
local DEFAULT_SCALE = 1
local COMPACT_ROW_SETTING = "showXpRate"  -- einzige Zeile im Kompaktmodus
local XP_BAR_HEIGHT = 6
local XP_BAR_BACKGROUND = { 1, 1, 1, 0.1 }
local XP_BAR_RESTED = { 0.3, 0.55, 1, 0.6 }
local XP_BAR_QUESTS = { 1, 0.8, 0.2, 0.75 }  -- XP der fertigen Quests (Einstellung questXpOnBar)
-- Einstellung "windowBackground": Standard oder einfarbig zum Freistellen in OBS (Chroma-Key)
TimerWindow.BACKGROUND_DEFAULT = "default"
TimerWindow.CHROMA_COLORS = {
  green = { 0, 1, 0 },
  magenta = { 1, 0, 1 },
}
local BAR_PADDING_X = 10              -- Info-Leiste: Rand links und rechts
local BAR_ITEM_GAP = 14               -- Info-Leiste: Abstand zwischen zwei Einträgen
local BAR_LABEL_GAP = 4               -- Info-Leiste: Abstand zwischen Bezeichnung und Wert

local window = Widgets.CreatePanel("LevelTimerFrame", 0.8)
window:Hide()  -- erst nach Login anzeigen, wenn Daten und Einstellungen bereitstehen

-- Reiter wählen den Bereich (Einstellung windowScope)
-- Linksklick wählt den Bereich, Rechtsklick öffnet wie auf dem Fenster die Einstellungen
local function createScopeTab(scope)
  local tab = Widgets.CreateTab(window, "GameFontNormalSmall", function(_, mouseButton)
    if mouseButton == "RightButton" then
      ns.ToggleOptions()
    else
      ns.Set("windowScope", scope)
    end
  end)
  tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  return tab
end

local levelTab = createScopeTab(Stats.LEVEL)
local sessionTab = createScopeTab(Stats.SESSION)

local instanceTab = Widgets.CreateTab(window, "GameFontNormalSmall")

-- Rechtsklick auf den Instanz-Reiter (oder Button/Befehl): Daten des Laufs zurücksetzen, nach Rückfrage
instanceTab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
instanceTab:SetScript("OnClick", function(_, mouseButton)
  if mouseButton == "RightButton" then
    ns.ConfirmInstanceReset()
  else
    ns.Set("windowScope", Stats.INSTANCE)
  end
end)
Widgets.AttachTooltip(instanceTab, function() return L.TAB_INSTANCE end, function() return L.TAB_INSTANCE_TIP end)

Widgets.AttachTooltip(levelTab, function() return string.format(L.TAB_LEVEL, ns.level) end, function() return L.TAB_LEVEL_TIP end)
Widgets.AttachTooltip(sessionTab, function() return L.TAB_SESSION end, function() return L.TAB_SESSION_TIP end)

local timeText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timeText:SetTextColor(unpack(Widgets.COLORS.highlight))

-- XP-Balken unter der Zeit: Fortschritt im Level, Erholungs-Bonus als helleres Stück dahinter
local xpBarBackground = window:CreateTexture(nil, "ARTWORK")
xpBarBackground:SetColorTexture(unpack(XP_BAR_BACKGROUND))
xpBarBackground:SetHeight(XP_BAR_HEIGHT)
local xpBarRested = window:CreateTexture(nil, "ARTWORK", nil, 1)
xpBarRested:SetColorTexture(unpack(XP_BAR_RESTED))
xpBarRested:SetPoint("TOPLEFT", xpBarBackground)
xpBarRested:SetHeight(XP_BAR_HEIGHT)
-- Darüber die XP der abgabebereiten Quests (QuestLogXp.lua), nur mit Einstellung questXpOnBar
local xpBarQuests = window:CreateTexture(nil, "ARTWORK", nil, 2)
xpBarQuests:SetColorTexture(unpack(XP_BAR_QUESTS))
xpBarQuests:SetPoint("TOPLEFT", xpBarBackground)
xpBarQuests:SetHeight(XP_BAR_HEIGHT)
local xpBarFill = window:CreateTexture(nil, "ARTWORK", nil, 3)
xpBarFill:SetColorTexture(unpack(Widgets.COLORS.highlight))
xpBarFill:SetPoint("TOPLEFT", xpBarBackground)
xpBarFill:SetHeight(XP_BAR_HEIGHT)
local xpBarParts = { xpBarBackground, xpBarRested, xpBarFill }

-- Tabellenzeilen: Bezeichnung links, Wert rechtsbündig. Je Stat aus ns.STAT_LINES
-- so viele Zeilen wie sie rows hat; stat.setting entscheidet über die Sichtbarkeit.
local rows = {}
for _, stat in ipairs(ns.STAT_LINES) do
  for _, rowDefinition in ipairs(stat.rows) do
    table.insert(rows, {
      stat = stat,
      setting = stat.setting,
      definition = rowDefinition,
      label = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
      value = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
    })
  end
end

local function fontSize(fontString)
  local _, size = fontString:GetFont()
  return size
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

local function growTo(width)
  if width > window:GetWidth() then
    window:SetWidth(width)
  end
end

-- Vertikal: drei Reiter um die Mitte (Session), Level links und Instanz rechts davon
local function tabsWidth()
  local side = math.max(levelTab:GetWidth(), instanceTab:GetWidth())
  return sessionTab:GetWidth() + 2 * (side + TAB_GAP) + 2 * PADDING_X
end

-- Fenster verbreitern, falls Bezeichnung und Wert einer Zeile nicht mehr nebeneinander passen
local function growToFitRows()
  if levelTab:IsShown() then
    growTo(tabsWidth())
  end
  for _, row in ipairs(rows) do
    if row.label:IsShown() then
      growTo(row.label:GetStringWidth() + COLUMN_GAP + row.value:GetStringWidth() + 2 * PADDING_X)
    end
  end
end

-- Info-Leiste: Summe aller sichtbaren Einträge einer Zeile
local function growToFitLine()
  local width = 2 * BAR_PADDING_X + timeText:GetWidth()
  if levelTab:IsShown() then
    width = width + levelTab:GetWidth() + sessionTab:GetWidth() + instanceTab:GetWidth() + 3 * BAR_ITEM_GAP
  end
  for _, row in ipairs(rows) do
    if row.label:IsShown() then
      width = width + BAR_ITEM_GAP + row.label:GetStringWidth() + BAR_LABEL_GAP + row.value:GetStringWidth()
    end
  end
  growTo(width)
end

-- Breiten von Fortschritt und Erholungs-Bonus aus XP, Bedarf und Erholungs-Pool
local function refreshXpBar()
  if not xpBarBackground:IsShown() then return end
  local xpMax = UnitXPMax("player")
  if xpMax <= 0 then return end
  local paddingX = ns.db.horizontalLayout and BAR_PADDING_X or PADDING_X
  local barWidth = window:GetWidth() - 2 * paddingX
  local xp = UnitXP("player")
  local withRested = math.min(xpMax, xp + (GetXPExhaustion() or 0))
  xpBarFill:SetWidth(math.max(1, barWidth * xp / xpMax))
  xpBarRested:SetWidth(math.max(1, barWidth * withRested / xpMax))
  if xpBarQuests:IsShown() then
    local withQuests = math.min(xpMax, xp + ns.QuestLogXp.Get())
    xpBarQuests:SetWidth(math.max(1, barWidth * withQuests / xpMax))
  end
end

-- Ziffern der Tage, für die die Zeitanzeige Platz hat; wächst bei 100 Tagen und mehr
local dayDigits = MIN_DAY_DIGITS
local updateLayout

local function digitsOfDays(seconds)
  return #tostring(math.floor((seconds or 0) / SECONDS_PER_DAY))
end

local function refreshTexts()
  local scope = ns.db.windowScope
  levelTab:SetLabel(string.format(L.TAB_LEVEL, ns.level))
  levelTab:SetActive(scope == Stats.LEVEL)
  sessionTab:SetLabel(L.TAB_SESSION)
  sessionTab:SetActive(scope == Stats.SESSION)
  instanceTab:SetLabel(L.TAB_INSTANCE)
  instanceTab:SetActive(scope == Stats.INSTANCE)

  local seconds = Stats.GetSeconds(scope)
  if digitsOfDays(seconds) > dayDigits then
    dayDigits = digitsOfDays(seconds)
    updateLayout(ns.db)
  end
  local open = Stats.IsOpen(scope)
  timeText:SetText(not open and L.INSTANCE_NONE or seconds and Format.Clock(seconds) or "...")
  for _, row in ipairs(rows) do
    if row.label:IsShown() then
      row.label:SetText(L[row.definition.label])
      row.value:SetText(open and row.definition.value(scope) or NO_VALUE)
    end
  end
  if ns.db.horizontalLayout then
    growToFitLine()
  else
    growToFitRows()
  end
  refreshXpBar()
end

-- Sichtbarkeit unabhängig von der Anordnung: Kompaktmodus ohne Reiter und nur mit XP/h,
-- XP-Balken nur beim Leveln
local function updateVisibility(db)
  local compact = db.compactMode
  levelTab:SetShown(not compact)
  sessionTab:SetShown(not compact)
  instanceTab:SetShown(not compact)

  local showXpBar = db.showXpBar and ns.Experience.IsLeveling()
  for _, part in ipairs(xpBarParts) do
    part:SetShown(showXpBar)
  end
  xpBarQuests:SetShown(showXpBar and db.questXpOnBar)

  for _, row in ipairs(rows) do
    local visible = ns.IsStatShown(row.stat, db)
    if compact then
      visible = row.setting == COMPACT_ROW_SETTING
    end
    row.label:SetShown(visible)
    row.value:SetShown(visible)
  end
end

-- XP-Balken über die ganze Breite bei Höhe y, gibt die Höhe darunter zurück
local function placeXpBar(y, paddingX)
  if not xpBarBackground:IsShown() then return y end
  xpBarBackground:ClearAllPoints()
  xpBarBackground:SetPoint("TOPLEFT", window, "TOPLEFT", paddingX, -y)
  xpBarBackground:SetPoint("TOPRIGHT", window, "TOPRIGHT", -paddingX, -y)
  return y + XP_BAR_HEIGHT + TABLE_GAP
end

-- Vertikal: Reiter, Zeit, XP-Balken und Zeilen untereinander
local function layoutVertical()
  local width = math.max(MIN_WIDTH, timeText:GetWidth() + 2 * PADDING_X)
  timeText:SetJustifyH("CENTER")

  local y = PADDING_Y
  if levelTab:IsShown() then
    levelTab:ClearAllPoints()
    sessionTab:ClearAllPoints()
    sessionTab:SetPoint("TOP", window, "TOP", 0, -y)
    levelTab:ClearAllPoints()
    levelTab:SetPoint("TOPRIGHT", sessionTab, "TOPLEFT", -TAB_GAP, 0)
    instanceTab:ClearAllPoints()
    instanceTab:SetPoint("TOPLEFT", sessionTab, "TOPRIGHT", TAB_GAP, 0)
    y = y + fontSize(levelTab.label) + 4 + LINE_GAP
  end
  timeText:ClearAllPoints()
  timeText:SetPoint("TOP", window, "TOP", 0, -y)
  y = y + fontSize(timeText) + TABLE_GAP
  y = placeXpBar(y, PADDING_X)

  for _, row in ipairs(rows) do
    if row.label:IsShown() then
      row.label:ClearAllPoints()
      row.label:SetPoint("TOPLEFT", window, "TOPLEFT", PADDING_X, -y)
      row.value:ClearAllPoints()
      row.value:SetPoint("TOPRIGHT", window, "TOPRIGHT", -PADDING_X, -y)
      y = y + fontSize(row.label) + LINE_GAP
    end
  end

  window:SetSize(width, y + PADDING_Y)
end

-- Horizontal (Info-Leiste): alle Einträge an der Mittellinie einer Zeile aneinandergereiht,
-- jeder Eintrag links am rechten Rand des vorigen. Die Breite wächst in refreshTexts mit den Texten.
local function layoutHorizontal()
  timeText:SetJustifyH("LEFT")
  local lineHeight = fontSize(timeText)
  local centerY = -(PADDING_Y + lineHeight / 2)
  local previous

  local function chain(element, gap)
    element:ClearAllPoints()
    if previous then
      element:SetPoint("LEFT", previous, "RIGHT", gap, 0)
    else
      element:SetPoint("LEFT", window, "TOPLEFT", BAR_PADDING_X, centerY)
    end
    previous = element
  end

  if levelTab:IsShown() then
    chain(levelTab)
    chain(sessionTab, BAR_ITEM_GAP)
    chain(instanceTab, BAR_ITEM_GAP)
  end
  chain(timeText, BAR_ITEM_GAP)
  for _, row in ipairs(rows) do
    if row.label:IsShown() then
      chain(row.label, BAR_ITEM_GAP)
      chain(row.value, BAR_LABEL_GAP)
    end
  end

  local y = placeXpBar(PADDING_Y + lineHeight + TABLE_GAP, BAR_PADDING_X)
  window:SetSize(0, y - TABLE_GAP + PADDING_Y)
end

-- Fenstergröße aus Schriftgrößen berechnen. Alle Maße gelten bei Skalierung 1;
-- SetScale vergrößert das Ergebnis gleichmäßig.
function updateLayout(db)
  -- Feste Breite der Zeit, damit nichts springt, wenn sich die Ziffern ändern
  timeText:SetText(string.rep("0", dayDigits) .. WIDEST_TIME_SUFFIX)
  timeText:SetWidth(math.ceil(timeText:GetStringWidth()) + TIME_WIDTH_SLACK)
  updateVisibility(db)
  if db.horizontalLayout then
    layoutHorizontal()
  else
    layoutVertical()
  end
end

-- Hintergrund aus den Einstellungen (auch für weitere Anzeigen wie die Split-Liste)
function TimerWindow.ApplyBackground(frame, db)
  local chroma = TimerWindow.CHROMA_COLORS[db.windowBackground]
  if chroma then
    Widgets.SetSolidBackground(frame, chroma)
  else
    Widgets.SetDefaultBackground(frame, db.bgAlpha)
  end
end

---------------------------------------------------------------------------
-- Automatisch zum Reiter Instanz wechseln (Einstellung autoInstanceTab): beim Betreten hin, beim Verlassen
-- zurück zum vorigen Reiter, außer man hat inzwischen selbst gewechselt
---------------------------------------------------------------------------
local scopeBeforeInstance

ns.InstanceCopy.OnEnter(function()
  if not ns.db.autoInstanceTab or scopeBeforeInstance or ns.db.windowScope == Stats.INSTANCE then return end
  scopeBeforeInstance = ns.db.windowScope
  ns.Set("windowScope", Stats.INSTANCE)
end)

ns.InstanceCopy.OnLeave(function()
  local previous = scopeBeforeInstance
  scopeBeforeInstance = nil
  if ns.db.windowScope ~= Stats.INSTANCE then return end  -- man hat selbst gewechselt
  if previous then
    ns.Set("windowScope", previous)
  elseif ns.db.autoInstanceTab then
    ns.Set("windowScope", Stats.LEVEL)  -- der Merker ging bei /reload in der Instanz verloren
  end
end)

---------------------------------------------------------------------------
-- Instanz-Lauf zurücksetzen
---------------------------------------------------------------------------
local RESET_INSTANCE_POPUP = "LEVELTIMER_RESET_INSTANCE"

StaticPopupDialogs[RESET_INSTANCE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function()
    if ns.Instances.ResetCurrent() then ns.Print(L.INSTANCE_RESET_DONE) end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

function ns.ConfirmInstanceReset()
  local run = ns.Instances.GetCurrentRun()
  if not run then
    ns.Print(L.INSTANCE_RESET_NONE)
    return
  end
  StaticPopupDialogs[RESET_INSTANCE_POPUP].text = L.INSTANCE_RESET_CONFIRM  -- aktuelle Sprache
  StaticPopup_Show(RESET_INSTANCE_POPUP, run.name)
end

---------------------------------------------------------------------------
-- Position und Größe
---------------------------------------------------------------------------
local function clampScale(scale)
  return math.max(TimerWindow.MIN_SCALE, math.min(TimerWindow.MAX_SCALE, scale))
end

-- Zuletzt angewendete bzw. gespeicherte Positionstabelle. Ein Profilwechsel kopiert db.pos als neue
-- Tabelle; daran erkennt das Apply, dass das Fenster an die Stelle des Profils muss.
local appliedPos

local function savePosition()
  local point, _, relativePoint, x, y = window:GetPoint()
  ns.db.pos = { point, relativePoint, x, y }
  appliedPos = ns.db.pos
end

-- Gespeicherte Abstände gelten in der Skalierung des Fensters, daher zuerst skalieren
local function restorePosition()
  appliedPos = ns.db.pos
  local pos = ns.db.pos or DEFAULT_POSITION
  window:SetScale(clampScale(ns.db.scale))
  window:ClearAllPoints()
  window:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

local function setScaleKeepingTopLeft(scale)
  Widgets.SetScaleKeepingTopLeft(window, scale)
end

function TimerWindow.ResetLayout()
  ns.db.pos = nil
  ns.db.splitListPos = nil
  ns.db.scale = DEFAULT_SCALE
  restorePosition()
  ns.ApplySettings()
end

window:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
window:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)

window:SetScript("OnMouseUp", function(_, mouseButton)
  if mouseButton == "RightButton" then ns.ToggleOptions() end
end)

-- Ziehgriff unten rechts ändert die Größe (Einstellung scale)
local grip = Widgets.CreateResizeGrip(window, clampScale, function(scale)
  savePosition()
  ns.Set("scale", scale)
end)

---------------------------------------------------------------------------
-- Ablauf
---------------------------------------------------------------------------
local sinceUpdate = 0
ns.SetUpdateScript(window, "TimerWindow", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  refreshTexts()
  -- Ziehgriff nur zeigen, wenn die Maus über dem Fenster ist (oder gerade gezogen wird)
  grip:UpdateAlpha()
end)

ns.OnLogin(restorePosition)

-- Ob gelevelt wird (XP-Balken, Zeilen), ändert sich auch ohne Einstellung: Max-Level erreicht oder
-- XP beim Erfahrungsverwalter ab-/angeschaltet
local function relayout()
  if not ns.db then return end
  updateLayout(ns.db)
  refreshTexts()
end
ns.OnLevelStarted(relayout)
ns.RegisterEvent("ENABLE_XP_GAIN", relayout)
ns.RegisterEvent("DISABLE_XP_GAIN", relayout)

ns.RegisterApply(function(db)
  updateLayout(db)
  refreshTexts()
  TimerWindow.ApplyBackground(window, db)

  -- Anderes Profil: dessen Position und Größe. Sonst Größe aus den Einstellungen (Regler);
  -- beim Login ist sie schon gesetzt
  local scale = clampScale(db.scale)
  if db.pos ~= appliedPos then
    restorePosition()
  elseif math.abs(window:GetScale() - scale) > 0.001 then
    setScaleKeepingTopLeft(scale)
    savePosition()
  end

  grip:SetShown(not db.locked)
  window:SetShown(db.showTimer)
end)
