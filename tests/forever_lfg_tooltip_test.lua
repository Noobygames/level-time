-- WoW Forever: Level-Time-Block im Tooltip der Gruppensuche (Assist/LFGTooltip.lua, Daten Assist/LFGData.lua) und
-- Sprachfilter (Assist/LFGLanguages.lua). Retail-Stil hängt an GameTooltip an, Classic-Stil ergänzt Blizzards
-- eigenen Rahmen. Todesminen (36): Quest 166 (Beute von VanCleef, Boss), 167 (Beute von NPC 626), 174 (nur Objekte).
local L = addon.L
local LFGData = addon.LFGData

wow.login({ level = 22 })
local vanCleef = addon.InstanceBosses.Name(2747)
wow.state.questTitles[166] = "Das Ende der Bruderschaft"
wow.state.questTitles[167] = "Die Bruderschaft"
wow.state.lfgActivities = { [900] = { mapID = 36, maxNumPlayers = 5 } }
wow.state.lfgResults = {
  [7] = {
    { name = "Brakkus", level = 23, areaName = "Westfall", classFilename = "WARRIOR", assignedRole = "TANK", isLeader = true },
    { name = "Jaina", level = 20, classFilename = "MAGE", assignedRole = "DAMAGER" },
    { name = "Thrall", level = 21, areaName = "Durotar", classFilename = "MAGE", assignedRole = "DAMAGER" },
  },
  [8] = { { name = "Garrosh" } },
  [9] = { { name = "Level 5", level = 5 }, { name = "Level 40", level = 40 } },
  [10] = { { name = "Solo", level = 30 } },
  [11] = { { name = "Gleich A", level = 37 }, { name = "Gleich B", level = 37 } },
  [12] = { { name = "Spanne A", level = 37 }, { name = "Spanne B", level = 40 } },
}
wow.state.lfgInfo = { [7] = { activityIDs = { 900 }, numGuildMates = 1, numBNetFriends = 1 }, [9] = { isDelisted = true } }
wow.state.lfgEncounters = { [7] = { vanCleef } }
wow.state.lfgMemberCounts = { [7] = { TANK = 1, HEALER = 0, DAMAGER = 2 } }

local function lines() return table.concat(GameTooltip._lines, "\n") end
local function has(text) return lines():find(text, 1, true) ~= nil end

LFGListUtil_SetSearchEntryTooltip(GameTooltip, 7)
expect("Blizzard-Zeile zuerst", GameTooltip._lines[1], "Gruppe 7")
expect("Überschrift", GameTooltip._lines[3], addon.DISPLAY_NAME)
expectTrue("Mitglied mit Rolle, Level und Zone", has("Brakkus - " .. L.LFG_ROLE_TANK .. " = 23 · Westfall"))
expectTrue("Mitglied ohne Zone nur mit Level", has("Jaina - " .. L.LFG_ROLE_DAMAGER .. " = 20"))
expectTrue("Level-Spanne und Passung", has(string.format(L.LFG_LEVELS, "20-23") .. " = " .. string.format(L.LFG_FIT_OK, 22)))
expectTrue("offener Heiler", has(string.format(L.LFG_OPEN, "1 " .. L.LFG_ROLE_HEALER)))
expectTrue("besiegter Boss", has(string.format(L.LFG_BOSSES_KILLED, vanCleef)))
expectTrue("Freunde und Gilde", has(string.format(L.LFG_SOCIAL, 1, 1)))
expectTrue("Quest mit besiegtem Boss", has("Das Ende der Bruderschaft = " .. L.LFG_QUEST_BOSS_DEAD))
expectTrue("Quest ohne Boss machbar", has("Die Bruderschaft = " .. L.LFG_QUEST_DOABLE))
expect("kein Abstand von 13 Leveln", has(string.format(L.LFG_NO_XP, 20, 23)), false)

-- Passung und Erfahrungs-Regel (reine Daten)
local members9 = LFGData.Members(9, 2)
expect("Level-Spanne", select(2, LFGData.LevelRange(members9)), 40)
expect("zu niedrig", LFGData.Fit(2, 5, 8), LFGData.BELOW)
expect("zu hoch", LFGData.Fit(20, 5, 8), LFGData.ABOVE)
expect("knapp daneben passt noch", LFGData.Fit(10, 5, 8), LFGData.FITS)
expect("13 Level Abstand", LFGData.NoExperience(members9, 22), 5)
expect("12 Level Abstand", LFGData.NoExperience({ { level = 10 }, { level = 22 } }, 15), nil)
expect("eigener Charakter zählt mit", LFGData.NoExperience({ { level = 10 }, { level = 12 } }, 23), 10)
LFGListUtil_SetSearchEntryTooltip(GameTooltip, 9)
expectTrue("Warnung vor fehlender Erfahrung", has(string.format(L.LFG_NO_XP, 5, 40)))
expectTrue("aufgelöst", has(L.LFG_DELISTED))

-- Gruppe ohne bekannte Mitglieder: kein Block (nur Blizzards Zeile); abgeschaltet: auch nicht
LFGListUtil_SetSearchEntryTooltip(GameTooltip, 99)
expect("unbekannte Gruppe ohne Block", #GameTooltip._lines, 1)
addon.Set("lfgTooltip", false)
LFGListUtil_SetSearchEntryTooltip(GameTooltip, 7)
expect("abgeschaltet ohne Block", #GameTooltip._lines, 1)
addon.Set("lfgTooltip", true)

-- Classic-Stil: Blizzards Rahmen wird ergänzt (Zone je Zeile, eigene Zeilen unten), kein GameTooltip-Block
local tip = LFGBrowseSearchEntryTooltip
GameTooltip:Hide()
LFGBrowseSearchEntryTooltip_UpdateAndShow(tip, 7)
expect("Classic: GameTooltip bleibt aus", GameTooltip:IsShown(), false)
local function zoneOf(row) return addon.LFGTooltip.RowZone(row) end
expect("Zone beim Leader", zoneOf(tip.Leader):GetText(), "Westfall")
local _, zoneAnchor = zoneOf(tip.Leader):GetPoint(1)
expect("Zone hängt an der eigenen Zeile, nicht an der Rahmenmitte", zoneAnchor, tip.Leader.Name)
local zones = {}
for row in tip.memberPool:EnumerateActive() do
  local zone = zoneOf(row)
  zones[#zones + 1] = zone and zone:IsShown() and zone:GetText() or "-"
end
expect("Zonen der Mitglieder", table.concat(zones, ","), "-,Durotar")
local texts = table.concat(addon.LFGTooltip.BlockTexts(tip), " | ")
expectTrue("Classic: Level-Spanne und Passung", texts:find(string.format(L.LFG_LEVELS, "20-23"), 1, true) ~= nil)
expectTrue("Classic: offener Heiler", texts:find(string.format(L.LFG_OPEN, "1 " .. L.LFG_ROLE_HEALER), 1, true) ~= nil)
expectTrue("Classic: Freunde und Gilde", texts:find(string.format(L.LFG_SOCIAL, 1, 1), 1, true) ~= nil)
expect("Classic: keine Mitglieder doppelt", texts:find("Brakkus", 1, true), nil)
expect("Classic: keine Bosse doppelt", texts:find(vanCleef, 1, true), nil)
local grown = tip:GetHeight()
expectTrue("Rahmen wächst um den Block", grown > 100)
expectTrue("Rahmen wird breiter für Zone und Zeilen", tip:GetWidth() > 150)
LFGBrowseSearchEntryTooltip_UpdateAndShow(tip, 7)
expect("zweiter Aufruf wächst nicht doppelt", tip:GetHeight(), grown)
LFGBrowseSearchEntryTooltip_UpdateAndShow(tip, 8)
expect("Gruppe ohne Block: Blizzards Höhe", tip:GetHeight(), 100)
expect("Gruppe ohne Block: keine Zeilen", #addon.LFGTooltip.BlockTexts(tip), 0)

-- Trefferliste: Level-Spanne, Punkt bei Freunden/Gilde, abgedunkelt bei aufgelöster Gruppe
local function entry(resultID)
  local frame = CreateFrame("Button")
  frame.ActivityName, frame.resultID = CreateFrame("Frame"), resultID
  LFGBrowseSearchEntry_Update(frame)
  return addon.LFGTooltip.EntryMarks(frame)
end
local marks7, marks9 = entry(7), entry(9)
expect("Level-Spanne in der Zeile", marks7.range._text, "20–23")
expect("Solo ohne Spanne", entry(10).range._text, "")
expect("Gruppe mit gleichem Level ohne Spanne", entry(11).range._text, "")
expect("Gruppe 37/40 als Spanne", entry(12).range._text, "37–40")
expect("Punkt bei Freunden", marks7.dot:IsShown(), true)
expect("nicht abgedunkelt", marks7.dim:IsShown(), false)
expect("aufgelöst abgedunkelt", marks9.dim:IsShown(), true)
expect("kein Punkt ohne Freunde", marks9.dot:IsShown(), false)
addon.Set("lfgTooltip", false)
expect("abgeschaltet ohne Markierungen", entry(7), nil)
addon.Set("lfgTooltip", true)

-- Sprachfilter: Auswahl DE+EN setzt genau diese Sprachen, Wiederherstellen bringt Blizzards Filter zurück
local function languages() return wow.state.lfgLanguages end
local function keys(filter)
  local list = {}
  for language in pairs(filter) do list[#list + 1] = language end
  table.sort(list)
  return table.concat(list, ",")
end
wow.state.lfgLanguages = { filter = { frFR = true }, available = { "enUS", "deDE", "frFR" }, defaults = {} }
addon.LFGLanguages.Toggle("deDE", true)
addon.LFGLanguages.Toggle("enUS", true)
addon.LFGLanguages.Toggle("frFR", false)
expect("genau die gewählten Sprachen", keys(languages().filter), "deDE,enUS")
local saves = languages().saved
addon.ApplySettings()
expect("Apply ändert nichts mehr", languages().saved, saves)
addon.LFGLanguages.Restore()
expect("Blizzard-Filter zurück", keys(languages().filter), "frFR")
expect("Auswahl verworfen", addon.db.lfgLanguages, false)
expect("keine Sicherung mehr", addon.db.lfgLanguageBackup, false)

-- Standardsprachen sind immer im gespeicherten Filter
wow.state.lfgLanguages = { filter = { enUS = true }, available = { "enUS", "deDE" }, defaults = { enUS = true } }
addon.LFGLanguages.Toggle("deDE", true)
addon.LFGLanguages.Toggle("deDE", false)
expect("Standardsprache bleibt im Filter", keys(languages().filter), "enUS")
addon.LFGLanguages.Restore()
wow.state.lfgLanguages = { filter = { frFR = true }, available = { "enUS", "deDE", "frFR" }, defaults = {} }

-- Migration: alter Schalter "alle Sprachen" wählt alle verfügbaren Sprachen
addon.db.lfgAllLanguages = true
wow.login()
expect("alle Sprachen gewählt", keys(languages().filter), "deDE,enUS,frFR")
expect("alter Schalter entfernt", addon.db.lfgAllLanguages, nil)

-- Reiter in den Einstellungen
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Gruppensuche", wow.click(L.OPTIONS_TAB_LFG))
expectTrue("Schalter Sprache", wow.click(L.LFG_LANGUAGE_DEDE))
expectTrue("Knopf Wiederherstellen", wow.click(L.LFG_LANGUAGES_RESTORE))
expect("keine Lua-Fehler", #wow.errors, 0)
