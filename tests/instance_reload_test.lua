-- /reload in einer Instanz, deren Kopie nie bestätigt wurde (WoW Forever: Gegner-GUIDs geheim): derselbe Lauf,
-- XP und Kills bleiben
local Instances = addon.Instances

local function enter(name, difficulty)
  wow.state.instance = name and { name = name, type = "party", difficulty = difficulty or 0 } or nil
  wow.fire("PLAYER_ENTERING_WORLD", false, name ~= nil)
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function runXp() return (Instances.Summarize(Instances.GetCurrentRun())) end

wow.login({ level = 21, xp = 0, xpMax = 100000 })
enter(nil)
enter("Die Höhlen des Wehklagens")
gainXp(4000)
wow.advance(600)
expect("vor Reload", runXp(), 4000)

wow.logout()
wow.advance(5)
wow.login()
enter("Die Höhlen des Wehklagens")
wow.runTimers()
expect("nach Reload: derselbe Lauf", #addon.character.instanceLog, 0)
expect("nach Reload: XP bleibt", runXp(), 4000)
gainXp(500)
expect("zählt weiter", runXp(), 4500)

-- Client meldet nach dem Laden eine andere Schwierigkeit: trotzdem derselbe Lauf
wow.logout()
wow.advance(5)
wow.login()
enter("Die Höhlen des Wehklagens", 1)
wow.runTimers()
expect("andere Schwierigkeit nach Reload: derselbe Lauf", #addon.character.instanceLog, 0)
expect("XP bleibt trotz Schwierigkeit", runXp(), 4500)

-- Logout und erst nach Stunden zurück: wie bisher geschätzt (neue Kopie nach über 30 Minuten)
wow.logout()
wow.advance(2 * 3600)
wow.login()
enter("Die Höhlen des Wehklagens", 1)
wow.runTimers()
expect("lange weg: neuer Lauf", #addon.character.instanceLog, 1)
expect("keine Fehler", #wow.errors, 0)
