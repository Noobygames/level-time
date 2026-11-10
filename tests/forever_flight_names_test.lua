-- Flugpunkt-Namen in allen Sprachen (Assist/FlightNamesData/forever.lua): alte Messungen unter Namen werden beim Login
-- auf nodeIDs umgeschrieben, auch ohne offene Karte; mehrdeutige Namen bleiben unter dem Namen
local FlightTimer, FlightTimes = addon.FlightTimer, addon.FlightTimes

local names = addon.FlightNamesData
expectTrue("Namen-Datei von Forever geladen", names ~= nil)
expect("Deutsch", names["Crossroads, Brachland"], 25)
expect("Englisch", names["Crossroads, The Barrens"], 25)
expect("Französisch", names["La Croisée, Tarides"], 25)
expect("Spanisch", names["El Cruce, Los Baldíos"], 25)
expect("Orgrimmar", names["Orgrimmar, Durotar"], 23)
expect("mehrdeutiger Name (Gadgetzan 39 und 40) fehlt", names["Gadgetzan, Tanaris"], nil)

wow.login({ level = 20 })
addon.Set("flightTimer", true)

local legacy = LevelTimerStatsDB.flightTimes
legacy["Orgrimmar, Durotar > Crossroads, Brachland"] = 111        -- deutscher Client
legacy["Orgrimmar, Durotar > La Croisée, Tarides"] = 120          -- gleiche Strecke, französischer Client
legacy["La Croisée, Tarides > Orgrimmar, Durotar"] = 143          -- Gegenrichtung
legacy["Orgrimmar, Durotar > Gadgetzan, Tanaris"] = 300           -- mehrdeutig
legacy["Orgrimmar, Durotar > Irgendwo"] = 77                      -- unbekannt
expect("drei Strecken zugeordnet", FlightTimes.MigrateLegacy(), 3)

local byId = LevelTimerStatsDB.flightTimesById.forever
expectTrue("nodeID-Strecke 23>25 gesetzt", byId["23>25"] == 111 or byId["23>25"] == 120)
expect("Gegenrichtung", byId["25>23"], 143)
expect("mehrdeutig: nicht umgeschrieben", byId["23>40"], nil)
expect("mehrdeutig: Name bleibt", legacy["Orgrimmar, Durotar > Gadgetzan, Tanaris"], 300)
expect("unbekannt: Name bleibt", legacy["Orgrimmar, Durotar > Irgendwo"], 77)
expect("Name bleibt lesbar", legacy["Orgrimmar, Durotar > Crossroads, Brachland"], 111)

-- Zweiter Lauf ändert nichts
expect("idempotent", FlightTimes.MigrateLegacy(), 3)
expect("idempotent: 2 Strecken", (function() local n = 0 for _ in pairs(byId) do n = n + 1 end return n end)(), 2)

-- Ohne offene Karte nachschlagbar
local found = FlightTimes.Lookup({ map = "9999", fromKey = "25", toKey = "23", fromName = "?", toName = "?" })
expect("ohne Karte: gemessen", found.source, FlightTimes.MEASURED)
expect("ohne Karte: Zeit", found.seconds, 143)

-- Karte öffnen: beide Knoten zu sehen, die Zeit wird zur Strecke der Karte und aus der Zwischentabelle genommen
wow.state.taxiNodes = {
  { name = "Orgrimmar, Durotar", x = 0.628, y = 0.443, id = 23, type = "CURRENT" },
  { name = "Crossroads, Brachland", x = 0.557, y = 0.530, id = 25, type = "REACHABLE" },
}
wow.state.taxiMapID = 9999
wow.fire("TAXIMAP_OPENED", 1)
local route = LevelTimerStatsDB.flights.forever["9999"].routes["23>25"]
expectTrue("Strecke der Karte", route ~= nil and (route.seconds == 111 or route.seconds == 120))
expect("Zwischentabelle geleert", byId["23>25"], nil)
expect("Gegenrichtung ebenso übernommen", LevelTimerStatsDB.flights.forever["9999"].routes["25>23"].seconds, 143)
expect("Zwischentabelle leer", next(byId), nil)
expect("Lookup nach der Karte", FlightTimer.Lookup(2).source, FlightTimes.MEASURED)
expect("keine Fehler", #wow.errors, 0)
