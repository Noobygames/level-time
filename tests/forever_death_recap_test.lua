-- LT-267: WoW Forever ohne Kampflog-Abruf: die Todesursache kommt aus dem Death Recap (C_DeathRecap, forever
-- DeathRecapDocumentation.lua)
C_DeathRecap = {
  GetRecapEvents = function() return { { event = "SPELL_DAMAGE", sourceName = "Hogger", spellName = "Prankenhieb" } } end,
}

wow.login()
expect("Forever: kein Kampflog-Abruf", addon.Client.CombatLogEventInfo, nil)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
local death = addon.character.deathLog[1]
expect("Recap: Verursacher", death.killer, "Hogger")
expect("Recap: Zauber", death.spell, "Prankenhieb")
expect("keine Lua-Fehler", #wow.errors, 0)
