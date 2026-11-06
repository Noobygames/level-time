-- Kills bis Level-Up genauer (Roadmap 273): Schnitt der letzten N Kills/Quests aus dem Journal, Erholungsbonus zählt doppelt.
local Experience = addon.Experience
local Stats = addon.Stats

wow.login({ level = 10, xp = 0, xpMax = 1000 })

local function kill(name, xp, bonus)
  if bonus then
    wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_EXHAUSTION1, name, xp, "+" .. bonus, "Erholung"))
  else
    wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, name, xp))
  end
end

-- Bonus aus der Meldung landet im Journal
kill("Wolf", 200, 100)
local entry = addon.character.killLog[#addon.character.killLog]
expect("XP im Journal", entry.xp, 200)
expect("Bonus im Journal", entry.rested, 100)
expect("Zähler zählt die ganze XP", Stats.Get(Stats.LEVEL, Stats.XP_KILLS), 200)

-- Letzte 2 Kills: Basis 100 und 60 -> Schnitt 80; die ersten (Basis 100) fallen heraus, wenn N = 2
addon.Set("toLevelSamples", 2)
kill("Kobold", 60)
kill("Kobold", 100)
wow.state.xp = 200
-- 800 XP fehlen, Basis (60+100)/2 = 80 -> 10 Kills
expect("Schnitt der letzten 2", Experience.CountToLevel(Stats.XP_KILLS, Stats.PVE_KILLS), 10)

-- Erholungs-Pool 400: die ersten 400 XP kommen doppelt (400 / 160 = 2,5 Kills), Rest 400 / 80 = 5 -> 7,5 -> 8
wow.state.rested = 400
expect("mit Erholung", Experience.CountToLevel(Stats.XP_KILLS, Stats.PVE_KILLS), 8)
wow.state.rested = 0

-- Ganzes Level (0): Kills-XP minus Erholungsbonus des Levels je Kill
addon.Set("toLevelSamples", 0)
Stats.Increment(Stats.XP_RESTED, 100)
-- XP_KILLS 360, Bonus 100 -> 260 / 3 Kills = 86,7 -> 800 / 86,7 = 9,2 -> 10
expect("ganzes Level ohne Bonus", Experience.CountToLevel(Stats.XP_KILLS, Stats.PVE_KILLS), 10)

-- Quests: aus dem Quest-Journal, ohne Erholung
addon.Set("toLevelSamples", 5)
wow.state.rested = 5000
wow.fire("QUEST_TURNED_IN", 11, 400, 0)
wow.state.xp = 600
-- 400 fehlen, Quest-Schnitt 400 -> 1
expect("Quests aus dem Journal", Experience.CountToLevel(Stats.XP_QUESTS, Stats.QUESTS), 1)

-- Reine Rechnung
expect("ohne Pool", Experience.CountForXp(1000, 100, 0), 10)
expect("Pool größer als Rest", Experience.CountForXp(1000, 100, 5000), 5)
