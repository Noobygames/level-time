-- Session- und Abschlusskarten (/lt recap, /lt recap death, /lt recap max):
-- Überblick über die laufende Session, Nachruf beim Tod (Hardcore) oder Abschlusskarte bei Max-Level
-- als kleines Fenster zum Zeigen und Kopieren (Discord, Twitch).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats
local History = ns.History

ns.Database.RegisterDefaults({
  settings = {
    showDeathCard = false,
    showMaxLevelCard = false,
  },
})

local RecapWindow = {
  MODE_SESSION = "session",
  MODE_DEATH = "death",
  MODE_MAX = "max",
}
ns.RecapWindow = RecapWindow

local MIN_WIDTH = 260
local MARGIN = 16
local CONTENT_TOP = -44
local ROW_HEIGHT = 18
local COLUMN_GAP = 24
local BUTTON_HEIGHT = 22
local NO_VALUE = Format.NO_VALUE
local BACKGROUND_ALPHA = 0.95  -- ohne Chroma-Hintergrund fast deckend, unabhängig von bgAlpha des Zeitfensters
local UPDATE_INTERVAL = 1      -- s: offene Karte zählt mit (Zeit, XP, Kills)

local currentMode = RecapWindow.MODE_SESSION

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Einträge eines Journals seit Beginn der Session, älteste zuerst.
local function sinceSessionStart(log)
  local startedAt = ns.character.currentSession.startedAt or 0
  local first = #log + 1
  while first > 1 and (log[first - 1].time or 0) >= startedAt do first = first - 1 end
  local entries = {}
  for i = first, #log do entries[#entries + 1] = log[i] end
  return entries
end

-- Beste Beute = höchste Qualität, bei Gleichstand die neueste
local function bestLoot()
  local best
  for _, entry in ipairs(sinceSessionStart(ns.character.lootLog)) do
    if not best or (entry.quality or 0) >= (best.quality or 0) then best = entry end
  end
  return best and (best.link or best.name) or NO_VALUE
end

-- Gefährlichster Gegner = häufigste Ursache von Toden und Beinahe-Toden, "Name (Anzahl)"
local function mostDangerous()
  local counts = {}
  for _, logName in ipairs({ "deathLog", "nearDeathLog" }) do
    for _, entry in ipairs(sinceSessionStart(ns.character[logName])) do
      if entry.killer then counts[entry.killer] = (counts[entry.killer] or 0) + 1 end
    end
  end
  local name, count = nil, 0
  for killer, times in pairs(counts) do
    if times > count or (times == count and killer < name) then name, count = killer, times end
  end
  return name and string.format("%s (%d)", name, count) or NO_VALUE
end

local function xpWithRate()
  local rate = ns.Experience.GetRatePerHour(Stats.SESSION)
  local xp = Format.Number(Stats.GetXp(Stats.SESSION))
  return rate and string.format("%s (%s %s)", xp, Format.Number(rate), L.ROW_XP_RATE) or xp
end

-- "25" ohne Level-Up, sonst "10 bis 12" (RECAP_LEVEL_RANGE)
local function levelText(startLevel)
  if startLevel == ns.level then return tostring(ns.level) end
  return string.format(L.RECAP_LEVEL_RANGE, startLevel, ns.level)
end

local function bestSplitsText()
  local completed = {}
  for _, record in pairs(ns.character.levelHistory or {}) do
    if record.seconds and record.seconds > 0 then
      table.insert(completed, { level = record.level, seconds = record.seconds })
    end
  end
  table.sort(completed, function(a, b) return a.seconds < b.seconds end)
  if #completed == 0 then return NO_VALUE end
  local parts = {}
  for i = 1, math.min(3, #completed) do
    table.insert(parts, string.format("Level %d (%s)", completed[i].level, Format.Duration(completed[i].seconds)))
  end
  return table.concat(parts, ", ")
end

local function characterTotals()
  local summary = History.Summarize(History.GetLevelRecords(ns.characterKey))
  local totalDeaths = (summary.counters and summary.counters[Stats.DEATHS]) or 0
  if ns.character and ns.character.deathLog and #ns.character.deathLog > totalDeaths then
    totalDeaths = #ns.character.deathLog
  end
  local totalKills = ((summary.counters and summary.counters[Stats.PVE_KILLS]) or 0) +
                     ((summary.counters and summary.counters[Stats.PVP_KILLS]) or 0)
  return totalDeaths, totalKills
end

-- Zeilen { label, value } je Modus
function RecapWindow.BuildRows(mode)
  local targetMode = mode or currentMode
  if targetMode == RecapWindow.MODE_DEATH then
    local death = ns.character.deathLog and ns.character.deathLog[#ns.character.deathLog]
    local deathLevel = (death and death.level) or ns.level
    local deathZone = (death and death.zone) or (GetZoneText and GetZoneText()) or "?"
    local totalDeaths, totalKills = characterTotals()
    local deathCause = death and History.DeathCauseText(death) or NO_VALUE
    return {
      { L.RECAP_CHARACTER, History.DisplayName(ns.characterKey) },
      { L.RECAP_STATUS, string.format(L.RECAP_STATUS_DEATH, deathLevel, deathZone) },
      { L.RECAP_TOTAL_PLAYED, Format.Duration(ns.PlayedTime.GetTotalSeconds() or 0) },
      { L.RECAP_LEVEL_TIME, Format.Duration(Stats.GetSeconds(Stats.LEVEL) or 0) },
      { L.RECAP_KILLER, deathCause },
      { L.RECAP_TOTAL_DEATHS, tostring(totalDeaths) },
      { L.RECAP_TOTAL_KILLS, tostring(totalKills) },
      { L.RECAP_BEST_SPLITS, bestSplitsText() },
    }
  elseif targetMode == RecapWindow.MODE_MAX then
    local totalDeaths, totalKills = characterTotals()
    return {
      { L.RECAP_CHARACTER, History.DisplayName(ns.characterKey) },
      { L.RECAP_STATUS, string.format(L.RECAP_STATUS_MAX, ns.level) },
      { L.RECAP_TOTAL_PLAYED, Format.Duration(ns.PlayedTime.GetTotalSeconds() or 0) },
      { L.RECAP_LEVEL_TIME, Format.Duration(Stats.GetSeconds(Stats.LEVEL) or 0) },
      { L.RECAP_TOTAL_DEATHS, tostring(totalDeaths) },
      { L.RECAP_TOTAL_KILLS, tostring(totalKills) },
      { L.RECAP_BEST_SPLITS, bestSplitsText() },
    }
  end

  local session = ns.character.currentSession
  local rows = {
    { L.RECAP_CHARACTER, History.DisplayName(ns.characterKey) },
    { L.RECAP_TIME, Format.Duration(Stats.GetSeconds(Stats.SESSION)) },
    { L.RECAP_LEVELS, levelText(session.startLevel or ns.level) },
    { L.RECAP_XP, xpWithRate() },
    { L.RECAP_KILLS, tostring(Stats.GetTotalKills(Stats.SESSION)) },
    { L.ROW_DEATHS, tostring(Stats.Get(Stats.SESSION, Stats.DEATHS)) },
  }
  if ns.NearDeath.IsAvailable() then
    table.insert(rows, { L.ROW_NEAR_DEATHS, tostring(Stats.Get(Stats.SESSION, Stats.NEAR_DEATHS)) })
  end
  table.insert(rows, { L.ROW_QUESTS, tostring(Stats.Get(Stats.SESSION, Stats.QUESTS)) })
  table.insert(rows, { L.ROW_MONEY, Format.Money(Stats.Get(Stats.SESSION, Stats.MONEY_EARNED)) })
  table.insert(rows, { L.RECAP_BEST_LOOT, bestLoot() })
  table.insert(rows, { L.RECAP_DANGER, mostDangerous() })
  return rows
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel(ns.GlobalName("Recap"), BACKGROUND_ALPHA)
panel:SetPoint("CENTER", UIParent, "CENTER", -40, -40)  -- versetzt zu den Einstellungen
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, ns.GlobalName("Recap"))  -- mit ESC schließen
Widgets.CreateCloseButton(panel)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

local copyButton = Widgets.CreateButton(panel, 80, BUTTON_HEIGHT, function()
  local content = RecapWindow.BuildRows(currentMode)
  local heading = title:GetText() or L.RECAP_TITLE
  local lines = { heading }
  for _, line in ipairs(content) do
    table.insert(lines, line[1] .. ": " .. line[2])
  end
  ns.Export.Show(heading, table.concat(lines, "\n"))
end)
copyButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, MARGIN)
Widgets.SetButtonText(copyButton, L.RECAP_COPY, 80)
Widgets.AttachTooltip(copyButton, L.RECAP_COPY_TIP, L.RECAP_COPY)

local rows = {}  -- { label, value } Schriftzeilen, bei Bedarf angelegt

local function getRow(index)
  if not rows[index] then
    local y = CONTENT_TOP - (index - 1) * ROW_HEIGHT
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", MARGIN, y)
    local value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPRIGHT", -MARGIN, y)
    rows[index] = { label = label, value = value }
  end
  return rows[index]
end

local function modeTitle(mode)
  if mode == RecapWindow.MODE_DEATH then return L.RECAP_TITLE_DEATH end
  if mode == RecapWindow.MODE_MAX then return L.RECAP_TITLE_MAX end
  return L.RECAP_TITLE
end

local function render()
  title:SetText(modeTitle(currentMode))
  Widgets.SetButtonText(copyButton, L.RECAP_COPY, 80)
  local width = math.max(MIN_WIDTH, title:GetStringWidth() + 2 * MARGIN)
  local content = RecapWindow.BuildRows(currentMode)
  for i, line in ipairs(content) do
    local row = getRow(i)
    row.label:SetText(line[1])
    row.value:SetText(line[2])
    row.label:Show()
    row.value:Show()
    width = math.max(width, row.label:GetStringWidth() + COLUMN_GAP + row.value:GetStringWidth() + 2 * MARGIN)
  end
  for i = #content + 1, #rows do
    rows[i].label:Hide()
    rows[i].value:Hide()
  end
  width = math.max(width, copyButton:GetWidth() + 2 * MARGIN)
  panel:SetSize(width, -CONTENT_TOP + #content * ROW_HEIGHT + MARGIN + BUTTON_HEIGHT + MARGIN)
end

function RecapWindow.ShowMode(mode)
  currentMode = mode or RecapWindow.MODE_SESSION
  render()
  panel:Show()
end

function RecapWindow.GetMode()
  return currentMode
end

-- Chroma-Hintergrund des Zeitfensters (Stream, OBS) übernehmen, sonst der eigene dunkle
local function applyBackground(db)
  if ns.Theme.CHROMA[db.windowBackground] then
    ns.Theme.ApplyBackground(panel, db)
  else
    Widgets.SetDefaultBackground(panel, BACKGROUND_ALPHA)
  end
end

function ns.ToggleRecap(mode)
  if not ns.db then return end
  local targetMode = mode or RecapWindow.MODE_SESSION
  if panel:IsShown() and currentMode == targetMode then
    panel:Hide()
  else
    RecapWindow.ShowMode(targetMode)
  end
end

-- Offen zählt die Karte mit, statt beim Öffnen stehen zu bleiben (nur solange sichtbar)
local sinceUpdate = 0
panel:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  render()
end)

-- Sprach- oder Hintergrundwechsel, auch bei offenem Fenster
ns.RegisterApply(function(db)
  applyBackground(db)
  if panel:IsShown() then render() end
end)

-- Automatische Einblendung beim Tod oder Max-Level
ns.RegisterEvent("PLAYER_DEAD", function()
  if ns.db and ns.db.showDeathCard then
    RecapWindow.ShowMode(RecapWindow.MODE_DEATH)
  end
end)

local function isPlayerMaxLevel()
  if GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel then
    return GameRulesUtil.IsPlayerAtEffectiveMaxLevel()
  end
  if IsPlayerAtEffectiveMaxLevel then return IsPlayerAtEffectiveMaxLevel() end
  return GetMaxPlayerLevel ~= nil and ns.level >= GetMaxPlayerLevel()
end

ns.OnLevelStarted(function()
  if ns.db and ns.db.showMaxLevelCard and isPlayerMaxLevel() then
    RecapWindow.ShowMode(RecapWindow.MODE_MAX)
  end
end)
