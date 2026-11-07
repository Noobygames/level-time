-- Beinahe-Tode: Leben unter 10 %, danach wieder über 30 %, ohne zu sterben.
local Stats = addon.Stats
local PLAYER = wow.state.guid

wow.login({ level = 25, zone = "Sumpfland" })

local function health(percent)
  wow.state.health = wow.state.healthMax * percent / 100
  wow.fire("UNIT_HEALTH", "player")
end

-- Knapp überlebt nach einem Treffer von Hogger
wow.combatLog("SPELL_DAMAGE", "Hogger", PLAYER, 123, "Prankenhieb", 1, 500)
health(8)
health(4)
health(15)  -- noch nicht erholt
health(9)   -- schwankt: kein zweiter Beinahe-Tod
health(35)  -- erholt
expect("ein Beinahe-Tod", Stats.Get(Stats.LEVEL, Stats.NEAR_DEATHS), 1)

local entry = addon.character.nearDeathLog[1]
expect("tiefster Wert", entry.lowestPercent, 4)
expect("Ursache", entry.killer, "Hogger")
expect("Zone", entry.zone, "Sumpfland")

-- Gestorben statt erholt: zählt nicht
health(5)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
health(0)
wow.state.dead = false
health(50)
expect("Tod ist kein Beinahe-Tod", Stats.Get(Stats.LEVEL, Stats.NEAR_DEATHS), 1)

-- Andere Einheiten ignorieren
wow.fire("UNIT_HEALTH", "target")
expect("nur der Spieler zählt", #addon.character.nearDeathLog, 1)

addon.Set("showNearDeaths", true)
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Beinahe-Tode", wow.click("Beinahe-Tode"))

-- Wiederbelebung mit wenig Leben (Geistheiler, Seelenstein): kein Beinahe-Tod
local before = Stats.Get(Stats.LEVEL, Stats.NEAR_DEATHS)
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")
health(5)
health(40)
expect("nach Wiederbelebung kein Beinahe-Tod", Stats.Get(Stats.LEVEL, Stats.NEAR_DEATHS), before)
wow.advance(60)
health(5)
health(40)
expect("später wieder gezählt", Stats.Get(Stats.LEVEL, Stats.NEAR_DEATHS), before + 1)
