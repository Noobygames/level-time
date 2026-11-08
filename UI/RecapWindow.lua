-- Session-Abschlusskarte (/lt recap): Überblick über die laufende Session als kleines Fenster,
-- z.B. als Abspann im Stream oder Screenshot für Discord. Zeilen: Bezeichnung links, Wert rechts.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats
local History = ns.History

local RecapWindow = {}
ns.RecapWindow = RecapWindow

local MIN_WIDTH = 260
local MARGIN = 16
local CONTENT_TOP = -44
local ROW_HEIGHT = 18
local COLUMN_GAP = 24
local NO_VALUE = Format.NO_VALUE
local BACKGROUND_ALPHA = 0.95  -- ohne Chroma-Hintergrund fast deckend, unabhängig von bgAlpha des Zeitfensters
local UPDATE_INTERVAL = 1      -- s: offene Karte zählt mit (Zeit, XP, Kills)

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Einträge eines Journals seit Beginn der Session, älteste zuerst. Der Eingang ist nach Zeit geordnet (angehängt mit
-- time()): von hinten lesen und beim ersten älteren Eintrag aufhören, statt jede Sekunde den ganzen Eingang.
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

-- Zeilen { label, value } der laufenden Session
function RecapWindow.BuildRows()
  local session = ns.character.currentSession
  local rows = {
    { L.RECAP_CHARACTER, History.DisplayName(ns.characterKey) },
    { L.RECAP_TIME, Format.Duration(Stats.GetSeconds(Stats.SESSION)) },
    { L.RECAP_LEVELS, string.format("%d > %d", session.startLevel or ns.level, ns.level) },
    { L.RECAP_XP, xpWithRate() },
    { L.RECAP_KILLS, tostring(Stats.GetTotalKills(Stats.SESSION)) },
    { L.ROW_DEATHS, tostring(Stats.Get(Stats.SESSION, Stats.DEATHS)) },
  }
  -- Beinahe-Tode nur, wo der Client das Leben lesbar macht (sonst stünde hier immer eine falsche 0)
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

local function render()
  title:SetText(L.RECAP_TITLE)
  local width = math.max(MIN_WIDTH, title:GetStringWidth() + 2 * MARGIN)
  local content = RecapWindow.BuildRows()
  for i, line in ipairs(content) do
    local row = getRow(i)
    row.label:SetText(line[1])
    row.value:SetText(line[2])
    width = math.max(width, row.label:GetStringWidth() + COLUMN_GAP + row.value:GetStringWidth() + 2 * MARGIN)
  end
  panel:SetSize(width, -CONTENT_TOP + #content * ROW_HEIGHT + MARGIN)
end

-- Chroma-Hintergrund des Zeitfensters (Stream, OBS) übernehmen, sonst der eigene dunkle
local function applyBackground(db)
  if ns.Theme.CHROMA[db.windowBackground] then
    ns.Theme.ApplyBackground(panel, db)
  else
    Widgets.SetDefaultBackground(panel, BACKGROUND_ALPHA)
  end
end

function ns.ToggleRecap()
  if not ns.db then return end
  if panel:IsShown() then
    panel:Hide()
  else
    render()
    panel:Show()
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
