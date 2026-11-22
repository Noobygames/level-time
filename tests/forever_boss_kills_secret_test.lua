-- LT-321: Forever-Instanz, alle UNIT_DIED-GUIDs geheim, kein ENCOUNTER_END: BOSS_KILL und tote Boss-Einheit zählen
local Bosses = addon.InstanceBosses

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local run = addon.Instances.GetCurrentRun()
local list = Bosses.List(36, 1)
local first, second
for _, id in ipairs(list) do
  if not Bosses.IsRare(id) and Bosses.Name(id) then
    if not first then first = id elseif not second then second = id end
  end
end

wow.fire("UNIT_DIED", wow.SECRET)
expect("geheime GUID zählt nicht", Bosses.ProgressText(run), "0/7")
wow.fire("BOSS_KILL", first, Bosses.Name(first))
expect("BOSS_KILL zählt", Bosses.ProgressText(run), "1/7")
expect("Quelle bosskill", Bosses.LastEvent().source, "bosskill")
wow.fire("ENCOUNTER_END", first, "x", 1, 5, 1)
expect("BOSS_KILL + ENCOUNTER_END zählen einmal", Bosses.ProgressText(run), "1/7")

wow.state.units.boss1 = { name = Bosses.Name(second), dead = false }
Bosses.CheckDeadUnits()
expect("lebender Boss zählt nicht", Bosses.ProgressText(run), "1/7")
wow.state.units.boss1.dead = true
Bosses.CheckDeadUnits()
Bosses.CheckDeadUnits()
expect("tote Boss-Einheit zählt einmal", Bosses.ProgressText(run), "2/7")
expect("Quelle unit", Bosses.LastEvent().source, "unit")
expect("Split je Kill", addon.InstanceRuns.Splits(run)[second] ~= nil, true)
expect("Quellen protokolliert", #Bosses.Sources().counted, 2)
