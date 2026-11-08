-- Zonen-Auswertung: Zeit, XP, Kills und Tode je Zone.
local Zones = addon.Zones

wow.login({ zone = "Wald von Elwynn", xp = 0, xpMax = 1000 })

-- Wald: 10 min, 300 XP, ein Kill
wow.advance(600)
wow.state.xp = 300
wow.fire("PLAYER_XP_UPDATE", "player")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")

-- Westfall: 5 min, ein Tod, keine XP
wow.state.zone = "Westfall"
wow.fire("ZONE_CHANGED_NEW_AREA")
wow.advance(300)
wow.state.dead = true
wow.fire("PLAYER_DEAD")

local records = Zones.GetRecords(addon.characterKey)
expect("zwei Zonen", #records, 2)
expect("beste XP/h zuerst", records[1].zone, "Wald von Elwynn")
expectNear("Zeit im Wald", records[1].seconds, 600)
expect("XP im Wald", records[1].xp, 300)
expect("Kill im Wald", records[1].counters.kills, 1)
expect("Westfall ist aktuelle Zone", records[2].isCurrent, true)
expectNear("laufende Zeit in Westfall", records[2].seconds, 300)
expect("Tod in Westfall", records[2].counters.deaths, 1)

-- Diagramm: nur Zonen mit genug Zeit und XP
local chart = addon.Analysis.XpRatePerZone(addon.characterKey)
expect("eine Zone im Diagramm", #chart, 1)
expectNear("XP/h im Wald", chart[1].value, 1800)

-- Logout verbucht die laufende Zeit dauerhaft
wow.logout()
expectNear("Zeit gespeichert", addon.character.zoneStats["Westfall"].seconds, 300)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Zonen", wow.click("Zonen"))
expectTrue("Diagramm XP/h/Zone", wow.click("XP/h je Zone"))

-- Die laufende Zone steht nach dem Login in der Liste, auch ohne XP, Kill oder Tod
wow.logout()
wow.state.zone = "Düsterwald"
wow.login({ zone = "Düsterwald" })
local hasZone = false
for _, record in ipairs(Zones.GetRecords(addon.characterKey)) do
  if record.zone == "Düsterwald" then hasZone = true end
end
expectTrue("laufende Zone ohne Ereignis in der Liste", hasZone)
