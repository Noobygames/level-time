-- Mehr XP-Quellen und Kontext (Roadmap 275): Entdecken, Sammeln, XP nach Ort (Welt/Dungeon/Raid/Schlachtfeld).
local Stats = addon.Stats
local Experience = addon.Experience

wow.login({ level = 10, xp = 0, xpMax = 1000 })

local function gain(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

-- Entdecken: Menge aus der Systemmeldung (Platzhalter vertauschbar)
wow.fire("CHAT_MSG_SYSTEM", "Goldhain entdeckt: 30 Erfahrung erhalten.")
gain(30)
expect("Entdecken", Stats.Get(Stats.LEVEL, Stats.XP_EXPLORE), 30)
expect("Entdecken nicht als Sammeln", Stats.Get(Stats.LEVEL, Stats.XP_GATHER), 0)
wow.fire("CHAT_MSG_SYSTEM", "Ihr seid jetzt AFK.")
expect("andere Systemmeldung", Stats.Get(Stats.LEVEL, Stats.XP_EXPLORE), 30)

-- Sammeln: Gewinn kurz nach der Sammel-Meldung
wow.advance(10)
wow.fire("CHAT_MSG_OPENING", "Ihr führt Kräutersammeln auf Friedensblume aus.")
wow.advance(1)
gain(50)
expect("Sammeln", Stats.Get(Stats.LEVEL, Stats.XP_GATHER), 50)
gain(40)  -- zweiter Gewinn gehört nicht mehr zum Sammeln
expect("nur ein Gewinn je Sammeln", Stats.Get(Stats.LEVEL, Stats.XP_GATHER), 50)

-- zu spät oder im Kampf: kein Sammeln
wow.fire("CHAT_MSG_OPENING", "Ihr führt Bergbau auf Kupferader aus.")
wow.advance(10)
gain(20)
expect("zu spät", Stats.Get(Stats.LEVEL, Stats.XP_GATHER), 50)
wow.fire("CHAT_MSG_OPENING", "Ihr führt Bergbau auf Kupferader aus.")
wow.state.inCombat = true
gain(20)
wow.state.inCombat = false
expect("im Kampf", Stats.Get(Stats.LEVEL, Stats.XP_GATHER), 50)
wow.advance(10)

-- Ort: bisher alles in der Welt; dann Dungeon, Raid, Schlachtfeld
expect("Welt", Stats.Get(Stats.LEVEL, Stats.XP_WORLD), 160)
wow.state.instance = { name = "Todesminen", type = "party" }
gain(100)
wow.state.instance = { name = "Molten Core", type = "raid" }
gain(10)
wow.state.instance = { name = "Warsongschlucht", type = "pvp" }
gain(40)
wow.state.instance = nil
expect("Dungeon", Stats.Get(Stats.SESSION, Stats.XP_DUNGEON), 100)
expect("Raid", Stats.Get(Stats.SESSION, Stats.XP_RAID), 10)
expect("Schlachtfeld", Stats.Get(Stats.SESSION, Stats.XP_BATTLEGROUND), 40)

-- Quellen: Sonstige = Rest ohne Kills, Quests, Entdecken, Sammeln
local sources = Experience.GetSources(Stats.LEVEL)
expect("gesamt", sources.total, 310)
expect("sonstige", sources.other, 310 - 30 - 50)

local function statLine(setting)
  for _, entry in ipairs(addon.STAT_LINES) do
    if entry.setting == setting then return entry end
  end
end
local line = statLine("showXpContext")
expect("Zeile Welt", line.rows[1].value(Stats.LEVEL), "52%")
expect("Zeile Dungeon", line.rows[2].value(Stats.LEVEL), "32%")
expect("Zeile Entdecken", statLine("showXpSources").rows[3].value(Stats.LEVEL), "10%")

-- Level-Historie bekommt die Zähler mit
wow.state.xp = 1000
wow.levelUp(11, 1200)
local record = addon.character.levelHistory[10]
expect("Historie Entdecken", record.counters[Stats.XP_EXPLORE], 30)
expect("Historie Dungeon", record.counters[Stats.XP_DUNGEON], 100)
