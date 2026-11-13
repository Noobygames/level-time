-- Changelog für Spieler: merkt sich account-weit die zuletzt gestartete Addon-Version (LevelTimerStatsDB.changelog =
-- { version, seen = Datum des neuesten gezeigten Tags }). Startet eine andere Version und gibt es Tage nach "seen",
-- erscheint das Fenster mit genau diesen Änderungen (Haken "Nicht mehr automatisch anzeigen" = changelogAutoShow aus).
-- /lt changelog und der Knopf in den Einstellungen zeigen immer die letzten RECENT_DAYS Tage.
-- Beim allerersten Start kommt die Willkommenskarte; der Changelog gilt dann als gesehen.
-- Inhalt: UI/ChangelogData.lua (ns.CHANGELOG).
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

local WIDTH, HEIGHT = 520, 440
local MARGIN = 16
local TITLE_HEIGHT = 24
local CHECK_HEIGHT = 26
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
  local language = (ns.db and ns.db.language) or ns.DefaultLanguage()
  return entry[language] or entry.enUS
end

-- Ganzer Text: je Tag eine Überschrift, je Änderung eine Zeile "• Neu: ..."
function Changelog.Format(days)
  local lines = {}
  for _, day in ipairs(days) do
    if #lines > 0 then lines[#lines + 1] = "" end
    lines[#lines + 1] = "|cffffd100" .. day.date .. "|r"
    for _, entry in ipairs(day.entries) do
      lines[#lines + 1] = string.format("• |c%s%s:|r %s", KIND_COLORS[entry.kind] or "ffffffff",
        L[KIND_LABELS[entry.kind] or "CHANGELOG_CHANGE"], Changelog.EntryText(entry))
    end
  end
  return table.concat(lines, "\n")
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

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -MARGIN)

local area = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, keepInRange = true })
area:SetPoint("TOPLEFT", MARGIN, -MARGIN - TITLE_HEIGHT)
area:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN + CHECK_HEIGHT)
local content = CreateFrame("Frame", nil, area)
content:SetSize(WIDTH - 2 * MARGIN, 1)
area:SetScrollChild(content)
local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
body:SetPoint("TOPLEFT")
body:SetWidth(WIDTH - 2 * MARGIN)
body:SetJustifyH("LEFT")
body:SetSpacing(2)

local hideCheck = Widgets.CreateCheckbox(panel, function(checked) ns.Set("changelogAutoShow", not checked) end)
hideCheck:SetPoint("BOTTOMLEFT", MARGIN - CHECK_INSET, MARGIN - CHECK_INSET)

local shownDays = {}

local function refresh()
  title:SetText(L.CHANGELOG_TITLE)
  body:SetText(Changelog.Format(shownDays))
  content:SetHeight(math.max(1, body:GetStringHeight() or 1))
  hideCheck.label:SetText(L.CHANGELOG_DONT_SHOW)
  hideCheck:SetChecked(ns.db and ns.db.changelogAutoShow == false)
  hideCheck:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + (hideCheck.label:GetStringWidth() or 0)), 0, 0)
end
Widgets.AttachTooltip(hideCheck, function() return L.CHANGELOG_DONT_SHOW end,
  function() return L.CHANGELOG_DONT_SHOW_TIP end)

function Changelog.Show(days)
  if not ns.db or #days == 0 then return end
  shownDays = days
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

function Changelog.Text()
  return body:GetText()
end

-- Test-Zugriff: Haken "Nicht mehr anzeigen"
function Changelog.HideCheck()
  return hideCheck
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
