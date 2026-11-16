-- WoW Forever: eigenes Gruppensuche-Fenster (UI/LFGWindow.lua, Assist/LFGSearch.lua). Ersetzt Blizzards Fenster nur mit
-- Einstellung lfgWindow; Suche nur auf Klick mit eigenem Sprachfilter, Liste, Filter, Detail, Flüstern/Einladen,
-- eigener Eintrag. Todesminen (36): Quest 167 (Beute von NPC 626).
local L = addon.L
local LFGWindow = addon.LFGWindow

wow.login({ level = 22 })
wow.state.questTitles[167] = "Die Bruderschaft"
wow.state.lfgActivities = { [900] = { mapID = 36, maxNumPlayers = 5, fullName = "Die Todesminen", shortName = "Todesminen",
  categoryID = 2, orderIndex = 1 } }
wow.state.lfgResults = {
  [7] = {
    { name = "Brakkus", level = 23, areaName = "Westfall", classFilename = "WARRIOR", assignedRole = "TANK", isLeader = true },
    { name = "Jaina", level = 20, classFilename = "MAGE", assignedRole = "DAMAGER" },
  },
  [8] = { { name = "Garrosh", level = 22, classFilename = "WARRIOR", lfgRoles = { tank = true, healer = false, dps = true } } },
  [9] = { { name = "Zu hoch", level = 40 } },
}
wow.state.lfgInfo = { [7] = { activityIDs = { 900 }, leaderName = "Brakkus", comment = "Nur Dungeonquests", age = 125 },
  [8] = { activityIDs = { 900 }, leaderName = "Garrosh", age = 30 }, [9] = { activityIDs = { 900 }, leaderName = "Zu hoch", age = 5 } }
wow.state.lfgMemberCounts = { [7] = { TANK = 1, HEALER = 0, DAMAGER = 1 } }
wow.state.lfgWindow = { categories = { [2] = "Dungeons" }, activities = { [2] = { 900 } }, filtered = { 7, 8, 9 } }
wow.state.lfgLanguages = { filter = { enUS = true, deDE = true }, available = { "enUS", "deDE" }, defaults = {} }

-- Aus: Blizzards Fenster bleibt
LFGVanilla_ShowFrame(2)
expect("aus: Blizzards Fenster offen", LFGParentFrame:IsShown(), true)
expect("aus: eigenes Fenster zu", LFGWindow.IsShown(), false)
LFGParentFrame:Hide()

-- An: ersetzt Blizzards Fenster, Reiter Wer bleibt bei Blizzard
addon.Set("lfgWindow", true)
LFGVanilla_ShowFrame(2)
expect("an: eigenes Fenster offen", LFGWindow.IsShown(), true)
expect("an: Blizzards Fenster geschlossen", LFGParentFrame:IsShown(), false)
LFGVanilla_ShowFrame(3)
expect("Reiter Wer bleibt Blizzards", LFGParentFrame:IsShown(), true)
LFGParentFrame:Hide()
LFGVanilla_ShowFrame(2)
expect("zweiter Aufruf schließt", LFGWindow.IsShown(), false)
LFGVanilla_ShowFrame(2)
expect("dritter Aufruf öffnet wieder", LFGWindow.IsShown(), true)

local parts = LFGWindow.Parts()
local function click(button) button._scripts.OnClick(button, "LeftButton") end
expect("vor der Suche: Hinweis", parts.emptyText:GetText(), L.LFG_STATE_START)
expect("vor der Suche keine Suche", #wow.lfgCalls, 0)

-- Suche nur auf Klick, mit eigenem Sprachfilter (Pflichtsprache enUS plus Chip deDE aus Blizzards Filter)
click(parts.searchButton)
local call = wow.lfgCalls[1]
expect("Suche aufgerufen", call[1], "Search")
expect("Kategorie", call[2], 2)
expect("Sprachfilter enthält Chip", call[5].deDE, true)
expect("Aktivitäten der Kategorie", call[8][1], 900)
expect("Suchlauf zeigt Hinweis", parts.emptyText:GetText(), L.LFG_STATE_SEARCHING)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
expect("Ergebnisse: drei Zeilen", parts.rows[3]:IsShown(), true)
expect("Zeile 3 leer", parts.rows[4]:IsShown(), false)
expect("neueste Gruppe zuerst", parts.rows[1].resultID, 9)
expect("Titel mit Leiter", parts.rows[3].title:GetText(), "Die Todesminen - Brakkus")
expect("Kommentar in der Zeile", parts.rows[3].comment:GetText(), "Nur Dungeonquests")
expectTrue("Level-Spanne der Gruppe", parts.rows[3].level:GetText():find("20-23", 1, true) ~= nil)
expectTrue("Einzelspieler zeigt Rollen", parts.rows[2].roles:GetText():find("tank", 1, true) ~= nil)
expectTrue("offene Rolle der Gruppe", parts.rows[3].roles:GetText():find("heal", 1, true) ~= nil)

-- "Passend für mich": Level 40 passt nicht zu Level 22
parts.fitCheck:SetChecked(true)
parts.fitCheck._scripts.OnClick(parts.fitCheck)
expect("Passend: Gruppe mit Level 40 weg", parts.rows[3]:IsShown(), false)
expect("Passend: zwei Gruppen", parts.rows[2]:IsShown(), true)
parts.fitCheck:SetChecked(false)
parts.fitCheck._scripts.OnClick(parts.fitCheck)
expect("ohne Filter wieder drei", parts.rows[3]:IsShown(), true)

-- Art: Gruppen
click(parts.moreButton)
click(parts.kindButton)
expect("nur Gruppen: eine Zeile", parts.rows[2]:IsShown(), false)
expect("nur Gruppen: Gruppe 7", parts.rows[1].resultID, 7)
expectTrue("Weitere Filter zählt Sprache und Art", parts.moreButton:GetText():find("(2)", 1, true) ~= nil)
click(parts.kindButton)
expect("nur Einzelspieler: Gruppe 7 weg", parts.rows[3]:IsShown(), false)
click(parts.kindButton)

-- Detail: Mitglieder, Quest, Aktionen
parts.rows[3]._scripts.OnClick(parts.rows[3], "LeftButton")
expect("Gruppe gewählt", LFGWindow.State().selected, 7)
local text = parts.detailText:GetText()
expectTrue("Detail: Mitglied", text:find("Brakkus", 1, true) ~= nil)
expectTrue("Detail: Quest", text:find("Die Bruderschaft", 1, true) ~= nil)
expect("Detail: Alter als Label-Wert", parts.detailFields.age.value:GetText(), "2m 05s")
expectTrue("Detail: Level-Spanne", parts.detailFields.level.value:GetText():find("20-23", 1, true) ~= nil)
click(parts.whisperButton)
expect("Flüstern an den Leiter", wow.socialActions[#wow.socialActions][2], "Brakkus")
expect("Gruppe nicht einladbar", parts.inviteButton:IsEnabled(), false)
parts.rows[2]._scripts.OnClick(parts.rows[2], "LeftButton")
expect("Einzelspieler einladbar", parts.inviteButton:IsEnabled(), true)
click(parts.inviteButton)
expect("Einladung", wow.socialActions[#wow.socialActions][1], "invite")
expect("Einladung an den Leiter", wow.socialActions[#wow.socialActions][2], "Garrosh")

-- Eigene Gruppe: eintragen, aktualisieren, austragen
LFGWindow.SetTab(1)
expect("kein Eintrag", parts.listingStatus:GetText(), L.LFG_LISTING_NONE)
expect("ohne Aktivität kein Eintragen", parts.postButton:IsEnabled(), false)
LFGWindow.State().listingCategoryID, LFGWindow.State().listingActivityID = 2, 900
LFGWindow.Refresh()
parts.roleChecks.TANK:SetChecked(true)
parts.newPlayerCheck:SetChecked(true)
wow.lfgCalls = {}
click(parts.postButton)
expect("Rollen gesetzt", wow.lfgCalls[1][1], "SetRoles")
expect("Rolle Tank", wow.lfgCalls[1][2].tank, true)
expect("Eintrag erstellt", wow.lfgCalls[2][1], "CreateListing")
expect("Aktivität im Eintrag", wow.lfgCalls[2][2].activityIDs[1], 900)
expect("einsteigerfreundlich", wow.lfgCalls[2][2].newPlayerFriendly, true)
wow.state.lfgWindow.entry = { activityIDs = { 900 }, newPlayerFriendly = true }
wow.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
expectTrue("Status nennt die Aktivität", parts.listingStatus:GetText():find("Todesminen", 1, true) ~= nil)
wow.lfgCalls = {}
click(parts.postButton)
expect("Eintrag aktualisiert", wow.lfgCalls[2][1], "UpdateListing")
click(parts.unlistButton)
expect("Eintrag entfernt", wow.lfgCalls[3][1], "RemoveListing")

-- Nur der Leiter darf den Eintrag ändern
wow.state.inGroup = true
LFGWindow.Refresh()
expectTrue("Hinweis für Mitglieder", parts.listingNotice:GetText() == L.LFG_LEADER_ONLY)
expect("Mitglied darf nicht eintragen", parts.postButton:IsEnabled(), false)

-- Lange Liste: Bildlaufleiste und Mausrad verschieben die sichtbaren Zeilen
LFGWindow.SetTab(2)
for id = 10, 29 do
  wow.state.lfgResults[id] = { { name = "Spieler" .. id, level = 22, classFilename = "MAGE" } }
  wow.state.lfgInfo[id] = { activityIDs = { 900 }, leaderName = "Spieler" .. id, age = id }
  table.insert(wow.state.lfgWindow.filtered, id)
end
click(parts.searchButton)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
local total = #LFGWindow.State().results
expect("23 Treffer", total, 23)
expect("Leiste sichtbar", parts.scrollBar:IsShown(), true)
local first = parts.rows[1].resultID
parts.scrollBar:SetValue(5)
parts.scrollBar._scripts.OnValueChanged(parts.scrollBar, 5)
expect("Leiste verschiebt die Liste", LFGWindow.State().offset, 5)
expectTrue("andere erste Zeile", parts.rows[1].resultID ~= first)
LFGWindow.State().offset = 0
LFGWindow.Refresh()
local searchFrame = LFGWindow.searchContainer
searchFrame._scripts.OnMouseWheel(searchFrame, -1)
expect("Mausrad scrollt drei Zeilen", LFGWindow.State().offset, 3)
searchFrame._scripts.OnMouseWheel(searchFrame, -10)
expect("Mausrad endet am Listenende", LFGWindow.State().offset, total - 15)

-- Ausschalten schließt das Fenster
addon.Set("lfgWindow", false)
expect("ausgeschaltet schließt", LFGWindow.IsShown(), false)
expect("keine Lua-Fehler", #wow.errors, 0)
