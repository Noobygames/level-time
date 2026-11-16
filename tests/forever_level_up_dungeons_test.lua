-- WoW Forever: Level-Up-Fenster nennt Dungeons, deren Level-Bereich mit dem neuen Level beginnt
local Info = addon.InstanceInfo

local starting = Info.StartingAt(15)
expectTrue("Level 15: Dungeon beginnt", #starting > 0)
for _, entry in ipairs(starting) do expect("Beginn genau Level 15", entry.minLevel, 15) end
expect("Level 16: kein Dungeon beginnt", #Info.StartingAt(16), 0)

wow.login({ level = 14 })
local gains = { health = 90, strength = 3 }
wow.levelUp(15, nil, gains)
wow.runTimers()
expect("Fenster mit Dungeon-Zeile", LevelTimerLevelUp:IsShown(), true)
