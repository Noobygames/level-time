-- Formular einer Zielart (oder der Zusätze) im Reiter "Ziele" aus einer Beschreibung (def.form, Kinds.lua):
--   spec = { amount = Locale-Key der Zahl (nil = keine Zahl), fields = { Feld, ... } }
--   Feld: { type = "text", param, label, numeric optional, short optional, links optional } | { type = "choice", param,
--         label, values = { Wert, ... }, labels = { [Wert] = Locale-Key } } | { type = "check", param, label }
-- form:Read() liefert params (Text leer = nil, Haken aus = nil) und target (Zahl leer = nil) für Goals.Create.
-- Breiten je Feldart: Zahlen und kurze Texte (numeric, short) NUMBER_BOX_WIDTH, Texte bis zum rechten Rand, Auswahl
-- CHOICE_WIDTH (wächst mit dem Text); alle Felder beginnen hinter der breitesten Beschriftung aller Formulare
-- (GoalForm.LabelWidth), damit das Formular beim Wechsel der Art nicht springt.
local _, ns = ...
local LT = ns.LT
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets

local GoalForm = {}
ns.GoalForm = GoalForm

local MIN_LABEL_WIDTH = 120
local LABEL_GAP = 12            -- Abstand zwischen der breitesten Beschriftung und den Feldern
local NUMBER_BOX_WIDTH = 80     -- Zahlen und kurze Texte (Frist)
local TEXT_BOX_START = 120      -- Breite eines Textfelds vor dem ersten Layout (danach bis zum rechten Rand)
local CHECK_INSET = -4          -- UICheckButtonTemplate hat links Luft im Bild
local CHOICE_WIDTH = 160
local AMOUNT = "amount"         -- Name der Zahl in form:Widget

local allForms = {}

-- Auswahl: Linksklick nächster, Rechtsklick voriger Wert; der Text folgt sofort
local function createChoice(form, row)
  local field = row.field
  local button = Widgets.CreateButton(form.frame, CHOICE_WIDTH, Manager.BOX_HEIGHT + 2, nil)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetScript("OnClick", function(_, mouseButton)
    local values = field.values
    local index = 1
    for i, value in ipairs(values) do
      if value == form.choices[field.param] then index = i end
    end
    local step = mouseButton == "RightButton" and -1 or 1
    form.choices[field.param] = values[(index - 1 + step) % #values + 1]
    form:SetTexts()
  end)
  Widgets.AttachTooltip(button, function() return L[field.label] end, function() return L.SG_FORM_CHOICE_TIP end)
  return button
end

-- Formular auf parent bauen; onEnter läuft bei Enter in einem Textfeld
function GoalForm.Build(parent, spec, onEnter)
  local form = { frame = CreateFrame("Frame", nil, parent), rows = {}, choices = {}, spec = spec }
  form.frame:SetSize(Manager.PAGE_WIDTH, 1)
  form.frame:Hide()
  local y = 0
  local function addRow(row)
    row.y = y
    if row.labelKey then
      row.label = Manager.CreateLabel(form.frame)
      row.label:SetPoint("TOPLEFT", 0, y)
    end
    table.insert(form.rows, row)
    y = y - Manager.ROW
  end
  if spec.amount then
    local box = Manager.CreateTextBox(form.frame, onEnter, true)
    box:SetWidth(NUMBER_BOX_WIDTH)
    addRow({ widget = box, labelKey = spec.amount, box = true })
  end
  for _, field in ipairs(spec.fields or {}) do
    local row = { field = field }
    if field.type == "check" then
      row.widget = Widgets.CreateCheckbox(form.frame, function() end)
    elseif field.type == "choice" then
      row.labelKey = field.label
      form.choices[field.param] = field.values[1]
      row.widget = createChoice(form, row)
    else
      row.labelKey = field.label
      local narrow = field.numeric or field.short
      row.widget = Manager.CreateTextBox(form.frame, onEnter, field.numeric)
      row.widget:SetWidth(narrow and NUMBER_BOX_WIDTH or TEXT_BOX_START)
      row.box = true
      row.fullWidth = not narrow
    end
    addRow(row)
  end
  form.height = -y

  -- Beschriftungen und Auswahltexte in der gewählten Sprache
  function form:SetTexts()
    for _, row in ipairs(self.rows) do
      if row.label then row.label:SetText(L[row.labelKey]) end
      local field = row.field
      if field and field.type == "check" then row.widget.label:SetText(L[field.label]) end
      if field and field.type == "choice" then
        Widgets.SetButtonText(row.widget, L[field.labels[self.choices[field.param]]], CHOICE_WIDTH)
      end
    end
  end

  -- Felder hinter die Beschriftungsspalte; Haken stehen in der Feldspalte (ihr Text rechts daneben), Textfelder
  -- reichen bis zum rechten Rand
  function form:Layout(labelWidth)
    self:SetTexts()
    for _, row in ipairs(self.rows) do
      local field = row.field
      row.widget:ClearAllPoints()
      if field and field.type == "check" then
        row.widget:SetPoint("TOPLEFT", labelWidth + CHECK_INSET, row.y + 2)
      else
        row.widget:SetPoint("TOPLEFT", labelWidth + (row.box and Manager.BOX_BORDER or 0), row.y + (row.box and 0 or 2))
      end
      if row.fullWidth then row.widget:SetWidth(Manager.PAGE_WIDTH - labelWidth - Manager.BOX_BORDER) end
    end
  end

  -- params und target der Eingabe
  function form:Read()
    local params, target = {}, nil
    for _, row in ipairs(self.rows) do
      local field = row.field
      if not field then
        target = tonumber(strtrim(row.widget:GetText() or ""))
      elseif field.type == "check" then
        params[field.param] = row.widget:GetChecked() and true or nil
      elseif field.type == "choice" then
        params[field.param] = self.choices[field.param]
      else
        local text = strtrim(row.widget:GetText() or "")
        if field.numeric then
          params[field.param] = tonumber(text)
        else
          params[field.param] = text ~= "" and text or nil
        end
      end
    end
    return params, target
  end

  function form:Clear()
    for _, row in ipairs(self.rows) do
      if row.box then row.widget:SetText("") end
    end
  end

  -- Hat ein Textfeld Inhalt? (Zusätze: aufgeklappt lassen, solange etwas eingetragen ist)
  function form:HasInput()
    for _, row in ipairs(self.rows) do
      if row.box and strtrim(row.widget:GetText() or "") ~= "" then return true end
    end
    return false
  end

  -- Feld zu param, "amount" = die Zahl
  function form:Widget(param)
    for _, row in ipairs(self.rows) do
      if (row.field and row.field.param or AMOUNT) == param then return row.widget end
    end
  end

  -- Shift-Klick auf einen Link: in das fokussierte Textfeld (nur Felder mit links, bzw. alle bei allLinks)
  function form:InsertLink(link, allLinks)
    for _, row in ipairs(self.rows) do
      local accepts = row.box and (allLinks or (row.field and row.field.links))
      if accepts and row.widget:HasFocus() then row.widget:Insert(link) end
    end
  end

  table.insert(allForms, form)
  return form
end

-- Breite der Beschriftungsspalte: breiteste Beschriftung aller Formulare (fr/es sind länger); setzt vorher die Texte
-- der gewählten Sprache, damit schon das erste Layout richtig misst
function GoalForm.LabelWidth()
  local widest = MIN_LABEL_WIDTH
  for _, form in ipairs(allForms) do
    for _, row in ipairs(form.rows) do
      if row.label then
        row.label:SetText(L[row.labelKey])
        widest = math.max(widest, math.ceil(row.label:GetStringWidth() or 0) + LABEL_GAP)
      end
    end
  end
  return widest
end
