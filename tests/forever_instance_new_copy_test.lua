-- Roadmap 493 (WoW Forever): der Gruppenleiter setzt die Instanz zurück, die Reset-Meldung bekommt nur er und die
-- GUIDs sind geheim. Neue Kopie trotzdem erkannt: Wiedereintritt nach dem Endboss, oder ein Boss fällt ein zweites Mal.
local Instances = addon.Instances
local InstanceLimit = addon.InstanceLimit
local Bosses = addon.InstanceBosses

local function enter(name, mapID)
  wow.state.instance = { name = name, type = "party", difficulty = 1, mapID = mapID, maxPlayers = 5 }
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function leave()
  wow.state.instance = nil
  wow.fire("PLAYER_ENTERING_WORLD")
  wow.fire("PLAYER_ALIVE")
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function run() return Instances.GetCurrentRun() end
local function log() return addon.character.instanceLog end

wow.login({ level = 30, xp = 0, xpMax = 100000 })
leave()

-- 1. Waffenkammer: Herod (448) ist Endboss seines Flügels; raus, Reset durch den Leiter, wieder rein
enter("Scharlachrotes Kloster", 189)
wow.fire("ENCOUNTER_END", 448, "Herod", 1, 5, 1)
expectTrue("Waffenkammer abgeschlossen", addon.InstanceRuns.IsCompleted(run()))
wow.advance(60)
leave()
-- Als Geist raus und wieder rein: dieselbe Kopie
wow.state.dead = true
enter("Scharlachrotes Kloster", 189)
leave()
wow.state.dead = false
wow.advance(60)
enter("Scharlachrotes Kloster", 189)
expect("nach Geist und Reset: alter Lauf beendet", #log(), 1)
expect("neuer Lauf ohne Bosse", run().bosses, nil)
expect("zwei Instanzen im Limit", InstanceLimit.GetHourCount(), 2)

-- Herod fällt in der neuen Kopie wieder: kein Teilen (fiel nicht vor dem letzten Betreten dieses Laufs)
wow.fire("ENCOUNTER_END", 448, "Herod", 1, 5, 1)
expect("Herod im neuen Lauf", run().bosses, "448")
expect("kein Teilen", #log(), 1)
leave()

-- 2. Todesminen: erster Boss, raus, Reset ohne Meldung, wieder rein, XP, derselbe Boss fällt noch einmal
local first = Bosses.List(36, 1)[1]
enter("Die Todesminen", 36)
expect("Waffenkammer-Lauf beendet", #log(), 2)
gainXp(500)
wow.fire("ENCOUNTER_END", first, "Boss", 1, 5, 1)
wow.advance(120)
leave()
wow.advance(300)
enter("Die Todesminen", 36)
expect("vermutet dieselbe Kopie", #log(), 2)
wow.advance(100)
gainXp(300)
wow.fire("ENCOUNTER_END", first, "Boss", 1, 5, 1)
expect("zweiter Kill: alter Lauf beendet", #log(), 3)
expect("Kill im neuen Lauf", run().bosses, tostring(first))
expect("XP nach dem Betreten im neuen Lauf", (Instances.Summarize(run())), 300)
expectNear("Zeit ab dem Betreten", Instances.GetRunSeconds(run()), 100, 0.01)
expect("Split ab dem Betreten", run().splits, "100")
expect("neue Instanz im Limit", InstanceLimit.GetHourCount(), 4)
-- ENCOUNTER_END und UNIT_DIED desselben Kills im selben Aufenthalt teilen nicht noch einmal
wow.fire("ENCOUNTER_END", first, "Boss", 1, 5, 1)
expect("kein weiterer Lauf", #log(), 3)
expect("keine Fehler", #wow.errors, 0)
