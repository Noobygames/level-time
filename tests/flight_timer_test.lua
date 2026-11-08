-- Flugzeiten: erste Strecke wird gemessen, danach Restzeit als Karte und Chatzeile beim Abflug
local L = addon.L
local FlightTimer = addon.FlightTimer

local function printed(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

local function openTaxiMap()
  wow.state.taxiNodes = {
    { name = "Ratschet, Brachland", type = "CURRENT" },
    { name = "Donnerfels, Mulgore", type = "REACHABLE" },
  }
  wow.fire("TAXIMAP_OPENED", 1)
end

local function fly(seconds)
  openTaxiMap()
  TakeTaxiNode(2)
  wow.state.onTaxi = true
  wow.fire("PLAYER_CONTROL_LOST")
  wow.advance(seconds)
  wow.update(1)
  wow.state.onTaxi = false
  wow.fire("PLAYER_CONTROL_GAINED")
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)

-- Erster Flug: gemessen, Karte "wird gemessen"
openTaxiMap()
TakeTaxiNode(2)
wow.state.onTaxi = true
expectTrue("Ansage unbekannt", printed(string.format(L.FLIGHT_STARTED_UNKNOWN, "Donnerfels, Mulgore")))
expect("Karte: Ziel", LevelTimerFlight.title:GetText(), "Donnerfels, Mulgore")
wow.advance(250)
wow.update(1)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")
expect("gemessen", FlightTimer.Get("Ratschet, Brachland", "Donnerfels, Mulgore"), 250)
expect("gelandet", LevelTimerFlight.title:GetText(), "Donnerfels, Mulgore")

-- Zweiter Flug: bekannte Dauer, Restzeit läuft herunter
openTaxiMap()
TakeTaxiNode(2)
wow.state.onTaxi = true
expectTrue("Ansage mit Dauer", printed(string.format(L.FLIGHT_STARTED, "Donnerfels, Mulgore",
  addon.Format.Duration(250))))
wow.advance(10)
wow.update(1)
expect("Restzeit", LevelTimerFlight.time:GetText(), addon.Format.Duration(240))
wow.advance(230)
wow.state.onTaxi = false
wow.fire("PLAYER_CONTROL_GAINED")
expect("neu gemessen", FlightTimer.Get("Ratschet, Brachland", "Donnerfels, Mulgore"), 240)

-- Ausgeschaltet: misst weiter, zeigt nichts
addon.Set("flightTimer", false)
local lines = #wow.printed
fly(245)
expect("aus: keine Ansage", #wow.printed, lines)
expect("aus: trotzdem gemessen", FlightTimer.Get("Ratschet, Brachland", "Donnerfels, Mulgore"), 245)

-- Kurzer Abbruch zählt nicht
fly(2)
expect("Abbruch nicht gemerkt", FlightTimer.Get("Ratschet, Brachland", "Donnerfels, Mulgore"), 245)
expect("keine Fehler", #wow.errors, 0)
