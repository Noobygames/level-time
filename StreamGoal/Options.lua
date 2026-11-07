-- Einstellungsfenster von Level Time Goals (Roadmap 312), gebaut mit dem OptionsBuilder von Level Time: Seitenleiste
-- (Tracker, Meldungen, Daten), Suche, "Standard" je Unterseite, Tooltips aus <LABEL>_TIP. Die Werte stehen in
-- StreamGoalDB.settings (nicht in den Einstellungen von Level Time), daher hat jeder Baustein eigene get/set und
-- reset-Funktionen. Rechtsklick auf den Tracker und der Knopf "Einstellungen" im Edit-Modus öffnen die Unterseite
-- Tracker (LT.RegisterOptionsWindow).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Tracker = ns.Tracker
local L = ns.L
local Frames = LT.Frames
local Widgets = LT.Widgets
local Theme = LT.Theme

local Options = {}
ns.Options = Options

local PERCENT = 100
local SCALE_STEP = 5
local PANEL_ALPHA = 0.95
local INFO_HEIGHT = 34       -- Zeile mit den Zählern über den Aufräum-Knöpfen
local COLOR_CHOICES = { { key = "kind", label = "SG_COLORS_KIND" }, { key = "accent", label = "SG_COLORS_ACCENT" } }

local builder = LT.OptionsBuilder.New({
  name = "StreamGoalOptions",
  alpha = PANEL_ALPHA,
  title = function() return L.SG_OPTIONS_TITLE end,
})
Options.builder = builder

local function settings()
  return ns.db.settings
end

-- Zurücksetzen eines Schlüssels in StreamGoalDB.settings auf den Standard aus Core.lua
local function settingReset(key)
  return {
    get = function() return settings()[key] end,
    set = function(value) settings()[key] = value end,
    default = function() return ns.SettingDefault(key) end,
  }
end

local function toggle(label, key)
  return {
    label = label,
    get = function() return settings()[key] end,
    set = function(checked) ns.SetSetting(key, checked and true or false) end,
    reset = settingReset(key),
  }
end

---------------------------------------------------------------------------
-- Seite "Ziele": Tracker, Meldungen, Daten
---------------------------------------------------------------------------
builder.AddPage("SG_OPTIONS_PAGE_GOALS")

builder.AddSubPage(Tracker.SETTINGS_PAGE)
builder.AddSection("SG_OPTIONS_SECTION_CARDS")
builder.AddToggles({ toggle("SG_SHOW_TRACKER", "showTracker"), toggle("SG_OPTIONS_SHOW_BINGO", "showBingo") })
builder.AddSlider({
  label = "SG_OPTIONS_MAX_CARDS",
  min = ns.MIN_CARDS, max = ns.MAX_CARDS, step = 1,
  get = function() return settings().maxCards end,
  set = function(value) ns.SetSetting("maxCards", value) end,
  format = function(value) return tostring(value) end,
  reset = settingReset("maxCards"),
})
builder.AddCycleButton({
  label = "SG_OPTIONS_CARD_COLORS",
  choices = function()
    local list = {}
    for _, choice in ipairs(COLOR_CHOICES) do table.insert(list, { key = choice.key, name = L[choice.label] }) end
    return list
  end,
  get = function() return settings().cardColors end,
  set = function(key) ns.SetSetting("cardColors", key) end,
  nameOf = function(key)
    for _, choice in ipairs(COLOR_CHOICES) do
      if choice.key == key then return L[choice.label] end
    end
    return tostring(key)
  end,
  reset = settingReset("cardColors"),
})
builder.AddSection("SG_OPTIONS_SECTION_POSITION")
builder.AddSlider({
  label = "SG_OPTIONS_SCALE",
  min = Frames.MIN_SCALE * PERCENT, max = Frames.MAX_SCALE * PERCENT, step = SCALE_STEP,
  get = function() return math.floor(Frames.GetScale(Tracker.FRAME_ID) * PERCENT + 0.5) end,
  set = function(value) Tracker.SetScale(value / PERCENT) end,
  format = function(value) return string.format("%d %%", value) end,
  reset = {
    get = function() return Frames.GetStoredScale(Tracker.FRAME_ID) end,
    set = function(scale) Frames.SetStoredScale(Tracker.FRAME_ID, scale) end,
    default = function() return nil end,
  },
})
builder.AddButtonRow({
  { label = "SG_MOVE", onClick = function() LT.EditMode.Toggle() end },
  { label = "SG_RESET_POSITION", onClick = function() Frames.Reset(Tracker.FRAME_ID) end },
})

builder.AddSubPage("SG_OPTIONS_PAGE_NOTICES")
builder.AddSection("SG_OPTIONS_SECTION_DONE")
builder.AddToggles({
  toggle("SG_SOUND", "sound"),
  toggle("SG_OPTIONS_DONE_ALERT", "doneAlert"),
  toggle("SG_OPTIONS_DONE_CHAT", "doneChat"),
  toggle("SG_OPTIONS_BINGO_ANNOUNCE", "bingoAnnounce"),
})

-- Daten: Ziele gelöschter Charaktere und die Historie entfernen, beides mit Rückfrage
builder.AddSubPage("SG_OPTIONS_PAGE_DATA")
builder.AddSection("SG_OPTIONS_SECTION_CLEANUP")
local info = builder.Page():CreateFontString(nil, "OVERLAY", Theme.Font("small"))
info:SetJustifyH("LEFT")
info:SetJustifyV("TOP")
info:SetHeight(INFO_HEIGHT)
builder.AddRow(info, INFO_HEIGHT, true)
Options.info = info
builder.OnRefresh(function()
  if not ns.db then return end
  info:SetText(string.format(L.SG_OPTIONS_DATA_INFO, #Goals.History(), Goals.CountOrphans()))
end)

local confirmOrphans = Widgets.ConfirmPopup("STREAMGOAL_REMOVE_ORPHANS", "SG_CONFIRM_REMOVE_ORPHANS", function()
  ns.Print(string.format(L.SG_CHAT_REMOVED, Goals.RemoveOrphans()))
end)
local confirmHistory = Widgets.ConfirmPopup("STREAMGOAL_CLEAR_HISTORY", "SG_CONFIRM_CLEAR_HISTORY", function()
  ns.Print(string.format(L.SG_CHAT_REMOVED, Goals.ClearHistory()))
end)

builder.AddButton("SG_OPTIONS_REMOVE_ORPHANS", function()
  local count = Goals.CountOrphans()
  if count == 0 then
    ns.Print(L.SG_NOTHING_TO_REMOVE)
    return
  end
  confirmOrphans(count)
end)
builder.AddButton("SG_OPTIONS_CLEAR_HISTORY", function()
  local count = #Goals.History()
  if count == 0 then
    ns.Print(L.SG_NOTHING_TO_REMOVE)
    return
  end
  confirmHistory(count)
end)
builder.FinishSubPages()
builder.FinishPage()

builder.AddFooterButton("SG_OPEN_MANAGER", function() ns.Manager.Toggle() end)
builder.Finish()

---------------------------------------------------------------------------
-- Öffnen
---------------------------------------------------------------------------
local panel = builder.panel

function Options.Show(pageKey)
  if not ns.db then return end
  builder.Refresh(LT.db)
  panel:Show()
  if pageKey then builder.ShowPage(pageKey) end
end

-- Ist genau diese Seite schon offen, schließen (zweiter Rechtsklick auf den Tracker)
function Options.Toggle(pageKey)
  if not ns.db then return end
  local tab, sub = builder.CurrentPage()
  if panel:IsShown() and (not pageKey or (sub or tab) == pageKey) then
    panel:Hide()
  else
    Options.Show(pageKey)
  end
end

local pages = {}
for _, key in ipairs({ "SG_OPTIONS_PAGE_GOALS", Tracker.SETTINGS_PAGE, "SG_OPTIONS_PAGE_NOTICES",
  "SG_OPTIONS_PAGE_DATA" }) do
  pages[key] = true
end
LT.RegisterOptionsWindow({ pages = pages, show = Options.Show, toggle = Options.Toggle })

-- Geänderte Einstellungen, Ziele (Zähler unter "Daten"), Sprache: offenes Fenster aktuell halten
ns.RegisterApply(function() builder.RefreshIfShown(LT.db) end)
Goals.OnChange(function() builder.RefreshIfShown(LT.db) end)
