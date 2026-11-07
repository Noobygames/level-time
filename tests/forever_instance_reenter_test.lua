-- Debug-Log WoW Forever 2026-11-06 21:13:45: Burg Shadowfang verlassen (Schlüssel #1), 21:14:04 Instanz-Daten
-- zurückgesetzt (Button), 21:14:08 wieder betreten, der Client meldet wieder zuerst Schwierigkeit 0. Der Besuch
-- unter #1 gilt (Schwierigkeit 0 = noch nicht bekannt), der Lauf geht mit zurückgesetzten Daten weiter und die
-- Uhr läuft. Ein Reset der Instanz im Spiel löscht dagegen die Besuche jeder Schwierigkeit: neuer Lauf.
local Instances = addon.Instances
local InstanceLimit = addon.InstanceLimit

local function setInstance(name, difficulty)
  wow.state.instance = name and { name = name, type = "party", difficulty = difficulty } or nil
end

local function enterSettling(name)
  setInstance(name, 0)
  wow.fire("PLAYER_ENTERING_WORLD")
  wow.advance(1)
  setInstance(name, 1)
  wow.fire("ZONE_CHANGED_NEW_AREA")
end

local function leave()
  setInstance(nil)
  wow.fire("PLAYER_ENTERING_WORLD")
  wow.fire("PLAYER_ALIVE")
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function run() return Instances.GetCurrentRun() end
local function runXp() return (Instances.Summarize(run())) end
local function visit(key) return addon.character.instanceVisits[key] end

wow.login({ level = 22, xp = 0, xpMax = 100000 })
leave()

-- 21:07:56 Betreten (0, dann 1), Lauf bis 21:13:45
enterSettling("Burg Shadowfang")
gainXp(2000)
wow.advance(348)
leave()
expect("ein Lauf offen", run().name, "Burg Shadowfang")
expect("eine Instanz", InstanceLimit.GetHourCount(), 1)
expect("Uhr angehalten", Instances.IsRunning(), false)

-- 21:14:04 Daten zurückgesetzt, 21:14:08 wieder rein: zuerst Schwierigkeit 0, bleibt so bis zum Verlassen
wow.advance(19)
expect("Daten zurückgesetzt", Instances.ResetCurrent(), true)
wow.advance(4)
setInstance("Burg Shadowfang", 0)
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("PLAYER_ALIVE")
expect("derselbe Lauf", #addon.character.instanceLog, 0)
expect("kein neuer Limit-Eintrag", InstanceLimit.GetHourCount(), 1)
expect("Uhr läuft wieder", Instances.IsRunning(), true)
expect("Besuch unter dem gemeldeten Schlüssel", visit("Burg Shadowfang#0") ~= nil, true)
expect("alter Schlüssel weg", visit("Burg Shadowfang#1"), nil)
gainXp(700)
wow.advance(2184)
expectNear("36 Minuten gezählt", Instances.GetRunSeconds(run()), 2184, 0.01)
expect("nur XP nach dem Zurücksetzen", runXp(), 700)

-- 21:50:32 raus; die Schwierigkeit stand drinnen nie fest. Kurz darauf wieder rein mit 1: derselbe Besuch
leave()
wow.advance(60)
setInstance("Burg Shadowfang", 1)
wow.fire("PLAYER_ENTERING_WORLD")
expect("zurück mit Schwierigkeit 1: derselbe Lauf", #addon.character.instanceLog, 0)
expect("weiter eine Instanz", InstanceLimit.GetHourCount(), 1)
leave()

-- Reset im Spiel (Systemchat, nur der Gruppenleiter): alle Besuche des Namens weg, auch unter #0
visit("Burg Shadowfang#1").leftAt = time()
addon.character.instanceVisits["Burg Shadowfang#0"] = { leftAt = time(), pending = { guessNew = true, enteredAt = time() } }
wow.advance(10)
wow.fire("CHAT_MSG_SYSTEM", string.format(INSTANCE_RESET_SUCCESS, "Burg Shadowfang"))
expect("Reset: Lauf beendet", #addon.character.instanceLog, 1)
expect("Reset: kein Besuch #0", visit("Burg Shadowfang#0"), nil)
expect("Reset: kein Besuch #1", visit("Burg Shadowfang#1"), nil)
wow.advance(4)
enterSettling("Burg Shadowfang")
expect("nach Reset: neuer Lauf", run() ~= nil and run().seconds, 0)
expect("nach Reset: Uhr läuft", Instances.IsRunning(), true)
expect("nach Reset: neue Instanz", InstanceLimit.GetHourCount(), 2)
expect("keine Fehler", #wow.errors, 0)
