-- Level Time Goals, Roadmap 307: Gebiete entdecken (Systemchat oder Bildschirmmeldung, einmal je Entdeckung),
-- Gebiete in bestimmter Zone entdecken (optionaler Zonenfilter) und eine Zone erreichen.
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

-- Gebiete in bestimmter Zone entdecken
SlashCmdList.STREAMGOAL("add explore 2 Durotar")
local durotarGoal = Goals.Active()[#Goals.Active()]
expect("Zonenfilter Durotar", durotarGoal.params.zone, "Durotar")
expect("Titel mit Zone", Goals.Title(durotarGoal), string.format(L.SG_GOAL_EXPLORE_ZONE, 2, "Durotar"))

wow.fire("CHAT_MSG_SYSTEM", "Entdeckt: Tal der Prüfungen")
expect("Entdeckung zählt allgemein", count.progress, 1)
expect("Entdeckung zählt für Durotar", durotarGoal.progress, 1)
wow.fire("UI_INFO_MESSAGE", 0, "Entdeckt: Tal der Prüfungen")
expect("dieselbe Entdeckung zweimal zählt einmal", count.progress, 1)
wow.fire("UI_INFO_MESSAGE", 0, "Ragefire Chasm entdeckt: 120 Erfahrung erhalten.")
expect("mit XP zählt auch", count.progress, 2)
expect("Durotar zählt auch", durotarGoal.progress, 2)
expect("Durotar-Ziel erreicht", durotarGoal.status, Goals.DONE)
wow.fire("CHAT_MSG_SYSTEM", "Ihr seid jetzt AFK.")
expect("andere Meldung zählt nicht", count.progress, 2)

-- Weiteres Zonen-Ziel für Brachland
SlashCmdList.STREAMGOAL("add explore 1 Brachland")
local brachlandGoal = Goals.Active()[#Goals.Active()]
-- Entdeckung in Durotar zählt nicht für Brachland
wow.state.zone = "Durotar"
wow.fire("CHAT_MSG_SYSTEM", "Entdeckt: Sen'jin")
expect("Durotar-Entdeckung zählt nicht für Brachland", brachlandGoal.progress, 0)
expect("allgemeines Ziel erreicht", count.status, Goals.DONE)

-- Entdeckung im Brachland zählt für Brachland
wow.state.zone = "Brachland"
wow.fire("CHAT_MSG_SYSTEM", "Entdeckt: Wegekreuz")
expect("Brachland-Entdeckung zählt", brachlandGoal.status, Goals.DONE)

wow.state.zone = "Brachland"
wow.fire("ZONE_CHANGED_NEW_AREA")
expect("Zone erreicht", zone.status, Goals.DONE)

-- C_MapExplorationInfo Kacheln abfragen
C_MapExplorationInfo = {
  GetExploredMapTextures = function(uiMapID)
    if uiMapID == 1411 then return { "tile1", "tile2", "tile3" } end
    return {}
  end,
}
C_Map = {
  GetBestMapForUnit = function(unit)
    return unit == "player" and 1411 or nil
  end,
}
expect("3 erkundete Kacheln", streamGoal.ExploreGoals.ExploredTextureCount(), 3)
