-- Changelog für Spieler: merkt sich account-weit die zuletzt gestartete Addon-Version (LevelTimerStatsDB.changelog =
-- { version, seen = Datum des neuesten gezeigten Tags }). Startet eine andere Version und gibt es Tage nach "seen",
-- erscheint das Fenster mit genau diesen Änderungen (Haken "Nicht mehr automatisch anzeigen" = changelogAutoShow aus).
-- /lt changelog und der Knopf in den Einstellungen zeigen immer die letzten RECENT_DAYS Tage.
-- Beim allerersten Start kommt die Willkommenskarte; der Changelog gilt dann als gesehen.
-- Inhalt: UI/ChangelogData.lua (ns.CHANGELOG). Je Tag eine einklappbare Überschrift (beim Öffnen nur der neueste Tag
-- offen), darunter die Änderungen nach Art: neu, geändert, behoben. Unten fest (scrollt nicht mit) eine Danksagung.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

ns.RegisterDefaults({
  settings = {
    changelogAutoShow = true,
  },
})

local Changelog = {}
ns.Changelog = Changelog

local RECENT_DAYS = 14
local SECONDS_PER_DAY = 86400
local KIND_COLORS = { new = "ff66dd66", fix = "ffffcc44", change = "ff66bbff" }
local KIND_LABELS = { new = "CHANGELOG_NEW", fix = "CHANGELOG_FIX", change = "CHANGELOG_CHANGE" }
local KIND_ORDER = { "new", "change", "fix" }
local THANKS = { "mamo_derechte" }  -- Danksagung unten im Fenster
local COLLAPSED_MARK, EXPANDED_MARK = "+", "-"

local WIDTH, HEIGHT = 520, 440
local MARGIN = 16
local TITLE_HEIGHT = 24
local CHECK_HEIGHT = 26
local THANKS_HEIGHT = 22
local DAY_GAP = 6          -- Abstand zwischen zwei Tagen
local DAY_BODY_GAP = 4     -- Überschrift bis Text
local CHECK_INSET = 4      -- die Checkbox-Vorlage hat links etwas Rand
local SCROLL_STEP = 40

function Changelog.Version()
  local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = getMetadata and getMetadata(ns.ADDON_ID, "Version")
  return type(version) == "string" and version or nil
end

-- Tage nach dem Datum "seen" (YYYY-MM-DD, Textvergleich reicht); nil = alle Tage
function Changelog.DaysAfter(seen)
  local days = {}
  for _, day in ipairs(ns.CHANGELOG) do
    if not seen or day.date > seen then days[#days + 1] = day end
  end
  return days
end

-- Tage der letzten RECENT_DAYS Tage ab heute; gab es so lange kein Update, wenigstens der neueste Tag
function Changelog.Recent(now)
  local since = date("%Y-%m-%d", (now or time()) - RECENT_DAYS * SECONDS_PER_DAY)
  local days = {}
  for _, day in ipairs(ns.CHANGELOG) do
    if day.date >= since then days[#days + 1] = day end
  end
  if #days == 0 and ns.CHANGELOG[1] then days[1] = ns.CHANGELOG[1] end
  return days
end

-- Zeile in der eingestellten Sprache, Fallback Englisch
function Changelog.EntryText(entry)
  return entry[ns.Language()] or entry.enUS
end

-- Änderungen eines Tages nach Art (neu, geändert, behoben), je Änderung eine Zeile "• Neu: ..."; unbekannte Art
-- zählt als geändert
function Changelog.FormatDay(day)
  local lines = {}
  for _, kind in ipairs(KIND_ORDER) do
    for _, entry in ipairs(day.entries) do
      local entryKind = KIND_LABELS[entry.kind] and entry.kind or "change"
      if entryKind == kind then
        lines[#lines + 1] = string.format("• |c%s%s:|r %s", KIND_COLORS[kind], L[KIND_LABELS[kind]],
          Changelog.EntryText(entry))
      end
    end
  end
  return table.concat(lines, "\n")
end

-- Ganzer Text aller Tage (Datum, dann die Zeilen)
function Changelog.Format(days)
  local blocks = {}
  for _, day in ipairs(days) do
    blocks[#blocks + 1] = ns.Theme.Hex("gold") .. day.date .. "|r\n" .. Changelog.FormatDay(day)
  end
  return table.concat(blocks, "\n\n")
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel(ns.GlobalName("Changelog"), 0.95)
panel:SetSize(WIDTH, HEIGHT)
panel:SetPoint("CENTER", 0, 60)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
Widgets.CreateCloseButton(panel)
table.insert(UISpecialFrames, ns.GlobalName("Changelog"))  -- mit ESC schließen

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -MARGIN)

local CONTENT_WIDTH = WIDTH - 2 * MARGIN
local area = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, keepInRange = true })
area:SetPoint("TOPLEFT", MARGIN, -MARGIN - TITLE_HEIGHT)
area:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN + CHECK_HEIGHT + THANKS_HEIGHT)
local content = CreateFrame("Frame", nil, area)
content:SetSize(CONTENT_WIDTH, 1)
area:SetScrollChild(content)

-- Danksagung: fest über dem Haken, scrollt nicht mit
local thanks = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
thanks:SetPoint("BOTTOMLEFT", MARGIN, MARGIN + CHECK_HEIGHT)
thanks:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN + CHECK_HEIGHT)
thanks:SetHeight(THANKS_HEIGHT)
thanks:SetJustifyH("CENTER")

local hideCheck = Widgets.CreateCheckbox(panel, function(checked) ns.Set("changelogAutoShow", not checked) end)
hideCheck:SetPoint("BOTTOMLEFT", MARGIN - CHECK_INSET, MARGIN - CHECK_INSET)

local shownDays = {}
local expanded = {}  -- Datum -> true, wenn der Tag offen ist
local dayRows = {}   -- je gezeigtem Tag: Überschrift und Text (wiederverwendet)
local refresh

local function dayRow(index)
  if dayRows[index] then return dayRows[index] end
  local header = Widgets.CreateSectionHeader(content)
  header:EnableMouse(true)
  header:SetScript("OnMouseUp", function(self)
    expanded[self.date] = not expanded[self.date] or nil
    refresh()
  end)
  Widgets.AttachTooltip(header, function() return header.date end, function() return L.SECTION_COLLAPSE_TIP end)
  local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  body:SetWidth(CONTENT_WIDTH)
  body:SetJustifyH("LEFT")
  body:SetSpacing(2)
  dayRows[index] = { header = header, body = body }
  return dayRows[index]
end

-- Tage untereinander: Überschrift mit +/-; offen folgt der Text
local function layoutDays()
  local y = 0
  for index, day in ipairs(shownDays) do
    local row = dayRow(index)
    local open = expanded[day.date] == true
    row.header.date = day.date
    row.header:SetText((open and EXPANDED_MARK or COLLAPSED_MARK) .. " " .. day.date)
    row.header:ClearAllPoints()
    row.header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    row.header:SetPoint("RIGHT", content, "RIGHT")
    row.header:Show()
    y = y + (row.header:GetHeight() or 0)
    row.body:ClearAllPoints()
    row.body:SetShown(open)
    if open then
      row.body:SetText(Changelog.FormatDay(day))
      row.body:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(y + DAY_BODY_GAP))
      y = y + DAY_BODY_GAP + math.ceil(row.body:GetStringHeight() or 0)
    end
    y = y + DAY_GAP
  end
  for index = #shownDays + 1, #dayRows do
    dayRows[index].header:Hide()
    dayRows[index].body:Hide()
  end
  content:SetHeight(math.max(1, y))
end

refresh = function()
  title:SetText(L.CHANGELOG_TITLE)
  layoutDays()
  thanks:SetText(string.format(L.CHANGELOG_THANKS, table.concat(THANKS, ", ")))
  hideCheck.label:SetText(L.CHANGELOG_DONT_SHOW)
  hideCheck:SetChecked(ns.db and ns.db.changelogAutoShow == false)
  hideCheck:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + (hideCheck.label:GetStringWidth() or 0)), 0, 0)
end
Widgets.AttachTooltip(hideCheck, function() return L.CHANGELOG_DONT_SHOW end,
  function() return L.CHANGELOG_DONT_SHOW_TIP end)

function Changelog.Show(days)
  if not ns.db or #days == 0 then return end
  shownDays = days
  expanded = { [days[1].date] = true }  -- nur der neueste Tag offen
  refresh()
  area:ScrollTo(0)
  panel:Show()
end

function Changelog.ShowRecent()
  Changelog.Show(Changelog.Recent())
end

function Changelog.IsShown()
  return panel:IsShown()
end

-- Ganzer Text der gezeigten Tage (auch eingeklappter)
function Changelog.Text()
  return Changelog.Format(shownDays)
end

-- Test-Zugriff: Haken "Nicht mehr anzeigen", Überschrift des n-ten Tags, ist ein Tag offen?
function Changelog.HideCheck()
  return hideCheck
end
function Changelog.DayHeader(index)
  return dayRows[index] and dayRows[index].header
end
function Changelog.IsExpanded(day)
  return expanded[day] == true
end

ns.RegisterApply(function()
  if panel:IsShown() then refresh() end
end)

-- Andere Version als beim letzten Start: ungesehene Tage zeigen. Läuft vor Commands.lua, das den ersten Start merkt.
ns.OnLogin(function()
  LevelTimerStatsDB.changelog = LevelTimerStatsDB.changelog or {}
  local store = LevelTimerStatsDB.changelog
  local version, newest = Changelog.Version(), ns.CHANGELOG[1] and ns.CHANGELOG[1].date
  local changed = version ~= store.version
  local unseen = Changelog.DaysAfter(store.seen)
  ns.Debug("changelog", "version %s, last %s, unseen days %s", version, store.version, #unseen)
  if changed and not ns.Database.IsFirstStart() and ns.db.changelogAutoShow then Changelog.Show(unseen) end
  store.version, store.seen = version, newest or store.seen
end)
