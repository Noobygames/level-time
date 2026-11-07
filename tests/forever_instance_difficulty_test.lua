-- Debug-Log WoW Forever 2026-11-06 21:07:56: Burg Shadowfang betreten, der Client meldet zuerst Schwierigkeit 0
-- und eine Sekunde später 1, ohne dass man die Instanz verlassen hat. Das ist derselbe Aufenthalt: kein
-- Mini-Lauf von 1,7 s im Journal und kein zweiter Eintrag fürs Instanzlimit.
local Instances = addon.Instances
local InstanceLimit = addon.InstanceLimit

local function setInstance(name, difficulty)
  wow.state.instance = name and { name = name, type = "party", difficulty = difficulty } or nil
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

local function run() return Instances.GetCurrentRun() end
local function runXp() return (Instances.Summarize(run())) end

wow.login({ level = 22, xp = 0, xpMax = 100000 })
setInstance(nil)
wow.fire("PLAYER_ENTERING_WORLD")

-- Vorher: offener Lauf in den Höhlen des Wehklagens, draußen beendet (angehalten)
setInstance("Höhlen des Wehklagens", 1)
wow.fire("PLAYER_ENTERING_WORLD")
wow.advance(600)
setInstance(nil)
wow.fire("PLAYER_ENTERING_WORLD")
wow.advance(60)
expect("Wehklagen offen", run().name, "Höhlen des Wehklagens")
local hourBefore = InstanceLimit.GetHourCount()

-- 21:07:56 Betreten mit Schwierigkeit 0, 21:07:57 meldet ZONE_CHANGED_NEW_AREA Schwierigkeit 1
setInstance("Burg Shadowfang", 0)
wow.fire("PLAYER_ENTERING_WORLD")
expect("neuer Lauf in Shadowfang", run().name, "Burg Shadowfang")
expect("Wehklagen beendet", #addon.character.instanceLog, 1)
expect("eine neue Instanz", InstanceLimit.GetHourCount(), hourBefore + 1)
local startedAt = run().startedAt
wow.advance(1)
setInstance("Burg Shadowfang", 1)
wow.fire("ZONE_CHANGED_NEW_AREA")
expect("Schwierigkeit fest: kein Mini-Lauf im Journal", #addon.character.instanceLog, 1)
expect("derselbe Lauf", run().startedAt, startedAt)
expect("kein zweiter Eintrag fürs Limit", InstanceLimit.GetHourCount(), hourBefore + 1)
expect("Uhr läuft", Instances.IsRunning(), true)
expect("Besuch unter neuem Schlüssel", addon.character.instanceVisits["Burg Shadowfang#1"] ~= nil, true)
expect("kein Besuch unter #0", addon.character.instanceVisits["Burg Shadowfang#0"], nil)

gainXp(1500)
wow.advance(300)
expect("XP zählen im Lauf", runXp(), 1500)
expectNear("Zeit seit dem Betreten", Instances.GetRunSeconds(run()), 301, 0.01)

-- Die Ereignisse für die Schwierigkeit allein verlassen die Instanz nicht
wow.fire("PLAYER_DIFFICULTY_CHANGED")
wow.fire("UPDATE_INSTANCE_INFO")
expect("weiter derselbe Lauf", run().startedAt, startedAt)
expect("keine Fehler", #wow.errors, 0)
