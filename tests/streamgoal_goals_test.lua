-- Level Time Goals: Ziele anlegen, Fortschritt je Zielart, Abschluss mit Meldung, Historie, Befehle, Fenster.
local Goals = streamGoal.Goals
local L = streamGoal.L

local function link(id, name)
  return "|cffa335ee|Hitem:" .. id .. "::::::::20:::::|h[" .. name .. "]|h|r"
end
local function lastPrint() return wow.printed[#wow.printed] end

wow.login({ level = 10, zone = "Wald von Elwynn" })
expectTrue("Datenbank angelegt", StreamGoalDB ~= nil and StreamGoalDB.nextId == 1)
expect("keine Ziele", #Goals.Active(), 0)

---------------------------------------------------------------------------
-- Ungültige Ziele
---------------------------------------------------------------------------
local goal, err = Goals.Create("level", {}, 10)
expect("aktuelles Level ist kein Ziel", goal, nil)
expect("Fehlertext Level", err, string.format(L.SG_ERR_LEVEL, 10))
expect("Anzahl 0", select(1, Goals.Create("kills", { source = "any" }, 0)), nil)
expect("Item ohne ID", select(1, Goals.Create("item", {}, 1)), nil)
expect("unbekannte Art", select(1, Goals.Create("fishing", {}, 1)), nil)

---------------------------------------------------------------------------
-- Level
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add level 12")
local levelGoal = Goals.Active()[1]
expect("Level-Ziel", levelGoal.kind, "level")
expect("Startstand = aktuelles Level", levelGoal.progress, 10)
expectNear("noch kein Anteil", Goals.Fraction(levelGoal), 0)
wow.levelUp(11)
expect("Level 11 gebucht", levelGoal.progress, 11)
expectNear("halber Weg", Goals.Fraction(levelGoal), 0.5)
expect("Karte zeigt Stand", streamGoal.Tracker.frame:IsShown(), true)
wow.levelUp(12)
expect("Level-Ziel erreicht", levelGoal.status, Goals.DONE)
expect("Abschlusszeit", levelGoal.finishedAt ~= nil, true)
expect("Chat meldet Erreichen", lastPrint():find(string.format(L.SG_CHAT_DONE, string.format(L.SG_GOAL_LEVEL, 12)), 1, true) ~= nil, true)
expect("keine aktiven Ziele mehr", #Goals.Active(), 0)
expect("Karte weg", streamGoal.Tracker.frame:IsShown(), false)

---------------------------------------------------------------------------
-- Kills: PvE zählt nur PvE, PvP nur Schlachtfeld
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add kills 2 pve")
SlashCmdList.STREAMGOAL("add kills 2 pvp bg")
SlashCmdList.STREAMGOAL("add kills 3")
local pveGoal, pvpGoal, anyGoal = Goals.Active()[1], Goals.Active()[2], Goals.Active()[3]
expect("PvE-Quelle", pveGoal.params.source, "pve")
expect("PvP im Schlachtfeld", pvpGoal.params.battleground, true)
expect("alle Gegner", anyGoal.params.source, "any")

wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 45 Erfahrung.")
expect("PvE-Kill zählt für PvE", pveGoal.progress, 1)
expect("PvE-Kill zählt nicht für PvP", pvpGoal.progress, 0)
expect("PvE-Kill zählt für alle", anyGoal.progress, 1)

local honor = "Grimbar stirbt, ehrenhafter Sieg Rang: Gefreiter (Geschätzte Ehrenpunkte: 12)"
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", honor)
expect("PvP-Kill in der Welt zählt nicht für BG-Ziel", pvpGoal.progress, 0)
expect("PvP-Kill zählt für alle", anyGoal.progress, 2)
expect("PvP-Kill zählt nicht für PvE", pveGoal.progress, 1)

wow.state.instance = { name = "Arathibecken", type = "pvp" }
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", honor)
expect("PvP-Kill im Schlachtfeld", pvpGoal.progress, 1)
wow.fire("CHAT_MSG_COMBAT_HONOR_GAIN", honor)
expect("BG-Ziel erreicht", pvpGoal.status, Goals.DONE)
expect("Ziel über alle erreicht", anyGoal.status, Goals.DONE)
wow.state.instance = nil
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 45 Erfahrung.")
expect("PvE-Ziel erreicht", pveGoal.status, Goals.DONE)
expect("Fortschritt bleibt am Ziel stehen", pvpGoal.progress, 2)

---------------------------------------------------------------------------
-- Items: Link und ID, Anzahl, nur das gesuchte Item
---------------------------------------------------------------------------
local blade, cloth = link(1234, "Zornklinge"), link(55, "Leinenstoff")
SlashCmdList.STREAMGOAL("add item " .. blade)
SlashCmdList.STREAMGOAL("add item 55 3")
local bladeGoal, clothGoal = Goals.Active()[1], Goals.Active()[2]
expect("Item-ID aus Link", bladeGoal.params.itemId, 1234)
expect("Standardanzahl 1", bladeGoal.target, 1)
expect("Item-ID aus Zahl", clothGoal.params.itemId, 55)
expect("Anzahl 3", clothGoal.target, 3)

wow.fire("CHAT_MSG_LOOT", "Grimbar erhält Beute: " .. blade .. ".")  -- fremde Beute
expect("fremde Beute zählt nicht", bladeGoal.progress, 0)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. cloth .. "x2.")
expect("zwei Stück", clothGoal.progress, 2)
expect("anderes Item bleibt", bladeGoal.progress, 0)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet einen Gegenstand: " .. cloth .. ".")  -- Kauf, Post oder Quest
expect("erhaltener Gegenstand ist keine Beute", clothGoal.progress, 2)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. cloth .. ".")
expect("Leinenstoff-Ziel erreicht", clothGoal.status, Goals.DONE)
wow.fire("CHAT_MSG_LOOT", "Ihr erhaltet Beute: " .. blade .. ".")
expect("Klinge erreicht", bladeGoal.status, Goals.DONE)

---------------------------------------------------------------------------
-- Schlachtfeld-Siege: einmal je Spiel, nur Sieg, optional nach Name
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("add bgwin 2")
SlashCmdList.STREAMGOAL("add bgwin 1 Kriegshymnenschlucht")
local anyBg, namedBg = Goals.Active()[1], Goals.Active()[2]
expect("Name aus Befehl", namedBg.params.battleground, "Kriegshymnenschlucht")

wow.state.instance = { name = "Arathibecken", type = "pvp" }
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("läuft noch: kein Sieg", anyBg.progress, 0)
wow.state.battlefieldWinner = 1  -- Allianz, wir sind Allianz
wow.fire("UPDATE_BATTLEFIELD_SCORE")
wow.fire("PVP_MATCH_COMPLETE", 1, 600)
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("Sieg zählt einmal", anyBg.progress, 1)
expect("anderes Schlachtfeld zählt nicht", namedBg.progress, 0)

-- Verlust im nächsten Spiel
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Arathibecken", type = "pvp" }
wow.state.battlefieldWinner = 0  -- Horde
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("Niederlage zählt nicht", anyBg.progress, 1)

-- Unentschieden zählt nicht, Sieg im benannten Schlachtfeld schon
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Kriegshymnenschlucht", type = "pvp" }
wow.state.battlefieldWinner = 255
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("Unentschieden zählt nicht", namedBg.progress, 0)
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Kriegshymnenschlucht", type = "pvp" }
wow.state.battlefieldWinner = 1
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("Sieg in Kriegshymnenschlucht", namedBg.status, Goals.DONE)
expect("Sieg zählt auch für das offene Ziel", anyBg.status, Goals.DONE)
wow.state.instance = nil

-- Arena ist kein Schlachtfeld
SlashCmdList.STREAMGOAL("add bgwin 1")
local arenaGoal = Goals.Active()[1]
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Nagrandarena", type = "arena" }
wow.state.battlefieldWinner = 1
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("Arena zählt nicht", arenaGoal.progress, 0)
wow.state.instance = nil

---------------------------------------------------------------------------
-- Abbrechen, Historie, andere Charaktere
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("cancel " .. arenaGoal.id)
expect("abgebrochen", arenaGoal.status, Goals.CANCELLED)
expect("Chat meldet Abbruch", lastPrint():find(string.format(L.SG_CHAT_CANCELLED, string.format(L.SG_GOAL_BGWIN_ANY, 1)), 1, true) ~= nil, true)
SlashCmdList.STREAMGOAL("cancel 999")
expect("unbekannte Nummer", lastPrint():find(string.format(L.SG_ERR_NO_GOAL, "999"), 1, true) ~= nil, true)

local history = Goals.History()
expect("Historie mit allen Zielen", #history, 9)
expect("neuestes zuerst", history[1].finishedAt >= history[#history].finishedAt, true)

StreamGoalDB.goals[#StreamGoalDB.goals + 1] = { id = 500, kind = "level", character = "Anderer-Realm", createdAt = 1,
  target = 20, start = 10, progress = 10, params = {}, status = Goals.ACTIVE }
expect("Ziel eines anderen Charakters läuft hier nicht", #Goals.Active(), 0)
wow.levelUp(13)
expect("und wird nicht gebucht", StreamGoalDB.goals[#StreamGoalDB.goals].progress, 10)

-- Historie wächst nicht über das Limit
Goals.MAX_HISTORY = 5
SlashCmdList.STREAMGOAL("add kills 1")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Kobold stirbt, Ihr bekommt 45 Erfahrung.")
expect("Historie begrenzt", #Goals.History(), 5)

-- Speichern über Neuladen
wow.logout()
wow.login()
expect("Daten bleiben", #Goals.History(), 5)
expect("nächste Nummer läuft weiter", StreamGoalDB.nextId, 11)

---------------------------------------------------------------------------
-- Fenster: öffnen, Formular, Historie
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("")
expect("Fenster offen", StreamGoalWindow:IsShown(), true)
wow.click(L.SG_KIND_ITEM)
wow.click(L.SG_KIND_BGWIN)
wow.click(L.SG_KIND_KILLS)
wow.click(L.SG_KIND_LEVEL)
SlashCmdList.STREAMGOAL("history")
expect("Historie sichtbar", wow.shownTable() ~= nil, true)
expect("Zeilen der Historie", #wow.shownTable():GetVisibleRecords(), 5)
SlashCmdList.STREAMGOAL("tracker")
expect("Anzeige aus", StreamGoalDB.settings.showTracker, false)
SlashCmdList.STREAMGOAL("scale 9")
expect("Größe begrenzt", StreamGoalDB.settings.scale, 2)
SlashCmdList.STREAMGOAL("move")
SlashCmdList.STREAMGOAL("help")
expect("Hilfe", lastPrint():find(L.SG_HELP, 1, true) ~= nil, true)

---------------------------------------------------------------------------
-- Obergrenze und Reload im fertigen Schlachtfeld
---------------------------------------------------------------------------
for _ = 1, Goals.MAX_ACTIVE do SlashCmdList.STREAMGOAL("add bgwin 5") end
expect("Obergrenze erreicht", #Goals.Active(), Goals.MAX_ACTIVE)
SlashCmdList.STREAMGOAL("add bgwin 5")
expect("Obergrenze: kein weiteres Ziel", #Goals.Active(), Goals.MAX_ACTIVE)
expect("Obergrenze: Meldung", lastPrint():find(string.format(L.SG_ERR_TOO_MANY, Goals.MAX_ACTIVE), 1, true) ~= nil, true)

wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
wow.state.instance = { name = "Arathibecken", type = "pvp" }
wow.state.battlefieldWinner = 1
wow.fire("UPDATE_BATTLEFIELD_SCORE")
local firstActive = Goals.Active()[1]
expect("Sieg gezählt", firstActive.progress, 1)
wow.fire("PLAYER_ENTERING_WORLD")  -- /reload im fertigen Schlachtfeld
wow.fire("UPDATE_BATTLEFIELD_SCORE")
expect("Reload zählt nicht doppelt", firstActive.progress, 1)
wow.state.instance = nil
