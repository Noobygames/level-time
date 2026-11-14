-- Roadmap 493: Dungeon- und Raid-Runs in Classic Era: Splits je Boss, Gruppe, Geld und Quests im Journal, Bestzeit
-- als Vergleich, Chat "neue Bestzeit", Live-Tracker und Run-Fenster
local Instances = addon.Instances
local Runs = addon.InstanceRuns
local Stats = addon.Stats
local L = addon.L

local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
local SHADOWFANG = { name = "Burg Schattenfang", type = "party", difficulty = 1, mapID = 33, maxPlayers = 5 }

local function enter(instance)
  wow.state.instance = instance
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function printedContains(from, text)
  for i = from + 1, #wow.printed do
    if wow.printed[i]:find(text, 1, true) then return true end
  end
  return false
end

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.groupSize = 3
enter(DEADMINES)
wow.state.groupSize = 5
local run = Instances.GetCurrentRun()
wow.advance(100)
wow.fire("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 1)
wow.advance(200)
addon.Journal.AddKill("pve", "Edwin van Cleef", "elite", 300)
Stats.Increment(Stats.MONEY_EARNED, 500)
Stats.Increment(Stats.QUESTS, 2)
local printedBefore = #wow.printed
wow.fire("ENCOUNTER_END", 2747, "Edwin van Cleef", 1, 5, 1)
expect("Splits je Boss", run.splits, "100,300")
expect("größte Gruppe", run.groupSize, 5)
expectTrue("erster Lauf: keine neue Bestzeit", not printedContains(printedBefore, L.DUNGEON_RUN_NEW_BEST))
expect("Split je Boss gelesen", Runs.Splits(run)[2747], 300)

-- Andere Instanz beendet den Lauf: Journal mit Splits, Geld, Quests, Gruppe
enter(SHADOWFANG)
local log = addon.character.instanceLog
local first = log[#log]
expect("Journal: Splits", first.splits, "100,300")
expect("Journal: Geld", first.counters.money, 500)
expect("Journal: Quests", first.counters.quests, 2)
expect("Journal: Gruppe", first.groupSize, 5)
expectTrue("erster Lauf abgeschlossen", Runs.IsCompleted(first))

-- Zweiter Lauf schneller: Vergleich mit der Bestzeit, Chat meldet die neue Bestzeit
enter(DEADMINES)
run = Instances.GetCurrentRun()
wow.advance(90)
wow.fire("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 1)
local records = addon.History.GetInstanceLog(addon.characterKey)
expect("Bestzeit = erster Lauf", Runs.Reference(records, 1, Runs.BEST).time, first.time)
expect("letzter Lauf derselben Instanz", Runs.Reference(records, 1, Runs.LAST).time, first.time)

-- Live-Tracker: Abstand zur Bestzeit beim letzten Boss (90 gegen 100 Sekunden)
addon.Set("showRunTracker", true)
addon.InstanceRunTracker.Refresh()
local card = addon.InstanceRunTracker.Card()
expectTrue("Tracker in der Instanz sichtbar", card.frame:IsShown())
expectTrue("Tracker zeigt die Bosse", card.frame.body:GetText():find("Rhahk'Zor", 1, true) ~= nil)
expectTrue("Tracker zeigt den Abstand", card.frame.time:GetText():find("-10", 1, true) ~= nil)
-- Porträt des nächsten Bosses (Rhahk'Zor besiegt -> zweiter Boss der Liste) über das Modell
local _, trackerPortrait = addon.InstanceRunTracker.Card()
local nextNpc = addon.InstanceBosses.NpcID(addon.InstanceBosses.List(36, 1)[2])
expectTrue("NPC-ID des nächsten Bosses bekannt", nextNpc ~= nil)
expect("Tracker-Porträt: Modell des nächsten Bosses", trackerPortrait.model._creature, nextNpc)
expectTrue("Tracker-Porträt sichtbar", trackerPortrait:IsShown())

wow.advance(150)
printedBefore = #wow.printed
wow.fire("ENCOUNTER_END", 2747, "Edwin van Cleef", 1, 5, 1)
expectTrue("neue Bestzeit gemeldet", printedContains(printedBefore, L.DUNGEON_RUN_NEW_BEST))

-- Wurf in diesem Lauf, selbst gewonnen
local ownName = addon.characterKey:match("^([^-]+)")
addon.Journal.AddRoll({ link = "[Kapitänsmantel]", winner = ownName, ownChoice = "need", ownRoll = 87,
  runStart = run.startedAt })

-- Run-Fenster über /lt runs: offener Lauf vorne, Kacheln, Bosstabelle, Beute
SlashCmdList.LEVELTIMER("runs")
local Window = addon.InstanceRunWindow
expectTrue("Fenster offen", Window.IsShown())
local parts = Window.Parts()
expect("offener Lauf gewählt", parts.selected, run.startedAt)
expect("Kachel Bosse", parts.tiles[5].value:GetText(), "2/7")
expect("Porträt Rhahk'Zor (NPC 644)", parts.bossRows[1].portrait.npcID, 644)
expect("Porträt-Modell bekommt die NPC-ID", parts.bossRows[1].portrait.model._creature, 644)
expect("Endboss-Porträt im Kopf: Edwin van Cleef (NPC 639)", parts.endBossPortrait.npcID, 639)
-- Ohne Daten: Symbol statt Modell, ohne Fehler
local CreatureModel = addon.CreatureModel
local portrait = CreatureModel.Create(UIParent, 20)
CreatureModel.Set(portrait, addon.InstanceBosses.NpcID(999999))
expectTrue("ohne NPC-ID: Symbol", portrait.npcID == false and portrait.icon:IsShown() and portrait.model == false)
CreatureModel.Set(portrait, 644)
CreatureModel.Set(portrait, nil)
expectTrue("zurück auf Symbol", portrait.icon:IsShown() and not portrait.model:IsShown())
expectTrue("Bosstabelle: schneller als die Bestzeit", parts.bossRows[1].cells[4]:GetText():find("-10", 1, true) ~= nil)
expectTrue("Beute mit Wurf", parts.loot:GetText():find("[Kapitänsmantel]", 1, true) ~= nil
  and parts.loot:GetText():find(string.format(L.DUNGEON_RUNS_ROLL_WON, L.LOOT_ROLL_KIND_NEED), 1, true) ~= nil)

-- Älterer Lauf über die Liste: XP je Boss aus dem Kill-Journal, Geld-Kachel
Window.Show(addon.characterKey, first.time)
parts = Window.Parts()
expect("Kachel Gruppe", parts.tiles[8].value:GetText(), "5")
expect("XP von Edwin", parts.bossRows[7].cells[5]:GetText(), "300")
Window.SetCompare(Runs.LAST)
Window.SetFilter(Runs.RAID)
expect("Filter Raids: nichts gewählt", Window.Parts().selected, nil)

-- Edit-Modus-Vorschau ohne Lua-Fehler; draußen verschwindet der Tracker
addon.Frames.Preview("dungeonRun")
enter(nil)
addon.InstanceRunTracker.Refresh()
expect("keine Lua-Fehler", #wow.errors, 0)
