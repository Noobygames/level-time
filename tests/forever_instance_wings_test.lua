-- LT-318: Flügel vor dem ersten Boss-Kill erkennen (Scharlachrotes Kloster, alle Flügel auf Karte 189)
local Bosses = addon.InstanceBosses
local MYRMIDON = 4295     -- Trash der Kathedrale
local SHARED_MOB = 99001  -- Gegner, der in zwei Flügeln stirbt
local CATHEDRAL, ARMORY = 4, 3
local MONASTERY = { name = "Scharlachrotes Kloster", type = "party", difficulty = 1, mapID = 189, maxPlayers = 5 }
local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }

local function died(npcID)
  wow.fire("UNIT_DIED", "Creature-0-1-189-1-" .. npcID .. "-00001")
end

-- Neue Kopie des Klosters (vorher eine andere Instanz, damit ein neuer Lauf beginnt)
local function enterMonastery()
  wow.state.instance = DEADMINES
  wow.fire("PLAYER_ENTERING_WORLD")
  wow.state.instance = MONASTERY
  wow.fire("PLAYER_ENTERING_WORLD")
  return addon.Instances.GetCurrentRun()
end

wow.login({ level = 40, xp = 0, xpMax = 100000 })
local run = enterMonastery()
expect("ohne Wissen: ganze Liste", Bosses.ProgressText(run), "0/7")
died(MYRMIDON)
died(SHARED_MOB)
expect("unbekannter Mob gibt keinen Hinweis", run.wing, nil)
wow.fire("ENCOUNTER_END", 449, "Hochinquisitor Schönufer", 1, 5, 1)
expect("Boss legt die Kathedrale fest", Bosses.Wing(run), CATHEDRAL)
expect("Fortschritt im Flügel", Bosses.ProgressText(run), "1/2")

-- Zweiter Lauf: der erste Trash-Kill erkennt den Flügel
run = enterMonastery()
expect("neuer Lauf: ganze Liste", Bosses.ProgressText(run), "0/7")
died(MYRMIDON)
expect("Myrmidonin erkennt die Kathedrale", Bosses.Wing(run), CATHEDRAL)
expect("Fortschritt vor dem ersten Boss", Bosses.ProgressText(run), "0/2")
expect("Tooltip nur mit den Bossen des Flügels", #Bosses.TooltipLines(run), 3)
-- Ein Boss-Kill geht vor einem falschen Hinweis
wow.fire("ENCOUNTER_END", 448, "Herod", 1, 5, 1)
expect("Boss schlägt den Hinweis", Bosses.Wing(run), ARMORY)
died(SHARED_MOB)

-- Mob in zwei Flügeln ist mehrdeutig
run = enterMonastery()
local herodRun
for _, record in ipairs(addon.History.GetInstanceLog(addon.characterKey)) do
  if record.bosses == "448" then herodRun = record end
end
expect("Hinweis im Journal", herodRun and herodRun.wing, CATHEDRAL)
died(SHARED_MOB)
expect("mehrdeutiger Mob gibt keinen Hinweis", run.wing, nil)

-- Gruppensuche: Aktivität des eigenen Eintrags wird gelernt und erkennt den Flügel beim Betreten
wow.state.lfgActivities = { [217] = { mapID = 189, fullName = "Scharlachrotes Kloster - Kathedrale" } }
wow.state.lfgWindow = { entry = { activityIDs = { 217 } } }
wow.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
wow.fire("ENCOUNTER_END", 450, "Hochinquisitorin Weißsträhne", 1, 5, 1)
wow.state.lfgWindow = nil  -- ausgetragen: die letzten Aktivitäten bleiben gemerkt
wow.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
run = enterMonastery()
expect("Eintrag erkennt die Kathedrale beim Betreten", Bosses.Wing(run), CATHEDRAL)
expectTrue("Debug-Zustand", addon.InstanceWings.State().learned[189] >= 2)

-- Eintrag mit mehreren Aktivitäten der Karte: nichts lernen (sonst wird die Waffenkammer-Aktivität zur Kathedrale)
wow.state.lfgActivities = { [217] = { mapID = 189 }, [218] = { mapID = 189, fullName = "Scharlachrotes Kloster - Waffenkammer" } }
wow.state.lfgWindow = { entry = { activityIDs = { 217, 218 } } }
wow.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
wow.fire("ENCOUNTER_END", 449, "Hochinquisitor Schönufer", 1, 5, 1)
wow.state.lfgWindow = { entry = { activityIDs = { 218 } } }  -- gelesen beim Betreten
run = enterMonastery()
expect("mehrere Aktivitäten lernen nichts", run.wing, nil)

-- Unterzone (Forever: GUIDs geheim): gelernt beim Boss-Kill, erkannt beim nächsten Betreten
wow.state.lfgWindow, wow.state.lfgActivities = nil, nil
run = enterMonastery()
wow.state.subZone = "Waffenkammer der Scharlachroten"
wow.fire("ZONE_CHANGED_INDOORS")
wow.fire("UNIT_DIED", wow.SECRET)
wow.fire("ENCOUNTER_END", 448, "Herod", 1, 5, 1)
expect("Herod legt die Waffenkammer fest", Bosses.Wing(run), ARMORY)
expect("Unterzone gelernt", addon.InstanceWings.State().zones[189]["Waffenkammer der Scharlachroten"], ARMORY)
wow.state.subZone = ""
run = enterMonastery()
expect("ohne Unterzone kein Hinweis", run.wing, nil)
wow.state.subZone = "Waffenkammer der Scharlachroten"
wow.fire("ZONE_CHANGED_INDOORS")
expect("Unterzone erkennt die Waffenkammer", Bosses.Wing(run), ARMORY)
expect("Fortschritt im Flügel", Bosses.ProgressText(run), "0/1")
-- Dieselbe Unterzone in einem anderen Flügel macht sie mehrdeutig
enterMonastery()
wow.fire("ENCOUNTER_END", 449, "Hochinquisitor Schönufer", 1, 5, 1)
expect("mehrdeutige Unterzone", addon.InstanceWings.State().zones[189]["Waffenkammer der Scharlachroten"], 0)
wow.state.subZone = nil

-- Andere Karten ohne Flügel bleiben unberührt
wow.state.instance = DEADMINES
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("UNIT_DIED", "Creature-0-1-36-1-" .. MYRMIDON .. "-00001")
expect("Karte ohne Flügel: kein Hinweis", addon.Instances.GetCurrentRun().wing, nil)
expect("keine Lua-Fehler", #wow.errors, 0)
