-- Level Time Goals, Fenster /sg: Schließen-Kreuz innen, Reiter Ziele/Bingo/Glücksrad/Sammlung/Historie, Zielarten in
-- Gruppen (jede Art mit Formular erreichbar, Bingo hat einen eigenen Reiter), einheitliche Feldbreiten, Zusätze
-- zugeklappt, Hinweis mit Paketen ohne aktive Ziele, "Einstellungen" öffnet die Unterseite des Reiters, "Layout
-- bearbeiten" in der Fußzeile.
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local L = streamGoal.L

local CONTENT_WIDTH = Manager.PAGE_WIDTH

wow.login({ level = 10 })
SlashCmdList.STREAMGOAL("")
expect("Fenster offen", StreamGoalWindow:IsShown(), true)

---------------------------------------------------------------------------
-- Reiter: feste Reihenfolge, jeder mit Tooltip
---------------------------------------------------------------------------
local order = table.concat(Manager.PageKeys(), ",")
expect("Reihenfolge der Reiter", order, "goals,bingo,wheel,collection,history")
for _, tab in ipairs(Manager.PageTabs()) do
  expectTrue("Reiter " .. tostring(tab.label._text) .. " mit Tooltip", tab._scripts.OnEnter ~= nil)
end
expect("alter Name packs führt zur Sammlung", (function()
  Manager.Toggle("packs")
  return Manager.ShownPage()
end)(), "collection")
Manager.Toggle("goals")

---------------------------------------------------------------------------
-- Schließen-Kreuz: oben rechts innerhalb des Fensters
---------------------------------------------------------------------------
local close = Manager.closeButton._points[1]
expect("Kreuz oben rechts", close[1], "TOPRIGHT")
local closeX, closeY = close[#close - 1], close[#close]
expectTrue("Kreuz nicht rechts hinaus", closeX <= 0)
expectTrue("Kreuz nicht oben hinaus", closeY <= 0)

---------------------------------------------------------------------------
-- Gruppen: jede Art gehört zu genau einer Gruppe, jede verfügbare Art ist über ihre Gruppe erreichbar
---------------------------------------------------------------------------
local inGroup = {}
for _, group in ipairs(Goals.KIND_GROUPS) do
  for _, kind in ipairs(Goals.KindsOfGroup(group.key)) do
    expect("Art " .. kind .. " nur einmal", inGroup[kind], nil)
    inGroup[kind] = group.key
  end
end
local function inForm(kind)
  return Goals.IsAvailable(kind) and Goals.GetKind(kind).inForm ~= false
end
expect("Bingo hat keinen Formular-Reiter", inForm("bingo"), false)
for _, kind in ipairs(Goals.KindOrder()) do
  expectTrue("Art " .. kind .. " hat eine Gruppe", inGroup[kind] ~= nil)
  expectTrue("Art " .. kind .. " hat eine eigene Gruppe", Goals.GetKind(kind).group == inGroup[kind])
end

local function rightEdge(frame)
  local point = frame._points[1]
  return point[#point - 1] + frame:GetWidth()
end

for _, group in ipairs(Goals.KIND_GROUPS) do
  local groupTab = Manager.GroupTab(group.key)
  expectTrue("Gruppe " .. group.key .. " sichtbar", groupTab:IsShown())
  expect("Gruppe " .. group.key .. " beschriftet", groupTab.label._text, L[group.label])
  expectTrue("Gruppe " .. group.key .. " in der Breite", rightEdge(groupTab) <= CONTENT_WIDTH)
  groupTab._scripts.OnClick(groupTab)
  expect("Gruppe " .. group.key .. " gewählt", Manager.SelectedGroup(), group.key)
  for _, kind in ipairs(Goals.KindOrder()) do
    local tab = Manager.KindTab(kind)
    local member = Goals.GroupOf(kind) == group.key and inForm(kind)
    expect(group.key .. ": Reiter " .. kind, tab:IsShown(), member)
    if member then
      expectTrue(group.key .. ": " .. kind .. " in der Breite", rightEdge(tab) <= CONTENT_WIDTH)
      tab._scripts.OnClick(tab)
      expect("Art " .. kind .. " gewählt", Manager.SelectedKind(), kind)
    end
  end
end

-- Zurück zu einer Gruppe: die dort zuletzt gewählte Art ist wieder da
Manager.SelectKind("gold")
Manager.SelectGroup("progress")
Manager.SelectGroup("loot")
expect("zuletzt gewählte Art der Gruppe", Manager.SelectedKind(), "gold")

---------------------------------------------------------------------------
-- Feldbreiten: Zahlen einheitlich schmal, Texte bis zum rechten Rand, alle Felder in einer Spalte
---------------------------------------------------------------------------
local function leftOf(widget)
  local point = widget._points[1]
  return point[#point - 1]
end

Manager.SelectKind("custom")
expect("Zusätze zugeklappt", Manager.ExtrasShown(), false)
expect("Knopf Weitere Optionen", Manager.extrasButton.label._text, L.SG_FORM_MORE)
Manager.extrasButton._scripts.OnClick(Manager.extrasButton, "LeftButton")
expect("Zusätze aufgeklappt", Manager.ExtrasShown(), true)
expect("Knopf Weniger Optionen", Manager.extrasButton.label._text, L.SG_FORM_LESS)
local amount, text = Manager.FormWidget("amount"), Manager.FormWidget("text")
local deadline, points = Manager.FormWidget("deadline"), Manager.FormWidget("points")
local reward = Manager.FormWidget("reward")
expect("Zahl und Frist gleich breit", deadline:GetWidth(), amount:GetWidth())
expect("Punkte so breit wie Zahlen", points:GetWidth(), amount:GetWidth())
expect("Text bis zum Rand", rightEdge(text), CONTENT_WIDTH)
expect("Belohnung bis zum Rand", rightEdge(reward), CONTENT_WIDTH)
expect("Felder in einer Spalte", leftOf(text), leftOf(amount))
expect("Zusätze in derselben Spalte", leftOf(reward), leftOf(amount))
Manager.SelectKind("checklist")
expect("Checkliste: Text bis zum Rand", rightEdge(Manager.FormWidget("text")), CONTENT_WIDTH)
Manager.ToggleExtras(false)
expect("wieder zugeklappt", Manager.ExtrasShown(), false)
Manager.FormWidget("deadline"):SetText("2h")
Manager.Refresh()
expect("Eingabe in Zusätzen klappt auf", Manager.ExtrasShown(), true)
Manager.FormWidget("deadline"):SetText("")
Manager.ToggleExtras(false)

---------------------------------------------------------------------------
-- Keine aktiven Ziele: Hinweis mit Weg zu den Paketen der Sammlung
---------------------------------------------------------------------------
Manager.SelectKind("level")
expect("keine Ziele", #Goals.Active(), 0)
local packs = Manager.packsButton
expectTrue("Pakete-Button ohne Ziele", packs:IsShown())
expect("Pakete-Button beschriftet", packs.label._text, L.SG_OPEN_PACKS)
streamGoal.CollectionView.SelectSection("own")
packs._scripts.OnClick(packs)
expect("Sammlung geöffnet", Manager.ShownPage(), "collection")
expect("bei den Paketen", streamGoal.CollectionView.Section(), "packs")
SlashCmdList.STREAMGOAL("add level 12")
Manager.Toggle("goals")
expect("Pakete-Button mit Ziel weg", packs:IsShown(), false)
expect("Überschrift zählt Plätze", Manager.activeHeader.label._text,
  string.format(L.SG_ACTIVE_TITLE, 1, Goals.MAX_ACTIVE))

---------------------------------------------------------------------------
-- "Einstellungen" öffnet die Unterseite, die zum Reiter gehört
---------------------------------------------------------------------------
local SETTINGS = streamGoal.SETTINGS_PAGES
for page, expected in pairs({ goals = SETTINGS.TRACKER, bingo = SETTINGS.BINGO, wheel = SETTINGS.WHEEL,
  history = SETTINGS.DATA }) do
  Manager.Toggle(page)
  Manager.settingsButton._scripts.OnClick(Manager.settingsButton, "LeftButton")
  expect("Einstellungen von " .. page, select(2, streamGoal.Options.builder.CurrentPage()), expected)
  StreamGoalOptions:Hide()
end
Manager.Toggle("goals")

---------------------------------------------------------------------------
-- Fußzeile: "Layout bearbeiten" startet den Edit-Modus von Level Time und schließt das Fenster
---------------------------------------------------------------------------
local edit = Manager.editButton
expect("Button heißt wie in Level Time", edit.label._text, addon.L.EDIT_MODE)
edit._scripts.OnClick(edit)
expect("Edit-Modus an", addon.EditMode.IsActive(), true)
expect("Fenster zu", StreamGoalWindow:IsShown(), false)
addon.EditMode.Leave()

---------------------------------------------------------------------------
-- Lange Sprachen: Gruppen und Arten bleiben in der Breite
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("")
for _, language in ipairs({ "frFR", "esES", "enUS", "deDE" }) do
  addon.Set("language", language)
  for _, group in ipairs(Goals.KIND_GROUPS) do
    Manager.SelectGroup(group.key)
    expect(language .. ": Gruppe " .. group.key, Manager.GroupTab(group.key).label._text, addon.L[group.label])
    local groupTab = Manager.GroupTab(group.key)
    expectTrue(language .. ": Gruppe " .. group.key .. " in der Breite", rightEdge(groupTab) <= CONTENT_WIDTH)
    for _, kind in ipairs(Goals.KindsOfGroup(group.key)) do
      local tab = Manager.KindTab(kind)
      if tab:IsShown() then
        expectTrue(language .. ": " .. kind .. " in der Breite", rightEdge(tab) <= CONTENT_WIDTH)
      end
    end
  end
  -- Reiter der Seiten (Ziele, Bingo, Glücksrad, Sammlung, Historie) nebeneinander im Fenster
  local used = 0
  for index, tab in ipairs(Manager.PageTabs()) do
    used = used + tab:GetWidth() + (index > 1 and 14 or 0)
  end
  expectTrue(language .. ": Seiten-Reiter in der Breite", used <= CONTENT_WIDTH)
end
