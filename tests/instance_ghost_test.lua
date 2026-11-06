-- Geist zurück zur Leiche: immer derselbe Lauf, auch ohne lesbare Gegner-GUIDs (WoW Forever), wenn der Client beim
-- Wiedereintritt eine andere Schwierigkeit meldet oder der Geisterlauf länger als die Wiederverwendungszeit dauert.
local Instances = addon.Instances

local function enter(name, difficulty)
  wow.state.instance = name and { name = name, type = "party", difficulty = difficulty } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function die()
  wow.state.dead = true
  wow.fire("PLAYER_DEAD")
  wow.fire("PLAYER_ALIVE")  -- Geist freigelassen
end

local function revive()
  wow.state.dead = false
  wow.fire("PLAYER_UNGHOST")
end

local function run() return Instances.GetCurrentRun() end
local function runXp() return (Instances.Summarize(run())) end

wow.login({ level = 20, xp = 0, xpMax = 100000 })
enter(nil)

-- Gegner-GUIDs geheim: keine Bestätigung, nur Schätzung
enter("Die Höhlen des Wehklagens", 0)
gainXp(2000)
wow.advance(600)
die()
enter(nil)
wow.advance(60)
enter("Die Höhlen des Wehklagens", 1)  -- Client meldet als Geist eine andere Schwierigkeit
revive()
expect("andere Schwierigkeit: derselbe Lauf", #addon.character.instanceLog, 0)
expect("XP bleibt", runXp(), 2000)
expectNear("Geisterlauf zählt", Instances.GetRunSeconds(run()), 660)

-- Langer Geisterlauf (länger als die Wiederverwendungszeit)
die()
enter(nil)
wow.advance(40 * 60)
enter("Die Höhlen des Wehklagens", 1)
revive()
expect("langer Geisterlauf: derselbe Lauf", #addon.character.instanceLog, 0)
expect("XP bleibt nach langem Lauf", runXp(), 2000)

-- Lebend raus und nach über 30 Minuten wieder rein: neue Kopie (wie bisher)
enter(nil)
wow.advance(31 * 60)
enter("Die Höhlen des Wehklagens", 1)
expect("lebend nach langer Pause: neuer Lauf", #addon.character.instanceLog, 1)

-- Als Geist raus, beim Geistheiler wiederbelebt, lebend wieder rein: keine Sonderbehandlung als Geist
gainXp(500)
die()
enter(nil)
revive()
wow.advance(31 * 60)
enter("Die Höhlen des Wehklagens", 1)
expect("wiederbelebt und spät zurück: neuer Lauf", #addon.character.instanceLog, 2)

-- Als Geist in eine andere Instanz: neuer Lauf
die()
enter(nil)
enter("Die Todesminen", 1)
revive()
expect("andere Instanz als Geist: neuer Lauf", #addon.character.instanceLog, 3)
expect("keine Fehler", #wow.errors, 0)
