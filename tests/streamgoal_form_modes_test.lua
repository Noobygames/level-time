-- Level Time Goals, Formular im Fenster /sg: Arten mit Modus (Quests, Erkundung, Ruf) zeigen nur die Felder des
-- gewählten Modus, Fehler nennen das echte Problem; Zusätze (Frist, Wiederholung, ...) gelten nur für das nächste Ziel.
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local Recurring = streamGoal.Recurring
local L = streamGoal.L

wow.login({ level = 10, zone = "Orgrimmar" })
SlashCmdList.STREAMGOAL("")

local function widget(param) return Manager.FormWidget(param) end
local function shown(param) return widget(param):IsShown() end
local function y(param)
  local point = widget(param)._points[1]
  return point[#point]
end
-- Auswahl weiterschalten (Linksklick: nächster Wert)
local function nextChoice(param)
  local button = widget(param)
  button._scripts.OnClick(button, "LeftButton")
end
local function errorShown() return Manager.errorText._text end

---------------------------------------------------------------------------
-- Quests: Anzahl oder bestimmte Quests
---------------------------------------------------------------------------
Manager.SelectKind("quest")
expect("Modus zuerst", y("mode"), 2)
expect("Modus Anzahl: Zahl da", shown("amount"), true)
expect("Modus Anzahl: Quest-Feld versteckt", shown("input"), false)
expect("Zahl direkt unter dem Modus", y("amount"), -Manager.ROW)
expect("ohne Zahl: Fehler zur Anzahl", Manager.AddFromForm(), nil)
expect("Fehlertext Anzahl", errorShown(), L.SG_ERR_AMOUNT)

nextChoice("mode")
expect("Modus Quests: Quest-Feld da", shown("input"), true)
expect("Modus Quests: Zahl versteckt", shown("amount"), false)
expect("Quest-Feld rückt an die Stelle der Zahl", y("input"), -Manager.ROW)
expect("ohne Quests: Fehler zu den Quests", Manager.AddFromForm(), nil)
expect("Fehlertext Quests", errorShown(), L.SG_ERR_QUEST)
widget("input"):SetText("101 102")
local chain = Manager.AddFromForm()
expectTrue("Kette angelegt", chain ~= nil)
expect("Modus ids", chain.params.mode, "ids")
expect("zwei Quests", #chain.params.quests, 2)

---------------------------------------------------------------------------
-- Erkundung: eine Zahl im versteckten Feld zählt nicht
---------------------------------------------------------------------------
Manager.SelectKind("explore")
widget("amount"):SetText("3")
nextChoice("mode")
expect("Modus Zone: Zahl versteckt", shown("amount"), false)
expect("Modus Zone: Zonen-Feld da", shown("zone"), true)
expect("ohne Zone: Fehler zur Zone", Manager.AddFromForm(), nil)
expect("Fehlertext Zone", errorShown(), L.SG_ERR_ZONE)
widget("zone"):SetText("Tanaris")
local zone = Manager.AddFromForm()
expect("Zonen-Ziel", zone and zone.params.zone, "Tanaris")
nextChoice("mode")
expect("zurück auf Anzahl", shown("amount"), true)

---------------------------------------------------------------------------
-- Ruf: Fraktion immer, dazu Rufpunkte oder Stufe
---------------------------------------------------------------------------
Manager.SelectKind("reputation")
expect("Fraktion da", shown("faction"), true)
expect("gewinnen: Rufpunkte da", shown("amount"), true)
expect("gewinnen: Stufe versteckt", shown("standing"), false)
nextChoice("mode")
expect("Stufe: Stufe da", shown("standing"), true)
expect("Stufe: Rufpunkte versteckt", shown("amount"), false)
expect("Stufe rückt nach oben", y("standing"), -2 * Manager.ROW + 2)
expect("ohne Fraktion: Fehler zur Fraktion", Manager.AddFromForm(), nil)
expect("Fehlertext Fraktion", errorShown(), L.SG_ERR_FACTION)
nextChoice("mode")

---------------------------------------------------------------------------
-- Zusätze: gesetzte Auswahl hält sie offen, nach "Ziel hinzufügen" stehen sie wieder auf Anfang
---------------------------------------------------------------------------
Manager.SelectKind("kills")
Manager.ToggleExtras(true)
nextChoice("repeatPeriod")
Manager.ToggleExtras(false)
expect("Wiederholung gesetzt: Zusätze bleiben sichtbar", Manager.ExtrasShown(), true)
widget("amount"):SetText("5")
widget("reward"):SetText("Pizza")
local daily = Manager.AddFromForm()
expect("erstes Ziel täglich", daily.recur and daily.recur.period, Recurring.DAILY)
expect("erstes Ziel mit Belohnung", daily.reward, "Pizza")
expect("Wiederholung zurück auf Nie", widget("repeatPeriod").label._text, L[Recurring.LABELS[Recurring.NONE]])
expect("Belohnung geleert", widget("reward"):GetText(), "")
Manager.ToggleExtras(false)
expect("danach zuklappbar", Manager.ExtrasShown(), false)
widget("amount"):SetText("6")
local plain = Manager.AddFromForm()
expect("zweites Ziel nicht täglich", plain.recur, nil)
expect("ohne Belohnung", plain.reward, nil)
for _, goal in ipairs(Goals.Active()) do Goals.Cancel(goal.id) end
