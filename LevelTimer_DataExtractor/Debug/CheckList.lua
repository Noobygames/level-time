-- Spiel-Checkliste: die offenen Vikunja-Tickets "Im Spiel prüfen" (CheckListData.lua) im Spiel abhaken. Tritt eine Situation
-- ein, für die offene Prüfungen existieren (Trigger, siehe TRIGGERS), kommt einmal je Trigger und Sitzung eine Chatzeile und ein
-- kleines Hinweisfenster ("Jetzt prüfbar: ..."); nie im Kampf. /lte todo öffnet die Liste (passende Situation oben), je
-- Eintrag Knöpfe OK / Fehler / Später und eine Notiz. /lte todo off|on schaltet die Hinweise ab/an.
-- Ergebnisse: LevelTimerDebugLog.checkResults[id] = { status = "ok"|"fail"|"skip", t = Zeit, note = Text } (SavedVariable,
-- wird von `make checkresults` gelesen); jedes Ergebnis steht zusätzlich als Zeile (area "checklist") im Debug-Log.
local _, X = ...
local ns = X.LT
if not ns then return end
local L = X.L
local DebugLog = X.DebugLog
local Widgets, Client = ns.Widgets, ns.Client

local CheckList = {}
X.CheckList = CheckList

local STATUS = { ok = "ok", fail = "fail", skip = "skip" }
-- Reihenfolge der Gruppen in der Liste
local TRIGGERS = { "login", "instance", "raid", "levelup", "questAccept", "questTurnIn", "lfg", "worldmap", "combat", "death",
  "loot", "flight", "merchant", "trainer", "options", "history", "stream", "anywhere" }
-- Trigger, die immer als "passend" gelten
local ALWAYS = { login = true, anywhere = true }
-- Rahmen, deren OnShow einen Trigger auslöst (entstehen teils erst spät, daher bei jedem Weltwechsel erneut versucht)
local FRAME_TRIGGERS = {
  { "LFGParentFrame", "lfg" }, { "PVEFrame", "lfg" }, { "WorldMapFrame", "worldmap" }, { "LevelTimerOptions", "options" },
  { "LevelTimerHistory", "history" }, { "StreamGoalWindow", "stream" },
}

local WIDTH, HEIGHT = 560, 520
local PADDING = 12
local HEADER = 44
local BUTTON_W, BUTTON_H = 64, 24
local TOAST_SECONDS = 12
local LINE = 14

local fired = {}   -- Trigger, die in dieser Sitzung eingetreten sind
local hinted = {}  -- Trigger, für die schon ein Hinweis kam
local hooked = {}
local expanded = {}
local window, rows, groupTitles, content, counter
local toast, toastText

---------------------------------------------------------------------------
-- Daten und Zustand
---------------------------------------------------------------------------
local function state()
  if not LevelTimerDebugLog then return nil end
  LevelTimerDebugLog.checkResults = LevelTimerDebugLog.checkResults or {}
  LevelTimerDebugLog.checkList = LevelTimerDebugLog.checkList or {}
  return LevelTimerDebugLog
end

local function clientFits(entry)
  return entry.client == "all" or entry.client == Client.Flavor()
end

-- Offene Prüfungen (kein Ergebnis oder "Später") des Clients, optional nur eines Triggers
function CheckList.Open(trigger, includeSkipped)
  local store, list = state(), {}
  if not store then return list end
  for _, entry in ipairs(X.CheckListData or {}) do
    local result = store.checkResults[entry.id]
    local open = result == nil or (includeSkipped ~= false and result.status == STATUS.skip)
    if open and clientFits(entry) then
      for _, t in ipairs(entry.triggers) do
        if trigger == nil or t == trigger then list[#list + 1] = { entry = entry, trigger = t }; break end
      end
    end
  end
  return list
end

function CheckList.Enabled()
  local store = state()
  return store ~= nil and store.checkList.hintsOff ~= true
end

-- Ergebnis speichern und ins Debug-Log schreiben
function CheckList.Mark(id, status, note)
  local store = state()
  if not store or not STATUS[status] then return end
  note = (note and note ~= "") and note or nil
  store.checkResults[id] = { status = status, t = date("%Y-%m-%d %H:%M:%S"), note = note }
  DebugLog.Write({ area = "checklist", msg = string.format("%s %s%s", id, status, note and (" " .. note) or "") })
end

---------------------------------------------------------------------------
-- Hinweis
---------------------------------------------------------------------------
local function showToast(text)
  if not toast then
    toast = Widgets.CreatePanel("LevelTimerCheckListToast", 0.95)
    toast:SetSize(340, 52)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -140)
    toast:SetFrameStrata("DIALOG")
    toastText = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toastText:SetPoint("TOPLEFT", PADDING, -8)
    toastText:SetPoint("BOTTOMRIGHT", -PADDING, 8)
    toastText:SetJustifyH("LEFT")
    toast:SetScript("OnMouseUp", function() toast:Hide(); CheckList.Show() end)
  end
  toastText:SetText(text)
  toast:Show()
  C_Timer.After(TOAST_SECONDS, function() toast:Hide() end)
end

-- Situation ist eingetreten: Hinweis einmal je Trigger und Sitzung, nie im Kampf
function CheckList.Fire(trigger)
  fired[trigger] = true
  if window and window:IsShown() then CheckList.Refresh() end
  if hinted[trigger] or not CheckList.Enabled() or InCombatLockdown() then return end
  local list = CheckList.Open(trigger, false)
  if #list == 0 then return end
  hinted[trigger] = true
  local first = list[1].entry
  local text = string.format(L.TODO_NOW, first.id, first.title) .. (#list > 1 and string.format(L.TODO_MORE, #list - 1) or "")
  X.Print(text .. " " .. L.TODO_OPEN_HINT)
  showToast(text)
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local function createRow()
  local row = CreateFrame("Frame", nil, content)
  row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.title:SetJustifyH("LEFT")
  row.steps = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.steps:SetJustifyH("LEFT")
  row.toggle = CreateFrame("Button", nil, row)
  row.toggle:SetScript("OnClick", function()
    expanded[row.id] = not expanded[row.id]
    CheckList.Refresh()
  end)
  row.note = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
  row.note:SetAutoFocus(false)
  row.note:SetHeight(20)
  row.note:SetScript("OnEscapePressed", row.note.ClearFocus)
  row.buttons = {}
  for _, status in ipairs({ "ok", "fail", "skip" }) do
    local button = Widgets.CreateButton(row, BUTTON_W, BUTTON_H, function()
      CheckList.Mark(row.id, status, row.note:GetText())
      expanded[row.id] = nil
      CheckList.Refresh()
    end)
    Widgets.SetButtonText(button, L["TODO_" .. status:upper()], BUTTON_W)
    row.buttons[status] = button
  end
  return row
end

local function createWindow()
  window = Widgets.CreatePanel("LevelTimerCheckList", 0.95)
  window:SetSize(WIDTH, HEIGHT)
  window:SetPoint("CENTER")
  window:SetFrameStrata("DIALOG")
  window:SetScript("OnDragStart", window.StartMoving)
  window:SetScript("OnDragStop", window.StopMovingOrSizing)
  window.header = Widgets.CreateWindowHeader(window, L.TODO_TITLE)
  counter = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  counter:SetPoint("TOPLEFT", PADDING, -HEADER)
  local scroll = Widgets.CreateScrollArea(window, { step = 40 })
  scroll:SetPoint("TOPLEFT", PADDING, -(HEADER + LINE + 6))
  scroll:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(WIDTH - 2 * PADDING, 10)
  scroll:SetScrollChild(content)
  rows, groupTitles = {}, {}
  table.insert(UISpecialFrames, "LevelTimerCheckList")
end

-- Einträge nach Trigger gruppiert; Gruppen der aktuellen Situation zuerst, sonst feste Reihenfolge
local function groups()
  local byTrigger, order = {}, {}
  for _, item in ipairs(CheckList.Open()) do
    byTrigger[item.trigger] = byTrigger[item.trigger] or {}
    table.insert(byTrigger[item.trigger], item.entry)
  end
  for _, trigger in ipairs(TRIGGERS) do
    if byTrigger[trigger] then order[#order + 1] = trigger end
  end
  local function fits(trigger) return fired[trigger] or ALWAYS[trigger] end
  table.sort(order, function(a, b)
    if (fits(a) and true or false) ~= (fits(b) and true or false) then return fits(a) and true or false end
    return false
  end)
  return byTrigger, order
end

function CheckList.Refresh()
  if not window then return end
  local byTrigger, order = groups()
  local width = WIDTH - 2 * PADDING
  local y, used, groupCount, total = 0, 0, 0, 0
  for _, trigger in ipairs(order) do
    groupCount = groupCount + 1
    local title = groupTitles[groupCount]
    if not title then
      title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      title:SetJustifyH("LEFT")
      groupTitles[groupCount] = title
    end
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    title:SetText(L["TODO_TRIGGER_" .. trigger:upper()] .. ((fired[trigger] or ALWAYS[trigger]) and (" - " .. L.TODO_NOW_FITS) or ""))
    title:Show()
    y = y + 24
    for _, entry in ipairs(byTrigger[trigger]) do
      used, total = used + 1, total + 1
      local row = rows[used] or createRow()
      rows[used] = row
      row.id = entry.id
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
      row.title:ClearAllPoints()
      row.title:SetPoint("TOPLEFT", 0, 0)
      row.title:SetWidth(width - 3 * BUTTON_W - 12)
      row.title:SetText(entry.id .. "  " .. entry.title)
      row.toggle:ClearAllPoints()
      row.toggle:SetAllPoints(row.title)
      local height = 28
      local open = expanded[entry.id]
      if open then
        row.steps:ClearAllPoints()
        row.steps:SetPoint("TOPLEFT", 8, -height)
        row.steps:SetWidth(width - 16)
        row.steps:SetText("- " .. table.concat(entry.steps, "\n- "))
        row.steps:Show()
        height = height + (#entry.steps + 1) * LINE
        row.note:ClearAllPoints()
        row.note:SetPoint("TOPLEFT", 8, -height)
        row.note:SetWidth(width - 24)
        local result = ((state() or {}).checkResults or {})[entry.id]
        row.note:SetText(result and result.note or "")
        row.note:Show()
        height = height + 26
      else
        row.steps:Hide()
        row.note:Hide()
      end
      local x = width
      for _, status in ipairs({ "skip", "fail", "ok" }) do
        local button = row.buttons[status]
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", row, "TOPLEFT", x, 0)
        button:Show()
        x = x - BUTTON_W - 4
      end
      row:SetSize(width, height)
      row:Show()
      y = y + height + 6
    end
    y = y + 8
  end
  for index = groupCount + 1, #groupTitles do groupTitles[index]:Hide() end
  for index = used + 1, #rows do rows[index]:Hide() end
  content:SetHeight(math.max(y, 10))
  counter:SetText(string.format(L.TODO_COUNT, total, CheckList.Enabled() and L.DEBUG_LOG_STATE_ON or L.DEBUG_LOG_STATE_OFF))
end

function CheckList.Show()
  if not state() then return end
  if not window then createWindow() end
  CheckList.Refresh()
  window:Show()
end

---------------------------------------------------------------------------
-- /lte todo
---------------------------------------------------------------------------
function CheckList.Command(argument)
  local store = state()
  if not store then return X.Print(L.TODO_NOT_READY) end
  if argument == "off" or argument == "on" then
    store.checkList.hintsOff = argument == "off" or nil
    X.CheckReminders.Refresh()  -- Fenster "Offene Prüfungen" folgt dem Schalter
    return X.Print(argument == "off" and L.TODO_HINTS_OFF or L.TODO_HINTS_ON)
  end
  CheckList.Show()
end

---------------------------------------------------------------------------
-- Auslöser
---------------------------------------------------------------------------
local function hookFrames()
  for _, pair in ipairs(FRAME_TRIGGERS) do
    local frame = _G[pair[1]]
    if frame and frame.HookScript and not hooked[pair[1]] then
      hooked[pair[1]] = true
      frame:HookScript("OnShow", function() CheckList.Fire(pair[2]) end)
    end
  end
end

ns.OnLogin(function()
  hookFrames()
  CheckList.Fire("login")
  C_Timer.After(30, function() CheckList.Fire("anywhere") end)  -- Prüfungen ohne besondere Situation
end)

-- shortcut: Rahmen, die erst nach dem Weltwechsel entstehen, werden erst beim nächsten Weltwechsel eingehängt
X.On("PLAYER_ENTERING_WORLD", function()
  hookFrames()
  local inInstance, kind = IsInInstance()
  if inInstance then
    CheckList.Fire("instance")
    if kind == "raid" then CheckList.Fire("raid") end
  end
end)
ns.OnLevelStarted(function() CheckList.Fire("levelup") end)
X.On("QUEST_ACCEPTED", function() CheckList.Fire("questAccept") end)
X.On("QUEST_TURNED_IN", function() CheckList.Fire("questTurnIn") end)
X.On("PLAYER_REGEN_ENABLED", function() CheckList.Fire("combat") end)
X.On("PLAYER_DEAD", function() CheckList.Fire("death") end)
X.On("LOOT_OPENED", function() CheckList.Fire("loot") end)
X.On("TAXIMAP_OPENED", function() CheckList.Fire("flight") end)
X.On("MERCHANT_SHOW", function() CheckList.Fire("merchant") end)
X.On("TRAINER_SHOW", function() CheckList.Fire("trainer") end)
