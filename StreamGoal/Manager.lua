-- Fenster von Level Time Goals (/sg): Reiter "Ziele" (Formular für ein neues Ziel, laufende Ziele mit Abbrechen,
-- Einstellungen der Anzeige) und Reiter "Historie" (Tabelle aller abgeschlossenen und abgebrochenen Ziele,
-- gebaut mit TableView von Level Time: Filter, Sortieren, CSV-Export).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local Tracker = ns.Tracker
local L = ns.L
local Widgets = LT.Widgets
local Format = LT.Format

local Manager = {}
ns.Manager = Manager

local MARGIN = 16
local CONTENT_WIDTH = 570
local PAGE_HEIGHT = 330
local PAGE_TOP = -66
local FOOTER_HEIGHT = 34
local ROW = 26                  -- Höhe einer Formularzeile
local LABEL_WIDTH = 170
local AMOUNT_BOX_WIDTH = 70
local TEXT_BOX_WIDTH = 300
local BOX_HEIGHT = 20
local ACTIVE_ROW = 22
local MAX_ACTIVE_ROWS = Goals.MAX_ACTIVE
local KIND_TAB_GAP = 14
local CANCEL_WIDTH = 80
local STEP_WIDTH = 24           -- Knöpfe "-" und "+" bei selbst gezählten Zielen
local BUTTON_GAP = 4
local ERROR_COLOR = { 1, 0.4, 0.4 }
local MUTED = Widgets.COLORS.muted

---------------------------------------------------------------------------
-- Formular: welche Felder zu welcher Art gehören
---------------------------------------------------------------------------
-- amount = Beschriftung der Zahl; text1/text2 = Beschriftung der Textfelder (nil = Feld aus);
-- kills zeigt stattdessen Quelle und "nur Schlachtfeld"
local FORM = {
  level = { amount = "SG_FORM_TARGET_LEVEL" },
  kills = { amount = "SG_FORM_AMOUNT", kills = true },
  item = { amount = "SG_FORM_AMOUNT", text1 = "SG_FORM_ITEM", text2 = "SG_FORM_BOSS" },
  bgwin = { amount = "SG_FORM_AMOUNT", text1 = "SG_FORM_BG" },
  custom = { amount = "SG_FORM_COUNTER", text1 = "SG_FORM_TEXT" },
}
local KIND_LABELS = { level = "SG_KIND_LEVEL", kills = "SG_KIND_KILLS", item = "SG_KIND_ITEM", bgwin = "SG_KIND_BGWIN",
  custom = "SG_KIND_CUSTOM" }
local SOURCE_LABELS = { any = "SG_FORM_SOURCE_ANY", pve = "SG_FORM_SOURCE_PVE", pvp = "SG_FORM_SOURCE_PVP" }

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

local function createPageTab(key, labelKey, x)
  local tab = Widgets.CreateTab(panel, "GameFontNormal", function() showPage(key) end)
  tab:SetPoint("TOPLEFT", x, -40)
  tab.labelKey = labelKey
  pageTabs[key] = tab
  return tab
end
createPageTab("goals", "SG_TAB_GOALS", MARGIN)
createPageTab("history", "SG_TAB_HISTORY", MARGIN + 90)

---------------------------------------------------------------------------
-- Reiter "Ziele": Formular
---------------------------------------------------------------------------
local formHeader = Widgets.CreateSectionHeader(goalsPage)
formHeader:SetPoint("TOPLEFT")
formHeader:SetPoint("TOPRIGHT")

local selectedKind = "level"
local kindTabs = {}
for _, kind in ipairs(Kinds.ORDER) do
  kindTabs[kind] = Widgets.CreateTab(goalsPage, "GameFontHighlight", function() Manager.SelectKind(kind) end)
end

local function layoutKindTabs()
  local left = 0
  for _, kind in ipairs(Kinds.ORDER) do
    local tab = kindTabs[kind]
    tab:SetLabel(L[KIND_LABELS[kind]])
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", left, -24)
    left = left + tab:GetWidth() + KIND_TAB_GAP
  end
end

local function createLabel(y)
  local label = goalsPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", 0, y)
  label:SetJustifyH("LEFT")
  return label
end

local function createBox(y, width)
  local box = CreateFrame("EditBox", nil, goalsPage, "InputBoxTemplate")
  box:SetSize(width, BOX_HEIGHT)
  box:SetPoint("TOPLEFT", LABEL_WIDTH, y)
  box:SetAutoFocus(false)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  return box
end

local FIELD_Y = -54
local amountLabel, amountBox = createLabel(FIELD_Y), createBox(FIELD_Y, AMOUNT_BOX_WIDTH)
amountBox:SetNumeric(true)
local text1Label, text1Box = createLabel(FIELD_Y - ROW), createBox(FIELD_Y - ROW, TEXT_BOX_WIDTH)
local text2Label, text2Box = createLabel(FIELD_Y - 2 * ROW), createBox(FIELD_Y - 2 * ROW, TEXT_BOX_WIDTH)

-- Kills: Quelle (Klick wechselt) und Schalter "nur Schlachtfeld"
local killSource = "any"
local sourceButton = Widgets.CreateButton(goalsPage, 140, BOX_HEIGHT + 2, function()
  local order = Kinds.KILL_SOURCES
  for i, source in ipairs(order) do
    if source == killSource then
      killSource = order[i % #order + 1]
      break
    end
  end
  Manager.Refresh()
end)
sourceButton:SetPoint("TOPLEFT", 0, FIELD_Y - ROW)
local battlegroundCheck = Widgets.CreateCheckbox(goalsPage, function() end)
battlegroundCheck:SetPoint("TOPLEFT", -4, FIELD_Y - 2 * ROW - 2)

local errorText = goalsPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
errorText:SetTextColor(unpack(ERROR_COLOR))
errorText:SetPoint("TOPLEFT", 0, FIELD_Y - 3 * ROW - 4)
errorText:SetWidth(CONTENT_WIDTH - 130)
errorText:SetJustifyH("LEFT")

local function boxText(box)
  return strtrim(box:GetText() or "")
end

-- Ziel aus dem Formular; Rückgabe: Ziel oder nil und Fehlertext
local function createFromForm()
  local params
  if selectedKind == "kills" then
    params = { source = killSource, battleground = battlegroundCheck:GetChecked() and true or nil }
  elseif selectedKind == "item" then
    local itemId, link = Kinds.ParseItem(boxText(text1Box))
    local boss = boxText(text2Box)
    params = { itemId = itemId, link = link, boss = boss ~= "" and boss or nil }
  elseif selectedKind == "bgwin" then
    local name = boxText(text1Box)
    params = { battleground = name ~= "" and name or nil }
  elseif selectedKind == "custom" then
    params = { text = boxText(text1Box) }  -- leere Anzahl = ohne Zähler
  end
  return Goals.Create(selectedKind, params, tonumber(boxText(amountBox)))
end

local addButton = Widgets.CreateButton(goalsPage, 120, BOX_HEIGHT + 2, function()
  local goal, err = createFromForm()
  if not goal then
    errorText:SetText(err or "")
    return
  end
  errorText:SetText("")
  ns.Print(string.format(L.SG_CHAT_ADDED, Goals.Title(goal)))
  amountBox:SetText("")
  text1Box:SetText("")
  text2Box:SetText("")
end)
addButton:SetPoint("TOPRIGHT", 0, FIELD_Y - 3 * ROW - 2)

-- Shift-Klick auf ein Item (Taschen, Beute, Chat) fügt den Link ins Feld ein, solange es den Fokus hat
-- Blizzards Chat ruft ChatFrameUtil.InsertLink; ChatEdit_InsertLink ist nur ein Deprecation-Alias (fehlt ohne
-- CVar loadDeprecationFallbacks) und wird nie aufgerufen
local function insertLinkIntoField(link)
  if link and text1Box:IsVisible() and text1Box:HasFocus() and selectedKind == "item" then
    text1Box:Insert(link)
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
local ACTIVE_HEADER_Y = FIELD_Y - 4 * ROW - 10
local activeHeader = Widgets.CreateSectionHeader(goalsPage)
activeHeader:SetPoint("TOPLEFT", 0, ACTIVE_HEADER_Y)
activeHeader:SetPoint("TOPRIGHT", 0, ACTIVE_HEADER_Y)

local emptyText = goalsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
emptyText:SetTextColor(unpack(MUTED))
emptyText:SetPoint("TOPLEFT", 0, ACTIVE_HEADER_Y - ACTIVE_ROW)

local activeRows = {}
local STEP_LABELS = { minus = "-", plus = "+" }

local function stepGoal(id, delta)
  local _, err = Goals.Step(id, delta)
  if err then ns.Print(err) end
end

local function activeRow(index)
  if not activeRows[index] then
    local y = ACTIVE_HEADER_Y - index * ACTIVE_ROW
    local text = goalsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, y)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetWidth(CONTENT_WIDTH - CANCEL_WIDTH - 2 * (STEP_WIDTH + BUTTON_GAP) - 8)
    local cancel = Widgets.CreateButton(goalsPage, CANCEL_WIDTH, ACTIVE_ROW - 4, nil)
    cancel:SetPoint("TOPRIGHT", 0, y + 2)
    local plus = Widgets.CreateButton(goalsPage, STEP_WIDTH, ACTIVE_ROW - 4, nil)
    plus:SetPoint("RIGHT", cancel, "LEFT", -BUTTON_GAP, 0)
    Widgets.SetButtonText(plus, STEP_LABELS.plus, STEP_WIDTH)
    local minus = Widgets.CreateButton(goalsPage, STEP_WIDTH, ACTIVE_ROW - 4, nil)
    minus:SetPoint("RIGHT", plus, "LEFT", -BUTTON_GAP, 0)
    Widgets.SetButtonText(minus, STEP_LABELS.minus, STEP_WIDTH)
    activeRows[index] = { text = text, cancel = cancel, plus = plus, minus = minus }
  end
  return activeRows[index]
end

-- "#3  Text  (4 / 5)"; ohne Zähler nur Nummer und Text
local function activeLabel(goal)
  local label = string.format("#%d  %s", goal.id, Goals.Title(goal))
  if not Goals.HasCount(goal) then return label end
  return string.format("%s  (%d / %d)", label, goal.progress, goal.target)
end

local function renderActive()
  local active = Goals.Active()
  emptyText:SetText(L.SG_ACTIVE_EMPTY)
  emptyText:SetShown(#active == 0)
  for i = 1, math.max(#active, #activeRows) do
    local goal = active[i]
    if goal and i <= MAX_ACTIVE_ROWS then
      local row = activeRow(i)
      row.text:SetText(activeLabel(goal))
      row.text:Show()
      Widgets.SetButtonText(row.cancel, L.SG_CANCEL, CANCEL_WIDTH)
      row.cancel:SetScript("OnClick", function() Manager.CancelGoal(goal.id) end)
      row.cancel:Show()
      local manual = Goals.IsManual(goal)
      row.plus:SetScript("OnClick", function() stepGoal(goal.id, 1) end)
      row.minus:SetScript("OnClick", function() stepGoal(goal.id, -1) end)
      row.plus:SetShown(manual)
      row.minus:SetShown(manual and Goals.HasCount(goal))  -- ohne Zähler gibt es nur "erledigt"
    elseif activeRows[i] then
      activeRows[i].text:Hide()
      activeRows[i].cancel:Hide()
      activeRows[i].plus:Hide()
      activeRows[i].minus:Hide()
    end
  end
end

function Manager.CancelGoal(id)
  local goal = Goals.Cancel(id)
  if goal then ns.Print(string.format(L.SG_CHAT_CANCELLED, Goals.Title(goal))) end
end

---------------------------------------------------------------------------
-- Fußzeile: Einstellungen der Anzeige
---------------------------------------------------------------------------
local trackerCheck = Widgets.CreateCheckbox(panel, function(checked) Tracker.SetShown(checked) end)
trackerCheck:SetPoint("BOTTOMLEFT", MARGIN - 4, 8)
local soundCheck = Widgets.CreateCheckbox(panel, function(checked) ns.db.settings.sound = checked end)
local moveButton = Widgets.CreateButton(panel, 90, BOX_HEIGHT + 2, function()
  Tracker.mover.SetMoving(not Tracker.mover.IsMoving())
end)
moveButton:SetPoint("BOTTOMRIGHT", -MARGIN - 96, 12)
local resetButton = Widgets.CreateButton(panel, 90, BOX_HEIGHT + 2, function() Tracker.mover.Reset() end)
resetButton:SetPoint("BOTTOMRIGHT", -MARGIN, 12)

---------------------------------------------------------------------------
-- Reiter "Historie"
---------------------------------------------------------------------------
local WHITE = { 1, 1, 1 }
local STATUS_LABELS = { [Goals.DONE] = "SG_STATUS_DONE", [Goals.CANCELLED] = "SG_STATUS_CANCELLED" }

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
  { header = "SG_COL_GOAL", width = 190, align = "LEFT", value = function(g) return Goals.Title(g) end },
  { header = "SG_COL_CHARACTER", width = 100, align = "LEFT", value = characterName },
  { header = "SG_COL_PROGRESS", width = 60,
    value = function(g) return Goals.HasCount(g) and string.format("%d/%d", g.progress, g.target) or "" end,
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
  rowColor = function(goal) return goal.status == Goals.DONE and WHITE or MUTED end,
})
Manager.history = historyView.Create(historyPage, CONTENT_WIDTH, PAGE_HEIGHT)

---------------------------------------------------------------------------
-- Anzeige aufbauen
---------------------------------------------------------------------------
function Manager.SelectKind(kind)
  selectedKind = kind
  errorText:SetText("")
  Manager.Refresh()
end

-- Alle Texte (Sprache!), Felder der gewählten Art und laufende Ziele neu setzen
function Manager.Refresh()
  title:SetText(L.SG_TITLE)
  for key, tab in pairs(pageTabs) do tab:SetLabel(L[tab.labelKey]); tab:SetActive(key == shownPage) end
  formHeader:SetText(L.SG_FORM_TITLE)
  activeHeader:SetText(L.SG_ACTIVE_TITLE)
  layoutKindTabs()
  for kind, tab in pairs(kindTabs) do tab:SetActive(kind == selectedKind) end

  local form = FORM[selectedKind]
  amountLabel:SetText(L[form.amount])
  text1Label:SetText(form.text1 and L[form.text1] or "")
  text2Label:SetText(form.text2 and L[form.text2] or "")
  text1Label:SetShown(form.text1 ~= nil)
  text1Box:SetShown(form.text1 ~= nil)
  text2Label:SetShown(form.text2 ~= nil)
  text2Box:SetShown(form.text2 ~= nil)
  sourceButton:SetShown(form.kills == true)
  battlegroundCheck:SetShown(form.kills == true)
  battlegroundCheck.label:SetText(L.SG_FORM_ONLY_BG)
  Widgets.SetButtonText(sourceButton, L[SOURCE_LABELS[killSource]], 140)
  Widgets.SetButtonText(addButton, L.SG_FORM_ADD, 120)

  renderActive()

  trackerCheck.label:SetText(L.SG_SHOW_TRACKER)
  trackerCheck:SetChecked(ns.db.settings.showTracker)
  -- Ton-Schalter hinter dem Text des ersten
  soundCheck:ClearAllPoints()
  soundCheck:SetPoint("LEFT", trackerCheck.label, "RIGHT", 14, 0)
  soundCheck.label:SetText(L.SG_SOUND)
  soundCheck:SetChecked(ns.db.settings.sound)
  Widgets.SetButtonText(moveButton, L.SG_MOVE, 90)
  Widgets.SetButtonText(resetButton, L.SG_RESET_POSITION, 90)
  moveButton:ClearAllPoints()
  moveButton:SetPoint("BOTTOMRIGHT", resetButton, "BOTTOMLEFT", -6, 0)
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

-- Sprachwechsel in Level Time bei offenem Fenster
LT.RegisterApply(function()
  if panel:IsShown() then Manager.Refresh() end
end)
