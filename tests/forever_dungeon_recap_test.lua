-- LT-334 (WoW Forever): Dungeon-Recap nach dem Endboss. Zahlen aus C_DamageMeter erst nach dem Kampf, Zeit gegen die
-- Bestzeit mit Pfeil und Farbe, Auszeichnungen, Reiter Beute/Gruppe/Gegner, Einstellung und /lt recap run.
local Instances = addon.Instances
local Bosses = addon.InstanceBosses
local Recap = addon.InstanceRecap
local Window = addon.DungeonRecapWindow
local L = addon.L

local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
local SHADOWFANG = { name = "Burg Schattenfang", type = "party", difficulty = 1, mapID = 33, maxPlayers = 5 }

local function enter(instance)
  wow.state.instance = instance
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function panel() return _G[addon.GlobalName("DungeonRecap")] end

wow.login({ level = 21, xp = 0, xpMax = 100000 })
wow.state.groupSize = 3
wow.state.units.party1 = { name = "Lunaria", class = "PRIEST" }
wow.state.units.party2 = { name = "Frostbyte", class = "MAGE" }
local ownName = addon.characterKey:match("^([^-]+)")
local list = Bosses.List(36, 1)
local endBoss = Bosses.EndBoss(list)

SlashCmdList.LEVELTIMER("recap run")
expectTrue("ohne Lauf: Hinweis, kein Fenster",
  not Window.IsShown() and wow.printed[#wow.printed]:find(L.DUNGEON_RECAP_NONE, 1, true) ~= nil)

-- Erster Lauf (langsam), ohne Schadensmesser im Client
enter(DEADMINES)
wow.advance(10)
wow.fire("PLAYER_STARTED_MOVING")
wow.advance(90)
wow.fire("ENCOUNTER_END", list[1], "Boss", 1, 5, 1)
wow.advance(200)
wow.fire("ENCOUNTER_END", endBoss, "Boss", 1, 5, 1)
expectTrue("Recap öffnet nach dem Endboss", Window.IsShown())
local parts = Window.Parts()
expectTrue("Kopf: Lauf und Endboss", parts.header.title:GetText():find(Bosses.Name(endBoss), 1, true) ~= nil)
expect("Endboss-Porträt", parts.portrait.npcID, Bosses.NpcID(endBoss))
expect("erster Lauf: kein Vergleich", parts.delta:GetText(), addon.Theme.Hex("muted") .. L.DUNGEON_RECAP_FIRST_RUN .. "|r")
expect("keine Messerzahlen ohne API", Instances.GetCurrentRun().recapPlayers, nil)
expect("Auszeichnung schnellster Boss", parts.awardRows[1].label:GetText(), L.DUNGEON_RECAP_AWARD_FASTEST)
panel():Hide()

-- Zweiter Lauf schneller, mit Schadensmesser; Kill im Kampf: Zahlen erst nach PLAYER_REGEN_ENABLED
enter(SHADOWFANG)
local T = Enum.DamageMeterType
wow.installDamageMeter({
  { id = 1, name = Bosses.Name(list[1]),
    sources = {
      [T.DamageDone] = { { name = ownName, classFilename = "WARRIOR", totalAmount = 1000, isLocalPlayer = true },
        { name = "Lunaria", classFilename = "PRIEST", totalAmount = 200 },
        { name = "Frostbyte", classFilename = "MAGE", totalAmount = 3000 } },
      [T.HealingDone] = { { name = "Lunaria", totalAmount = 5000 } },
      [T.Interrupts] = { { name = "Frostbyte", totalAmount = 3 } },
      [T.DamageTaken] = { { name = ownName, totalAmount = 700, isLocalPlayer = true, sourceGUID = "Player-own" },
        { name = "Lunaria", totalAmount = 100 } },
      [T.Deaths] = { { name = "Lunaria" } },
    },
    spells = { ["Player-own"] = { { creatureName = "Gnarl", totalAmount = 400 }, { creatureName = "Kobold", totalAmount = 50 } } } },
  { id = 2, name = "Gegnergruppe",
    sources = {
      [T.DamageDone] = { { name = ownName, classFilename = "WARRIOR", totalAmount = 500, isLocalPlayer = true } },
      [T.Deaths] = { { name = "Lunaria" } },
      [T.DamageTaken] = { { name = ownName, totalAmount = 100, isLocalPlayer = true, sourceGUID = "Player-own" } },
    },
    spells = { ["Player-own"] = { { creatureName = "Gnarl", totalAmount = 100 } } } },
})
enter(DEADMINES)
local run = Instances.GetCurrentRun()
wow.advance(5)
wow.fire("PLAYER_STARTED_MOVING")
wow.advance(60)
wow.fire("ENCOUNTER_END", list[1], "Boss", 1, 5, 1)
wow.advance(100)
wow.state.combatLockdown = true
wow.fire("ENCOUNTER_END", endBoss, "Boss", 1, 5, 1)
expectTrue("im Kampf: noch nichts eingesammelt, kein Fenster", run.recapPlayers == nil and not Window.IsShown())
addon.Journal.AddRoll({ link = "[Helm]", winner = "Frostbyte", runStart = run.startedAt })
addon.Journal.AddRoll({ link = "[Axt]", winner = "Frostbyte", runStart = run.startedAt })
addon.Journal.AddRoll({ link = "[Ring]", winner = "Lunaria", runStart = run.startedAt })
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expectTrue("nach dem Kampf: Zahlen und Fenster", run.recapPlayers ~= nil and Window.IsShown())

local players = Recap.Players(run)
expect("Spieler nach Schaden sortiert", players[1].name, "Frostbyte")
expect("Schaden summiert", players[2].damage, 1500)
expect("Bossschaden aus der Boss-Sitzung", players[1].bossDamage, 3000)
expect("Tode gezählt", players[3].deaths, 2)
expect("Gegner: gefährlichster", Recap.Mobs(run)[1].name, "Gnarl")
expect("Gegner: Schaden", Recap.Mobs(run)[1].damage, 500)

parts = Window.Parts()
expectTrue("Zeit besser: grüner Pfeil nach oben", parts.delta:GetText():find("Arrow-Up-Up", 1, true) ~= nil
  and parts.delta:GetText():find(addon.Theme.Hex("good"), 1, true) ~= nil)
local awards = {}
local record = addon.History.GetInstanceLog(addon.characterKey)[1]
local loot = addon.InstanceRuns.Loot(addon.characterKey, record, time() + 1)
for _, award in ipairs(Recap.Awards(record, loot)) do awards[award.id] = award end
expect("Top-Schaden", awards[Recap.DAMAGE].who, "Frostbyte")
expect("Boss-Schaden", awards[Recap.BOSS_DAMAGE].who, "Frostbyte")
expect("Top-Heilung", awards[Recap.HEALING].who, "Lunaria")
expect("Unterbrecher", awards[Recap.INTERRUPTS].value, 3)
expect("Meiste Tode", awards[Recap.MOST_DEATHS].who, "Lunaria")
expect("Prügelknabe", awards[Recap.TANK].who, ownName)
expect("Gefährlichster Gegner", awards[Recap.DANGEROUS_MOB].who, "Gnarl")
expect("Würfelglück", awards[Recap.LOOT_LUCK].value, 2)
expect("Schnellster Boss", awards[Recap.FASTEST_BOSS].encounterID, list[1])
expect("MVP (Schaden plus Heilung)", Recap.Mvp(players), "Lunaria")

-- Reiter
Window.SetTab("group")
expectTrue("Gruppe: Zeile mit Porträt der Gruppeneinheit", parts.playerRows[1]:IsShown()
  and parts.playerRows[1].portrait._portraitUnit == "party2")
expect("Gruppe: Schaden", parts.playerRows[1].cells[1]:GetText(), "3.0k")
Window.SetTab("loot")
expectTrue("Beute: Würfe", parts.loot:GetText():find("[Helm]", 1, true) ~= nil)
Window.SetTab("enemies")
expect("Gegner: Gnarl", parts.mobRows[1].name:GetText(), "Gnarl")
expectTrue("Gegner: Boss schneller als im ersten Lauf", parts.bossRows[1].second:GetText():find("Arrow-Up-Up", 1, true) ~= nil)

-- Einstellung aus: kein Fenster nach dem Endboss; /lt recap run öffnet den jüngsten abgeschlossenen Lauf
panel():Hide()
addon.Set("dungeonRecapAutoOpen", false)
enter(SHADOWFANG)
enter(DEADMINES)
wow.fire("ENCOUNTER_END", endBoss, "Boss", 1, 5, 1)
expectTrue("Einstellung aus: Fenster bleibt zu", not Window.IsShown())
SlashCmdList.LEVELTIMER("recap run")
expectTrue("/lt recap run öffnet", Window.IsShown())
