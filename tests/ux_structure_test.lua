-- UX-Review Paket 4 (Struktur): Historie in sieben Hauptreitern (W13) mit alten historyTab-Werten, Charakter-Auswahl
-- aus bei Ansichten über alle Charaktere (W18), schlanke Übersicht mit Unterreiter "Kills & Items" (W21), Bereich in
-- den Layouts ohne Reiter (W7), Titel der Split-Liste mit dem Vergleich (W25) und die neuen Orte in den Einstellungen
-- (S11, S15, S16, S18, S20).
local L = addon.L
local Stats = addon.Stats
local HistoryWindow = addon.HistoryWindow
wow.login({ level = 12, xp = 0, xpMax = 1000 })

---------------------------------------------------------------------------
-- W13: Hauptreiter in fester Reihenfolge, jede Ansicht erreichbar
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("history")
local tabs = {}
for index, entry in ipairs(HistoryWindow.Entries()) do tabs[index] = entry.tab end
expect("Hauptreiter", table.concat(tabs, ","), table.concat(HistoryWindow.TAB_ORDER, ","))
expect("Reiterzeile in derselben Reihenfolge", HistoryWindow.MainTabs()[4], HistoryWindow.Entries()[4].tabButton)

local function groupOf(viewKey)
  for _, entry in ipairs(HistoryWindow.Entries()) do
    for _, view in ipairs(entry.members) do
      if view.tab == viewKey then return entry.tab end
    end
  end
end
for viewKey, group in pairs({
  HISTORY_TAB_LEVELS = "HISTORY_GROUP_LEVELS", HISTORY_TAB_LEVEL_KILLS = "HISTORY_GROUP_LEVELS",
  HISTORY_TAB_SESSIONS = "HISTORY_GROUP_SESSIONS", HISTORY_TAB_SESSION_KILLS = "HISTORY_GROUP_SESSIONS",
  HISTORY_TAB_KILLS = "HISTORY_GROUP_JOURNAL", HISTORY_TAB_INSTANCES = "HISTORY_GROUP_JOURNAL",
  HISTORY_TAB_ZONES = "HISTORY_GROUP_ANALYSIS", HISTORY_TAB_REPUTATION = "HISTORY_GROUP_ANALYSIS",
  HISTORY_TAB_MONEY = "HISTORY_GROUP_ANALYSIS", HISTORY_TAB_TURN_IN = "HISTORY_GROUP_ANALYSIS",
  HISTORY_TAB_QUEST_EFFICIENCY = "HISTORY_GROUP_ANALYSIS", HISTORY_TAB_RUNS = "HISTORY_GROUP_SPEEDRUN",
  HISTORY_TAB_RECORDS = "HISTORY_GROUP_SPEEDRUN", HISTORY_TAB_PERSONAL_RECORDS = "HISTORY_GROUP_SPEEDRUN",
  HISTORY_TAB_WORLD_RECORDS = "HISTORY_GROUP_SPEEDRUN", HISTORY_TAB_QUEST_SPLITS = "HISTORY_GROUP_SPEEDRUN",
  HISTORY_TAB_COMPARE = "HISTORY_TAB_COMPARE", CHART_PROGRESS = "HISTORY_TAB_CHARTS",
}) do
  expect("Ansicht " .. viewKey, groupOf(viewKey), group)
end
for _, entry in ipairs(HistoryWindow.Entries()) do
  for _, view in ipairs(entry.members) do
    expectTrue("zeigbar: " .. view.tab, HistoryWindow.ShowView(view.tab))
    expect("gemerkt: " .. view.tab, LevelTimerDB.historyTab, view.tab)
  end
end
expect("unbekannte Ansicht", HistoryWindow.ShowView("GIBT_ES_NICHT"), false)

-- Gespeicherte Werte von vorher (Ansicht-Keys blieben gleich) öffnen ihre Ansicht im neuen Reiter
local function reopenWith(historyTab)
  LevelTimerDB.historyTab = historyTab
  if LevelTimerHistory:IsShown() then SlashCmdList.LEVELTIMER("history") end
  SlashCmdList.LEVELTIMER("history")
  return wow.shownTable()
end
reopenWith("HISTORY_TAB_PERSONAL_RECORDS")
expect("Persönliche Rekorde unter Speedrun & Rekorde", HistoryWindow.Entries()[6].selected.tab,
  "HISTORY_TAB_PERSONAL_RECORDS")
expectTrue("Reiter aktiv", HistoryWindow.Entries()[6].tabButton.label._text == L.HISTORY_GROUP_SPEEDRUN)
reopenWith("HISTORY_TAB_ZONES")
expect("Zonen unter Auswertung", HistoryWindow.Entries()[4].selected.tab, "HISTORY_TAB_ZONES")
reopenWith("HISTORY_TAB_KAPUTT")
expectTrue("unbekannter Wert: erster Reiter", wow.shownTable() ~= nil)

---------------------------------------------------------------------------
-- W21: Übersicht nur mit Kernwerten, Raten und PvP im Unterreiter
---------------------------------------------------------------------------
local function header(viewKey)
  HistoryWindow.ShowView(viewKey)
  return wow.shownTable():BuildCsv():match("^[^\n]*")
end
for _, viewKey in ipairs({ "HISTORY_TAB_LEVELS", "HISTORY_TAB_SESSIONS" }) do
  local text = header(viewKey)
  expectTrue(viewKey .. ": XP/h", text:find(L.HISTORY_XP_RATE, 1, true) ~= nil)
  expect(viewKey .. ": ohne Kills/h", text:find(L.HISTORY_KILL_RATE, 1, true), nil)
  expect(viewKey .. ": ohne PvP", text:find(L.HISTORY_PVP, 1, true), nil)
end
for _, viewKey in ipairs({ "HISTORY_TAB_LEVEL_KILLS", "HISTORY_TAB_SESSION_KILLS" }) do
  local text = header(viewKey)
  for _, column in ipairs({ "HISTORY_KILL_RATE", "HISTORY_ITEM_RATE", "HISTORY_PVP", "HISTORY_ITEMS_LOOTED" }) do
    expectTrue(viewKey .. ": " .. column, text:find(L[column], 1, true) ~= nil)
  end
end

---------------------------------------------------------------------------
-- W18: Ansichten über alle Charaktere schalten die Auswahl aus
---------------------------------------------------------------------------
local function findText(text)
  return wow.findFrame(function(frame) return rawget(frame, "_text") == text end)
end
local function findButton(text)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == text and rawget(frame, "_scripts") and frame._scripts.OnClick ~= nil
  end)
end
local deleteButton = findButton(L.DELETE_CHARACTER)
local characterLine = string.format(L.HISTORY_CHARACTER, addon.History.DisplayName(addon.characterKey), 12)
for _, viewKey in ipairs({ "HISTORY_TAB_COMPARE", "HISTORY_TAB_PERSONAL_RECORDS", "HISTORY_TAB_RUNS",
  "HISTORY_TAB_RECORDS", "HISTORY_TAB_WORLD_RECORDS", "HISTORY_TAB_QUEST_EFFICIENCY" }) do
  HistoryWindow.ShowView(viewKey)
  expectTrue(viewKey .. ": alle Charaktere", HistoryWindow.IsAllCharacters())
  expectTrue(viewKey .. ": Name ersetzt", findText(L.HISTORY_ALL_CHARACTERS) ~= nil)
  expect(viewKey .. ": Löschen aus", deleteButton:IsEnabled(), false)
end
local previous = findButton("<")
expect("Pfeil aus", previous:IsEnabled(), false)
HistoryWindow.ShowView("HISTORY_TAB_LEVELS")
expect("eigene Ansicht: Auswahl an", HistoryWindow.IsAllCharacters(), false)
expectTrue("Name wieder da", findText(characterLine) ~= nil)
expect("Löschen wieder an", deleteButton:IsEnabled(), true)
expect("Pfeil wieder an", previous:IsEnabled(), true)
wow.update(1.1)  -- Takt bleibt bei der Auswahl
expect("Takt: Löschen an", deleteButton:IsEnabled(), true)
SlashCmdList.LEVELTIMER("history")

---------------------------------------------------------------------------
-- W7: Kompakt, Text und Uhr zeigen den Bereich
---------------------------------------------------------------------------
local elements = addon.TimerWindow.Elements()
local function showLayout(id, scope)
  addon.Set("windowLayout", id)
  addon.Set("windowScope", scope or Stats.LEVEL)
  wow.update(1)
end
local levelText = string.format(L.TAB_LEVEL, 12)
showLayout("compact")
expect("kompakt: Bereich sichtbar", elements.sub:IsShown(), true)
expect("kompakt: Level", elements.sub._text, levelText)
showLayout("compact", Stats.SESSION)
expect("kompakt: Session", elements.sub._text, L.TAB_SESSION)
addon.Set("textLabels", true)
showLayout("text")
expect("Text: Bereich mit Bezeichnungen", elements.sub._text, levelText)
addon.Set("textLabels", false)
wow.update(1)
expect("Text ohne Bezeichnungen: nur die Zahl", elements.sub:IsShown(), false)
addon.Set("textLabels", true)
addon.Set("compactRows", "ROW_XP_RATE")
showLayout("clock")
expect("Uhr: Bereich vorn", elements.sub._text:sub(1, #levelText), levelText)
expectTrue("Uhr: Werte dahinter", #elements.sub._text > #levelText)
showLayout("table")
expect("Tabelle: Reiter statt Bereichszeile", elements.sub:IsShown(), false)

---------------------------------------------------------------------------
-- W25: Split-Liste nennt den Vergleich
---------------------------------------------------------------------------
local SplitList = addon.SplitList
addon.Set("splitComparison", addon.Splits.BEST)
expect("gegen Bestzeit", SplitList.TitleText(), string.format(L.SPLIT_LIST_TITLE_VS, L.SPLIT_LIST_TITLE, L.SPLIT_VS_BEST))
addon.Set("splitComparison", addon.Splits.PERSONAL_BEST)
expect("gegen PB", SplitList.TitleText(), string.format(L.SPLIT_LIST_TITLE_VS, L.SPLIT_LIST_TITLE, L.SPLIT_VS_PB))
addon.Set("splitReference", { id = "Fremd-Realm", name = "Schnellerläufer", times = { [1] = 60 } })
addon.Set("splitComparison", addon.Splits.RUN)
expect("gegen gewählten Lauf", SplitList.TitleText(),
  string.format(L.SPLIT_LIST_TITLE_VS, L.SPLIT_LIST_TITLE, "Schnellerläufer"))
addon.Set("showSplitList", true)
wow.update(1)
expect("Titel in der Liste", wow.findFrame(function(frame)
  return rawget(frame, "_text") == SplitList.TitleText()
end) ~= nil, true)

---------------------------------------------------------------------------
-- S11/S18: Level-Up-Seite und Stream-Abkürzungen
---------------------------------------------------------------------------
local options = addon.OptionsWindow
addon.Set("optionsAdvanced", true)
SlashCmdList.LEVELTIMER("config")
local function entryOf(labelKey)
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if not entry.isPage and entry.tipKey == labelKey .. "_TIP" then return entry end
  end
end
options.ShowPage("OPTIONS_PAGE_LEVEL_UP")
local banner = entryOf("ALERT_TOGGLE_LEVEL_UP")
addon.Set("levelUpWindow", true)
options.Refresh(addon.db)
expect("Einblendung ausgegraut mit Level-Up-Fenster", banner.left:GetAlpha() < 1, true)
addon.Set("levelUpWindow", false)
options.Refresh(addon.db)
expect("Einblendung ohne Fenster an", banner.left:GetAlpha(), 1)

options.ShowPage("OPTIONS_TAB_STREAM")
local streamLayout = entryOf("STREAM_LAYOUT")
expect("Stream: Layout-Abkürzung", streamLayout and streamLayout.sub.key, "OPTIONS_TAB_STREAM")
expectTrue("sichtbar", streamLayout.left:IsVisible())
local outlinePages = {}
for _, entry in ipairs(options.Search(L.THEME_OUTLINE)) do
  if entry.tipKey == "THEME_OUTLINE_TIP" then outlinePages[entry.sub.key] = true end
end
expectTrue("Kontur unter Aussehen", outlinePages.OPTIONS_PAGE_LOOK)
expectTrue("Kontur auch unter Stream", outlinePages.OPTIONS_TAB_STREAM)
LevelTimerOptions:Hide()
expect("keine Fehler", #wow.errors, 0)
