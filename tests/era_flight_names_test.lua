-- Classic Era: eigene Namen-Datei (Assist/FlightNamesData/classic_era.lua); der Client liefert dort vermutlich keine
-- nodeIDs, darum bleibt der Name-Schlüssel stehen und lesbar
local FlightTimes = addon.FlightTimes

expect("Namen-Datei von Classic Era", addon.FlightNamesData["Orgrimmar, Durotar"], 23)
expect("Spanisch", addon.FlightNamesData["El Cruce, Los Baldíos"], 25)

wow.login({ level = 20 })
LevelTimerStatsDB.flightTimes["Orgrimmar, Durotar > Crossroads, The Barrens"] = 111
expect("zugeordnet", FlightTimes.MigrateLegacy(), 1)
expect("nodeID-Strecke", LevelTimerStatsDB.flightTimesById.classic_era["23>25"], 111)
expect("Name bleibt", LevelTimerStatsDB.flightTimes["Orgrimmar, Durotar > Crossroads, The Barrens"], 111)
expect("keine Fehler", #wow.errors, 0)
