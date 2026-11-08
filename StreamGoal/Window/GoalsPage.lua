-- Reiter "Ziele" im Fenster /sg: oben ein neues Ziel (Gruppen- und Artenreiter, Formular der Art, aufklappbare Zusätze
-- Frist/Wiederholung/Belohnung/Punkte), darunter die laufenden Ziele mit Zählen und Abbrechen.
-- Knopfzeile unter dem Formular: links "Weitere Optionen" (Zusätze auf- und zuklappen), rechts die Hauptaktion
-- "Ziel hinzufügen" und daneben "Als eigenes Ziel speichern" (gleiche Eingabe ohne Zusätze in die Sammlung, Library.lua,
-- für Bingo-Felder und das Glücksrad). Fehler stehen in einer eigenen Zeile darunter über die ganze Breite.
-- Arten mit inForm = false (Bingo: eigener Reiter) haben hier keinen Reiter; Gruppen ohne Art im Client fehlen.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local GoalForm = ns.GoalForm
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local KIND_TAB_ROW = 22
local KIND_TAB_GAP = 14
local KIND_TABS_TOP = -24
local KIND_ROW_GAP = 2          -- zwischen Gruppen- und Artenzeile
local FORM_GAP = 6              -- Reiter zum Formular
local BUTTONS_GAP = 4           -- Formular zur Knopfzeile
local ACTIVE_GAP = 4            -- Fehlerzeile zur Überschrift "Aktive Ziele"
local EMPTY_BUTTON_GAP = 6      -- "Pakete ansehen" unter dem Hinweis ohne aktive Ziele
local ADD_MIN_WIDTH = 120
local ACTIVE_ROW = 22
local CANCEL_WIDTH = 80
local STEP_WIDTH = 24           -- Knöpfe "-" und "+" bei selbst gezählten Zielen
local STEP_UP, STEP_DOWN = 1, -1
local NESTED_PREFIX = "    "    -- Teilziel einer Checkliste, eingerückt

local page = Manager.AddPage({
  key = "goals", label = "SG_TAB_GOALS", settingsPage = ns.SETTINGS_PAGES.TRACKER,
  refresh = function() Manager.LayoutGoalsPage() end,
  render = function() Manager.RenderActive() end,
})

---------------------------------------------------------------------------
-- Arten und Gruppen
---------------------------------------------------------------------------
-- Art im Formular wählbar: im Client verfügbar und nicht mit eigenem Reiter (Bingo)
local function inForm(kind)
  return Goals.IsAvailable(kind) and Goals.GetKind(kind).inForm ~= false
end

local function formKinds(group)
  local list = {}
  for _, kind in ipairs(Goals.KindsOfGroup(group)) do
    if inForm(kind) then table.insert(list, kind) end
  end
  return list
end

local function firstFormKind()
  for _, kind in ipairs(Goals.KindOrder()) do
    if inForm(kind) then return kind end
  end
end

local selectedKind = firstFormKind()
local selectedGroup = Goals.GroupOf(selectedKind)
local lastKindOfGroup = {}  -- [Gruppe] = zuletzt gewählte Art, beim Zurückwechseln wieder gewählt
local kindTabs = {}
local groupTabs = {}        -- [Gruppe] = Reiter
local forms = {}            -- [Art] = Formular (GoalForm)

local formHeader = Widgets.CreateSectionHeader(page)
formHeader:SetPoint("TOPLEFT")
formHeader:SetPoint("TOPRIGHT")

local function addFromForm()
  Manager.AddFromForm()
end

for _, group in ipairs(Goals.KIND_GROUPS) do
  local tab = Widgets.CreateTab(page, Theme.Font("title"), function() Manager.SelectGroup(group.key) end)
  Widgets.AttachTooltip(tab, function() return L[group.label] end, function()
    local names = {}
    for _, kind in ipairs(formKinds(group.key)) do table.insert(names, L[Goals.GetKind(kind).label]) end
    return string.format(L.SG_GROUP_TAB_TIP, table.concat(names, ", "))
  end)
  groupTabs[group.key] = tab
end
for _, kind in ipairs(Goals.KindOrder()) do
  local def = Goals.GetKind(kind)
  local tab = Widgets.CreateTab(page, Theme.Font("body"), function() Manager.SelectKind(kind) end)
  Widgets.AttachTooltip(tab, function() return L[def.label] end, function()
    return def.usage and string.format(L.SG_KIND_TAB_TIP, L[def.usage]) or nil
  end)
  kindTabs[kind] = tab
  forms[kind] = GoalForm.Build(page, def.form or {}, addFromForm)
end

-- Zusätze (Frist, Wiederholung, Belohnung, Punkte) unter dem Formular jeder Art, zugeklappt bis "Weitere Optionen"
local extrasForm = GoalForm.Build(page, { fields = Goals.ExtraFields() }, addFromForm)
local extrasShown = false

-- Reiter { tab, text } ab y = top nebeneinander, in die nächste Zeile, wenn einer nicht mehr passt; Rückgabe: Höhe
local function layoutTabRows(entries, top)
  local left, row = 0, 0
  for _, entry in ipairs(entries) do
    entry.tab:SetLabel(entry.text)
    local width = entry.tab:GetWidth()
    if left > 0 and left + width > Manager.PAGE_WIDTH then
      left, row = 0, row + 1
    end
    entry.tab:ClearAllPoints()
    entry.tab:SetPoint("TOPLEFT", left, top - row * KIND_TAB_ROW)
    left = left + width + KIND_TAB_GAP
  end
  return (row + 1) * KIND_TAB_ROW
end

-- Zeile der Gruppen, darunter die Arten der gewählten Gruppe; Rückgabe: Höhe beider Zeilen
local function layoutKindTabs()
  local groupEntries = {}
  for _, group in ipairs(Goals.KIND_GROUPS) do
    local tab = groupTabs[group.key]
    local available = #formKinds(group.key) > 0
    tab:SetShown(available)
    tab:SetActive(group.key == selectedGroup)
    if available then table.insert(groupEntries, { tab = tab, text = L[group.label] }) end
  end
  local groupsHeight = layoutTabRows(groupEntries, KIND_TABS_TOP) + KIND_ROW_GAP
  local kindEntries = {}
  for _, kind in ipairs(Goals.KindOrder()) do
    local shown = Goals.GroupOf(kind) == selectedGroup and inForm(kind)
    kindTabs[kind]:SetShown(shown)
    kindTabs[kind]:SetActive(kind == selectedKind)
    if shown then table.insert(kindEntries, { tab = kindTabs[kind], text = L[Goals.GetKind(kind).label] }) end
  end
  return groupsHeight + layoutTabRows(kindEntries, KIND_TABS_TOP - groupsHeight)
end

---------------------------------------------------------------------------
-- Knopfzeile und Fehler
---------------------------------------------------------------------------
local errorText = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
errorText:SetTextColor(Theme.RGB("bad"))
errorText:SetJustifyH("LEFT")
errorText:SetWidth(Manager.PAGE_WIDTH)
errorText:SetWordWrap(false)

local function showError(err)
  errorText:SetText(err or "")
end

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
  extrasForm:Clear()
  return goal
end

-- Eingabe der gewählten Art als eigenes Ziel speichern (Zusätze wie Frist gehören zum laufenden Ziel, nicht dazu)
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

local addButton = Manager.CreateButton(page, "SG_FORM_ADD", addFromForm, ADD_MIN_WIDTH)
local saveOwnButton = Manager.CreateButton(page, "SG_FORM_SAVE_OWN", function() Manager.SaveFormAsOwn() end,
  ADD_MIN_WIDTH)
Manager.addButton, Manager.saveOwnButton = addButton, saveOwnButton

-- Zusätze auf- und zuklappen (Eingaben bleiben erhalten und gelten auch zugeklappt)
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

---------------------------------------------------------------------------
-- Laufende Ziele
---------------------------------------------------------------------------
local activeHeader = Widgets.CreateSectionHeader(page)
Manager.activeHeader = activeHeader

-- Ohne aktive Ziele: Hinweis und ein Weg zu den Paketen statt einer leeren Fläche
local emptyText = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
emptyText:SetTextColor(Theme.RGB("muted"))
emptyText:SetJustifyH("LEFT")
emptyText:SetWidth(Manager.PAGE_WIDTH)
local packsButton = Manager.CreateButton(page, "SG_OPEN_PACKS", function()
  if ns.CollectionView then ns.CollectionView.SelectSection("packs") end
  Manager.ShowPage("collection")
end, ADD_MIN_WIDTH)
Manager.packsButton = packsButton

local activeRows = {}
local activeTop = 0  -- y der Überschrift "Aktive Ziele" (hängt von Reiterzeilen, Formular und Zusätzen ab)

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

local function activeRow(index)
  if activeRows[index] then return activeRows[index] end
  local row = {}
  row.text = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  row.text:SetJustifyH("LEFT")
  row.text:SetWordWrap(false)
  row.text:SetWidth(Manager.PAGE_WIDTH - CANCEL_WIDTH - 2 * (STEP_WIDTH + Manager.BUTTON_GAP) - 8)
  row.cancel = smallButton("SG_CANCEL", CANCEL_WIDTH, function()
    if row.goal then confirmCancel(Goals.Title(row.goal), row.goal.id) end
  end)
  row.plus = smallButton("SG_STEP_UP", STEP_WIDTH, function()
    if row.goal then stepGoal(row.goal.id, STEP_UP) end
  end)
  row.plus:SetPoint("RIGHT", row.cancel, "LEFT", -Manager.BUTTON_GAP, 0)
  row.minus = smallButton("SG_STEP_DOWN", STEP_WIDTH, function()
    if row.goal then stepGoal(row.goal.id, STEP_DOWN) end
  end)
  row.minus:SetPoint("RIGHT", row.plus, "LEFT", -Manager.BUTTON_GAP, 0)
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

function Manager.RenderActive()
  local active = listedGoals()
  activeHeader:SetText(string.format(L.SG_ACTIVE_TITLE, Goals.UsedSlots(), Goals.MAX_ACTIVE))
  emptyText:SetText(L.SG_ACTIVE_EMPTY)
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
      row.cancel:ClearAllPoints()
      row.cancel:SetPoint("TOPRIGHT", 0, y + 2)
      Manager.SetLabels({ row.cancel, row.plus, row.minus })
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
-- Auswahl und Anordnung
---------------------------------------------------------------------------
function Manager.SelectKind(kind)
  if not inForm(kind) then return end
  selectedKind = kind
  selectedGroup = Goals.GroupOf(kind)
  lastKindOfGroup[selectedGroup] = kind
  showError(nil)
  Manager.Refresh()
end

-- Gruppe wählen: ihre zuletzt gewählte Art, sonst die erste verfügbare
function Manager.SelectGroup(group)
  local kind = lastKindOfGroup[group] or formKinds(group)[1]
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

-- Feld des Formulars der gewählten Art oder der Zusätze (Tests): param oder "amount" für die Zahl
function Manager.FormWidget(param)
  return forms[selectedKind]:Widget(param) or extrasForm:Widget(param)
end

-- Reiter, Formular der gewählten Art, Zusätze (aufgeklappt oder mit Eingabe), Knopfzeile, Fehler, laufende Ziele
function Manager.LayoutGoalsPage()
  formHeader:SetText(L.SG_FORM_TITLE)
  activeHeader:SetText(string.format(L.SG_ACTIVE_TITLE, Goals.UsedSlots(), Goals.MAX_ACTIVE))
  local formTop = KIND_TABS_TOP - layoutKindTabs() - FORM_GAP
  local labelWidth = GoalForm.LabelWidth()
  for kind, form in pairs(forms) do
    form.frame:SetShown(kind == selectedKind)
  end
  local form = forms[selectedKind]
  form:Layout(labelWidth)
  form.frame:ClearAllPoints()
  form.frame:SetPoint("TOPLEFT", 0, formTop)
  local y = formTop - form.height
  extrasShown = extrasShown or extrasForm:HasInput()
  extrasForm:SetTexts()
  extrasForm.frame:SetShown(extrasShown)
  if extrasShown then
    extrasForm:Layout(labelWidth)
    extrasForm.frame:ClearAllPoints()
    extrasForm.frame:SetPoint("TOPLEFT", 0, y)
    y = y - extrasForm.height
  end
  local buttonsY = y - BUTTONS_GAP
  extrasButton.labelKey = extrasShown and "SG_FORM_LESS" or "SG_FORM_MORE"
  Manager.SetLabels({ addButton, saveOwnButton, extrasButton, packsButton })
  Manager.AlignRight({ addButton, saveOwnButton }, page, "TOPRIGHT", buttonsY)
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
