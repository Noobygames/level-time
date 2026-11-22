-- Erinnerung an Prüfungen, die eine Spielsituation brauchen (LT-290): Prüfungen mit Situation (DebugLog.SetWhen / dritter
-- Parameter von AddCheck: { trigger = "...", flavor = "forever", instance = true }) erscheinen in einem kleinen Fenster,
-- sobald die Situation eintritt und die Prüfung für den aktuellen Build noch nicht bestätigt ist. Das Fenster bleibt, bis
-- der Build bestätigt ist (kein Timeout, übersteht /reload). /lt debug check bestätigt nicht von selbst: erst der Knopf
-- "Ausgeführt" zählt. Bestätigung und offene Situationen liegen in LevelTimerDebugLog.reminder.
-- /lte todo off (oder Knopf "Hinweise aus") blendet das Fenster aus, bis /lte todo on; Situationen bleiben gemerkt.
-- Trigger: login, instance, bossKill (nach dem Kampf), afterCombat, lfgOpen, bookRead, levelUp, worldMapOpen.
local _, X = ...
local ns = X.LT
if not ns then return end
local L = X.L
local DebugLog = X.DebugLog
local Widgets, Client = ns.Widgets, ns.Client

local Reminders = {}
X.CheckReminders = Reminders

local WIDTH = 340
local PADDING = 12
local PANEL_ALPHA = 0.95
local ROW_HEIGHT = 32
local HEADER_HEIGHT = 40
local HINT_HEIGHT = 32
local BUTTON_HEIGHT = 28
local DONE_WIDTH = 96
local LAST_RUN_HEIGHT = 18
local BUTTON_GAP = 6
local LFG_FRAMES = { "LFGParentFrame", "PVEFrame" }

-- Situationen der bestehenden Prüfungen (Prüfungen ohne Situation brauchen keine)
local SITUATIONS = {
  ["LT273.questmarks.instance"] = { trigger = "instance" },
  ["LT285.damageMeter.api"] = { trigger = "bossKill" },
  ["LT321.bossKills.sources"] = { trigger = "bossKill" },
  ["LT271.lfg.finder"] = { trigger = "lfgOpen" },
  ["LT271.lfg.encounters"] = { trigger = "lfgOpen" },
  ["LT271.lfg.languages"] = { trigger = "lfgOpen" },
  ["LT272.lfg.window"] = { trigger = "lfgOpen" },
  ["LT351.lfg.sidetab"] = { trigger = "lfgOpen" },
  ["LT352.lfg.filters"] = { trigger = "lfgOpen" },
  ["LT287.books.collected"] = { trigger = "bookRead" },
  ["LT279.kills.events"] = { trigger = "afterCombat", instance = true },
  ["LT267.combatlog.api"] = { trigger = "afterCombat" },
  ["LT52.combatlog.guid"] = { trigger = "afterCombat", instance = true },  -- LT-278: unitCasts
  ["LT252.map.zoneLevels"] = { trigger = "worldMapOpen" },
}
for name, when in pairs(SITUATIONS) do DebugLog.SetWhen(name, when) end

---------------------------------------------------------------------------
-- Zustand
---------------------------------------------------------------------------
local function build()
  return tostring(select(2, GetBuildInfo()))
end

-- { confirmed = { [Prüfung] = Build }, active = { [Trigger] = true } }; erst nach dem Login (SavedVariable)
local function state()
  if not LevelTimerDebugLog then return nil end
  local reminder = LevelTimerDebugLog.reminder or {}
  LevelTimerDebugLog.reminder = reminder
  reminder.confirmed = reminder.confirmed or {}
  reminder.active = reminder.active or {}
  return reminder
end

local function applies(when)
  return not (when.flavor and when.flavor ~= Client.Flavor())
end

-- Prüfungen dieses Triggers (oder aller, trigger = nil), die für den aktuellen Build offen sind
function Reminders.Pending(trigger)
  local reminder, list = state(), {}
  if not reminder then return list end
  for _, check in ipairs(DebugLog.Checks()) do
    local when = check.when
    if when and (trigger == nil or when.trigger == trigger) and applies(when)
      and reminder.confirmed[check.name] ~= build() then
      list[#list + 1] = check
    end
  end
  return list
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel, rows, allButton, hint, lastRun

local function createPanel()
  panel = Widgets.CreatePanel("LevelTimerCheckReminder", PANEL_ALPHA)
  panel:SetSize(WIDTH, 100)
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
  panel:SetFrameStrata("DIALOG")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", PADDING, -PADDING)
  title:SetText(L.REMINDER_TITLE)
  hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  hint:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT)
  hint:SetWidth(WIDTH - 2 * PADDING)
  hint:SetJustifyH("LEFT")
  hint:SetText(L.REMINDER_HINT)
  lastRun = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  lastRun:SetPoint("BOTTOMLEFT", PADDING, PADDING + BUTTON_HEIGHT + BUTTON_GAP)
  Widgets.CreateCloseButton(panel):SetScript("OnClick", function() panel:Hide() end)  -- bis zum nächsten Auslöser
  allButton = Widgets.CreateButton(panel, DONE_WIDTH, BUTTON_HEIGHT, function() Reminders.Confirm(nil) end)
  allButton:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
  Widgets.SetButtonText(allButton, L.REMINDER_ALL_DONE, DONE_WIDTH)
  local offButton = Widgets.CreateButton(panel, DONE_WIDTH, BUTTON_HEIGHT, function() X.CheckList.Command("off") end)
  offButton:SetPoint("BOTTOMLEFT", PADDING, PADDING)
  Widgets.SetButtonText(offButton, L.REMINDER_OFF, DONE_WIDTH)
  rows = {}
end

local function row(index)
  if rows[index] then return rows[index] end
  local item = {}
  item.label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  item.label:SetJustifyH("LEFT")
  item.button = Widgets.CreateButton(panel, DONE_WIDTH, BUTTON_HEIGHT, function() Reminders.Confirm(item.name) end)
  Widgets.SetButtonText(item.button, L.REMINDER_DONE, DONE_WIDTH)
  rows[index] = item
  return item
end

-- Offene Prüfungen der aktiven Situationen zeigen; nichts offen: Fenster zu und Situationen vergessen.
-- Prüf-Hinweise aus (/lte todo off): Fenster zu, Situationen bleiben für /lte todo on gemerkt.
function Reminders.Refresh()
  local reminder = state()
  if not reminder then return end
  if X.CheckList and not X.CheckList.Enabled() then
    if panel then panel:Hide() end
    return
  end
  local shown = {}
  for trigger in pairs(reminder.active) do
    local list = Reminders.Pending(trigger)
    if #list == 0 then reminder.active[trigger] = nil end
    for _, check in ipairs(list) do shown[#shown + 1] = check end
  end
  if #shown == 0 then
    if panel then panel:Hide() end
    return
  end
  table.sort(shown, function(a, b) return a.name < b.name end)
  if not panel then createPanel() end
  for index, item in ipairs(rows) do
    if index > #shown then item.label:Hide(); item.button:Hide() end
  end
  local top = HEADER_HEIGHT + HINT_HEIGHT
  for index, check in ipairs(shown) do
    local item = row(index)
    item.name = check.name
    item.label:ClearAllPoints()
    item.label:SetPoint("TOPLEFT", PADDING, -(top + (index - 1) * ROW_HEIGHT + 8))
    item.label:SetWidth(WIDTH - 3 * PADDING - DONE_WIDTH)
    item.label:SetText(check.name)
    item.label:Show()
    item.button:ClearAllPoints()
    item.button:SetPoint("TOPRIGHT", -PADDING, -(top + (index - 1) * ROW_HEIGHT))
    item.button:Show()
  end
  lastRun:SetText(string.format(L.REMINDER_LAST_RUN, LevelTimerDebugLog.lastCheckRun or L.REMINDER_NEVER))
  panel:SetHeight(top + #shown * ROW_HEIGHT + LAST_RUN_HEIGHT + BUTTON_GAP + BUTTON_HEIGHT + 2 * PADDING)
  panel:Show()
end

-- name = Prüfung bestätigen, nil = alle gerade gezeigten
function Reminders.Confirm(name)
  local reminder = state()
  if not reminder then return end
  for _, check in ipairs(Reminders.Pending()) do
    if (name == nil and reminder.active[check.when.trigger]) or check.name == name then
      reminder.confirmed[check.name] = build()
    end
  end
  Reminders.Refresh()
end

-- Situation ist eingetreten; context.instance = Spieler ist in einer Instanz
function Reminders.Fire(trigger, context)
  local reminder = state()
  if not reminder then return end
  local inInstance = context and context.instance
  if inInstance == nil then inInstance = (IsInInstance()) and true or false end
  local fired = false
  for _, check in ipairs(Reminders.Pending(trigger)) do
    if not check.when.instance or inInstance then fired = true end
  end
  if fired then reminder.active[trigger] = true end
  Reminders.Refresh()
end

function Reminders.PrintPending()
  local list = Reminders.Pending()
  if #list == 0 then return X.DebugPrint("pending", L.PENDING_NONE, build()) end
  for _, check in ipairs(list) do
    X.DebugPrint("pending", L.PENDING_LINE, check.name, check.when.trigger)
  end
end

---------------------------------------------------------------------------
-- Auslöser
---------------------------------------------------------------------------
local bossKilled = false
local hooked = {}  -- Rahmen, deren OnShow schon hängt (OnLogin kann mehrfach laufen)

ns.OnLogin(function()
  Reminders.Fire("login")
  Reminders.Refresh()  -- offene Situationen aus der letzten Sitzung
  for _, name in ipairs(LFG_FRAMES) do
    local frame = _G[name]
    if frame and frame.HookScript and not hooked[name] then
      hooked[name] = true
      frame:HookScript("OnShow", function() Reminders.Fire("lfgOpen") end)
    end
  end
  if ns.LFGWindow and not hooked.LFGWindow then
    hooked.LFGWindow = true
    hooksecurefunc(ns.LFGWindow, "Show", function() Reminders.Fire("lfgOpen") end)
  end
  if WorldMapFrame and WorldMapFrame.HookScript and not hooked.WorldMapFrame then
    hooked.WorldMapFrame = true
    WorldMapFrame:HookScript("OnShow", function() Reminders.Fire("worldMapOpen") end)
  end
end)

ns.OnLevelStarted(function() Reminders.Fire("levelUp") end)
X.On("PLAYER_ENTERING_WORLD", function()
  if IsInInstance() then Reminders.Fire("instance", { instance = true }) end
end)
X.On("ITEM_TEXT_BEGIN", function() Reminders.Fire("bookRead") end)
X.On("ENCOUNTER_END", function(_, _, _, _, success) if success == 1 then bossKilled = true end end)
X.On("BOSS_KILL", function() bossKilled = true end)
X.On("PLAYER_REGEN_ENABLED", function()
  local context = { instance = IsInInstance() and true or false }
  Reminders.Fire("afterCombat", context)
  if bossKilled then
    bossKilled = false
    Reminders.Fire("bossKill", context)
  end
end)
