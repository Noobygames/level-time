-- Level Time Goals, Roadmap 307: Gebiete entdecken (Systemchat oder Bildschirmmeldung, einmal je Entdeckung) und
-- eine Zone erreichen.
local Goals = streamGoal.Goals
local L = streamGoal.L

ERR_ZONE_EXPLORED = "Entdeckt: %s"
wow.login({ level = 20, zone = "Durotar" })

SlashCmdList.STREAMGOAL("add explore 3")
local count = Goals.Active()[1]
expect("Anzahl", count.params.mode, "count")
expect("Titel", Goals.Title(count), string.format(L.SG_GOAL_EXPLORE, 3))

SlashCmdList.STREAMGOAL("add explore Brachland")
local zone = Goals.Active()[2]
expect("Zone", zone.params.zone, "Brachland")
expect("ohne Zähler", Goals.HasCount(zone), false)
SlashCmdList.STREAMGOAL("add explore Durotar")
expect("schon dort: kein Ziel", #Goals.Active(), 2)

wow.fire("CHAT_MSG_SYSTEM", "Entdeckt: Tal der Prüfungen")
expect("Entdeckung zählt", count.progress, 1)
wow.fire("UI_INFO_MESSAGE", 0, "Entdeckt: Tal der Prüfungen")
expect("dieselbe Entdeckung zweimal zählt einmal", count.progress, 1)
wow.fire("UI_INFO_MESSAGE", 0, "Ragefire Chasm entdeckt: 120 Erfahrung erhalten.")
expect("mit XP zählt auch", count.progress, 2)
wow.fire("CHAT_MSG_SYSTEM", "Ihr seid jetzt AFK.")
expect("andere Meldung zählt nicht", count.progress, 2)

wow.state.zone = "Brachland"
wow.fire("ZONE_CHANGED_NEW_AREA")
expect("Zone erreicht", zone.status, Goals.DONE)
