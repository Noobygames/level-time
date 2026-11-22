-- WoW Forever, Gruppensuche (LT-352): gespeicherte Filter (Gruppen nach Rolle, Einzelspieler nach Rolle und Level,
-- Klassen, Spielstil, Freunde zuerst, Zurücksetzen), Rollenabfrage, 15-s-Such-Timeout, ausgelevelte Aktivitäten im
-- eigenen Eintrag abwählen, Tastenbelegung.
local L = addon.L
local LFGWindow = addon.LFGWindow
local LFGFilters = addon.LFGFilters

-- vor PLAYER_LOGIN (Auswahlliste beim Laden): Standard statt Fehler
local savedDb = addon.db
addon.db = nil
expect("Filter vor Login", LFGFilters.Get().kind, LFGFilters.KIND_ALL)
addon.db = savedDb

wow.login({ level = 22 })
wow.state.lfgActivities = {
  [900] = { mapID = 36, maxNumPlayers = 5, fullName = "Die Todesminen", shortName = "Todesminen", categoryID = 2,
    minLevelSuggestion = 15, maxLevelSuggestion = 22 },
  [901] = { mapID = 33, maxNumPlayers = 5, fullName = "Burg Schattenfang", shortName = "Schattenfang", categoryID = 2,
    minLevelSuggestion = 20, maxLevelSuggestion = 30 },
}
wow.state.lfgResults = {
  -- Gruppe mit Tank, Heiler fehlt
  [1] = { { name = "Brakkus", level = 22, classFilename = "WARRIOR", assignedRole = "TANK" },
    { name = "Jaina", level = 21, classFilename = "MAGE", assignedRole = "DAMAGER" } },
  -- Gruppe mit Heiler, Tank fehlt, Freund dabei
  [2] = { { name = "Lunalia", level = 23, classFilename = "PRIEST", assignedRole = "HEALER" },
    { name = "Kragor", level = 22, classFilename = "ROGUE", assignedRole = "DAMAGER" } },
  [3] = { { name = "Garrosh", level = 30, classFilename = "WARRIOR", lfgRoles = { tank = true, dps = true } } },
  [4] = { { name = "Mirelle", level = 20, classFilename = "SHAMAN", lfgRoles = { healer = true } } },
}
wow.state.lfgInfo = {
  [1] = { activityIDs = { 900 }, leaderName = "Brakkus", age = 10, generalPlaystyle = 2 },
  [2] = { activityIDs = { 900 }, leaderName = "Lunalia", age = 50, numCharFriends = 1, generalPlaystyle = 1 },
  [3] = { activityIDs = { 900 }, leaderName = "Garrosh", age = 20 },
  [4] = { activityIDs = { 900 }, leaderName = "Mirelle", age = 30 },
}
wow.state.lfgMemberCounts = { [1] = { TANK = 1, HEALER = 0, DAMAGER = 1 }, [2] = { TANK = 0, HEALER = 1, DAMAGER = 1 } }
wow.state.lfgWindow = { categories = { [2] = "Dungeons" }, activities = { [2] = { 900, 901 } }, filtered = { 1, 2, 3, 4 } }

local parts = LFGWindow.Parts()
local function click(button) button._scripts.OnClick(button, "LeftButton") end
local function toggle(check, checked)
  check:SetChecked(checked)
  check._scripts.OnClick(check)
end
local function shownIDs()  -- als Text "1,2"
  local ids = {}
  for _, summary in ipairs(LFGWindow.State().results) do table.insert(ids, summary.resultID) end
  table.sort(ids)
  return "ids " .. table.concat(ids, ",")
end

LFGWindow.Show()
click(parts.searchButton)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
expect("ohne Filter alle", shownIDs(), "ids 1,2,3,4")
-- Freunde zuerst (Standard an): Gruppe 2 vor der neueren Gruppe 1
expect("Freund oben", parts.rows[2].resultID, 2)
click(parts.moreButton)
local view = parts.filterView.parts
toggle(view.socialCheck, false)
expect("ohne Freunde zuerst: neueste oben", LFGWindow.State().lines[2].summary.resultID, 1)
toggle(view.socialCheck, true)

-- Gruppen nach Rolle: Heiler frei -> nur Gruppe 1; zusätzlich "hat Heiler" -> keine Gruppe
toggle(view.groupChecks[2], true)  -- Heiler frei
expect("Heiler frei", shownIDs(), "ids 1,3,4")
toggle(view.groupChecks[5], true)  -- hat Heiler
expect("Heiler frei und hat Heiler: keine Gruppe", shownIDs(), "ids 3,4")
toggle(view.groupChecks[2], false)
expect("nur hat Heiler", shownIDs(), "ids 2,3,4")
toggle(view.groupChecks[5], false)

-- Einzelspieler nach Rolle und Level
toggle(view.playerChecks[2], true)  -- Heiler
expect("Spieler Heiler", shownIDs(), "ids 1,2,4")
toggle(view.playerChecks[2], false)
view.levelMinBox:SetText("25")
view.levelMinBox._scripts.OnEditFocusLost(view.levelMinBox)
expect("Spieler ab Level 25", shownIDs(), "ids 1,2,3")
expect("Weitere Filter zählt Level", parts.moreButton:GetText():find("(1)", 1, true) ~= nil, true)
view.levelMinBox:SetText("")
view.levelMinBox._scripts.OnEditFocusLost(view.levelMinBox)

-- Symbole vor Rollen und Klassen
expectTrue("Rollen-Symbol", view.groupChecks[2].textFn():find("|A:groupfinder-icon-role-large-heal", 1, true) ~= nil)
expectTrue("Klassen-Symbol", view.classChecks[1].textFn():find("UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:0:64:0:64|t", 1, true) ~= nil)
-- Klassen: Krieger abwählen blendet Gruppe 1 (hat Krieger) und Garrosh aus
toggle(view.classChecks[1], false)
expect("ohne Krieger", shownIDs(), "ids 2,4")
-- Spielstil
view.playstyleDropdown.pick(1)
expect("Spielstil 1", shownIDs(), "ids 2")
-- gespeichert pro Account
expect("gespeichert", addon.db.lfgFilters.hiddenClasses.WARRIOR, true)
expect("Zahl der Filter", LFGFilters.ActiveCount(LFGFilters.Get()), 2)
click(view.resetButton)
expect("Zurücksetzen", shownIDs(), "ids 1,2,3,4")
expect("Zurücksetzen: Klassen wieder an", view.classChecks[1]:GetChecked(), true)

-- Rollenabfrage nur als Leiter in einer Gruppe
expect("allein keine Rollenabfrage", parts.rolePollButton:IsEnabled(), false)
wow.state.inGroup = true
wow.state.groupLeader = true
LFGWindow.Refresh()
expect("als Leiter Rollenabfrage", parts.rolePollButton:IsEnabled(), true)
wow.lfgCalls = {}
click(parts.rolePollButton)
expect("Rollenabfrage gestartet", wow.lfgCalls[1][1], "InitiateRolePoll")
wow.state.inGroup, wow.state.groupLeader = nil, nil

-- Such-Timeout: ohne Antwort nach 15 s "gescheitert", neue Suche danach möglich
wow.timers = {}
click(parts.searchButton)
expect("Suche läuft", LFGWindow.State().status, "searching")
wow.runTimers()
expect("Timeout", LFGWindow.State().status, "failed")
expect("Timeout-Hinweis", parts.emptyText:GetText(), L.LFG_STATE_FAILED)
click(parts.searchButton)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
wow.runTimers()
expect("alter Timer stört fertige Suche nicht", LFGWindow.State().status, "done")

-- Eigener Eintrag: ausgelevelte Aktivität nach Level-up abgewählt
LFGWindow.SetTab(LFGWindow.TAB_LISTING)
LFGWindow.State().listingActivities = { [900] = true, [901] = true }
wow.levelUp(24)
expect("Todesminen (Forever bis 23) abgewählt", LFGWindow.State().listingActivities[900], nil)
expect("Schattenfang bleibt", LFGWindow.State().listingActivities[901], true)

-- Tastenbelegung schaltet das Fenster um
expect("Name der Taste", BINDING_NAME_LEVELTIMER_LFG_WINDOW, L.LFG_BINDING)
LevelTimer_LFGWindow()
expect("Taste schließt", LFGWindow.IsShown(), false)
LevelTimer_LFGWindow()
expect("Taste öffnet", LFGWindow.IsShown(), true)
expect("keine Lua-Fehler", #wow.errors, 0)

-- v3.0.1: Addon-Sprache ungleich Client-Sprache: keine Blizzard-Texte (Client) zwischen unseren
local clientLocale = GetLocale()
LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE or { WARRIOR = "Krieger" }
addon.Set("language", clientLocale == "enUS" and "deDE" or "enUS")
expect("spricht nicht Client-Sprache", addon.SpeaksClientLanguage(), false)
expectTrue("Klasse in Addon-Sprache", view.classChecks[1].textFn():find(addon.L.CLASS_NAME_WARRIOR, 1, true) ~= nil)
expect("Fenstertext aus eigenen Texten", addon.LFGWindow.Text("LFG_TITLE", "LFG_WIN_TITLE"), addon.L.LFG_WIN_TITLE)
addon.Set("language", addon.AUTO_LANGUAGE)
expect("wieder Client-Sprache", addon.SpeaksClientLanguage(), true)
expect("keine Fehler (Sprache)", #wow.errors, 0)
