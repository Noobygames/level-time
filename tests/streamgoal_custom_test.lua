-- Level Time Goals: eigene Ziele mit freiem Text, mit oder ohne Zähler, selbst gezählt über Karte, Fenster und Befehl.
local Goals = streamGoal.Goals
local Kinds = streamGoal.Kinds
local L = streamGoal.L

local function lastPrint() return wow.printed[#wow.printed] end
local function clickCard(index, mouseButton)
  local card = _G["StreamGoalCard" .. index]
  card._scripts.OnMouseUp(card, mouseButton or "LeftButton")
end

wow.login({ level = 10, zone = "Orgrimmar" })

---------------------------------------------------------------------------
-- Ungültige Ziele
---------------------------------------------------------------------------
local goal, err = Goals.Create("custom", { text = "   " })
expect("leerer Text", goal, nil)
expect("Fehlertext leer", err, L.SG_ERR_TEXT)
goal, err = Goals.Create("custom", { text = string.rep("x", Kinds.MAX_TEXT_LENGTH + 1) })
expect("zu langer Text", goal, nil)
expect("Fehlertext lang", err, string.format(L.SG_ERR_TEXT_LONG, Kinds.MAX_TEXT_LENGTH))
expect("Zähler 0", select(1, Goals.Create("custom", { text = "RFC" }, 0)), nil)

---------------------------------------------------------------------------
-- Mit Zähler: Befehl, Karte, Klicks
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add custom 5 Alle Quests für RFC sammeln")
local quests = Goals.Active()[1]
expect("eigene Art", quests.kind, "custom")
expect("Text ohne Zahl", quests.params.text, "Alle Quests für RFC sammeln")
expect("Zähler bis 5", quests.target, 5)
expect("mit Zähler", Goals.HasCount(quests), true)
expect("Titel = Text", Goals.Title(quests), "Alle Quests für RFC sammeln")
expect("Karte zeigt Stand", StreamGoalCard1.time._text, "0 / 5")

clickCard(1)
clickCard(1)
clickCard(1)
expect("drei Klicks", quests.progress, 3)
expect("Karte aktualisiert", StreamGoalCard1.time._text, "3 / 5")
clickCard(1, "RightButton")
expect("Rechtsklick zählt zurück", quests.progress, 2)
clickCard(1, "RightButton")
clickCard(1, "RightButton")
clickCard(1, "RightButton")
expect("nie unter 0", quests.progress, 0)

SlashCmdList.STREAMGOAL("count " .. quests.id .. " 4")
expect("Befehl zählt um 4", quests.progress, 4)
expect("Befehl meldet Stand", lastPrint():find("(4 / 5)", 1, true) ~= nil, true)

-- Edit-Modus von Level Time: Klicks zählen nicht
addon.EditMode.Enter()
clickCard(1)
expect("kein Zählen im Edit-Modus", quests.progress, 4)
addon.EditMode.Leave()

-- Automatische Ziele lassen sich nicht selbst zählen
SlashCmdList.STREAMGOAL("add kills 10")
local kills = Goals.Active()[2]
SlashCmdList.STREAMGOAL("count " .. kills.id)
expect("Kills nicht manuell", kills.progress, 0)
expect("Meldung automatisch", lastPrint():find(string.format(L.SG_ERR_NOT_MANUAL, kills.id), 1, true) ~= nil, true)
clickCard(2)
expect("Klick auf Kill-Karte zählt nicht", kills.progress, 0)
SlashCmdList.STREAMGOAL("count 999")
expect("unbekannte Nummer", lastPrint():find(string.format(L.SG_ERR_NO_GOAL, "999"), 1, true) ~= nil, true)

clickCard(1)
expect("Ziel erreicht", quests.status, Goals.DONE)
expect("Chat meldet Erreichen", lastPrint():find(string.format(L.SG_CHAT_DONE, quests.params.text), 1, true) ~= nil, true)
SlashCmdList.STREAMGOAL("cancel " .. kills.id)

---------------------------------------------------------------------------
-- Ohne Zähler: einmal abhaken
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add custom Ragefire-Abgrund ohne Tod")
local todo = Goals.Active()[1]
expect("Text komplett", todo.params.text, "Ragefire-Abgrund ohne Tod")
expect("ohne Zähler", Goals.HasCount(todo), false)
expect("Ziel 1 Schritt", todo.target, 1)
SlashCmdList.STREAMGOAL("list")
expect("Liste ohne Stand", lastPrint():find("(0 / 1)", 1, true), nil)
clickCard(1, "RightButton")
expect("Rechtsklick ändert nichts", todo.status, Goals.ACTIVE)
clickCard(1)
expect("Linksklick hakt ab", todo.status, Goals.DONE)

---------------------------------------------------------------------------
-- Fenster: Reiter und Knöpfe + / -
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add custom 3 Drei Wölfe zähmen")
local wolves = Goals.Active()[1]
SlashCmdList.STREAMGOAL("")
expect("Reiter eigene Ziele", wow.click(L.SG_KIND_CUSTOM), true)
expect("Plus-Knopf", wow.click("+"), true)
expect("Plus zählt", wolves.progress, 1)
expect("Minus-Knopf", wow.click("-"), true)
expect("Minus zählt zurück", wolves.progress, 0)

-- Über Neuladen bleibt alles erhalten
wow.logout()
wow.login()
expect("Text bleibt", Goals.Active()[1].params.text, "Drei Wölfe zähmen")
expect("Zähler bleibt", Goals.Active()[1].params.counted, true)
