-- UX-Review Paket 2 (Roadmap 436): Tooltips an den Werten im Hauptfenster (W1), Tode mit Totzeit (W9), Erklärung je
-- Spaltenkopf der Historie (W3), Hinweiszeile der Graphen (W5), Tooltips der Werkzeugknöpfe (W24), abhängige
-- Schalter ausgegraut (S30), Recap ohne "25 > 25" (W36) und einheitliche Begriffe.
local L = addon.L
local Stats = addon.Stats
wow.login({ level = 10, xp = 0, xpMax = 1000 })

---------------------------------------------------------------------------
-- W1: Mausfläche je Zeile mit Erklärung der Stat und des Platzhalters
---------------------------------------------------------------------------
addon.Set("windowLayout", "table")
addon.Set("showDeaths", true)
addon.Set("showXpRate", true)
wow.update(1)
local elements = addon.TimerWindow.Elements()

local function rowWith(key)
  for _, row in ipairs(elements.rows) do
    if row.hover.data and row.hover.data.key == key and row.hover:IsShown() then return row end
  end
end

local deaths = rowWith("ROW_DEATHS")
expectTrue("Zeile Tode hat eine Mausfläche", deaths ~= nil)
deaths.hover._scripts.OnEnter(deaths.hover)
expect("Titel = Bezeichnung", GameTooltip._text, L.ROW_DEATHS)
expect("Text = Erklärung der Stat", GameTooltip._lines[1], L.STAT_DEATHS_TIP)
deaths.hover._scripts.OnLeave(deaths.hover)

-- XP/h in der ersten Minute: "...", der Tooltip erklärt den Platzhalter
local rate = rowWith("ROW_XP_RATE")
expect("XP/h noch offen", rate.hover.data.value, addon.Format.PENDING)
rate.hover._scripts.OnEnter(rate.hover)
expect("Platzhalter erklärt", GameTooltip._lines[1], L.STAT_XP_RATE_TIP .. "\n\n" .. L.ROW_PENDING_TIP)
expect("RowTip ohne Platzhalter", addon.WindowElements.RowTip({ stat = { label = "STAT_DEATHS" }, value = "3" }),
  L.STAT_DEATHS_TIP)
expect("RowTip mit -", addon.WindowElements.RowTip({ stat = { label = "STAT_DEATHS" }, value = "-" }),
  L.STAT_DEATHS_TIP .. "\n\n" .. L.ROW_NO_VALUE_TIP)
expect("ohne Daten kein Tooltip", addon.WindowElements.RowTip(nil), nil)

-- Ziehen und Rechtsklick gehen an das Fenster weiter
local forwarded = {}
local window = LevelTimerFrame
local originalUp = window._scripts.OnMouseUp
window._scripts.OnMouseUp = function(_, button) forwarded.up = button end
deaths.hover._scripts.OnMouseUp(deaths.hover, "RightButton")
expect("Rechtsklick ans Fenster", forwarded.up, "RightButton")
window._scripts.OnMouseUp = originalUp

-- Kacheln: jede Kachel außer der Zeit hat den Tooltip ihrer Zeile
addon.Set("windowLayout", "tiles")
wow.update(1)
local tile = elements.tiles[2]
expectTrue("Kachel mit Daten", tile.data ~= nil)
tile.frame._scripts.OnEnter(tile.frame)
expect("Kachel-Tooltip", GameTooltip._text, tile.data.label)
expect("Zeit-Kachel ohne Daten", elements.tiles[1].data, nil)
addon.Set("windowLayout", "table")
wow.update(1)

---------------------------------------------------------------------------
-- W9: Totzeit mit Bezeichnung
---------------------------------------------------------------------------
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.advance(90)
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")
wow.update(1)
local deathText = string.format(L.DEATHS_WITH_DEAD_TIME, 1, addon.Format.Duration(90))
expectTrue("Tode mit Totzeit", rowWith("ROW_DEATHS").hover.data.value:find(deathText, 1, true) ~= nil)

---------------------------------------------------------------------------
-- W3: Spaltenköpfe erklären sich (<header>_TIP), sonst der Sortier-Hinweis
---------------------------------------------------------------------------
local HEADERS = { "HISTORY_PVE", "HISTORY_PVP", "HISTORY_LEVELS_DONE", "HISTORY_RESTED", "HISTORY_REST", "HISTORY_IDLE",
  "HISTORY_LEVEL_SHARE", "HISTORY_LOWEST_HEALTH", "HISTORY_INCOME", "HISTORY_SPENDING", "HISTORY_BALANCE",
  "HISTORY_RUN_CATEGORY", "HISTORY_AVERAGE_XP", "HISTORY_XP_RATE", "HISTORY_KILL_RATE", "HISTORY_ITEM_RATE" }
for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  addon.Set("language", language)
  for _, header in ipairs(HEADERS) do
    expect(language .. " " .. header, addon.TableView.HeaderTip({ header = header }), L[header .. "_TIP"])
  end
end
addon.Set("language", "deDE")
expect("eigener tip gewinnt", addon.TableView.HeaderTip({ header = "HISTORY_PVE", tip = "HISTORY_COVERAGE_TIP" }),
  L.HISTORY_COVERAGE_TIP)
expect("ohne Erklärung der Sortier-Hinweis", addon.TableView.HeaderTip({ header = "TEST_HEADER_WITHOUT_TIP" }),
  L.TABLE_SORT_HINT)

---------------------------------------------------------------------------
-- W5: Graphen mit Hinweiszeile; W24: Werkzeugknöpfe mit Tooltip
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Graphen", wow.click(L.HISTORY_TAB_CHARTS))
expectTrue("Diagramm Zeit je Level", wow.click(L.CHART_LEVEL_TIME))
local hint = wow.findFrame(function(frame)
  return rawget(frame, "hint") ~= nil and frame.hint._text == L.CHART_LEVEL_TIME_HINT
end)
expectTrue("Hinweis unter dem Diagramm", hint ~= nil)

expectTrue("Reiter Speedrun", wow.click(L.HISTORY_GROUP_SPEEDRUN))
expectTrue("Läufe", wow.click(L.HISTORY_TAB_RUNS))
local backup = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == L.RUNS_BACKUP and frame:IsShown()
end)
backup._scripts.OnEnter(backup)
expect("Tooltip Alle sichern", GameTooltip._lines[1], L.RUNS_BACKUP_TIP)
SlashCmdList.LEVELTIMER("history")

---------------------------------------------------------------------------
-- S30: abhängige Schalter ausgegraut, solange ihr Hauptschalter aus ist
---------------------------------------------------------------------------
local options = addon.OptionsWindow
SlashCmdList.LEVELTIMER("config")
local function controlOf(labelKey)
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if entry.tipKey == labelKey .. "_TIP" then return entry.left end
  end
end
for _, case in ipairs({
  { page = "OPTIONS_PAGE_FLIGHTS", label = "FLIGHT_TOOLTIP_TOGGLE", setting = "flightTimer" },
  { page = "COMFORT_PAGE_AUTOMATION", label = "AUTO_REPAIR_GUILD", setting = "autoRepair" },
  { page = "OPTIONS_PAGE_ALERT_KINDS", label = "ALERT_TOGGLE_RARE_FLASH", setting = "alertRareSpotted" },
  { page = "OPTIONS_PAGE_LEVEL_UP_WINDOW", label = "LEVEL_UP_COMPACT", setting = "levelUpWindow" },
  { page = "COMFORT_PAGE_SYSTEM", label = "LOOT_ROLL_NAMES_TOGGLE", setting = "lootRollCounts" },
}) do
  options.ShowPage(case.page)
  local control = controlOf(case.label)
  if control then
    addon.Set(case.setting, false)
    options.Refresh(addon.db)
    expect(case.label .. ": aus = ausgegraut", control:GetAlpha() < 1, true)
    addon.Set(case.setting, true)
    options.Refresh(addon.db)
    expect(case.label .. ": an = bedienbar", control:GetAlpha(), 1)
  else
    expect(case.label .. " fehlt nur, wo der Client ihn nicht kennt", case.label, "AUTO_REPAIR_GUILD")
  end
end
SlashCmdList.LEVELTIMER("config")

---------------------------------------------------------------------------
-- W36: Recap ohne Level-Up nur das Level
---------------------------------------------------------------------------
local function recapLevel()
  for _, row in ipairs(addon.RecapWindow.BuildRows()) do
    if row[1] == L.RECAP_LEVELS then return row[2] end
  end
end
expect("ohne Level-Up nur das Level", recapLevel(), "10")

---------------------------------------------------------------------------
-- Begriffe: ein Wort je Sache in allen vier Sprachen
---------------------------------------------------------------------------
local locales = addon.locales
expectTrue("deDE ohne Umschalt", not locales.deDE.COMFORT_HINT:find("Umschalt"))
for key, text in pairs(locales.deDE) do
  expectTrue("deDE " .. key .. ": Shift statt Umschalt", not text:find("Umschalt"))
  expectTrue("deDE " .. key .. ": Knopf statt Button", not text:find("Button"))
  expectTrue("deDE " .. key .. ": „…“ statt \"…\"", not text:find('"'))
  expectTrue("deDE " .. key .. ": Erholt statt Erholungs-/Ruhe-XP", not text:find("Erholungs") and not text:find("Ruhe%-XP"))
end
for key, text in pairs(locales.enUS) do
  expectTrue("enUS " .. key .. ": gerade Anführungszeichen", not text:find("“") and not text:find("‘"))
end
expect("Reiter eindeutig", L.OPTIONS_TAB_NOTIFICATIONS ~= L.OPTIONS_TAB_ALERTS, true)
expect("Anzahl statt Gesamt", string.format(L.HISTORY_COUNT, 3), "3 Einträge")
