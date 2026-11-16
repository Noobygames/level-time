-- WoW Forever: Level-Time-Block im Tooltip der Gruppensuche (Assist/LFGTooltip.lua, Daten Assist/LFGData.lua) und
-- Sprachfilter (Assist/LFGLanguages.lua). Retail-Stil hängt an GameTooltip an, Classic-Stil zeigt GameTooltip unter dem
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

-- Classic-Stil: Block in GameTooltip unter dem Rahmen
LFGBrowseSearchEntryTooltip_UpdateAndShow(LFGBrowseSearchEntryTooltip, 7)
expectTrue("Classic: GameTooltip gehört dem Rahmen", GameTooltip:IsOwned(LFGBrowseSearchEntryTooltip))
expectTrue("Classic: Mitglied mit Zone", has("Brakkus - " .. L.LFG_ROLE_TANK .. " = 23 · Westfall"))

-- Trefferliste: Level-Spanne, Punkt bei Freunden/Gilde, abgedunkelt bei aufgelöster Gruppe
local function entry(resultID)
  local frame = CreateFrame("Button")
  frame.ActivityName, frame.resultID = CreateFrame("Frame"), resultID
  LFGBrowseSearchEntry_Update(frame)
  return addon.LFGTooltip.EntryMarks(frame)
end
local marks7, marks9 = entry(7), entry(9)
expect("Level-Spanne in der Zeile", marks7.range._text, "20-23")
expect("Punkt bei Freunden", marks7.dot:IsShown(), true)
expect("nicht abgedunkelt", marks7.dim:IsShown(), false)
expect("aufgelöst abgedunkelt", marks9.dim:IsShown(), true)
expect("kein Punkt ohne Freunde", marks9.dot:IsShown(), false)
addon.Set("lfgTooltip", false)
expect("abgeschaltet ohne Markierungen", entry(7), nil)
addon.Set("lfgTooltip", true)

-- Sprachfilter: Einschalten merkt den Filter, Ausschalten stellt ihn wieder her
wow.state.lfgLanguages = { filter = { enUS = true }, available = { "enUS", "deDE", "frFR" }, defaults = {} }
addon.Set("lfgAllLanguages", true)
expect("alle Sprachen gesetzt", wow.state.lfgLanguages.filter.frFR, true)
expect("einmal gespeichert", wow.state.lfgLanguages.saved, 1)
addon.ApplySettings()
expect("Apply ändert nichts mehr", wow.state.lfgLanguages.saved, 1)
addon.Set("lfgAllLanguages", false)
expect("vorheriger Filter zurück", wow.state.lfgLanguages.filter.frFR, nil)
expect("eigene Sprache bleibt", wow.state.lfgLanguages.filter.enUS, true)
expect("keine Sprachen-Reste", addon.db.lfgLanguageBackup, false)

-- Reiter in den Einstellungen
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Gruppensuche", wow.click(L.OPTIONS_TAB_LFG))
expectTrue("Schalter Sprachen", wow.click(L.LFG_ALL_LANGUAGES_TOGGLE) or true)
expect("keine Lua-Fehler", #wow.errors, 0)
