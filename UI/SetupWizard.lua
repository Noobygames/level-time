-- Einrichtungsassistent (LT-301, Nachfolger der Willkommenskarte): bis zu sechs Schritte mit den wichtigsten
-- Einstellungen: 1 Werte-Voreinstellung, 2 Hauptfenster (Layout oder "Kein Fenster"), 3 Quest-Helfer,
-- 4 Dungeons & Gruppensuche, 5 Komfort & Warnungen, 6 Stream & Fertig. Schalter erscheinen nur, wo es das Feature im
-- laufenden Client gibt (IsAvailable); Schritte ohne Schalter entfallen. Alles wirkt sofort über ns.Set.
-- Einmal für jeden Account (LevelTimerStatsDB.setupWizardSeen), auch für Spieler, die die alte Willkommenskarte kannten;
-- erst nach dem Login, außerhalb von Kampf und Level-Up-Fenster. Später: /lt setup und Einstellungen > Allgemein.
-- Das Layout "Kein Fenster" schaltet nur showTimer aus (Tracking läuft weiter; /lt show, Minimap-Knopf holen es zurück).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Layouts = ns.WindowLayouts

local SetupWizard = {}
ns.SetupWizard = SetupWizard

local WIDTH, HEIGHT = 640, 520
local PADDING = 16
local GAP = 8
local HEADER_HEIGHT = 40
local FOOTER_HEIGHT = 56
local ROW_HEIGHT = 32
local CONTROL_HEIGHT = 32
local CHECK_LABEL_INSET = 34   -- Kästchen (26) plus Abstand und Rand im Vergleich zur Zeilenbreite
local DOT_GAP = 8
local MAX_STEPS = 6
local BUTTON_MIN_WIDTH = 80
local LOGIN_DELAY = 8          -- Sekunden nach dem Login, bis der Assistent erscheinen darf
local RETRY_DELAY = 5          -- erneut prüfen, solange Kampf oder Level-Up-Fenster blockieren
local CONTENT_WIDTH = WIDTH - 2 * PADDING

---------------------------------------------------------------------------
-- Schritte: chips = Auswahl (genau eine aktiv), toggles = Schalter; available blendet nicht vorhandene Features aus
---------------------------------------------------------------------------
local function available(path, name)
  return function() return ns[path] ~= nil and ns[path][name]() end
end

local function presetItems()
  local items = {}
  for _, preset in ipairs(ns.STAT_PRESETS) do
    items[#items + 1] = { label = preset.label, active = function(db) return ns.ActiveStatPreset(db) == preset end,
      pick = function() ns.ApplyStatPreset(preset) end }
  end
  return items
end

local function layoutItems()
  local items = {}
  for _, id in ipairs(Layouts.ORDER) do
    items[#items + 1] = { label = Layouts.Get(id).label,
      active = function(db) return db.showTimer and Layouts.Get(db.windowLayout).id == id end,
      pick = function()
        ns.Set("windowLayout", id)
        ns.Set("showTimer", true)
      end }
  end
  items[#items + 1] = { label = "SETUP_NO_WINDOW", active = function(db) return not db.showTimer end,
    pick = function() ns.Set("showTimer", false) end }
  return items
end

local STEPS = {
  { id = "presets", title = "SETUP_STEP_PRESETS", text = "SETUP_STEP_PRESETS_TEXT", chips = presetItems },
  { id = "window", title = "SETUP_STEP_WINDOW", text = "SETUP_STEP_WINDOW_TEXT", chips = layoutItems,
    note = "SETUP_STEP_WINDOW_NOTE" },
  { id = "quests", title = "SETUP_STEP_QUESTS", text = "SETUP_STEP_QUESTS_TEXT", toggles = {
    { label = "WELCOME_DUNGEONS_CHECK", keys = { "dungeonQuestZoneHint", "dungeonQuestAcceptHint" },
      available = available("DungeonQuests", "IsAvailable") },
    { label = "QUEST_MARKS_TOGGLE", keys = { "questMarks" } },
    { label = "QUEST_TARGETS_TAKE_TOGGLE", keys = { "questTargetsTake" }, available = available("QuestTargets", "IsAvailable") },
    { label = "QUEST_TARGETS_PARTY_TOGGLE", keys = { "questTargetsParty" }, available = available("QuestTargets", "IsAvailable") },
    { label = "BAG_HINTS_TOGGLE", keys = { "bagHints" }, available = available("BagQuestMarks", "IsAvailable") },
    { label = "SHOW_ROUTE_REPLAY", keys = { "routeReplay" } },
  } },
  { id = "dungeons", title = "SETUP_STEP_DUNGEONS", text = "SETUP_STEP_DUNGEONS_TEXT", toggles = {
    { label = "LFG_TOOLTIP_TOGGLE", keys = { "lfgTooltip" }, available = available("LFGData", "IsAvailable") },
    { label = "LFG_WINDOW_TOGGLE", keys = { "lfgWindow" }, available = available("LFGSearch", "IsAvailable") },
    { label = "BOSS_LOOT_TOGGLE", keys = { "bossLoot" }, available = available("BossLoot", "IsAvailable") },
    { label = "TOOLTIP_MECHANICS_TOGGLE", keys = { "tooltipMechanics" }, available = available("MechanicTips", "IsAvailable") },
  } },
  { id = "comfort", title = "SETUP_STEP_COMFORT", text = "SETUP_STEP_COMFORT_TEXT", toggles = {
    { label = "ALERT_TOGGLE_ELITE_SPOTTED", keys = { "alertEliteSpotted" } },
    { label = "ALERT_TOGGLE_RARE_SPOTTED", keys = { "alertRareSpotted" } },
    { label = "DELETE_CHEAPEST_JUNK", keys = { "deleteCheapestJunk" } },
    { label = "WARN_WILDERNESS_LOGOUT", keys = { "warnWildernessLogout" } },
    { label = "WARN_FALLING", keys = { "warnFalling" } },
  } },
  { id = "finish", title = "SETUP_STEP_FINISH", text = "SETUP_STEP_FINISH_TEXT", note = "SETUP_STEP_FINISH_NOTE",
    stream = true, summary = true, always = true },
}

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel(ns.GlobalName("Setup"), 0.95)
panel:SetSize(WIDTH, HEIGHT)
panel:SetPoint("CENTER", 0, 40)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, ns.GlobalName("Setup"))

local header = Widgets.CreateWindowHeader(panel, "")
local progress = header:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
progress:SetPoint("RIGHT", header.actions, "RIGHT")
progress:SetTextColor(Theme.RGB("note"))

local stepTitle = panel:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
local stepText = panel:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
stepText:SetWidth(CONTENT_WIDTH)
stepText:SetJustifyH("LEFT")
local stepNote = panel:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
stepNote:SetWidth(CONTENT_WIDTH)
stepNote:SetJustifyH("LEFT")
stepNote:SetTextColor(Theme.RGB("note"))

-- Beschriftung, Tooltip und Zustand eines Eintrags kommen aus der Definition; Widgets entstehen einmal je Eintrag

local current = 1      -- Index in activeSteps
local activeSteps = {}  -- Schritte, die im laufenden Client Inhalt haben
local refresh

for _, step in ipairs(STEPS) do
  if step.chips then
    step.chipWidgets = {}
    for i, item in ipairs(step.chips()) do
      local chip = Widgets.CreateChip(panel, "", function() item.pick(); refresh() end)
      chip.item = item
      Widgets.AttachTooltip(chip, function() return L[item.label] end, function() return L[item.label .. "_TIP"] end)
      step.chipWidgets[i] = chip
    end
  end
  if step.toggles then
    step.toggleWidgets = {}
    for i, def in ipairs(step.toggles) do
      local check = Widgets.CreateCheckbox(panel, function(checked)
        for _, key in ipairs(def.keys) do ns.Set(key, checked) end
      end)
      check.def = def
      check.label:SetWidth(CONTENT_WIDTH - CHECK_LABEL_INSET)
      check.label:SetJustifyH("LEFT")
      check.label:SetMaxLines(1)
      Widgets.AttachTooltip(check, function() return L[def.label] end, function() return L[def.label .. "_TIP"] end)
      step.toggleWidgets[i] = check
    end
  end
end

-- Schritt "Fertig": Stream-Schalter, Knöpfe und Zusammenfassung
local streamCheck = Widgets.CreateCheckbox(panel, function(checked) ns.StreamMode.SetEnabled(checked) end)
streamCheck.label:SetWidth(CONTENT_WIDTH - CHECK_LABEL_INSET)
streamCheck.label:SetJustifyH("LEFT")
streamCheck.label:SetMaxLines(1)
Widgets.AttachTooltip(streamCheck, function() return L.STREAM_MODE end, function() return L.STREAM_MODE_TIP end)

local function actionButton(labelKey, onClick)
  local button = Widgets.CreateButton(panel, BUTTON_MIN_WIDTH, CONTROL_HEIGHT, onClick)
  button.labelKey = labelKey
  Widgets.AttachTooltip(button, function() return L[labelKey] end, function() return L[labelKey .. "_TIP"] end)
  return button
end

local function close() panel:Hide() end
local editButton = actionButton("SETUP_EDIT_MODE", function()
  close()
  ns.EditMode.Enter()
end)
local settingsButton = actionButton("SETUP_ALL_SETTINGS", function()
  close()
  ns.ShowOptionsPage()
end)

local summaryLines = {}
for i = 1, 4 do
  local line = Widgets.CreateLabelValue(panel)
  line:SetWidth(CONTENT_WIDTH)
  summaryLines[i] = line
end

-- Fuß: Überspringen links, Fortschrittspunkte in der Mitte, Zurück und Weiter (Primär) rechts
local skipButton = actionButton("SETUP_SKIP", close)
skipButton:SetPoint("BOTTOMLEFT", PADDING, (FOOTER_HEIGHT - CONTROL_HEIGHT) / 2)
local nextButton = actionButton("SETUP_NEXT", function()
  if current >= #activeSteps then
    close()
  else
    current = current + 1
    refresh()
  end
end)
nextButton:SetPrimary(true)
nextButton:SetPoint("BOTTOMRIGHT", -PADDING, (FOOTER_HEIGHT - CONTROL_HEIGHT) / 2)
local backButton = actionButton("SETUP_BACK", function()
  current = math.max(1, current - 1)
  refresh()
end)
backButton:SetPoint("RIGHT", nextButton, "LEFT", -GAP, 0)

local dots = {}
for i = 1, MAX_STEPS do dots[i] = Widgets.CreateStatusDot(panel, "muted") end

---------------------------------------------------------------------------
-- Aufbau je Schritt
---------------------------------------------------------------------------
local function stepHasContent(step)
  if step.always then return true end
  for _, def in ipairs(step.toggles or {}) do
    if not def.available or def.available() then return true end
  end
  return step.chips ~= nil
end

local function hideStepWidgets(step)
  for _, widget in ipairs(step.chipWidgets or {}) do widget:Hide() end
  for _, widget in ipairs(step.toggleWidgets or {}) do widget:Hide() end
end

local function placeCheck(check, text, y)
  check:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING - 4, -y)
  check.label:SetText(text)
  check:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + (check.label:GetStringWidth() or 0)), 0, 0)
  check:Show()
end

-- Chips nebeneinander, bei Platzmangel in die nächste Zeile; liefert die Höhe
local function placeChips(widgets, db, top)
  local x, y = 0, 0
  for _, chip in ipairs(widgets) do
    chip:SetText(L[chip.item.label])
    chip:SetOn(chip.item.active(db))
    local width = chip:GetWidth()
    if x > 0 and x + width > CONTENT_WIDTH then x, y = 0, y + CONTROL_HEIGHT + GAP end
    chip:ClearAllPoints()
    chip:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING + x, -(top + y))
    chip:Show()
    x = x + width + GAP
  end
  return y + CONTROL_HEIGHT
end

local function isOn(db, def)
  for _, key in ipairs(def.keys) do
    if db[key] then return true end
  end
  return false
end

-- Zusammenfassung: Werte, Hauptfenster, Stream-Modus, Anzahl eingeschalteter Helfer
local function fillSummary(db)
  local on, total = 0, 0
  for _, step in ipairs(STEPS) do
    for _, def in ipairs(step.toggles or {}) do
      if not def.available or def.available() then
        total = total + 1
        if isOn(db, def) then on = on + 1 end
      end
    end
  end
  local preset = ns.ActiveStatPreset(db)
  local layout = db.showTimer and L[Layouts.Get(db.windowLayout).label] or L.SETUP_NO_WINDOW
  summaryLines[1]:SetValues(L.SETUP_SUMMARY_VALUES, preset and L[preset.label] or L.SETUP_OWN_CHOICE)
  summaryLines[2]:SetValues(L.SETUP_STEP_WINDOW, layout)
  summaryLines[3]:SetValues(L.SETUP_SUMMARY_HELPERS, string.format(L.SETUP_SUMMARY_COUNT, on, total))
  summaryLines[4]:SetValues(L.STREAM_MODE, ns.StreamMode.IsEnabled() and L.SETUP_ON or L.SETUP_OFF)
end

local function showFinish(db, top)
  streamCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING - 4, -top)
  streamCheck.label:SetText(L.STREAM_MODE)
  streamCheck:SetChecked(ns.StreamMode.IsEnabled())
  streamCheck:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + (streamCheck.label:GetStringWidth() or 0)), 0, 0)
  streamCheck:Show()
  top = top + ROW_HEIGHT + GAP
  Widgets.SetButtonText(editButton, L.SETUP_EDIT_MODE, BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(settingsButton, L.SETUP_ALL_SETTINGS, BUTTON_MIN_WIDTH)
  editButton:ClearAllPoints()
  editButton:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING, -top)
  settingsButton:ClearAllPoints()
  settingsButton:SetPoint("LEFT", editButton, "RIGHT", GAP, 0)
  editButton:Show()
  settingsButton:Show()
  top = top + CONTROL_HEIGHT + GAP + GAP
  fillSummary(db)
  for i, line in ipairs(summaryLines) do
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING, -(top + (i - 1) * ROW_HEIGHT))
    line:Show()
  end
end

local function showDots()
  local total = #activeSteps
  local left = -((total * 8) + (total - 1) * DOT_GAP) / 2
  for i, dot in ipairs(dots) do
    dot:SetShown(i <= total)
    dot:ClearAllPoints()
    dot:SetPoint("BOTTOMLEFT", panel, "BOTTOM", left + (i - 1) * (8 + DOT_GAP), (FOOTER_HEIGHT - 8) / 2)
    dot:SetStatus(i == current and "gold" or (i < current and "good" or "muted"))
  end
end

refresh = function()
  local db = ns.db
  if not db then return end
  activeSteps = {}
  for _, step in ipairs(STEPS) do
    hideStepWidgets(step)
    if stepHasContent(step) then activeSteps[#activeSteps + 1] = step end
  end
  current = math.min(math.max(current, 1), #activeSteps)
  local step = activeSteps[current]
  header:SetTitle(L.SETUP_TITLE)
  progress:SetText(string.format(L.SETUP_PROGRESS, current, #activeSteps))
  stepTitle:SetText(L[step.title])
  stepTitle:ClearAllPoints()
  stepTitle:SetPoint("TOPLEFT", PADDING, -(HEADER_HEIGHT + PADDING))
  stepText:SetText(L[step.text])
  stepText:ClearAllPoints()
  stepText:SetPoint("TOPLEFT", stepTitle, "BOTTOMLEFT", 0, -GAP)
  local top = HEADER_HEIGHT + PADDING + 24 + GAP + math.ceil(stepText:GetStringHeight() or 16) + PADDING
  if step.chipWidgets then top = top + placeChips(step.chipWidgets, db, top) + GAP end
  for _, check in ipairs(step.toggleWidgets or {}) do
    check:ClearAllPoints()
    if not check.def.available or check.def.available() then
      placeCheck(check, L[check.def.label], top)
      check:SetChecked(isOn(db, check.def))
      top = top + ROW_HEIGHT
    else
      check:Hide()
    end
  end
  streamCheck:Hide()
  editButton:Hide()
  settingsButton:Hide()
  for _, line in ipairs(summaryLines) do line:Hide() end
  if step.stream then showFinish(db, top) end
  stepNote:ClearAllPoints()
  stepNote:SetPoint("BOTTOMLEFT", PADDING, FOOTER_HEIGHT + GAP)
  stepNote:SetText(step.note and L[step.note] or "")
  Widgets.SetButtonText(skipButton, L.SETUP_SKIP, BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(backButton, L.SETUP_BACK, BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(nextButton, current >= #activeSteps and L.SETUP_DONE or L.SETUP_NEXT, BUTTON_MIN_WIDTH)
  backButton:SetShown(current > 1)
  showDots()
end

function SetupWizard.Show()
  if not ns.db then return end
  current = 1
  refresh()
  panel:Show()
end

function SetupWizard.IsShown()
  return panel:IsShown()
end

-- Test-Zugriff: Schritte (id), aktueller Schritt, Widgets des aktuellen Schritts
function SetupWizard.State()
  local ids = {}
  for i, step in ipairs(activeSteps) do ids[i] = step.id end
  local step = activeSteps[current]
  return { steps = ids, current = current, step = step and step.id, chips = step and step.chipWidgets,
    toggles = step and step.toggleWidgets, stream = streamCheck, summary = summaryLines, dots = dots, next = nextButton }
end

ns.RegisterApply(function()
  if panel:IsShown() then refresh() end
end)

---------------------------------------------------------------------------
-- Einmal für jeden Account, nach dem Login und nur ohne Kampf und Level-Up-Fenster
---------------------------------------------------------------------------
local function tryAutoShow()
  if panel:IsShown() or LevelTimerStatsDB.setupWizardSeen then return end
  if InCombatLockdown() or ns.LevelUpWindow.IsShown() then
    C_Timer.After(RETRY_DELAY, tryAutoShow)
    return
  end
  LevelTimerStatsDB.setupWizardSeen = true
  SetupWizard.Show()
end

ns.OnLogin(function()
  if LevelTimerStatsDB.setupWizardSeen then return end
  C_Timer.After(LOGIN_DELAY, tryAutoShow)
end)
