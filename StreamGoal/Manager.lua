-- Fenster von Level Time Goals (/sg): Reiter "Ziele" (Formular für ein neues Ziel, laufende Ziele mit Zählen und
-- Abbrechen) und Reiter "Historie" (Tabelle aller abgeschlossenen, abgebrochenen und gescheiterten Ziele, gebaut mit
-- TableView von Level Time: Filter, Sortieren, CSV-Export). Fußzeile: Tracker an/aus, Einstellungen, Layout bearbeiten.
-- Formular: je Zielart eine eigene Fläche aus def.form (Kinds.lua und Kinds/*.lua):
--   form = { amount = Locale-Key der Zahl (nil = keine Zahl), fields = { Feld, ... } }
--   Feld: { type = "text", param, label, numeric optional, short optional } | { type = "choice", param, label,
--         values = { Wert, ... }, labels = { [Wert] = Locale-Key } } | { type = "check", param, label }
-- Daraus entstehen params (Text leer = nil, Haken aus = nil) und target (Zahl leer = nil) für Goals.Create.
-- "Als eigenes Ziel speichern" legt dieselbe Eingabe (ohne Zusätze) unter den eigenen Zielen ab (Library.lua): für
-- selbst gewählte Bingo-Felder und das Glücksrad.
-- Breiten je Feldart: Zahlen und kurze Texte (numeric, short) NUMBER_BOX_WIDTH, Texte bis zum rechten Rand, Auswahl
-- CHOICE_WIDTH (wächst mit dem Text); alle Felder beginnen hinter der breitesten Beschriftung aller Formulare.
-- Zielarten: Reiterzeile der Gruppen (Goals.KIND_GROUPS), darunter die Arten der gewählten Gruppe; beide Zeilen brechen
-- um, wenn die Sprache breitere Texte hat.
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
local PAGE_HEIGHT = 520
local PAGE_TOP = -66
local FOOTER_HEIGHT = 34
local ROW = 26                  -- Höhe einer Formularzeile
local MIN_LABEL_WIDTH = 120
local LABEL_GAP = 12            -- Abstand zwischen der breitesten Beschriftung und den Feldern
local NUMBER_BOX_WIDTH = 80     -- Zahlen und kurze Texte (Frist)
local TEXT_BOX_START = 120       -- Breite eines Textfelds vor dem ersten Layout (danach bis zum rechten Rand)
local BOX_HEIGHT = 20
local BOX_BORDER = 6            -- InputBoxTemplate zeichnet seinen Rand links außerhalb
local CHECK_INSET = -4          -- UICheckButtonTemplate hat links Luft im Bild
local CHOICE_WIDTH = 160
local ADD_MIN_WIDTH = 120
local KIND_TAB_ROW = 22
local KIND_TAB_GAP = 14
local KIND_TABS_TOP = -24
local KIND_ROW_GAP = 2          -- zwischen Gruppen- und Artenzeile
local EMPTY_BUTTON_GAP = 6      -- "Vorlagen öffnen" unter dem Hinweis ohne aktive Ziele
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
-- Mittig, nicht darüber: das Fenster ist hoch und stieß sonst bei großer UI-Skalierung an den oberen Rand, wo das
-- Schließen-Kreuz abgeschnitten wirkte
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "StreamGoalWindow")  -- mit ESC schließen
Manager.closeButton = Widgets.CreateCloseButton(panel)  -- innen oben rechts wie bei den Fenstern von Level Time
Manager.panel = panel

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

-- Reiter des Fensters: Manager.AddPage(key, labelKey, render) legt Seite und Reiter an (weitere Dateien, z.B.
-- Vorlagen); render() läuft beim Zeigen der Seite und nach Änderungen der Ziele, solange sie sichtbar ist
Manager.PAGE_WIDTH, Manager.PAGE_HEIGHT = CONTENT_WIDTH, PAGE_HEIGHT
local pages = {}      -- [key] = { frame, tab, labelKey, render }
local pageOrder = {}
local shownPage = "goals"

local function showPage(name)
  shownPage = name
  for key, page in pairs(pages) do
    page.frame:SetShown(key == name)
    page.tab:SetActive(key == name)
  end
  if pages[name].render then pages[name].render() end
end

function Manager.AddPage(key, labelKey, render)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetSize(CONTENT_WIDTH, PAGE_HEIGHT)
  frame:SetPoint("TOPLEFT", MARGIN, PAGE_TOP)
  frame:Hide()
  local tab = Widgets.CreateTab(panel, Theme.Font("title"), function() showPage(key) end)
  local previous = pages[pageOrder[#pageOrder]]
  if previous then
    tab:SetPoint("LEFT", previous.tab, "RIGHT", KIND_TAB_GAP, 0)
  else
    tab:SetPoint("TOPLEFT", MARGIN, -40)
  end
  pages[key] = { frame = frame, tab = tab, labelKey = labelKey, render = render }
  table.insert(pageOrder, key)
  return frame
end

function Manager.ShownPage()
  return panel:IsShown() and shownPage or nil
end

-- Reiter der Seiten in ihrer Reihenfolge (Tests: passen alle in die Breite)
function Manager.PageTabs()
  local tabs = {}
  for _, key in ipairs(pageOrder) do table.insert(tabs, pages[key].tab) end
  return tabs
end

local goalsPage = Manager.AddPage("goals", "SG_TAB_GOALS")
local historyPage = Manager.AddPage("history", "SG_TAB_HISTORY", function() Manager.history:Render() end)

---------------------------------------------------------------------------
-- Reiter "Ziele": Formular je Zielart
---------------------------------------------------------------------------
local formHeader = Widgets.CreateSectionHeader(goalsPage)
formHeader:SetPoint("TOPLEFT")
formHeader:SetPoint("TOPRIGHT")

local selectedKind = Goals.KindOrder()[1]
local selectedGroup = Goals.GroupOf(selectedKind)
local lastKindOfGroup = {}  -- [Gruppe] = zuletzt gewählte Art, beim Zurückwechseln wieder gewählt
local kindTabs = {}
local groupTabs = {}     -- [Gruppe] = Reiter
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
  local button = Widgets.CreateButton(parent, CHOICE_WIDTH, BOX_HEIGHT + 2, nil)
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
    form.amountBox = createBox(form.frame, NUMBER_BOX_WIDTH, true)
    table.insert(form.rows, { label = createLabel(form.frame, y), widget = form.amountBox, labelKey = spec.amount,
      y = y, box = true })
    y = y - ROW
  end
  for _, field in ipairs(spec.fields or {}) do
    local row = { field = field, y = y }
    if field.type == "check" then
      row.widget = Widgets.CreateCheckbox(form.frame, function() end)
    else
      row.label = createLabel(form.frame, y)
      row.labelKey = field.label
      if field.type == "choice" then
        form.choices[field.param] = field.values[1]
        row.widget = createChoice(form.frame, field, form)
      else
        local narrow = field.numeric or field.short
        row.widget = createBox(form.frame, narrow and NUMBER_BOX_WIDTH or TEXT_BOX_START, field.numeric)
        row.box = true
        row.fullWidth = not narrow
      end
    end
    table.insert(form.rows, row)
    y = y - ROW
  end
  form.height = -y
  return form
end

for _, group in ipairs(Goals.KIND_GROUPS) do
  groupTabs[group.key] = Widgets.CreateTab(goalsPage, Theme.Font("title"), function()
    Manager.SelectGroup(group.key)
  end)
end
for _, kind in ipairs(Goals.KindOrder()) do
  kindTabs[kind] = Widgets.CreateTab(goalsPage, Theme.Font("body"), function() Manager.SelectKind(kind) end)
  forms[kind] = buildForm(Goals.GetKind(kind).form or {})
end
-- Zusätze (Frist, Belohnung, Punkte) unter dem Formular jeder Art
local extrasForm = buildForm({ fields = Goals.ExtraFields() })
extrasForm.frame:Show()

-- Im Client verfügbare Arten einer Gruppe
local function availableKinds(group)
  local list = {}
  for _, kind in ipairs(Goals.KindsOfGroup(group)) do
    if Goals.IsAvailable(kind) then table.insert(list, kind) end
  end
  return list
end

-- Reiter { tab, text } ab y = top nebeneinander, in die nächste Zeile, wenn einer nicht mehr passt; Rückgabe: Höhe
local function layoutTabRows(entries, top)
  local left, row = 0, 0
  for _, entry in ipairs(entries) do
    entry.tab:SetLabel(entry.text)
    local width = entry.tab:GetWidth()
    if left > 0 and left + width > CONTENT_WIDTH then
      left, row = 0, row + 1
    end
    entry.tab:ClearAllPoints()
    entry.tab:SetPoint("TOPLEFT", left, top - row * KIND_TAB_ROW)
    left = left + width + KIND_TAB_GAP
  end
  return (row + 1) * KIND_TAB_ROW
end

-- Zeile der Gruppen (ohne Gruppen, deren Arten der Client nicht kennt), darunter die Arten der gewählten Gruppe;
-- Rückgabe: Höhe beider Zeilen
local function layoutKindTabs()
  local groupEntries = {}
  for _, group in ipairs(Goals.KIND_GROUPS) do
    local tab = groupTabs[group.key]
    local available = #availableKinds(group.key) > 0
    tab:SetShown(available)
    tab:SetActive(group.key == selectedGroup)
    if available then table.insert(groupEntries, { tab = tab, text = L[group.label] }) end
  end
  local groupsHeight = layoutTabRows(groupEntries, KIND_TABS_TOP) + KIND_ROW_GAP
  local kindEntries = {}
  for _, kind in ipairs(Goals.KindOrder()) do
    local shown = Goals.GroupOf(kind) == selectedGroup and Goals.IsAvailable(kind)
    kindTabs[kind]:SetShown(shown)
    if shown then table.insert(kindEntries, { tab = kindTabs[kind], text = L[Goals.GetKind(kind).label] }) end
  end
  return groupsHeight + layoutTabRows(kindEntries, KIND_TABS_TOP - groupsHeight)
end


-- Breite der Beschriftungsspalte: breiteste Beschriftung aller Formulare (fr/es sind länger); setzt vorher die
-- Texte der gewählten Sprache, damit schon das erste Layout richtig misst
local function labelColumnWidth()
  for _, form in pairs(forms) do
    for _, row in ipairs(form.rows) do
      if row.label then row.label:SetText(L[row.labelKey]) end
    end
  end
  for _, row in ipairs(extrasForm.rows) do
    if row.label then row.label:SetText(L[row.labelKey]) end
  end
  local widest = MIN_LABEL_WIDTH
  for _, label in ipairs(allLabels) do
    widest = math.max(widest, math.ceil(label:GetStringWidth() or 0) + LABEL_GAP)
  end
  return widest
end

-- Felder hinter die Beschriftungsspalte; Haken stehen in der Feldspalte (ihr Text rechts daneben), Textfelder reichen
-- bis zum rechten Rand
local function refreshForm(form, labelWidth)
  for _, row in ipairs(form.rows) do
    local field = row.field
    row.widget:ClearAllPoints()
    if field and field.type == "check" then
      row.widget.label:SetText(L[field.label])
      row.widget:SetPoint("TOPLEFT", labelWidth + CHECK_INSET, row.y + 2)
    else
      row.widget:SetPoint("TOPLEFT", labelWidth + (row.box and BOX_BORDER or 0), row.y + (row.box and 0 or 2))
    end
    if row.fullWidth then row.widget:SetWidth(CONTENT_WIDTH - labelWidth - BOX_BORDER) end
    if field and field.type == "choice" then
      local value = form.choices[field.param]
      Widgets.SetButtonText(row.widget, L[field.labels[value]], CHOICE_WIDTH)
    end
  end
end

local errorText = goalsPage:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
errorText:SetTextColor(Theme.RGB("bad"))
errorText:SetJustifyH("LEFT")

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

-- Eingabe der gewählten Art als eigenes Ziel speichern (Zusätze wie Frist gehören zum laufenden Ziel, nicht dazu)
function Manager.SaveFormAsOwn()
  local form = forms[selectedKind]
  local params, target = readForm(form)
  local entry, err = ns.Library.Add(selectedKind, params, target)
  if not entry then
    errorText:SetText(err or "")
    return nil
  end
  errorText:SetText("")
  ns.Print(string.format(L.SG_CHAT_OWN_SAVED, ns.Pool.Title(entry)))
  clearForm(form)
  return entry
end

local saveOwnButton = Widgets.CreateButton(goalsPage, ADD_MIN_WIDTH, BOX_HEIGHT + 2, function()
  Manager.SaveFormAsOwn()
end)
saveOwnButton:SetPoint("RIGHT", addButton, "LEFT", -BUTTON_GAP, 0)
Widgets.AttachTooltip(saveOwnButton, function() return L.SG_FORM_SAVE_OWN end,
  function() return L.SG_FORM_SAVE_OWN_TIP end)
Manager.saveOwnButton = saveOwnButton

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

-- Ohne aktive Ziele: Hinweis und ein Weg zu den Vorlagen statt einer leeren Fläche
local emptyText = goalsPage:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
emptyText:SetTextColor(Theme.RGB("muted"))
emptyText:SetJustifyH("LEFT")
local packsButton = Widgets.CreateButton(goalsPage, ADD_MIN_WIDTH, BOX_HEIGHT + 2, function()
  if pages.packs then showPage("packs") end
end)
Manager.packsButton = packsButton

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

-- Laufende Ziele für die Liste: ohne Felder eines Bingo-Scheins (die zeigt der Schein)
local listed = {}
local function listedGoals()
  for i = #listed, 1, -1 do listed[i] = nil end
  for _, goal in ipairs(Goals.Active()) do
    if not goal.cell then table.insert(listed, goal) end
  end
  return listed
end

local function renderActive()
  local active = listedGoals()
  emptyText:SetText(L.SG_ACTIVE_EMPTY)
  emptyText:SetShown(#active == 0)
  packsButton:SetShown(#active == 0 and pages.packs ~= nil)
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
-- Fußzeile: Tracker an/aus, Einstellungen, Layout bearbeiten
---------------------------------------------------------------------------
local trackerCheck = Widgets.CreateCheckbox(panel, function(checked) Tracker.SetShown(checked) end)
trackerCheck:SetPoint("BOTTOMLEFT", MARGIN - 4, 8)
local settingsButton = Widgets.CreateButton(panel, FOOTER_BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, function()
  ns.Options.Toggle(Tracker.SETTINGS_PAGE)
end)
settingsButton:SetPoint("BOTTOMRIGHT", -MARGIN, 12)
-- Edit-Modus von Level Time (alle Anzeigen samt Ziel-Karten verschieben und skalieren); das Fenster geht dafür zu,
-- damit es die Karten nicht verdeckt (im Kampf startet der Modus nicht, dann bleibt es offen)
local editButton = Widgets.CreateButton(panel, FOOTER_BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, function()
  if LT.EditMode.Enter() then panel:Hide() end
end)
editButton:SetPoint("BOTTOMRIGHT", settingsButton, "BOTTOMLEFT", -6, 0)
Widgets.AttachTooltip(editButton, function() return L.EDIT_MODE end, function() return L.EDIT_MODE_TIP end)
Manager.editButton = editButton

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
    return { string.format(L.SG_HISTORY_FOOTER, done, #records, ns.Rewards.TotalPoints()) }
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
  selectedGroup = Goals.GroupOf(kind)
  lastKindOfGroup[selectedGroup] = kind
  errorText:SetText("")
  Manager.Refresh()
end

-- Gruppe wählen: ihre zuletzt gewählte Art, sonst die erste verfügbare
function Manager.SelectGroup(group)
  local kind = lastKindOfGroup[group] or availableKinds(group)[1]
  if kind then Manager.SelectKind(kind) end
end

function Manager.SelectedKind()
  return selectedKind
end

function Manager.SelectedGroup()
  return selectedGroup
end

-- Reiter einer Art bzw. Gruppe (Tests)
function Manager.KindTab(kind)
  return kindTabs[kind]
end

function Manager.GroupTab(group)
  return groupTabs[group]
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
  Widgets.SetButtonText(saveOwnButton, L.SG_FORM_SAVE_OWN, ADD_MIN_WIDTH)
  saveOwnButton:SetShown(selectedKind ~= "bingo")
  errorText:ClearAllPoints()
  errorText:SetPoint("TOPLEFT", 0, addY - 4)
  errorText:SetWidth(CONTENT_WIDTH - addButton:GetWidth() - saveOwnButton:GetWidth() - BUTTON_GAP - 2 * LABEL_GAP)
  activeTop = addY - ROW - 10
  activeHeader:ClearAllPoints()
  activeHeader:SetPoint("TOPLEFT", 0, activeTop)
  activeHeader:SetPoint("TOPRIGHT", 0, activeTop)
  emptyText:ClearAllPoints()
  emptyText:SetPoint("TOPLEFT", 0, activeTop - ACTIVE_ROW)
  packsButton:ClearAllPoints()
  packsButton:SetPoint("TOPLEFT", emptyText, "BOTTOMLEFT", 0, -EMPTY_BUTTON_GAP)
  Widgets.SetButtonText(packsButton, L.SG_OPEN_PACKS, ADD_MIN_WIDTH)
end

-- Alle Texte (Sprache!), Felder der gewählten Art und laufende Ziele neu setzen
function Manager.Refresh()
  title:SetText(L.SG_TITLE)
  for key, page in pairs(pages) do
    page.tab:SetLabel(L[page.labelKey])
    page.tab:SetActive(key == shownPage)
  end
  formHeader:SetText(L.SG_FORM_TITLE)
  activeHeader:SetText(L.SG_ACTIVE_TITLE)
  layoutGoalsPage()
  renderActive()

  trackerCheck.label:SetText(L.SG_SHOW_TRACKER)
  trackerCheck:SetChecked(ns.db.settings.showTracker)
  Widgets.SetButtonText(settingsButton, L.SG_SETTINGS, FOOTER_BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(editButton, L.EDIT_MODE, FOOTER_BUTTON_MIN_WIDTH)
  local page = pages[shownPage]
  if panel:IsShown() and page.render then page.render() end
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
  if not panel:IsShown() then return end
  renderActive()
  if shownPage == "history" then
    Manager.history:Render(nil, false, true)
  elseif shownPage ~= "goals" and pages[shownPage].render then
    pages[shownPage].render()
  end
end)

-- Einstellungen und Sprachwechsel bei offenem Fenster
ns.RegisterApply(function()
  if panel:IsShown() then Manager.Refresh() end
end)
