-- Flugzeiten ohne eigene Messung der Strecke: Gegenrichtung, Schätzung aus der Strecke, Teilstrecken, alte Messungen.
-- Positionen und Zeiten aus dem Debug-Log eines echten Spielers (WoW Forever, Kalimdor und Östliche Königreiche).
local FlightTimes = addon.FlightTimes
local FlightTimer = addon.FlightTimer
local FlightMap = addon.FlightMap
-- Ohne Flugstrecken aus den Spieldaten (eigenes Szenario flight_paths), sonst gewinnt die Flugroute
addon.FlightPathsData = nil

local KALIMDOR = {
  { name = "Thunder Bluff, Mulgore", x = 0.44947779178619, y = 0.56151235103607, id = 22 },
  { name = "Orgrimmar, Durotar", x = 0.62800776958466, y = 0.44340223073959, id = 23 },
  { name = "Crossroads, Brachland", x = 0.55735743045807, y = 0.53047657012939, id = 25 },
  { name = "Sonnenfels, Steinkrallengebirge", x = 0.4079572558403, y = 0.47261422872543, id = 29 },
  { name = "Camp Taurajo, Brachland", x = 0.52804720401764, y = 0.61013436317444, id = 77 },
  { name = "Ratchet, Brachland", x = 0.6057111620903, y = 0.54907929897308, id = 80 },
}
local TB, ORG, XROADS, SUN, TAURAJO, RATCHET = 1, 2, 3, 4, 5, 6

-- Karte mit dem Startknoten current öffnen; hops[slot] = Teilstrecken zu diesem Ziel
local function openMap(nodes, mapID, current, hops)
  local list = {}
  for slot, node in ipairs(nodes) do
    list[slot] = { name = node.name, x = node.x, y = node.y, id = node.id,
      type = slot == current and "CURRENT" or "REACHABLE", hops = hops and hops[slot] }
  end
  wow.state.taxiNodes, wow.state.taxiMapID = list, mapID
  wow.fire("TAXIMAP_OPENED", 1)
end

local function fly(slot, seconds)
  TakeTaxiNode(slot)
  wow.state.onTaxi = true
  wow.advance(seconds)
  wow.update(1)
  wow.state.onTaxi = false
  wow.fire("PLAYER_CONTROL_GAINED")
end

local function distance(a, b)
  return math.sqrt((KALIMDOR[a].x - KALIMDOR[b].x) ^ 2 + (KALIMDOR[a].y - KALIMDOR[b].y) ^ 2)
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)

-- Ohne jede Messung auf der Karte: keine Schätzung
openMap(KALIMDOR, 1411, XROADS)
expect("ohne Messung nichts", FlightTimer.Lookup(TAURAJO), nil)

-- Erste Messung: Crossroads > Camp Taurajo 91 s, gespeichert unter den nodeIDs
fly(TAURAJO, 91)
local routes = LevelTimerStatsDB.flights.retail["1411"].routes
expect("Strecke mit nodeIDs", routes["25>77"].seconds, 91)
expectNear("Strecke gemerkt", routes["25>77"].distance, distance(XROADS, TAURAJO), 0.0001)
expect("Knoten gemerkt", LevelTimerStatsDB.flights.retail["1411"].nodes["80"].name, "Ratchet, Brachland")
openMap(KALIMDOR, 1411, XROADS)
local known = FlightTimer.Lookup(TAURAJO)
expect("gemessen", known.source, FlightTimes.MEASURED)
expect("gemessen: keine Schätzung", known.estimated, false)

-- Gegenrichtung: Camp Taurajo > Crossroads nie geflogen
openMap(KALIMDOR, 1411, TAURAJO)
local reverse = FlightTimer.Lookup(XROADS)
expect("Gegenrichtung", reverse.source, FlightTimes.REVERSE)
expect("Gegenrichtung: Zeit", reverse.seconds, 91)
expect("Gegenrichtung ist Schätzung", reverse.estimated, true)

-- Ein Flug auf der Karte: Schätzung mit Standard-Start/Landung
openMap(KALIMDOR, 1411, XROADS)
local guess = FlightTimer.Lookup(ORG)
expect("Schätzung", guess.source, FlightTimes.ESTIMATE)
expectNear("Schätzung aus einem Flug", guess.seconds, 10 + (91 - 10) / distance(XROADS, TAURAJO) * distance(XROADS, ORG), 0.5)

-- Andere Karte: dort keine Schätzung
local EASTERN_KINGDOMS = {
  { name = "Undercity, Tirisfal", x = 0.44267696142197, y = 0.19490665197372, id = 11 },
  { name = "Tarrens Mühle, Hillsbrad", x = 0.49442172050476, y = 0.26687431335449, id = 13 },
}
openMap(EASTERN_KINGDOMS, 1415, 2)
expect("andere Karte: nichts", FlightTimer.Lookup(1), nil)

-- Teilstrecken: Ratchet > Thunder Bluff fliegt über Crossroads, Strecke ist die Summe
local viaCrossroads = { [TB] = { { RATCHET, XROADS }, { XROADS, TB } }, [SUN] = { { RATCHET, XROADS }, { XROADS, SUN } } }
openMap(KALIMDOR, 1411, RATCHET, viaCrossroads)
local hopDistance, hops = FlightMap.Distance(FlightMap.Read(), RATCHET, TB)
expectNear("Summe der Teilstrecken", hopDistance, distance(RATCHET, XROADS) + distance(XROADS, TB), 0.0001)
expect("zwei Teilstrecken", hops, 2)
fly(TB, 251.2)
openMap(KALIMDOR, 1411, RATCHET, viaCrossroads)
fly(XROADS, 69.6)

-- Drei Flüge: Faktor gelernt; Ratchet > Sonnenfels (218,8 s) zurückgehalten und geschätzt
local factor = FlightTimes.OwnFactor("1411")
expect("drei Strecken", factor.samples, 3)
openMap(KALIMDOR, 1411, RATCHET, viaCrossroads)
local heldOut = FlightTimer.Lookup(SUN)
expect("zurückgehaltene Strecke geschätzt", heldOut.source, FlightTimes.ESTIMATE)
expectTrue("Schätzung höchstens 25 % daneben (" .. heldOut.seconds .. " s)", math.abs(heldOut.seconds - 218.8) / 218.8 <= 0.25)

-- Gemessen schlägt die Schätzung; Median der Messungen
fly(SUN, 219)
openMap(KALIMDOR, 1411, RATCHET, viaCrossroads)
local measured = FlightTimer.Lookup(SUN)
expect("jetzt gemessen", measured.source, FlightTimes.MEASURED)
expect("gemessene Zeit", measured.seconds, 219)
fly(SUN, 300)
fly(SUN, 221)
expect("Median der Messungen", routes["80>29"].seconds, 221)

-- Alte Messungen nach Namen: beim Öffnen der Karte unter die nodeIDs übernommen
LevelTimerStatsDB.flightTimes["Tarrens Mühle, Hillsbrad > Undercity, Tirisfal"] = 140
openMap(EASTERN_KINGDOMS, 1415, 2)
expect("alte Messung übernommen", LevelTimerStatsDB.flights.retail["1415"].routes["13>11"].seconds, 140)
expect("alte Messung bleibt lesbar", FlightTimer.Get("Tarrens Mühle, Hillsbrad", "Undercity, Tirisfal"), 140)
local legacy = FlightTimer.Lookup(1)
expect("übernommen: gemessen", legacy.source, FlightTimes.MEASURED)

-- Chatzeile beim Abflug mit Schätzung
openMap(KALIMDOR, 1411, TAURAJO)
TakeTaxiNode(ORG)
expectTrue("Ansage mit Schätzung", wow.printed[#wow.printed]:find("~", 1, true) ~= nil)
wow.state.onTaxi = true
wow.advance(100)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")

-- Debug-Prüfung listet Strecken und Faktoren
local summary = FlightTimes.Summary()
expectTrue("Prüfung: Karte 1411", summary.maps["1411"].routeCount >= 4)
expect("keine Fehler", #wow.errors, 0)
