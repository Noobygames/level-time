-- Mitgelieferte Flugstrecken von WoW Forever (Assist/FlightPathsData/forever.lua, generiert aus den Spieldaten): nur
-- die Datei des eigenen Flavors lädt; die Rechnung trifft die gemessenen Flugzeiten
local FlightTimer, FlightTimes = addon.FlightTimer, addon.FlightTimes

expectTrue("Forever-Daten geladen", addon.FlightPathsData and addon.FlightPathsData.build:match("^1%.60") ~= nil)
expectTrue("Forever-Geschwindigkeit gemessen", addon.FlightPathsData.speed.borrowedFrom == nil)

-- Karte ohne mitgelieferte Messungen, damit die Flugroute zählt: Orgrimmar (23), Crossroads (25), Thunder Bluff (22)
local function openMap(current)
  wow.state.taxiNodes = {
    { name = "Orgrimmar", x = 0.628, y = 0.443, id = 23 },
    { name = "Crossroads", x = 0.557, y = 0.530, id = 25 },
    { name = "Thunder Bluff", x = 0.470, y = 0.580, id = 22 },
  }
  for slot, node in ipairs(wow.state.taxiNodes) do node.type = slot == current and "CURRENT" or "REACHABLE" end
  wow.state.taxiMapID = 9999
  wow.fire("TAXIMAP_OPENED", 1)
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)

-- Gemessen (Debug-Log): Orgrimmar > Crossroads 111 s, Crossroads > Orgrimmar 143 s
openMap(1)
local toCrossroads = FlightTimer.Lookup(2)
expect("Flugroute", toCrossroads.source, FlightTimes.PATH)
expect("ohne ~", toCrossroads.estimated, false)
expectNear("Orgrimmar > Crossroads", toCrossroads.seconds, 111, 2)
openMap(2)
expectNear("Crossroads > Orgrimmar", FlightTimer.Lookup(1).seconds, 143, 2)
expect("keine Fehler", #wow.errors, 0)
