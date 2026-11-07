-- Fenster von Level Time Goals (/sg): Reiter "Ziele" (Formular für ein neues Ziel, laufende Ziele mit Zählen und
-- Abbrechen) und Reiter "Historie" (Tabelle aller abgeschlossenen, abgebrochenen und gescheiterten Ziele, gebaut mit
-- TableView von Level Time: Filter, Sortieren, CSV-Export). Fußzeile: Tracker an/aus, Einstellungen, Verschieben.
-- Formular: je Zielart eine eigene Fläche aus def.form (Kinds.lua und Kinds/*.lua):
--   form = { amount = Locale-Key der Zahl (nil = keine Zahl), fields = { Feld, ... } }
--   Feld: { type = "text", param, label, width optional } | { type = "choice", param, label, values = { Wert, ... },
--         labels = { [Wert] = Locale-Key } } | { type = "check", param, label }
-- Daraus entstehen params (Text leer = nil, Haken aus = nil) und target (Zahl leer = nil) für Goals.Create.
-- Reiter der Zielarten brechen in weitere Zeilen um, wenn die Sprache breitere Texte hat.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Tracker = ns.Tracker
local L = ns.L
local Widgets = LT.Widgets
local Format = LT.Format
local Theme = LT.Theme

local Manager = {}
ns.Manager = Manager

local MARGIN = 16
local CONTENT_WIDTH = 600
local PAGE_HEIGHT = 480
local PAGE_TOP = -66
local FOOTER_HEIGHT = 34
local ROW = 26                  -- Höhe einer Formularzeile
local MIN_LABEL_WIDTH = 120
local LABEL_GAP = 12            -- Abstand zwischen der breitesten Beschriftung und den Feldern
local AMOUNT_BOX_WIDTH = 70
local TEXT_BOX_WIDTH = 300
local BOX_HEIGHT = 20
local BOX_BORDER = 6            -- InputBoxTemplate zeichnet seinen Rand links außerhalb
local CHOICE_MIN_WIDTH = 140
local ADD_MIN_WIDTH = 120
local KIND_TAB_ROW = 22
local KIND_TAB_GAP = 14
local KIND_TABS_TOP = -24
local ACTIVE_ROW = 22
local CANCEL_WIDTH = 80
local STEP_WIDTH = 24           -- Knöpfe "-" und "+" bei selbst gezählten Zielen
local BUTTON_GAP = 4
local FOOTER_BUTTON_MIN_WIDTH = 90
local STEP_UP, STEP_DOWN = 1, -1

---------------------------------------------------------------------------
-- Fenster und Reiter
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel("StreamGoalWindow", 0.95)
panel:SetSize(CONTENT_WIDTH + 2 * MARGIN, -PAGE_TOP + PAGE_HEIGHT + FOOTER_HEIGHT + MARGIN)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "StreamGoalWindow")  -- mit ESC schließen
Widgets.CreateCloseButton(panel)
Manager.panel = panel

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

local goalsPage = CreateFrame("Frame", nil, panel)
goalsPage:SetSize(CONTENT_WIDTH, PAGE_HEIGHT)
goalsPage:SetPoint("TOPLEFT", MARGIN, PAGE_TOP)
local historyPage = CreateFrame("Frame", nil, panel)
historyPage:SetSize(CONTENT_WIDTH, PAGE_HEIGHT)
historyPage:SetPoint("TOPLEFT", MARGIN, PAGE_TOP)

local pageTabs = {}
local shownPage = "goals"

local function showPage(name)
  shownPage = name
  goalsPage:SetShown(name == "goals")
  historyPage:SetShown(name == "history")
  for key, tab in pairs(pageTabs) do tab:SetActive(key == name) end
  if name == "history" then Manager.history:Render() end
end

local function createPageTab(key, labelKey)
  local tab = Widgets.CreateTab(panel, Theme.Font("title"), function() showPage(key) end)
  tab.labelKey = labelKey
  pageTabs[key] = tab
  return tab
end
local goalsTab = createPageTab("goals", "SG_TAB_GOALS")
local historyTab = createPageTab("history", "SG_TAB_HISTORY")
goalsTab:SetPoint("TOPLEFT", MARGIN, -40)
historyTab:SetPoint("LEFT", goalsTab, "RIGHT", KIND_TAB_GAP, 0)

---------------------------------------------------------------------------
-- Reiter "Ziele": Formular je Zielart
---------------------------------------------------------------------------
local formHeader = Widgets.CreateSectionHeader(goalsPage)
formHeader:SetPoint("TOPLEFT")
formHeader:SetPoint("TOPRIGHT")

local selectedKind = Goals.KindOrder()[1]
local kindTabs = {}
local forms = {}         -- [Art] = { frame, rows = { { label, widget, field } }, amountBox }
local allLabels = {}     -- alle Beschriftungen der Formulare (Breite der Beschriftungsspalte)

local function createLabel(parent, y)
  local label = parent:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
  label:SetPoint("TOPLEFT", 0, y)
  label:SetJustifyH("LEFT")
  table.insert(allLabels, label)
  return label
end

local function createBox(parent, width, numeric)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(width, BOX_HEIGHT)
  box:SetAutoFocus(false)
  box:SetNumeric(numeric and true or false)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEnterPressed", function() Manager.AddFromForm() end)
  return box
end

-- Auswahl: Linksklick nächster, Rechtsklick voriger Wert
local function createChoice(parent, field, form)
  local button = Widgets.CreateButton(parent, CHOICE_MIN_WIDTH, BOX_HEIGHT + 2, nil)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetScript("OnClick", function(_, mouseButton)
    local values = field.values
    local index = 1
    for i, value in ipairs(values) do
      if value == form.choices[field.param] then index = i end
    end
    local step = mouseButton == "RightButton" and -1 or 1
    form.choices[field.param] = values[(index - 1 + step) % #values + 1]
    Manager.Refresh()
  end)
  return button
end

-- Formular aus einer Beschreibung { amount, fields } (Zielart oder Zusätze)
local function buildForm(spec)
  local form = { frame = CreateFrame("Frame", nil, goalsPage), rows = {}, choices = {}, spec = spec }
  form.frame:SetSize(CONTENT_WIDTH, 1)
  form.frame:Hide()
  local y = 0
  if spec.amount then
    form.amountBox = createBox(form.frame, AMOUNT_BOX_WIDTH, true)
    table.insert(form.rows, { label = createLabel(form.frame, y), widget = form.amountBox, labelKey = spec.amount,
      y = y, box = true })
    y = y - ROW
  end
  for _, field in ipairs(spec.fields or {}) do
    local row = { field = field, y = y }
    if field.type == "check" then
      row.widget = Widgets.CreateCheckbox(form.frame, function() end)
      row.widget:SetPoint("TOPLEFT", -4, y + 2)
    else
      row.label = createLabel(form.frame, y)
      row.labelKey = field.label
      if field.type == "choice" then
        form.choices[field.param] = field.values[1]
        row.widget = createChoice(form.frame, field, form)
      else
        row.widget = createBox(form.frame, field.width or TEXT_BOX_WIDTH, field.numeric)
        row.box = true
      end
    end
    table.insert(form.rows, row)
    y = y - ROW
  end
  form.height = -y
  return form
end

for _, kind in ipairs(Goals.KindOrder()) do
  kindTabs[kind] = Widgets.CreateTab(goalsPage, Theme.Font("body"), function() Manager.SelectKind(kind) end)
  forms[kind] = buildForm(Goals.GetKind(kind).form or {})
end
-- Zusätze (Frist, Belohnung, Punkte) unter dem Formular jeder Art
local extrasForm = buildForm({ fields = Goals.ExtraFields() })
extrasForm.frame:Show()

-- Reiter hinter den vorigen setzen oder in die nächste Zeile, wenn er nicht mehr passt
local function placeKindTab(tab, kind, left, row)
  tab:SetLabel(L[Goals.GetKind(kind).label])
  local width = tab:GetWidth()
  if left > 0 and left + width > CONTENT_WIDTH then
    left, row = 0, row + 1
  end
  tab:ClearAllPoints()
  tab:SetPoint("TOPLEFT", left, KIND_TABS_TOP - row * KIND_TAB_ROW)
  return left + width + KIND_TAB_GAP, row
end

-- Reiter der verfügbaren Zielarten in Zeilen umbrechen; Rückgabe: Höhe aller Zeilen
local function layoutKindTabs()
  local left, row = 0, 0
  for _, kind in ipairs(Goals.KindOrder()) do
    local tab = kindTabs[kind]
    local available = Goals.IsAvailable(kind)
    tab:SetShown(available)
    if available then
      left, row = placeKindTab(tab, kind, left, row)
    end
  end
  return (row + 1) * KIND_TAB_ROW
end


-- Breite der Beschriftungsspalte: breiteste Beschriftung aller Formulare (fr/es sind länger)
local function labelColumnWidth()
  local widest = MIN_LABEL_WIDTH
  for _, label in ipairs(allLabels) do
    widest = math.max(widest, math.ceil(label:GetStringWidth() or 0) + LABEL_GAP)
  end
  return widest
end

local function refreshForm(form, labelWidth)
  for _, row in ipairs(form.rows) do
    local field = row.field
    if row.label then row.label:SetText(L[row.labelKey]) end
    if field and field.type == "check" then
      row.widget.label:SetText(L[field.label])
    else
      row.widget:ClearAllPoints()
      row.widget:SetPoint("TOPLEFT", labelWidth + (row.box and BOX_BORDER or 0), row.y + (row.box and 0 or 2))
    end
    if field and field.type == "choice" then
      local value = form.choices[field.param]
      Widgets.SetButtonText(row.widget, L[field.labels[value]], CHOICE_MIN_WIDTH)
    end
  end
end

local errorText = goalsPage:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
errorText:SetTextColor(Theme.RGB("bad"))
errorText:SetJustifyH("LEFT")
errorText:SetWidth(CONTENT_WIDTH - ADD_MIN_WIDTH - 2 * LABEL_GAP)

local function boxText(box)
  return strtrim(box:GetText() or "")
end

-- params und target aus dem Formular der gewählten Art
local function readForm(form)
  local params, target = {}, nil
  for _, row in ipairs(form.rows) do
    local field = row.field
    if not field then
      target = tonumber(boxText(row.widget))
    elseif field.type == "check" then
      params[field.param] = row.widget:GetChecked() and true or nil
    elseif field.type == "choice" then
      params[field.param] = form.choices[field.param]
    else
      local text = boxText(row.widget)
      if field.numeric then
        params[field.param] = tonumber(text)
      else
        params[field.param] = text ~= "" and text or nil
      end
    end
  end
  return params, target
end

local function clearForm(form)
  for _, row in ipairs(form.rows) do
    if row.box then row.widget:SetText("") end
  end
end

function Manager.AddFromForm()
  local form = forms[selectedKind]
  local params, target = readForm(form)
  local extras = readForm(extrasForm)
  local goal, err = Goals.Create(selectedKind, params, target, extras)
  if not goal then
    errorText:SetText(err or "")
    return nil
  end
  errorText:SetText("")
  ns.Print(string.format(L.SG_CHAT_ADDED, Goals.Title(goal)))
  clearForm(form)
  clearForm(extrasForm)
  return goal
end

local addButton = Widgets.CreateButton(goalsPage, ADD_MIN_WIDTH, BOX_HEIGHT + 2, function() Manager.AddFromForm() end)

-- Shift-Klick auf ein Item (Taschen, Beute, Chat) fügt den Link in das fokussierte Textfeld ein
-- Blizzards Chat ruft ChatFrameUtil.InsertLink; ChatEdit_InsertLink ist nur ein Deprecation-Alias (fehlt ohne
-- CVar loadDeprecationFallbacks) und wird nie aufgerufen
local function insertLinkIntoField(link)
  if not link or not panel:IsVisible() then return end
  for _, row in ipairs(forms[selectedKind].rows) do
    local field = row.field
    if field and field.links and row.widget:HasFocus() then row.widget:Insert(link) end
  end
  for _, row in ipairs(extrasForm.rows) do
    if row.box and row.widget:HasFocus() then row.widget:Insert(link) end
  end
end
if ChatFrameUtil and ChatFrameUtil.InsertLink then
  hooksecurefunc(ChatFrameUtil, "InsertLink", insertLinkIntoField)
elseif ChatEdit_InsertLink then
  hooksecurefunc("ChatEdit_InsertLink", insertLinkIntoField)
end

---------------------------------------------------------------------------
-- Reiter "Ziele": laufende Ziele
---------------------------------------------------------------------------
local activeHeader = Widgets.CreateSectionHeader(goalsPage)

local emptyText = goalsPage:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
emptyText:SetTextColor(Theme.RGB("muted"))
emptyText:SetJustifyH("LEFT")

local activeRows = {}
local activeTop = 0  -- y der Überschrift "Aktive Ziele" (hängt von Reiterzeilen und Formular ab)

local function stepGoal(id, delta)
  local _, err = Goals.Step(id, delta)
  if err then ns.Print(err) end
end

local confirmCancel = Widgets.ConfirmPopup("STREAMGOAL_CANCEL", "SG_CONFIRM_CANCEL", function(id)
  Manager.CancelGoal(id)
end)

local function activeRow(index)
  if not activeRows[index] then
    local row = {}
    row.text = goalsPage:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.text:SetWidth(CONTENT_WIDTH - CANCEL_WIDTH - 2 * (STEP_WIDTH + BUTTON_GAP) - 8)
    row.cancel = Widgets.CreateButton(goalsPage, CANCEL_WIDTH, ACTIVE_ROW - 4, function()
      if row.goal then confirmCancel(Goals.Title(row.goal), row.goal.id) end
    end)
    row.plus = Widgets.CreateButton(goalsPage, STEP_WIDTH, ACTIVE_ROW - 4, function()
      if row.goal then stepGoal(row.goal.id, STEP_UP) end
    end)
    row.plus:SetPoint("RIGHT", row.cancel, "LEFT", -BUTTON_GAP, 0)
    Widgets.SetButtonText(row.plus, "+", STEP_WIDTH)
    row.minus = Widgets.CreateButton(goalsPage, STEP_WIDTH, ACTIVE_ROW - 4, function()
      if row.goal then stepGoal(row.goal.id, STEP_DOWN) end
    end)
    row.minus:SetPoint("RIGHT", row.plus, "LEFT", -BUTTON_GAP, 0)
    Widgets.SetButtonText(row.minus, "-", STEP_WIDTH)
    activeRows[index] = row
  end
  return activeRows[index]
end

-- "#3  Text  (4 / 5)"; ohne Zähler nur Nummer und Text
local NESTED_PREFIX = "    "  -- Teilziel einer Checkliste, eingerückt

local function activeLabel(goal)
  local label = string.format("#%d  %s", goal.id, Goals.Title(goal))
  if goal.parentId then label = NESTED_PREFIX .. label end
  if Goals.HasCount(goal) then label = string.format("%s  (%s)", label, Goals.CountText(goal)) end
  local left = ns.Deadlines.Text(goal)
  if left then label = label .. "  " .. left end
  return label
end

local function hideRow(row)
  row.goal = nil
  row.text:Hide()
  row.cancel:Hide()
  row.plus:Hide()
  row.minus:Hide()
end

local function renderActive()
  local active = Goals.Active()
  emptyText:SetText(L.SG_ACTIVE_EMPTY)
  emptyText:SetShown(#active == 0)
  for i = 1, math.max(#active, #activeRows) do
    local goal = active[i]
    if goal then
      local row = activeRow(i)
      local y = activeTop - i * ACTIVE_ROW
      row.goal = goal
      row.text:ClearAllPoints()
      row.text:SetPoint("TOPLEFT", 0, y)
      row.text:SetText(activeLabel(goal))
      row.text:Show()
      row.cancel:ClearAllPoints()
      row.cancel:SetPoint("TOPRIGHT", 0, y + 2)
      Widgets.SetButtonText(row.cancel, L.SG_CANCEL, CANCEL_WIDTH)
      row.cancel:Show()
      local manual = Goals.IsManual(goal)
      row.plus:SetShown(manual)
      row.minus:SetShown(manual and Goals.HasCount(goal))  -- ohne Zähler gibt es nur "erledigt"
    elseif activeRows[i] then
      hideRow(activeRows[i])
    end
  end
end

function Manager.CancelGoal(id)
  local goal = Goals.Cancel(id)
  if goal then ns.Print(string.format(L.SG_CHAT_CANCELLED, Goals.Title(goal))) end
end

---------------------------------------------------------------------------
-- Fußzeile: Tracker an/aus, Einstellungen, Verschieben
---------------------------------------------------------------------------
local trackerCheck = Widgets.CreateCheckbox(panel, function(checked) Tracker.SetShown(checked) end)
trackerCheck:SetPoint("BOTTOMLEFT", MARGIN - 4, 8)
local settingsButton = Widgets.CreateButton(panel, FOOTER_BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, function()
  ns.Options.Toggle(Tracker.SETTINGS_PAGE)
end)
settingsButton:SetPoint("BOTTOMRIGHT", -MARGIN, 12)
local moveButton = Widgets.CreateButton(panel, FOOTER_BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, function()
  LT.EditMode.Toggle()  -- Edit-Modus von Level Time: alle Anzeigen verschieben
end)
moveButton:SetPoint("BOTTOMRIGHT", settingsButton, "BOTTOMLEFT", -6, 0)

---------------------------------------------------------------------------
-- Reiter "Historie"
---------------------------------------------------------------------------
local STATUS_LABELS = { [Goals.DONE] = "SG_STATUS_DONE", [Goals.CANCELLED] = "SG_STATUS_CANCELLED",
  [Goals.FAILED] = "SG_STATUS_FAILED" }
local STATUS_COLORS = { [Goals.DONE] = Theme.COLORS.text, [Goals.CANCELLED] = Theme.COLORS.muted,
  [Goals.FAILED] = Theme.COLORS.bad }

local function characterName(goal)
  local ok, name = pcall(LT.History.DisplayName, goal.character)
  return ok and name or tostring(goal.character)
end

local function duration(goal)
  return math.max(0, (goal.finishedAt or goal.createdAt) - goal.createdAt)
end

local historyColumns = {
  { header = "SG_COL_DATE", width = 80, align = "LEFT",
    value = function(g) return date("%Y-%m-%d", g.finishedAt) end, sort = function(g) return g.finishedAt end },
  { header = "SG_COL_GOAL", width = 210, align = "LEFT", value = function(g) return Goals.Title(g) end },
  { header = "SG_COL_CHARACTER", width = 100, align = "LEFT", value = characterName },
  { header = "SG_COL_PROGRESS", width = 70,
    value = function(g) return Goals.HasCount(g) and Goals.CountText(g) or "" end,
    sort = function(g) return Goals.Fraction(g) end },
  { header = "SG_COL_RESULT", width = 70, align = "LEFT", value = function(g) return L[STATUS_LABELS[g.status]] end },
  { header = "SG_COL_TIME", width = 70, value = function(g) return Format.Duration(duration(g)) end, sort = duration },
}

local historyView = LT.TableView.Create({
  tab = "SG_TAB_HISTORY",
  columns = historyColumns,
  records = function() return Goals.History() end,
  footer = function(_, records)
    local done = 0
    for _, goal in ipairs(records) do
      if goal.status == Goals.DONE then done = done + 1 end
    end
    return { string.format("%d / %d", done, #records) }
  end,
  rowColor = function(goal) return STATUS_COLORS[goal.status] or Theme.COLORS.muted end,
})
Manager.history = historyView.Create(historyPage, CONTENT_WIDTH, PAGE_HEIGHT)

---------------------------------------------------------------------------
-- Anzeige aufbauen
---------------------------------------------------------------------------
function Manager.SelectKind(kind)
  if not Goals.IsAvailable(kind) then return end
  selectedKind = kind
  errorText:SetText("")
  Manager.Refresh()
end

function Manager.SelectedKind()
  return selectedKind
end

-- Feld des Formulars der gewählten Art (Tests): param oder "amount" für die Zahl
function Manager.FormWidget(param)
  for _, form in ipairs({ forms[selectedKind], extrasForm }) do
    for _, row in ipairs(form.rows) do
      if (row.field and row.field.param or "amount") == param then return row.widget end
    end
  end
end

-- Formular der gewählten Art unter den Reitern, darunter Fehlertext und "Ziel hinzufügen", dann die laufenden Ziele
local function layoutGoalsPage()
  local tabsHeight = layoutKindTabs()
  local formTop = KIND_TABS_TOP - tabsHeight - 6
  local labelWidth = labelColumnWidth()
  for kind, form in pairs(forms) do
    refreshForm(form, labelWidth)
    form.frame:SetShown(kind == selectedKind)
    kindTabs[kind]:SetActive(kind == selectedKind)
  end
  refreshForm(extrasForm, labelWidth)
  local form = forms[selectedKind]
  form.frame:ClearAllPoints()
  form.frame:SetPoint("TOPLEFT", 0, formTop)
  local extrasTop = formTop - form.height
  extrasForm.frame:ClearAllPoints()
  extrasForm.frame:SetPoint("TOPLEFT", 0, extrasTop)
  local addY = extrasTop - extrasForm.height - 4
  addButton:ClearAllPoints()
  addButton:SetPoint("TOPRIGHT", 0, addY)
  Widgets.SetButtonText(addButton, L.SG_FORM_ADD, ADD_MIN_WIDTH)
  errorText:ClearAllPoints()
  errorText:SetPoint("TOPLEFT", 0, addY - 4)
  activeTop = addY - ROW - 10
  activeHeader:ClearAllPoints()
  activeHeader:SetPoint("TOPLEFT", 0, activeTop)
  activeHeader:SetPoint("TOPRIGHT", 0, activeTop)
  emptyText:ClearAllPoints()
  emptyText:SetPoint("TOPLEFT", 0, activeTop - ACTIVE_ROW)
end

-- Alle Texte (Sprache!), Felder der gewählten Art und laufende Ziele neu setzen
function Manager.Refresh()
  title:SetText(L.SG_TITLE)
  for key, tab in pairs(pageTabs) do
    tab:SetLabel(L[tab.labelKey])
    tab:SetActive(key == shownPage)
  end
  formHeader:SetText(L.SG_FORM_TITLE)
  activeHeader:SetText(L.SG_ACTIVE_TITLE)
  layoutGoalsPage()
  renderActive()

  trackerCheck.label:SetText(L.SG_SHOW_TRACKER)
  trackerCheck:SetChecked(ns.db.settings.showTracker)
  Widgets.SetButtonText(settingsButton, L.SG_SETTINGS, FOOTER_BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(moveButton, L.SG_MOVE, FOOTER_BUTTON_MIN_WIDTH)
end

function Manager.Toggle(page)
  if not ns.db then return end
  if panel:IsShown() and not page then
    panel:Hide()
    return
  end
  Manager.Refresh()
  showPage(page or shownPage)
  panel:Show()
end

-- Ziele ändern sich auch durch Spielereignisse: offene Liste aktuell halten
Goals.OnChange(function()
  if panel:IsShown() then
    renderActive()
    if shownPage == "history" then Manager.history:Render(nil, false, true) end
  end
end)

-- Einstellungen und Sprachwechsel bei offenem Fenster
ns.RegisterApply(function()
  if panel:IsShown() then Manager.Refresh() end
end)
