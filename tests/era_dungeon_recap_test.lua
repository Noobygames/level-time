-- LT-334 (Classic Era): Dungeon-Recap ohne Schadensmesser (C_DamageMeter gibt es dort nicht): das Fenster öffnet nach dem
-- Endboss, zeigt Kopf, Zeit, Auszeichnungen aus dem Journal und den Hinweis statt Zahlen; /lt recap run.
local Bosses = addon.InstanceBosses
local Window = addon.DungeonRecapWindow
local L = addon.L

local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }

wow.login({ level = 20, xp = 0, xpMax = 100000 })
expect("Era: kein Schadensmesser", C_DamageMeter, nil)
expectTrue("Messer nicht verfügbar", not addon.RunMeter.IsAvailable())

wow.state.instance = DEADMINES
wow.fire("PLAYER_ENTERING_WORLD")
local run = addon.Instances.GetCurrentRun()
wow.advance(100)
wow.fire("ENCOUNTER_END", 2741, "Rhahk'Zor", 1, 5, 1)
wow.advance(200)
wow.fire("ENCOUNTER_END", 2747, "Edwin van Cleef", 1, 5, 1)
expectTrue("Recap öffnet nach dem Endboss", Window.IsShown())
local parts = Window.Parts()
expectTrue("Kopf mit Endboss", parts.header.title:GetText():find(Bosses.Name(2747), 1, true) ~= nil)
expect("Endboss-Porträt (NPC 639)", parts.portrait.npcID, 639)
expect("Laufzeit", parts.duration:GetText(), addon.Format.Duration(300))
expect("ohne Zahlen: nichts gespeichert", run.recapPlayers, nil)
expect("Auszeichnung: schnellster Boss (Rhahk'Zor, 100 s)", parts.awardRows[1].label:GetText(), L.DUNGEON_RECAP_AWARD_FASTEST)
expectTrue("Hinweis statt Zahlen", parts.pages.overview:IsShown())
Window.SetTab("group")
expect("Gruppe: keine Zeilen", #parts.playerRows, 0)
Window.SetTab("enemies")
expectTrue("Gegner: Bosse in Kill-Reihenfolge", parts.bossRows[1].name:GetText():find("Rhahk'Zor", 1, true) ~= nil)

-- Journal: abgeschlossener Lauf bleibt für /lt recap run erhalten
_G[addon.GlobalName("DungeonRecap")]:Hide()
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
SlashCmdList.LEVELTIMER("recap run")
expectTrue("/lt recap run öffnet den Lauf aus dem Journal", Window.IsShown())
