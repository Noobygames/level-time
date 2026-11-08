-- Level Time Goals, Fenster /sg: Schließen-Kreuz innen, Reiter Ziele/Bingo/Glücksrad/Sammlung/Historie, Kacheln der
-- Zielarten (jede Art mit Formular erreichbar, Bingo hat einen eigenen Reiter), einheitliche Feldbreiten, Zusätze
-- zugeklappt, Hinweis mit Paketen ohne laufende Ziele, "Einstellungen" öffnet die Unterseite des Reiters, "Layout
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
-- Kacheln der Zielarten (UX G15): jede Art gehört zu genau einer Gruppe (Reihenfolge), jede verfügbare Art hat eine
-- Kachel mit Namen und Tooltip, ein Klick wählt sie; alle Kacheln in der Seitenbreite
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
expect("Bingo hat keine Kachel", inForm("bingo"), false)
for _, kind in ipairs(Goals.KindOrder()) do
  expectTrue("Art " .. kind .. " hat eine Gruppe", inGroup[kind] ~= nil)
  expectTrue("Art " .. kind .. " hat eine eigene Gruppe", Goals.GetKind(kind).group == inGroup[kind])
end

local function rightEdge(frame)
  local point = frame._points[1]
  return point[#point - 1] + frame:GetWidth()
end

for _, kind in ipairs(Goals.KindOrder()) do
  local tile = Manager.KindTile(kind)
  if inForm(kind) then
    expectTrue("Kachel " .. kind .. " sichtbar", tile:IsShown())
    expect("Kachel " .. kind .. " beschriftet", tile.label._text, L[Goals.GetKind(kind).label])
    expectTrue("Kachel " .. kind .. " mit Tooltip", tile._scripts.OnEnter ~= nil)
    expectTrue("Kachel " .. kind .. " in der Breite", rightEdge(tile) <= CONTENT_WIDTH)
    tile._scripts.OnClick(tile, "LeftButton")
    expect("Art " .. kind .. " gewählt", Manager.SelectedKind(), kind)
    expect("Kachel " .. kind .. " hervorgehoben", Manager.KindTile(kind).selected, true)
  else
    expectTrue("keine Kachel für " .. kind, tile == nil or not tile:IsShown())
  end
end
-- Reihenfolge der Kacheln folgt den Gruppen: Level oben links, Freitext gleich daneben
local first = Manager.KindTile("level")._points[1]
expect("Level oben links", first[#first - 1], 0)

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
-- Lange Sprachen: Kacheln bleiben in der Breite, ihr Name passt in die Kachel
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("")
for _, language in ipairs({ "frFR", "esES", "enUS", "deDE" }) do
  addon.Set("language", language)
  local picker = Manager.picker
  expectTrue(language .. ": Name passt in die Kachel", picker:NeededWidth() <= picker.tileWidth)
  for _, kind in ipairs(Goals.KindOrder()) do
    local tile = Manager.KindTile(kind)
    if tile and tile:IsShown() then
      expect(language .. ": Kachel " .. kind, tile.label._text, addon.L[Goals.GetKind(kind).label])
      expectTrue(language .. ": " .. kind .. " in der Breite", rightEdge(tile) <= CONTENT_WIDTH)
    end
  end
  -- Reiter der Seiten (Ziele, Bingo, Glücksrad, Sammlung, Historie) nebeneinander im Fenster
  local used = 0
  for index, tab in ipairs(Manager.PageTabs()) do
    used = used + tab:GetWidth() + (index > 1 and 14 or 0)
  end
  expectTrue(language .. ": Seiten-Reiter in der Breite", used <= CONTENT_WIDTH)
end
