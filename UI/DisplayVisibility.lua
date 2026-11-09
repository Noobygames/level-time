-- Sichtbarkeitsregeln der Anzeigen (Hauptfenster: windowVisibility, Split-Liste: splitListVisibility):
--   always, outOfCombat, inCombat, instanceOnly (in einer Instanz, auch Schlachtfeld/Arena), hideAtMaxLevel
--   (nur beim Leveln), mouseover (nur bei Mauskontakt).
-- Greift eine Regel nicht, wird die Anzeige auf fadeAlpha abgeblendet statt versteckt; nur bei 0 und einer Regel ohne
-- Mauskontakt wird sie versteckt (eine unsichtbare Fläche soll keine Klicks schlucken). Im Edit-Modus immer voll.
-- Ausgewertet bei Ereignissen (Kampf an/aus, Zonenwechsel, Level-Up, XP an/aus) und bei Mauskontakt, nie per Takt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    windowVisibility = "always",
    splitListVisibility = "always",
    fadeAlpha = 0,
  },
  ranges = {
    fadeAlpha = { 0, 1 },
  },
})

local DisplayVisibility = {
  ALWAYS = "always",
  OUT_OF_COMBAT = "outOfCombat",
  IN_COMBAT = "inCombat",
  INSTANCE_ONLY = "instanceOnly",
  HIDE_AT_MAX_LEVEL = "hideAtMaxLevel",
  MOUSEOVER = "mouseover",
}
DisplayVisibility.MODES = {
  DisplayVisibility.ALWAYS, DisplayVisibility.OUT_OF_COMBAT, DisplayVisibility.IN_COMBAT,
  DisplayVisibility.INSTANCE_ONLY, DisplayVisibility.HIDE_AT_MAX_LEVEL, DisplayVisibility.MOUSEOVER,
}
ns.DisplayVisibility = DisplayVisibility

local FULL_ALPHA = 1
local controllers = {}
local state = { inCombat = false, inInstance = false }

local function readState()
  state.inCombat = ns.InCombat()
  local inInstance = IsInInstance()
  state.inInstance = not ns.IsSecret(inInstance) and inInstance == true
end

local RULES = {
  [DisplayVisibility.OUT_OF_COMBAT] = function() return not state.inCombat end,
  [DisplayVisibility.IN_COMBAT] = function() return state.inCombat end,
  [DisplayVisibility.INSTANCE_ONLY] = function() return state.inInstance end,
  [DisplayVisibility.HIDE_AT_MAX_LEVEL] = function() return ns.Experience.IsLeveling() end,
}

local Controller = {}
Controller.__index = Controller

-- Regel der Anzeige erfüllt (ohne Mauskontakt)
function Controller:RuleMet()
  local rule = RULES[ns.db[self.setting]]
  return not rule or rule()
end

function Controller:Update()
  if not ns.db then return end
  local frame = self.frame
  if not (self.editing or self.enabled()) then
    frame:Hide()
    return
  end
  local mode = ns.db[self.setting]
  local visible = self.editing or (mode == DisplayVisibility.MOUSEOVER and self.hovered)
    or (mode ~= DisplayVisibility.MOUSEOVER and self:RuleMet())
  local fade = ns.db.fadeAlpha or 0
  if not visible and fade <= 0 and mode ~= DisplayVisibility.MOUSEOVER then
    frame:Hide()
    return
  end
  frame:SetAlpha(visible and FULL_ALPHA or fade)
  frame:Show()
end

function Controller:SetEditing(editing)
  self.editing = editing
  self:Update()
end

-- Maus über der Anzeige oder einem ihrer Kinder (Reiter, Balken): Kinder haben eigene Mausflächen, beim Wechsel auf
-- ein Kind meldet das Fenster OnLeave, obwohl die Maus noch darüber ist
local function isOver(frame)
  return frame:IsShown() and frame:IsMouseOver() == true
end

function Controller:RefreshHover()
  local hovered = isOver(self.frame)
  for _, child in ipairs(self.children) do hovered = hovered or isOver(child) end
  self:SetHovered(hovered)
end

function Controller:SetHovered(hovered)
  if self.hovered == hovered then return end
  self.hovered = hovered
  if self.onHover then self.onHover(hovered) end
  self:Update()
end

function Controller:WatchHover(frame)
  frame:HookScript("OnEnter", function() self:SetHovered(true) end)
  frame:HookScript("OnLeave", function() self:RefreshHover() end)
  if frame ~= self.frame then table.insert(self.children, frame) end
end

-- options = { frame, setting, enabled() (Anzeige überhaupt an), onHover(hovered) optional, children optional }
function DisplayVisibility.Attach(options)
  local controller = setmetatable({
    frame = options.frame, setting = options.setting, enabled = options.enabled, onHover = options.onHover,
    children = {}, hovered = false, editing = false,
  }, Controller)
  controller:WatchHover(options.frame)
  for _, child in ipairs(options.children or {}) do controller:WatchHover(child) end
  table.insert(controllers, controller)
  return controller
end

local function updateAll()
  for _, controller in ipairs(controllers) do controller:Update() end
end

-- Ereignisse nur, solange eine Anzeige eine Regel außer "immer" hat
local events = ns.NewEventGroup()
events.Add("PLAYER_REGEN_DISABLED", nil, function()
  state.inCombat = true
  updateAll()
end)
events.Add("PLAYER_REGEN_ENABLED", nil, function()
  state.inCombat = false
  updateAll()
end)
local function onZone()
  readState()
  updateAll()
end
events.Add("PLAYER_ENTERING_WORLD", nil, onZone)
events.Add("ZONE_CHANGED_NEW_AREA", nil, onZone)
events.Add("ENABLE_XP_GAIN", nil, updateAll)
events.Add("DISABLE_XP_GAIN", nil, updateAll)

ns.OnLevelStarted(function()
  if events.IsActive() then updateAll() end
end)

-- Ereignisse an- oder abmelden; die Anzeigen rufen in ihrem eigenen Apply noch einmal Update auf
function DisplayVisibility.Apply(db)
  local needed = false
  for _, controller in ipairs(controllers) do
    if db[controller.setting] ~= DisplayVisibility.ALWAYS then needed = true end
  end
  if needed and not events.IsActive() then readState() end
  events.SetActive(needed)
  updateAll()
end
ns.RegisterApply(DisplayVisibility.Apply)
