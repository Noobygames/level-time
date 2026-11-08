-- Level Time Goals, Fenster /sg: Schließen-Kreuz innen, Zielarten in Gruppen (jede verfügbare Art erreichbar),
-- einheitliche Feldbreiten, Hinweis mit Vorlagen ohne aktive Ziele, "Layout bearbeiten" in der Fußzeile.
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local L = streamGoal.L

local CONTENT_WIDTH = Manager.PAGE_WIDTH

wow.login({ level = 10 })
SlashCmdList.STREAMGOAL("")
expect("Fenster offen", StreamGoalWindow:IsShown(), true)

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
    local member = Goals.GroupOf(kind) == group.key and Goals.IsAvailable(kind)
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

---------------------------------------------------------------------------
-- Keine aktiven Ziele: Hinweis mit Weg zu den Vorlagen
---------------------------------------------------------------------------
Manager.SelectKind("level")
expect("keine Ziele", #Goals.Active(), 0)
local packs = Manager.packsButton
expectTrue("Vorlagen-Button ohne Ziele", packs:IsShown())
expect("Vorlagen-Button beschriftet", packs.label._text, L.SG_OPEN_PACKS)
packs._scripts.OnClick(packs)
expect("Vorlagen geöffnet", Manager.ShownPage(), "packs")
SlashCmdList.STREAMGOAL("add level 12")
expect("Vorlagen-Button mit Ziel weg", packs:IsShown(), false)

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
end
