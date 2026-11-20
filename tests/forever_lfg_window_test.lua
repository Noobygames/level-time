-- WoW Forever: eigenes Gruppensuche-Fenster (UI/LFGWindow.lua, Assist/LFGSearch.lua) neben Blizzards (Einstiege:
-- Minikarten-Icon, Knopf an Blizzards Fenster, /lt lfg; Aufbaufehler öffnet Blizzards); Suche nur auf Klick mit
-- eigenem Sprachfilter, Liste, Filter, Detail, Flüstern/Einladen, eigener Eintrag. Todesminen (36): Quest 167 (Beute von NPC 626).
local L = addon.L
local LFGWindow = addon.LFGWindow

wow.login({ level = 22 })
wow.state.questTitles[167] = "Die Bruderschaft"
-- minLevelSuggestion = Blizzards (Classic-)Vorschlag; Level-Spannen und Sortierung kommen aus den Forever-Daten
-- (InstanceInfo): Todesminen 18-23, Schattenfang 22-30, Versunkener Tempel 50-60
wow.state.lfgActivities = {
  [900] = { mapID = 36, maxNumPlayers = 5, fullName = "Die Todesminen", shortName = "Todesminen", categoryID = 2,
    minLevelSuggestion = 15, maxLevelSuggestion = 24 },
  [901] = { mapID = 33, maxNumPlayers = 5, fullName = "Burg Schattenfang", shortName = "Schattenfang", categoryID = 2,
    minLevelSuggestion = 30, maxLevelSuggestion = 38 },
  [902] = { mapID = 109, maxNumPlayers = 5, fullName = "Versunkener Tempel", shortName = "Versunkener Tempel",
    categoryID = 2, minLevelSuggestion = 40, maxLevelSuggestion = 47 },
}
wow.state.lfgResults = {
  [7] = {
    { name = "Brakkus", level = 23, areaName = "Westfall", classFilename = "WARRIOR", assignedRole = "TANK", isLeader = true },
    { name = "Jaina", level = 20, classFilename = "MAGE", assignedRole = "DAMAGER" },
  },
  [8] = { { name = "Garrosh", level = 22, classFilename = "WARRIOR", lfgRoles = { tank = true, healer = false, dps = true } } },
  [9] = { { name = "Zu hoch", level = 40 } },
}
wow.state.lfgInfo = { [7] = { activityIDs = { 900 }, leaderName = "Brakkus", comment = "Nur Dungeonquests", age = 125,
    generalPlaystyle = 0 },  -- 0 = Enum.LFGEntryGeneralPlaystyle.None
  [8] = { activityIDs = { 900 }, leaderName = "Garrosh", age = 30 }, [9] = { activityIDs = { 900 }, leaderName = "Zu hoch", age = 5 } }
wow.state.lfgMemberCounts = { [7] = { TANK = 1, HEALER = 0, DAMAGER = 1 } }
wow.state.lfgWindow = { categories = { [2] = "Dungeons" }, activities = { [2] = { 900, 901, 902 } }, filtered = { 7, 8, 9 } }
wow.state.lfgLanguages = { filter = { enUS = true, deDE = true }, available = { "enUS", "deDE" }, defaults = { enUS = true } }

-- Dungeonliste nach Level aufsteigend, ohne Levelangabe ganz am Ende (unabhängig von der Reihenfolge der Blizzard-IDs)
wow.state.lfgActivities[903] = { mapID = 1, fullName = "Ohne Level", shortName = "Ohne Level", categoryID = 2 }
wow.state.lfgWindow.activities[2] = { 903, 902, 900, 901 }
local order = {}
for _, activity in ipairs(addon.LFGSearch.Activities(2)) do table.insert(order, activity.id) end
expect("Dungeonliste aufsteigend nach Level", table.concat(order, ","), "900,901,902,903")
wow.state.lfgActivities[903] = nil
wow.state.lfgWindow.activities[2] = { 900, 901, 902 }

local parts = LFGWindow.Parts()
local function click(button) button._scripts.OnClick(button, "LeftButton") end

-- Blizzards Fenster bleibt unberührt: Taste (Umschalten mit Reiter), Minikarten-Auge und Wer öffnen nur Blizzards
LFGVanilla_ToggleFrame(1)
expect("Blizzard: Umschalten öffnet", LFGParentFrame:IsShown(), true)
expect("Blizzard: eigenes Fenster bleibt zu", LFGWindow.IsShown(), false)
LFGVanilla_ToggleFrame(1)
expect("Blizzard: zweites Umschalten schließt", LFGParentFrame:IsShown(), false)
LFGVanilla_ToggleFrame()
LFGVanilla_ShowFrame(3)
expect("Blizzard: Reiter Wer", LFGParentFrame.selectedTab, 3)
expect("Blizzard: Wer offen, eigenes zu", LFGParentFrame:IsShown() and not LFGWindow.IsShown(), true)
LFGVanilla_ToggleFrame()
expect("Blizzard: Auge schließt", LFGParentFrame:IsShown(), false)

-- Minikarten-Icon (Standard an) schaltet unser Fenster um
local minimapButton = LFGWindow.minimapButton
expect("Minikarten-Icon sichtbar", minimapButton:IsShown(), true)
click(minimapButton)
expect("Icon öffnet", LFGWindow.IsShown(), true)
expect("Reiter Suchen gewählt", LFGWindow.panel.selectedTab, LFGWindow.TAB_SEARCH)
click(minimapButton)
expect("Icon schließt", LFGWindow.IsShown(), false)
addon.Set("lfgMinimapButton", false)
expect("Icon ausgeschaltet", minimapButton:IsShown(), false)
addon.Set("lfgMinimapButton", true)
expect("Icon wieder an", minimapButton:IsShown(), true)

-- /lt lfg schaltet um, der Knopf an Blizzards Fenster schließt dessen Fenster und öffnet unseres
SlashCmdList.LEVELTIMER("lfg")
expect("/lt lfg öffnet", LFGWindow.IsShown(), true)
SlashCmdList.LEVELTIMER("lfg")
expect("/lt lfg schließt", LFGWindow.IsShown(), false)
-- LT-351: Seitenreiter an Blizzards Fenster (nur Starter), unter LFG Forever, falls installiert
local function mouseUp(tab) tab._scripts.OnMouseUp(tab, "LeftButton", true) end
local blizzardTab = LFGWindow.blizzardTab
expect("Seitenreiter an Blizzards Fenster", blizzardTab:GetParent(), LFGParentFrame)
LFGForeverBlizzardTab = CreateFrame("Frame")
local foreverClicks = { 0 }
LFGForeverBlizzardTab:SetScript("OnMouseUp", function() foreverClicks[1] = foreverClicks[1] + 1 end)
LFGVanilla_ShowFrame(2)
local tabAnchor = { blizzardTab:GetPoint(1) }
expect("unter dem Reiter von LFG Forever", tabAnchor[2], LFGForeverBlizzardTab)
expect("Blizzards Reiter bleibt gewählt", LFGParentFrame.selectedTab, 2)
wow.state.combatLockdown = true
mouseUp(blizzardTab)
expect("im Kampf: Blizzards Fenster bleibt", LFGParentFrame:IsShown(), true)
expect("im Kampf: eigenes Fenster trotzdem offen", LFGWindow.IsShown(), true)
wow.state.combatLockdown = nil
LFGWindow.Hide()
mouseUp(blizzardTab)
expect("Reiter: Blizzards Fenster zu", LFGParentFrame:IsShown(), false)
expect("Reiter: eigenes Fenster offen", LFGWindow.IsShown(), true)
-- Gleiche Seitenleiste an unserem Fenster: Blizzards Reiter, LFG Forever, unserer
local sideTabs = LFGWindow.sideTabs
expect("Seitenleiste: fünf Reiter", #sideTabs, 5)
expect("LFG Forever sichtbar, wenn installiert", LFGWindow.lfgForeverSideTab:IsShown(), true)
expect("erster Reiter rechts am Fenster", ({ sideTabs[1]:GetPoint(1) })[2], LFGWindow.panel)
mouseUp(LFGWindow.lfgForeverSideTab)
expect("LFG Forever über dessen Reiter geöffnet", foreverClicks[1], 1)
expect("LFG Forever: eigenes Fenster zu", LFGWindow.IsShown(), false)
LFGWindow.Show()
wow.state.combatLockdown = true
mouseUp(sideTabs[3])
expect("im Kampf kein Blizzard-Fenster", LFGParentFrame:IsShown(), false)
wow.state.combatLockdown = nil
mouseUp(sideTabs[3])
expect("Reiter Wer öffnet Blizzards Fenster", LFGParentFrame.selectedTab, 3)
expect("Reiter Wer schließt unseres", LFGWindow.IsShown(), false)
LFGForeverBlizzardTab = nil
LFGParentFrame:Hide()
LFGWindow.Show()
expect("ohne LFG Forever kein Reiter", LFGWindow.lfgForeverSideTab:IsShown(), false)

-- Scheitert der Aufbau, öffnet Blizzards Fenster statt keinem
LFGWindow.Hide()
local realRefresh = LFGWindow.Refresh
LFGWindow.Refresh = function() error("Aufbau kaputt") end
click(minimapButton)
LFGWindow.Refresh = realRefresh
expect("Fehler: eigenes Fenster zu", LFGWindow.IsShown(), false)
expect("Fehler: Blizzards Fenster offen", LFGParentFrame:IsShown(), true)
LFGParentFrame:Hide()
click(minimapButton)
expect("danach öffnet es wieder", LFGWindow.IsShown(), true)
expect("vor der Suche: Hinweis", parts.emptyText:GetText(), L.LFG_STATE_START)
expect("vor der Suche keine Suche", #wow.lfgCalls, 0)

-- Suche nur auf Klick, mit eigenem Sprachfilter (Pflichtsprache enUS plus Chip deDE aus Blizzards Filter)
click(parts.searchButton)
local call = wow.lfgCalls[1]
expect("Suche aufgerufen", call[1], "Search")
expect("Kategorie", call[2], 2)
expect("Sprachfilter enthält Chip", call[5].deDE, true)
expect("Aktivitäten der Kategorie", #call[8], 3)
expect("Suchlauf zeigt Hinweis", parts.emptyText:GetText(), L.LFG_STATE_SEARCHING)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
expect("Ergebnisse blenden den Suchhinweis aus", parts.emptyText:GetText(), "")
expect("kein Seitenfenster ohne Auswahl", parts.detail:IsShown(), false)

-- Ergebnis trifft schon während Search ein (vor dem Zurückkehren): Hinweis bleibt nicht stehen
local realSearch = C_LFGList.Search
C_LFGList.Search = function(...)
  realSearch(...)
  wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
end
click(parts.searchButton)
C_LFGList.Search = realSearch
expect("Ereignis während Search: fertig", LFGWindow.State().status, "done")
expect("Ereignis während Search: kein Hinweis", parts.emptyText:GetText(), "")

-- Aktivitätsliste: nach Level aufsteigend, mit Level-Spanne
local activityEntries = parts.activityDropdown.entriesFn()
expect("Alle zuerst", activityEntries[1].key, 0)
expect("niedrigste Spanne zuerst", activityEntries[2].key, 900)
expect("dann nach Mindestlevel", activityEntries[3].key, 901)
expect("höchste zuletzt", activityEntries[4].key, 902)
expectTrue("Spanne im Text", activityEntries[4].text:find("(50 - 60)", 1, true) ~= nil)
-- LT-326: allein unterwegs zuerst der Abschnitt Gruppen, dann Einzelspieler (je neueste zuerst)
expect("Kopf Gruppen", parts.rows[1].section, "groups")
expect("Gruppen-Kopf mit Zahl", parts.rows[1].sectionLabel:GetText(), L.LFG_KIND_GROUPS .. " (1)")
expect("Gruppe unter dem Kopf", parts.rows[2].resultID, 7)
expect("Kopf Einzelspieler", parts.rows[3].section, "solo")
expect("neuester Einzelspieler zuerst", parts.rows[4].resultID, 9)
expect("Garrosh danach", parts.rows[5].resultID, 8)
expect("nicht mehr Zeilen", parts.rows[6] == nil or not parts.rows[6]:IsShown(), true)
expectTrue("Leiter als Titel", parts.rows[2].title:GetText():find("Brakkus", 1, true) ~= nil)
expectTrue("Krone bei Gruppen", parts.rows[2].title:GetText():find("groupfinder-icon-leader", 1, true) ~= nil)
expectTrue("keine Krone bei Einzelspielern", parts.rows[5].title:GetText():find("groupfinder-icon-leader", 1, true) == nil)
expectTrue("Aktivität mit Level-Spanne", parts.rows[2].activity:GetText():find("20-23", 1, true) ~= nil)
expectTrue("Kommentar ohne Spielstil", parts.rows[2].comment:GetText():find("Nur Dungeonquests", 1, true) ~= nil)
expectTrue("Einzelspieler zeigt Rollen", parts.rows[5].roles:GetText():find("tank", 1, true) ~= nil)
expectTrue("Rolle je Mitglied", parts.rows[2].roles:GetText():find("dps", 1, true) ~= nil)
-- LT-305: Karten wie Blizzard: freie Plätze als leere Symbole (2 von 5 belegt), Kopf und Karte verschieden hoch
local _, emptySlots = parts.rows[2].roles:GetText():gsub("groupfinder%-icon%-emptyslot", "")
expect("drei freie Plätze", emptySlots, 3)
expectTrue("Karte höher als Kopf", parts.rows[2]:GetHeight() > parts.rows[1]:GetHeight())
expect("Kopf ohne Kartenteile", parts.rows[1].title:IsShown(), false)
expect("Karte ohne Kopfteile", parts.rows[2].sectionLabel:IsShown(), false)
-- Ohne Auswahl: Flüstern und Einladen unten im Fenster aus, kein Seitenfenster
expect("ohne Auswahl kein Flüstern", parts.whisperButton:IsEnabled(), false)
expect("ohne Auswahl kein Einladen", parts.inviteButton:IsEnabled(), false)
expect("Flüstern unten im Fenster", parts.whisperButton:GetParent(), LFGWindow.searchContainer)
expect("keine Karte gewählt", parts.rows[2].selected, false)
-- In einer Gruppe sucht man Leute: Einzelspieler oben
wow.state.inGroup = true
LFGWindow.Refresh()
expect("in Gruppe: Einzelspieler oben", parts.rows[1].section, "solo")
wow.state.inGroup = nil
LFGWindow.Refresh()
-- Abschnitt einklappen und wieder aufklappen
parts.rows[3]._scripts.OnClick(parts.rows[3], "LeftButton")
expect("eingeklappt: Kopf bleibt", parts.rows[3].section, "solo")
expect("eingeklappt: Karten weg", parts.rows[4]:IsShown(), false)
expect("eingeklappt: Zeichen", parts.rows[3].collapsed, true)
expect("eingeklappt: Zahl zählt alle", #LFGWindow.State().results, 3)
parts.rows[3]._scripts.OnClick(parts.rows[3], "LeftButton")
expect("aufgeklappt", parts.rows[4].resultID, 9)
expect("aufgeklappt: Zeichen", parts.rows[3].collapsed, false)

-- "Passend für mich": Level 40 passt nicht zu Level 22; Aktivitäten nach Level-Spanne (Todesminen und Schattenfang),
-- Suche nur mit passenden
parts.fitCheck:SetChecked(true)
parts.fitCheck._scripts.OnClick(parts.fitCheck)
expect("Passend: nur Aktivitäten zum Level", #parts.activityDropdown.entriesFn(), 3)
expect("Passend: Todesminen", parts.activityDropdown.entriesFn()[2].key, 900)
wow.lfgCalls = {}
click(parts.searchButton)
expect("Passend: Suche nur mit passenden Aktivitäten", #wow.lfgCalls[1][8], 2)
expect("Passend: Aktivität 900", wow.lfgCalls[1][8][1], 900)
wow.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
expect("Passend: Level 40 weg", parts.rows[4].resultID, 8)
expect("Passend: nur vier Zeilen", parts.rows[5]:IsShown(), false)
parts.fitCheck:SetChecked(false)
parts.fitCheck._scripts.OnClick(parts.fitCheck)
expect("ohne Filter wieder fünf Zeilen", parts.rows[5]:IsShown(), true)

-- LT-347: Trefferzahl getrennt nach Gruppen und Einzelspielern, Abschnittskopf mit Tooltip
expect("Zahl getrennt", parts.countText:GetText(), string.format(L.LFG_COUNT_SPLIT, 1, 2))
parts.rows[1]._scripts.OnEnter(parts.rows[1])
expectTrue("Kopf erklärt Einklappen", table.concat(GameTooltip._lines or {}, " "):find(L.LFG_SECTION_TIP, 1, true) ~= nil)

-- Weitere Filter: eigene Ansicht an Stelle der Liste, Art als Auswahlliste, Sprachen als Kästchen
click(parts.moreButton)
local view = parts.filterView.parts
expect("Filteransicht offen", parts.filterView.frame:IsShown(), true)
expect("Liste weg bei offenen Filtern", parts.rows[1]:IsShown(), false)
expect("kein Suchhinweis über den Filtern", parts.emptyText:GetText(), "")
expect("Pflichtsprache nicht abwählbar", view.languageChecks[1]:IsEnabled(), false)
expect("Sprache als Haken", view.languageChecks[2]:GetChecked(), true)
view.languageChecks[2]:SetChecked(false)
view.languageChecks[2]._scripts.OnClick(view.languageChecks[2])
expect("Sprache abgewählt", addon.LFGSearch.Languages()[2].enabled, false)
view.languageChecks[2]:SetChecked(true)
view.languageChecks[2]._scripts.OnClick(view.languageChecks[2])
view.kindDropdown.pick("groups")
expectTrue("Weitere Filter zählt Sprache und Art", parts.moreButton:GetText():find("(2)", 1, true) ~= nil)
click(parts.moreButton)
expect("Filteransicht zu", parts.filterView.frame:IsShown(), false)
expect("nur Gruppen: Kopf und eine Karte", parts.rows[3]:IsShown(), false)
expect("nur Gruppen: Gruppe 7", parts.rows[2].resultID, 7)
view.kindDropdown.pick("solo")
expect("nur Einzelspieler: Kopf Einzelspieler oben", parts.rows[1].section, "solo")
expect("nur Einzelspieler: Gruppe 7 weg", parts.rows[4]:IsShown(), false)
view.kindDropdown.pick("all")

-- Mit Treffern schließen und wieder öffnen (LT-309: die Titel-Farbe warf hier, das Fenster blieb zu)
LFGWindow.Hide()
click(minimapButton)
expect("mit Treffern wieder offen", LFGWindow.IsShown(), true)
expectTrue("Titel-Farbe gesetzt", parts.rows[2].title._textColor[3] ~= nil)

-- Layout: die Filterzeile liegt unter dem Porträtring am linken Rand, jede Zeile hängt an der vorigen
local function anchorOf(frame)
  local point, relative, relativePoint, x, y = unpack(frame._points[#frame._points])
  return { point = point, relative = relative, relativePoint = relativePoint, x = x or 0, y = y or 0 }
end
local fitAnchor = anchorOf(parts.fitCheck)
-- parts.categoryDropdown ist die des Reiters Eigene Gruppe; die Aktivität hängt rechts an der Kategorie der Suche
local searchCategory = anchorOf(parts.activityDropdown).relative
expect("Kategorie am linken Rand", anchorOf(searchCategory).x, LFGWindow.PAD)
expectTrue("Kategorie unter dem Porträt", anchorOf(searchCategory).y <= -60)
expectTrue("Passend unter der Kategorie", fitAnchor.relative == searchCategory
  and fitAnchor.relativePoint == "BOTTOMLEFT" and fitAnchor.x == 0 and fitAnchor.y < 0)
local moreAnchor = anchorOf(parts.moreButton)
expectTrue("Weitere Filter unter Suchen", moreAnchor.relative == parts.searchButton and moreAnchor.y < 0)
expectTrue("Kopf unter Weitere Filter", anchorOf(parts.header).relative == parts.moreButton)
expectTrue("Filteransicht unter dem Kopf", anchorOf(parts.filterView.frame).relative == parts.header)
-- Viele Sprachen: Kästchen brechen um und bleiben in der Breite
wow.state.lfgLanguages.available = { "enUS", "deDE", "frFR", "esES", "ruRU", "ptBR", "itIT", "koKR", "zhCN", "zhTW",
  "esMX", "ptPT", "enGB", "nlNL" }
click(parts.moreButton)
local filterWidth = LFGWindow.WIDTH - 2 * LFGWindow.PAD
local wrapped, firstY = false, nil
for _, check in ipairs(view.languageChecks) do
  local anchor = anchorOf(check)
  firstY = firstY or anchor.y
  expectTrue("Kästchen in der Breite", anchor.x + 28 + check.label:GetStringWidth() <= filterWidth)
  wrapped = wrapped or anchor.y < firstY
end
expect("Kästchen brechen um", wrapped, true)
wow.state.lfgLanguages.available = { "enUS", "deDE" }
click(parts.moreButton)

-- Detail: Mitglieder, Quest, Aktionen
parts.rows[2]._scripts.OnClick(parts.rows[2], "LeftButton")
expect("Gruppe gewählt", LFGWindow.State().selected, 7)
expect("Karte markiert", parts.rows[2].selected, true)
expect("andere Karte nicht markiert", parts.rows[5].selected, false)
expect("mit Auswahl Flüstern an", parts.whisperButton:IsEnabled(), true)
expect("Seitenfenster bei Auswahl", parts.detail:IsShown(), true)
local text = parts.detailText:GetText()
expectTrue("Detail: Mitglied", text:find("Brakkus", 1, true) ~= nil)
expectTrue("Detail: Quest", text:find("Die Bruderschaft", 1, true) ~= nil)
expect("Detail: Alter als Label-Wert", parts.detailFields.age.value:GetText(), "2m 05s")
expectTrue("Detail: Level-Spanne", parts.detailFields.level.value:GetText():find("20-23", 1, true) ~= nil)
click(parts.whisperButton)
expect("Flüstern an den Leiter", wow.socialActions[#wow.socialActions][2], "Brakkus")
expect("Gruppe nicht einladbar", parts.inviteButton:IsEnabled(), false)
parts.rows[5]._scripts.OnClick(parts.rows[5], "LeftButton")
expect("Einzelspieler einladbar", parts.inviteButton:IsEnabled(), true)
click(parts.inviteButton)
expect("Einladung", wow.socialActions[#wow.socialActions][1], "invite")
expect("Einladung an den Leiter", wow.socialActions[#wow.socialActions][2], "Garrosh")

-- Eigene Gruppe: eintragen, aktualisieren, austragen
LFGWindow.SetTab(1)
expect("kein Eintrag", parts.listingStatus:GetText(), L.LFG_LISTING_NONE)
expect("ohne Aktivität kein Eintragen", parts.postButton:IsEnabled(), false)
expect("Kategorie vorbelegt", LFGWindow.State().listingCategoryID, 2)
expect("Liste nur mit passender Aktivität", parts.activityRows[1].activityID, 900)
expect("Liste: Schattenfang passt auch", parts.activityRows[2].activityID, 901)
expect("Liste: dritte Zeile leer", parts.activityRows[3]:IsShown(), false)
parts.allLevelsCheck:SetChecked(true)
parts.allLevelsCheck._scripts.OnClick(parts.allLevelsCheck)
expect("Alle Stufen: niedrigste Spanne zuerst", parts.activityRows[1].activityID, 900)
expect("Alle Stufen: Spanne rechts", parts.activityRows[3].level:GetText(), "(50 - 60)")
expect("Alle Stufen: drei Zeilen", parts.activityRows[3].activityID, 902)
parts.activityRows[1]._scripts.OnClick(parts.activityRows[1], "LeftButton")
expect("Aktivität gewählt", LFGWindow.State().listingActivities[900], true)
expect("ohne Spielstil kein Eintragen", parts.postButton:IsEnabled(), false)
parts.playstyleDropdown.pick(1)
expect("mit Spielstil eintragbar", parts.postButton:IsEnabled(), true)
parts.roleChecks.TANK:SetChecked(true)
parts.newPlayerCheck:SetChecked(true)
wow.lfgCalls = {}
click(parts.postButton)
expect("Rollen gesetzt", wow.lfgCalls[1][1], "SetRoles")
expect("Rolle Tank", wow.lfgCalls[1][2].tank, true)
expect("Eintrag erstellt", wow.lfgCalls[2][1], "CreateListing")
expect("Aktivität im Eintrag", wow.lfgCalls[2][2].activityIDs[1], 900)
expect("einsteigerfreundlich", wow.lfgCalls[2][2].newPlayerFriendly, true)
expect("Spielstil im neuen Eintrag", wow.lfgCalls[2][2].generalPlaystyle, 1)
expect("Voicechat im Eintrag", wow.lfgCalls[2][2].voiceMode, nil)
wow.state.lfgWindow.entry = { activityIDs = { 900 }, newPlayerFriendly = true }
wow.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
expectTrue("Status nennt die Aktivität", parts.listingStatus:GetText():find("Todesminen", 1, true) ~= nil)
wow.lfgCalls = {}
click(parts.postButton)
expect("Eintrag aktualisiert", wow.lfgCalls[2][1], "UpdateListing")
expect("Aktualisierung ohne Spielstil", wow.lfgCalls[2][2].generalPlaystyle, nil)
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
expect("Mausrad endet am Listenende", LFGWindow.State().offset, #LFGWindow.State().lines - 5)  -- in Gruppe: 3 Karten, Kopf Gruppen, 1 Karte

-- Zurück wechselt zur Suche, Seitenfenster gehört zur Suche
LFGWindow.State().selected = 7
LFGWindow.SetTab(1)
expect("Seitenfenster nur im Reiter Suchen", parts.detail:IsShown(), false)
click(parts.backButton)
expect("Zurück öffnet die Suche", LFGWindow.State().tab, 2)

expect("keine Lua-Fehler", #wow.errors, 0)
