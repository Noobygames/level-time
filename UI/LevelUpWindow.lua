-- Level-Up-Fenster (Einstellung levelUpWindow): ersetzt Blizzards großes "Level 31"-Banner durch ein eigenes Fenster mit
--   Titel, Werten vorher -> nachher (Leben, Mana, Stärke, ... aus LevelGains), neuen Talentpunkten und den Fähigkeiten,
--   die der Klassenlehrer ab diesem Level anbietet (TrainerCache; Symbole mit Tooltip).
-- Aussehen: levelUpTheme (modern, alliance, horde), levelUpCompact (eine Zeile statt Tabelle), levelUpDuration,
-- levelUpSound; Position und Größe über Lib/Frames.lua (Edit-Modus, Vorschau). levelUpHideBlizzard schaltet das Standardbanner ab.
-- Im Kampf wartet das Fenster bis zum Ende des Kampfes.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local LevelUpWindow = {
  THEMES = { "modern", "alliance", "horde" },
  MIN_DURATION = 3, MAX_DURATION = 20,
}
ns.LevelUpWindow = LevelUpWindow

local DEFAULT_POSITION = { "TOP", "TOP", 0, -160 }
local PADDING = 14
local COLUMN_GAP = 14
local MIN_WIDTH = 300
local MAX_COMPACT_TEXT = 420
local TITLE_ICON = 40
local ROW_HEIGHT = 20
local LINE_GAP = 6
local ABILITY_SIZE = 30
local ABILITY_GAP = 5
local ABILITIES_PER_ROW = 8
local MAX_ABILITIES = 16
local ACCENT_HEIGHT = 4
local BORDER = 1
local FADE_IN, FADE_OUT = 0.25, 0.7
local SAMPLE_DURATION = 8
local QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local BACKGROUND_ALPHA = 0.94
local MOVING = "moving"  -- Wert von override im Edit-Modus

-- Farben je Theme: Grund, Akzent (Leiste und Rahmen), Titel
local THEME_COLORS = {
  modern = { background = ns.Theme.COLORS.surface, accent = ns.Theme.COLORS.gold, title = { 1, 0.9, 0.45 } },
  alliance = { background = { 0.03, 0.06, 0.16 }, accent = { 0.3, 0.55, 1 }, title = { 0.75, 0.88, 1 } },
  horde = { background = { 0.15, 0.03, 0.03 }, accent = { 0.9, 0.2, 0.15 }, title = { 1, 0.8, 0.7 } },
}

local frame = CreateFrame("Frame", "LevelTimerLevelUp", UIParent)
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetClampedToScreen(true)
frame:Hide()

local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(frame)

local border = {}
for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
  local line = frame:CreateTexture(nil, "BORDER")
  if side == "TOP" or side == "BOTTOM" then
    line:SetPoint(side .. "LEFT")
    line:SetPoint(side .. "RIGHT")
    line:SetHeight(BORDER)
  else
    line:SetPoint("TOP" .. side)
    line:SetPoint("BOTTOM" .. side)
    line:SetWidth(BORDER)
  end
  border[side] = line
end

local accent = frame:CreateTexture(nil, "ARTWORK")
accent:SetPoint("TOPLEFT")
accent:SetPoint("TOPRIGHT")
accent:SetHeight(ACCENT_HEIGHT)

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(TITLE_ICON, TITLE_ICON)
icon:SetPoint("TOPLEFT", PADDING, -(PADDING + ACCENT_HEIGHT))
icon:SetTexture(ns.Alerts.ICONS.levelUp)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
title:SetJustifyH("LEFT")

local divider = frame:CreateTexture(nil, "ARTWORK")
divider:SetHeight(1)

local compactText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
compactText:SetJustifyH("LEFT")

local talentsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
talentsText:SetJustifyH("LEFT")

local abilitiesLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
abilitiesLabel:SetJustifyH("LEFT")

local trainerHintText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
trainerHintText:SetJustifyH("LEFT")

local rows = {}  -- { label, value, delta } je Zeile, werden wiederverwendet

local function rowAt(index)
  if not rows[index] then
    local row = {
      label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
      value = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
      delta = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    }
    row.label:SetJustifyH("LEFT")
    row.value:SetJustifyH("RIGHT")
    row.delta:SetJustifyH("RIGHT")
    rows[index] = row
  end
  return rows[index]
end

local abilityButtons = {}

local function abilityButtonAt(index)
  if not abilityButtons[index] then
    local button = CreateFrame("Frame", nil, frame)
    button:SetSize(ABILITY_SIZE, ABILITY_SIZE)
    button:EnableMouse(true)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button:SetScript("OnEnter", function(self)
      local ability = self.ability
      if not ability then return end
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:AddLine(ability.name)
      if ability.rank and ability.rank ~= "" then GameTooltip:AddLine(ability.rank, 1, 1, 1) end
      GameTooltip:AddLine(string.format(L.LEVEL_UP_ABILITY_LEVEL, ability.level), 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    abilityButtons[index] = button
  end
  return abilityButtons[index]
end

local function textWidth(fontString)
  return fontString:GetStringWidth() or 0
end

local function setColor(texture, color, alpha)
  texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function applyTheme()
  local theme = THEME_COLORS[ns.db.levelUpTheme] or THEME_COLORS.modern
  setColor(background, theme.background, BACKGROUND_ALPHA)
  setColor(accent, theme.accent)
  setColor(divider, theme.accent, 0.5)
  for _, line in pairs(border) do setColor(line, theme.accent, 0.6) end
  title:SetTextColor(unpack(theme.title))
end

local function hideRows()
  for _, row in ipairs(rows) do
    row.label:Hide()
    row.value:Hide()
    row.delta:Hide()
  end
end

-- Eine Zeile der Tabelle: Name, "vorher -> nachher", "+Zuwachs"
local function fillRow(index, gain)
  local row = rowAt(index)
  row.label:SetText(gain.label)
  if gain.to then
    row.value:SetText(string.format("%d -> %d", gain.from, gain.to))
  else
    row.value:SetText("")
  end
  row.delta:SetText(string.format("%s+%d|r", ns.Theme.Hex("success"), gain.delta))
  return row
end

-- Symbole der Fähigkeiten ab top; Rückgabe: Höhe darunter
local function layoutAbilities(abilities, top)
  local count = math.min(#abilities, MAX_ABILITIES)
  abilitiesLabel:SetShown(count > 0)
  for index = count + 1, #abilityButtons do abilityButtons[index]:Hide() end
  if count == 0 then return top end
  abilitiesLabel:SetText(L.LEVEL_UP_NEW_ABILITIES)
  abilitiesLabel:ClearAllPoints()
  abilitiesLabel:SetPoint("TOPLEFT", PADDING, -top)
  top = top + ROW_HEIGHT
  for index = 1, count do
    local ability = abilities[index]
    local button = abilityButtonAt(index)
    local column = (index - 1) % ABILITIES_PER_ROW
    local line = math.floor((index - 1) / ABILITIES_PER_ROW)
    button.ability = ability
    button.icon:SetTexture(ability.icon or QUESTION_ICON)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", PADDING + column * (ABILITY_SIZE + ABILITY_GAP), -(top + line * (ABILITY_SIZE + ABILITY_GAP)))
    button:Show()
  end
  return top + math.ceil(count / ABILITIES_PER_ROW) * (ABILITY_SIZE + ABILITY_GAP)
end

-- Kompakt: alle Zuwächse in einem Text; Rückgabe: Breite, Höhe darunter
local function layoutCompact(gains, top, width)
  local parts = {}
  for _, gain in ipairs(gains and gains.rows or {}) do
    table.insert(parts, string.format("%s %s+%d|r", gain.label, ns.Theme.Hex("success"), gain.delta))
  end
  if gains and gains.talents then table.insert(parts, string.format(L.GAIN_TALENTS, gains.talents)) end
  if #parts == 0 then return width, top end
  compactText:SetText(table.concat(parts, "   "))
  compactText:SetWidth(0)
  width = math.max(width, math.min(textWidth(compactText), MAX_COMPACT_TEXT) + 2 * PADDING)
  compactText:SetWidth(width - 2 * PADDING)
  compactText:ClearAllPoints()
  compactText:SetPoint("TOPLEFT", PADDING, -top)
  compactText:Show()
  return width, top + (compactText:GetStringHeight() or ROW_HEIGHT) + LINE_GAP
end

-- Tabelle: Name links, "vorher -> nachher" und "+Zuwachs" rechts; Rückgabe: Breite, Höhe darunter
local function layoutTable(gainRows, top, width)
  divider:SetPoint("TOPLEFT", PADDING, -top)
  divider:SetPoint("TOPRIGHT", -PADDING, -top)
  top = top + LINE_GAP
  local labelWidth, valueWidth, deltaWidth = 0, 0, 0
  for index, gain in ipairs(gainRows) do
    local row = fillRow(index, gain)
    labelWidth = math.max(labelWidth, textWidth(row.label))
    valueWidth = math.max(valueWidth, textWidth(row.value))
    deltaWidth = math.max(deltaWidth, textWidth(row.delta))
  end
  width = math.max(width, 2 * PADDING + labelWidth + valueWidth + deltaWidth + 2 * COLUMN_GAP)
  for index = 1, #gainRows do
    local row = rows[index]
    row.label:ClearAllPoints()
    row.label:SetPoint("TOPLEFT", PADDING, -top)
    row.delta:ClearAllPoints()
    row.delta:SetPoint("TOPRIGHT", -PADDING, -top)
    row.value:ClearAllPoints()
    row.value:SetPoint("TOPRIGHT", -PADDING - deltaWidth - COLUMN_GAP, -top)
    row.label:Show()
    row.value:Show()
    row.delta:Show()
    top = top + ROW_HEIGHT
  end
  return width, top + LINE_GAP / 2
end

-- Inhalt aufbauen: level = neues Level, gains aus LevelGains (oder nil), abilities = Liste aus TrainerCache
local function layout(level, gains, abilities)
  applyTheme()
  title:SetText(string.format(L.ALERT_LEVEL_UP, level))
  local gainRows = gains and gains.rows or {}
  local compact = ns.db.levelUpCompact
  local top = PADDING + ACCENT_HEIGHT + TITLE_ICON + LINE_GAP
  local width = MIN_WIDTH

  divider:ClearAllPoints()
  compactText:Hide()
  talentsText:Hide()
  trainerHintText:Hide()
  hideRows()
  divider:SetShown(not compact and #gainRows > 0)

  if compact then
    width, top = layoutCompact(gains, top, width)
  else
    if #gainRows > 0 then width, top = layoutTable(gainRows, top, width) end
    if gains and gains.talents then
      talentsText:SetText(string.format(L.GAIN_TALENTS, gains.talents))
      talentsText:ClearAllPoints()
      talentsText:SetPoint("TOPLEFT", PADDING, -top)
      talentsText:Show()
      top = top + ROW_HEIGHT
    end
  end

  top = layoutAbilities(abilities, top)
  -- Lehrerliste noch nie gelesen: erklären, warum keine Fähigkeiten erscheinen
  if #abilities == 0 and ns.TrainerCache.IsAvailable() and ns.TrainerCache.Count() == 0 then
    trainerHintText:SetText(L.LEVEL_UP_TRAINER_UNKNOWN)
    trainerHintText:SetWidth(width - 2 * PADDING)
    trainerHintText:ClearAllPoints()
    trainerHintText:SetPoint("TOPLEFT", PADDING, -top)
    trainerHintText:Show()
    top = top + (trainerHintText:GetStringHeight() or ROW_HEIGHT) + LINE_GAP
  end
  width = math.max(width, 2 * PADDING + math.min(#abilities, ABILITIES_PER_ROW) * (ABILITY_SIZE + ABILITY_GAP))
  frame:SetSize(width, top + PADDING - LINE_GAP)
end

---------------------------------------------------------------------------
-- Anzeigen, Ausblenden, Warten im Kampf
---------------------------------------------------------------------------
local shownAt
local override  -- true = Vorschau (verschwindet nach SAMPLE_DURATION), MOVING = Edit-Modus (bleibt stehen)

local function duration()
  return math.max(LevelUpWindow.MIN_DURATION, math.min(LevelUpWindow.MAX_DURATION, ns.db.levelUpDuration))
end

local function hide()
  override = nil
  frame:Hide()
end

local function display(level, gains, abilities, overrideKind)
  layout(level, gains, abilities)
  override = overrideKind
  shownAt = GetTime()
  frame:SetAlpha(0)
  frame:Show()
end

ns.SetUpdateScript(frame, "LevelUpWindow", function(self)
  if not self:IsShown() then return end
  local age = GetTime() - shownAt
  if override then
    self:SetAlpha(math.min(1, age / FADE_IN))
    if override ~= MOVING and age >= SAMPLE_DURATION then hide() end
    return
  end
  local hold = duration()
  if self:IsMouseOver() and age > hold then  -- unter der Maus bleibt es stehen
    shownAt = GetTime() - hold
    age = hold
  end
  if age >= hold + FADE_OUT then
    hide()
  elseif age > hold then
    self:SetAlpha(1 - (age - hold) / FADE_OUT)
  else
    self:SetAlpha(math.min(1, age / FADE_IN))
  end
end)

-- Fähigkeiten, die der Lehrer ab diesem Level anbietet (leer, wo es keine Lehrerliste gibt)
local function abilitiesFor(level)
  return ns.TrainerCache.IsAvailable() and ns.TrainerCache.ForLevel(level) or {}
end

local pending  -- { level, gains }, wenn das Fenster im Kampf nicht erscheinen durfte

local function show(level, gains)
  local abilities = abilitiesFor(level)
  ns.Debug("levelup", "window for level %s: %s abilities, trainer cache %s", level, #abilities,
    ns.TrainerCache.IsAvailable())
  display(level, gains, abilities, nil)
  if ns.db.levelUpSound then ns.Alerts.PlaySound() end
end

ns.LevelGains.OnReady(function(level, gains)
  if not ns.db.levelUpWindow then return end
  if ns.InCombat() then
    pending = { level = level, gains = gains }
    ns.Print(L.LEVEL_UP_AFTER_COMBAT)
    return
  end
  show(level, gains)
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  local waiting = pending
  pending = nil
  if waiting and ns.db.levelUpWindow then show(waiting.level, waiting.gains) end
end)

---------------------------------------------------------------------------
-- Vorschau und Edit-Modus; Position und Größe über Lib/Frames.lua
---------------------------------------------------------------------------
-- Linksklick schließt das Fenster, Rechtsklick öffnet seine Einstellungen (Lib/Frames.lua; im Edit-Modus liegt dessen
-- Fläche darüber)
frame:EnableMouse(true)
frame:SetScript("OnMouseUp", function(_, mouseButton)
  if mouseButton == "LeftButton" and override ~= MOVING then hide() end
end)

Widgets.AttachTooltip(frame, function() return ns.DISPLAY_NAME end,
  function() return override ~= MOVING and L.LEVEL_UP_CLOSE_HINT or nil end)

-- Beispieldaten: Zuwächse auf die aktuellen Werte, Fähigkeiten aus dem Lehrer-Cache (sonst drei Beispiele)
local function sampleData()
  local level = ns.level + 1
  local abilities = abilitiesFor(level)
  if #abilities == 0 then
    for index = 1, 3 do
      abilities[index] = { name = string.format(L.LEVEL_UP_SAMPLE_ABILITY, index), rank = "", level = level }
    end
  end
  return level, ns.LevelGains.Sample(), abilities
end

function LevelUpWindow.Preview()
  if override == MOVING then return end
  display(ns.level + 1, ns.LevelGains.Sample(), select(3, sampleData()), true)
end

-- Edit-Modus: Beispiel bleibt stehen, bis der Modus endet
local function setEditing(enabled)
  if enabled == (override == MOVING) then return end
  if enabled then
    local level, gains, abilities = sampleData()
    display(level, gains, abilities, MOVING)
    frame:SetAlpha(1)
  else
    hide()
  end
end

ns.Frames.Register({
  id = "levelUp", frame = frame, label = "EDIT_FRAME_LEVEL_UP", default = DEFAULT_POSITION,
  settingsPage = "OPTIONS_PAGE_LEVEL_UP_WINDOW", preview = setEditing,
  hide = function() ns.Set("levelUpWindow", false) end,
})

function LevelUpWindow.IsShown()
  return frame:IsShown()
end


---------------------------------------------------------------------------
-- Blizzards Standardbanner: Ereignis abmelden, solange unser Fenster es ersetzt (und wieder anmelden)
---------------------------------------------------------------------------
local blizzardSilenced = false

local function updateBlizzardBanner()
  local banner = LevelUpDisplay
  if not banner or not banner.RegisterEvent then return end
  local silence = ns.db.levelUpWindow and ns.db.levelUpHideBlizzard
  if silence and not blizzardSilenced then
    banner:UnregisterEvent("PLAYER_LEVEL_UP")
    blizzardSilenced = true
    ns.Debug("levelup", "Blizzard banner off")
  elseif not silence and blizzardSilenced then
    banner:RegisterEvent("PLAYER_LEVEL_UP")
    blizzardSilenced = false
    ns.Debug("levelup", "Blizzard banner on")
  end
end

---------------------------------------------------------------------------
-- WoW Forever: Das Level-Up-Banner ist dort ein Toast des EventToastManager (Titel "Stufe 4"), kein LevelUpDisplay.
-- Alle Toasts abzuschalten ginge zu weit; deshalb wird nur der Toast geschlossen, der kurz nach dem Level-Up
-- erscheint und die neue Stufe im Titel trägt. Geschlossen wird mit Blizzards eigener Funktion (wie der Rechtsklick
-- auf den Toast); Alpha und Sichtbarkeit des Frames bleiben unangetastet.
---------------------------------------------------------------------------
local TOAST_MAX_AGE = 5  -- Sekunden nach PLAYER_LEVEL_UP, in denen ein Toast als Level-Up-Banner gilt
local lastLevelUp        -- { level, time }
local toastHooked = false

ns.RegisterEvent("PLAYER_LEVEL_UP", function(level)
  lastLevelUp = { level = level, time = GetTime() }
end)

local function isLevelUpToast(info)
  if not info or not lastLevelUp or GetTime() - lastLevelUp.time > TOAST_MAX_AGE then return false end
  local titleDisplay = Enum and Enum.EventToastDisplayType and Enum.EventToastDisplayType.NormalTitleAndSubTitle
  if info.displayType ~= titleDisplay then return false end
  -- Ganze Zahl im Titel: Stufe 4 passt nicht auf "Stufe 14" (mit Leerzeichen als Rand, damit Anfang und Ende zählen)
  return type(info.title) == "string" and (" " .. info.title .. " "):find("%D" .. lastLevelUp.level .. "%D") ~= nil
end

local function hookBlizzardToast()
  local manager = EventToastManagerFrame
  if toastHooked or not manager or not manager.Show or not manager.CloseActiveToasts then return end
  toastHooked = true
  hooksecurefunc(manager, "Show", function(self)
    local toast = self.currentDisplayingToast
    if ns.db.levelUpWindow and ns.db.levelUpHideBlizzard and isLevelUpToast(toast and toast.toastInfo) then
      self:CloseActiveToasts()
      ns.Debug("levelup", "Blizzard toast closed")
    end
  end)
end

ns.OnLogin(hookBlizzardToast)

ns.RegisterApply(function(db)
  updateBlizzardBanner()
  if frame:IsShown() and override then  -- Theme, Kompaktmodus oder Sprache haben sich geändert
    local level, gains, abilities = sampleData()
    layout(level, gains, abilities)
  end
end)
