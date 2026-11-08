-- Level Time Goals, UX-Review Paket 4 (Struktur): Kacheln statt zweier Reiterzeilen (G15), laufende Ziele im Fenster
-- bearbeiten samt Teilzielen einer Checkliste (G17), Ziel jeder Art direkt fürs Bingo-Feld (G4), Einstellungen mit
-- Hauptreitern statt eines einzigen Reiters samt Seitenleiste (G19).
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local BingoEditor = streamGoal.BingoEditor
local Pool = streamGoal.Pool
local Deadlines = streamGoal.Deadlines
local L = streamGoal.L

local WIDTH = Manager.PAGE_WIDTH

local function click(button)
  button._scripts.OnClick(button, "LeftButton")
end

local function pointOf(frame)
  local point = frame._points[1]
  return point[#point - 1], point[#point]
end

wow.login({ level = 10 })
SlashCmdList.STREAMGOAL("")

---------------------------------------------------------------------------
-- G15: Kacheln in jeder Sprache ohne Überlappung, Name passt hinein; Seite passt auch im ungünstigsten Fall
---------------------------------------------------------------------------
local TILE_HEIGHT = 20
for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  addon.Set("language", language)
  Manager.Toggle("goals")
  local picker = Manager.picker
  local placed = {}
  for _, kind in ipairs(Goals.KindOrder()) do
    local tile = Manager.KindTile(kind)
    if tile and tile:IsShown() then
      local x, y = pointOf(tile)
      expectTrue(language .. ": " .. kind .. " links in der Seite", x >= 0)
      expectTrue(language .. ": " .. kind .. " rechts in der Seite", x + tile:GetWidth() <= WIDTH)
      for other, rect in pairs(placed) do
        local apart = x >= rect.x + rect.w or rect.x >= x + tile:GetWidth() or y ~= rect.y
        expectTrue(language .. ": " .. kind .. " überlappt " .. other .. " nicht", apart)
      end
      placed[kind] = { x = x, y = y, w = tile:GetWidth() }
    end
  end
  expectTrue(language .. ": Name samt Symbol passt", picker:Fits())
  expectTrue(language .. ": mehrere Spalten", picker.columns >= 3)
  expectTrue(language .. ": Kachel hoch genug", Manager.KindTile("level"):GetHeight() >= TILE_HEIGHT)
  -- Ungünstigster Fall: längstes Formular, Zusätze offen, alle Plätze belegt -> letzte Zeile noch in der Seite
  for _, kind in ipairs({ "reputation", "kills", "item", "custom" }) do
    Manager.SelectKind(kind)
    Manager.ToggleExtras(true)
    expectTrue(language .. ": " .. kind .. " mit Zusätzen passt in die Seite",
      Manager.ActiveBottom() >= -Manager.PAGE_HEIGHT)
    Manager.ToggleExtras(false)
  end
end
addon.Set("language", "deDE")
L = streamGoal.L

---------------------------------------------------------------------------
-- G17: Bearbeiten eines laufenden Freitexts (Tippfehler, Zähler nachträglich, Zusätze)
---------------------------------------------------------------------------
Manager.Toggle("goals")
SlashCmdList.STREAMGOAL("add custom Ragnaros lgen")
local text = Goals.Active()[1]
Manager.RenderActive()
local row = Manager.ActiveRow(text.id)
expectTrue("Zeile hat Bearbeiten", row ~= nil and row.edit:IsShown())
expect("Bearbeiten beschriftet", row.edit.label._text, L.SG_EDIT)
expectTrue("Text der Zeile neben den Knöpfen",
  row.text:GetWidth() + row.edit:GetWidth() + row.cancel:GetWidth() + row.plus:GetWidth() <= WIDTH)
click(row.edit)
expect("bearbeitet", Manager.EditingGoal(), text)
expect("Überschrift nennt das Ziel", Manager.formHeader.label._text,
  string.format(L.SG_EDIT_TITLE, text.id, "Ragnaros lgen"))
expect("Kacheln ausgeblendet", Manager.KindTile("level"):IsShown(), false)
expect("Hinweis statt Kacheln", Manager.editHint:IsShown(), true)
expect("Zusätze offen", Manager.ExtrasForm().frame:IsShown(), true)
expect("Speichern sichtbar", Manager.saveEditButton:IsShown(), true)
expect("Hinzufügen versteckt", Manager.addButton:IsShown(), false)
expect("Text vorbelegt", Manager.FormWidget("text"):GetText(), "Ragnaros lgen")
expect("Kachelwahl gesperrt", (function() Manager.SelectKind("level") return Manager.SelectedKind() end)(), "custom")
Manager.FormWidget("text"):SetText("Ragnaros legen")
Manager.FormWidget("amount"):SetText("3")
Manager.FormWidget("reward"):SetText("Zuschauer wählen die Zone")
Manager.FormWidget("points"):SetText("10")
Manager.FormWidget("deadline"):SetText("2h")
click(Manager.saveEditButton)
expect("Text korrigiert", text.params.text, "Ragnaros legen")
expect("jetzt mit Zähler", text.params.counted, true)
expect("Ziel 3", text.target, 3)
expect("Stand bleibt", text.progress, 0)
expect("Belohnung", text.reward, "Zuschauer wählen die Zone")
expect("Punkte", text.points, 10)
expect("Frist gesetzt", Deadlines.Remaining(text), 7200)
expect("Eingabe gemerkt (Vorlagen, Export)", text.source.params.text, "Ragnaros legen")
expect("Chat meldet die Änderung", wow.printed[#wow.printed]:find(string.format(L.SG_CHAT_EDITED, "Ragnaros legen"),
  1, true) ~= nil, true)
expect("Bearbeiten beendet", Manager.EditingGoal(), nil)
expect("Kacheln wieder da", Manager.KindTile("level"):IsShown(), true)
expect("Formular wieder leer", Manager.Form("custom"):Widget("text"):GetText(), "")
expect("Zusätze wieder leer", Manager.ExtrasForm():Widget("reward"):GetText(), "")

-- Unveränderte Frist bleibt, wie sie war; geleertes Feld nimmt Belohnung und Frist weg
wow.advance(600)
Manager.EditGoal(text.id)
expect("Restzeit vorbelegt", Manager.FormWidget("deadline"):GetText(), "1h50m")
expect("Punkte vorbelegt", Manager.FormWidget("points"):GetText(), "10")
local before = text.deadline.at
Manager.FormWidget("points"):SetText("20")
click(Manager.saveEditButton)
expect("Frist unverändert", text.deadline.at, before)
expect("Punkte geändert", text.points, 20)
Manager.EditGoal(text.id)
Manager.FormWidget("deadline"):SetText("")
Manager.FormWidget("reward"):SetText("")
click(Manager.saveEditButton)
expect("Frist weg", text.deadline, nil)
expect("Belohnung weg", text.reward, nil)

-- Wiederholung beim Bearbeiten
Manager.EditGoal(text.id)
local repeatButton = Manager.FormWidget("repeatPeriod")
click(repeatButton)
click(Manager.saveEditButton)
expect("täglich", text.recur and text.recur.period, "daily")

-- Ziel unter den Stand: Fehler, nichts ändert sich
Goals.Step(text.id, 1)
Goals.Step(text.id, 1)
Manager.EditGoal(text.id)
Manager.FormWidget("amount"):SetText("2")
Manager.FormWidget("text"):SetText("Anders")
click(Manager.saveEditButton)
expect("Fehler im Fenster", Manager.errorText._text, string.format(L.SG_ERR_EDIT_TARGET, "2 / 3"))
expect("Text unverändert", text.params.text, "Ragnaros legen")
expect("noch im Bearbeiten", Manager.EditingGoal(), text)
click(Manager.stopEditButton)
expect("abgebrochen", Manager.EditingGoal(), nil)
expect("nichts geändert", text.target, 3)

-- Ziel erreicht, während es bearbeitet wird: Bearbeiten endet
Manager.EditGoal(text.id)
Goals.Step(text.id, 1)
expect("erreicht", text.status, Goals.DONE)
expect("Bearbeiten endet von selbst", Manager.EditingGoal(), nil)

---------------------------------------------------------------------------
-- G17: Level und Kills: nur die Zielzahl; Item: Zahl und Notiz; Arten ohne editierbare Angaben nur die Zusätze
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add level 12")
local level = Goals.Active()[1]
Manager.SelectKind("kills")
Manager.EditGoal(level.id)
expect("Art des Ziels gewählt", Manager.SelectedKind(), "level")
Manager.FormWidget("amount"):SetText("14")
click(Manager.saveEditButton)
expect("neues Ziel-Level", level.target, 14)
expect("Titel folgt", Goals.Title(level), string.format(L.SG_GOAL_LEVEL, 14))
expect("vorige Art wieder gewählt", Manager.SelectedKind(), "kills")
Manager.EditGoal(level.id)
Manager.FormWidget("amount"):SetText("9")
click(Manager.saveEditButton)
expect("Level darunter abgelehnt", Manager.errorText._text, string.format(L.SG_ERR_LEVEL, 10))
click(Manager.stopEditButton)

SlashCmdList.STREAMGOAL("add kills 5 pve")
local kills = Goals.Active()[2]
Manager.EditGoal(kills.id)
local killForm = Manager.Form("kills")
local shownParams = {}
for _, formRow in ipairs(killForm.rows) do
  if killForm:IsRowShown(formRow) then
    table.insert(shownParams, formRow.field and formRow.field.param or "amount")
  end
end
expect("Kills: nur die Zahl", table.concat(shownParams, ","), "amount")
expect("Zahl vorbelegt", Manager.FormWidget("amount"):GetText(), "5")
Manager.FormWidget("amount"):SetText("8")
click(Manager.saveEditButton)
expect("Kills: neues Ziel", kills.target, 8)
expect("Quelle bleibt", kills.params.source, "pve")

SlashCmdList.STREAMGOAL("add item 2589 3")
local item = Goals.Active()[3]
Manager.EditGoal(item.id)
Manager.FormWidget("boss"):SetText("Hogger")
click(Manager.saveEditButton)
expect("Notiz geändert", item.params.boss, "Hogger")
expect("Item bleibt", item.params.itemId, 2589)

SlashCmdList.STREAMGOAL("add rule nodeath")
local rule = Goals.Active()[4]
Manager.EditGoal(rule.id)
expect("Regel: Hinweis nur Zusätze", Manager.editHint._text, L.SG_EDIT_HINT_EXTRAS)
Manager.FormWidget("points"):SetText("5")
click(Manager.saveEditButton)
expect("Regel: Punkte", rule.points, 5)
Goals.Cancel(rule.id)
Goals.Cancel(item.id)

---------------------------------------------------------------------------
-- G17: Teilziele einer Checkliste im Fenster anhängen und lösen
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add list Holz; Erz")
local list = Goals.Active()[3]
expect("Checkliste", list.kind, "checklist")
Manager.EditGoal(list.id)
local sub = Manager.subGoals
expect("Teilziel-Auswahl", sub.choiceButton:IsShown(), true)
expect("erstes laufendes Ziel zur Wahl", sub:Candidate(), level)
click(sub.choiceButton)
expect("nächstes Ziel", sub:Candidate(), kills)
click(sub.attachButton)
expect("angehängt", kills.parentId, list.id)
expect("Checkliste zählt es", list.target, 3)
expect("noch im Bearbeiten", Manager.EditingGoal(), list)
local childRow = sub.children[1]
expect("Zeile des Teilziels", childRow.goal, kills)
expectTrue("Lösen sichtbar", childRow.detach:IsShown())
click(childRow.detach)
expect("gelöst", kills.parentId, nil)
expect("Checkliste wieder 2", list.target, 2)
expect("Teilziel-Zeile weg", childRow.detach:IsShown(), false)
click(Manager.stopEditButton)
Goals.Cancel(list.id)
Goals.Cancel(kills.id)

-- Ohne passende Ziele: Hinweis statt Auswahl
SlashCmdList.STREAMGOAL("add list Holz")
local lonely = Goals.Active()[2]
Goals.Cancel(level.id)
Manager.EditGoal(lonely.id)
expect("keine Auswahl", sub.choiceButton:IsShown(), false)
expect("Hinweis", sub.noneText._text, L.SG_SUBGOAL_NONE)
click(Manager.stopEditButton)
Goals.Cancel(lonely.id)

-- Fenster zu: angefangenes Bearbeiten verfällt
SlashCmdList.STREAMGOAL("add level 13")
local again = Goals.Active()[1]
Manager.EditGoal(again.id)
StreamGoalWindow:Hide()
SlashCmdList.STREAMGOAL("")
expect("nach dem Schließen kein Bearbeiten mehr", Manager.EditingGoal(), nil)
Goals.Cancel(again.id)

---------------------------------------------------------------------------
-- G4: Ziel jeder Art direkt fürs Bingo-Feld
---------------------------------------------------------------------------
streamGoal.Pool.PREMADE = {}
Manager.Toggle("bingo")
BingoEditor.Select(2)
local newGoal = BingoEditor.newGoalButton
expect("Knopf im Bingo-Reiter", newGoal:IsShown() ~= false, true)
expect("Knopf beschriftet", newGoal.label._text, L.SG_BINGO_NEW_GOAL)
click(newGoal)
expect("Reiter Ziele", Manager.ShownPage(), "goals")
expectTrue("Vorlagen-Modus", Manager.TemplateMode() ~= nil)
expect("Hauptaktion setzt ins Feld", Manager.templateButton.label._text, L.SG_BINGO_TEMPLATE_SAVE)
expect("Überschrift fürs Bingo-Feld", Manager.formHeader.label._text, L.SG_BINGO_TEMPLATE_TITLE)
expect("Zusätze aus", Manager.ExtrasForm().frame:IsShown(), false)
expect("Weitere Optionen versteckt", Manager.extrasButton:IsShown(), false)
expect("Kacheln da", Manager.KindTile("kills"):IsShown(), true)
click(Manager.KindTile("kills"))
Manager.FormWidget("amount"):SetText("15")
click(Manager.templateButton)
expect("zurück im Bingo", Manager.ShownPage(), "bingo")
expect("Vorlagen-Modus vorbei", Manager.TemplateMode(), nil)
local key = BingoEditor.Draft().picks[2]
expectTrue("Feld 2 belegt", key ~= nil)
local entry = Pool.Get(key)
expect("Vorlage der Art Kills", entry and entry.kind, "kills")
expect("mit der Zahl", entry and entry.target, 15)
expect("nächstes leeres Feld gewählt", BingoEditor.Selected(), 3)
expect("kein laufendes Ziel angelegt", #Goals.Active(), 0)

-- Fehler bleibt im Formular, "Zurück" speichert nichts
click(newGoal)
click(Manager.KindTile("level"))
Manager.FormWidget("amount"):SetText("5")
click(Manager.templateButton)
expect("Fehler im Formular", Manager.errorText._text, string.format(L.SG_ERR_LEVEL, 10))
expect("noch im Reiter Ziele", Manager.ShownPage(), "goals")
click(Manager.backButton)
expect("Zurück zum Bingo", Manager.ShownPage(), "bingo")
expect("Feld 3 leer", BingoEditor.Draft().picks[3], nil)
Manager.Toggle("goals")
expect("danach wieder normales Formular", Manager.addButton:IsShown(), true)

---------------------------------------------------------------------------
-- Roadmap 439: Kacheln in Zeilen nach Namensbreite, so wenige Zeilen wie möglich, gleichmäßig verteilt
---------------------------------------------------------------------------
local Rows = streamGoal.KindPicker.Rows
local function joined(list) return "" .. table.concat(list, ",") end
expect("passt in eine Zeile", joined(Rows({ 30, 30, 30 }, 100)), "1")
expect("zwei Zeilen ausgeglichen statt 3+1", joined(Rows({ 30, 30, 30, 30 }, 100)), "1,3")
expect("lange Kachel bekommt ihre Zeile", joined(Rows({ 90, 20, 20, 20 }, 100)), "1,2")
expect("leer", #Rows({}, 100), 0)
