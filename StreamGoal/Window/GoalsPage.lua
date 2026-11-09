-- Reiter "Ziele" im Fenster /sg: oben ein neues Ziel (Kacheln der Zielarten, Formular der Art, aufklappbare Zusätze
-- Frist/Wiederholung/Belohnung/Punkte), darunter die laufenden Ziele mit Zählen, Bearbeiten und Abbrechen.
-- Knopfzeile unter dem Formular: links "Weitere Optionen" (Zusätze auf- und zuklappen), rechts die Hauptaktion
-- "Ziel hinzufügen" und daneben "Als Vorlage speichern" (gleiche Eingabe ohne Zusätze als Vorlage in die Sammlung,
-- Library.lua, für Bingo-Felder und das Glücksrad; legt kein Ziel an). Fehler stehen in einer eigenen Zeile darunter.
-- Zwei weitere Modi derselben Fläche (UX G4, G17):
--   Bearbeiten (Manager.EditGoal): "Bearbeiten" an einer laufenden Zeile lädt das Ziel ins Formular. Die Kacheln
--   weichen einem Hinweis, das Formular zeigt nur, was sich ändern lässt (def.editable, Goals.Edit), die Zusätze sind
--   offen und vorbelegt; bei Checklisten darunter die Teilziele (SubGoalRows.lua). Knöpfe "Speichern" und "Fertig".
--   Vorlage für ein Bingo-Feld (Manager.StartTemplate, vom Reiter Bingo): Art und Eingabe wie sonst, ohne Zusätze;
--   die Hauptaktion speichert die Vorlage, übergibt sie (onSaved) und kehrt zum aufrufenden Reiter zurück.
-- Tooltips: Kacheln erklären, was die Art zählt (<label>_TIP), darunter gedämpft der Chatbefehl; jede Zeile der
-- laufenden Ziele zeigt beim Überfahren Titel, Stand und die Zeilen der Karte (abgeschnittene Titel).
-- Arten mit inForm = false (Bingo: eigener Reiter) haben hier keine Kachel.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local GoalForm = ns.GoalForm
local KindPicker = ns.KindPicker
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local PICKER_TOP = -Manager.HEADER_HEIGHT
local FORM_GAP = 6              -- Kacheln zum Formular
local BUTTONS_GAP = 4           -- Formular zur Knopfzeile
local ACTIVE_GAP = 4            -- Fehlerzeile zur Überschrift "Laufende Ziele"
local EMPTY_BUTTON_GAP = 6      -- "Pakete ansehen" unter dem Hinweis ohne laufende Ziele
local HINT_PADDING = 6          -- unter dem Hinweis beim Bearbeiten
local ADD_MIN_WIDTH = 120
local ACTIVE_ROW = 22
local ROW_BUTTON_MIN_WIDTH = 70  -- "Bearbeiten" und "Abbrechen" einer Zeile (wachsen mit dem Text)
local STEP_WIDTH = 24           -- Knöpfe "-" und "+" bei selbst gezählten Zielen
local STEP_UP, STEP_DOWN = 1, -1
local NESTED_PREFIX = "    "    -- Teilziel einer Checkliste, eingerückt
local ROW_TEXT_GAP = 8

local page = Manager.AddPage({
  key = "goals", label = "SG_TAB_GOALS", settingsPage = ns.SETTINGS_PAGES.TRACKER,
  refresh = function() Manager.LayoutGoalsPage() end,
  render = function() Manager.RenderActive() end,
})

---------------------------------------------------------------------------
-- Arten
---------------------------------------------------------------------------
-- Art im Formular wählbar: im Client verfügbar und nicht mit eigenem Reiter (Bingo)
local function inForm(kind)
  return Goals.IsAvailable(kind) and Goals.GetKind(kind).inForm ~= false
end

-- Wählbare Arten nach Gruppen geordnet (verwandte Arten nebeneinander im Raster)
local function formKinds()
  local list = {}
  for _, group in ipairs(Goals.KIND_GROUPS) do
    for _, kind in ipairs(Goals.KindsOfGroup(group.key)) do
      if inForm(kind) then table.insert(list, kind) end
    end
  end
  return list
end

local selectedKind = formKinds()[1]
local forms = {}            -- [Art] = Formular (GoalForm)
-- Modus der Seite: nil = neues Ziel, { goal } = laufendes Ziel bearbeiten, { template = spec } = Vorlage anlegen
local mode

local formHeader = Widgets.CreateSectionHeader(page)
formHeader:SetPoint("TOPLEFT")
formHeader:SetPoint("TOPRIGHT")
Manager.formHeader = formHeader  -- Tests: Überschrift je Modus

local function primaryAction()
  Manager.PrimaryAction()
end

-- Neue Auswahl (Modus einer Art, Zusätze): andere Felder, andere Höhe; die Seite ordnet sich neu an
local function onFormChange()
  Manager.LayoutGoalsPage()
  Manager.RenderActive()
end

-- Tooltip einer Kachel: was die Art zählt, darunter gedämpft der Chatbefehl (Tests)
function Manager.KindTipLines(kind)
  local def = Goals.GetKind(kind)
  local lines = { { text = L[def.label .. "_TIP"] } }
  if def.usage then table.insert(lines, { text = string.format(L.SG_KIND_TAB_TIP, L[def.usage]), muted = true }) end
  return lines
end

local picker = KindPicker.Create(page, {
  kinds = formKinds,
  label = function(kind) return L[Goals.GetKind(kind).label] end,
  onSelect = function(kind) Manager.SelectKind(kind) end,
  tipLines = Manager.KindTipLines,
})
Manager.picker = picker

for _, kind in ipairs(Goals.KindOrder()) do
  forms[kind] = GoalForm.Build(page, Goals.GetKind(kind).form or {}, primaryAction, onFormChange)
end

-- Zusätze (Frist, Wiederholung, Belohnung, Punkte) unter dem Formular jeder Art, zugeklappt bis "Weitere Optionen"
local extrasForm = GoalForm.Build(page, { fields = Goals.ExtraFields() }, primaryAction, onFormChange)
local extrasShown = false

-- Hinweis an Stelle der Kacheln beim Bearbeiten (die Art steht fest)
local editHint = Manager.CreateHint(page)
editHint:Hide()
Manager.editHint = editHint

-- Teilziele einer Checkliste beim Bearbeiten
local subGoals

---------------------------------------------------------------------------
-- Knopfzeile und Fehler
---------------------------------------------------------------------------
local errorText = Manager.CreateErrorLine(page)
Manager.errorText = errorText  -- Tests: gezeigter Fehler

local function showError(err)
  Manager.ShowError(errorText, err)
end

subGoals = ns.SubGoalRows.Create(page, function(err)
  showError(err)
  Manager.LayoutGoalsPage()
  Manager.RenderActive()
end)
Manager.subGoals = subGoals

function Manager.AddFromForm()
  local form = forms[selectedKind]
  local params, target = form:Read()
  local extras = extrasForm:Read()
  local goal, err = Goals.Create(selectedKind, params, target, extras)
  if not goal then
    showError(err)
    return nil
  end
  showError(nil)
  ns.Print(string.format(L.SG_CHAT_ADDED, Goals.Title(goal)))
  form:Clear()
  extrasForm:Reset()  -- Zusätze gelten nur für dieses Ziel, auch die Auswahl (Wiederholen, Frist zählt)
  return goal
end

-- Eingabe der gewählten Art als Vorlage speichern (Zusätze wie Frist gehören zum laufenden Ziel, nicht dazu)
function Manager.SaveFormAsOwn()
  local form = forms[selectedKind]
  local params, target = form:Read()
  local entry, err = ns.Library.Add(selectedKind, params, target)
  if not entry then
    showError(err)
    return nil
  end
  showError(nil)
  ns.Print(string.format(L.SG_CHAT_OWN_SAVED, ns.Pool.Title(entry)))
  form:Clear()
  return entry
end

-- Knöpfe je Modus; die erste ist die Hauptaktion (ganz rechts, auch bei Enter in einem Feld)
local addButton = Manager.CreateButton(page, "SG_FORM_ADD", function() Manager.AddFromForm() end, ADD_MIN_WIDTH)
local saveOwnButton = Manager.CreateButton(page, "SG_FORM_SAVE_OWN", function() Manager.SaveFormAsOwn() end,
  ADD_MIN_WIDTH)
local saveEditButton = Manager.CreateButton(page, "SG_EDIT_SAVE", function() Manager.SaveEdit() end, ADD_MIN_WIDTH)
local stopEditButton = Manager.CreateButton(page, "SG_EDIT_STOP", function() Manager.StopEditing() end)
local toTemplateButton = Manager.CreateButton(page, "SG_BINGO_TEMPLATE_SAVE", function() Manager.SaveTemplate() end,
  ADD_MIN_WIDTH)
local backButton = Manager.CreateButton(page, "SG_TEMPLATE_BACK", function() Manager.LeaveTemplate() end)
Manager.addButton, Manager.saveOwnButton = addButton, saveOwnButton
Manager.saveEditButton, Manager.stopEditButton = saveEditButton, stopEditButton
Manager.templateButton, Manager.backButton = toTemplateButton, backButton
local MODE_BUTTONS = {
  new = { addButton, saveOwnButton },
  edit = { saveEditButton, stopEditButton },
  template = { toTemplateButton, backButton },
}

local function modeName()
  if not mode then return "new" end
  return mode.goal and "edit" or "template"
end

function Manager.PrimaryAction()
  local name = modeName()
  if name == "edit" then return Manager.SaveEdit() end
  if name == "template" then return Manager.SaveTemplate() end
  return Manager.AddFromForm()
end

-- Zusätze auf- und zuklappen (Eingaben bleiben bis "Ziel hinzufügen" erhalten und gelten auch zugeklappt)
function Manager.ToggleExtras(shown)
  if shown == nil then shown = not extrasShown end
  extrasShown = shown and true or false
  Manager.LayoutGoalsPage()
  Manager.RenderActive()
end

function Manager.ExtrasShown()
  return extrasShown
end

local extrasButton = Manager.CreateButton(page, "SG_FORM_MORE", function() Manager.ToggleExtras() end)
Manager.extrasButton = extrasButton

-- Shift-Klick auf ein Item (Taschen, Beute, Chat) fügt den Link in das fokussierte Textfeld ein
-- Blizzards Chat ruft ChatFrameUtil.InsertLink; ChatEdit_InsertLink ist nur ein Deprecation-Alias (fehlt ohne
-- CVar loadDeprecationFallbacks) und wird nie aufgerufen
local function insertLinkIntoField(link)
  if not link or not page:IsVisible() then return end
  forms[selectedKind]:InsertLink(link)
  extrasForm:InsertLink(link, true)
end
if ChatFrameUtil and ChatFrameUtil.InsertLink then
  hooksecurefunc(ChatFrameUtil, "InsertLink", insertLinkIntoField)
elseif ChatEdit_InsertLink then
  hooksecurefunc("ChatEdit_InsertLink", insertLinkIntoField)
end

-- Shift-Klick auf eine Quest im klassischen Questlog (Classic Era/TBC, Forever mit QuestLogFrame): Blizzard fügt den
-- Link dort nur ein, wenn ein Chat-Eingabefeld offen ist (QuestLogTitleButton_OnClick prüft
-- ChatFrameUtil.GetActiveWindow), sonst kommt InsertLink nie an. Ohne offenes Chatfeld setzen wir den Quest-Link
-- (GetQuestLink, Fallback die Quest-ID) selbst ins fokussierte Feld. Die Weltkarte (QuestMapLogTitleButton_OnClick)
-- ruft InsertLink immer auf und läuft über den Hook oben.
local function chatOpen()
  return ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow() ~= nil
end

local function questIDOfButton(button)
  local offset = FauxScrollFrame_GetOffset and QuestLogListScrollFrame and FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
  local index = button:GetID() + offset
  if GetQuestIDFromLogIndex then
    local questID = GetQuestIDFromLogIndex(index)
    if type(questID) == "number" and questID > 0 then return questID end
  end
  local entry = LT.QuestLog.Entry(index)
  return entry and entry.questID
end

function Manager.OnQuestLogClick(button)
  if not page:IsVisible() or button.isHeader == true or chatOpen() then return end
  if not (IsModifiedClick and IsModifiedClick("CHATLINK")) then return end
  local questID = questIDOfButton(button)
  if not questID then return end
  local link = GetQuestLink and GetQuestLink(questID)
  if type(link) ~= "string" or LT.IsSecret(link) or link == "" then link = tostring(questID) end
  insertLinkIntoField(link)
end
if QuestLogTitleButton_OnClick then
  hooksecurefunc("QuestLogTitleButton_OnClick", Manager.OnQuestLogClick)
end

---------------------------------------------------------------------------
-- Bearbeiten eines laufenden Ziels (UX G17)
---------------------------------------------------------------------------
local kindBeforeMode  -- gewählte Art vor dem Bearbeiten, danach wieder gewählt

-- Formulare auf "neues Ziel" zurück (Filter weg, Eingaben leer)
local function resetForms(kind)
  forms[kind]:SetRowFilter(nil)
  forms[kind]:Reset()
  extrasForm:SetRowFilter(nil)
  extrasForm:Reset()
end

local function leaveMode()
  if mode and mode.goal then
    resetForms(mode.goal.kind)
    if kindBeforeMode then selectedKind = kindBeforeMode end
  end
  mode = nil
  kindBeforeMode = nil
  subGoals:Hide()
end

-- Ziel id ins Formular laden: Eingabe aus goal.source, Zusätze aus dem laufenden Ziel. Rückgabe: true
function Manager.EditGoal(id)
  local goal = Goals.Get(id)
  if not goal or goal.status ~= Goals.ACTIVE or goal.character ~= LT.characterKey or not inForm(goal.kind) then
    return false
  end
  if mode then leaveMode() end
  kindBeforeMode = selectedKind
  mode = { goal = goal }
  selectedKind = goal.kind
  local form = forms[goal.kind]
  local source = goal.source or {}
  form:SetRowFilter(function(param) return Goals.IsEditable(goal.kind, param) end)
  form:Fill(source.params, source.target)
  extrasForm:Fill(Goals.ExtraValues(goal))
  showError(nil)
  Manager.LayoutGoalsPage()
  Manager.RenderActive()
  return true
end

function Manager.EditingGoal()
  return mode and mode.goal or nil
end

function Manager.StopEditing()
  leaveMode()
  showError(nil)
  Manager.LayoutGoalsPage()
  Manager.RenderActive()
end

-- Änderungen übernehmen; Rückgabe: true bei Erfolg (Fehler in der Fehlerzeile)
function Manager.SaveEdit()
  local goal = mode and mode.goal
  if not goal then return false end
  local params, target = forms[goal.kind]:Read()
  local err = Goals.Edit(goal, params, target, extrasForm:Read(), extrasForm:Changes())
  if err then
    showError(err)
    return false
  end
  ns.Print(string.format(L.SG_CHAT_EDITED, Goals.Title(goal)))
  Manager.StopEditing()
  return true
end

---------------------------------------------------------------------------
-- Vorlage für einen anderen Reiter anlegen (Bingo-Feld, UX G4)
---------------------------------------------------------------------------
-- spec = { title = Locale-Key der Überschrift, button = Locale-Key der Hauptaktion (Tooltip <button>_TIP),
--         onSaved(entry), returnPage = Seite danach }
function Manager.StartTemplate(spec)
  if mode then leaveMode() end
  mode = { template = spec }
  showError(nil)
  Manager.ShowPage("goals")
end

function Manager.TemplateMode()
  return mode and mode.template or nil
end

-- Zurück zum aufrufenden Reiter, ohne etwas zu speichern
function Manager.LeaveTemplate()
  local spec = mode and mode.template
  leaveMode()
  if spec and spec.returnPage then
    Manager.ShowPage(spec.returnPage)
  else
    Manager.LayoutGoalsPage()
  end
end

function Manager.SaveTemplate()
  local spec = mode and mode.template
  if not spec then return nil end
  local entry = Manager.SaveFormAsOwn()
  if not entry then return nil end
  if spec.onSaved then spec.onSaved(entry) end
  Manager.LeaveTemplate()
  return entry
end

-- Seite verlassen (anderer Reiter, Fenster zu): ein angefangenes Bearbeiten bzw. die Vorlage verfällt
local function leaveOnHide()
  if mode then leaveMode() end
end
page:HookScript("OnHide", leaveOnHide)
Manager.panel:HookScript("OnHide", leaveOnHide)

---------------------------------------------------------------------------
-- Laufende Ziele
---------------------------------------------------------------------------
local activeHeader = Widgets.CreateSectionHeader(page)
Manager.activeHeader = activeHeader

-- Ohne laufende Ziele: Hinweis und ein Weg zu den Paketen statt einer leeren Fläche; wer noch nie ein Ziel hatte,
-- liest dort die drei Schritte zum ersten Ziel
local emptyText = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
emptyText:SetTextColor(Theme.RGB("muted"))
emptyText:SetJustifyH("LEFT")
emptyText:SetWidth(Manager.PAGE_WIDTH)
Manager.emptyText = emptyText  -- Tests: gezeigter Hinweis
local packsButton = Manager.CreateButton(page, "SG_OPEN_PACKS", function()
  if ns.CollectionView then ns.CollectionView.SelectSection("packs") end
  Manager.ShowPage("collection")
end, ADD_MIN_WIDTH)
Manager.packsButton = packsButton

local activeRows = {}
local activeTop = 0  -- y der Überschrift "Laufende Ziele" (hängt von Kacheln, Formular und Zusätzen ab)

local function stepGoal(id, delta)
  local _, err = Goals.Step(id, delta)
  if err then ns.Print(err) end
end

local confirmCancel = Widgets.ConfirmPopup("STREAMGOAL_CANCEL", "SG_CONFIRM_CANCEL", function(id)
  Manager.CancelGoal(id)
end)

local function smallButton(labelKey, width, onClick)
  local button = Manager.CreateButton(page, labelKey, onClick, width)
  button:SetHeight(ACTIVE_ROW - 4)
  return button
end

-- Tooltip einer Zeile der laufenden Ziele: Stand und die Zeilen der Karte (Art, Frist, Wiederholung, Belohnung)
function Manager.ActiveTipLines(goal)
  local lines = {}
  if Goals.HasCount(goal) then table.insert(lines, { text = Goals.CountText(goal) }) end
  local body = Goals.Body(goal)
  if body then table.insert(lines, { text = body }) end
  if Goals.IsManual(goal) then
    table.insert(lines, { text = Goals.HasCount(goal) and L.SG_ACTIVE_TIP_COUNT or L.SG_ACTIVE_TIP_DONE, muted = true })
  end
  if #lines == 0 then table.insert(lines, { text = L.SG_ACTIVE_TIP_AUTO, muted = true }) end
  return lines
end

local function activeRow(index)
  if activeRows[index] then return activeRows[index] end
  local row = {}
  row.text = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  row.text:SetJustifyH("LEFT")
  row.text:SetWordWrap(false)
  -- Fläche über dem Text für den Tooltip (FontStrings bekommen keine Maus); voller Titel, falls abgeschnitten
  row.hover = CreateFrame("Frame", nil, page)
  row.hover:SetAllPoints(row.text)
  row.hover:EnableMouse(true)
  Manager.AttachTooltip(row.hover, function() return row.goal and Goals.Title(row.goal) or "" end, function()
    return row.goal and Manager.ActiveTipLines(row.goal) or nil
  end)
  row.cancel = smallButton("SG_CANCEL", ROW_BUTTON_MIN_WIDTH, function()
    if row.goal then confirmCancel(Goals.Title(row.goal), row.goal.id) end
  end)
  row.share = smallButton("SG_SHARE", ROW_BUTTON_MIN_WIDTH, function()
    if row.goal then ns.PartySync.ShareGoal(row.goal.id) end
  end)
  row.edit = smallButton("SG_EDIT", ROW_BUTTON_MIN_WIDTH, function()
    if row.goal then Manager.EditGoal(row.goal.id) end
  end)
  row.plus = smallButton("SG_STEP_UP", STEP_WIDTH, function()
    if row.goal then stepGoal(row.goal.id, STEP_UP) end
  end)
  row.minus = smallButton("SG_STEP_DOWN", STEP_WIDTH, function()
    if row.goal then stepGoal(row.goal.id, STEP_DOWN) end
  end)
  activeRows[index] = row
  return row
end

-- "#3  Text  (4 / 5)  noch 1:30"; ohne Zähler nur Nummer und Text
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
  row.hover:Hide()
  row.cancel:Hide()
  row.share:Hide()
  row.edit:Hide()
  row.plus:Hide()
  row.minus:Hide()
end

-- Knöpfe einer Zeile von rechts: Abbrechen, Teilen, Bearbeiten, +, -; der Text füllt den Rest
local function placeRowButtons(row, goal, y)
  Manager.SetLabels({ row.cancel, row.share, row.edit, row.plus, row.minus })
  local manual = Goals.IsManual(goal)
  row.edit:SetShown(inForm(goal.kind))
  row.plus:SetShown(manual)
  row.minus:SetShown(manual and Goals.HasCount(goal))  -- ohne Zähler gibt es nur "erledigt"
  row.cancel:Show()
  row.share:Show()
  local right = 0
  for _, button in ipairs({ row.cancel, row.share, row.edit, row.plus, row.minus }) do
    if button:IsShown() then
      button:ClearAllPoints()
      button:SetPoint("TOPRIGHT", page, "TOPRIGHT", -right, y + 2)
      right = right + button:GetWidth() + Manager.BUTTON_GAP
    end
  end
  row.text:SetWidth(Manager.PAGE_WIDTH - right - ROW_TEXT_GAP)
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

function Manager.RenderActive()
  -- Das bearbeitete Ziel ist inzwischen erreicht, gescheitert oder abgebrochen: Bearbeiten endet
  if mode and mode.goal and mode.goal.status ~= Goals.ACTIVE then
    leaveMode()
    Manager.LayoutGoalsPage()
  end
  local active = listedGoals()
  activeHeader:SetText(string.format(L.SG_ACTIVE_TITLE, Goals.UsedSlots(), Goals.MAX_ACTIVE))
  emptyText:SetText(#ns.db.goals == 0 and L.SG_ACTIVE_EMPTY_FIRST or L.SG_ACTIVE_EMPTY)
  emptyText:SetShown(#active == 0)
  packsButton:SetShown(#active == 0)
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
      row.hover:Show()
      placeRowButtons(row, goal, y)
    elseif activeRows[i] then
      hideRow(activeRows[i])
    end
  end
end

-- Zeile der laufenden Ziele zu einem Ziel (Tests)
function Manager.ActiveRow(id)
  for _, row in ipairs(activeRows) do
    if row.goal and row.goal.id == id then return row end
  end
end

function Manager.CancelGoal(id)
  local goal = Goals.Cancel(id)
  if goal then ns.Print(string.format(L.SG_CHAT_CANCELLED, Goals.Title(goal))) end
end

---------------------------------------------------------------------------
-- Auswahl und Anordnung
---------------------------------------------------------------------------
function Manager.SelectKind(kind)
  if not inForm(kind) or (mode and mode.goal) then return end
  selectedKind = kind
  showError(nil)
  Manager.Refresh()
end

function Manager.SelectedKind()
  return selectedKind
end

-- Kachel einer Art (Tests)
function Manager.KindTile(kind)
  return picker:Tile(kind)
end

-- Formular einer Art bzw. der Zusätze (Tests: Tooltips jeder Zeile)
function Manager.Form(kind)
  return forms[kind]
end

function Manager.ExtrasForm()
  return extrasForm
end

-- Feld des Formulars der gewählten Art oder der Zusätze (Tests): param oder "amount" für die Zahl
function Manager.FormWidget(param)
  return forms[selectedKind]:Widget(param) or extrasForm:Widget(param)
end

-- Überschrift je Modus
local function headerText()
  if mode and mode.goal then return string.format(L.SG_EDIT_TITLE, mode.goal.id, Goals.Title(mode.goal)) end
  if mode and mode.template then return L[mode.template.title] end
  return L.SG_FORM_TITLE
end

-- Kacheln bzw. beim Bearbeiten der Hinweis; Rückgabe: belegte Höhe
local function layoutTop()
  local editing = mode and mode.goal
  picker:SetShown(not editing)
  editHint:SetShown(editing and true or false)
  if not editing then return picker:Layout(PICKER_TOP, selectedKind) end
  editHint:SetText(#(Goals.GetKind(editing.kind).editable or {}) > 0 and L.SG_EDIT_HINT or L.SG_EDIT_HINT_EXTRAS)
  editHint:ClearAllPoints()
  editHint:SetPoint("TOPLEFT", 0, PICKER_TOP)
  return math.max(Manager.ROW, math.ceil(editHint:GetStringHeight() or 0) + HINT_PADDING)
end

-- Kacheln, Formular der gewählten Art, Teilziele (Checkliste beim Bearbeiten), Zusätze (aufgeklappt, mit Eingabe oder
-- beim Bearbeiten), Knopfzeile, Fehler, laufende Ziele
function Manager.LayoutGoalsPage()
  formHeader:SetText(headerText())
  activeHeader:SetText(string.format(L.SG_ACTIVE_TITLE, Goals.UsedSlots(), Goals.MAX_ACTIVE))
  local name = modeName()
  local formTop = PICKER_TOP - layoutTop() - FORM_GAP
  local labelWidth = GoalForm.LabelWidth()
  for kind, form in pairs(forms) do
    form.frame:SetShown(kind == selectedKind)
  end
  local form = forms[selectedKind]
  form:Layout(labelWidth)
  form.frame:ClearAllPoints()
  form.frame:SetPoint("TOPLEFT", 0, formTop)
  local y = formTop - form.height
  if name == "edit" and mode.goal.kind == "checklist" then
    y = y - subGoals:Layout(mode.goal, y, labelWidth)
  else
    subGoals:Hide()
  end
  local showExtras = name == "edit" or (name == "new" and (extrasShown or extrasForm:HasInput()))
  if name == "new" then extrasShown = showExtras end
  extrasForm:SetTexts()
  extrasForm.frame:SetShown(showExtras)
  if showExtras then
    extrasForm:Layout(labelWidth)
    extrasForm.frame:ClearAllPoints()
    extrasForm.frame:SetPoint("TOPLEFT", 0, y)
    y = y - extrasForm.height
  end
  local buttonsY = y - BUTTONS_GAP
  extrasButton.labelKey = extrasShown and "SG_FORM_LESS" or "SG_FORM_MORE"
  extrasButton:SetShown(name == "new")
  if name == "template" then toTemplateButton.labelKey = mode.template.button end
  for key, buttons in pairs(MODE_BUTTONS) do
    for _, button in ipairs(buttons) do button:SetShown(key == name) end
  end
  Manager.SetLabels({ addButton, saveOwnButton, saveEditButton, stopEditButton, toTemplateButton, backButton,
    extrasButton, packsButton })
  Manager.AlignRight(MODE_BUTTONS[name], page, "TOPRIGHT", buttonsY)
  extrasButton:ClearAllPoints()
  extrasButton:SetPoint("TOPLEFT", 0, buttonsY)
  errorText:ClearAllPoints()
  errorText:SetPoint("TOPLEFT", 0, buttonsY - Manager.ROW - 2)
  activeTop = buttonsY - 2 * Manager.ROW - ACTIVE_GAP
  activeHeader:ClearAllPoints()
  activeHeader:SetPoint("TOPLEFT", 0, activeTop)
  activeHeader:SetPoint("TOPRIGHT", 0, activeTop)
  emptyText:ClearAllPoints()
  emptyText:SetPoint("TOPLEFT", 0, activeTop - ACTIVE_ROW)
  packsButton:ClearAllPoints()
  packsButton:SetPoint("TOPLEFT", emptyText, "BOTTOMLEFT", 0, -EMPTY_BUTTON_GAP)
end

-- Unterkante der letzten möglichen Zeile der laufenden Ziele (Tests: passt in die Seite)
function Manager.ActiveBottom()
  return activeTop - (Goals.MAX_ACTIVE + 1) * ACTIVE_ROW
end
