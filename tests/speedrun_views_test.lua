-- Historie "Speedrun": Läufe mit Favoriten, Klick wählt den Vergleich.
local L = addon.L

local function otherCharacter(name, class, levels, realm)
  realm = realm or "Testrealm"
  LevelTimerStatsDB.characters[name .. "-" .. realm] = {
    name = name, realm = realm, class = class, currentLevel = { level = 30, counters = {} },
    levelHistory = levels, sessionHistory = {}, killLog = {}, deathLog = {},
  }
end

wow.login({ name = "Neu", level = 12, playedSeconds = 0 })
addon.character.levelHistory[10] = { level = 10, seconds = 3000, counters = {} }
addon.character.levelHistory[11] = { level = 11, seconds = 2000, counters = {} }
otherCharacter("Rekord", "MAGE", { [10] = { level = 10, seconds = 2500 }, [11] = { level = 11, seconds = 2500 } })
otherCharacter("Lahm", "ROGUE", { [10] = { level = 10, seconds = 9000 } })

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Speedrun", wow.click(L.HISTORY_GROUP_SPEEDRUN))
local view = wow.shownTable()
local runs = view:GetVisibleRecords()
expect("alle Läufe", #runs, 3)
expect("eingeloggter zuerst", runs[1].id, "Neu-Testrealm")

local function runByName(name)
  for _, run in ipairs(view:GetVisibleRecords()) do
    if run.name == name then return run end
  end
end
expect("Zeit bis zum aktuellen Level", runByName("Rekord").timeToLevel, 5000)
expect("Lauf ohne alle Level: keine Zeit", runByName("Lahm").timeToLevel, nil)

-- Zeile per Name finden (Zelle 2 = Name) und anklicken
local function clickRow(name, mouseButton)
  local row = wow.findFrame(function(frame)
    local cells = rawget(frame, "cells")
    return cells and cells[2]._text:find(name, 1, true) == 1 and frame._scripts.OnMouseUp ~= nil and frame:IsShown()
  end)
  row._scripts.OnMouseUp(row, mouseButton)
end

clickRow("Rekord", "LeftButton")
expect("Klick wählt Vergleich", LevelTimerDB.splitReference.id, "Rekord-Testrealm")
expect("Vergleich als Lauf", LevelTimerDB.splitComparison, "run")

clickRow("Lahm", "RightButton")
expect("Favorit oben", view:GetVisibleRecords()[1].name, "Lahm")
clickRow("Lahm", "RightButton")
expect("Favorit wieder weg", view:GetVisibleRecords()[1].name, "Neu")

-- Eigener Lauf ist kein Vergleich
clickRow("Neu", "LeftButton")
expect("eigener Lauf nicht wählbar", LevelTimerDB.splitReference.id, "Rekord-Testrealm")

-- Suche nach Klasse
view:SetFilter("rogue")
local filtered = view:GetVisibleRecords()
expect("Filter nach Klasse", #filtered == 1 and filtered[1].name, "Lahm")

-- Markierungsspalte zeigt den gewählten Vergleich (statt einer meist leeren Status-Spalte)
view:SetFilter("")
local function cellsOf(name)
  local row = wow.findFrame(function(frame)
    local cells = rawget(frame, "cells")
    return cells and cells[2]._text == name and frame:IsShown()
  end)
  return row and row.cells
end
expect("Vergleich markiert", cellsOf("Rekord")[1]._text, ">")
expect("anderer Lauf ohne Markierung", cellsOf("Lahm")[1]._text, "")

-- Namen ohne Realm, voller Name im Tooltip der Zeile
expectTrue("Name ohne Realm", cellsOf("Neu") ~= nil)
local neuRow = wow.findFrame(function(frame)
  local cells = rawget(frame, "cells")
  return cells and cells[2]._text == "Neu" and frame:IsShown()
end)
local tooltipLines = {}
local originalSetText, originalAddLine = GameTooltip.SetText, GameTooltip.AddLine
GameTooltip.SetText = function(_, text) table.insert(tooltipLines, text) end
GameTooltip.AddLine = function(_, text) table.insert(tooltipLines, text) end
neuRow._scripts.OnEnter(neuRow)
GameTooltip.SetText, GameTooltip.AddLine = originalSetText, originalAddLine
expect("Tooltip mit Realm", tooltipLines[1], "Neu - Testrealm")

-- Keine Zeit bis zum aktuellen Level: gedämpfter Gedankenstrich
expect("fehlende Zeit gedämpft", cellsOf("Lahm")[6]._text, addon.Theme.Hex("muted") .. "–|r")

-- Spaltenköpfe sind eindeutig und erklären sich im Tooltip
for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  addon.Set("language", language)
  local texts = {}
  for _, key in ipairs({ "HISTORY_LEVELS_RECORDED", "HISTORY_COVERAGE", "HISTORY_TIME_TO_CURRENT", "HISTORY_RUN_CHECK",
      "HISTORY_LEVEL", "HISTORY_CHARACTER_NAME", "HISTORY_CLASS", "HISTORY_RUN_CATEGORY" }) do
    local text = addon.L[key]
    expectTrue(language .. ": Kopf " .. key .. " eindeutig", texts[text] == nil)
    texts[text] = true
  end
  for _, key in ipairs({ "HISTORY_FAVORITE_TIP", "HISTORY_LEVELS_RECORDED_TIP", "HISTORY_COVERAGE_TIP",
      "HISTORY_TIME_TO_CURRENT_TIP", "HISTORY_RUN_CHECK_TIP" }) do
    expectTrue(language .. ": " .. key, addon.L[key] ~= key and addon.L[key] ~= "")
  end
end
addon.Set("language", "deDE")

-- Gleiche Namen auf verschiedenen Realms: unterscheidender Teil des Realms dahinter
otherCharacter("Zwilling", "SHAMAN", { [10] = { level = 10, seconds = 3100 } }, "CAMWOW EU4 Realm 3 PvE")
otherCharacter("Zwilling", "PALADIN", { [10] = { level = 10, seconds = 3200 } }, "CAMWOW EU4 Realm 2 PvE")
otherCharacter("Lahm", "WARRIOR", { [10] = { level = 10, seconds = 9100 } }, "Anderswo")
addon.Runs.Invalidate()
view:Render(addon.characterKey, false, true)
expectTrue("Zwilling Realm 3", cellsOf("Zwilling (Realm 3 PvE)") ~= nil)
expectTrue("Zwilling Realm 2", cellsOf("Zwilling (Realm 2 PvE)") ~= nil)
expectTrue("Lahm Testrealm", cellsOf("Lahm (Testrealm)") ~= nil)
expectTrue("Lahm Anderswo", cellsOf("Lahm (Anderswo)") ~= nil)
expectTrue("eindeutiger Name bleibt kurz", cellsOf("Rekord") ~= nil)

-- Rekorde: schnellste Zeit je Level, eigene Zeit und Abweichung
expectTrue("Unterreiter Rekorde", wow.click(L.HISTORY_TAB_RECORDS))
local records = wow.shownTable():GetVisibleRecords()
expect("ein Rekord je Level", #records, 2)
expect("höchstes Level zuerst", records[1].level, 11)
expect("Rekord Level 11", records[1].seconds, 2000)
expect("hält der eingeloggte", records[1].run.name, "Neu")
expect("Rekord Level 10", records[2].seconds, 2500)
expect("hält Rekord", records[2].run.name, "Rekord")
expect("eigene Zeit", records[2].ownSeconds, 3000)

-- Noch kein eigenes Level abgeschlossen: keine Zeit bis zum aktuellen Level statt "0s"
expect("leere Spanne", addon.Runs.SumOfLevels({ [10] = 100 }, 12, 11), nil)

-- Summenzeile "Anzahl" steht in einer breiten Spalte, nicht in der schmalen Favoriten-Spalte
local cells = addon.HistoryTables.CountCells({ { width = 18 }, { width = 140 } }, { 1, 2, 3 })
expect("Favoriten-Spalte leer", cells[1], "")
expect("Anzahl in der Namensspalte", cells[2], string.format(L.HISTORY_COUNT, 3))
