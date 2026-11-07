-- Level Time Goals, Roadmap 312: Einstellungsfenster (Kartenzahl, Farben, Meldungen, Standard je Seite, Suche),
-- Edit-Modus mit Beispielkarte und Knopf "Einstellungen", Rückfrage beim Abbrechen, Aufräumen gelöschter Charaktere.
local Goals = streamGoal.Goals
local Options = streamGoal.Options
local Tracker = streamGoal.Tracker
local L = streamGoal.L
local Theme = addon.Theme
local builder = Options.builder

local function acceptPopup()
  StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
  wow.popup = nil
end
local function printedContains(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

-- Ein zweiter Charakter mit einem laufenden Ziel, der später in Level Time gelöscht wird
wow.login({ name = "Altchar", level = 5 })
SlashCmdList.STREAMGOAL("add custom Alt-Ziel")
local altGoal = Goals.Active()[1]
expect("Alt-Ziel angelegt", altGoal and altGoal.params.text, "Alt-Ziel")
local altKey = addon.characterKey
wow.logout()

wow.login({ name = "Hauptchar", level = 10 })
expect("Ziel des anderen Charakters läuft hier nicht", #Goals.Active(), 0)

---------------------------------------------------------------------------
-- Edit-Modus: Beispielkarte ohne Ziele, Knopf "Einstellungen" öffnet das Fenster von Level Time Goals
---------------------------------------------------------------------------
addon.EditMode.Enter()
expect("Beispielkarte im Edit-Modus", StreamGoalTracker:IsShown(), true)
expect("Beispieltitel", StreamGoalCard1.title._text, string.format(L.SG_GOAL_LEVEL, 20))
expectTrue("Fläche im Edit-Modus", addon.EditMode.Overlay("streamGoal") ~= nil)
addon.EditMode.ShowPopup("streamGoal")
LevelTimerEditPopup.settingsButton._scripts.OnClick(LevelTimerEditPopup.settingsButton, "LeftButton")
expect("Edit-Modus verlassen", addon.EditMode.IsActive(), false)
expect("Einstellungen von Goals offen", StreamGoalOptions:IsShown(), true)
expect("nicht die von Level Time", LevelTimerOptions and LevelTimerOptions:IsShown() or false, false)
expect("Unterseite Tracker", select(2, builder.CurrentPage()), "SG_OPTIONS_PAGE_TRACKER")
expect("ohne Ziele kein Tracker", StreamGoalTracker:IsShown(), false)
StreamGoalOptions:Hide()

---------------------------------------------------------------------------
-- Kartenzahl und "+n weitere"
---------------------------------------------------------------------------
for i = 1, 4 do SlashCmdList.STREAMGOAL("add custom Ziel " .. i) end
expect("vier Karten", StreamGoalCard4:IsShown(), true)
expect("keine Zusatzzeile", Tracker.moreText:IsShown(), false)
streamGoal.SetSetting("maxCards", 2)
expect("dritte Karte versteckt", StreamGoalCard3:IsShown(), false)
expect("zweite Karte bleibt", StreamGoalCard2:IsShown(), true)
expect("Zusatzzeile", Tracker.moreText._text, string.format(L.SG_MORE_GOALS, 2))

---------------------------------------------------------------------------
-- Farben: je Zielart oder Akzentfarbe
---------------------------------------------------------------------------
local kindColor = Goals.GetKind("custom").color
expect("Farbe der Zielart", StreamGoalCard1.title._textColor[1], kindColor[1])
streamGoal.SetSetting("cardColors", "accent")
expect("Akzentfarbe", StreamGoalCard1.title._textColor[1], Theme.COLORS.accent[1])
expect("Akzentfarbe auch Karte 2", StreamGoalCard2.title._textColor[3], Theme.COLORS.accent[3])

---------------------------------------------------------------------------
-- Einstellungsfenster: Suche, Standard je Unterseite (Rückfrage, Rückgängig)
---------------------------------------------------------------------------
Options.Toggle()
expect("Fenster offen", StreamGoalOptions:IsShown(), true)
builder.SetSearchText(L.SG_OPTIONS_MAX_CARDS)
expectTrue("Suche findet Kartenzahl", #builder.SearchResultRows() >= 1)
builder.SetSearchText("")
expect("Standard setzt Kartenzahl und Farbe zurück", builder.ResetCount("SG_OPTIONS_PAGE_TRACKER") >= 4, true)
builder.ResetPage("SG_OPTIONS_PAGE_TRACKER")
expect("Kartenzahl Standard", StreamGoalDB.settings.maxCards, 6)
expect("Farbe Standard", StreamGoalDB.settings.cardColors, "kind")
expect("alle Karten wieder da", StreamGoalCard4:IsShown(), true)
builder.UndoReset("SG_OPTIONS_PAGE_TRACKER")
expect("Rückgängig", StreamGoalDB.settings.maxCards, 2)
builder.ResetPage("SG_OPTIONS_PAGE_TRACKER")

-- Meldungen abschalten: keine Chatzeile, keine Einblendung
streamGoal.SetSetting("doneChat", false)
streamGoal.SetSetting("doneAlert", false)
addon.Alerts.Clear()
local printedBefore = #wow.printed
local first = Goals.Active()[1]
Goals.Step(first.id, 1)
expect("erreicht", first.status, Goals.DONE)
expect("keine Chatzeile", #wow.printed, printedBefore)
expect("keine Einblendung", LevelTimerNotice:IsShown(), false)
streamGoal.SetSetting("doneChat", true)
streamGoal.SetSetting("doneAlert", true)
StreamGoalOptions:Hide()

---------------------------------------------------------------------------
-- Abbrechen im Fenster nur nach Rückfrage
---------------------------------------------------------------------------
SlashCmdList.STREAMGOAL("")
local second = Goals.Active()[1]
expectTrue("Abbrechen-Knopf", wow.click(L.SG_CANCEL, true))
expect("noch nicht abgebrochen", Goals.Get(Goals.Active()[#Goals.Active()].id).status, Goals.ACTIVE)
expect("Rückfrage", wow.popup.name, "STREAMGOAL_CANCEL")
acceptPopup()
expect("nach Rückfrage abgebrochen", #Goals.Active(), 2)
expect("erstes Ziel bleibt", Goals.Active()[1], second)
StreamGoalWindow:Hide()

---------------------------------------------------------------------------
-- Gelöschter Charakter: laufende Ziele gelten als abgebrochen, Aufräumen entfernt sie
---------------------------------------------------------------------------
expect("Alt-Ziel läuft noch", altGoal.status, Goals.ACTIVE)
addon.DeleteCharacter(altKey)
expect("Alt-Ziel abgebrochen", altGoal.status, Goals.CANCELLED)
expect("als verwaist markiert", altGoal.orphaned, true)
expect("ein verwaistes Ziel", Goals.CountOrphans(), 1)
Options.Show("SG_OPTIONS_PAGE_DATA")
expect("Zähler im Fenster", Options.info._text, string.format(L.SG_OPTIONS_DATA_INFO, #Goals.History(), 1))
expectTrue("Aufräumen-Knopf", wow.click(L.SG_OPTIONS_REMOVE_ORPHANS))
expect("Rückfrage Aufräumen", wow.popup.name, "STREAMGOAL_REMOVE_ORPHANS")
acceptPopup()
expect("verwaistes Ziel entfernt", Goals.Get(altGoal.id), nil)
expectTrue("Meldung entfernt", printedContains(string.format(L.SG_CHAT_REMOVED, 1)))
expect("Zähler aktualisiert", Options.info._text, string.format(L.SG_OPTIONS_DATA_INFO, #Goals.History(), 0))
wow.click(L.SG_OPTIONS_REMOVE_ORPHANS)
expect("nichts mehr zu entfernen: keine Rückfrage", wow.popup, nil)

expectTrue("Historie leeren", wow.click(L.SG_OPTIONS_CLEAR_HISTORY))
acceptPopup()
expect("Historie leer", #Goals.History(), 0)
expect("laufende Ziele bleiben", #Goals.Active(), 2)
