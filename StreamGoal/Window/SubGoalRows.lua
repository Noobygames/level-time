-- Teilziele einer Checkliste beim Bearbeiten im Reiter "Ziele" (UX G17): je laufendem Teilziel eine Zeile mit "Lösen",
-- darunter "Teilziel: [laufendes Ziel ▸] [Anhängen]" (Auswahl wie im Formular: Linksklick nächstes, Rechtsklick voriges
-- Ziel). Ohne passende laufende Ziele steht dort ein Hinweis. Ersetzt den Befehl /sg sub im Fenster (der bleibt).
--   rows = SubGoalRows.Create(page, onChange); rows:Layout(goal, top, labelWidth) -> Höhe; rows:Hide()
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Checklist = ns.Checklist
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local SubGoalRows = {}
ns.SubGoalRows = SubGoalRows

local CHOICE_WIDTH = 220
local DETACH_MIN_WIDTH = 70
local CHILD_INDENT = 12
local CHOICE_TEXT_PADDING = 16  -- Rand des Texts im Auswahlknopf (lange Titel werden abgeschnitten)

function SubGoalRows.Create(page, onChange)
  local rows = { children = {}, candidates = {}, choice = 1 }

  local heading = Manager.CreateLabel(page)
  local attachLabel = Manager.CreateLabel(page)
  local none = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  none:SetTextColor(Theme.RGB("muted"))
  none:SetJustifyH("LEFT")
  rows.noneText = none

  local function candidate()
    return rows.candidates[rows.choice]
  end

  local choiceButton
  -- Titel des gewählten Ziels in den Auswahlknopf; ein langer Titel wird abgeschnitten, statt den Knopf über die
  -- Seite hinaus zu verbreitern (rows.maxChoiceWidth aus dem Layout)
  local function showChoice()
    local chosen = candidate()
    if not chosen then return end
    choiceButton.label:SetWidth(0)
    Widgets.SetButtonText(choiceButton, string.format("#%d  %s", chosen.id, Goals.Title(chosen)), CHOICE_WIDTH)
    local limit = rows.maxChoiceWidth
    if limit and choiceButton:GetWidth() > limit then
      choiceButton:SetWidth(limit)
      choiceButton.label:SetWidth(limit - CHOICE_TEXT_PADDING)
    end
  end

  -- Gewähltes Ziel anhängen bzw. ein Teilziel lösen; Fehler kommen zurück an die Seite (Fehlerzeile)
  function rows:Attach()
    local child = candidate()
    if not rows.goal or not child then return L.SG_ERR_SUBGOAL end
    local err = Checklist.Attach(rows.goal, child)
    if not err then ns.Print(string.format(L.SG_CHAT_SUBGOAL, Goals.Title(child), Goals.Title(rows.goal))) end
    onChange(err)
    return err
  end

  function rows:Detach(child)
    local err = Checklist.Detach(child)
    if not err then ns.Print(string.format(L.SG_CHAT_SUBGOAL_DETACHED, Goals.Title(child))) end
    onChange(err)
    return err
  end

  choiceButton = Widgets.CreateButton(page, CHOICE_WIDTH, Manager.BOX_HEIGHT + 2, nil)
  choiceButton.label:SetWordWrap(false)
  choiceButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  choiceButton:SetScript("OnClick", function(_, mouseButton)
    local count = #rows.candidates
    if count == 0 then return end
    local step = mouseButton == "RightButton" and -1 or 1
    rows.choice = (rows.choice - 1 + step) % count + 1
    showChoice()
  end)
  Manager.AttachTooltip(choiceButton, function() return L.SG_SUBGOAL_CHOICE end, function()
    return { { text = L.SG_SUBGOAL_CHOICE_TIP }, { text = L.SG_FORM_CHOICE_TIP, muted = true } }
  end)
  rows.choiceButton = choiceButton
  local attachButton = Manager.CreateButton(page, "SG_SUBGOAL_ATTACH", function() rows:Attach() end)
  rows.attachButton = attachButton

  local function childRow(index)
    if rows.children[index] then return rows.children[index] end
    local row = {}
    row.text = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.detach = Manager.CreateButton(page, "SG_SUBGOAL_DETACH", function()
      if row.goal then rows:Detach(row.goal) end
    end, DETACH_MIN_WIDTH)
    row.detach:SetHeight(Manager.BUTTON_HEIGHT - 2)
    rows.children[index] = row
    return row
  end

  local function hideChild(row)
    row.goal = nil
    row.text:Hide()
    row.detach:Hide()
  end

  function rows:Hide()
    self.goal = nil
    heading:Hide()
    attachLabel:Hide()
    none:Hide()
    choiceButton:Hide()
    attachButton:Hide()
    for _, row in ipairs(self.children) do hideChild(row) end
  end

  -- Teilziele von goal ab y = top; Rückgabe: belegte Höhe
  function rows:Layout(goal, top, labelWidth)
    self.goal = goal
    local y = top
    heading:SetText(L.SG_SUBGOAL_TITLE)
    heading:ClearAllPoints()
    heading:SetPoint("TOPLEFT", 0, y)
    heading:Show()
    y = y - Manager.ROW
    local index = 0
    for _, child in ipairs(Checklist.Children(goal)) do
      if child.status == Goals.ACTIVE then
        index = index + 1
        local row = childRow(index)
        row.goal = child
        Manager.SetLabels({ row.detach })
        row.detach:ClearAllPoints()
        row.detach:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, y + 2)
        row.text:ClearAllPoints()
        row.text:SetPoint("TOPLEFT", CHILD_INDENT, y)
        row.text:SetWidth(Manager.PAGE_WIDTH - CHILD_INDENT - row.detach:GetWidth() - Manager.BUTTON_GAP)
        row.text:SetText(string.format("#%d  %s", child.id, Goals.Title(child)))
        row.text:Show()
        row.detach:Show()
        y = y - Manager.ROW
      end
    end
    for i = index + 1, #self.children do hideChild(self.children[i]) end

    -- Auswahl der anhängbaren Ziele; die gewählte bleibt, solange es sie noch gibt
    local previous = candidate()
    self.candidates = Checklist.Candidates(goal)
    self.choice = 1
    for i, entry in ipairs(self.candidates) do
      if entry == previous then self.choice = i end
    end
    attachLabel:SetText(L.SG_SUBGOAL_CHOICE)
    attachLabel:ClearAllPoints()
    attachLabel:SetPoint("TOPLEFT", 0, y)
    attachLabel:Show()
    local any = #self.candidates > 0
    choiceButton:SetShown(any)
    attachButton:SetShown(any)
    none:SetShown(not any)
    if any then
      Manager.SetLabels({ attachButton })
      self.maxChoiceWidth = Manager.PAGE_WIDTH - labelWidth - attachButton:GetWidth() - Manager.BUTTON_GAP
      showChoice()
      choiceButton:ClearAllPoints()
      choiceButton:SetPoint("TOPLEFT", labelWidth, y + 2)
      attachButton:ClearAllPoints()
      attachButton:SetPoint("LEFT", choiceButton, "RIGHT", Manager.BUTTON_GAP, 0)
    else
      none:SetText(L.SG_SUBGOAL_NONE)
      none:ClearAllPoints()
      none:SetPoint("TOPLEFT", labelWidth, y)
    end
    y = y - Manager.ROW
    return top - y
  end

  -- Gewähltes Ziel der Auswahl (Tests)
  function rows:Candidate()
    return candidate()
  end

  rows:Hide()
  return rows
end
