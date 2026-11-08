-- UX-Review: Hinweise unter Tabellen brechen um (W15), Leer- und Kein-Treffer-Text (W11), Rückfrage vor dem
-- Zurücksetzen aller Anzeigen (W33/S26), bereichsunabhängige Zeilen ohne Instanz-Lauf (W19) und Rechtsklick auf
-- den Instanz-Reiter (W27).
local L = addon.L
local Stats = addon.Stats
wow.login({ level = 10, xp = 0, xpMax = 1000 })

---------------------------------------------------------------------------
-- W15: Hinweis in der Breite der Tabelle, lange Hinweise in mehreren Zeilen, Summenzeile darüber
---------------------------------------------------------------------------
local WIDTH, HINT_LINE_HEIGHT, MAX_HINT_LINES = addon.HistoryWindow.CONTENT_WIDTH, 12, 3
local HINT_KEYS = { "LEVELS_PARTIAL_HINT", "PERSONAL_RECORDS_HINT", "MONEY_HINT", "RUNS_HINT", "QUEST_SPLITS_HINT",
  "TURN_IN_HINT", "QUEST_EFFICIENCY_HINT", "TABLE_SORT_HINT" }

-- Summenzeile einer Tabelle (Zeile mit Zellen, unten verankert)
local function footerOf(view)
  return wow.findFrame(function(frame)
    local points = frame._points
    return rawget(frame, "_parent") == view and rawget(frame, "cells") ~= nil and points[1] ~= nil
      and points[1][1] == "BOTTOMLEFT"
  end)
end

for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  addon.Set("language", language)
  for _, key in ipairs(HINT_KEYS) do
    local view = addon.TableView.Create({
      tab = "HISTORY_TAB_LEVELS",
      columns = { { header = "HISTORY_LEVEL", width = 60, value = function(r) return r.level end } },
      records = function() return { { level = 1 } } end,
      footer = function() return {} end,
      hint = key,
    }).Create(CreateFrame("Frame"), WIDTH, addon.HistoryWindow.CONTENT_HEIGHT)
    view:Render("x", true)
    local footer = footerOf(view)
    local lines, hint = view:HintLines()
    local points = hint._points
    local needed = math.ceil(#L[key] * 6 / (WIDTH - 6))
    expectTrue(language .. " " .. key .. ": Hinweis links und rechts verankert",
      points[1][1] == "BOTTOMLEFT" and points[2][1] == "BOTTOMRIGHT")
    expect(language .. " " .. key .. ": Zeilen", lines, math.max(1, needed))
    expectTrue(language .. " " .. key .. ": höchstens " .. MAX_HINT_LINES .. " Zeilen", needed <= MAX_HINT_LINES)
    expect(language .. " " .. key .. ": Summenzeile über dem Hinweis", footer._points[1][3], lines * HINT_LINE_HEIGHT)
  end
end
addon.Set("language", "deDE")

-- In der Historie: Quests > Abgabe hat einen zweizeiligen Hinweis (englisch)
addon.Set("language", "enUS")
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Quests", wow.click(addon.L.HISTORY_GROUP_ANALYSIS))
expectTrue("Unterreiter Abgabe", wow.click(addon.L.HISTORY_TAB_TURN_IN))
local turnIn = wow.shownTable()
expect("Abgabe: Hinweis in zwei Zeilen", turnIn:HintLines(), 2)

---------------------------------------------------------------------------
-- W11: Abgabe ohne Quests bzw. für andere Charaktere, Filter ohne Treffer
---------------------------------------------------------------------------
expect("eigener Charakter ohne abgabebereite Quest", turnIn:EmptyText(), addon.L.TURN_IN_EMPTY)
turnIn:Render("Anderer-Realm", true)
expect("anderer Charakter: nur eingeloggt", turnIn:EmptyText(), addon.L.TURN_IN_OTHER_CHARACTER)

addon.Set("language", "deDE")
local levels = addon.TableView.Create({
  tab = "HISTORY_TAB_LEVELS",
  columns = { { header = "HISTORY_LEVEL", width = 60, value = function(r) return r.name end } },
  records = function() return { { name = "Wolf" }, { name = "Bär" } } end,
  footer = function() return {} end,
}).Create(CreateFrame("Frame"), WIDTH, 200)
levels:Render("x", true)
expect("mit Einträgen kein Leer-Text", levels:EmptyText(), nil)
levels:SetFilter("Hogger")
expect("Filter ohne Treffer", levels:EmptyText(), string.format(L.TABLE_NO_MATCH, "Hogger"))
levels:SetFilter("wolf")
expect("Filter mit Treffer", levels:EmptyText(), nil)
local empty = addon.TableView.Create({
  tab = "HISTORY_TAB_LEVELS",
  columns = { { header = "HISTORY_LEVEL", width = 60, value = function(r) return r.name end } },
  records = function() return {} end,
  footer = function() return {} end,
}).Create(CreateFrame("Frame"), WIDTH, 200)
empty:Render("x", true)
expect("ohne Einträge: Standardtext", empty:EmptyText(), L.TABLE_EMPTY)
SlashCmdList.LEVELTIMER("history")  -- schließen

---------------------------------------------------------------------------
-- W33/S26: "Alle zurücksetzen" und /lt reset fragen erst nach
---------------------------------------------------------------------------
addon.Frames.SetScale("main", 1.5)
wow.popup = nil
SlashCmdList.LEVELTIMER("reset")
expectTrue("/lt reset fragt nach", wow.popup ~= nil)
expectNear("ohne Bestätigung unverändert", addon.Frames.GetScale("main"), 1.5)
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expectNear("nach Bestätigung zurückgesetzt", addon.Frames.GetScale("main"), 1)
expectTrue("Reset gemeldet", wow.printed[#wow.printed]:find(L.RESET_DONE, 1, true) ~= nil)

addon.Frames.SetScale("main", 1.5)
addon.EditMode.Enter()
wow.popup = nil
expectTrue("Knopf Alle zurücksetzen", wow.click(L.EDIT_MODE_RESET_ALL))
expectTrue("Knopf fragt nach", wow.popup ~= nil)
expectNear("Knopf ohne Bestätigung unverändert", addon.Frames.GetScale("main"), 1.5)
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expectNear("Knopf nach Bestätigung zurückgesetzt", addon.Frames.GetScale("main"), 1)
addon.EditMode.Leave()

---------------------------------------------------------------------------
-- W19: Reiter Instanz ohne Lauf: bereichsunabhängige Zeilen zeigen Werte, Zähler "-"
---------------------------------------------------------------------------
addon.Set("showInstanceLimit", true)
addon.Set("showPveKills", true)
addon.Set("windowScope", Stats.INSTANCE)
expect("kein Lauf offen", Stats.IsOpen(Stats.INSTANCE), false)
local model = addon.WindowModel.New():Build(addon.db, addon.WindowModel.VISIBLE)
local function modelValue(label)
  for _, row in ipairs(model.rows) do
    if row.key == label then return row.value end
  end
end
local limit = modelValue("ROW_INSTANCE_LIMIT")
expectTrue("Instanzlimit ohne Lauf sichtbar", limit ~= nil and limit ~= addon.Format.NO_VALUE)
expect("Kills ohne Lauf: -", modelValue("ROW_PVE_KILLS"), addon.Format.NO_VALUE)
addon.Set("windowScope", Stats.LEVEL)

---------------------------------------------------------------------------
-- W27: Rechtsklick auf den Instanz-Reiter öffnet die Einstellungen, Shift+Rechtsklick fragt nach dem Zurücksetzen
---------------------------------------------------------------------------
local instanceTab = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == L.TAB_INSTANCE and frame._scripts.OnClick ~= nil
end)
expectTrue("Instanz-Reiter", instanceTab ~= nil)
wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
wow.popup = nil
expect("Einstellungen zu", LevelTimerOptions:IsShown(), false)
instanceTab._scripts.OnClick(instanceTab, "RightButton")
expect("Rechtsklick öffnet die Einstellungen", LevelTimerOptions:IsShown(), true)
expect("Rechtsklick setzt nichts zurück", wow.popup, nil)
SlashCmdList.LEVELTIMER("config")
wow.state.shiftDown = true
instanceTab._scripts.OnClick(instanceTab, "RightButton")
wow.state.shiftDown = false
expectTrue("Shift+Rechtsklick fragt nach dem Zurücksetzen", wow.popup ~= nil)
expect("Shift+Rechtsklick öffnet keine Einstellungen", LevelTimerOptions:IsShown(), false)
